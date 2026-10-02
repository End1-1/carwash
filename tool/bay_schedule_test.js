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

console.log("bay schedule walkthrough ok");
