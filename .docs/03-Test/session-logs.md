# Session Logs — PROXY Usability Test

> **PROXY.** All 8 participants are friends of the team: people **outside the team who are not professional boxers in fight camp**. They show whether a first-time user can operate the app. They do **not** show whether boxers in camp find it useful or would use it every day. See [no-real-user-test.md](../../test/no-real-user-test.md).

Participants are identified by code only (PROXY-01 – PROXY-08). No real names or contact details are stored in this repository (see [rule.md](../rule.md)). Each participant gave PDPA consent in the survey form ([sus-results.md](sus-results.md)).

## Session details

| Field | Value |
|---|---|
| Participants | 8 (PROXY-01 – PROXY-08), outside the team, not boxers |
| Date | 17 Nov 2026 (date recorded in the survey form) |
| Device / app build tested | _TO FILL (device, OS, commit hash)_ |
| Moderator | _TO FILL (team member)_ |
| Method | Moderated task-based test. Participant used the app themselves; a team member timed each task in seconds. Error = a wrong path or a needed hint. Afterwards the participant filled in the survey form. |

## Tasks

| Task | Scenario | Related backlog items |
|---|---|---|
| T1 | Set up the app for fight camp | US-01, US-02, US-38 |
| T2 | Morning check-in | US-08 – US-11 |
| T3 | Find out what is limiting recovery | US-22, US-24 |
| T4 | Check sparring advice | US-25, US-26 |
| T5 | Log training and check nutrition | US-13 – US-16 |
| T6 | Prioritize one thing tonight | US-27 |
| T7 | Report severe pain | US-18, US-31, US-33 |

## Summary per task

Times in seconds, n = 8 PROXY users.

| Task | Completed | Without help | With help | Errors (total) | Mean | Median | Min | Max |
|---|---|---|---|---|---|---|---|---|
| T1 Set up for fight camp | 8/8 | 7/8 | 1 (PROXY-03) | 1 | 109.4 | 107.5 | 90 | 140 |
| T2 Morning check-in | 8/8 | 8/8 | 0 | 1 | 46.9 | 47.5 | 35 | 60 |
| T3 Find recovery limiter | 8/8 | 7/8 | 1 (PROXY-07) | 2 | 26.3 | 25 | 15 | 40 |
| T4 Check sparring advice | 8/8 | 7/8 | 1 (PROXY-01) | 1 | 38.1 | 37.5 | 25 | 55 |
| T5 Log training + nutrition | 8/8 | 7/8 | 1 (PROXY-04) | 4 | 71.9 | 72.5 | 50 | 95 |
| T6 Prioritize one thing tonight | 8/8 | 8/8 | 0 | 0 | 21.3 | 20 | 15 | 30 |
| T7 Report severe pain | 8/8 | 7/8 | 1 (PROXY-03) | 1 | 28.1 | 25 | 20 | 45 |
| **All tasks** | **56/56 (100%)** | **51/56 (91%)** | **5** | **10** | | | | |

Total time across T1–T7 per participant: PROXY-01 345 s, PROXY-02 255 s, PROXY-03 405 s, PROXY-04 335 s, PROXY-05 380 s, PROXY-06 270 s, PROXY-07 360 s, PROXY-08 385 s (mean 341.9 s, median 352.5 s).

### Compared with backlog targets

| Target (from [backlog.md](../01-requirements/backlog.md)) | Observed | Met? |
|---|---|---|
| Morning check-in ≈ 30 s or less (US-08) | T2 mean 46.9 s, min 35 s | No — every participant was above 30 s |

The nutrition target (≈ 15 s, US-16) cannot be checked from this data, because T5 times training logging and the nutrition check together. These are first-time users; daily repeat use would likely be faster, but this test does not measure that.

## Observed issues

These feed into the issue log.

| # | Task | Participant(s) | Observation |
|---|---|---|---|
| 1 | T5 | PROXY-04, -05, -08 | Training/nutrition entry unclear: duration and intensity input confusing (PROXY-04, 2 errors); forgot to save the nutrition part (PROXY-05); nutrition confusing for a first-time user (PROXY-08) |
| 2 | T1 | PROXY-03 | Almost skipped the Privacy Notice without ticking it |
| 3 | T3 | PROXY-03, -07 | Baseline-learning state slightly confusing (PROXY-03); could not find which domain caused the limiter (PROXY-07) |
| 4 | T4 | PROXY-01 | Read Conditioning advice first instead of Sparring advice |
| 5 | T7 | PROXY-03 | Unsure whether they needed to edit the morning check-in to report pain |
| 6 | T2 | PROXY-08 | Hesitated between the two green buttons |
| 7 | T1 | PROXY-05 | "Font color is a bit too light" |

Positive observations: PROXY-01 saw the red Safety Gate clearly (T7); PROXY-02 selected soreness quickly (T2); PROXY-04 said sparring advice was "Easy to understand" (T4); PROXY-06 understood the 6-domain graph immediately (T3).

## Raw log

| ID | Type | Task | Result | Time (s) | Errors | Notes |
|---|---|---|---|---|---|---|
| PROXY-01 | PROXY | T1 Set up the app for fight camp | Completed independently | 110 | 0 | - |
| PROXY-01 | PROXY | T2 Morning check-in | Completed independently | 45 | 0 | - |
| PROXY-01 | PROXY | T3 Find out what is limiting recovery | Completed independently | 25 | 0 | - |
| PROXY-01 | PROXY | T4 Check sparring advice | Completed with help | 55 | 1 | Read Conditioning advice first by mistake |
| PROXY-01 | PROXY | T5 Log training and check nutrition | Completed independently | 65 | 0 | - |
| PROXY-01 | PROXY | T6 Prioritize one thing tonight | Completed independently | 20 | 0 | - |
| PROXY-01 | PROXY | T7 Report severe pain | Completed independently | 25 | 0 | Saw the red Safety Gate clearly |
| PROXY-02 | PROXY | T1 Set up the app for fight camp | Completed independently | 90 | 0 | - |
| PROXY-02 | PROXY | T2 Morning check-in | Completed independently | 35 | 0 | Selected soreness quickly |
| PROXY-02 | PROXY | T3 Find out what is limiting recovery | Completed independently | 15 | 0 | - |
| PROXY-02 | PROXY | T4 Check sparring advice | Completed independently | 30 | 0 | - |
| PROXY-02 | PROXY | T5 Log training and check nutrition | Completed independently | 50 | 0 | - |
| PROXY-02 | PROXY | T6 Prioritize one thing tonight | Completed independently | 15 | 0 | - |
| PROXY-02 | PROXY | T7 Report severe pain | Completed independently | 20 | 0 | - |
| PROXY-03 | PROXY | T1 Set up the app for fight camp | Completed with help | 140 | 1 | Almost skipped Privacy Notice without ticking |
| PROXY-03 | PROXY | T2 Morning check-in | Completed independently | 50 | 0 | - |
| PROXY-03 | PROXY | T3 Find out what is limiting recovery | Completed independently | 35 | 1 | Slightly confused by Baseline-learning state |
| PROXY-03 | PROXY | T4 Check sparring advice | Completed independently | 40 | 0 | - |
| PROXY-03 | PROXY | T5 Log training and check nutrition | Completed independently | 70 | 0 | - |
| PROXY-03 | PROXY | T6 Prioritize one thing tonight | Completed independently | 25 | 0 | - |
| PROXY-03 | PROXY | T7 Report severe pain | Completed with help | 45 | 1 | Unsure if they needed to edit the morning check-in |
| PROXY-04 | PROXY | T1 Set up the app for fight camp | Completed independently | 100 | 0 | - |
| PROXY-04 | PROXY | T2 Morning check-in | Completed independently | 40 | 0 | - |
| PROXY-04 | PROXY | T3 Find out what is limiting recovery | Completed independently | 20 | 0 | - |
| PROXY-04 | PROXY | T4 Check sparring advice | Completed independently | 35 | 0 | "Easy to understand" |
| PROXY-04 | PROXY | T5 Log training and check nutrition | Completed with help | 95 | 2 | Confused about entering duration and intensity |
| PROXY-04 | PROXY | T6 Prioritize one thing tonight | Completed independently | 20 | 0 | - |
| PROXY-04 | PROXY | T7 Report severe pain | Completed independently | 25 | 0 | - |
| PROXY-05 | PROXY | T1 Set up the app for fight camp | Completed independently | 120 | 0 | "Font color is a bit too light" |
| PROXY-05 | PROXY | T2 Morning check-in | Completed independently | 55 | 0 | - |
| PROXY-05 | PROXY | T3 Find out what is limiting recovery | Completed independently | 30 | 0 | - |
| PROXY-05 | PROXY | T4 Check sparring advice | Completed independently | 40 | 0 | - |
| PROXY-05 | PROXY | T5 Log training and check nutrition | Completed independently | 80 | 1 | Forgot to save nutrition part initially |
| PROXY-05 | PROXY | T6 Prioritize one thing tonight | Completed independently | 25 | 0 | - |
| PROXY-05 | PROXY | T7 Report severe pain | Completed independently | 30 | 0 | - |
| PROXY-06 | PROXY | T1 Set up the app for fight camp | Completed independently | 95 | 0 | - |
| PROXY-06 | PROXY | T2 Morning check-in | Completed independently | 40 | 0 | - |
| PROXY-06 | PROXY | T3 Find out what is limiting recovery | Completed independently | 20 | 0 | Saw the 6-domain graph and understood immediately |
| PROXY-06 | PROXY | T4 Check sparring advice | Completed independently | 25 | 0 | - |
| PROXY-06 | PROXY | T5 Log training and check nutrition | Completed independently | 55 | 0 | - |
| PROXY-06 | PROXY | T6 Prioritize one thing tonight | Completed independently | 15 | 0 | - |
| PROXY-06 | PROXY | T7 Report severe pain | Completed independently | 20 | 0 | - |
| PROXY-07 | PROXY | T1 Set up the app for fight camp | Completed independently | 105 | 0 | - |
| PROXY-07 | PROXY | T2 Morning check-in | Completed independently | 50 | 0 | - |
| PROXY-07 | PROXY | T3 Find out what is limiting recovery | Completed with help | 40 | 1 | Couldn't find which domain caused the issue |
| PROXY-07 | PROXY | T4 Check sparring advice | Completed independently | 45 | 0 | - |
| PROXY-07 | PROXY | T5 Log training and check nutrition | Completed independently | 75 | 0 | - |
| PROXY-07 | PROXY | T6 Prioritize one thing tonight | Completed independently | 20 | 0 | - |
| PROXY-07 | PROXY | T7 Report severe pain | Completed independently | 25 | 0 | - |
| PROXY-08 | PROXY | T1 Set up the app for fight camp | Completed independently | 115 | 0 | - |
| PROXY-08 | PROXY | T2 Morning check-in | Completed independently | 60 | 1 | Hesitated between the 2 green buttons |
| PROXY-08 | PROXY | T3 Find out what is limiting recovery | Completed independently | 25 | 0 | - |
| PROXY-08 | PROXY | T4 Check sparring advice | Completed independently | 35 | 0 | - |
| PROXY-08 | PROXY | T5 Log training and check nutrition | Completed independently | 85 | 1 | Nutrition function slightly confusing for first-time user |
| PROXY-08 | PROXY | T6 Prioritize one thing tonight | Completed independently | 30 | 0 | - |
| PROXY-08 | PROXY | T7 Report severe pain | Completed independently | 35 | 0 | - |
