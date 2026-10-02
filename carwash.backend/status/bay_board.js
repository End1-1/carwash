/**
 * Staff board: three bay columns, free parking, and the arrival queue.
 * Status changes come from the server when the board polls, about every 20 seconds, not from a tap.
 */
(function () {
  var sched = window.carwashBaySchedule;
  var lastRows = [];
  var timer = null;

  function tr(key, vars) {
    if (window.tvI18n && window.tvI18n.t) return window.tvI18n.t(key, vars);
    return key;
  }

  function asObj(v) {
    if (!v) return null;
    if (typeof v === "object") return v;
    if (typeof v !== "string") return null;
    var s = v.replace(/^\s+|\s+$/g, "");
    if (!s) return null;
    try {
      var j = JSON.parse(s);
      return j && typeof j === "object" ? j : null;
    } catch (e) {
      return null;
    }
  }

  function parseWhen(input) {
    if (input == null) return null;
    var s = String(input).replace(/^\s+|\s+$/g, "");
    if (!s) return null;
    var m = s.match(
      /^(\d{4})[-\/]([A-Za-z]{3}|\d{1,2})[-\/](\d{1,2})[ T](\d{1,2}):(\d{1,2})(?::(\d{1,2}))?$/
    );
    if (!m) return null;
    var year = parseInt(m[1], 10);
    var monRaw = m[2];
    var day = parseInt(m[3], 10);
    var hh = parseInt(m[4], 10);
    var mm = parseInt(m[5], 10);
    var sec = parseInt(m[6] || "0", 10);
    var mon = 0;
    if (/^\d+$/.test(monRaw)) mon = parseInt(monRaw, 10);
    else {
      var months = {
        jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6,
        jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12
      };
      mon = months[String(monRaw).toLowerCase()] || 0;
    }
    if (mon < 1 || mon > 12) return null;
    return Date.UTC(year, mon - 1, day, hh - 4, mm, sec);
  }

  function num(v) {
    var n = parseInt(v, 10);
    return isNaN(n) ? 0 : n;
  }

  function text(v) {
    return v == null ? "" : String(v);
  }

  function headerMap(row) {
    return asObj(row.f_header_data) || {};
  }

  function ogp(row) {
    return asObj(row.f_ogp_data) || asObj(row.f_data) || {};
  }

  function pair(row) {
    var d = ogp(row);
    var st = num(row.f_status);
    var ss = d.f_substatus != null && d.f_substatus !== "" ? num(d.f_substatus) : st === 1 ? 1 : 0;
    return { st: st, ss: ss, d: d };
  }

  function entryMs(d) {
    return parseWhen(d.f_bay_entry) || parseWhen(d.f_status_2_2_time) || parseWhen(d.f_status_2_3_time);
  }

  function arrivalMs(d) {
    return parseWhen(d.f_status_1_1_time);
  }

  function carLabel(lines) {
    var i;
    var plate = "";
    var services = [];
    var daily = "";
    for (i = 0; i < lines.length; i++) {
      var row = lines[i];
      var hdr = headerMap(row);
      if (!plate) plate = text(hdr.f_car_number || row.f_carnumber || row.f_car_number).replace(/^\s+|\s+$/g, "");
      if (!daily) daily = text(row.f_daily_number).replace(/^\s+|\s+$/g, "");
      var name = text(row.f_name).replace(/^\s+|\s+$/g, "");
      if (name && services.indexOf(name) < 0) services.push(name);
    }
    return {
      plate: plate || daily || "—",
      service: services.length ? services.join(", ") : tr("service_default")
    };
  }

  function headerKey(row) {
    var id = row.f_header_id != null ? row.f_header_id : row.f_header;
    if (id != null && String(id) !== "") return "h:" + String(id);
    return "r:" + String(row.f_id || "");
  }

  function groupRows(rows) {
    var map = {};
    var order = [];
    var i;
    for (i = 0; i < rows.length; i++) {
      var row = rows[i] || {};
      var key = headerKey(row);
      if (!map[key]) {
        map[key] = [];
        order.push(key);
      }
      map[key].push(row);
    }
    var out = [];
    for (i = 0; i < order.length; i++) out.push(map[order[i]]);
    return out;
  }

  function classify(lines) {
    var best = lines[0];
    var bestRank = -1;
    var i;
    var arrival = null;
    var entry = null;
    var bay = 0;
    var paid = false;
    var st = 1;
    var ss = 1;
    for (i = 0; i < lines.length; i++) {
      var p = pair(lines[i]);
      var d = p.d;
      if (p.st === 4 || (p.st === 3 && p.ss === 5) || d.f_paid_parking) paid = true;
      var a = arrivalMs(d);
      if (a != null && (arrival == null || a < arrival)) arrival = a;
      var e = entryMs(d);
      var rank = 0;
      if (p.st === 2) rank = 3;
      else if (p.st === 3 && p.ss === 4) rank = 2;
      else if (p.st === 1) rank = 1;
      if (rank > bestRank) {
        bestRank = rank;
        best = lines[i];
        st = p.st;
        ss = p.ss;
        bay = num(d.f_bay);
        entry = e;
      }
    }
    if (paid || st === 4 || (st === 3 && ss === 5)) return null;
    var label = carLabel(lines);
    return {
      plate: label.plate,
      service: label.service,
      st: st,
      ss: ss,
      bay: bay,
      entry: entry,
      arrival: arrival == null ? 0 : arrival
    };
  }

  function clear(el) {
    if (!el) return;
    while (el.firstChild) el.removeChild(el.firstChild);
  }

  function card(car, minutes) {
    var el = document.createElement("article");
    el.className = "bay-car";
    var plate = document.createElement("div");
    plate.className = "bay-car-plate";
    plate.textContent = car.plate;
    var service = document.createElement("div");
    service.className = "bay-car-service";
    service.textContent = car.service;
    var time = document.createElement("div");
    time.className = "bay-car-time";
    time.textContent = tr("time_left_prefix") + tr("time_elapsed_m", { m: minutes });
    el.appendChild(plate);
    el.appendChild(service);
    el.appendChild(time);
    return el;
  }

  function emptyNote() {
    var el = document.createElement("div");
    el.className = "bay-empty";
    el.textContent = tr("bay_empty");
    return el;
  }

  function paint() {
    var columns = document.getElementById("bay-columns");
    var freeEl = document.getElementById("free-parking-list");
    var queueEl = document.getElementById("queue-list");
    if (!columns || !freeEl || !queueEl || !sched) return;

    var now = Date.now();
    var groups = groupRows(lastRows);
    var bays = [null, null, null, null];
    var free = [];
    var queue = [];
    var i;
    for (i = 0; i < groups.length; i++) {
      var car = classify(groups[i]);
      if (!car) continue;
      if (car.st === 2 && car.bay >= 1 && car.bay <= sched.BAY_COUNT) {
        if (!bays[car.bay]) bays[car.bay] = car;
      } else if (car.st === 3 && car.ss === 4) {
        free.push(car);
      } else if (car.st === 1) {
        queue.push(car);
      }
    }
    free.sort(function (a, b) {
      return (a.entry || 0) - (b.entry || 0);
    });
    queue.sort(function (a, b) {
      return a.arrival - b.arrival;
    });

    clear(columns);
    for (i = 1; i <= sched.BAY_COUNT; i++) {
      var sec = document.createElement("section");
      sec.className = "card bay-card bay-card--wash";
      var head = document.createElement("div");
      head.className = "card-head";
      var h = document.createElement("h2");
      h.textContent = tr("bay_title", { n: i });
      head.appendChild(h);
      var list = document.createElement("div");
      list.className = "list";
      if (bays[i]) {
        var leftWash = bays[i].entry == null ? 0 : bays[i].entry + sched.WASH_MS - now;
        list.appendChild(card(bays[i], sched.minutesLeft(leftWash)));
      } else {
        list.appendChild(emptyNote());
      }
      sec.appendChild(head);
      sec.appendChild(list);
      columns.appendChild(sec);
    }

    clear(freeEl);
    if (!free.length) freeEl.appendChild(emptyNote());
    for (i = 0; i < free.length; i++) {
      var leftFree = free[i].entry == null ? 0 : free[i].entry + sched.PARK_END_MS - now;
      freeEl.appendChild(card(free[i], sched.minutesLeft(leftFree)));
    }

    clear(queueEl);
    if (!queue.length) queueEl.appendChild(emptyNote());
    for (i = 0; i < queue.length; i++) {
      var q = document.createElement("article");
      q.className = "bay-car";
      var plate = document.createElement("div");
      plate.className = "bay-car-plate";
      plate.textContent = queue[i].plate;
      var service = document.createElement("div");
      service.className = "bay-car-service";
      service.textContent = queue[i].service;
      q.appendChild(plate);
      q.appendChild(service);
      queueEl.appendChild(q);
    }
  }

  function render(rows) {
    lastRows = rows || [];
    paint();
    if (timer == null) timer = setInterval(paint, 20000);
  }

  window.carwashBayBoard = { render: render, paint: paint };
})();
