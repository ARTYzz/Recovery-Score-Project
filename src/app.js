import {
  RecoveryEngine,
  FeedbackService,
  CampClock,
  MockHealthConnector,
  MockFightCampConnector,
  demoData,
  emptyData,
  LABELS,
  DOMAINS,
} from "./core.js";
import { AthleteVault } from "./vault.js";
import { FoodJournal, prepareMealPhoto } from "./food.js";
import { RecoveryOverview } from "./recovery-overview.js";

const icon = (name, size = 18) =>
  `<i data-lucide="${name}" style="width:${size}px;height:${size}px"></i>`;
const safe = (v) =>
  String(v ?? "").replace(
    /[&<>"']/g,
    (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        c
      ],
  );
const date = () => {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
};
const localTomorrow = () => {
  const next = new Date();
  next.setDate(next.getDate() + 1);
  return `${next.getFullYear()}-${String(next.getMonth() + 1).padStart(2, "0")}-${String(next.getDate()).padStart(2, "0")}`;
};
const exampleFightDate = () =>
  CampClock.formatDate(
    new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10),
  );
const profileWeight = (profile) =>
  profile.officialWeighInWeight ?? profile.fightWeight ?? null;
const card = (content, cls = "") =>
  `<section class="card ${cls}">${content}</section>`;
const header = (title, badge = "") =>
  `<header class="page-head"><button class="back icon-btn" data-route="today">${icon("arrow-left")}</button><h1 class="head-title">${title}</h1><span class="pill">${badge}</span></header>`;
const nav = (active) =>
  `<nav class="bottom-nav">${[
    ["today", "house", "Today"],
    ["training", "plus-circle", "Log"],
    ["trends", "trending-up", "Trends"],
    ["camp", "calendar-days", "Camp"],
  ]
    .map(
      ([route, glyph, title]) =>
        `<button data-route="${route}" class="${active === route ? "active" : ""}">${icon(glyph, 20)}<span>${title}</span></button>`,
    )
    .join("")}</nav>`;
const fixed = (label, action) =>
  `<div class="fixed-action"><button class="primary" data-action="${action}">${label}</button></div>`;
const statusColor = (s) =>
  ({
    READY: "#b9df2e",
    CAUTION: "#bd9138",
    RESTRICTED: "#ad493e",
    INSUFFICIENT_DATA: "#cbd2da",
  })[s];
const weightPath = (values) => {
  if (!values.length) return "";
  const min = Math.min(...values) - 0.5,
    max = Math.max(...values) + 0.5,
    range = max - min || 1;
  return values
    .map(
      (v, i) =>
        `${i ? "L" : "M"}${(8 + (i * 300) / Math.max(1, values.length - 1)).toFixed(1)} ${(95 - ((v - min) / range) * 75).toFixed(1)}`,
    )
    .join(" ");
};
const choice = (field, options, value) =>
  `<div class="segmented ${options.length === 2 ? "two" : ""}">${options.map((x) => `<button data-field="${field}" data-value="${x}" class="${String(value) === String(x) ? "selected" : ""}">${x}</button>`).join("")}</div>`;
const metricStrong = (value, format = (v) => v) =>
  Number.isFinite(value)
    ? `<strong>${format(value)}</strong>`
    : `<strong class="missing-metric">Unavailable</strong>`;

const recoveryGauge = (overview) => {
  const tickCount = 41;
  const active = overview.score === null ? 0 : Math.round((overview.score / 100) * tickCount);
  const ticks = Array.from({ length: tickCount }, (_, index) => {
    const angle = ((150 + (index * 240) / (tickCount - 1)) * Math.PI) / 180;
    const at = (radius) => [75 + Math.cos(angle) * radius, 65 + Math.sin(angle) * radius];
    const [x1, y1] = at(44);
    const [x2, y2] = at(50);
    return `<line x1="${x1.toFixed(1)}" y1="${y1.toFixed(1)}" x2="${x2.toFixed(1)}" y2="${y2.toFixed(1)}" class="${index < active ? "active" : ""}"/>`;
  }).join("");
  const number = overview.score === null ? "—" : overview.score;
  return `<div class="recovery-gauge ${overview.tone}" role="img" aria-label="Recovery overview: ${number} ${overview.label}. ${overview.explanation}"><svg viewBox="0 0 150 117" aria-hidden="true">${ticks}<text x="75" y="69" class="gauge-number">${number}</text><text x="75" y="87" class="gauge-label">${overview.label}</text><text x="33" y="108" class="gauge-axis">0</text><text x="117" y="108" class="gauge-axis">100</text></svg><p>${overview.explanation}</p></div>`;
};
const campPhaseText = (phase) => ({
  BASE: "Base block",
  BUILD: "Build block",
  PEAK: "Peak block",
  TAPER: "Taper block",
  FIGHT_WEEK: "Fight week",
  POST_FIGHT: "Post fight",
  NO_CAMP: "No camp",
})[phase] || phase;

class BoxerApp {
  constructor() {
    this.vault = new AthleteVault();
    this.engine = new RecoveryEngine();
    this.feedback = new FeedbackService();
    this.foodJournal = new FoodJournal();
    this.data = null;
    this.draft = {};
    this.route = location.hash.slice(1) || "today";
    this.error = "";
    document.addEventListener("click", (e) => this.onClick(e));
    document.addEventListener("submit", (e) => this.onSubmit(e));
    document.addEventListener("change", (e) => {
      if (e.target.name === "fightDate") {
        const output = e.target.form?.querySelector("[data-fight-date-preview]");
        if (output) output.textContent = CampClock.formatDate(e.target.value);
      }
      if (e.target.id === "meal-photo") this.onMealPhoto(e.target.files?.[0]);
      if (["foodKey", "portions"].includes(e.target.name)) this.updateFoodEstimate(e.target.form);
    });
    window.addEventListener("hashchange", () => {
      this.route = location.hash.slice(1) || "today";
      this.render();
    });
    setInterval(() => this.tick(), 1000);
    this.render();
  }
  get result() {
    return this.engine.assess(this.data);
  }
  async persist() {
    this.data.assessments.push({ date: date(), result: this.result });
    await this.vault.save();
    this.render();
  }
  go(route) {
    this.route = route;
    location.hash = route;
    this.draft = {};
    this.error = "";
    window.scrollTo(0, 0);
    this.render();
  }
  async onSubmit(event) {
    event.preventDefault();
    const f = event.target,
      fd = new FormData(f);
    try {
      if (f.id === "setup") {
        if (!fd.get("privacy"))
          throw Error("Accept the Privacy Notice to continue.");
        if (!CampClock.isFutureDate(fd.get("fightDate")))
          throw Error("Choose a fight date in the future.");
        const officialWeight = String(
          fd.get("officialWeighInWeight") || "",
        ).trim();
        const data = emptyData();
        data.profile = {
          name: fd.get("name"),
          fightDate: fd.get("fightDate"),
          officialWeighInWeight: officialWeight ? Number(officialWeight) : null,
        };
        data.consent = {
          privacyVersion: "prototype-v1",
          privacyAcceptedAt: new Date().toISOString(),
        };
        data.onboarding = { stage: "connect" };
        await this.vault.create(fd.get("passphrase"), data);
        this.data = data;
        this.go("connect-health");
      }
      if (f.id === "unlock") {
        this.data = await this.vault.unlock(fd.get("passphrase"));
        this.render();
      }
      if (f.id === "profile") {
        if (!CampClock.isFutureDate(fd.get("fightDate")))
          throw Error("Choose a fight date in the future.");
        const officialWeight = String(
          fd.get("officialWeighInWeight") || "",
        ).trim();
        this.data.profile = {
          name: fd.get("name"),
          fightDate: fd.get("fightDate"),
          officialWeighInWeight: officialWeight ? Number(officialWeight) : null,
        };
        await this.persist();
        this.go("camp");
      }
      if (f.id === "food-entry") {
        const meal = this.foodJournal.createMeal({
          date: date(),
          time: new Date().toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" }),
          mealType: fd.get("mealType"),
          foodKey: fd.get("foodKey"),
          portions: fd.get("portions"),
          kcal: fd.get("kcal"),
          protein: fd.get("protein"),
          carbs: fd.get("carbs"),
          fat: fd.get("fat"),
          photo: this.draft.photo,
        });
        this.data.foodMeals ??= [];
        if (this.draft.editingId) {
          const index = this.data.foodMeals.findIndex((item) => item.id === this.draft.editingId);
          if (index >= 0) this.data.foodMeals[index] = { ...meal, id: this.draft.editingId, time: this.draft.editingTime };
        } else this.data.foodMeals.push(meal);
        await this.persist();
        this.go("food-photo");
      }
    } catch (e) {
      this.error = e.message;
      this.render();
    }
  }
  async onClick(event) {
    const el = event.target.closest("[data-route],[data-field],[data-action]");
    if (!el) return;
    const { route, field, value, action } = el.dataset;
    if (route) {
      this.go(route);
      return;
    }
    if (field) {
      this.draft[field] = value;
      this.error = "";
      this.render();
      return;
    }
    try {
      await this.act(action, value);
    } catch (e) {
      this.error = e.message;
      this.render();
    }
  }
  async onMealPhoto(file) {
    if (!file) return;
    try {
      this.draft.photo = await prepareMealPhoto(file);
      this.error = "";
      this.render();
    } catch (e) {
      this.error = e.message;
      this.render();
    }
  }
  updateFoodEstimate(form) {
    if (!form || form.id !== "food-entry") return;
    try {
      const values = this.foodJournal.estimate(
        form.elements.foodKey.value,
        Number(form.elements.portions.value),
      );
      for (const [key, value] of Object.entries(values))
        form.elements[key].value = value;
    } catch (e) {
      this.error = e.message;
    }
  }
  acceptHealthConsent() {
    if (this.draft.healthConsent !== "yes")
      throw Error("Confirm local health-data consent to continue.");
    this.data.consent.healthVersion = "prototype-v1";
    this.data.consent.healthAcceptedAt = new Date().toISOString();
    this.data.consent.healthWording =
      "I consent to local processing of health, training, and recovery inputs for personal guidance.";
  }
  async act(action, value) {
    const d = this.data,
      x = this.draft;
    switch (action) {
      case "demo":
        await this.vault.create("demo-passphrase", demoData());
        this.data = this.vault.data;
        this.go("today");
        break;
      case "onboarding-demo-source": {
        this.acceptHealthConsent();
        const source = value === "fightcamp" ? "demo-health" : value;
        const health = new MockHealthConnector(source);
        health.connect(d);
        health.sync(d, {
          sleepMinutes: 437,
          hrv: 66,
          restingHr: 48,
          heartRate: 74,
          workoutMinutes: 52,
        });
        if (value === "fightcamp") {
          const fightcamp = new MockFightCampConnector();
          fightcamp.connect(d);
          fightcamp.seedHistory(d);
        }
        d.onboarding = { stage: "ready", selectedSource: value, demo: true };
        await this.vault.save();
        this.go("baseline-intro");
        break;
      }
      case "onboarding-skip":
        this.acceptHealthConsent();
        d.onboarding = { stage: "ready", selectedSource: null, demo: false };
        await this.vault.save();
        this.go("baseline-intro");
        break;
      case "onboarding-start":
        d.onboarding = { ...d.onboarding, stage: "complete" };
        await this.vault.save();
        this.go("today");
        break;
      case "lock":
        this.vault.lock();
        this.data = null;
        this.render();
        break;
      case "delete":
        if (confirm("Delete all local athlete data permanently?")) {
          this.vault.delete();
          this.data = null;
          this.render();
        }
        break;
      case "weight-up":
      case "weight-down":
        x.weight = +Math.max(
          30,
          Number(
            x.weight ??
              d.checkins.at(-1)?.weight ??
              profileWeight(d.profile) ??
              70,
          ) + (action === "weight-up" ? 0.1 : -0.1),
        ).toFixed(1);
        this.render();
        break;
      case "round-up":
      case "round-down":
        x.rounds = Math.max(
          0,
          Number(x.rounds ?? 0) + (action === "round-up" ? 1 : -1),
        );
        this.render();
        break;
      case "sore":
        x.soreness = x.soreness || [];
        x.soreness = x.soreness.includes(value)
          ? x.soreness.filter((v) => v !== value)
          : [...x.soreness, value];
        this.render();
        break;
      case "save-morning": {
        const check = {
          date: date(),
          weight: x.weight ?? d.checkins.at(-1)?.weight ?? null,
          urine: Number(x.urine ?? 2),
          mood: x.mood || "OK",
          headSymptoms:
            x.symptom === "Yes" ? ["New symptoms after head contact"] : [],
          soreness: x.soreness || [],
          painSeverity: x.painSeverity || "None",
        };
        d.checkins.push(check);
        const w = d.wearables.at(-1),
          prior = d.wearables.at(-2);
        for (const a of d.actions.filter(
          (v) => v.completedAt && !v.nextDay && v.date < check.date,
        ))
          a.nextDay = {
            hrvDelta:
              Number.isFinite(w?.hrv) && Number.isFinite(prior?.hrv)
                ? w.hrv - prior.hrv
                : null,
            sleepMinutes: w?.sleepMinutes ?? null,
            restingHr: w?.restingHr ?? null,
            mood: check.mood,
          };
        await this.persist();
        this.go("today");
        break;
      }
      case "save-training":
        d.sessions.push({
          date: date(),
          type: x.type || "Sparring",
          duration: Number(x.duration || 30),
          intensity: x.intensity || "Moderate",
          rounds: Number(x.rounds || 0),
          contact: x.contact || "Light",
          soreness: x.soreness || [],
        });
        await this.persist();
        this.go("nutrition");
        break;
      case "save-nutrition":
        d.nutrition.push({
          date: date(),
          meal: x.meal || "No",
          protein: x.protein || "No",
          carbs: x.carbs || "Medium",
        });
        await this.persist();
        this.go("today");
        break;
      case "food-add":
        x.foodEditor = true;
        this.render();
        break;
      case "food-edit": {
        const meal = (d.foodMeals || []).find((item) => item.id === value);
        if (!meal) throw Error("Meal not found.");
        this.draft = {
          foodEditor: true,
          editingId: meal.id,
          editingTime: meal.time,
          photo: meal.photo,
          foodKey: meal.foodKey,
          mealType: meal.mealType,
          portions: meal.portions,
          kcal: meal.kcal,
          protein: meal.protein,
          carbs: meal.carbs,
          fat: meal.fat,
        };
        this.render();
        break;
      }
      case "food-cancel":
        this.draft = {};
        this.render();
        break;
      case "timer":
        x.seconds ??= this.result.action.seconds;
        x.running = !x.running;
        x.startedAt ??= new Date().toISOString();
        this.render();
        break;
      case "timer-reset":
        x.seconds = this.result.action.seconds;
        x.running = false;
        this.render();
        break;
      case "timer-complete":
        if (!x.startedAt)
          throw Error("Start the recovery timer before marking it complete.");
        d.actions.push({
          id: this.result.action.id,
          date: date(),
          startedAt: x.startedAt,
          completedAt: new Date().toISOString(),
          nextDay: null,
        });
        x.running = false;
        await this.persist();
        this.go("today");
        break;
      case "connect":
        if (value === "fightcamp") new MockFightCampConnector().connect(d);
        else new MockHealthConnector(value).connect(d);
        await this.persist();
        break;
      case "disconnect":
        if (value === "fightcamp") new MockFightCampConnector().disconnect(d);
        else new MockHealthConnector(value).disconnect(d);
        await this.persist();
        break;
      case "sync":
        if (value === "fightcamp") new MockFightCampConnector().sync(d);
        else
          new MockHealthConnector(value).sync(d, {
            hrv: 58,
            restingHr: 47,
            sleepMinutes: 342,
            heartRate: 76,
            workoutMinutes: 45,
          });
        await this.persist();
        break;
      case "fightcamp-demo": {
        const connector = new MockFightCampConnector();
        connector.connect(d);
        connector.seedHistory(d);
        await this.persist();
        break;
      }
      case "demo-history": {
        if (value !== "apple" && value !== "android")
          throw Error("Choose Apple Health or Health Connect demo data.");
        const connector = new MockHealthConnector(value);
        connector.connect(d);
        connector.seedHistory(d);
        await this.persist();
        break;
      }
      case "toggle-notify":
        d.settings ??= {};
        d.settings.notifications = !d.settings.notifications;
        await this.persist();
        break;
      case "next-day": {
        const w = d.wearables.at(-1);
        d.wearables.push({
          date: date(),
          hrv: (w?.hrv || 60) + 5,
          restingHr: (w?.restingHr || 45) - 2,
          sleepMinutes: (w?.sleepMinutes || 400) + 50,
          source: "Mock next day",
          mode: "MOCK",
        });
        for (const a of d.actions.filter((v) => v.completedAt && !v.nextDay))
          a.nextDay = {
            hrvDelta: 5,
            sleepMinutes: d.wearables.at(-1).sleepMinutes,
            restingHr: d.wearables.at(-1).restingHr,
            mood: d.checkins.at(-1)?.mood || null,
          };
        await this.persist();
        break;
      }
    }
  }
  tick() {
    if (
      this.route === "tonight" &&
      this.draft.running &&
      this.draft.seconds > 0
    ) {
      this.draft.seconds--;
      this.render();
    }
  }
  render() {
    const root = document.querySelector("#app");
    if (this.data?.onboarding?.stage === "connect")
      this.route = "connect-health";
    if (this.data?.onboarding?.stage === "ready") this.route = "baseline-intro";
    root.innerHTML = !this.data
      ? this.vault.exists()
        ? this.unlock()
        : this.setup()
      : this.view();
    if (this.route === "food-photo" && this.draft.editingId) {
      const form = root.querySelector("#food-entry");
      if (form) for (const key of ["mealType", "portions", "foodKey", "kcal", "protein", "carbs", "fat"])
        form.elements[key].value = this.draft[key];
    }
    window.lucide.createIcons();
  }
  setup() {
    return `<div class="screen setup-screen"><div class="onboarding-step">STEP 1 OF 3 · ATHLETE SETUP</div><h1>Recovery for Boxers</h1><p>Set up your private athlete profile</p>${this.error ? `<p class="error">${safe(this.error)}</p>` : ""}<form id="setup" class="setup-form"><label>Display name<input name="name" required autocomplete="nickname"></label><label>Next fight date<input type="date" name="fightDate" min="${localTomorrow()}" required><output data-fight-date-preview class="field-help">Select a date, e.g. ${exampleFightDate()}</output></label><label>Official weigh-in weight (kg) <span class="optional">Optional</span><input type="number" step="0.1" min="30" name="officialWeighInWeight"><span class="field-help">Used only for weight trend and safety monitoring.</span></label><label>Local passphrase<input name="passphrase" type="password" minlength="8" required><span class="field-help">At least 8 characters. Needed to unlock data on this device.</span></label><div class="consent-box"><details><summary>Read Privacy Notice</summary><p>We process your profile and, after the next step, any health, training, and recovery inputs to provide personal guidance. Data stays encrypted on this device. You can disconnect demo sources and delete local data in Settings. No advertising use or data sale.</p></details><label><input type="checkbox" name="privacy" value="yes"> I accept the Privacy Notice, prototype v1</label></div><button class="primary">Create profile</button></form><button class="text-button" data-action="demo">Try synthetic demo</button></div>`;
  }
  connectHealth() {
    const sources = [
      ["apple", "Apple Health", "Sleep, HRV, Resting HR, Workout"],
      ["android", "Health Connect", "Sleep, HRV, Resting HR, Workout"],
      [
        "fightcamp",
        "FightCamp",
        "Punch and session data; health metrics are separate synthetic demo data",
      ],
    ];
    return `<div class="screen setup-screen connect-health-screen"><div class="onboarding-step">STEP 2 OF 3 · HEALTH DATA</div><h1>Connect Health Data</h1><p>These are prototype sources. No real device or account connection is made.</p>${this.error ? `<p class="error">${safe(this.error)}</p>` : ""}${sources.map(([key, title, detail]) => card(`<div class="source-title"><strong>${title}</strong><span>Prototype / Demo</span></div><p>${detail}</p><button class="source-demo" data-action="onboarding-demo-source" data-value="${key}">Use demo data</button>`, "onboarding-source")).join("")}${card(`<button class="health-consent ${this.draft.healthConsent === "yes" ? "selected" : ""}" data-field="healthConsent" data-value="${this.draft.healthConsent === "yes" ? "no" : "yes"}">${icon(this.draft.healthConsent === "yes" ? "check-square" : "square", 18)} I consent to local processing of health, training, and recovery inputs for personal guidance.</button><p class="helper">Required even if you skip a wearable, because manual check-ins contain health-related data.</p>`, "health-consent-card")}<button class="secondary-wide" data-action="onboarding-skip">Skip for now</button><p class="field-help center-note">Skipped metrics will show Unavailable, never 0.</p></div>`;
  }
  baselineIntro() {
    const camp = CampClock.get(this.data.profile);
    const source = this.data.onboarding?.selectedSource;
    return `<div class="screen setup-screen baseline-intro-screen"><div class="onboarding-step">STEP 3 OF 3 · READY TO BEGIN</div><h1>Your fight camp starts here</h1>${card(`<div class="eyebrow">NEXT FIGHT</div><h2>${CampClock.formatDate(this.data.profile.fightDate)}</h2><div class="intro-stats"><div><strong>${camp.daysOut}</strong><span>days out</span></div><div><strong>${camp.phase}</strong><span>camp phase</span></div></div>`, "intro-fight-card")}${card(`<div class="eyebrow">PERSONAL BASELINE</div><h2>Learning your baseline — Day 1 of 7</h2><p>Recommendations become more personal as you record consistent days.</p>`, "intro-baseline-card")}${card(`<div class="eyebrow">AUTOMATICALLY TRACKED</div><p>Sleep · HRV · Resting HR</p><p class="field-help">${source ? `Using ${safe(source === "apple" ? "Apple Health" : source === "android" ? "Health Connect" : "synthetic health")} demo data. No real connection.` : "Unavailable until a demo source is chosen. You can still continue."}</p>`)}${card(`<div class="eyebrow">MANUAL INPUTS</div><p>Morning weight · Urine colour · Mood · Boxing training details</p>`)}${fixed("Start", "onboarding-start")}</div>`;
  }
  unlock() {
    return `<div class="screen setup-screen"><h1>Welcome back</h1><p>Unlock private athlete data</p>${this.error ? `<p class="error">${safe(this.error)}</p>` : ""}<form id="unlock" class="setup-form"><label>Passphrase<input name="passphrase" type="password" required></label><button class="primary">Unlock</button></form><button class="text-button" data-action="delete">Delete local data</button></div>`;
  }
  view() {
    const pages = {
      "connect-health": () => this.connectHealth(),
      "baseline-intro": () => this.baselineIntro(),
      today: () => this.today(),
      morning: () => this.morning(),
      training: () => this.training(),
      nutrition: () => this.nutrition(),
      "food-photo": () => this.foodPhoto(),
      fightcamp: () => this.fightcamp(),
      punch: () => this.fightcamp(),
      brain: () => this.brain(),
      tonight: () => this.tonight(),
      camp: () => this.camp(),
      trends: () => this.trends(),
      settings: () => this.settings(),
      connections: () => this.connections(),
    };
    return (pages[this.route] || pages.today)();
  }
  todayDataSources(assessment) {
    const moodLogged = this.data.checkins.some((check) => check.date === date() && check.mood);
    const fightCampDays = assessment.baseline.punch.count;
    return `<div class="today-input-links"><button data-route="morning">${icon("sun", 16)}<span><b>Morning check-in</b><small>${moodLogged ? "Mood logged today" : "Add mood and safety answers"}</small></span>${icon("chevron-right", 15)}</button><button data-route="fightcamp">${icon("target", 16)}<span><b>FightCamp data</b><small>${fightCampDays} of 4 session days · Demo</small></span>${icon("chevron-right", 15)}</button></div>${assessment.domains.sleep.status === "INSUFFICIENT_DATA" ? `<button class="card strip link-card wearable-help" data-route="connections"><b>${icon("watch", 16)} Sleep & Heart: ${Math.max(assessment.baseline.hrv.count, assessment.baseline.sleep.count)} of 7 baseline days</b><span>Demo data ${icon("chevron-right", 15)}</span></button>` : ""}`;
  }
  today() {
    const a = this.result,
      w = this.data.wearables.at(-1) || {},
      c = a.camp;
    return `<div class="screen today"><div class="top-date"><div><h1>${new Intl.DateTimeFormat("en", { weekday: "long" }).format(new Date())}</h1><p>${c.daysOut ?? "—"} days out · ${campPhaseText(c.phase)}</p></div><button class="icon-btn" data-route="settings">${icon("settings-2")}</button></div><div class="camp-progress"><span></span></div><div class="progress-label"><span>CAMP START</span><span>FIGHT NIGHT</span></div><div class="brake">● TODAY'S LIMITER · <b>${a.limiter ? LABELS[a.limiter].toUpperCase() : a.assessedCount < 4 ? "LEARNING BASELINE" : "NO PRIMARY LIMITER"}</b></div><p class="limiter-reason">${safe(a.reason)}</p>${recoveryGauge(RecoveryOverview.fromAssessment(a))}<div class="metric-grid">${card(`<div class="metric-label">${icon("activity", 13)} Last HRV</div><div class="metric-number">${Number.isFinite(w.hrv) ? w.hrv : "—"}<small> ${Number.isFinite(w.hrv) ? "ms" : "Unavailable"}</small></div><p>${safe(w.source || "No source")}</p>`)}${card(`<div class="metric-label">${icon("heart", 13)} Resting HR</div><div class="metric-number">${Number.isFinite(w.restingHr) ? w.restingHr : "—"}<small> ${Number.isFinite(w.restingHr) ? "bpm" : "Unavailable"}</small></div><p>Sleep ${Number.isFinite(w.sleepMinutes) ? Math.floor(w.sleepMinutes / 60) + "h " + (w.sleepMinutes % 60) + "m" : "Unavailable"}</p>`)}</div>${this.todayDataSources(a)}<button class="card strip link-card" data-route="brain"><b>${a.safety.length ? "Safety flag: review before training" : "Review Brain & Impact"}</b>${icon("chevron-right", 16)}</button>${card(`<div class="train-row"><span class="green">${icon("check", 17)}</span><div><b>YOU CAN TRAIN</b><p>${safe(a.allowed.join(" · ") || "Not enough data for training guidance")}</p></div></div><div class="train-row"><span class="red">${icon("circle-alert", 17)}</span><div><b>AVOID TODAY</b><p>${safe(a.avoid.join(" · ") || (a.limiter ? "No specific restriction" : "Not enough data to assess"))}</p></div></div>`, "train-card")}<div class="domains">${DOMAINS.map((k) => `<button class="domain ${a.domains[k].status === "RESTRICTED" ? "safety" : ""}" data-route="${k === "brain" ? "brain" : k === "power" ? "fightcamp" : "trends"}">${icon(k === "brain" ? "brain" : k === "sleep" ? "cloud-moon" : k === "power" ? "zap" : "heart", 15)}<b>${LABELS[k]}</b><span class="mini-track"><em style="width:${a.domains[k].status === "READY" ? 85 : a.domains[k].status === "CAUTION" ? 52 : a.domains[k].status === "RESTRICTED" ? 22 : 10}%;background:${statusColor(a.domains[k].status)}"></em></span></button>`).join("")}</div><button class="tonight-preview" data-route="tonight"><div><small>ONE THING TONIGHT</small><strong>${safe(a.action.title)}</strong></div><span>${icon("play", 16)}</span></button><button class="card strip link-card" data-route="food-photo"><b>${icon("camera", 17)} Food photo & today's intake</b>${icon("chevron-right", 16)}</button><div class="sync-line">${icon("watch", 13)} ${safe(w.source || "Wearable unavailable")} ${w.mode === "DEMO" || w.mode === "MOCK" ? "· Prototype / Demo" : ""}</div>${nav("today")}</div>`;
  }
  morning() {
    const x = this.draft,
      w = this.data.wearables.at(-1) || {};
    return `<div class="screen form-screen">${header("Morning check-in", "~30 s")}<div class="step-progress"><i></i><i></i><i></i></div>${card(`<div class="eyebrow">${icon("watch", 14)} ${safe(w.source || "WEARABLE UNAVAILABLE")}</div><div class="watch-stats"><div>${metricStrong(w.hrv)}<span>HRV</span></div><div>${metricStrong(w.restingHr)}<span>Resting HR</span></div><div>${metricStrong(w.sleepMinutes, (minutes) => `${Math.floor(minutes / 60)}:${String(minutes % 60).padStart(2, "0")}`)}<span>Sleep</span></div></div>`, "watch-card")}${card(`<div class="section-head"><b>1 · WEIGH IN</b><span>First thing, nothing on</span></div><div class="weight-step"><button data-action="weight-down">${icon("minus")}</button><strong>${x.weight !== undefined || this.data.checkins.at(-1)?.weight != null ? Number(x.weight ?? this.data.checkins.at(-1).weight).toFixed(1) : "--.-"}<small> kg</small></strong><button data-action="weight-up">${icon("plus")}</button></div>`)}${card(`<div class="section-head"><b>2 · URINE COLOUR</b></div><div class="urine-swatches">${["#ffffe6", "#fbfbd1", "#faecac", "#efd97b", "#d6be4e", "#af8d2f"].map((c, i) => `<button data-field="urine" data-value="${i}" class="${String(x.urine ?? 2) === String(i) ? "selected" : ""}" style="background:${c}"></button>`).join("")}</div><div class="scale-label"><span>Clear</span><b>${Number(x.urine ?? 2) + 1} selected</b><span>Dark</span></div>`)}${card(`<div class="section-head muted"><b>3 · HOW DO YOU FEEL</b><span>One tap</span></div><div class="moods">${["Flat", "Low", "OK", "Good", "Sharp"].map((m, i) => `<button data-field="mood" data-value="${m}" class="${x.mood === m ? "selected" : ""}"><span style="opacity:${0.35 + i * 0.13}"></span>${m}</button>`).join("")}</div>`)}${card(`<div class="section-head muted"><b>SAFETY CHECK</b></div><p class="helper">New symptoms after head contact?</p>${choice("symptom", ["No", "Yes"], x.symptom)}<p class="helper">Pain severity</p>${choice("painSeverity", ["None", "Mild", "Severe"], x.painSeverity)}`)}${fixed("Save check-in", "save-morning")}</div>`;
  }
  training() {
    const x = this.draft,
      type = x.type || "Sparring";
    return `<div class="screen form-screen">${header("After training", "~30 s")}<div class="eyebrow outside">WHAT DID YOU DO</div><div class="training-grid">${[
      ["Sparring", "hand"],
      ["Boxing / Technical", "target"],
      ["Conditioning", "activity"],
      ["Strength", "dumbbell"],
    ]
      .map(
        ([t, g]) =>
          `<button data-field="type" data-value="${t}" class="${type === t ? "selected" : ""}">${icon(g, 18)}<b>${t}</b></button>`,
      )
      .join(
        "",
      )}</div>${card(`<b>Duration</b>${choice("duration", ["30", "45", "60"], x.duration || "30")}<div class="divider"></div><b>Intensity</b>${choice("intensity", ["Easy", "Moderate", "Hard"], x.intensity || "Moderate")}${type === "Sparring" ? `<div class="divider"></div><div class="round-row"><b>Rounds</b><div><button data-action="round-down">${icon("minus")}</button><strong>${x.rounds || 0}</strong><button data-action="round-up">${icon("plus")}</button></div></div><b>Head contact</b>${choice("contact", ["Light", "Moderate", "Heavy"], x.contact || "Light")}` : ""}`)}${card(`<div class="section-head"><strong>Where are you sore</strong><span>Tap the spots</span></div><div class="body-map"><svg viewBox="0 0 105 155"><circle cx="53" cy="13" r="10"/><path d="M48 24 L36 30 L27 71 L35 75 L44 43 L43 86 L47 149 L55 149 L58 91 L61 149 L69 149 L72 87 L68 43 L77 75 L85 71 L72 30 L58 24 Z"/></svg><button class="spot shoulder" data-action="sore" data-value="Shoulder"></button><button class="spot core" data-action="sore" data-value="Core"></button><button class="spot calf" data-action="sore" data-value="Calf"></button></div><div class="sore-chips">${(x.soreness || []).map((s) => `<button data-action="sore" data-value="${s}">${s}</button>`).join("")}</div>`)}${fixed("Log session", "save-training")}</div>`;
  }
  nutrition() {
    const x = this.draft;
    const todaySessions = this.data.sessions.filter((session) => session.date === date());
    return `<div class="screen form-screen">${header("Food", "~20 s")}${todaySessions.length ? card(`<div class="training-saved"><span>${icon("check", 17)}</span><div><b>Training saved</b><p>${todaySessions.length} session${todaySessions.length === 1 ? "" : "s"} logged today</p></div><button data-route="training">Log another session</button></div>`, "training-saved-card") : ""}<div class="section-head outside muted"><b>POST-TRAINING CHECK</b><span>3 quick answers</span></div>${[
      [
        "meal",
        "Post-training meal",
        "Did you eat after training?",
        ["Yes", "No"],
        "check",
      ],
      [
        "protein",
        "Protein",
        "Did you complete your protein plan?",
        ["Yes", "No"],
        "heart",
      ],
      [
        "carbs",
        "Carbohydrates",
        "How much did you have today?",
        ["Low", "Medium", "High"],
        "zap",
      ],
    ]
      .map(([k, t, p, o, g]) =>
        card(
          `<div class="nutrition-prompt"><span>${icon(g, 22)}</span><div><h2>${t}</h2><p>${p}</p></div></div>${choice(k, o, x[k])}`,
        ),
      )
      .join(
        "",
      )}<button class="secondary-wide" data-route="food-photo">${icon("camera", 17)} Add a food photo & daily intake</button><div class="food-note">${icon("info", 16)} Optional photo log uses user-confirmed estimates. This quick recovery check stays separate.</div>${fixed("Save", "save-nutrition")}</div>`;
  }
  foodPhoto() {
    const { meals, totals } = this.foodJournal.today(this.data.foodMeals, date());
    const x = this.draft;
    const estimate = this.foodJournal.estimate("chickenRice", 1);
    const entry = x.foodEditor || x.photo;
    const photo = x.photo
      ? `<img class="food-photo-preview" src="${safe(x.photo)}" alt="Selected meal photo">`
      : `${icon("camera", 19)} <span>Take a photo of your meal</span>`;
    return `<div class="screen food-photo-screen">${header("Food", "TODAY")}${this.error ? `<p class="error">${safe(this.error)}</p>` : ""}<div class="section-head outside muted"><b>SNAP YOUR PLATE</b><span>${meals.length} meal${meals.length === 1 ? "" : "s"} logged</span></div><label class="food-capture" for="meal-photo"><span class="food-capture-icon">${icon("camera", 18)}</span>${x.photo ? "Change photo" : "Take or choose a meal photo"}</label><input id="meal-photo" class="visually-hidden" type="file" accept="image/*" capture="environment">${entry ? `<form id="food-entry" class="card food-entry"><div class="food-entry-head">${photo}<button type="button" data-action="food-cancel" aria-label="Cancel meal">${icon("x", 16)}</button></div><p class="food-estimate-note">Choose the food and serving, then correct the estimates. The photo is not analyzed automatically.</p><div class="food-form-row"><label>Meal<select name="mealType"><option>Breakfast</option><option selected>Lunch</option><option>Dinner</option><option>Snack</option></select></label><label>Servings<select name="portions"><option value="0.5">½</option><option value="1" selected>1</option><option value="1.5">1½</option><option value="2">2</option><option value="3">3</option><option value="4">4</option></select></label></div><label class="food-field">Food<select name="foodKey">${Object.entries(FoodJournal.foods).map(([key, food]) => `<option value="${key}">${food.name}</option>`).join("")}</select></label><div class="food-nutrient-grid">${[["kcal", "kcal"], ["protein", "Protein g"], ["carbs", "Carbs g"], ["fat", "Fat g"]].map(([key, label]) => `<label>${label}<input name="${key}" type="number" min="0" max="5000" step="1" value="${estimate[key]}" required></label>`).join("")}</div><p class="food-estimate-note">Per-serving values are rough examples. Use the label or your own recipe for better accuracy.</p></form>` : ""}${meals.slice().reverse().map((meal) => card(`<div class="food-meal-top">${meal.photo ? `<img src="${safe(meal.photo)}" alt="${safe(meal.description)}">` : `<div class="food-placeholder">${icon("plus-circle", 19)}</div>`}<div><strong>${safe(meal.mealType)} — ${safe(meal.time)}</strong><p>${safe(meal.description)}</p><span class="food-kcal">${meal.kcal} kcal</span></div></div><div class="food-macros">${[["Protein", meal.protein, "protein"], ["Carbs", meal.carbs, "carbs"], ["Fat", meal.fat, "fat"]].map(([label, amount, cls]) => `<div><span>${label}</span><b>${amount}g</b><i class="${cls}"></i></div>`).join("")}</div><div class="food-confirmed">${icon("check", 14)} ${safe(meal.source || "User confirmed estimate")}<button data-action="food-edit" data-value="${safe(meal.id)}">Correct</button></div>`, "food-meal-card")).join("")}${card(`<div class="eyebrow">TODAY SO FAR</div><div class="food-summary"><div class="food-summary-ring"><strong>${meals.length}</strong><span>meals</span></div><div><div><span>Energy</span><strong>${totals.kcal} kcal</strong></div><div><span>Protein</span><strong>${totals.protein}g</strong></div><div><span>Carbs</span><strong>${totals.carbs}g</strong></div><div><span>Fat</span><strong>${totals.fat}g</strong></div></div></div>`, "food-summary-card")}<div class="food-note">${icon("info", 16)} These totals include only meals you log. Estimates are for awareness, not a calorie or weight-cutting target.</div>${entry ? `<div class="fixed-action"><button class="primary" type="submit" form="food-entry">Save meal</button></div>` : fixed("Add meal without a photo", "food-add")}</div>`;
  }
  fightcamp() {
    const sessions = this.data.fightCampSessions || [],
      connected = ["MOCK_CONNECTED", "CONNECTED"].includes(this.data.connections.fightcamp?.status),
      latest = connected ? sessions.at(-1) : null,
      baseline = this.result.baseline.punch,
      power = this.result.domains.power;
    const value = (metric) => Number.isFinite(metric) ? metric : "Unavailable";
    return `<div class="screen form-screen fightcamp-screen">${header("FightCamp", "Prototype / Demo")}${card(`<div class="eyebrow">BOXING PERFORMANCE SOURCE</div><h2>${connected ? "Mock connected" : "Unavailable"}</h2><p>${connected ? "Synthetic FightCamp sessions stored locally. No real account or API connection." : "Connect the mock source to preview punch and session data."}</p>`, "fightcamp-source")}${card(`<div class="section-head"><b>LATEST SESSION</b><span>${safe(latest?.date || "No data")}</span></div><div class="fightcamp-metrics">${[["Punch count", value(latest?.count)], ["Speed · demo", value(latest?.speed)], ["Output · demo", value(latest?.output)], ["Rounds", value(latest?.rounds)]].map(([label, metric]) => `<div><span>${label}</span><strong>${metric}</strong></div>`).join("")}</div><p class="helper">${safe(latest?.source || "FightCamp source unavailable")}</p>`, "fightcamp-latest")}${card(`<div class="eyebrow">POWER & SPEED</div><h2>${power.status.replace("_", " ")}</h2><p>${safe(power.reasons.join(" · ") || "No FightCamp session data yet.")}</p><p class="helper">${baseline.count} of 4 session days for a personal punch-count baseline.</p>`, "lime-card")}${card(`<div class="eyebrow">RECENT FIGHTCAMP SESSIONS</div>${sessions.length ? sessions.slice(-4).reverse().map((session) => `<div class="history-row"><span>${safe(session.date)} · ${safe(session.source)}</span><b>${value(session.count)} punches · ${value(session.rounds)} rounds</b></div>`).join("") : "<p>No FightCamp sessions yet.</p>"}`)}<button class="primary fightcamp-demo-button" data-action="fightcamp-demo">Load mock FightCamp history</button>${connected ? `<button class="secondary-wide" data-action="sync" data-value="fightcamp">Sync mock session</button>` : ""}<button class="secondary-wide" data-route="connections">Connected sources</button></div>`;
  }
  brain() {
    const a = this.result,
      r = a.domains.brain,
      flags = a.safety.filter((f) => f.domain === "brain");
    return `<div class="screen brain-screen">${header("Brain")}${card(`<div class="eyebrow">HEAD CONTACT</div><div class="head-rounds"><strong>${this.data.sessions.filter((s) => s.type === "Sparring").reduce((n, s) => n + s.rounds, 0)}</strong><b>reported rounds</b></div><p>Based on your training log</p>`)}${card(`<div class="eyebrow">CURRENT STATUS</div><h2>${r.status.replace("_", " ")}</h2><p>${safe(r.reasons.join(" · ") || "Not enough data.")}</p>`)}${flags.map((f) => card(`<div class="flag-label">${icon("alert-triangle", 18)} SAFETY FLAG</div><h2>Avoid head-impact training.</h2><p>${safe(f.message)}</p><div class="divider"></div><p class="muted">This app does not diagnose injury or provide medical clearance.</p>`, "flag-card")).join("")}${!flags.length ? card("<p>No current safety flag from entered data. This is not medical clearance.</p>") : ""}</div>`;
  }
  tonight() {
    const a = this.result.action,
      x = this.draft,
      seconds = x.seconds ?? a.seconds,
      insight = this.feedback.insight(this.data, a.id);
    return `<div class="screen tonight-screen"><header class="night-head"><button class="icon-btn" data-route="today">${icon("chevron-down")}</button><h1>Tonight</h1><span>Recovery</span></header><div class="night-copy"><div class="eyebrow">ONE THING, THEN SLEEP</div><h2>${safe(a.title)}</h2><p>${safe(a.reason)}</p></div><div class="timer-ring"><strong>${String(Math.floor(seconds / 60)).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}</strong><span>Take it at your own pace</span></div><button class="timer-button" data-action="timer">${icon(x.running ? "pause" : "play", 17)} ${x.running ? "Pause" : "Start"}</button><div class="night-controls"><button data-action="timer-reset">Reset</button><button data-action="timer-complete" ${x.startedAt ? "" : "disabled"}>Complete</button></div><div class="night-history"><div class="eyebrow">${icon("rotate-ccw", 15)} DID IT HELP?</div><h2>${insight.label}</h2><p>${safe(insight.detail)}</p></div></div>`;
  }
  campRecovery() {
    const history = this.data.assessments.slice(-7);
    return card(
      `<div class="eyebrow">RECOVERY TREND</div><div class="recovery-bars">${history.length ? history.map((x) => `<span style="height:${18 + DOMAINS.filter((k) => x.result.domains[k].status === "READY").length * 9}px;background:${x.result.safety.length ? "#ad493e" : "#b9df2e"}"></span>`).join("") : "<p>Not enough data yet</p>"}</div><p class="helper">Ready domains across recent assessments</p>`,
    );
  }
  camp() {
    const p = this.data.profile,
      c = CampClock.get(p),
      weights = this.data.checkins.map((x) => x.weight).filter(Number.isFinite);
    return `<div class="screen camp-screen"><div class="camp-head"><div><h1>Camp</h1><p>${CampClock.formatDate(p.fightDate)}${profileWeight(p) !== null ? ` · ${profileWeight(p)} kg official weigh-in` : ""}</p></div><span>${c.daysOut ?? "—"} days out</span></div><div class="camp-phases">${["BASE", "BUILD", "PEAK", "TAPER"].map((s) => `<div class="${c.phase === s ? "active" : ""}"><b>${s}</b><i></i></div>`).join("")}</div><p class="camp-summary">Current phase: ${c.phase}. Safety restrictions take priority.</p>${card(`<div class="section-head muted"><b>WEIGHT TREND</b><strong>${weights.length ? weights.at(-1).toFixed(1) + " kg" : "Unavailable"}</strong></div><div class="weight-chart"><svg viewBox="0 0 320 110"><path d="${weightPath(weights)}" fill="none" stroke="#4c65e8" stroke-width="3"/></svg></div><div class="scale-label"><span>${weights.length} check-ins</span><b>today</b><strong>fight date</strong></div>`, "weight-card")}${this.campRecovery()}${card(`<div class="safe-title">${icon("shield-check", 18)} WEIGHT & RECOVERY</div><p>Weight is recovery context. Discuss weight-management decisions with a qualified professional.</p>`, "safe-card")}<button class="secondary-wide" data-route="settings">Edit fight details</button>${nav("camp")}</div>`;
  }
  historySection() {
    const d = this.data;
    return card(
      `<div class="eyebrow">RECENT WEARABLE HISTORY</div>${
        d.wearables
          .slice(-7)
          .reverse()
          .map(
            (w) =>
              `<div class="history-row"><span>${safe(w.date)} · ${safe(w.source)}</span><b>HRV ${w.hrv ?? "—"} · Sleep ${w.sleepMinutes ?? "—"}m · RHR ${w.restingHr ?? "—"}</b></div>`,
          )
          .join("") || "<p>No wearable data</p>"
      }<div class="eyebrow history-heading">WEIGHT & FIGHTCAMP</div>${d.checkins
        .slice(-5)
        .reverse()
        .map(
          (x) =>
            `<div class="history-row"><span>${safe(x.date)} weight</span><b>${x.weight ?? "—"} kg</b></div>`,
        )
        .join("")}${(d.fightCampSessions || [])
        .slice(-5)
        .reverse()
        .map(
          (x) =>
              `<div class="history-row"><span>${safe(x.date)} FightCamp demo</span><b>${x.count ?? "—"} punches · ${x.rounds ?? "—"} rounds</b></div>`,
        )
        .join("")}<div class="eyebrow history-heading">RECOVERY ACTIONS</div>${
        d.actions
          .slice(-5)
          .reverse()
          .map(
            (x) =>
              `<div class="history-row"><span>${safe(x.date)} ${safe(x.id)}</span><b>${x.nextDay ? "Follow-up recorded" : "Awaiting next day"}</b></div>`,
          )
          .join("") || "<p>No completed actions</p>"
      }`,
    );
  }
  trends() {
    const d = this.data,
      w = d.wearables.at(-1) || {},
      a = this.result;
    return `<div class="screen form-screen">${header("Trends")}<div class="history-grid">${[
      ["HRV", w.hrv ?? "Unavailable"],
      ["Sleep", w.sleepMinutes ?? "Unavailable"],
      ["Resting HR", w.restingHr ?? "Unavailable"],
      ["Weight", d.checkins.at(-1)?.weight ?? "Unavailable"],
      ["FightCamp sessions", (d.fightCampSessions || []).length],
      ["Actions done", d.actions.length],
    ]
      .map(([k, v]) =>
        card(`<div class="eyebrow">${k}</div><strong>${v}</strong>`),
      )
      .join(
        "",
      )}</div>${card(`<div class="eyebrow">DOMAIN HISTORY</div>${DOMAINS.map((k) => `<div class="history-row"><span>${LABELS[k]}</span><b style="color:${statusColor(a.domains[k].status)}">${a.domains[k].status}</b></div>`).join("")}`)}${card(`<div class="eyebrow">TRAINING LOAD</div>${["Sparring", "Boxing / Technical", "Conditioning", "Strength"].map((k) => `<div class="history-row"><span>${k}</span><b>${d.sessions.filter((s) => s.type === k).length} sessions</b></div>`).join("")}`)}${card(
      `<div class="eyebrow">LIMITER HISTORY</div><p>${
        d.assessments
          .slice(-5)
          .map((x) =>
            x.result.limiter ? LABELS[x.result.limiter] : "Learning baseline",
          )
          .join(" · ") || "No assessments yet"
      }</p>`,
    )}${this.historySection()}${nav("trends")}</div>`;
  }
  connections() {
    return `<div class="screen form-screen">${header("Connected sources")}<p class="camp-summary">Mock adapters only. Native device permissions and official FightCamp access are not connected.</p>${[
      ["apple", "Apple Health"],
      ["android", "Health Connect"],
      ["fightcamp", "FightCamp (mock)"],
    ]
      .map(([key, label]) => {
        const c = this.data.connections[key],
          ok = c?.status === "MOCK_CONNECTED";
        return card(
          `<div class="section-head"><strong>${label}</strong><span>${ok ? "Mock connected" : "Unavailable"}</span></div><p class="helper">Source: ${safe(c?.source || "None")}</p><div class="source-actions"><button data-action="${ok ? "disconnect" : "connect"}" data-value="${key}">${ok ? "Disconnect mock" : "Connect mock"}</button>${ok ? `<button data-action="sync" data-value="${key}">Sync sample</button>` : ""}${key === "fightcamp" ? `<button data-action="fightcamp-demo">Load mock FightCamp history</button>` : `<button data-action="demo-history" data-value="${key}">Load 7-day synthetic history</button>`}</div>`,
        );
      })
      .join(
        "",
      )}<button class="secondary-wide" data-route="settings">Back to settings</button></div>`;
  }
  settings() {
    const p = this.data.profile;
    return `<div class="screen form-screen">${header("Settings")}<form id="profile" class="setup-form card"><label>Display name<input name="name" value="${safe(p.name)}" required></label><label>Next fight date<input name="fightDate" type="date" min="${localTomorrow()}" value="${safe(p.fightDate)}" required><output data-fight-date-preview class="field-help">${CampClock.formatDate(p.fightDate)}</output></label><label>Official weigh-in weight (kg) <span class="optional">Optional</span><input name="officialWeighInWeight" type="number" step="0.1" min="30" value="${profileWeight(p) ?? ""}"><span class="field-help">Used only for weight trend and safety monitoring.</span></label><button class="primary">Save profile</button></form>${card(`<div class="eyebrow">PRIVACY & CONSENT</div><p>Privacy Notice accepted ${safe((this.data.consent.privacyAcceptedAt ?? this.data.consent.acceptedAt ?? "").slice(0, 10))}. Data is encrypted on this device.</p>`)}<button class="secondary-wide" data-route="connections">Connected devices & permissions</button><button class="secondary-wide" data-action="toggle-notify">Reminder preference: ${this.data.settings?.notifications ? "On" : "Off"} (not scheduled yet)</button><button class="secondary-wide" data-action="lock">Lock app</button>${this.data.consent.mockOnly ? '<button class="secondary-wide" data-action="next-day">Advance mock data to next day</button>' : ""}<button class="secondary-wide danger" data-action="delete">Delete local account and data</button><p class="helper">Notifications and real device permissions require a native build.</p></div>`;
  }
}
new BoxerApp();
