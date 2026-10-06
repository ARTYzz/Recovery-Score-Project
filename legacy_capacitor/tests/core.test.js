import test from "node:test";
import assert from "node:assert/strict";
import {
  RecoveryEngine,
  SafetyGate,
  CampClock,
  demoData,
  emptyData,
  FeedbackService,
  MockFightCampConnector,
  MockHealthConnector,
  MorningCheckInSchedule,
  PersonalBaseline,
  normalizeWearableSample,
  normalizeFightCampSession,
} from "../src/core.js";
import { AthleteVault } from "../src/vault.js";
test("morning check-in is due once per local day after onboarding", () => {
  const data = emptyData();
  data.profile = { name: "Athlete" };
  data.onboarding = { stage: "ready" };
  assert.equal(MorningCheckInSchedule.isDue(data, "2026-09-23"), false);
  data.onboarding.stage = "complete";
  assert.equal(MorningCheckInSchedule.isDue(data, "2026-09-23"), true);
  MorningCheckInSchedule.save(data, { date: "2026-09-23", mood: "OK" });
  assert.equal(MorningCheckInSchedule.isDue(data, "2026-09-23"), false);
  assert.equal(MorningCheckInSchedule.isDue(data, "2026-09-24"), true);
  MorningCheckInSchedule.save(data, { date: "2026-09-23", mood: "Good" });
  assert.equal(data.checkins.length, 1);
  assert.equal(data.checkins[0].mood, "Good");
  const now = new Date();
  const localToday = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
  assert.equal(MorningCheckInSchedule.isDue(demoData(), localToday), false);
});
test("missing wearable data stays insufficient, never zero", () => {
  const result = new RecoveryEngine().assess(emptyData());
  assert.equal(result.domains.sleep.status, "INSUFFICIENT_DATA");
  assert.equal(result.limiter, null);
});
test("synthetic history supplies seven distinct baseline days without duplicate syncs", () => {
  const data = emptyData();
  const connector = new MockHealthConnector("apple");
  connector.connect(data);
  connector.seedHistory(data);
  connector.seedHistory(data);
  connector.sync(data, { hrv: 66, sleepMinutes: 430, restingHr: 46 });
  const baseline = new PersonalBaseline(data);
  assert.equal(baseline.metric("hrv").count, 7);
  assert.equal(baseline.metric("sleepMinutes").ready, true);
  assert.equal(new Set(data.wearables.map((row) => row.date)).size, 7);
  assert.ok(data.wearables.every((row) => row.mode === "DEMO"));
});
test("ready domains do not invent a primary limiter", () => {
  const data = emptyData();
  data.profile = { fightDate: "2027-12-31" };
  const connector = new MockHealthConnector("apple");
  connector.connect(data);
  connector.seedHistory(data);
  data.checkins.push({ date: "2026-09-23", weight: 74, urine: 2, mood: "Good", headSymptoms: [] });
  data.sessions.push({ type: "Boxing / Technical", contact: "Light", soreness: [] });
  const result = new RecoveryEngine().assess(data);
  assert.equal(result.domains.sleep.status, "READY");
  assert.equal(result.limiter, null);
  assert.equal(result.reason, "No primary limiter from the available data");
  assert.ok(result.allowed.includes("Boxing / Technical"));
});
test("FightCamp punch baseline requires four separate session days", () => {
  const data = emptyData();
  new MockFightCampConnector().connect(data);
  data.fightCampSessions = [60, 62, 61, 63].map((count) => ({
    date: "2026-09-23", count, source: "FightCamp demo",
  }));
  assert.equal(new PersonalBaseline(data).punch().count, 1);
  data.fightCampSessions.push(
    { date: "2026-09-24", count: 62, source: "FightCamp demo" },
    { date: "2026-09-25", count: 64, source: "FightCamp demo" },
    { date: "2026-09-26", count: 63, source: "FightCamp demo" },
  );
  assert.equal(new PersonalBaseline(data).punch().ready, true);
});
test("legacy manually entered punch tests no longer affect Power & Speed", () => {
  const data = emptyData();
  data.punchTests = ["2026-09-20", "2026-09-21", "2026-09-22", "2026-09-23"].map(
    (date) => ({ date, count: 60, source: "Manual 10-second test" }),
  );
  assert.equal(new PersonalBaseline(data).punch().count, 0);
  assert.equal(new RecoveryEngine().assess(data).domains.power.status, "INSUFFICIENT_DATA");
});
test("head symptoms override readiness and restrict sparring", () => {
  const data = demoData();
  data.checkins.at(-1).headSymptoms = ["New symptoms"];
  const result = new RecoveryEngine().assess(data);
  assert.equal(result.domains.brain.status, "RESTRICTED");
  assert.equal(result.limiter, "brain");
  assert.ok(result.avoid.includes("Sparring"));
  assert.ok(!result.allowed.includes("Sparring"));
});
test("low sleep and HRV against own baseline selects sleep limiter", () => {
  const data = demoData();
  const result = new RecoveryEngine().assess(data);
  assert.equal(result.domains.sleep.status, "RESTRICTED");
  assert.equal(result.limiter, "sleep");
});
test("one heavy session is different from repeated heavy contact", () => {
  const data = demoData();
  data.sessions.push({ type: "Sparring", contact: "Heavy", rounds: 6 });
  assert.equal(new SafetyGate().evaluate(data).length, 0);
  data.sessions.push({ type: "Sparring", contact: "Heavy", rounds: 6 });
  assert.ok(
    new SafetyGate().evaluate(data).some((x) => x.code === "HEAD_LOAD"),
  );
});
test("feedback stays cautious until repeated observations", () => {
  const data = demoData();
  data.actions = [
    { id: "breathing", completedAt: "x", nextDay: { hrvDelta: 6 } },
  ];
  assert.equal(
    new FeedbackService().insight(data, "breathing").label,
    "Not Enough Data",
  );
});
test("local athlete vault encrypts records and rejects a wrong passphrase", async () => {
  const items = new Map(),
    storage = {
      getItem: (k) => items.get(k) || null,
      setItem: (k, v) => items.set(k, v),
      removeItem: (k) => items.delete(k),
    },
    vault = new AthleteVault(storage),
    data = demoData();
  await vault.create("long-test-passphrase", data);
  assert.ok(!items.get("boxer-vault-v1").includes("Demo Boxer"));
  vault.lock();
  await assert.rejects(() => vault.unlock("wrong-passphrase"));
  const opened = await vault.unlock("long-test-passphrase");
  assert.equal(opened.profile.name, "Demo Boxer");
});
test("three observations are described as association, not causation", () => {
  const data = demoData();
  data.actions = [5, 6, 7].map((v) => ({
    id: "breathing",
    completedAt: "x",
    nextDay: { hrvDelta: v },
  }));
  const insight = new FeedbackService().insight(data, "breathing");
  assert.equal(insight.label, "Possible Benefit");
  assert.match(insight.detail, /not proof of cause/);
});
test("FightCamp mock preserves source and optional punch metrics", () => {
  const d = emptyData(),
    connector = new MockFightCampConnector();
  connector.connect(d);
  connector.sync(d);
  assert.equal(d.fightCampSessions.at(-1).source, "FightCamp demo");
  assert.equal(d.fightCampSessions.at(-1).mode, "DEMO");
  assert.ok(Number.isFinite(d.fightCampSessions.at(-1).speed));
  assert.equal(d.wearables.length, 0);
  connector.disconnect(d);
  connector.sync(d);
  assert.equal(d.fightCampSessions.length, 1);
  assert.equal(new RecoveryEngine().assess(d).domains.power.status, "INSUFFICIENT_DATA");
  assert.equal(normalizeFightCampSession({ date: "2026-09-23", source: "FightCamp demo" }).count, null);
});
test("FightCamp demo history is distinct, idempotent, and feeds Power & Speed", () => {
  const d = emptyData();
  const connector = new MockFightCampConnector();
  connector.connect(d);
  connector.seedHistory(d);
  connector.seedHistory(d);
  assert.equal(d.fightCampSessions.length, 4);
  assert.equal(new PersonalBaseline(d).punch().count, 4);
  assert.equal(new RecoveryEngine().assess(d).domains.power.status, "READY");
});
test("FightCamp mock initializes automatically without duplicating sessions", () => {
  const data = emptyData();
  const connector = new MockFightCampConnector();
  assert.equal(connector.ensureDemoData(data), true);
  assert.equal(data.connections.fightcamp.status, "MOCK_CONNECTED");
  assert.equal(data.fightCampSessions.length, 4);
  assert.equal(connector.ensureDemoData(data), false);
  assert.equal(data.fightCampSessions.length, 4);
  assert.equal(new RecoveryEngine().assess(data).domains.power.status, "READY");
});
test("fight date must be strictly in the future and formats clearly", () => {
  const now = new Date("2026-07-19T10:00:00");
  assert.equal(CampClock.isFutureDate("2026-07-19", now), false);
  assert.equal(CampClock.isFutureDate("2026-07-20", now), true);
  assert.equal(CampClock.formatDate("2026-07-20"), "20 Jul 2026");
});
test("new profile can leave official weigh-in weight unset", () => {
  const data = emptyData();
  data.profile = {
    name: "New boxer",
    fightDate: "2026-12-01",
    officialWeighInWeight: null,
  };
  const result = new RecoveryEngine().assess(data);
  assert.equal(result.domains.sleep.status, "INSUFFICIENT_DATA");
  assert.equal(data.profile.officialWeighInWeight, null);
  assert.deepEqual(result.allowed, []);
  assert.deepEqual(result.avoid, []);
});
test("demo athlete includes normalized wearable and training history", () => {
  const data = demoData();
  assert.ok(data.wearables.length >= 7);
  assert.ok(data.sessions.length >= 3);
  assert.ok(
    data.wearables.every(
      (row) =>
        "sleepMinutes" in row &&
        "hrv" in row &&
        "restingHr" in row &&
        "workoutMinutes" in row,
    ),
  );
  assert.equal(data.onboarding.stage, "complete");
});
test("normalized wearable sample preserves source and missing fields", () => {
  const row = normalizeWearableSample({
    date: "2026-09-22",
    source: "Health Connect demo",
    mode: "DEMO",
    hrv: 64,
  });
  assert.equal(row.hrv, 64);
  assert.equal(row.sleepMinutes, null);
  assert.equal(row.workoutMinutes, null);
  assert.equal(row.source, "Health Connect demo");
});
