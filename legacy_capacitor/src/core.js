export const DOMAINS = ["brain", "fuel", "sleep", "power", "body", "mind"];
export const LABELS = {
  brain: "Brain",
  fuel: "Fuel & Weight",
  sleep: "Sleep & Heart",
  power: "Power & Speed",
  body: "Body",
  mind: "Mind",
};
export class MorningCheckInSchedule {
  static isDue(data, localDate) {
    if (!data?.profile || ["connect", "ready"].includes(data.onboarding?.stage)) return false;
    return !(data.checkins || []).some((checkin) => checkin.date === localDate);
  }

  static save(data, checkin) {
    data.checkins ??= [];
    const index = data.checkins.findIndex((entry) => entry.date === checkin.date);
    if (index >= 0) data.checkins[index] = checkin;
    else data.checkins.push(checkin);
  }
}
// Shared shape for demo samples and future authorized native integrations.
export function normalizeWearableSample(sample) {
  return {
    date: sample.date,
    source: sample.source,
    mode: sample.mode,
    sleepMinutes: Number.isFinite(sample.sleepMinutes)
      ? sample.sleepMinutes
      : null,
    hrv: Number.isFinite(sample.hrv) ? sample.hrv : null,
    restingHr: Number.isFinite(sample.restingHr) ? sample.restingHr : null,
    heartRate: Number.isFinite(sample.heartRate) ? sample.heartRate : null,
    workoutMinutes: Number.isFinite(sample.workoutMinutes)
      ? sample.workoutMinutes
      : null,
  };
}
// Shared FightCamp shape for synthetic samples and a future authorized adapter.
export function normalizeFightCampSession(sample) {
  return {
    date: sample.date,
    source: sample.source,
    mode: sample.mode,
    sessionId: sample.sessionId,
    count: Number.isFinite(sample.count) ? sample.count : null,
    speed: Number.isFinite(sample.speed) ? sample.speed : null,
    output: Number.isFinite(sample.output) ? sample.output : null,
    rounds: Number.isFinite(sample.rounds) ? sample.rounds : null,
  };
}
const day = (d) => new Date(d).toISOString().slice(0, 10);
const mean = (a) => (a.length ? a.reduce((x, y) => x + y, 0) / a.length : null);
export class CampClock {
  static isFutureDate(fightDate, now = new Date()) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(fightDate || "")) return false;
    const selected = new Date(`${fightDate}T12:00:00`);
    const currentDay = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      12,
    );
    return Number.isFinite(selected.getTime()) && selected > currentDay;
  }
  static formatDate(fightDate) {
    if (!fightDate) return "No fight date";
    const parsed = new Date(`${fightDate}T12:00:00`);
    return Number.isFinite(parsed.getTime())
      ? new Intl.DateTimeFormat("en-GB", {
          day: "numeric",
          month: "short",
          year: "numeric",
        }).format(parsed)
      : "Invalid date";
  }
  static get(profile, now = new Date()) {
    if (!profile?.fightDate) return { daysOut: null, phase: "NO_CAMP" };
    const daysOut = Math.ceil(
      (new Date(profile.fightDate + "T12:00:00").getTime() - now.getTime()) /
        86400000,
    );
    return {
      daysOut,
      phase:
        daysOut < 0
          ? "POST_FIGHT"
          : daysOut <= 7
            ? "FIGHT_WEEK"
            : daysOut <= 14
              ? "TAPER"
              : daysOut <= 28
                ? "PEAK"
                : daysOut <= 56
                  ? "BUILD"
                  : "BASE",
    };
  }
}
export class PersonalBaseline {
  constructor(data) {
    this.data = data;
  }
  metric(key, rows = this.data.wearables) {
    const latestSource = rows.at(-1)?.source;
    const sameSource = latestSource
      ? rows.filter((row) => row.source === latestSource)
      : rows;
    const daily = new Map();
    sameSource.forEach((row, index) => {
      if (Number.isFinite(row[key])) daily.set(row.date || `undated-${index}`, row[key]);
    });
    const values = [...daily.values()].slice(-10);
    return {
      value: mean(values),
      count: values.length,
      ready: values.length >= 7,
    };
  }
  punch() {
    const connectionStatus = this.data.connections?.fightcamp?.status;
    if (!["MOCK_CONNECTED", "CONNECTED"].includes(connectionStatus))
      return { value: null, count: 0, ready: false };
    const sessions = this.data.fightCampSessions || [];
    const latestSource = sessions.at(-1)?.source;
    const daily = new Map();
    sessions.forEach((session, index) => {
      if (Number.isFinite(session.count) && (!latestSource || session.source === latestSource))
        daily.set(session.date || `undated-${index}`, session.count);
    });
    const values = [...daily.values()].slice(-10);
    return {
      value: mean(values),
      count: values.length,
      ready: values.length >= 4,
    };
  }
}
export class SafetyGate {
  evaluate(data) {
    const check = data.checkins.at(-1),
      sessions = data.sessions.slice(-7);
    const flags = [];
    if (check?.headSymptoms?.length)
      flags.push({
        code: "HEAD_SYMPTOMS",
        domain: "brain",
        message:
          "New symptoms after head contact. Avoid sparring and other head-impact training. Seek qualified medical evaluation.",
      });
    if (
      sessions.filter((x) => x.type === "Sparring" && x.contact === "Heavy")
        .length >= 2
    )
      flags.push({
        code: "HEAD_LOAD",
        domain: "brain",
        message:
          "Repeated heavy head contact reported recently. Avoid further head-impact training and consider qualified evaluation.",
      });
    if (check?.painSeverity === "Severe")
      flags.push({
        code: "PHYSICAL",
        domain: "body",
        message:
          "Severe pain reported. Avoid loading the affected area and seek appropriate professional assessment.",
      });
    if (check?.urine >= 4)
      flags.push({
        code: "HYDRATION",
        domain: "fuel",
        message:
          "A dark urine-colour report may signal a hydration concern. Prioritize hydration awareness and professional support if symptoms persist.",
      });
    return flags;
  }
}
export class RecoveryEngine {
  constructor() {
    this.safety = new SafetyGate();
  }
  assess(data) {
    const safety = this.safety.evaluate(data),
      base = new PersonalBaseline(data),
      wear = data.wearables.at(-1) || {},
      check = data.checkins.at(-1) || {},
      food = data.nutrition.at(-1) || {},
      punch = ["MOCK_CONNECTED", "CONNECTED"].includes(data.connections?.fightcamp?.status)
        ? data.fightCampSessions?.at(-1) || {}
        : {},
      camp = CampClock.get(data.profile);
    const domains = Object.fromEntries(
      DOMAINS.map((k) => [k, { status: "INSUFFICIENT_DATA", reasons: [] }]),
    );
    const set = (k, status, reasons) => (domains[k] = { status, reasons });
    const hr = base.metric("hrv"),
      rest = base.metric("restingHr"),
      sleep = base.metric("sleepMinutes");
    if (
      Number.isFinite(wear.sleepMinutes) ||
      Number.isFinite(wear.hrv) ||
      Number.isFinite(wear.restingHr)
    ) {
      const reasons = [];
      if (
        sleep.ready &&
        Number.isFinite(wear.sleepMinutes) &&
        wear.sleepMinutes < sleep.value * 0.85
      )
        reasons.push("Sleep below your baseline");
      if (hr.ready && Number.isFinite(wear.hrv) && wear.hrv < hr.value * 0.85)
        reasons.push("HRV below your baseline");
      if (
        rest.ready &&
        Number.isFinite(wear.restingHr) &&
        wear.restingHr > rest.value * 1.1
      )
        reasons.push("Resting HR above your baseline");
      set(
        "sleep",
        reasons.length >= 2
          ? "RESTRICTED"
          : reasons.length
            ? "CAUTION"
            : hr.ready || sleep.ready
              ? "READY"
              : "INSUFFICIENT_DATA",
        reasons.length
          ? reasons
          : hr.ready || sleep.ready
            ? ["Within your personal baseline"]
            : ["Learning your baseline"],
      );
    }
    if (Number.isFinite(check.weight) || food.meal) {
      const reasons = [];
      if (check.urine >= 3)
        reasons.push("Urine colour suggests hydration attention");
      if (food.meal === "No") reasons.push("Post-training meal missed");
      if (food.protein === "No") reasons.push("Protein plan incomplete");
      set(
        "fuel",
        reasons.length >= 2 ? "CAUTION" : reasons.length ? "CAUTION" : "READY",
        reasons,
      );
    }
    const lastSession = data.sessions.at(-1);
    if (lastSession || check.headSymptoms?.length) {
      const reasons = [];
      if (lastSession?.type === "Sparring")
        reasons.push(`${lastSession.rounds || 0} sparring rounds reported`);
      set("brain", reasons.length ? "CAUTION" : "READY", reasons);
    }
    const pb = base.punch();
    if (Number.isFinite(punch.count))
      set(
        "power",
        pb.ready && punch.count < pb.value * 0.85
          ? "CAUTION"
          : pb.ready
            ? "READY"
            : "INSUFFICIENT_DATA",
        pb.ready
          ? [`FightCamp punch count compared with your baseline (${pb.value.toFixed(0)})`]
          : ["Learning your FightCamp punch baseline"],
      );
    if (check.soreness?.length || lastSession?.soreness?.length) {
      const sores = check.soreness?.length
        ? check.soreness
        : lastSession.soreness;
      set("body", check.painSeverity === "Severe" ? "RESTRICTED" : "CAUTION", [
        `Soreness reported: ${sores.join(", ")}`,
      ]);
    }
    if (check.mood)
      set("mind", ["Flat", "Low"].includes(check.mood) ? "CAUTION" : "READY", [
        `Mood: ${check.mood}`,
      ]);
    for (const f of safety) set(f.domain, "RESTRICTED", [f.message]);
    const order = { RESTRICTED: 3, CAUTION: 2, READY: 1, INSUFFICIENT_DATA: 0 };
    const assessedCount = DOMAINS.filter(
      (k) => domains[k].status !== "INSUFFICIENT_DATA",
    ).length;
    let limiter =
      safety[0]?.domain ||
      DOMAINS.filter((k) => order[domains[k].status] >= order.CAUTION).sort(
        (a, b) => order[domains[b].status] - order[domains[a].status],
      )[0] ||
      null;
    const avoid = new Set(),
      allowed = new Set(["Boxing / Technical", "Conditioning", "Strength"]);
    if (
      domains.brain.status === "RESTRICTED" ||
      safety.some((x) => x.domain === "brain")
    )
      avoid.add("Sparring");
    else if (domains.brain.status === "CAUTION") avoid.add("Hard sparring");
    else if (domains.brain.status === "READY") allowed.add("Sparring");
    if (domains.sleep.status === "RESTRICTED") avoid.add("Hard conditioning");
    if (domains.body.status === "RESTRICTED")
      avoid.add("Strength for affected area");
    if (camp.phase === "FIGHT_WEEK") avoid.add("Sparring");
    if (safety.length) allowed.delete("Sparring");
    if (assessedCount < 4 && !safety.length) {
      allowed.clear();
      avoid.clear();
    }
    const action =
      domains.sleep.status === "CAUTION" ||
      domains.sleep.status === "RESTRICTED"
        ? {
            id: "breathing",
            title: "10 min breathing down-regulation",
            seconds: 600,
            reason: "Sleep & Heart needs attention today.",
          }
        : domains.body.status === "CAUTION"
          ? {
              id: "mobility",
              title: "10 min gentle mobility",
              seconds: 600,
              reason: "Body soreness is present today.",
            }
          : {
              id: "early-bed",
              title: "Prepare for an earlier bedtime",
              seconds: 600,
              reason: "Protect recovery before tomorrow.",
            };
    return {
      date: day(new Date()),
      camp,
      domains,
      assessedCount,
      safety,
      limiter,
      reason: limiter
        ? domains[limiter].reasons.join(" · ")
        : assessedCount < 4
          ? "Learning your baseline"
          : "No primary limiter from the available data",
      allowed: [...allowed],
      avoid: [...avoid],
      action,
      baseline: { hrv: hr, sleep, restingHr: rest, punch: pb },
    };
  }
}
export class FeedbackService {
  insight(data, actionId) {
    const relevant = data.actions.filter(
      (x) => x.id === actionId && x.completedAt && x.nextDay,
    );
    if (relevant.length < 3)
      return {
        label: "Not Enough Data",
        detail: "Complete this action on more days to compare your recovery.",
      };
    const delta = mean(
      relevant.map((x) => x.nextDay.hrvDelta).filter(Number.isFinite),
    );
    if (delta === null)
      return {
        label: "Not Enough Data",
        detail: "Following-day HRV is unavailable.",
      };
    return {
      label:
        delta > 4
          ? "Possible Benefit"
          : Math.abs(delta) < 3
            ? "No Clear Pattern"
            : "No Clear Pattern",
      detail: `Across ${relevant.length} observations, following-day HRV differed by ${delta.toFixed(1)} ms on average. This is an association, not proof of cause.`,
    };
  }
}
export class MockHealthConnector {
  constructor(kind) {
    this.kind = kind;
  }
  connect(data) {
    data.connections[this.kind] = {
      status: "MOCK_CONNECTED",
      connectedAt: new Date().toISOString(),
      source:
        this.kind === "apple"
          ? "Apple Health demo"
          : this.kind === "android"
            ? "Health Connect demo"
            : this.kind === "demo-health"
              ? "Synthetic health demo"
              : "FightCamp demo",
      mode: "DEMO",
    };
    return data;
  }
  disconnect(data) {
    data.connections[this.kind] = { status: "DISCONNECTED", source: this.kind };
    return data;
  }
  sync(data, sample) {
    if (data.connections[this.kind]?.status !== "MOCK_CONNECTED") return data;
    const normalized = normalizeWearableSample({
      ...sample,
      date: sample.date || day(new Date()),
      source: data.connections[this.kind].source,
      mode: "DEMO",
    });
    const existing = data.wearables.findIndex(
      (row) => row.date === normalized.date && row.source === normalized.source,
    );
    if (existing >= 0) data.wearables[existing] = normalized;
    else data.wearables.push(normalized);
    return data;
  }
  seedHistory(data) {
    if (data.connections[this.kind]?.status !== "MOCK_CONNECTED") return data;
    for (let daysAgo = 6; daysAgo >= 0; daysAgo--) {
      const sampleDate = day(new Date(Date.now() - daysAgo * 86400000));
      if (data.wearables.some((row) => row.date === sampleDate && row.source === data.connections[this.kind].source))
        continue;
      this.sync(data, {
        date: sampleDate,
        sleepMinutes: 420 + (daysAgo % 3) * 18,
        hrv: 64 + (daysAgo % 4) * 3,
        restingHr: 45 + (daysAgo % 3),
        heartRate: 70 + (daysAgo % 5),
        workoutMinutes: daysAgo % 2 === 0 ? 52 : 0,
      });
    }
    data.wearables.sort((a, b) => a.date.localeCompare(b.date));
    return data;
  }
}
export class MockFightCampConnector {
  constructor() {
    this.kind = "fightcamp";
  }
  ensureDemoData(data) {
    // The prototype uses a local sample source until an authorized adapter exists.
    // Never replace a future official connection with synthetic sessions.
    data.connections ??= {};
    data.fightCampSessions ??= [];
    if (data.connections.fightcamp?.status === "CONNECTED") return false;
    const wasConnected = data.connections.fightcamp?.status === "MOCK_CONNECTED";
    const previousCount = data.fightCampSessions?.length || 0;
    if (!wasConnected) this.connect(data);
    this.seedHistory(data);
    return !wasConnected || (data.fightCampSessions?.length || 0) !== previousCount;
  }
  connect(data) {
    data.connections.fightcamp = {
      status: "MOCK_CONNECTED",
      connectedAt: new Date().toISOString(),
      source: "FightCamp demo",
      mode: "DEMO",
    };
    return data;
  }
  disconnect(data) {
    data.connections.fightcamp = { status: "DISCONNECTED", source: "FightCamp demo" };
    return data;
  }
  sync(
    data,
    sample = {
      count: 62,
      speed: 8.2,
      output: 73,
      rounds: 6,
      sessionId: `fightcamp-demo-${day(new Date())}`,
    },
  ) {
    if (data.connections.fightcamp?.status !== "MOCK_CONNECTED") return data;
    const normalized = normalizeFightCampSession({
      ...sample,
      date: sample.date || day(new Date()),
      source: "FightCamp demo",
      mode: "DEMO",
    });
    data.fightCampSessions ??= [];
    const existing = data.fightCampSessions.findIndex(
      (session) => session.sessionId === normalized.sessionId && session.source === normalized.source,
    );
    if (existing >= 0) data.fightCampSessions[existing] = normalized;
    else data.fightCampSessions.push(normalized);
    return data;
  }
  seedHistory(data) {
    if (data.connections.fightcamp?.status !== "MOCK_CONNECTED") return data;
    for (const [daysAgo, count, speed, output, rounds] of [
      [9, 63, 8.1, 77, 5],
      [6, 61, 7.9, 74, 6],
      [3, 64, 8.3, 79, 5],
      [0, 59, 7.7, 70, 6],
    ]) {
      const sessionDate = day(new Date(Date.now() - daysAgo * 86400000));
      this.sync(data, {
        date: sessionDate,
        sessionId: `fightcamp-demo-${sessionDate}`,
        count,
        speed,
        output,
        rounds,
      });
    }
    data.fightCampSessions.sort((a, b) => a.date.localeCompare(b.date));
    return data;
  }
}
export const emptyData = () => ({
  profile: null,
  consent: null,
  onboarding: null,
  connections: {},
  wearables: [],
  checkins: [],
  sessions: [],
  nutrition: [],
  foodMeals: [],
  fightCampSessions: [],
  // Kept only so older local vaults can still be opened; no longer assessed.
  punchTests: [],
  actions: [],
  assessments: [],
});
export function demoData() {
  const d = emptyData(),
    today = new Date();
  d.profile = {
    name: "Demo Boxer",
    fightDate: day(new Date(today.getTime() + 32 * 86400000)),
    officialWeighInWeight: 72.5,
  };
  d.consent = {
    privacyVersion: "prototype-v1",
    healthVersion: "prototype-v1",
    acceptedAt: new Date().toISOString(),
    mockOnly: true,
  };
  d.onboarding = { stage: "complete" };
  d.connections.mock = {
    status: "MOCK_CONNECTED",
    source: "Synthetic wearable demo",
    mode: "DEMO",
  };
  new MockFightCampConnector().ensureDemoData(d);
  for (let i = 10; i >= 0; i--) {
    let date = day(new Date(today.getTime() - i * 86400000));
    d.wearables.push(
      normalizeWearableSample({
        date,
        hrv: i === 0 ? 58 : 69 + (i % 4),
        restingHr: i === 0 ? 47 : 41 + (i % 3),
        sleepMinutes: i === 0 ? 342 : 430 + (i % 4) * 12,
        heartRate: 72 + (i % 5),
        workoutMinutes: i % 2 ? 45 : 70,
        source: "Synthetic wearable demo",
        mode: "DEMO",
      }),
    );
  }
  d.sessions.push(
    {
      date: day(new Date(today.getTime() - 3 * 86400000)),
      type: "Boxing / Technical",
      duration: 60,
      intensity: "Moderate",
      rounds: 0,
      contact: "Light",
      soreness: [],
    },
    {
      date: day(new Date(today.getTime() - 2 * 86400000)),
      type: "Strength",
      duration: 45,
      intensity: "Moderate",
      rounds: 0,
      contact: "Light",
      soreness: [],
    },
    {
      date: day(new Date(today.getTime() - 86400000)),
      type: "Sparring",
      duration: 50,
      intensity: "Moderate",
      rounds: 5,
      contact: "Moderate",
      soreness: [],
    },
  );
  d.checkins.push({
    date: `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`,
    weight: 74.6,
    urine: 2,
    mood: "Low",
    headSymptoms: [],
    soreness: [],
    painSeverity: "None",
  });
  return d;
}
