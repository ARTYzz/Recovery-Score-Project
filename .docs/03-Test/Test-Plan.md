# Recovery Score App — Test Plan

> **Planned protocol, not an execution report.** This plan was written before the current iOS/HealthKit implementation and still names retired prototype flows such as a local passphrase, mock Apple Health/Health Connect, and a manual Punch Test. Use [README.md](../../README.md) and [spec.md](../01-requirements/spec.md) for current behavior. The planned real-boxer UAT did not occur. Actual PROXY sessions, results, gaps, and retest status are recorded in [session-logs.md](session-logs.md), [sus-results.md](sus-results.md), [issue-log.md](issue-log.md), and [no-real-user-test.md](../../test/no-real-user-test.md). Unexecuted test cases below are not pass claims.

## 1. Overview and objectives
Testing runs from 1 to 29 November 2026. It checks that the Recovery Score app (Flutter, Android + web demo) helps boxers make safer daily training decisions with less than about 90 seconds of input per day.

**Objectives:**
1. Verify that recovery logic (six domains, Safety Gate, training advice) gives correct, safe outputs.
2. Confirm that real athletes can complete the core daily workflow without help.
3. Measure improvement in task results before and after use, plus usability (SUS) and acceptance (TAM).

## 2. Scope

### In scope
- Onboarding: athlete profile, Privacy Notice, Health Data preview, fight countdown, 7-day baseline intro
- Synthetic demo mode and restart with fresh demo data
- Morning Check-in (sleep, HRV, resting HR, mood, soreness/pain)
- Today screen: six-domain recovery status, "Not Enough Data" and baseline-learning states
- Training guidance for Sparring, Boxing / Technical, Conditioning and Strength
- Training log (type, duration, intensity, contact, body area, soreness)
- Safety Gate for severe pain and concerning head symptoms
- Nutrition quick check and optional Food journal
- "One thing tonight" recovery action and Next Morning review
- Encrypted local vault, passphrase unlock, data persistence after reload
- Demo health sources (Apple Health / Health Connect / FightCamp adapters): connect, disconnect, restore

### Out of scope
- Real Apple Health, Health Connect, FightCamp or smart-scale integrations (the app uses mock adapters only)
- Cloud sync, backend accounts, multi-device use
- Clinical validation of thresholds (e.g. the 60-minute load rule); the app is not a medical tool
- iOS builds and data migration from the legacy Capacitor app

## 3. Test levels

| Level | What is tested | Method / tool | Owner | Exit criteria |
| :--- | :--- | :--- | :--- | :--- |
| **Unit** | `lib/domain/`: RecoveryEngine, TrainingAdvisor, Safety Gate, personal baselines | flutter test | Developers | 100% of unit tests pass |
| **Integration** | `lib/data/` + `lib/app/`: encrypted vault, demo adapters, onboarding/check-in controller | flutter test with widget/integration tests | Developers | Data saves and reloads correctly; no data loss |
| **System** | Full app on Android APK and Chrome (390 px mobile layout) | Manual test cases in section 4 | QA / team | All high-priority cases pass; no open critical bugs |
| **UAT** | Real boxers complete daily tasks | Moderated sessions (sections 5–6) | Team + participants | $\ge 10$ sessions done; task success $\ge 80\%$; SUS $\ge 68$ |

## 4. Test cases
Twenty system test cases cover the in-scope features; H = must pass before UAT starts.

| ID | Feature | Steps / input | Expected result | Priority |
| :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Onboarding | Fresh install → enter profile → accept Privacy Notice → Start | Health Data preview, countdown and baseline intro shown; Morning Check-in opens | H |
| **TC-02** | Onboarding | Try to continue without accepting Privacy Notice | Cannot continue | H |
| **TC-03** | Demo mode | Fresh install → Try synthetic demo | Predefined athlete opens on Today with history | H |
| **TC-04** | Demo mode | Settings → Restart with fresh demo data | Demo data reset; no old sessions remain | M |
| **TC-05** | Morning Check-in | Unlock on a new day | Check-in opens once; after saving, goes to Today and not again that day | H |
| **TC-06** | Baseline | Fewer than 7 days of data | Sleep shown on Today; Sleep & Heart domain shows baseline learning, no score claimed | H |
| **TC-07** | Recovery status | Only one observation after an action | Labelled "Not Enough Data"; no causation claim | M |
| **TC-08** | Training guidance | Open Review training guidance | Four types shown with separate advice | H |
| **TC-09** | Training rule | Log Strength > 60 min with shoulder soreness | Advice: rest upper body, avoid another upper-body session | H |
| **TC-10** | Training rule | Log repeated heavy head contact within 7 days | Sparring advice restricted | H |
| **TC-11** | Safety Gate | Report severe pain | Safety Gate shown before any training advice | H |
| **TC-12** | Safety Gate | Report concerning head symptoms | Safety Gate shown; sparring not recommended | H |
| **TC-13** | Training log | Log session then reload browser | Session still shown on Today | H |
| **TC-14** | Nutrition | Complete Yes/No, protein, carbohydrate check | Saved; returns to Today | M |
| **TC-15** | Food journal | Add photo, choose preset and serving, edit | Entry and daily totals saved; no automatic food recognition claimed | L |
| **TC-16** | One thing tonight | Start → Complete action | Marked complete on Today | M |
| **TC-17** | Next Morning | Continue to next morning (demo) → save check-in | Next Morning shows HRV, sleep, resting HR, mood, domain status | M |
| **TC-18** | Security | Reload a real athlete profile | Passphrase required; wrong passphrase rejected | H |
| **TC-19** | Health sources | Disconnect and restore each demo source in Settings | Each source changes independently; labelled Demo | M |
| **TC-20** | Layout | Run in Chrome and on Android | 390 px layout; no overflow on domain cards | L |
| **TC-21** | Consent | Fresh install → profile step; look at the Privacy Notice checkbox before tapping anything | Checkbox is not pre-checked; Start stays disabled until the user ticks it | H |
| **TC-22** | Consent record | Accept Privacy Notice → inspect the stored profile record | Record holds the notice version, date and time of acceptance, and is linked to this athlete profile | H |
| **TC-23** | Withdraw / delete | Settings → withdraw consent or delete my data → confirm → reload | All personal and health data removed; app returns to first-run screen; no old data after reload | H |
| **TC-24** | Access / correct | Open own profile and history → correct a wrong value (e.g. body weight) → save | User can view own data; corrected value is saved and used in the assessment | M |
| **TC-25** | Data exposure | In Chrome with DevTools open, complete a check-in and log training; trigger an error (e.g. wrong passphrase) | No health values (HRV, sleep, pain, weight, mood) in the URL, console logs or error messages | H |
| **TC-26** | Encryption at rest | Save a check-in → DevTools → Application → inspect local storage / IndexedDB | Stored health data is encrypted; no readable health values | H |

*Note: Bugs are logged with ID, steps, severity (Critical / Major / Minor) and retest result.*

## 5. UAT tasks
Each participant does the same seven tasks without help, thinking aloud. The moderator records success (completed / with help / failed), time and errors.

| Task | Scenario given to the participant | Success criterion | Target time |
| :--- | :--- | :--- | :--- |
| **T1** | "Set up the app for your fight camp." | Profile saved, Privacy accepted, reaches Check-in | $\le 3$ min |
| **T2** | "Do your morning check-in." | Check-in saved | $\le 60$ s |
| **T3** | "Find out what is limiting your recovery today." | Names the limiting domain correctly | $\le 30$ s |
| **T4** | "You planned sparring today. Should you do it?" | Reads the Sparring advice and states it correctly | $\le 45$ s |
| **T5** | "Log the training you just did and check nutrition." | Session and Nutrition saved | $\le 90$ s |
| **T6** | "What should you prioritise tonight?" | Opens and completes One thing tonight | $\le 30$ s |
| **T7** | "You have severe shoulder pain. What does the app tell you?" | Sees Safety Gate and states its message | $\le 30$ s |

*Note: T2 + T5 together test the goal of daily input under about 90 seconds (excluding setup).*

## 6. Participants and sessions
At least 10 real users join 12 planned sessions (2 extra for no-shows), each 45–60 minutes.
- **Who:** 5-10 boxers (amateur or professional, training $\ge 3$ times a week) 
- **Recruit from:** MFU Gym
- **Format:** one-to-one, in person at the gym or online by screen share; Android phone or Chrome provided with the latest build
- **Session flow:** consent (5 min) → baseline "before" tasks (10 min) → app tasks T1–T7 (20 min) → SUS + TAM questionnaires (10 min) → short interview (10 min)
- **Roles:** 1 moderator + 1 note-taker per session
- **Data:** participants use synthetic demo data only; no real health data is collected. Recordings need written consent and are deleted after analysis.

## 7. Metrics
Success = task success $\ge 80\%$, SUS mean $\ge 68$ and TAM construct means $\ge 5.0 / 7$.

### 7.1 Task results: before and after
Before: each participant does T3, T4 and T6 using their current method (notes, memory, a generic fitness app or asking the coach) with the same scenario data on paper. After: they do the same tasks in the app. Order is fixed (before → after) so the app does not teach the answer first.

| Measure | How recorded | Compared |
| :--- | :--- | :--- |
| **Task success rate (%)** | Completed without help | Before vs after, per task |
| **Time on task (s)** | Stopwatch from scenario read to answer | Before vs after (median) |
| **Errors (count)** | Wrong answer or wrong screen | Before vs after |
| **Decision correctness** | Answer matches the expected safe decision | Before vs after |
| **Daily input time (s)** | T2 + T5 in the app | Against the 90 s target |
| **Help requests (count)** | Moderator interventions | After only |

*Analysis: paired comparison per participant (Wilcoxon signed-rank test for $n \approx 10$).*

### 7.2 System Usability Scale (SUS)
Standard 10-item SUS, 5-point scale, given right after T7. Score 0–100; $68$ = average, $\ge 80$ = good.

### 7.3 Technology Acceptance Model (TAM)
7-point Likert (1 = strongly disagree, 7 = strongly agree), 12 items.

| Construct | Example items |
| :--- | :--- |
| **Perceived usefulness (PU)** | "The app helps me decide what training is safe today." · "The app helps me plan recovery for tonight." · "Using the app would improve my fight camp." · "The app shows what is limiting my recovery." |
| **Perceived ease of use (PEOU)** | "The app is easy to use." · "The daily check-in is quick." · "I understand the recovery status." · "I can use it without help." |
| **Behavioural intention (BI)** | "I would use the app every day of my camp." · "I would recommend it to other boxers." · "I would share it with my coach." · "I intend to keep using it." |

*Report mean and standard deviation per construct; Cronbach's alpha checks reliability.*

## 8. Testing schedule
*test schedule · 1–29 Nov 2026*
System testing must pass all H cases before the pilot on 15 Nov; the pilot fixes task wording before UAT starts.

## 9. Risks, ethics and deliverables

| Risk | Mitigation |
| :--- | :--- |
| **Fewer than 10 boxers available** | Recruit 12; add coaches; allow online sessions |
| **Critical bug found in UAT** | Hot-fix window 13–14 Nov; retest affected cases |
| **Participants treat advice as medical** | Brief states the app is a prototype, not medical advice |
| **Before/after learning effect** | Same scenario, fixed order; report it as a limitation |

*Ethics: informed consent, synthetic data only, anonymised participant IDs (P01–P12), recordings deleted after analysis.*
