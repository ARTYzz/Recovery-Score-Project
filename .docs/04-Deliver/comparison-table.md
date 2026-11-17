# Recovery Score App: Before / After Comparison

> **No real-user (boxer) data.** "After" results come from **PROXY** users: 8 friends outside the team who are not boxers, tested on 17 Nov 2026. "Before" was measured by a team member (**TEAM**) doing the same tasks without the app. See [no-real-user-test.md](../../test/no-real-user-test.md).

| Item | Before (without app) | After (using app) | Change | Measured with | Evidence |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Total time, tasks T1–T7** | 226 s (TEAM, n = 1) | median 352.5 s, mean 341.9 s (PROXY, n = 8) | **+126.5 s (+56%) slower** | Stopwatch | [no-real-user-test.md §3](../../test/no-real-user-test.md), [session-logs.md](../03-Test/session-logs.md) |
| **Task success rate (T1–T7)** | Not measured | 56/56 completed (100%); 51/56 without help (91%) | — | Observation | [session-logs.md](../03-Test/session-logs.md) |
| **Time to check sparring advice (T4)** | Not measured separately | median 37.5 s (target ≤ 45 s: met) | — | Stopwatch | [session-logs.md](../03-Test/session-logs.md) |
| **Daily input time (T2 + T5)** | Not measured separately | median 122.5 s, mean 118.8 s; 1 of 8 under 90 s (target ≤ 90 s: **not met**) | — | Stopwatch | [session-logs.md](../03-Test/session-logs.md) |
| **System Usability Scale (SUS)** | — (no earlier SUS) | 56.9 (benchmark 68: **below**) | — | 10-item SUS, 5-point | [sus-results.md](../03-Test/sus-results.md) |
| **Acceptance items** | — | 4.25 / 5 (mean of 10 team-written items) | — | 10 items, 5-point; TAM-style, not the validated 12-item TAM in the Test Plan | [sus-results.md](../03-Test/sus-results.md) |
| **Decision logic (AI row)** | No rules; training decided by feel | Rule-based engine, **no AI/ML at runtime**; rule tests 29/29 pass (`recovery_engine_test` 27 + `head_safety_flow_test` 2) | — | `flutter test` on `main` (`ff08c6e`), 17 Nov 2026 | [test/recovery_engine_test.dart](../../test/recovery_engine_test.dart), [RECOVERY_SCORING.md](../../RECOVERY_SCORING.md) |
| **AI feature demand** | — | 1 of 8 PROXY respondents asked for AI advice ("มีAiแนะนำ") as their one change | Future feature, not built | Open survey question | [sus-results.md §3](../03-Test/sus-results.md) |

**Reading the table:** first-time PROXY users completed every task, but the app was slower than doing the tasks by hand, daily input (T2 + T5) is above the 90 s goal, and SUS is below average. Main causes are in the [issue log](../03-Test/issue-log.md): training/nutrition entry (I-01) and Thai translation (I-02). Before and After were measured on different people (1 team member vs 8 PROXY users), so the comparison is rough.
