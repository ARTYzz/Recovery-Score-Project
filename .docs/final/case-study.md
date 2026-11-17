# Case Study: Boxer Recovery App

**Role:** Product Owner /  Developer / Designer / QA tester / Tech Lead

**Timeline:**  Sept 2026 – Nov 2026 

**Live URL:** no public web deployment yet. The Android build is in the repo at [output/BoxerRecovery-debug.apk](../../output/BoxerRecovery-debug.apk); setup steps are in [README.md](../../README.md). _TO FILL: add the live URL if one is deployed._

> **Evidence note:** no real boxers have tested the app yet. All test results below come from **PROXY** users (8 friends outside the team, not boxers) on 17 Nov 2026 — see [no-real-user-test.md](../../test/no-real-user-test.md).

## 1. The Problem

Professional and amateur boxers undergo intense, grueling "fight camps" leading up to a bout. During this phase, balancing training load and recovery is critical to avoid overtraining, injuries, or peaking too early. However, athletes face several massive hurdles:
* **Fragmented Data:** Boxers track data across multiple disjointed sources (smartwatches for sleep, FightCamp for punches, paper logs for sparring).
* **Information Overload:** Wearables provide raw numbers (e.g., HRV, resting HR) but lack actionable, boxing-specific context. 
* **Safety Blind Spots:** Generic fitness apps do not account for neurological risks (head impacts from sparring) or the dangers of extreme weight cutting.
* **Time Constraints:** Boxers need fast insights. They do not have time to navigate complex sports-science dashboards every morning.

**The Goal:** Build a centralized, mobile-first recovery application that takes **less than 90 seconds a day** to use. It must answer three critical questions for the athlete: *What is limiting me today? What can I train (and what should I avoid)? What is one thing I should do tonight to recover?*

---

## 2. The Process

To address these challenges, we defined a strict product backlog and system specification tailored exclusively for fighters.

### A. Establishing Medical Constraints & Safety First (The "Safety Gate")
Before writing any core logic, we established strict non-functional constraints. The app is not a medical device. We built a **Safety Gate** that executes before any recovery recommendations. If an athlete reports severe post-impact head symptoms or extreme rapid weight changes, the app immediately overrides performance metrics, restricts sparring, and flags a safety warning.

### B. Defining the 6-Domain Recovery Model
Instead of a single, vague "Readiness Score," we designed a Recovery Engine that evaluates six independent domains:
1. Brain & Impact Load
2. Energy / Nutrition / Weight
3. Autonomic / Sleep Recovery (Sleep & Heart)
4. Neuromuscular Power (Power & Speed)
5. Physical / Structural Recovery (Body)
6. Mental / Fight Stress (Mind)

### C. Streamlining the User Journey (The 90-Second Loop)
We designed the daily flow to minimize friction:
* **Automated Syncing:** Real Apple Health import on iPhone (sleep, HRV, resting HR, workouts). Health Connect is designed for but not yet integrated. FightCamp punch data is a clearly labelled mock.
* **Morning Check-In:** A tap-based flow (no typing) for morning weight, urine color, and mood, designed for a 30-second target.
* **Smart Training Logs:** Segmented training loads into four boxing-specific categories (Sparring, Boxing/Technical, Conditioning, Strength) so the app knows *exactly* what type of fatigue is accumulating.

### D. Testing
We built a functional prototype (Flutter/Android/Web). A real-user test with boxers at MFU Gym was planned ([Test-Plan.md](../03-Test/Test-Plan.md)) but could not be run in time: we could not recruit boxers in camp before the deadline, and the app is not yet in an app store. Instead we:
* ran **85 automated tests** (85/85 pass on `main`, 18 Nov 2026);
* ran a moderated, timed task test (T1–T7) with **8 PROXY users** — friends outside the team who are not boxers — followed by a SUS survey ([session-logs.md](../03-Test/session-logs.md), [sus-results.md](../03-Test/sus-results.md));
* did a heuristic review and collected published research as SECONDARY evidence ([no-real-user-test.md](../../test/no-real-user-test.md)).

---

## 3. The Outcome

First-time PROXY users could complete every core task, but the app is not yet fast or easy enough. All numbers are from PROXY users (n = 8, not boxers) unless stated; full table in [comparison-table.md](comparison-table.md).

### Key Metrics
* **Task success:** 56/56 tasks completed (100%); **51/56 without help (91%)**, above the 80% target.
* **Sparring decision (T4):** median **37.5 s**, within the 45 s target. A by-hand "before" time for this task was not measured separately.
* **Daily input (T2 + T5):** median **122.5 s** — **above** the 90 s goal; only 1 of 8 users was under 90 s.
* **Total time T1–T7:** by hand (TEAM, 1 run) 226 s vs in the app median 352.5 s — the app was **56% slower** for first-time users.
* **SUS:** **56.9**, below the 68 average.
* **Acceptance items** (10 team-written items, 5-point): mean **4.25 / 5** — from non-boxers, so it does not show that fighters find it useful.
* **Automated tests:** 85/85 pass, including 29 recovery-rule and Safety Gate tests.

### Lessons Learned & Next Steps
The core logic works as specified in tests, but usability is below average. PROXY feedback ([issue-log.md](../03-Test/issue-log.md)):
1. **Data entry:** training/nutrition entry (T5) caused 4 of 10 errors — simplify it first (I-01).
2. **Localization:** Thai translation is incomplete in places (I-02).
3. **Visual polish:** text-heavy screens, few icons (I-10).
4. **AI Integration:** one respondent asked for **"AI Advice" (มีAiแนะนำ)**. The app currently has no AI; this is a possible future feature, not yet in the backlog.
5. **Real-user test:** run the [ready-to-run plan](../../test/no-real-user-test.md) with boxers once a store/test build is available.
