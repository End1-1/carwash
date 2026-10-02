"use strict";

var assert = require("assert");
var sched = require("../carwash.backend/status/bay_schedule.js");

function at(h, m) {
  return Date.UTC(2026, 9, 2, h - 4, m, 0, 0);
}

function car(id, arrivalMs) {
  return {
    headerId: id,
    lineIds: [id],
    arrivalMs: arrivalMs,
    status: 1,
    substatus: 1,
    bay: 0,
    entryMs: null
  };
}

function byId(cars, id) {
  for (var i = 0; i < cars.length; i++) {
    if (cars[i].headerId === id) return cars[i];
  }
  throw new Error("missing " + id);
}

function advance(cars, now) {
  return sched.advanceBaySchedule(cars, now);
}

var t0900 = at(9, 0);
var t0920 = at(9, 20);
var t0940 = at(9, 40);
var t0950 = at(9, 50);
var t1000 = at(10, 0);
var t1100 = at(11, 0);

var a = car("a", t0900);
var state = advance([a], t0900);
a = byId(state, "a");
assert.strictEqual(a.status, 2);
assert.strictEqual(a.substatus, 2);
assert.strictEqual(a.bay, 1);
assert.strictEqual(a.entryMs, t0900);

var b = car("b", t0920);
state = advance([a, b], t0920);
a = byId(state, "a");
b = byId(state, "b");
assert.strictEqual(a.bay, 1);
assert.strictEqual(a.entryMs, t0900);
assert.strictEqual(a.status, 2);
assert.strictEqual(b.bay, 2);
assert.strictEqual(b.entryMs, t0920);
assert.strictEqual(b.status, 2);

var c = car("c", t0940);
state = advance([a, b, c], t0940);
c = byId(state, "c");
assert.strictEqual(c.bay, 3);
assert.strictEqual(c.entryMs, t0940);
assert.strictEqual(byId(state, "a").bay, 1);
assert.strictEqual(byId(state, "b").bay, 2);

var d = car("d", t0950);
state = advance([byId(state, "a"), byId(state, "b"), c, d], t0950);
d = byId(state, "d");
assert.strictEqual(d.status, 1);
assert.strictEqual(d.bay, 0);
assert.strictEqual(d.entryMs, null);
assert.strictEqual(byId(state, "a").status, 2);
assert.strictEqual(byId(state, "a").bay, 1);

var again = advance(state.map(function (x) { return x; }), t0950);
assert.strictEqual(byId(again, "d").status, 1);
assert.strictEqual(byId(again, "a").entryMs, t0900);
assert.strictEqual(byId(again, "b").entryMs, t0920);

state = advance(
  [byId(state, "a"), byId(state, "b"), byId(state, "c"), byId(state, "d")],
  t1000
);
a = byId(state, "a");
d = byId(state, "d");
assert.strictEqual(a.status, 3);
assert.strictEqual(a.substatus, 4);
assert.strictEqual(a.bay, 0);
assert.strictEqual(a.entryMs, t0900);
assert.strictEqual(a.paid, false);
assert.strictEqual(d.status, 2);
assert.strictEqual(d.bay, 1);
assert.strictEqual(d.entryMs, t1000);
assert.strictEqual(byId(state, "b").status, 2);
assert.strictEqual(byId(state, "b").bay, 2);
assert.strictEqual(byId(state, "c").status, 2);
assert.strictEqual(byId(state, "c").bay, 3);

assert.strictEqual(sched.minutesLeft(t1100 - t1000), 60);
assert.strictEqual(sched.minutesLeft(t1000 - t0900), 60);

state = advance(state, t1100);
a = byId(state, "a");
assert.strictEqual(a.status, 4);
assert.strictEqual(a.substatus, 5);
assert.strictEqual(a.paid, true);
assert.strictEqual(sched.onSchedule(a), false);
assert.strictEqual(byId(state, "d").status, 3);
assert.strictEqual(byId(state, "d").entryMs, t1000);
assert.strictEqual(byId(state, "b").status, 3);
assert.strictEqual(byId(state, "c").status, 3);

var parked = advance([a], t1100 + 60000);
assert.strictEqual(sched.onSchedule(byId(parked, "a")), false);

var off = sched.resolveDurations(null);
assert.strictEqual(off.enabled, 0);
assert.strictEqual(off.washMs, sched.WASH_MS);
assert.strictEqual(off.parkEndMs, sched.PARK_END_MS);
var offExplicit = sched.resolveDurations({ enabled: 0, coeff: 60 });
assert.strictEqual(offExplicit.washMs, 60 * 60 * 1000);
assert.strictEqual(offExplicit.parkEndMs, 120 * 60 * 1000);

var scale = { enabled: 1, coeff: 60 };
var scaled = sched.resolveDurations(scale);
assert.strictEqual(scaled.washMs, 60 * 1000);
assert.strictEqual(scaled.parkEndMs, 120 * 1000);

function advanceScaled(cars, now) {
  return sched.advanceBaySchedule(cars, now, scale);
}

var s0 = at(9, 0);
var s1 = at(9, 1);
var s2 = at(9, 2);
var sa = car("a", s0);
var sb = car("b", s0);
var sc = car("c", s0);
var sd = car("d", s0);
var scaledState = advanceScaled([sa, sb, sc, sd], s0);
assert.strictEqual(byId(scaledState, "a").status, 2);
assert.strictEqual(byId(scaledState, "a").bay, 1);
assert.strictEqual(byId(scaledState, "a").entryMs, s0);
assert.strictEqual(byId(scaledState, "b").bay, 2);
assert.strictEqual(byId(scaledState, "b").entryMs, s0);
assert.strictEqual(byId(scaledState, "c").bay, 3);
assert.strictEqual(byId(scaledState, "c").entryMs, s0);
assert.strictEqual(byId(scaledState, "d").status, 1);
assert.strictEqual(byId(scaledState, "d").bay, 0);
assert.strictEqual(byId(scaledState, "d").entryMs, null);

var stillWashing = advance([byId(scaledState, "a")], s1);
assert.strictEqual(byId(stillWashing, "a").status, 2);
assert.strictEqual(byId(stillWashing, "a").entryMs, s0);

scaledState = advanceScaled(scaledState, s1);
sa = byId(scaledState, "a");
sd = byId(scaledState, "d");
assert.strictEqual(sa.status, 3);
assert.strictEqual(sa.substatus, 4);
assert.strictEqual(sa.bay, 0);
assert.strictEqual(sa.entryMs, s0);
assert.strictEqual(sd.status, 2);
assert.strictEqual(sd.bay, 1);
assert.strictEqual(sd.entryMs, s1);
assert.strictEqual(byId(scaledState, "b").status, 3);
assert.strictEqual(byId(scaledState, "c").status, 3);

scaledState = advanceScaled(scaledState, s2);
assert.strictEqual(byId(scaledState, "a").status, 4);
assert.strictEqual(byId(scaledState, "a").substatus, 5);
assert.strictEqual(byId(scaledState, "a").paid, true);
assert.strictEqual(byId(scaledState, "a").entryMs, s0);
assert.strictEqual(byId(scaledState, "d").status, 3);
assert.strictEqual(byId(scaledState, "d").entryMs, s1);

var zeroCoeff = sched.resolveDurations({ enabled: 1, coeff: 0 });
assert.strictEqual(zeroCoeff.coeff, 60);
assert.strictEqual(zeroCoeff.washMs, 60 * 1000);
assert.strictEqual(sched.minutesLeft(scaled.washMs), 1);
assert.strictEqual(sched.minutesLeft(scaled.parkEndMs), 2);

console.log("bay schedule walkthrough ok");
