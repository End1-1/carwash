(function () {
  "use strict";
  var APP_VERSION = "2026.09.21-g";
  if (typeof console !== "undefined") {
    console.log("[tv] version:", APP_VERSION);
    console.log("[tv] console check: app.js loaded");
    console.error("[tv] console check: error channel works");
  }

  // Source for TV process board (new API).
  var API_URL =
    getQueryParam("api") || "/engine/v2/carwash/goods-in-progress/get";
  var REFRESH_MS = 20000;

  function bayTimeFromPayload(json) {
    if (!json || typeof json !== "object") return null;
    if (json.bay_time && typeof json.bay_time === "object") return json.bay_time;
    var data = json.data;
    if (data && typeof data === "object" && !Array.isArray(data) && data.bay_time && typeof data.bay_time === "object") {
      return data.bay_time;
    }
    return null;
  }
  /** Мигание (3/4): время через ogpStatusSubTime(..., 3, 4) — см. комментарий у ogpStatusSubTime */
  var DONE34_BLINK_AFTER_MINUTES = 40;
  var REQUEST_TIMEOUT_MS = 7000;
  var MAX_ROWS_PER_COLUMN = 20;
  var DEFAULT_F_MENU = 0;
  var DEBUG_LOG = true;

  // Values normally taken from Flutter prefs in WebHttpQuery.
  var DEFAULT_APIKEY =
    "8eabcee4-f1bc-11ee-8b0f-021eaa527a65-a0d5c784-f1bc-11ee-8b0f-021eaa527a65";

  var activeListEl = document.getElementById("active-list");
  var queuedListEl = document.getElementById("queued-list");
  var lastUpdateEl = document.getElementById("last-update");
  var statusLineEl = document.getElementById("status-line");
  var rowTemplate = document.getElementById("row-template");

  var activeCache = Object.create(null);
  var queuedCache = Object.create(null);
  var activeOrder = [];
  var queuedOrder = [];
  var lastAllItems = [];
  var maxWashSlots = 0;
  var inFlightController = null;
  var refreshTimerId = null;

  /** Narrow screens: no polling (see start()). Override: ?autorefresh=1|0 */
  function wantsAutoRefresh() {
    var o = getQueryParam("autorefresh");
    if (o === "0" || o === "false") return false;
    return true;
  }

  function scheduleAutoRefresh() {
    if (refreshTimerId != null) {
      clearInterval(refreshTimerId);
      refreshTimerId = null;
    }
    if (!wantsAutoRefresh()) {
      logDebug("refresh.auto", "off (mobile or autorefresh=0)");
      return;
    }
    refreshTimerId = setInterval(refresh, REFRESH_MS);
    logDebug("refresh.auto", { ms: REFRESH_MS });
  }

  function logDebug(tag, payload) {
    if (!DEBUG_LOG || typeof console === "undefined") return;
    try {
      if (payload === undefined) {
        console.log("[tv]", tag);
      } else {
        console.log("[tv]", tag, payload);
      }
    } catch (e) {
      // ignore logging errors on old browsers
    }
  }

  function tr(key, vars) {
    if (typeof window.tvI18n !== "undefined" && window.tvI18n.t) {
      return window.tvI18n.t(key, vars);
    }
    return key;
  }

  function setStatusLine(msg) {
    if (!statusLineEl) return;
    statusLineEl.textContent = String(msg || "");
  }

  if (typeof window !== "undefined") {
    window.onerror = function (message, source, lineno, colno) {
      var m = String(message || "unknown js error");
      var s = String(source || "");
      var where = s ? (" @ " + s + ":" + lineno + ":" + colno) : "";
      setStatusLine(tr("js_error_prefix") + m);
      if (typeof console !== "undefined" && console.error) {
        console.error("[tv] window.onerror", m + where);
      }
      return false;
    };
  }

  function getQueryParam(name) {
    // For older TVs without URLSearchParams.
    var q = window.location.search || "";
    var s = q.replace(/^\?/, "");
    if (!s) return null;
    var parts = s.split("&");
    for (var i = 0; i < parts.length; i++) {
      var kv = parts[i].split("=");
      var k = decodeURIComponent((kv[0] || "").replace(/\+/g, " "));
      if (k === name) {
        return decodeURIComponent((kv[1] || "").replace(/\+/g, " "));
      }
    }
    return null;
  }

  function safeLocalStorageGet(key) {
    try {
      if (!window.localStorage) return null;
      return window.localStorage.getItem(key);
    } catch (e) {
      return null;
    }
  }

  function safeLocalStorageSet(key, value) {
    try {
      if (!window.localStorage) return;
      window.localStorage.setItem(key, value);
    } catch (e) {
      // ignore
    }
  }

  function loadSettings() {
    // Optional overrides via URL:
    // ?sessionkey=...&config=...&f_menu=...&cashsession=...
    var sessionkey = getQueryParam("sessionkey") || safeLocalStorageGet("sessionkey") || "";
    var token = getQueryParam("token") || safeLocalStorageGet("token") || "";
    var config = getQueryParam("config") || safeLocalStorageGet("config") || "";
    var cashsessionStr = getQueryParam("cashsession") || safeLocalStorageGet("cashsession") || "0";
    var fmenuStr = getQueryParam("f_menu") || safeLocalStorageGet("f_menu") || String(DEFAULT_F_MENU);

    var cashsession = parseInt(cashsessionStr, 10);
    if (isNaN(cashsession)) cashsession = 0;

    var f_menu = parseInt(fmenuStr, 10);
    if (isNaN(f_menu)) f_menu = DEFAULT_F_MENU;

    // Cache for convenience (safe wrapper).
    safeLocalStorageSet("sessionkey", sessionkey);
    safeLocalStorageSet("token", token);
    safeLocalStorageSet("config", config);
    safeLocalStorageSet("cashsession", String(cashsession));
    safeLocalStorageSet("f_menu", String(f_menu));

    return {
      sessionkey: sessionkey,
      token: token,
      apikey: DEFAULT_APIKEY,
      config: config,
      language: "am",
      hostinfo: "",
      cashsession: cashsession,
      f_menu: f_menu
    };
  }

  var settings = loadSettings();

  function syncI18nToSettings() {
    if (typeof window.tvI18n !== "undefined" && window.tvI18n.apiLanguage) {
      settings.language = window.tvI18n.apiLanguage();
    }
  }
  syncI18nToSettings();

  logDebug("settings.loaded", {
    sessionkeyLen: settings.sessionkey ? String(settings.sessionkey).length : 0,
    tokenLen: settings.token ? String(settings.token).length : 0,
    hasConfig: !!settings.config,
    cashsession: settings.cashsession,
    f_menu: settings.f_menu
  });

  function engineBaseFromListUrl(listUrl) {
    if (!listUrl) return "/engine/carwash/";
    var i = listUrl.indexOf("get-process-list.php");
    if (i >= 0) return listUrl.substring(0, i);
    var j = listUrl.lastIndexOf("/");
    if (j >= 0) return listUrl.substring(0, j + 1);
    return "/engine/carwash/";
  }

  function resolveEngineUrl(fileName) {
    var base = engineBaseFromListUrl(API_URL);
    if (base.indexOf("http") === 0) return base + fileName;
    if (base.charAt(0) !== "/") return "/" + base + fileName;
    return base + fileName;
  }

  // Status update for goods-in-progress backend.
  var STATUS_URL =
    getQueryParam("statusApi") ||
    resolveLoginUrlFromApi(API_URL, "/engine/v2/carwash/goods-in-progress/update-status");
  var END_ORDER_URL = getQueryParam("endOrderApi") || resolveEngineUrl("end-order.php");

  function resolveLoginUrlFromApi(listUrl, suffix) {
    listUrl = listUrl || "";
    var marker = "/engine/";
    var i = listUrl.indexOf(marker);
    var root = i < 0 ? "" : listUrl.substring(0, i);
    var tail = suffix || "/engine/v2/worker/user-login/pin-login";
    if (tail.charAt(0) !== "/") tail = "/" + tail;
    return root + tail;
  }

  var LOGIN_URL =
    getQueryParam("loginApi") ||
    resolveLoginUrlFromApi(API_URL, "/engine/v2/worker/user-login/pin-login");
  var HASH_LOGIN_URL =
    getQueryParam("hashLoginApi") ||
    resolveLoginUrlFromApi(API_URL, "/engine/v2/worker/user-login/hash-login");

  var overlayEl = document.getElementById("overlay");
  var dialogTitleEl = document.getElementById("dialog-title");
  var dialogButtonsEl = document.getElementById("dialog-buttons");
  var dialogCloseEl = document.getElementById("dialog-close");
  var payOverlayEl = document.getElementById("pay-overlay");
  var payTitleEl = document.getElementById("pay-title");
  var payTotalEl = document.getElementById("pay-total");
  var payMethodsEl = document.getElementById("pay-methods");
  var payConfirmEl = document.getElementById("pay-confirm");
  var payCancelEl = document.getElementById("pay-cancel");
  var statusConfirmOverlayEl = document.getElementById("status-confirm-overlay");
  var statusConfirmFromEl = document.getElementById("status-confirm-from");
  var statusConfirmToEl = document.getElementById("status-confirm-to");
  var statusConfirmOkEl = document.getElementById("status-confirm-ok");
  var statusConfirmCancelEl = document.getElementById("status-confirm-cancel");
  var limitOverlayEl = document.getElementById("limit-overlay");
  var limitTitleEl = document.getElementById("limit-title");
  var limitMessageEl = document.getElementById("limit-message");
  var limitCloseEl = document.getElementById("limit-close");
  var schemaErrorOverlayEl = document.getElementById("schema-error-overlay");
  var schemaErrorTitleEl = document.getElementById("schema-error-title");
  var schemaErrorLeadEl = document.getElementById("schema-error-lead");
  var schemaErrorDetailEl = document.getElementById("schema-error-detail");
  var schemaErrorRefreshEl = document.getElementById("schema-error-refresh");
  var paymentRequiredOverlayEl = document.getElementById("payment-required-overlay");
  var paymentRequiredTitleEl = document.getElementById("payment-required-title");
  var paymentRequiredOkEl = document.getElementById("payment-required-ok");

  /**
   * Контракт API `goods-in-progress/get` (GoodsInProgress::get):
   *   f_header_id, f_id, f_status, f_table, f_table_name;
   *   f_header_data = JSON_DETAILED(oh.f_data),
   *   f_ogp_data = JSON_DETAILED(ogp.f_data),
   *   f_cooking_time = coalesce(json_value(og.f_data,'$.f_cooking_time'), json_value(cg.f_data,'$.f_cooking_time')).
   * Подстатус берём из f_ogp_data.f_substatus; для f_status===1 при отсутствии поля считаем 1.
   * Допустимые пары (f_status, f_substatus): 1/1, 2/2, 2/3, 3/4, 3/5.
   */
  var KEY_ROW_ID = "f_id";
  var KEY_ROW_STATUS = "f_status";
  var KEY_OGP_DATA = "f_ogp_data";
  var KEY_HEADER_DATA = "f_header_data";

  var actionBusy = false;
  var payWorkingOrder = null;
  var loginBusy = false;
  var pinBuffer = "";
  var appStarted = false;

  function safeText(value) {
    return value == null ? "" : String(value);
  }

  function parseDateAsUtcPlus4(input) {
    if (input == null) return null;
    var s = String(input).trim();
    if (!s) return null;

    // Сначала разбор «серверных» строк 2026-04-03 17:36:27 / 2026-Apr-03 … — единая схема UTC+4.
    // Иначе new Date(s) на разных движках даёт разный смысл и интервал «минут с события» ломается (мигание 3/4).
    var m = s.match(
      /^(\d{4})[-\/]([A-Za-z]{3}|\d{1,2})[-\/](\d{1,2})[ T](\d{1,2}):(\d{1,2})(?::(\d{1,2}))?$/
    );
    if (m) {
      var year = parseInt(m[1], 10);
      var monRaw = m[2];
      var day = parseInt(m[3], 10);
      var hh = parseInt(m[4], 10);
      var mm = parseInt(m[5], 10);
      var sec = parseInt(m[6] || "0", 10);

      var mon = 0;
      if (/^\d+$/.test(monRaw)) {
        mon = parseInt(monRaw, 10);
      } else {
        var months = {
          jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6,
          jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12
        };
        mon = months[String(monRaw).toLowerCase()] || 0;
      }
      if (mon >= 1 && mon <= 12) {
        return new Date(Date.UTC(year, mon - 1, day, hh - 4, mm, sec));
      }
    }

    var d = new Date(s);
    if (!isNaN(d.getTime())) return d;
    return null;
  }

  function asObj(v) {
    if (!v) return null;
    if (typeof v === "object") return v;
    if (typeof v === "string") {
      var s = String(v).trim();
      // Иногда поле приходит с BOM в начале.
      if (s.charCodeAt(0) === 0xfeff) s = s.slice(1);
      try {
        var d = JSON.parse(s);
        if (d && typeof d === "object") return d;
        // Бывает двойное кодирование: JSON-строка внутри JSON-строки.
        if (typeof d === "string") {
          var s2 = d.trim();
          if (s2 && (s2.charAt(0) === "{" || s2.charAt(0) === "[")) {
            try {
              var d2 = JSON.parse(s2);
              if (d2 && typeof d2 === "object") return d2;
            } catch (e2) {
              // ignore nested parse errors
            }
          }
        }
      } catch (e) {
        // ignore parse errors
      }
    }
    return null;
  }

  function ogpDataStrict(item) {
    if (!item || !Object.prototype.hasOwnProperty.call(item, KEY_OGP_DATA)) return null;
    return asObj(item[KEY_OGP_DATA]);
  }

  /** Время окна заказа: только f_ogp_data.f_cooking_start / f_cooking_end. */
  function rowStartEndFromOrderData(item) {
    if (!item) return null;
    var ogp = ogpDataStrict(item) || {};
    var start = parseDateAsUtcPlus4(ogp.f_cooking_start);
    var end = parseDateAsUtcPlus4(ogp.f_cooking_end);
    if (!start || isNaN(start.getTime()) || !end || isNaN(end.getTime())) return null;
    return { start: start, end: end };
  }

  function rowStartEndForDisplay(item) {
    if (item && item.__tvLines && item.__tvLines.length) {
      var start = null;
      var end = null;
      for (var i = 0; i < item.__tvLines.length; i++) {
        var se = rowStartEndFromOrderData(item.__tvLines[i]);
        if (!se) continue;
        if (!start || se.start.getTime() < start.getTime()) start = se.start;
        if (!end || se.end.getTime() > end.getTime()) end = se.end;
      }
      if (start && end) return { start: start, end: end };
      return null;
    }
    return rowStartEndFromOrderData(item);
  }

  function statusSubForDisplay(item) {
    if (item && item.__tvLines && item.__tvLines.length) {
      var best = item.__tvLines[0];
      var bestR = progressRankFromRow(best);
      for (var i = 1; i < item.__tvLines.length; i++) {
        var r = progressRankFromRow(item.__tvLines[i]);
        if (r > bestR) {
          bestR = r;
          best = item.__tvLines[i];
        }
      }
      return normalizedProcessStatusSubstatus(best);
    }
    return normalizedProcessStatusSubstatus(item);
  }

  /**
   * Момент времени для пары (статус, субстатус) в JSON_DETAILED(ogp.f_data).
   * 1) Новый формат: f_status_{st}_{ss}_time (напр. f_status_1_1_time, f_status_3_5_time).
   * 2) Старый формат (как пишет смена статуса на многих инсталляциях): только f_status_N_time,
   *    где N часто — порядковый «крупный» шаг, а не пара (st,ss). Соответствие:
   *    (1,1)→f_status_1_time; (2,2)→f_status_2_time; (2,3)→f_status_3_time или f_status_2_time;
   *    (3,4)→f_status_4_time или f_status_3_time; (3,5)→f_status_3_time, f_parking_time, f_status_5_time.
   */
  function ogpStatusSubTime(dObj, st, ss) {
    if (!dObj) return null;
    var stn = Number(st);
    var ssn = Number(ss);
    var key = "f_status_" + stn + "_" + ssn + "_time";
    var v = dObj[key];
    if (v != null && v !== "") return v;

    if (stn === 1 && ssn === 1) {
      v = dObj.f_status_1_time;
      if (v != null && v !== "") return v;
    }
    if (stn === 2 && ssn === 2) {
      v = dObj.f_status_2_time;
      if (v != null && v !== "") return v;
    }
    if (stn === 2 && ssn === 3) {
      v = dObj.f_status_3_time || dObj.f_status_2_time;
      if (v != null && v !== "") return v;
    }
    if (stn === 3 && ssn === 4) {
      v = dObj.f_status_4_time || dObj.f_status_3_time;
      if (v != null && v !== "") return v;
    }
    if (stn === 3 && ssn === 5) {
      v = dObj.f_status_3_time || dObj.f_parking_time || dObj.f_status_5_time;
      if (v != null && v !== "") return v;
    }
    return null;
  }

  function headerDataStrict(item) {
    if (!item || !Object.prototype.hasOwnProperty.call(item, KEY_HEADER_DATA)) return null;
    return asObj(item[KEY_HEADER_DATA]);
  }

  /**
   * Неоплачено (как HistoryGoods._canPayFromHeader / Cashbox::OrderUnpaidAmount).
   * Legacy: нет f_amount_other, f_amount_paid=0 и нет нал/карта/idram при ненулевой сумме.
   */
  function headerOrderUnpaid(item) {
    var hdr = headerDataStrict(item);
    if (!hdr) return true;

    var other = hdr.f_amount_other;
    if (other == null && hdr.f_amountother != null) other = hdr.f_amountother;
    if (numAmt(other) > 0.009) return true;

    var cash = numAmt(firstVal(hdr.f_amount_cash, hdr.f_amountcash));
    var card = numAmt(firstVal(hdr.f_amount_card, hdr.f_amountcard));
    var idram = numAmt(firstVal(hdr.f_amount_idram, hdr.f_amountidram));
    var paid = cash + card + idram;

    var subTotal = numAmt(firstVal(hdr.f_sub_total, hdr.f_subtotal));
    var total = numAmt(firstVal(hdr.f_amounttotal, hdr.f_amount_total));
    var orderTotal = subTotal > 0.009 ? subTotal : total;

    var hasOtherField =
      Object.prototype.hasOwnProperty.call(hdr, "f_amount_other") ||
      Object.prototype.hasOwnProperty.call(hdr, "f_amountother");
    var amountPaid = numAmt(hdr.f_amount_paid);

    if (
      !hasOtherField &&
      paid <= 0.009 &&
      amountPaid <= 0.009 &&
      orderTotal > 0.009
    ) {
      return true;
    }

    if (orderTotal > 0.009 && paid <= 0.009) return true;
    return false;
  }

  /** Оплачен (инверсия headerOrderUnpaid). */
  function headerOrderIsPaid(item) {
    return !headerOrderUnpaid(item);
  }

  /** Оплата по "реальным" методам: cash/card/idram > 0 (в f_header_data). */
  function headerHasRealPayment(item) {
    var hdr = headerDataStrict(item);
    if (!hdr) return false;
    var cash = hdr.f_amount_cash;
    if (cash == null) cash = hdr.f_amountcash;
    var card = hdr.f_amount_card;
    if (card == null) card = hdr.f_amountcard;
    var idram = hdr.f_amount_idram;
    if (idram == null) idram = hdr.f_amountidram;
    return numAmt(cash) > 0 || numAmt(card) > 0 || numAmt(idram) > 0;
  }

  /** Архив 4/1 разрешён только если заказ оплачен. */
  function archiveStatusRequiresPaidOrder(status, substatus) {
    return Number(status) === 4 && Number(substatus) === 1;
  }

  /**
   * Подстатус только из f_ogp_data.f_substatus; для очереди (f_status===1)
   * сервер может не присылать поле — тогда 1.
   */
  function resolvedSubstatusFromRow(row) {
    var st = parseInt(row[KEY_ROW_STATUS], 10);
    var ogp = ogpDataStrict(row);
    if (isNaN(st)) return NaN;
    // Для очереди достаточно самого f_status==1: даже при битом/пустом JSON OGP
    // карточка должна попасть в колонку «Ожидают».
    if (!ogp) {
      if (st === 1) return 1;
      return NaN;
    }
    if (ogp.f_substatus != null && ogp.f_substatus !== "") {
      var ss = parseInt(ogp.f_substatus, 10);
      if (!isNaN(ss)) return ss;
    }
    if (st === 1) return 1;
    return NaN;
  }

  function isKnownProcessPair(st, ss) {
    if (st === 1 && ss === 1) return true;
    if (st === 2 && ss === 2) return true;
    if (st === 2 && ss === 3) return true;
    if (st === 3 && ss === 4) return true;
    if (st === 3 && ss === 5) return true;
    return false;
  }

  /**
   * Пара f_status + f_ogp_data.f_substatus иногда расходятся (например 1/3: в шапке строки ещё «1»,
   * а в OGP уже фаза 2/3). Как во Flutter: приводим к ближайшей допустимой паре, иначе orderProgress=0
   * и модалка действий пустая.
   */
  function normalizedProcessStatusSubstatus(item) {
    if (!item) return { st: NaN, ss: NaN };
    var st = processStatus(item);
    var ss = processSubstatus(item);
    if (isNaN(st) || isNaN(ss)) return { st: st, ss: ss };
    if (isKnownProcessPair(st, ss)) return { st: st, ss: ss };
    if (st < 3 && (ss === 4 || ss === 5)) return { st: 3, ss: ss };
    if (st < 2 && (ss === 2 || ss === 3)) return { st: 2, ss: ss };
    return { st: st, ss: ss };
  }

  /**
   * Сырая пара f_status + f_ogp_data.f_substatus не из допустимого набора (рассинхрон на сервере).
   * Для сгруппированного заказа достаточно одной битой строки.
   */
  function isRawProcessPairInvalid(item) {
    if (!item) return false;
    if (item.__tvLines && item.__tvLines.length) {
      for (var i = 0; i < item.__tvLines.length; i++) {
        var r = item.__tvLines[i];
        var st = processStatus(r);
        var ss = processSubstatus(r);
        if (!isKnownProcessPair(st, ss)) return true;
      }
      return false;
    }
    return !isKnownProcessPair(processStatus(item), processSubstatus(item));
  }

  /**
   * Проверка контракта ответа до отрисовки. При ошибке — полноэкранное сообщение для разработчиков.
   */
  function validateProcessListRows(items) {
    if (!Array.isArray(items)) {
      return { ok: false, reason: "payload_not_array" };
    }
    var requiredRowKeys = [KEY_ROW_ID, KEY_ROW_STATUS, KEY_OGP_DATA];
    var i, j, row, key, st, ss;
    for (i = 0; i < items.length; i++) {
      row = items[i];
      if (!row || typeof row !== "object") {
        return { ok: false, index: i, reason: "row_not_object" };
      }
      for (j = 0; j < requiredRowKeys.length; j++) {
        key = requiredRowKeys[j];
        if (!Object.prototype.hasOwnProperty.call(row, key)) {
          return {
            ok: false,
            index: i,
            reason: "missing_key",
            key: key,
            expectedKeys: requiredRowKeys,
            rowKeysSample: Object.keys(row).sort()
          };
        }
        if (row[key] == null || row[key] === "") {
          return {
            ok: false,
            index: i,
            reason: "empty_value",
            key: key,
            expectedKeys: requiredRowKeys,
            rowKeysSample: Object.keys(row).sort()
          };
        }
      }
      if (!ogpDataStrict(row)) {
        return {
          ok: false,
          index: i,
          reason: "ogp_f_data_invalid_json",
          key: KEY_OGP_DATA,
          expectedKeys: requiredRowKeys
        };
      }
      st = parseInt(row[KEY_ROW_STATUS], 10);
      ss = resolvedSubstatusFromRow(row);
      if (isNaN(st) || isNaN(ss)) {
        return {
          ok: false,
          index: i,
          reason: "nan_status",
          f_status: row[KEY_ROW_STATUS],
          f_substatus_resolved: ss,
          note: "substatus from f_ogp_data.f_substatus or 1 when f_status===1"
        };
      }
      if (!isKnownProcessPair(st, ss)) {
        return {
          ok: false,
          index: i,
          reason: "unknown_status_pair",
          st: st,
          ss: ss,
          note: "expected one of: 1/1, 2/2, 2/3, 3/4, 3/5"
        };
      }
    }
    return { ok: true };
  }

  function processStatus(item) {
    return parseInt(item[KEY_ROW_STATUS], 10);
  }

  function processSubstatus(item) {
    var ss = resolvedSubstatusFromRow(item);
    return isNaN(ss) ? 0 : ss;
  }

  function statusLabel(status, substatus) {
    var s = Number(status);
    var u = Number(substatus);
    // 1/1 ожидание, 2/2 мойка, 2/3 сушка, 3/4 выполнено, 3/5 паркинг
    if (s === 1 && u === 1) return tr("col_pending");
    if (s === 2 && u === 2) return tr("btn_wash");
    if (s === 2 && u === 3) return tr("btn_dry");
    if (s === 3 && u === 4) return tr("col_free_parking");
    if (s === 3 && u === 5) return tr("btn_paid_parking");
    if (s === 4 && u === 6) return tr("btn_deliver");
    if (s === 4 && u === 1) return tr("status_archive_row");
    return String(status) + "/" + String(substatus);
  }

  function askStatusChangeConfirm(fromLabel, toLabel) {
    return new Promise(function (resolve) {
      if (
        !statusConfirmOverlayEl ||
        !statusConfirmFromEl ||
        !statusConfirmToEl ||
        !statusConfirmOkEl ||
        !statusConfirmCancelEl
      ) {
        if (typeof window.confirm === "function") {
          resolve(window.confirm(tr("status_change_confirm") + "\n" + fromLabel + " -> " + toLabel));
        } else {
          resolve(true);
        }
        return;
      }

      statusConfirmFromEl.textContent = fromLabel || "—";
      statusConfirmToEl.textContent = toLabel || "—";
      statusConfirmOverlayEl.style.display = "flex";
      statusConfirmOverlayEl.setAttribute("aria-hidden", "false");

      function cleanup(result) {
        statusConfirmOverlayEl.style.display = "none";
        statusConfirmOverlayEl.setAttribute("aria-hidden", "true");
        statusConfirmOkEl.onclick = null;
        statusConfirmCancelEl.onclick = null;
        statusConfirmOverlayEl.onclick = null;
        resolve(result);
      }

      statusConfirmOkEl.onclick = function () {
        cleanup(true);
      };
      statusConfirmCancelEl.onclick = function () {
        cleanup(false);
      };
      statusConfirmOverlayEl.onclick = function (e) {
        if (e.target === statusConfirmOverlayEl) cleanup(false);
      };
    });
  }

  function processId(item) {
    if (!item || !Object.prototype.hasOwnProperty.call(item, KEY_ROW_ID)) return null;
    var v = item[KEY_ROW_ID];
    if (v == null) return null;
    var s = String(v).trim();
    if (!s) return null;
    return v;
  }

  function closeLimitModal() {
    if (!limitOverlayEl) return;
    limitOverlayEl.style.display = "none";
    limitOverlayEl.setAttribute("aria-hidden", "true");
  }

  function openLimitModal(message, titleKey) {
    if (!limitOverlayEl || !limitMessageEl) {
      setStatusLine(String(message || ""));
      return;
    }
    if (limitTitleEl) {
      limitTitleEl.textContent = tr(titleKey || "wash_limit_title");
    }
    limitMessageEl.textContent = String(message || "");
    limitOverlayEl.style.display = "flex";
    limitOverlayEl.setAttribute("aria-hidden", "false");
  }

  /** Парковка 3/5 и неоплачен: только короткий диалог «требуется оплата» (без меню статуса). */
  function needsPaymentRequiredNotice(order) {
    if (!order) return false;
    var st = processStatus(order);
    var ss = processSubstatus(order);
    if (st !== 3 || ss !== 5) return false;
    return headerOrderUnpaid(order);
  }

  function closePaymentRequiredModal() {
    if (!paymentRequiredOverlayEl) return;
    paymentRequiredOverlayEl.style.display = "none";
    paymentRequiredOverlayEl.setAttribute("aria-hidden", "true");
  }

  function openPaymentRequiredModal(order) {
    if (!paymentRequiredOverlayEl) return;
    if (paymentRequiredTitleEl) {
      paymentRequiredTitleEl.textContent = tr("payment_required_title");
    }
    if (paymentRequiredOkEl) {
      paymentRequiredOkEl.textContent = tr("dialog_close");
    }
    paymentRequiredOverlayEl.style.display = "flex";
    paymentRequiredOverlayEl.setAttribute("aria-hidden", "false");
  }

  function orderProgress(item) {
    if (!item) return 0;
    var n = normalizedProcessStatusSubstatus(item);
    var st = n.st;
    var ss = n.ss;
    if (st === 1 && ss === 1) return 1;
    if (st === 2 && ss === 2) return 2;
    if (st === 2 && ss === 3) return 3;
    if (st === 3 && ss === 4) return 4;
    if (st === 3 && ss === 5) return 5;
    return 0;
  }

  // Для выбора "главной" строки в сгруппированном заказе:
  // чем больше rank, тем "позднее" стадия процесса.
  function progressRankFromRow(item) {
    return orderProgress(item);
  }

  /**
   * Минуты с перехода в «выполнено» (3/4): ogpStatusSubTime(..., 3, 4). Без времени — null.
   */
  function minutesSinceEnteredDone34(item) {
    if (!item) return null;
    var nd = normalizedProcessStatusSubstatus(item);
    if (nd.st !== 3 || nd.ss !== 4) return null;
    var dObj = ogpDataStrict(item);
    if (!dObj) return null;
    var start = ogpStatusSubTime(dObj, 3, 4);
    if (start == null || start === "") return null;
    var d = parseDateAsUtcPlus4(start);
    if (!d || isNaN(d.getTime())) return null;
    var mins = (Date.now() - d.getTime()) / 60000;
    if (!isFinite(mins)) return null;
    return mins;
  }

  function shouldBlinkDone34Row(item) {
    if (item && item.__tvLines && item.__tvLines.length) {
      for (var i = 0; i < item.__tvLines.length; i++) {
        var m = minutesSinceEnteredDone34(item.__tvLines[i]);
        if (m != null && isFinite(m) && m >= DONE34_BLINK_AFTER_MINUTES) return true;
      }
      return false;
    }
    var m = minutesSinceEnteredDone34(item);
    if (m == null || !isFinite(m)) return false;
    return m >= DONE34_BLINK_AFTER_MINUTES;
  }

  /** Лимит минут для фазы мойки (2/2): f_washtime или доля от cook, как в projectedBayFreeMsActiveWash. */
  function washMinutesBudgetForBlink(row) {
    var cook = cookingMinutesFromRow(row);
    var dObj = ogpDataStrict(row);
    if (!dObj) return cook;
    var washM = Number(dObj.f_washtime) || 0;
    var dryM = Number(dObj.f_drytime) || 0;
    if (washM > 0) return washM;
    if (washM + dryM > 0) return Math.max(1, cook - dryM);
    return cook;
  }

  /** Лимит минут для фазы сушки (2/3). */
  function dryMinutesBudgetForBlink(row) {
    var cook = cookingMinutesFromRow(row);
    var dObj = ogpDataStrict(row);
    if (!dObj) return cook;
    var washM = Number(dObj.f_washtime) || 0;
    var dryM = Number(dObj.f_drytime) || 0;
    if (dryM > 0) return dryM;
    if (washM + dryM > 0) return Math.max(1, cook - washM);
    return cook;
  }

  function shouldBlinkWashDryOvertimeSingle(row) {
    if (!row) return false;
    var n = normalizedProcessStatusSubstatus(row);
    var st = n.st;
    var ss = n.ss;
    if (st !== 2 || (ss !== 2 && ss !== 3)) return false;
    var mins = minutesSinceOgpPair(row, st, ss);
    if (mins == null || !isFinite(mins)) return false;
    if (ss === 2) return mins >= washMinutesBudgetForBlink(row);
    return mins >= dryMinutesBudgetForBlink(row);
  }

  /** Мигание 2/2 и 2/3, если время в текущей фазе превысило расчётное (cook / washtime / drytime). */
  function shouldBlinkWashDryOvertimeRow(item) {
    if (item && item.__tvLines && item.__tvLines.length) {
      for (var i = 0; i < item.__tvLines.length; i++) {
        if (shouldBlinkWashDryOvertimeSingle(item.__tvLines[i])) return true;
      }
      return false;
    }
    return shouldBlinkWashDryOvertimeSingle(item);
  }

  /** Same idea as Flutter global.dart washMinutesSince */
  function washMinutesSince(item) {
    if (!item) return 0;
    var st = processStatus(item);
    var ss = processSubstatus(item);
    var dObj = ogpDataStrict(item);
    if (!dObj) return 0;
    var start = null;
    if (st === 3 && ss === 5) {
      start = ogpStatusSubTime(dObj, 3, 5);
    } else if (st === 2 && ss === 2) {
      start = ogpStatusSubTime(dObj, 2, 2);
    } else if (st === 2 && ss === 3) {
      start = ogpStatusSubTime(dObj, 2, 3);
    } else if (st === 3 && ss === 4) {
      start = ogpStatusSubTime(dObj, 3, 4);
    }
    if (!start && (st === 1 || st === 2)) {
      start = ogpStatusSubTime(dObj, 1, 1);
    }
    if (start == null || start === "") return 0;
    var d = parseDateAsUtcPlus4(start);
    if (!d) return 0;
    if (isNaN(d.getTime())) return 0;
    return Math.floor((Date.now() - d.getTime()) / 60000);
  }

  var STATUS_ICON_BASE = "./assets/icons/";

  /** Mirrors status/substatus from goods-in-progress API */
  function resolveStatusIconUrl(item, isQueued) {
    if (isQueued) return STATUS_ICON_BASE + "timer.png";
    var n = normalizedProcessStatusSubstatus(item);
    var st = n.st;
    var ss = n.ss;
    if (st === 2 && ss === 2) return STATUS_ICON_BASE + "shower.png";
    if (st === 2 && ss === 3) return STATUS_ICON_BASE + "fan.png";
    if (st === 3 && ss === 4) return STATUS_ICON_BASE + "timer.png";
    if (st === 3 && ss === 5) return STATUS_ICON_BASE + "parking.png";
    if (st === 1 && ss === 1) return STATUS_ICON_BASE + "timer.png";
    return null;
  }

  function numAmt(v) {
    if (v == null || v === "") return 0;
    var n = Number(v);
    return isNaN(n) ? 0 : n;
  }

  /** Замена `a ?? b`: оператор недоступен в Firefox < 72 (мобильные сборки). */
  function firstVal(a, b) {
    return a == null ? b : a;
  }

  function isUnpaidOrder(o) {
    return (
      numAmt(o.f_amountcash) === 0 &&
      numAmt(o.f_amountcard) === 0 &&
      numAmt(o.f_amountidram) === 0
    );
  }

  function cloneOrderForApi(o) {
    var c = {};
    for (var k in o) {
      if (Object.prototype.hasOwnProperty.call(o, k)) c[k] = o[k];
    }
    return c;
  }

  function withAuthPayload(obj) {
    var out = cloneOrderForApi(obj);
    out.sessionkey = settings.sessionkey;
    out.apikey = settings.apikey;
    out.config = settings.config;
    out.language = settings.language;
    out.hostinfo = settings.hostinfo || "";
    out.cashsession = settings.cashsession;
    return out;
  }

  /** Flutter AppModel.tryLogin / initModel(auth by token) body shape */
  function loginPinPayload(pin) {
    return {
      pin: pin != null ? String(pin) : "",
      phone: "+37455555220",
      sessionkey: settings.sessionkey || "",
      apikey: settings.apikey,
      config: settings.config,
      language: settings.language,
      hostinfo: settings.hostinfo || "",
      cashsession: settings.cashsession || 0,
      nootp: true
    };
  }

  function loginSessionPayload() {
    return {
      token: settings.token || "",
      sessionkey: settings.sessionkey || "",
      apikey: settings.apikey,
      config: settings.config,
      language: settings.language,
      hostinfo: settings.hostinfo || "",
      cashsession: settings.cashsession || 0,
      nootp: true
    };
  }

  function applyLoginSuccess(data) {
    if (!data || typeof data !== "object") return;
    if (data.token) {
      settings.token = String(data.token);
      safeLocalStorageSet("token", settings.token);
    }
    if (data.sessionkey) {
      settings.sessionkey = String(data.sessionkey);
      safeLocalStorageSet("sessionkey", settings.sessionkey);
    }
    if (data.userdata && data.userdata.f_group != null) {
      safeLocalStorageSet("user_group", String(data.userdata.f_group));
    } else if (data.user && data.user.f_group != null) {
      safeLocalStorageSet("user_group", String(data.user.f_group));
    }
    if (data.cashsession && data.cashsession.f_id != null) {
      settings.cashsession = parseInt(data.cashsession.f_id, 10);
      if (isNaN(settings.cashsession)) settings.cashsession = 0;
      safeLocalStorageSet("cashsession", String(settings.cashsession));
    }
  }

  function loginErrorText(json) {
    if (json != null && json.data != null && typeof json.data === "string") return json.data;
    return tr("login_error_fallback");
  }

  function updatePinDots() {
    var dots = document.querySelectorAll("#login-overlay .pin-dot");
    for (var i = 0; i < dots.length; i++) {
      if (i < pinBuffer.length) dots[i].classList.add("pin-dot--filled");
      else dots[i].classList.remove("pin-dot--filled");
    }
  }

  function setLoginError(msg) {
    var el = document.getElementById("login-error");
    if (el) el.textContent = msg || "";
  }

  function showLoginOverlay(warnMsg) {
    var el = document.getElementById("login-overlay");
    if (!el) return;
    pinBuffer = "";
    updatePinDots();
    setLoginError(warnMsg || "");
    loginBusy = false;
    el.style.display = "flex";
    el.setAttribute("aria-hidden", "false");
    document.body.classList.remove("app-authed");
    setStatusLine(tr("enter_pin"));
  }

  function hideLoginOverlay() {
    var el = document.getElementById("login-overlay");
    if (!el) return;
    el.style.display = "none";
    el.setAttribute("aria-hidden", "true");
    document.body.classList.add("app-authed");
  }

  function tryRestoreSession() {
    if (!settings.token) return Promise.resolve({ ok: false, clearKey: false });
    return doPost(HASH_LOGIN_URL, loginSessionPayload(), REQUEST_TIMEOUT_MS, true)
      .then(function (json) {
        logDebug("login.session.response", json);
        if (json && json.status === 1) {
          applyLoginSuccess(json);
          return { ok: true, clearKey: false };
        }
        return { ok: false, clearKey: true };
      })
      .catch(function (e) {
        logDebug("login.session.error", String(e && e.message ? e.message : e));
        return { ok: false, clearKey: false };
      });
  }

  function clearStaleSession() {
    settings.sessionkey = "";
    settings.token = "";
    settings.cashsession = 0;
    safeLocalStorageSet("sessionkey", "");
    safeLocalStorageSet("token", "");
    safeLocalStorageSet("cashsession", "0");
  }

  function submitPinLogin() {
    if (loginBusy || !pinBuffer.length) return;
    loginBusy = true;
    setLoginError("");
    setStatusLine(tr("login_progress"));
    doPost(LOGIN_URL, loginPinPayload(pinBuffer), REQUEST_TIMEOUT_MS, true)
      .then(function (json) {
        logDebug("login.pin.response", json);
        if (json && json.status === 1) {
          applyLoginSuccess(json);
          pinBuffer = "";
          updatePinDots();
          hideLoginOverlay();
          if (!appStarted) start();
          setStatusLine(tr("status_ok_short"));
        } else {
          setLoginError(loginErrorText(json));
          setStatusLine(tr("error_login"));
          pinBuffer = "";
          updatePinDots();
        }
      })
      .catch(function () {
        setLoginError(tr("network_error"));
        setStatusLine(tr("error_login"));
        pinBuffer = "";
        updatePinDots();
      })
      .then(function () {
        loginBusy = false;
      });
  }

  function wireLoginUi() {
    var overlay = document.getElementById("login-overlay");
    if (!overlay) return;

    // Суффикс js подтверждает, что скрипт разобран и выполнен: в HTML стоит html.
    var verEl = document.getElementById("login-ver");
    if (verEl) verEl.textContent = APP_VERSION + " js";

    var pinGate = 0;
    var ignoreMouseUntil = 0;

    function loginVisible() {
      return overlay && overlay.style.display !== "none" && overlay.getAttribute("aria-hidden") !== "true";
    }

    function onDigit(d) {
      if (loginBusy) return;
      if (pinBuffer.length >= 5) return;
      pinBuffer += d;
      updatePinDots();
      setLoginError("");
    }

    function applyPinAct(act) {
      if (!act) return;
      if (act === "bs") {
        if (loginBusy || !pinBuffer.length) return;
        pinBuffer = pinBuffer.slice(0, -1);
        updatePinDots();
        return;
      }
      if (act === "ok") {
        submitPinLogin();
        return;
      }
      if (/^\d$/.test(act)) onDigit(act);
    }

    function isMouseLike(src) {
      return (
        src === "click" ||
        src === "mousedown" ||
        src === "mouseup" ||
        src === "pointerdown" ||
        src === "pointerup"
      );
    }

    function handlePinAct(act, src) {
      if (!act) return;
      var now = Date.now();
      src = src || "";
      // Один жест даёт touchstart + touchend + mousedown + click. Берём первое, остальное режем.
      if (now - pinGate < 280) return;
      if (isMouseLike(src) && now < ignoreMouseUntil) return;
      pinGate = now;
      if (src.indexOf("touch") === 0) ignoreMouseUntil = now + 800;
      applyPinAct(act);
    }

    function pinActFromNode(n) {
      var hops = 0;
      while (n && hops < 12) {
        if (n.nodeType === 1 && n.getAttribute) {
          var a = n.getAttribute("data-pin");
          if (a) return a;
        }
        n = n.parentNode || n.parentElement;
        hops += 1;
      }
      return "";
    }

    function eventPoint(ev) {
      if (!ev) return null;
      var t = null;
      if (ev.touches && ev.touches.length) t = ev.touches[0];
      else if (ev.changedTouches && ev.changedTouches.length) t = ev.changedTouches[0];
      else t = ev;
      if (!t || typeof t.clientX !== "number") return null;
      return { x: t.clientX, y: t.clientY };
    }

    function pinActFromEvent(ev, hintEl) {
      var act = pinActFromNode(hintEl);
      if (act) return act;
      if (!ev) return "";
      act = pinActFromNode(ev.currentTarget);
      if (act) return act;
      act = pinActFromNode(ev.srcElement || ev.target);
      if (act) return act;
      var pt = eventPoint(ev);
      if (!pt || !document.elementFromPoint) return "";
      try {
        return pinActFromNode(document.elementFromPoint(pt.x, pt.y));
      } catch (err) {
        return "";
      }
    }

    function onPinPointer(ev, hintEl) {
      ev = ev || window.event;
      if (!ev) return false;
      if (!loginVisible()) return false;
      if (typeof ev.button === "number" && ev.button > 0) return false;
      var act = pinActFromEvent(ev, hintEl);
      if (!act) return false;
      handlePinAct(act, ev.type || "tap");
      try {
        if (ev.preventDefault) ev.preventDefault();
        if (ev.stopPropagation) ev.stopPropagation();
      } catch (err) {}
      return false;
    }

    window.__tvPinPress = function (ev, hintEl) {
      if (!hintEl && this && this.getAttribute) hintEl = this;
      return onPinPointer(ev, hintEl);
    };

    function listen(node, type, fn) {
      if (!node || !node.addEventListener) return;
      try {
        node.addEventListener(type, fn, true);
      } catch (e1) {
        try {
          node.addEventListener(type, fn);
        } catch (e2) {}
      }
    }

    function bindKey(el) {
      function go(ev) {
        return onPinPointer(ev, el);
      }
      el.onclick = go;
      el.ontouchend = go;
    }

    var nodes = overlay.getElementsByTagName("*");
    for (var i = 0; i < nodes.length; i++) {
      if (nodes[i].getAttribute && nodes[i].getAttribute("data-pin")) bindKey(nodes[i]);
    }

    listen(document, "keydown", function (ev) {
      ev = ev || window.event;
      if (!ev || !loginVisible()) return;
      var k = ev.key || "";
      var code = ev.keyCode || ev.which;
      if (k === "Backspace" || k === "Delete" || code === 8 || code === 46) {
        if (ev.preventDefault) ev.preventDefault();
        handlePinAct("bs", "keydown");
        return;
      }
      if (k === "Enter" || code === 13) {
        if (ev.preventDefault) ev.preventDefault();
        handlePinAct("ok", "keydown");
        return;
      }
      if (/^\d$/.test(k)) {
        if (ev.preventDefault) ev.preventDefault();
        handlePinAct(k, "keydown");
        return;
      }
      if (code >= 48 && code <= 57) {
        if (ev.preventDefault) ev.preventDefault();
        handlePinAct(String(code - 48), "keydown");
      }
    });
  }

  function formatTime(input) {
    if (!input) return "--:--";
    var d = parseDateAsUtcPlus4(input);
    if (!d) return safeText(input);
    if (isNaN(d.getTime())) {
      // Server can return already-formatted time, keep it.
      return safeText(input);
    }
    var hh = d.getHours();
    var mm = d.getMinutes();
    return (hh < 10 ? "0" + hh : "" + hh) + ":" + (mm < 10 ? "0" + mm : "" + mm);
  }

  function getKey(item, index) {
    if (!item) return "idx:" + index;
    if (item.__tvIsGroup && item.__tvLineIds && item.__tvLineIds.length) {
      return "grp:" + headerKeyForRow(item);
    }
    if (item[KEY_ROW_ID] != null && item[KEY_ROW_ID] !== "") {
      return "id:" + String(item[KEY_ROW_ID]);
    }
    if (item.f_id) return "id:" + String(item.f_id);
    if (item.f_carnumber) return "car:" + String(item.f_carnumber);
    if (item.f_uuid) return "uuid:" + String(item.f_uuid);
    if (item.f_table != null) return "table:" + String(item.f_table);
    return "idx:" + index;
  }

  function setEmptyState(container) {
    if (!container) return;
    container.textContent = "";
    var empty = document.createElement("div");
    empty.className = "empty";
    empty.textContent = tr("empty_no_data");
    container.appendChild(empty);
  }

  function createRow(item, isQueued) {
    var rowEl = null;
    if (rowTemplate && rowTemplate.content && rowTemplate.content.cloneNode) {
      var fragment = rowTemplate.content.cloneNode(true);
      rowEl = fragment.querySelector(".row");
    }
    if (!rowEl) {
      rowEl = document.createElement("article");
      rowEl.className = "row row-clickable";
      rowEl.setAttribute("tabindex", "0");
      rowEl.innerHTML =
        '<img src="' +
        STATUS_ICON_BASE +
        'parking.png" alt="" class="status-icon" width="40" height="40">' +
        '<div class="row-main"><div class="number"></div><div class="service"></div></div>' +
        '<div class="row-side"><div class="table"></div><div class="time"></div></div>';
    }
    patchRow(rowEl, item, isQueued);
    return rowEl;
  }

  function patchRow(rowEl, item, isQueued) {
    var disp = effectiveRowForDisplay(item) || item;
    var headerData = headerDataStrict(disp) || {};
    var car = safeText(
      disp.f_carnumber ||
        disp.f_car_number ||
        headerData.f_car_number ||
        "---"
    );
    var table = safeText(
      disp.f_tablename ||
        disp.f_table_name ||
        (disp.f_daily_number != null ? "#" + safeText(disp.f_daily_number) : "") ||
        ("BOX " + safeText(disp.f_table || ""))
    ).trim();

    var service = item.__tvCombinedService || "";
    if (!service) {
      var lbl = serviceLabelFromRow(disp);
      service = lbl || tr("service_default");
    }

    rowEl.classList.remove(
      "row-pending",
      "row-inprog-wash",
      "row-inprog-ok",
      "is-queued",
      "row-blink-done34",
      "row-blink-washdry-overtime",
      "row-process-invalid"
    );
    if (isRawProcessPairInvalid(item)) {
      rowEl.classList.add("row-process-invalid");
    }
    if (isQueued) {
      rowEl.classList.add("row-pending");
    } else {
      var pn = normalizedProcessStatusSubstatus(disp);
      var pst = pn.st;
      var pss = pn.ss;
      if (pst === 2 && pss === 2) rowEl.classList.add("row-inprog-wash");
      else rowEl.classList.add("row-inprog-ok");
      if (shouldBlinkDone34Row(item)) {
        rowEl.classList.add("row-blink-done34");
      }
      if (shouldBlinkWashDryOvertimeRow(item)) {
        rowEl.classList.add("row-blink-washdry-overtime");
      }
    }

    var numEl = rowEl.querySelector(".number");
    if (numEl) {
      numEl.textContent = car;
      // Оплаченный заказ: выделяем номер машины квадратным бейджем.
      numEl.classList.toggle("number--paid-square", headerOrderIsPaid(disp));
    }
    var svcEl = rowEl.querySelector(".service");
    svcEl.textContent = service;
    if (item.__tvIsGroup && String(service).indexOf("\n") >= 0) {
      svcEl.classList.add("service--multi");
    } else {
      svcEl.classList.remove("service--multi");
    }
    rowEl.querySelector(".table").textContent = table
      ? tr("post_prefix") + " " + table
      : tr("post_prefix") + " " + tr("post_empty");
    rowEl.querySelector(".time").textContent = formatRowTimeDisplay(
      item,
      isQueued,
      lastAllItems,
      maxWashSlots
    );

    var iconEl = rowEl.querySelector(".status-icon");
    if (iconEl) {
      var iconUrl = resolveStatusIconUrl(disp, isQueued);
      if (iconUrl) {
        iconEl.src = iconUrl;
        iconEl.style.display = "";
        iconEl.removeAttribute("aria-hidden");
      } else {
        iconEl.style.display = "none";
        iconEl.setAttribute("aria-hidden", "true");
      }
    }

    rowEl.__tvOrder = item;
  }

  function updateColumn(container, cache, order, items, isQueued) {
    if (!container) return;
    logDebug("column.update.start", {
      column: isQueued ? "pending" : "inProgress",
      incoming: items.length,
      limit: MAX_ROWS_PER_COLUMN
    });

    var limited = items.slice(0, MAX_ROWS_PER_COLUMN);
    if (!limited.length) {
      for (var i = 0; i < order.length; i++) delete cache[order[i]];
      order.length = 0;
      setEmptyState(container);
      logDebug("column.update.empty", { column: isQueued ? "pending" : "inProgress" });
      return;
    }

    var nextKeys = Object.create(null);
    for (var j = 0; j < limited.length; j++) {
      var item = limited[j] || {};
      var key = getKey(item, j);
      nextKeys[key] = true;
      if (!cache[key]) {
        cache[key] = createRow(item, isQueued);
      } else {
        patchRow(cache[key], item, isQueued);
      }
    }

    for (var k = 0; k < order.length; k++) {
      if (!nextKeys[order[k]]) delete cache[order[k]];
    }

    container.textContent = "";
    var frag = document.createDocumentFragment();
    order.length = 0;
    for (var n = 0; n < limited.length; n++) {
      var keyN = getKey(limited[n] || {}, n);
      order.push(keyN);
      frag.appendChild(cache[keyN]);
    }
    container.appendChild(frag);
    logDebug("column.update.done", {
      column: isQueued ? "pending" : "inProgress",
      rendered: limited.length
    });
  }

  function tryDecodeProcessListPayload(json) {
    // WebHttpQuery returns like: { status: 1, data: [ "<json string>" ] }
    // Flutter: jsonDecode(queryResult['data'][0])['data']
    if (!json) return [];
    if (json.status === 1 && Array.isArray(json.data)) return json.data;
    if (json.status === 1 && json.data && Array.isArray(json.data.data)) return json.data.data;
    if (Array.isArray(json)) return json;
    if (Array.isArray(json.data)) {
      if (json.data.length === 0) return [];

      var first = json.data[0];
      if (typeof first === "string") {
        try {
          var decoded = JSON.parse(first);
          if (decoded && Array.isArray(decoded.data)) return decoded.data;
          if (decoded && Array.isArray(decoded)) return decoded;
          if (decoded && decoded.data && Array.isArray(decoded.data.data)) return decoded.data.data;
        } catch (e) {
          // ignore
        }
      }
      if (typeof first === "object" && first) {
        if (Array.isArray(first.data)) return first.data;
        if (Array.isArray(first)) return first;
      }
    }

    // Some backends might directly return the array.
    if (json && Array.isArray(json.orders)) return json.orders;
    if (json && Array.isArray(json.items)) return json.items;
    return [];
  }

  function tryExtractTablesCount(json) {
    function len(v) {
      return Array.isArray(v) ? v.length : 0;
    }
    if (!json) return 0;
    if (len(json.tables) > 0) return len(json.tables);
    if (json.data) {
      if (len(json.data.tables) > 0) return len(json.data.tables);
      if (Array.isArray(json.data) && json.data.length > 0) {
        var first = json.data[0];
        if (first && typeof first === "object") {
          if (len(first.tables) > 0) return len(first.tables);
          if (len(first.data && first.data.tables) > 0) return len(first.data.tables);
        }
        if (typeof first === "string") {
          try {
            var decoded = JSON.parse(first);
            if (len(decoded.tables) > 0) return len(decoded.tables);
            if (len(decoded.data && decoded.data.tables) > 0) return len(decoded.data.tables);
          } catch (e) {
            // ignore
          }
        }
      }
    }
    return 0;
  }

  function isWashTransition(status, substatus) {
    return Number(status) === 2 && Number(substatus) === 2;
  }

  /** Уникальные заказы (шапка) в 2/2: несколько строк o_goods_process = одна машина = один пост. */
  function countWashInProgress(items) {
    var seen = Object.create(null);
    var c = 0;
    for (var i = 0; i < items.length; i++) {
      var it = items[i] || {};
      var nw = normalizedProcessStatusSubstatus(it);
      if (nw.st !== 2 || nw.ss !== 2) continue;
      var k = headerKeyForRow(it);
      if (seen[k]) continue;
      seen[k] = true;
      c++;
    }
    return c;
  }

  /** Очередь 1/1: сортировка по времени входа (ogpStatusSubTime 1,1) — старые выше (FIFO). */
  function pendingQueueTimeMs(item) {
    var dObj = ogpDataStrict(item);
    var raw = dObj ? ogpStatusSubTime(dObj, 1, 1) : null;
    if (!dObj || raw == null || raw === "") {
      return Number.MAX_SAFE_INTEGER;
    }
    var d = parseDateAsUtcPlus4(raw);
    if (!d || isNaN(d.getTime())) return Number.MAX_SAFE_INTEGER;
    return d.getTime();
  }

  function sortPendingOldestFirst(pending) {
    var arr = pending.slice();
    arr.sort(function (a, b) {
      return pendingQueueTimeMs(a) - pendingQueueTimeMs(b);
    });
    return arr;
  }

  /** Ключ заказа: приоритет `f_header_id` (новый API), затем legacy `f_header`, иначе `f_id`. */
  function headerKeyForRow(row) {
    if (!row) return "id:0";
    var v = row.f_header_id != null ? row.f_header_id : row.f_header;
    var s = v != null ? String(v).trim() : "";
    if (s && s !== "0") return "h:" + s;
    return "id:" + String(processId(row) || "0");
  }

  /** Текст услуги для одной строки API (как в patchRow). */
  function serviceLabelFromRow(row) {
    if (!row) return "";
    var firstItem = null;
    if (Array.isArray(row.f_items) && row.f_items.length) firstItem = row.f_items[0];
    var service = "";
    if (firstItem) {
      var part = safeText(firstItem.f_part1name || firstItem.f_part2name || "");
      var dish = safeText(firstItem.f_dishname || firstItem.f_dish || "");
      service = (part + (part && dish ? " " : "") + dish).trim();
    }
    if (!service) service = safeText(row.f_name || row.f_goods_name || "");
    return service.trim();
  }

  /** Время входа в текущую фазу (st/ss) — для сортировки «в работе» по возрастанию. */
  function inProgressEnteredAtMs(item) {
    if (!item) return Number.MAX_SAFE_INTEGER;
    var n = normalizedProcessStatusSubstatus(item);
    var st = n.st;
    var ss = n.ss;
    var dObj = ogpDataStrict(item);
    var raw = ogpStatusSubTime(dObj, st, ss);
    if (raw == null || raw === "") return Number.MAX_SAFE_INTEGER;
    var d = parseDateAsUtcPlus4(raw);
    if (!d || isNaN(d.getTime())) return Number.MAX_SAFE_INTEGER;
    return d.getTime();
  }

  /**
   * Порядок на табло: сначала мойка (2/2), потом сушка (2/3), затем готово/парковка.
   * Иначе при сортировке только по времени сушка (вошла в фазу раньше по часам) оказывается выше мойки.
   */
  function inProgressPhaseRank(row) {
    if (!row) return 99;
    var n = normalizedProcessStatusSubstatus(row);
    var st = n.st;
    var ss = n.ss;
    if (st === 2 && ss === 2) return 0;
    if (st === 2 && ss === 3) return 1;
    if (st === 3 && ss === 4) return 2;
    if (st === 3 && ss === 5) return 3;
    return 50;
  }

  function inProgressSortKeyForItem(item) {
    var row = item && item.__tvRepresentative ? item.__tvRepresentative : item;
    return {
      rank: inProgressPhaseRank(row),
      t: inProgressEnteredAtMs(row)
    };
  }

  function compareInProgressItems(a, b) {
    var ka = inProgressSortKeyForItem(a);
    var kb = inProgressSortKeyForItem(b);
    if (ka.rank !== kb.rank) return ka.rank - kb.rank;
    return ka.t - kb.t;
  }

  function sortInProgressAscending(list) {
    var arr = list.slice();
    arr.sort(compareInProgressItems);
    return arr;
  }

  function pendingGroupSortKeyMs(item) {
    if (item && item.__tvLines && item.__tvLines.length) {
      var m = Number.MAX_SAFE_INTEGER;
      for (var i = 0; i < item.__tvLines.length; i++) {
        m = Math.min(m, pendingQueueTimeMs(item.__tvLines[i]));
      }
      return m;
    }
    return pendingQueueTimeMs(item);
  }

  function sortPendingGroupsOldestFirst(groups) {
    var arr = groups.slice();
    arr.sort(function (a, b) {
      return pendingGroupSortKeyMs(a) - pendingGroupSortKeyMs(b);
    });
    return arr;
  }

  function sortInProgressGroupsAscending(groups) {
    var arr = groups.slice();
    arr.sort(compareInProgressItems);
    return arr;
  }

  /**
   * Несколько строк `o_goods_process` с одним шапочным id — один заказ, одна карточка.
   * Статус меняется для каждой строки последовательно (postStatusChange).
   */
  function groupRowsByHeader(rows, pickPrimary) {
    var map = Object.create(null);
    for (var i = 0; i < rows.length; i++) {
      var r = rows[i] || {};
      var k = headerKeyForRow(r);
      if (!map[k]) map[k] = [];
      map[k].push(r);
    }
    var keys = Object.keys(map);
    var out = [];
    for (var j = 0; j < keys.length; j++) {
      var lines = map[keys[j]];
      if (lines.length === 1) {
        out.push(lines[0]);
        continue;
      }
      lines.sort(function (a, b) {
        var sa = String(processId(a) || "");
        var sb = String(processId(b) || "");
        var na = parseInt(sa, 10);
        var nb = parseInt(sb, 10);
        if (!isNaN(na) && !isNaN(nb) && na !== nb) return na - nb;
        return sa.localeCompare(sb);
      });
      var primary = pickPrimary ? pickPrimary(lines) : lines[0];
      var parts = [];
      for (var p = 0; p < lines.length; p++) {
        var lbl = serviceLabelFromRow(lines[p]);
        if (lbl) parts.push(lbl);
      }
      var combined = parts.length ? parts.join("\n") : tr("service_default");
      var merged = Object.assign({}, primary);
      merged.__tvIsGroup = true;
      merged.__tvLines = lines.slice();
      merged.__tvLineIds = lines.map(processId);
      merged.__tvRepresentative = primary;
      merged.__tvCombinedService = combined;
      out.push(merged);
    }
    return out;
  }

  function pickPrimaryPending(lines) {
    var best = lines[0];
    var bestT = pendingQueueTimeMs(best);
    for (var i = 1; i < lines.length; i++) {
      var t = pendingQueueTimeMs(lines[i]);
      if (t < bestT) {
        bestT = t;
        best = lines[i];
      }
    }
    return best;
  }

  function pickPrimaryInProgress(lines) {
    var best = lines[0];
    var bestT = inProgressEnteredAtMs(best);
    for (var i = 1; i < lines.length; i++) {
      var t = inProgressEnteredAtMs(lines[i]);
      if (t < bestT) {
        bestT = t;
        best = lines[i];
      }
    }
    return best;
  }

  /** Строки заказа для смены статуса (сырой объект или группа). */
  function linesForOrderAction(order) {
    if (order && order.__tvLines && order.__tvLines.length) return order.__tvLines;
    return [order];
  }

  /** Сколько постов мойки занимает переход: один заказ = одна машина = 1 (не число строк заказа). */
  function countLinesEnteringWash(order, status, substatus) {
    if (!(Number(status) === 2 && Number(substatus) === 2)) return 0;
    var lines = linesForOrderAction(order);
    var c = 0;
    for (var i = 0; i < lines.length; i++) {
      var st = processStatus(lines[i]);
      var ss = processSubstatus(lines[i]);
      if (!(st === 2 && ss === 2)) c++;
    }
    return c > 0 ? 1 : 0;
  }

  function effectiveRowForDisplay(item) {
    if (item && item.__tvRepresentative) return item.__tvRepresentative;
    return item;
  }

  /** Минуты по строке API (json_value … f_cooking_time); иначе washtime+drytime из ogp.f_data. */
  function cookingMinutesFromRow(item) {
    if (!item) return 15;
    var n = Number(item.f_cooking_time);
    if (!isNaN(n) && n > 0) return n;
    var dObj = ogpDataStrict(item);
    if (!dObj) return 15;
    var sum =
      (Number(dObj.f_washtime) || 0) + (Number(dObj.f_drytime) || 0);
    return sum > 0 ? sum : 15;
  }

  function formatHmFromMs(ms) {
    var d = new Date(ms);
    if (isNaN(d.getTime())) return "--:--";
    var hh = d.getHours();
    var mm = d.getMinutes();
    return (hh < 10 ? "0" + hh : "" + hh) + ":" + (mm < 10 ? "0" + mm : "" + mm);
  }

  function minutesSinceOgpPair(item, st, ss) {
    var dObj = ogpDataStrict(item);
    if (!dObj) return null;
    var raw = ogpStatusSubTime(dObj, st, ss);
    var d = parseDateAsUtcPlus4(raw);
    if (!d || isNaN(d.getTime())) return null;
    return (Date.now() - d.getTime()) / 60000;
  }

  /**
   * Момент освобождения бокса этим авто (статус 2): конец мойки/сушки по времени в ogp.
   * Учитывает оставшееся время, а не «полный cook с начала», если фаза уже идёт.
   */
  function projectedBayFreeMsActiveWash(item, nowMs) {
    var nWash = normalizedProcessStatusSubstatus(item);
    if (nWash.st !== 2) return null;
    var dObj = ogpDataStrict(item);
    if (!dObj) return null;
    var ss = nWash.ss;
    var cook = cookingMinutesFromRow(item);
    var washM = Number(dObj.f_washtime) || 0;
    var dryM = Number(dObj.f_drytime) || 0;
    var t22 = parseDateAsUtcPlus4(ogpStatusSubTime(dObj, 2, 2));
    var t23 = parseDateAsUtcPlus4(ogpStatusSubTime(dObj, 2, 3));

    if (t22 && !isNaN(t22.getTime())) {
      var endWashDry = t22.getTime() + cook * 60000;
      if (ss === 2) {
        return Math.max(nowMs, endWashDry);
      }
      // 2/3 сушка: конец = начало сушки + доля dry
      if (t23 && !isNaN(t23.getTime())) {
        var dryMin =
          dryM > 0
            ? dryM
            : washM + dryM > 0
              ? Math.max(0, cook - washM)
              : Math.max(0, cook - (nowMs - t22.getTime()) / 60000);
        if (dryMin <= 0) dryMin = cook * 0.4;
        return Math.max(nowMs, t23.getTime() + dryMin * 60000);
      }
      return Math.max(nowMs, endWashDry);
    }

    if (t23 && !isNaN(t23.getTime())) {
      var dm =
        dryM > 0
          ? dryM
          : washM + dryM > 0
            ? Math.max(0, cook - washM)
            : cook;
      if (dm <= 0) dm = cook;
      return Math.max(nowMs, t23.getTime() + dm * 60000);
    }

    // Нет времён в ogp — консервативно: ещё cook минут с текущего момента
    return nowMs + cook * 60000;
  }

  /**
   * Состояние боксов: для каждого заказа со статусом 2 — время освобождения;
   * распределяем по B постам (минимальная загрузка), чтобы учесть несколько машин в мойке сразу.
   */
  function buildBayNextFreeMs(allItems, bayCount, nowMs) {
    var B = Math.max(1, bayCount | 0);
    var jobs = [];
    for (var i = 0; i < allItems.length; i++) {
      if (normalizedProcessStatusSubstatus(allItems[i]).st !== 2) continue;
      var t = projectedBayFreeMsActiveWash(allItems[i], nowMs);
      if (t != null && isFinite(t)) jobs.push(t);
    }
    jobs.sort(function (a, b) {
      return a - b;
    });
    var heap = [];
    for (var k = 0; k < B; k++) heap.push(nowMs);
    for (var j = 0; j < jobs.length; j++) {
      var freeAt = jobs[j];
      var minI = 0;
      for (var b = 1; b < B; b++) {
        if (heap[b] < heap[minI]) minI = b;
      }
      heap[minI] = Math.max(heap[minI], freeAt);
    }
    return heap;
  }

  /** FIFO + занятость боксов: время старта для позиции в очереди 1/1. */
  function scheduledStartMsForQueueItem(item, allItems, bayCount) {
    var B = Math.max(1, bayCount | 0);
    var pending = sortPendingOldestFirst(
      allItems.filter(function (it) {
        return processStatus(it) === 1 && processSubstatus(it) === 1;
      })
    );
    var idx = -1;
    var myId = processId(item);
    for (var pi = 0; pi < pending.length; pi++) {
      if (String(processId(pending[pi])) === String(myId)) {
        idx = pi;
        break;
      }
    }
    if (idx < 0) return null;
    var nowMs = Date.now();
    var heap = buildBayNextFreeMs(allItems, B, nowMs);
    for (var q = 0; q <= idx; q++) {
      var cookMs = cookingMinutesFromRow(pending[q]) * 60000;
      var minI = 0;
      for (var b = 1; b < heap.length; b++) {
        if (heap[b] < heap[minI]) minI = b;
      }
      var startMs = heap[minI];
      if (q === idx) return startMs;
      heap[minI] = startMs + cookMs;
    }
    return null;
  }

  function formatElapsedParts(mins) {
    mins = Math.floor(mins);
    if (!isFinite(mins) || mins < 0) mins = 0;
    var d = Math.floor(mins / 1440);
    var h = Math.floor((mins % 1440) / 60);
    var m = mins % 60;
    if (d > 0) return tr("time_elapsed_dh", { d: d, h: h });
    if (h > 0) return tr("time_elapsed_hm", { h: h, m: m });
    return tr("time_elapsed_m", { m: mins });
  }

  /**
   * Колонка времени в строке:
   * 1/1, 2/2, 2/3 — окно из f_ogp_data.f_cooking_start/f_cooking_end (задаётся при принятии заказа);
   * 3/4 — минуты до мигания (40 − время в статусе);
   * >2 (кроме 3/4) — сколько осталось до завершения по f_cooking_end.
   * Без f_cooking_start/f_cooking_end для 1/* и 2/* показываем "--:--" (без локального авто-расчёта).
   */
  function formatRowTimeDisplay(item, isQueued, allItems, maxSlots) {
    if (!item) return "--:--";
    var pair = statusSubForDisplay(item);
    var st = pair.st;
    var ss = pair.ss;
    var se = rowStartEndForDisplay(item);

    if (st === 1 && ss === 1 && isQueued) {
      if (!(se && se.start && se.end)) return "--:--";
      return (
        tr("time_start_in") +
        " " +
        formatHmFromMs(se.start.getTime()) +
        " — " +
        formatHmFromMs(se.end.getTime())
      );
    }

    if (st === 2 && (ss === 2 || ss === 3)) {
      if (!(se && se.start && se.end)) return "--:--";
      var leftM2 = (se.end.getTime() - Date.now()) / 60000;
      var leftMin2 = Math.max(0, Math.ceil(leftM2));
      return tr("time_left_prefix") + tr("time_elapsed_m", { m: leftMin2 });
    }

    if (st === 3 && ss === 4) {
      var m34 = minutesSinceEnteredDone34(item);
      if (m34 == null || !isFinite(m34)) return "--:--";
      var left = DONE34_BLINK_AFTER_MINUTES - m34;
      if (left <= 0) return tr("time_blink_now");
      return tr("time_until_blink", { min: Math.max(1, Math.ceil(left)) });
    }

    if (st > 2) {
      if (!(se && se.end)) return "--:--";
      var leftM = (se.end.getTime() - Date.now()) / 60000;
      var leftMin = Math.max(0, Math.ceil(leftM));
      return tr("time_left_prefix") + tr("time_elapsed_m", { m: leftMin });
    }

    return "--:--";
  }

  function splitByProgress(items) {
    // «Ожидают» — только 1/1. Рассинхрон 1/3 и т.п. после нормализации уходит в «В работе».
    var inProgress = [];
    var pending = [];
    for (var i = 0; i < items.length; i++) {
      var item = items[i] || {};
      var n = normalizedProcessStatusSubstatus(item);
      var st = n.st;
      if (st === 1) pending.push(item);
      else if (st === 2 || st === 3) inProgress.push(item);
    }
    return { inProgress: inProgress, pending: sortPendingOldestFirst(pending) };
  }

  /** Мягкая фильтрация: не валим весь экран из-за одной плохой строки. */
  function isDisplayableRow(row) {
    if (!row || typeof row !== "object") return false;
    var st = processStatus(row);
    if (st === 1) return true;
    var ss = processSubstatus(row);
    if (st === 2) return ss === 2 || ss === 3;
    if (st === 3) return ss === 4 || ss === 5;
    return false;
  }

  function rowFilterReason(row) {
    if (!row || typeof row !== "object") return "row_not_object";
    var st = processStatus(row);
    var ss = processSubstatus(row);
    if (isNaN(st)) return "nan_status";
    if (st === 1) return "";
    if (st === 2 && (ss === 2 || ss === 3)) return "";
    if (st === 3 && (ss === 4 || ss === 5)) return "";
    return "unsupported_pair_" + String(st) + "/" + String(ss);
  }

  function markUpdated() {
    var now = new Date();
    var h = now.getHours();
    var m = now.getMinutes();
    var s = now.getSeconds();
    lastUpdateEl.textContent =
      (h < 10 ? "0" + h : h) + ":" +
      (m < 10 ? "0" + m : m) + ":" +
      (s < 10 ? "0" + s : s);
  }

  function doPost(url, bodyObj, timeoutMs, noAbort) {
    var useAbort = !noAbort && typeof AbortController !== "undefined";
    var ctrl = null;
    if (useAbort) {
      if (inFlightController) inFlightController.abort();
      inFlightController = new AbortController();
      ctrl = inFlightController;
    }

    var timeoutId = setTimeout(function () {
      if (ctrl) ctrl.abort();
    }, timeoutMs);

    var strBody = JSON.stringify(bodyObj);
    var fetchOpts = {
      method: "POST",
      cache: "no-store",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-Application-Name": "carwash",
        "X-Application-Version": "1.0.2",
        Authorization: "Bearer " + (settings.token || "")
      },
      body: strBody
    };
    logDebug("request.send", { url: url, bytes: strBody.length });
    if (ctrl) fetchOpts.signal = ctrl.signal;

    if (typeof fetch === "function") {
      return fetch(url, fetchOpts).then(function (res) {
        clearTimeout(timeoutId);
        logDebug("request.response", { status: res.status, ok: res.ok });
        if (!res.ok) throw new Error("HTTP " + res.status);
        return res.json();
      });
    }

    return new Promise(function (resolve, reject) {
      var xhr = new XMLHttpRequest();
      xhr.open("POST", url, true);
      xhr.setRequestHeader("Content-Type", "application/json");
      xhr.setRequestHeader("Accept", "application/json");
      xhr.setRequestHeader("X-Application-Name", "carwash");
      xhr.setRequestHeader("X-Application-Version", "1.0.2");
      xhr.setRequestHeader("Authorization", "Bearer " + (settings.token || ""));
      xhr.onreadystatechange = function () {
        if (xhr.readyState !== 4) return;
        clearTimeout(timeoutId);
        logDebug("request.response.xhr", { status: xhr.status });
        if (xhr.status < 200 || xhr.status >= 300) {
          reject(new Error("HTTP " + xhr.status));
          return;
        }
        try {
          resolve(JSON.parse(xhr.responseText));
        } catch (e) {
          reject(new Error("Invalid JSON"));
        }
      };
      xhr.onerror = function () {
        clearTimeout(timeoutId);
        reject(new Error("Network error"));
      };
      xhr.send(strBody);
    });
  }

  function fetchProcessList(url, timeoutMs) {
    return doPost(url, withAuthPayload({ f_menu: settings.f_menu }), timeoutMs, false);
  }

  function showSchemaError(result) {
    if (
      schemaErrorOverlayEl &&
      schemaErrorTitleEl &&
      schemaErrorLeadEl &&
      schemaErrorDetailEl
    ) {
      schemaErrorTitleEl.textContent = tr("err_schema_title");
      schemaErrorLeadEl.textContent = tr("err_schema_lead");
      try {
        schemaErrorDetailEl.textContent = JSON.stringify(result, null, 2);
      } catch (e) {
        schemaErrorDetailEl.textContent = String(result);
      }
      schemaErrorOverlayEl.style.display = "flex";
      schemaErrorOverlayEl.setAttribute("aria-hidden", "false");
    } else {
      setStatusLine(tr("err_schema_fallback"));
    }
  }

  function hideSchemaError() {
    if (schemaErrorOverlayEl) {
      schemaErrorOverlayEl.style.display = "none";
      schemaErrorOverlayEl.setAttribute("aria-hidden", "true");
    }
  }

  function closeActionModal() {
    if (overlayEl) {
      overlayEl.classList.remove("overlay--process-invalid");
      overlayEl.style.display = "none";
      overlayEl.setAttribute("aria-hidden", "true");
    }
  }

  function openActionModal(order) {
    if (!overlayEl || !dialogButtonsEl || !dialogTitleEl) return;
    overlayEl.classList.remove("overlay--process-invalid");
    var n0 = normalizedProcessStatusSubstatus(order);
    var st0 = n0.st;
    var ss0 = n0.ss;
    var pr = orderProgress(order);
    var rawInvalid = isRawProcessPairInvalid(order);
    var hdr = headerDataStrict(order) || {};
    var car = safeText(order.f_carnumber || order.f_car_number || hdr.f_car_number || "---");
    var boxNo = safeText(order.f_table || "").trim();
    dialogTitleEl.textContent =
      (rawInvalid ? tr("process_data_invalid_badge") + " " : "") +
      car +
      " · " +
      safeText(
        order.f_tablename ||
          order.f_table_name ||
          (boxNo ? "BOX " + boxNo : tr("post_empty"))
      );
    dialogButtonsEl.textContent = "";
    if (rawInvalid) {
      overlayEl.classList.add("overlay--process-invalid");
      var warn = document.createElement("p");
      warn.className = "dialog-invalid-hint";
      warn.textContent = tr("process_data_invalid");
      dialogButtonsEl.appendChild(warn);
    }

    function addBtn(label, handler, className) {
      var b = document.createElement("button");
      b.type = "button";
      b.className = "btn btn-block" + (className ? " " + className : "");
      b.textContent = label;
      b.onclick = function () {
        if (actionBusy) return;
        handler();
      };
      dialogButtonsEl.appendChild(b);
    }

    if (rawInvalid) {
      addBtn(
        tr("btn_fix_to_1_1"),
        function () {
          postStatusChange(order, 1, 1);
        },
        "btn-primary"
      );
    }

    // 1/1 → 2/2 или 2/3; 2/2 ↔ 2/3 ↔ 1 свободно; 2/2|2/3 → 3/4|3/5 как раньше
    if (pr === 2 || pr === 3) {
      addBtn(tr("btn_suspend"), function () {
        postStatusChange(order, 1, 1);
      });
    }
    if (pr === 1) {
      addBtn(tr("btn_wash"), function () {
        postStatusChange(order, 2, 2);
      });
      addBtn(tr("btn_dry"), function () {
        postStatusChange(order, 2, 3);
      });
    }
    if (pr === 2) {
      addBtn(tr("btn_dry"), function () {
        postStatusChange(order, 2, 3);
      });
      addBtn(tr("btn_done"), function () {
        postStatusChange(order, 3, 4);
      });
    }
    if (pr === 3) {
      addBtn(tr("btn_wash"), function () {
        postStatusChange(order, 2, 2);
      });
      addBtn(tr("btn_done"), function () {
        postStatusChange(order, 3, 4);
      });
      addBtn(tr("btn_parking"), function () {
        postStatusChange(order, 3, 5);
      });
    }
    if (pr === 4) {
      addBtn(tr("btn_parking"), function () {
        postStatusChange(order, 3, 5);
      });
    }
    if (Number(st0) === 3 && headerHasRealPayment(order)) {
      addBtn(tr("btn_deliver"), function () {
        postStatusChange(order, 4, 6);
      });
    }
    overlayEl.style.display = "flex";
    overlayEl.setAttribute("aria-hidden", "false");
  }

  function postStatusChange(order, status, substatus) {
    if (actionBusy) return;
    if (isWashTransition(status, substatus) && maxWashSlots > 0) {
      var currentWash = countWashInProgress(lastAllItems);
      var enteringWash = countLinesEnteringWash(order, status, substatus);
      var nextWash = currentWash + enteringWash;
      if (nextWash > maxWashSlots) {
        openLimitModal(tr("err_wash_limit", { max: maxWashSlots }));
        return;
      }
    }
    // Сушка 2/3: лимит по количеству постов в зале не применяем (см. dry в ответе API).
    if (archiveStatusRequiresPaidOrder(status, substatus)) {
      if (headerOrderUnpaid(order)) {
        openLimitModal(
          tr("err_payment_required_archive_only"),
          "payment_required_title"
        );
        return;
      }
    }
    var nFrom = normalizedProcessStatusSubstatus(order);
    var fromLabel = statusLabel(nFrom.st, nFrom.ss);
    var toLabel = statusLabel(status, substatus);
    askStatusChangeConfirm(fromLabel, toLabel).then(function (ok) {
      if (!ok) {
        closeActionModal();
        return;
      }
      actionBusy = true;
      setStatusLine(tr("status_pending"));
      var ids = [];
      if (order.__tvLineIds && order.__tvLineIds.length) {
        ids = order.__tvLineIds.slice();
      } else {
        var one = processId(order);
        if (one != null && String(one).trim() !== "") ids = [one];
      }
      if (!ids.length) {
        logDebug("status.request.missing_id.keys", Object.keys(order || {}));
        logDebug("status.request.missing_id.order", order);
        setStatusLine(tr("err_status"));
        actionBusy = false;
        return;
      }

      function postNextId(idx) {
        if (idx >= ids.length) {
          actionBusy = false;
          closeActionModal();
          refresh();
          setStatusLine(tr("ok_status"));
          return;
        }
        var payload = withAuthPayload({
          id: ids[idx],
          status: status,
          substatus: substatus
        });
        logDebug("status.request", payload);
        doPost(STATUS_URL, payload, REQUEST_TIMEOUT_MS, true)
          .then(function (json) {
            logDebug("status.response", json);
            if (json && json.status === 1) {
              postNextId(idx + 1);
              return;
            }
            var msg =
              (json && (json.data || json.error || json.message)) || tr("err_status");
            setStatusLine(String(msg));
            actionBusy = false;
          })
          .catch(function (e) {
            logDebug("status.error", String(e && e.message ? e.message : e));
            setStatusLine(tr("err_status"));
            actionBusy = false;
          });
      }
      postNextId(0);
    });
  }

  function closePayModal() {
    if (payOverlayEl) {
      payOverlayEl.style.display = "none";
      payOverlayEl.setAttribute("aria-hidden", "true");
    }
    payWorkingOrder = null;
  }

  function openPayModal(order) {
    if (!payOverlayEl || !payMethodsEl || !payTotalEl || !payTitleEl) return;
    payWorkingOrder = cloneOrderForApi(order);
    var total = numAmt(payWorkingOrder.f_amounttotal);
    payWorkingOrder.f_amountcash = 0;
    payWorkingOrder.f_amountcard = 0;
    payWorkingOrder.f_amountidram = 0;
    payTitleEl.textContent = tr("pay_order_title", {
      car: safeText(order.f_carnumber),
      pay: tr("payment_word")
    });
    payTotalEl.textContent = String(total) + " ֏";

    function renderMethodButtons() {
      payMethodsEl.textContent = "";
      var methods = [
        { label: tr("pay_cash"), key: "f_amountcash" },
        { label: tr("pay_card"), key: "f_amountcard" },
        { label: tr("pay_idram"), key: "f_amountidram" }
      ];
      for (var i = 0; i < methods.length; i++) {
        var m = methods[i];
        var b = document.createElement("button");
        b.type = "button";
        b.className =
          numAmt(payWorkingOrder[m.key]) > 0 ? "btn btn-primary" : "btn";
        b.textContent = m.label;
        (function (key) {
          b.onclick = function () {
            payWorkingOrder.f_amountcash = 0;
            payWorkingOrder.f_amountcard = 0;
            payWorkingOrder.f_amountidram = 0;
            payWorkingOrder[key] = total;
            renderMethodButtons();
          };
        })(m.key);
        payMethodsEl.appendChild(b);
      }
    }
    renderMethodButtons();

    payOverlayEl.style.display = "flex";
    payOverlayEl.setAttribute("aria-hidden", "false");
  }

  function submitEndOrder() {
    if (!payWorkingOrder || actionBusy) return;
    if (
      numAmt(payWorkingOrder.f_amountcash) === 0 &&
      numAmt(payWorkingOrder.f_amountcard) === 0 &&
      numAmt(payWorkingOrder.f_amountidram) === 0
    ) {
      setStatusLine(tr("pick_payment_method"));
      return;
    }
    actionBusy = true;
    setStatusLine(tr("end_order_pending"));
    var body = withAuthPayload({
      f_id: payWorkingOrder.f_id,
      f_amountcash: numAmt(payWorkingOrder.f_amountcash),
      f_amountcard: numAmt(payWorkingOrder.f_amountcard),
      f_amountidram: numAmt(payWorkingOrder.f_amountidram)
    });
    doPost(END_ORDER_URL, body, REQUEST_TIMEOUT_MS, true)
      .then(function (json) {
        logDebug("end-order.response", json);
        closePayModal();
        refresh();
        setStatusLine(tr("ok_payment"));
      })
      .catch(function (e) {
        logDebug("end-order.error", String(e && e.message ? e.message : e));
        setStatusLine(tr("err_payment"));
      })
      .then(function () {
        actionBusy = false;
      });
  }

  function wireActionUi() {
    var refreshBtn = document.getElementById("btn-refresh");
    if (refreshBtn) {
      refreshBtn.addEventListener("click", function () {
        refresh();
      });
      refreshBtn.addEventListener("keydown", function (ev) {
        if (ev.key === "Enter" || ev.key === " ") {
          ev.preventDefault();
          refresh();
        }
      });
    }
    var logoutBtn = document.getElementById("btn-logout");
    if (logoutBtn) {
      logoutBtn.addEventListener("click", function () {
        if (refreshTimerId != null) {
          clearInterval(refreshTimerId);
          refreshTimerId = null;
        }
        clearStaleSession();
        location.reload();
      });
    }
    if (dialogCloseEl) {
      dialogCloseEl.onclick = function () {
        closeActionModal();
      };
    }
    if (overlayEl) {
      overlayEl.onclick = function (e) {
        if (e.target === overlayEl) closeActionModal();
      };
    }
    if (payCancelEl) payCancelEl.onclick = closePayModal;
    if (payConfirmEl) payConfirmEl.onclick = submitEndOrder;
    if (payOverlayEl) {
      payOverlayEl.onclick = function (e) {
        if (e.target === payOverlayEl) closePayModal();
      };
    }
    if (limitCloseEl) {
      limitCloseEl.onclick = closeLimitModal;
    }
    if (limitOverlayEl) {
      limitOverlayEl.onclick = function (e) {
        if (e.target === limitOverlayEl) closeLimitModal();
      };
    }
    if (paymentRequiredOkEl) {
      paymentRequiredOkEl.onclick = function (ev) {
        if (ev) {
          ev.preventDefault();
          ev.stopPropagation();
        }
        closePaymentRequiredModal();
      };
    }
    if (paymentRequiredOverlayEl) {
      paymentRequiredOverlayEl.onclick = function (e) {
        if (e.target === paymentRequiredOverlayEl) closePaymentRequiredModal();
      };
    }
    if (schemaErrorRefreshEl) {
      schemaErrorRefreshEl.addEventListener("click", function () {
        hideSchemaError();
        refresh();
      });
    }

    function onListClick(ev) {
      var row = ev.target.closest ? ev.target.closest(".row") : null;
      if (!row || !row.__tvOrder) return;
      var o = row.__tvOrder;
      if (needsPaymentRequiredNotice(o)) {
        openPaymentRequiredModal(o);
        return;
      }
      openActionModal(o);
    }
    function onListKey(ev) {
      if (ev.keyCode !== 13 && ev.which !== 13) return;
      var row = ev.target;
      if (!row.classList || !row.classList.contains("row")) return;
      if (!row.__tvOrder) return;
      var o = row.__tvOrder;
      if (needsPaymentRequiredNotice(o)) {
        openPaymentRequiredModal(o);
        return;
      }
      openActionModal(o);
    }
    if (activeListEl) {
      activeListEl.addEventListener("click", onListClick);
      activeListEl.addEventListener("keydown", onListKey);
    }
    if (queuedListEl) {
      queuedListEl.addEventListener("click", onListClick);
      queuedListEl.addEventListener("keydown", onListKey);
    }
  }

  function refresh() {
    fetchProcessList(API_URL, REQUEST_TIMEOUT_MS)
      .then(function (json) {
        logDebug("response.raw", json);
        var all = tryDecodeProcessListPayload(json);
        lastAllItems = Array.isArray(all) ? all : [];
        maxWashSlots = tryExtractTablesCount(json);
        logDebug("response.parsedList", {
          count: all.length,
          first: all.length ? all[0] : null,
          tables: maxWashSlots
        });
        if (DEBUG_LOG && typeof console !== "undefined") {
          try {
            console.log("[tv] response.allItems.full", all);
            for (var ii = 0; ii < all.length; ii++) {
              console.log("[tv] response.item[" + ii + "]", all[ii]);
            }
          } catch (e) {
            // ignore
          }
        }
        var vr = validateProcessListRows(all);
        if (!vr.ok) {
          // Не блокируем UI целиком: отбрасываем только неподходящие строки.
          logDebug("response.schema_invalid_soft", vr);
        } else {
          hideSchemaError();
        }
        var cleaned = [];
        for (var ci = 0; ci < all.length; ci++) {
          var r = all[ci];
          var reason = rowFilterReason(r);
          if (!reason) {
            cleaned.push(r);
          } else if (DEBUG_LOG && typeof console !== "undefined") {
            try {
              console.warn("[tv] row.filtered_out", {
                index: ci,
                reason: reason,
                f_id: r && r.f_id,
                f_header_id: r && r.f_header_id,
                f_status: r && r.f_status,
                f_substatus: r && (asObj(r.f_ogp_data) || {}).f_substatus
              });
            } catch (e) {
              // ignore
            }
          }
        }
        if (DEBUG_LOG && typeof console !== "undefined") {
          try {
            console.log("[tv] rows.summary", {
              total: all.length,
              displayable: cleaned.length,
              pending_by_status: cleaned.filter(function (x) { return processStatus(x) === 1; }).length,
              in_progress_by_status: cleaned.filter(function (x) { var s = processStatus(x); return s === 2 || s === 3; }).length
            });
          } catch (e) {
            // ignore
          }
        }
        lastAllItems = cleaned;
        var split = splitByProgress(cleaned);
        var pendingGrouped = groupRowsByHeader(split.pending, pickPrimaryPending);
        var pendingDisplay = sortPendingGroupsOldestFirst(pendingGrouped);
        var inProgSorted = sortInProgressAscending(split.inProgress);
        var inProgGrouped = groupRowsByHeader(inProgSorted, pickPrimaryInProgress);
        var inProgDisplay = sortInProgressGroupsAscending(inProgGrouped);
        logDebug("response.split", {
          inProgress: inProgDisplay.length,
          pending: pendingDisplay.length,
          inProgressRows: split.inProgress.length,
          pendingRows: split.pending.length
        });
        if (DEBUG_LOG && typeof console !== "undefined") {
          try {
            console.log("[tv] response.inProgress.display", inProgDisplay);
            console.log("[tv] response.pending.display", pendingDisplay);
          } catch (e) {
            // ignore
          }
        }
        if (window.carwashBayBoard && window.carwashBayBoard.render) {
          window.carwashBayBoard.render(cleaned, bayTimeFromPayload(json));
        }
        updateColumn(activeListEl, activeCache, activeOrder, inProgDisplay, false);
        updateColumn(queuedListEl, queuedCache, queuedOrder, pendingDisplay, true);
        markUpdated();
        setStatusLine(
          tr("ok_counts", {
            inProgress: inProgDisplay.length,
            pending: pendingDisplay.length
          })
        );
      })
      .catch(function (err) {
        // Keep previous data on network errors, only update timestamp when successful.
        var em = String(err && err.message ? err.message : err);
        logDebug("refresh.error", em);
        setStatusLine(tr("err_api", { msg: em, api: API_URL }));
      });
  }

  function loadSessionKeyFromFile() {
    // Allows placing key into static file for TVs.
    // If TV can't read file, we just keep whatever came from URL/localStorage.
    if (typeof fetch === "function") {
      return fetch("./tvkey.txt", { method: "GET", cache: "no-store" })
        .then(function (res) {
          logDebug("tvkey.fetch.response", { status: res.status, ok: res.ok });
          if (!res.ok) return null;
          return res.text();
        })
        .then(function (txt) {
          if (!txt) return null;
          var s = String(txt).replace(/^\s+|\s+$/g, "");
          logDebug("tvkey.fetch.value", { hasKey: !!s, keyLen: s ? s.length : 0 });
          return s || null;
        })
        .catch(function () {
          logDebug("tvkey.fetch.error");
          return null;
        });
    }

    return new Promise(function (resolve) {
      var xhr = new XMLHttpRequest();
      xhr.open("GET", "./tvkey.txt", true);
      xhr.onreadystatechange = function () {
        if (xhr.readyState !== 4) return;
        if (xhr.status < 200 || xhr.status >= 300) {
          logDebug("tvkey.fetch.response.xhr", { status: xhr.status });
          resolve(null);
          return;
        }
        var s = String(xhr.responseText || "").replace(/^\s+|\s+$/g, "");
        logDebug("tvkey.fetch.value.xhr", { hasKey: !!s, keyLen: s ? s.length : 0 });
        resolve(s || null);
      };
      xhr.onerror = function () {
        logDebug("tvkey.fetch.error.xhr");
        resolve(null);
      };
      xhr.send(null);
    });
  }

  function start() {
    if (appStarted) return;
    appStarted = true;
    logDebug("app.start", { autoRefresh: wantsAutoRefresh() });
    wireActionUi();
    setStatusLine(tr("loading"));
    setEmptyState(activeListEl);
    setEmptyState(queuedListEl);
    refresh();
    scheduleAutoRefresh();
    if (typeof window !== "undefined" && window.addEventListener) {
      window.addEventListener("resize", scheduleAutoRefresh);
    }
  }

  (function initApp() {
    if (typeof window.tvI18n !== "undefined" && window.tvI18n.applyDom) {
      window.tvI18n.applyDom();
      syncI18nToSettings();
    }
    logDebug("app.init", { loginUrl: LOGIN_URL, locale: window.tvI18n ? window.tvI18n.locale : "" });
    wireLoginUi();

    var qToken = getQueryParam("token");
    if (qToken) {
      settings.token = qToken;
      safeLocalStorageSet("token", qToken);
      logDebug("session.source", "url-token");
      hideLoginOverlay();
      start();
      return;
    }

    var p = Promise.resolve();
    if (getQueryParam("tvkey") === "1") {
      p = loadSessionKeyFromFile().then(function (fileKey) {
        if (fileKey) {
          settings.sessionkey = fileKey;
          safeLocalStorageSet("sessionkey", fileKey);
          logDebug("session.source", "tvkey.txt");
        }
      });
    }

    p.then(function () {
      return tryRestoreSession();
    }).then(function (res) {
      if (res && res.ok) {
        hideLoginOverlay();
        start();
        return;
      }
      if (res && res.clearKey) clearStaleSession();
      showLoginOverlay();
    });
  })();
})();
