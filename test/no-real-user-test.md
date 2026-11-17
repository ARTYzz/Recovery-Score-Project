# No Real-User Test

**Status:** The app has **not** been tested with real users (professional boxers in fight camp). Instead it was tested with **8 PROXY users** (friends outside the team, not boxers). This document records why, what we tested instead, what the team measured itself, and a ready-to-run plan for a real-user test.

No number in this file comes from a real user. Each piece of evidence is labelled with its source type:

| Label | Meaning |
|---|---|
| **AUTOMATED** | Our own automated tests in `test/` |
| **TEAM** | Measured or reviewed by team members (not real users) |
| **PROXY** | People outside the team who are not the target user (not boxers in camp) |
| **SECONDARY** | Published research, reviews or public data, with a source link |

---

## 1. Why there is no real-user test

1. **Could not recruit target users in time.** The target user is a professional boxer currently in fight camp. We could not find boxers in camp who were available to test before the deadline.
2. **The app is not in an app store yet.** Building and publishing to the App Store / Google Play was not finished. Without a store build, a boxer cannot install the app on their own phone and use it for several days in a real camp; the app could only be tried on a team device with a development build.

Because of this we tested with PROXY users on a team device instead (section 2.4).

What this means: every task time, completion rate, error count and SUS score we report comes from PROXY users and must be labelled PROXY. We cannot claim how boxers in camp would perform or rate the app.

---

## 2. What we tested instead

### 2.1 Automated tests (AUTOMATED)

Branch `main` at commit `65d7ba5` contains 85 `test(...)` / `testWidgets(...)` cases across 16 files (count from `grep` on `test/*.dart`). They check rules, data handling and some UI behaviour, not usability with people.

| File | Cases | What it checks | Backlog items |
|---|---|---|---|
| [recovery_engine_test.dart](recovery_engine_test.dart) | 27 | Six independent domain scores; limiter = lowest measured domain; head symptoms and severe pain override training advice; weight change flagged without cut advice; missing HRV stays missing; urine colours (incl. red/purple) handled without a medical claim | US-10, US-22, US-24 – US-26, US-31 – US-33 |
| [onboarding_flow_test.dart](onboarding_flow_test.dart) | 11 | No fabricated wearable data for a new athlete; profile required fields; optional fight date; fight expiry and archive | US-01, US-02 |
| [apple_health_normalizer_test.dart](apple_health_normalizer_test.dart) | 11 | Source records kept separate; manual entries not treated as wearable; no HRV guessed from heart rate | US-04, US-06, US-39 |
| [trends_dashboard_test.dart](trends_dashboard_test.dart) | 6 | Calendar buckets; gaps stay null (not zero) | US-34, US-35 |
| [wearable_history_merger_test.dart](wearable_history_merger_test.dart) | 9 | Sync merges without losing history; disconnect removes imported records | US-04, US-38 |
| [athlete_storage_test.dart](athlete_storage_test.dart) | 5 | Encrypted storage, migration, tamper-checked backup | US-38, US-40 |
| [device_key_flow_test.dart](device_key_flow_test.dart) | 3 | Account opens with a protected device key; missing key keeps encrypted data | US-38 |
| [language_switch_test.dart](language_switch_test.dart) | 3 | Language choice persists and changes visible text | — |
| [food_journal_test.dart](food_journal_test.dart) | 2 | Nutrition estimates and per-day totals | US-16 |
| [head_safety_flow_test.dart](head_safety_flow_test.dart) | 2 | Self-reported medical plan never creates sparring clearance | US-31 |
| [body_pain_map_test.dart](body_pain_map_test.dart) | 1 | Body map selects and clears front and back locations | US-18 |
| [nutrition_check_form_test.dart](nutrition_check_form_test.dart) | 1 | Nutrition check records three answers on a phone-sized screen | US-16 |
| [training_type_icons_test.dart](training_type_icons_test.dart) | 1 | Training types show distinct icons; selection still works | US-13 |
| [urine_colour_picker_test.dart](urine_colour_picker_test.dart) | 1 | Seven colours selectable; help guide opens | US-10 |
| [today_available_metrics_test.dart](today_available_metrics_test.dart) | 1 | Today shows only available health values and updates after sync | US-04, US-06 |
| [today_refresh_test.dart](today_refresh_test.dart) | 1 | Pull-to-refresh on Today requests a sync | US-04 |

**Result of `flutter test`:** `00:41 +85: All tests passed!` — **85 / 85 passed, 0 failed**. Run on 18 Nov 2026 on a clean checkout of `main` at commit `65d7ba5`, Flutter 3.50.0 (stable, Dart 3.14.0), Windows.

**Result of `flutter analyze`:** 34 issues, all level `info`, all `deprecated_member_use` (APIs deprecated in Flutter 3.47+, newer than the version the project was written with). 0 errors, 0 warnings.

What this proves: the scoring and safety rules behave as written in the spec for the tested inputs.
What it does **not** prove: that boxers can use the app, understand it, or find it useful.

### 2.2 Heuristic review (TEAM)

Each problem seen in the PROXY test (session log + survey comments) is mapped to one of [Nielsen's 10 usability heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/) and rated on Nielsen's severity scale (0 = not a problem … 4 = usability catastrophe). Severity is based on how many PROXY users hit it and whether it blocked the task.

**How this was made:** drafted with AI assistance (Claude) from the PROXY observations and a reading of the source code; the "Code check" column says what was confirmed in code. _TO CONFIRM: a team member re-checks each row in the running app and fills in "Confirmed in app"._

| # | Task / screen | Heuristic | Problem | Seen by | Code check | Severity | Confirmed in app | Fix commit | Retest |
|---|---|---|---|---|---|---|---|---|---|
| H1 | T5 Log training + nutrition | #6 Recognition rather than recall; #5 Error prevention | Duration/intensity entry unclear; nutrition part easy to leave unsaved | PROXY-04, -05, -08 (4 errors) | — | 3 | | | |
| H2 | Whole app, Thai language | #4 Consistency and standards; #2 Match with the real world | After switching to Thai some text stays English or reads oddly | Survey S6, S7, S8 | Confirmed cause: `AppCopy.of` returns the English text when a string has no entry in the Thai map, and otherwise does word-by-word replacement, which can give mixed Thai/English ([lib/ui/app_text.dart:7-21](../lib/ui/app_text.dart)) | 3 | | | |
| H3 | First use | #10 Help and documentation | No first-use guide; new users unsure what to do step by step | Survey S7, S8 | — | 2 | | | |
| H4 | T2 Morning check-in | #4 Consistency and standards | Two green buttons on one screen; unclear which is the main action | PROXY-08; survey S6 | — | 2 | | | |
| H5 | T1 Profile setup | #1 Visibility of system status | Placeholder text looks like a value already filled in | Survey S6 | Inputs use `hintText` with the theme's default hint style, no lighter style set ([lib/ui/screens/onboarding_screens.dart:122](../lib/ui/screens/onboarding_screens.dart), [lib/ui/components.dart:300](../lib/ui/components.dart)) | 2 | | | |
| H6 | T1 Privacy Notice | #5 Error prevention | Participant almost continued without ticking the Privacy Notice | PROXY-03 | — | 2 | | | |
| H7 | T3 Recovery limiter | #1 Visibility of system status | Hard to see which domain causes the limiter; "Learning baseline" state unclear | PROXY-03, -07 | — | 2 | | | |
| H8 | T7 Report severe pain | #3 User control and freedom | Unclear whether pain must be reported by editing the morning check-in | PROXY-03 | — | 2 | | | |
| H9 | T4 Sparring advice | #8 Aesthetic and minimalist design | Read Conditioning advice before finding Sparring advice | PROXY-01 | — | 1 | | | |
| H10 | Whole app | #8 Aesthetic and minimalist design | Too much text, too few icons; font colour too light | PROXY-05; survey S5 | — | 1 | | | |

What this proves: the problems are specific and repeatable enough to fix and retest.
What it does **not** prove: it is not an independent expert review, and severity ratings are the team's judgement.

### 2.3 Secondary evidence (SECONDARY)

Published research supporting the design choices that we could not test with boxers. All sources are peer-reviewed.

| # | Source | What it shows | Supports which design choice | What it does **not** prove |
|---|---|---|---|---|
| S-1 | Saw, Main & Gastin (2016). Monitoring the athlete training response: subjective self-reported measures trump commonly used objective measures: a systematic review. *Br J Sports Med* 50(5):281–291. [PMC4789708](https://pmc.ncbi.nlm.nih.gov/articles/PMC4789708/) | Review of 56 studies: athletes' self-reported well-being responded to training load more consistently than common objective measures | Short daily self-report check-in (mood, soreness, urine colour) alongside wearable data (US-08 – US-11, US-18) | That our specific questions are valid, or that boxers in particular respond this way |
| S-2 | Saw, Main & Gastin (2015). Impact of sport context and support on the use of a self-report measure for athlete monitoring. *J Sports Sci Med* 14:732–739. [jssm.org](https://www.jssm.org/jssm-14-732.xml-Fulltext) | Over 16 weeks, self-directed individual-sport athletes completed self-reports only 28 ± 40% of the time; athletes named minimal burden and wanted content as key to keep using it | Keeping daily input very short (≈ 90 s/day target) for a boxer with no support staff | That our app meets that burden level — our PROXY T2 time (46.9 s) is above our own 30 s target — or how long boxers would keep using it |
| S-3 | Bernick et al. (2015). Repeated head trauma is associated with smaller thalamic volumes and slower processing speed: the Professional Fighters' Brain Health Study. *Br J Sports Med* 49(15):1007–1011. [doi:10.1136/bjsports-2014-093877](https://doi.org/10.1136/bjsports-2014-093877) | In professional boxers and MMA fighters, more fight exposure was associated with lower brain volumes and slower processing speed | Separating sparring load and making head-impact safety override readiness (US-14, US-31, US-33) | That the app can detect or prevent brain injury; the app does not diagnose concussion |
| S-4 | Franchini, Brito & Artioli (2012). Weight loss in combat sports: physiological, psychological and performance effects. *J Int Soc Sports Nutr* 9:52. [PMC3607973](https://pmc.ncbi.nlm.nih.gov/articles/PMC3607973/) | Rapid weight loss is common in combat sports (reported in about half of athletes) and has negative health effects | Never giving weight-cut or dehydration advice; flagging sudden weight change instead (US-09, US-32) | That boxers using our app cut weight more safely |

What this evidence proves together: the problem (boxers need simple daily recovery monitoring with safety limits) and our main design rules have research support.
What it does **not** prove: that our app works for boxers. Only a real-user test (section 4) can show that.

### 2.4 PROXY usability test (PROXY)

8 friends of the team (outside the team, not boxers) each used the app themselves on 17 Nov 2026 and did tasks T1–T7 (section 4) while a team member timed them. Afterwards they filled in the survey form.

| Result | Value | Evidence |
|---|---|---|
| Task completion | 56/56 (100%) | [session-logs.md](../.docs/03-Test/session-logs.md) |
| Completed without help | 51/56 (91%) | [session-logs.md](../.docs/03-Test/session-logs.md) |
| Errors | 10 in total; 4 of them in T5 (log training + nutrition) | [session-logs.md](../.docs/03-Test/session-logs.md) |
| Morning check-in (T2) | mean 46.9 s — target ≈ 30 s **not met** | [session-logs.md](../.docs/03-Test/session-logs.md) |
| SUS | mean 56.9 (median 53.75) — **below** the 68 average | [sus-results.md](../.docs/03-Test/sus-results.md) |
| Acceptance items (team-written) | mean 4.25 / 5 | [sus-results.md](../.docs/03-Test/sus-results.md) |

What this proves: first-time users who are not boxers can complete every core task, mostly without help, and found specific usability problems (T5 data entry, Thai translation, need for a tutorial).
What it does **not** prove: that boxers in fight camp would understand the recovery domains the same way, trust the advice, or use the app daily. Usefulness ratings come from non-boxers.

---

## 3. Before / After

- **After** = median time in the app from the PROXY test (section 2.4).
- **Before** = how long the same job takes **without** the app (noting weight, sleep and soreness by hand and deciding today's training yourself). Measured by team member TEAM-01 on 17 Nov 2026 with a stopwatch, recording the data in a notes app on a phone: one run of all tasks T1–T7 together, **3:46 = 226 s**. Individual tasks were not timed separately.

**Total time T1–T7:**

| | Before (TEAM, without app) | After (PROXY, in app) | Change |
|---|---|---|---|
| Total T1–T7 | 226 s (n = 1, one run) | median 352.5 s, mean 341.9 s (n = 8) | **+126.5 s (+56%) slower** (median) |

**Reading this result:**

- With the app, the full set of tasks took **longer** than doing them by hand.
- T1 (first-time setup, median 107.5 s) is about a third of the in-app time and is done once, not every day. Before was not split by task, so a fair "daily tasks only" comparison cannot be made from this data.
- After was measured on first-time users (PROXY); Before on a team member who knew the tasks. Different people and different sample sizes (1 vs 8), so this is only a rough comparison.
- The by-hand version gives no six-domain assessment, Safety Gate or training advice — the app does more in that time, but this table does not measure that benefit.

**Per task:**

| Task | MUST items | Target from backlog | Before (TEAM) | After (s, PROXY median) | Change / vs target | Evidence |
|---|---|---|---|---|---|---|
| T1 Set up the app for fight camp | US-01, US-02, US-38 | — | Not measured separately | 107.5 | — | [session-logs.md](../.docs/03-Test/session-logs.md) |
| T2 Morning check-in | US-08 – US-11 | ≈ 30 s or less | Not measured separately | 47.5 | Target **not met** | [session-logs.md](../.docs/03-Test/session-logs.md) |
| T3 Find what is limiting recovery | US-22, US-24 | — | Not measured separately | 25 | — | [session-logs.md](../.docs/03-Test/session-logs.md) |
| T4 Check sparring advice | US-25, US-26 | — | Not measured separately | 37.5 | — | [session-logs.md](../.docs/03-Test/session-logs.md) |
| T5 Log training and check nutrition | US-13 – US-16 | nutrition ≈ 15 s | Not measured separately | 72.5 | Not comparable (T5 includes training log) | [session-logs.md](../.docs/03-Test/session-logs.md) |
| T6 Prioritize one thing tonight | US-27 | — | Not measured separately | 20 | — | [session-logs.md](../.docs/03-Test/session-logs.md) |
| T7 Report severe pain | US-18, US-31, US-33 | — | Not measured separately | 25 | — | [session-logs.md](../.docs/03-Test/session-logs.md) |
| **Total T1–T7** | | | **226** | **352.5** | **+126.5 s (+56%)** | this section |

Targets are from [backlog.md](../.docs/01-requirements/backlog.md).

---

## 4. Ready-to-run plan for a real-user test

This repeats the PROXY test (section 2.4) with the target users, so results can be compared directly.

**Participants:** 5–8 boxers currently in fight camp, outside the team. Coded U01, U02, … — no real names in the repo.

**Consent:** PDPA consent question first (already in the Google Form). No data is recorded without consent.

**Setup:** one phone with the app installed (record device, OS and commit hash), fresh account, stopwatch, observer sheet.

**Tasks** (read aloud, one at a time, no hints unless the participant is stuck for 60 s):

| Task | Scenario given to participant | Success = |
|---|---|---|
| T1 | "Set the app up for your current fight camp." | Profile saved, privacy notice accepted, fight date set or skipped |
| T2 | "Do your morning check-in." | Weight, urine color and mood saved |
| T3 | "Find out what is limiting your recovery today." | Participant names the limiter domain |
| T4 | "Can you spar today? Show me where the app says so." | Participant finds the sparring advice |
| T5 | "Log yesterday's training and do the nutrition check." | Training type, duration, intensity and nutrition saved |
| T6 | "What is the one thing you should do tonight?" | Participant names the recovery action |
| T7 | "You have severe pain in your hand. Report it." | Pain saved and safety warning shown |

**Record per task:** result (completed independently / completed with help / failed), time in seconds, number of errors (wrong path or hint needed), notes and quotes.

**After the tasks:** participant fills in the Google Form (SUS 10 items + 10 acceptance items + 3 open questions).

**Outputs to commit:**

- `.docs/03-Test/real-user-session-logs.md` — same format as the PROXY [session-logs.md](../.docs/03-Test/session-logs.md), codes U01, U02, …
- `.docs/03-Test/real-user-sus-results.md` — same format as the PROXY [sus-results.md](../.docs/03-Test/sus-results.md)
- Issue log — severity, fix commit, retest
- A real-user column added to the Before/After table in section 3
