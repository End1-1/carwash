(function (global) {
  "use strict";

  function getQueryParam(name) {
    var q = global.location.search || "";
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

  function lsGet(key) {
    try {
      if (!global.localStorage) return null;
      return global.localStorage.getItem(key);
    } catch (e) {
      return null;
    }
  }

  function lsSet(key, val) {
    try {
      if (!global.localStorage) return;
      global.localStorage.setItem(key, val);
    } catch (e) {
      // ignore
    }
  }

  var STRINGS = {
    ru: {
      app_title: "Carwash Status",
      logout: "Выйти",
      logout_aria: "Выйти из аккаунта",
      refresh: "Обновить",
      refresh_aria: "Обновить список",
      login_title: "Вход",
      pin_clear_aria: "Стереть",
      col_active: "В работе",
      col_pending: "Ожидают",
      dialog_close: "Закрыть",
      payment_word: "Оплата",
      pay_confirm: "Подтвердить",
      pay_cancel: "Закрыть",
      empty_no_data: "Нет данных",
      post_prefix: "Пост:",
      post_empty: "—",
      service_default: "Мойка",
      enter_pin: "Введите PIN",
      login_progress: "Вход…",
      status_ok_short: "ОК",
      error_login: "Ошибка: вход",
      network_error: "Сеть или сервер недоступны",
      login_error_fallback: "Ошибка входа",
      init_status: "инициализация…",
      loading: "Загрузка…",
      status_pending: "Статус…",
      ok_status: "Готово: статус",
      err_status: "Ошибка: статус",
      err_wash_limit: "Нельзя запустить мойку: заняты все посты ({max})",
      err_dry_limit: "Нельзя запустить сушку: заняты все боксы ({max})",
      dry_limit_title: "Все боксы сушки заняты",
      remove_pending: "Удаление…",
      ok_removed: "Готово: удалено",
      err_remove: "Ошибка: удаление",
      pick_payment_method: "Выберите способ оплаты",
      end_order_pending: "Завершение…",
      ok_payment: "Готово: оплата",
      err_payment: "Ошибка: оплата",
      ok_counts: "ОК: в работе {inProgress}, ожидают {pending}",
      err_api: "Ошибка: {msg} | api={api}",
      err_schema_title: "Ошибка контракта API",
      err_schema_lead:
        "Ожидаются поля строки: f_id, f_status, f_ogp_data; подстатус — внутри JSON в f_substatus (при f_status===1 без f_substatus считается 1). Допустимые пары: 1/1, 2/2, 2/3, 3/4, 3/5. Пожалуйста, свяжитесь с разработчиком приложения.",
      err_schema_short: "Контракт API: ошибка (см. экран)",
      err_schema_fallback: "Контракт API: ошибка (нет блока ошибки в разметке). См. консоль.",
      js_error_prefix: "Ошибка: ",
      btn_suspend: "Пауза",
      btn_wash: "Мойка",
      btn_dry: "Сушка",
      btn_done: "Выполнено",
      btn_parking: "Парковка",
      btn_deliver: "Отдать клиенту",
      btn_pay: "Оплата",
      btn_remove: "Удалить",
      status_archive_row: "Архив",
      status_change_confirm: "Изменить статус?",
      wash_limit_title: "Все боксы заняты",
      payment_required_title: "Требуется оплата",
      err_payment_required_archive_only:
        "Сначала оплатите заказ. Архив и удаление станут доступны после оплаты.",
      remove_confirm: "Удалить заказ?",
      pay_cash: "Наличные",
      pay_card: "Карта",
      pay_idram: "Idram",
      pay_order_title: "{car} · {pay}",
      time_start_in: "Старт в",
      time_duration_prefix: "Длит. ",
      time_until_blink: "~{min} мин до мигания",
      time_blink_now: "Мигание",
      time_left_prefix: "Осталось: ",
      time_parking_prefix: "до паркинга: ",
      time_elapsed_dh: "{d}д {h}ч",
      time_elapsed_hm: "{h}ч {m}мин",
      time_elapsed_m: "{m} мин",
      process_data_invalid_badge: "⚠",
      process_data_invalid:
        "В строке процесса недопустимая пара статус/подстатус (рассинхрон с сервером). Можно принудительно выставить «очередь 1/1» или дальше менять стадии — проверьте данные в админке.",
      btn_fix_to_1_1: "В очередь 1/1 (исправить)"
    },
    en: {
      app_title: "Carwash Status",
      logout: "Log out",
      logout_aria: "Log out",
      refresh: "Refresh",
      refresh_aria: "Refresh list",
      login_title: "Sign in",
      pin_clear_aria: "Backspace",
      col_active: "In progress",
      col_pending: "Waiting",
      dialog_close: "Close",
      payment_word: "Payment",
      pay_confirm: "Confirm",
      pay_cancel: "Close",
      empty_no_data: "No data",
      post_prefix: "Bay:",
      post_empty: "—",
      service_default: "Wash",
      enter_pin: "Enter PIN",
      login_progress: "Signing in…",
      status_ok_short: "OK",
      error_login: "Error: sign-in",
      network_error: "Network or server unavailable",
      login_error_fallback: "Sign-in error",
      init_status: "initializing…",
      loading: "Loading…",
      status_pending: "Status…",
      ok_status: "Done: status",
      err_status: "Error: status",
      err_wash_limit: "Cannot start wash: all bays are busy ({max})",
      err_dry_limit: "Cannot start drying: all drying bays are busy ({max})",
      dry_limit_title: "All drying bays are busy",
      remove_pending: "Removing…",
      ok_removed: "Done: removed",
      err_remove: "Error: remove",
      pick_payment_method: "Select payment method",
      end_order_pending: "Completing…",
      ok_payment: "Done: payment",
      err_payment: "Error: payment",
      ok_counts: "OK: in progress {inProgress}, waiting {pending}",
      err_api: "Error: {msg} | api={api}",
      err_schema_title: "API contract error",
      err_schema_lead:
        "Each row must include f_id, f_status, f_ogp_data; substatus is JSON.f_substatus (if f_status===1 and f_substatus is absent, use 1). Allowed pairs: 1/1, 2/2, 2/3, 3/4, 3/5. Please contact the application developer.",
      err_schema_short: "API contract error (see dialog)",
      err_schema_fallback: "API contract error (no error overlay in markup). See console.",
      js_error_prefix: "Error: ",
      btn_suspend: "Suspend",
      btn_wash: "Wash",
      btn_dry: "Dry",
      btn_done: "Done",
      btn_parking: "Parking",
      btn_deliver: "Deliver to client",
      btn_pay: "Payment",
      btn_remove: "Remove",
      status_archive_row: "Archive",
      status_change_confirm: "Change status?",
      wash_limit_title: "All bays are busy",
      payment_required_title: "Payment required",
      err_payment_required_archive_only:
        "Please pay the order first. Archive and remove are available after payment.",
      remove_confirm: "Remove order?",
      pay_cash: "Cash",
      pay_card: "Card",
      pay_idram: "Idram",
      pay_order_title: "{car} · {pay}",
      time_start_in: "Start at",
      time_duration_prefix: "Dur. ",
      time_until_blink: "~{min} min until alert",
      time_blink_now: "Alert",
      time_left_prefix: "Left: ",
      time_parking_prefix: "To parking: ",
      time_elapsed_dh: "{d}d {h}h",
      time_elapsed_hm: "{h}h {m}m",
      time_elapsed_m: "{m} min",
      process_data_invalid_badge: "⚠",
      process_data_invalid:
        "Invalid status/substatus pair (server data out of sync). You can force «queue 1/1» or keep changing stages — check data in admin.",
      btn_fix_to_1_1: "Queue 1/1 (fix)"
    },
    hy: {
      app_title: "Carwash Status",
      logout: "Ելք",
      logout_aria: "Ելք",
      refresh: "Թարմացնել",
      refresh_aria: "Թարմացնել ցուցակը",
      login_title: "Մուտք",
      pin_clear_aria: "Ջնջել",
      col_active: "Աշխատանքում",
      col_pending: "Սպասում են",
      dialog_close: "Փակել",
      payment_word: "Վճարում",
      pay_confirm: "Հաստատել",
      pay_cancel: "Փակել",
      empty_no_data: "Տվյալներ չկան",
      post_prefix: "Կայան:",
      post_empty: "—",
      service_default: "Լվացում",
      enter_pin: "Մուտքագրեք PIN",
      login_progress: "Մուտք…",
      status_ok_short: "OK",
      error_login: "Սխալ: մուտք",
      network_error: "Ցանցը կամ սերվերը հասանելի չեն",
      login_error_fallback: "Մուտքի սխալ",
      init_status: "սկզբնավորում…",
      loading: "Բեռնում…",
      status_pending: "Կարգավիճակ…",
      ok_status: "Պատրաստ է: կարգավիճակ",
      err_status: "Սխալ: կարգավիճակ",
      err_wash_limit: "Չի կարելի սկսել լվացումը․ բոլոր կայանները զբաղված են ({max})",
      err_dry_limit: "Չի կարելի սկսել չորացումը․ բոլոր բոկսերը զբաղված են ({max})",
      dry_limit_title: "Չորացման բոլոր բոկսերը զբաղված են",
      remove_pending: "Հեռացում…",
      ok_removed: "Պատրաստ է: հեռացված",
      err_remove: "Սխալ: հեռացում",
      pick_payment_method: "Ընտրեք վճարման եղանակը",
      end_order_pending: "Ավարտում…",
      ok_payment: "Պատրաստ է: վճարում",
      err_payment: "Սխալ: վճարում",
      ok_counts: "OK: աշխատանքում {inProgress}, սպասում {pending}",
      err_api: "Սխալ: {msg} | api={api}",
      err_schema_title: "API պայմանագրի սխալ",
      err_schema_lead:
        "Յուրաքանչյուր տողում պահանջվում են f_id, f_status, f_ogp_data՝ ենթակարգավիճակը JSON-ի f_substatus-ում (եթե f_status===1 և f_substatus չկա՝ 1)։ Թույլատրելի զույգեր՝ 1/1, 2/2, 2/3, 3/4, 3/5։ Խնդրում ենք կապ հաստատել հավելվածի ծրագրավորողի հետ։",
      err_schema_short: "API պայմանագիր․ սխալ (տե՛ս էկրանը)",
      err_schema_fallback: "API պայմանագիր․ սխալ (չկա error overlay)։ Տե՛ս console։",
      js_error_prefix: "Սխալ: ",
      btn_suspend: "Սպասել",
      btn_wash: "Լվացում",
      btn_dry: "Չորացում",
      btn_done: "Կատարված",
      btn_parking: "Պարկինգ",
      btn_deliver: "Հանձնել հաճախորդին",
      btn_pay: "Վճարում",
      btn_remove: "Հեռացնել",
      status_archive_row: "Արխիվ",
      status_change_confirm: "Փոխե՞լ կարգավիճակը",
      wash_limit_title: "Բոլոր կայանները զբաղված են",
      payment_required_title: "Պահանջվում է վճարում",
      err_payment_required_archive_only:
        "Նախ վճարեք պատվերը։ Արխիվը և հեռացումը հասանելի կլինեն վճարումից հետո։",
      remove_confirm: "Հեռացնե՞լ",
      pay_cash: "Կանխիկ",
      pay_card: "Քարտ",
      pay_idram: "Idram",
      pay_order_title: "{car} · {pay}",
      time_start_in: "Մեկնարկը",
      time_duration_prefix: "Տևողություն․ ",
      time_until_blink: "~{min} ր մինչ կայանը",
      time_blink_now: "Ահազանգ",
      time_left_prefix: "Մնացել է․ ",
      time_parking_prefix: "Մինչև կայանը․ ",
      time_elapsed_dh: "{d}օ {h}ժ",
      time_elapsed_hm: "{h}ժ {m}ր",
      time_elapsed_m: "{m} ր",
      process_data_invalid_badge: "⚠",
      process_data_invalid:
        "Կարգավիճակի/ենթակարգավիճակի թույլատրելի զույգ չէ (տվյալների ռասսինխ)։ Կարելի է «հերթ 1/1» կամ շարունակել փուլերը։ Ստուգեք ադմինում։",
      btn_fix_to_1_1: "Հերթ 1/1 (ուղղում)"
    }
  };

  function normalizeLocale(code) {
    if (!code) return null;
    var c = String(code).toLowerCase().replace(/_/g, "-").split("-")[0];
    if (c === "am") c = "hy";
    return c;
  }

  function resolveLocale() {
    var q = normalizeLocale(getQueryParam("lang") || getQueryParam("language"));
    if (q && STRINGS[q]) {
      lsSet("tv_lang", q);
      return q;
    }
    // Default locale for TV board: Armenian.
    // Ignore stored/browser locale unless explicitly provided via URL query.
    lsSet("tv_lang", "hy");
    return "hy";
  }

  var locale = resolveLocale();

  function t(key, vars) {
    var bag = STRINGS[locale] || STRINGS.hy;
    var s = bag[key];
    if (s == null) s = STRINGS.hy[key];
    if (s == null) s = key;
    if (vars) {
      for (var k in vars) {
        if (Object.prototype.hasOwnProperty.call(vars, k)) {
          s = s.split("{" + k + "}").join(String(vars[k]));
        }
      }
    }
    return s;
  }

  function apiLanguage() {
    if (locale === "hy") return "am";
    if (locale === "en") return "en";
    return "ru";
  }

  function applyDom() {
    var doc = global.document;
    if (!doc) return;
    doc.documentElement.lang = locale === "hy" ? "hy" : locale;
    doc.title = t("app_title");

    var nodes = doc.querySelectorAll("[data-i18n]");
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      var k = el.getAttribute("data-i18n");
      if (k) el.textContent = t(k);
      var ak = el.getAttribute("data-i18n-aria");
      if (ak) el.setAttribute("aria-label", t(ak));
    }
  }

  global.tvI18n = {
    t: t,
    applyDom: applyDom,
    locale: locale,
    apiLanguage: apiLanguage
  };
})(typeof window !== "undefined" ? window : this);
