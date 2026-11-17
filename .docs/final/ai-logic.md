# AI Logic

## Summary

**The app does not use AI or machine learning at runtime.** Recovery assessment is a deterministic, rule-based engine. This was a deliberate scope decision: the backlog lists "machine-learning-based recovery prediction" and "advanced AI coaching" as *not required* for the prototype ([backlog.md §5](../01-requirements/backlog.md)), and the safety rules ([rule.md](../rule.md)) need decisions that are explainable and testable.

AI **was** used to build the project (design, analysis, documentation) — see section 5.

## 1. Where

| Part | Uses AI? | What it does |
|---|---|---|
| `RecoveryEngine` ([lib/domain/recovery_engine.dart](../../lib/domain/recovery_engine.dart)) | No — rules | Scores six domains, picks the limiter, applies the Safety Gate |
| `TrainingAdvisor` (same file) | No — rules | Advice per training category (sparring, technical, conditioning, strength) |
| Personal baselines | No — statistics | Compares today with the athlete's own previous 30 days |
| Food journal | No | Stores a photo and the user's own estimate; does **not** recognise food |
| Building the project | **Yes** | AI tools for UI prototyping, analysis and documentation (section 5) |

## 2. How (the decision logic)

Full rules: [RECOVERY_SCORING.md](../../RECOVERY_SCORING.md).

1. **Safety Gate first.** Head symptoms, post-contact head pain or severe pain restrict training before any score is used (US-31, US-33).
2. **Six independent domains**, each 0–100 or *Unavailable*: Brain & Impact, Fuel & Weight, Sleep & Heart, Power & Speed, Body, Mind. No overall average.
3. **Personal baseline.** Sleep, HRV and resting HR are compared with the athlete's previous 30 days; at least 7 days are needed, otherwise the domain shows "Learning baseline".
4. **Limiter** = lowest available domain score. 80–100 Ready, 50–79 Caution, < 50 Restricted.
5. **Missing data stays missing.** No metric is turned into 0 and HRV is never guessed from heart rate.

## 3. Prove

| Item | Value |
|---|---|
| Test set | [test/recovery_engine_test.dart](../../test/recovery_engine_test.dart) — 27 scenario tests (e.g. "head symptoms override training even with baseline data", "severe pain safety overrides all four categories", "missing HRV stays missing", "primary limiter uses the lowest measured domain score") + [test/head_safety_flow_test.dart](../../test/head_safety_flow_test.dart) — 2 tests. **29 rule tests in total.** |
| Baseline (what "correct" means) | The written rules in [RECOVERY_SCORING.md](../../RECOVERY_SCORING.md) and acceptance criteria in [backlog.md](../01-requirements/backlog.md). Each test encodes one rule. |
| Eval script | `flutter test test/recovery_engine_test.dart test/head_safety_flow_test.dart` (or `flutter test` for the full suite) |
| Eval log | Latest local run: 85/85 tests passed and `flutter analyze` found no issues on `main` at `c79e632`, 18 Nov 2026, Flutter 3.47.6. Command and limits: [automated-test-run-2026-11-18.md](../../test/automated-test-run-2026-11-18.md). Earlier run: [no-real-user-test.md §2.1](../../test/no-real-user-test.md). |

## 4. Measure

| Measure | Result | Evidence |
|---|---|---|
| Rule tests passing | **29 / 29** | eval log above |
| PROXY users who found the limiter (T3) | 8/8 completed, 7/8 without help, median 25 s | [session-logs.md](../03-Test/session-logs.md) |
| "The app clearly shows what is limiting my recovery" | 4.25 / 5 (PROXY, n = 8) | [sus-results.md](../03-Test/sus-results.md) |
| "I easily understand the six-domain recovery status" | 4.50 / 5 (PROXY, n = 8) | [sus-results.md](../03-Test/sus-results.md) |

PROXY = friends outside the team, not boxers.

## Limitations and trust

- **Thresholds are prototype heuristics, not validated medical scores.** They have not been checked against expert decisions or real outcomes.
- **Bias across devices:** different watches compute HRV and sleep differently. Using each athlete's own baseline per source reduces this but does not remove it.
- **No real boxers** have used the engine yet; PROXY results show the output is understandable, not that it is right for boxers.
- **When it fails:** missing data → domain shows *Unavailable*; not enough history → "Learning baseline"; any safety signal → training restricted and professional evaluation advised. The app never issues medical clearance.

## 5. AI used to build the project

From members' AI disclosures in their role statements:

| Tool | Used for | Source |
|---|---|---|
| Google Gemini | Requirement analysis; writing prompts for Stitch AI | [6631503024-Theerawut.md](role-statements/6631503024-Theerawut.md) |
| Stitch AI (Google) | Initial UI prototype screens | [6631503024-Theerawut.md](role-statements/6631503024-Theerawut.md) |
| Google Gemini | SUS/TAM calculation, Markdown tables, editing tone | [6631503127-Hassakorn.md](role-statements/6631503127-Hassakorn.md) |
| Claude Code | Test documentation (no-real-user test, session log formatting, SUS recalculation, issue log, heuristic review draft), this document | this repository's test documents |
| ChatGPT/Codex | Flutter and HealthKit implementation support, troubleshooting, and documentation | [6631503125-Chisanucha.md](role-statements/6631503125-Chisanucha.md) |
| Claude Code, Gemini, ChatGPT | Analysis, documentation, and implementation approaches | [6631503023-Thiraphat.md](role-statements/6631503023-Thiraphat.md) |

The Product Owner also discloses Claude Code use in [6531503111-Pawornpat.md](role-statements/6531503111-Pawornpat.md). Rules the team follows when using AI are in [CLAUDE.md](../../CLAUDE.md).

One PROXY respondent asked for AI recommendations as the one change they would make (survey S1) — a possible future feature, out of scope for this prototype.
