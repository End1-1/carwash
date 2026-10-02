/**
 * Car-wash bay schedule.
 * Exactly 3 bays. A car holds a bay only during wash+dry: 60 minutes from bay
 * entry. Service names do not change that. Then free parking until 120 minutes
 * after entry (the bay is free). After that the car is paid parking and leaves
 * the schedule. Queue is arrival order and moves only into a bay that is not
 * in its wash hour. The clock starts at bay assignment, not at order time.
 *
 * Status pairs already used by goods-in-progress:
 *   1/1 queue, 2/2 wash (bay), 3/4 free parking, 4/5 paid parking (off schedule).
 */
(function (root, factory) {
  var api = factory();
  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
  root.carwashBaySchedule = api;
})(typeof window !== "undefined" ? window : globalThis, function () {
  var BAY_COUNT = 3;
  var WASH_MS = 60 * 60 * 1000;
  var PARK_END_MS = 120 * 60 * 1000;

  function lowestFreeBay(used) {
    var b;
    for (b = 1; b <= BAY_COUNT; b++) {
      if (!used[b]) return b;
    }
    return 0;
  }

  function cloneCar(c) {
    return {
      headerId: String(c.headerId),
      lineIds: (c.lineIds || []).slice(),
      arrivalMs: c.arrivalMs == null ? null : c.arrivalMs,
      status: c.status | 0,
      substatus: c.substatus | 0,
      bay: c.bay | 0,
      entryMs: c.entryMs == null ? null : c.entryMs,
      paid: !!c.paid
    };
  }

  function markPaid(c) {
    c.status = 4;
    c.substatus = 5;
    c.bay = 0;
    c.paid = true;
  }

  function markFree(c) {
    c.status = 3;
    c.substatus = 4;
    c.bay = 0;
    c.paid = false;
  }

  function markWash(c, bay, entryMs) {
    c.status = 2;
    c.substatus = 2;
    c.bay = bay;
    c.entryMs = entryMs;
    c.paid = false;
  }

  function markQueue(c) {
    c.status = 1;
    c.substatus = 1;
    c.bay = 0;
    c.entryMs = null;
    c.paid = false;
  }

  function isPaidState(c) {
    return !!c.paid || c.status === 4 || (c.status === 3 && c.substatus === 5);
  }

  function isWashState(c) {
    return c.status === 2 && (c.substatus === 2 || c.substatus === 3);
  }

  function isFreeState(c) {
    return c.status === 3 && c.substatus === 4;
  }

  /**
   * @param {Array} input cars {headerId, lineIds, arrivalMs, status, substatus, bay, entryMs}
   * @param {number} nowMs
   * @returns {Array} next cars, including ones that just went to paid parking
   */
  function advanceBaySchedule(input, nowMs) {
    var cars = [];
    var src = input || [];
    var n;
    for (n = 0; n < src.length; n++) cars.push(cloneCar(src[n]));
    var active = [];
    var i;

    for (i = 0; i < cars.length; i++) {
      var c = cars[i];
      if (isPaidState(c)) {
        markPaid(c);
        continue;
      }
      if (isWashState(c)) {
        if (c.entryMs == null) c.entryMs = nowMs;
        if (nowMs >= c.entryMs + PARK_END_MS) {
          markPaid(c);
          continue;
        }
        if (nowMs >= c.entryMs + WASH_MS) {
          markFree(c);
        } else {
          c.status = 2;
          c.substatus = 2;
          c.paid = false;
        }
      } else if (isFreeState(c)) {
        if (c.entryMs == null || nowMs >= c.entryMs + PARK_END_MS) {
          markPaid(c);
          continue;
        }
        markFree(c);
      } else {
        markQueue(c);
      }
      active.push(c);
    }

    var washing = [];
    for (i = 0; i < active.length; i++) {
      if (active[i].status === 2) washing.push(active[i]);
    }
    washing.sort(function (a, b) {
      var d = a.entryMs - b.entryMs;
      if (d) return d;
      return String(a.headerId) < String(b.headerId) ? -1 : String(a.headerId) > String(b.headerId) ? 1 : 0;
    });

    var used = {};
    var needBay = [];
    for (i = 0; i < washing.length; i++) {
      var w = washing[i];
      if (w.bay >= 1 && w.bay <= BAY_COUNT && !used[w.bay]) {
        used[w.bay] = w.headerId;
      } else {
        w.bay = 0;
        needBay.push(w);
      }
    }
    for (i = 0; i < needBay.length; i++) {
      var bay = lowestFreeBay(used);
      if (!bay) {
        markQueue(needBay[i]);
      } else {
        markWash(needBay[i], bay, needBay[i].entryMs == null ? nowMs : needBay[i].entryMs);
        used[bay] = needBay[i].headerId;
      }
    }

    var queue = [];
    for (i = 0; i < active.length; i++) {
      if (active[i].status === 1) queue.push(active[i]);
    }
    queue.sort(function (a, b) {
      var aa = a.arrivalMs == null ? nowMs : a.arrivalMs;
      var bb = b.arrivalMs == null ? nowMs : b.arrivalMs;
      if (aa !== bb) return aa - bb;
      return String(a.headerId) < String(b.headerId) ? -1 : String(a.headerId) > String(b.headerId) ? 1 : 0;
    });
    for (i = 0; i < queue.length; i++) {
      var free = lowestFreeBay(used);
      if (!free) break;
      markWash(queue[i], free, nowMs);
      used[free] = queue[i].headerId;
    }

    return cars;
  }

  function onSchedule(c) {
    return !c.paid && c.status !== 4 && !(c.status === 3 && c.substatus === 5);
  }

  function minutesLeft(ms) {
    if (ms == null || !isFinite(ms) || ms <= 0) return 0;
    return Math.ceil(ms / 60000);
  }

  return {
    BAY_COUNT: BAY_COUNT,
    WASH_MS: WASH_MS,
    PARK_END_MS: PARK_END_MS,
    advanceBaySchedule: advanceBaySchedule,
    onSchedule: onSchedule,
    minutesLeft: minutesLeft
  };
});
