# Final Project Index — Boxer Recovery

All items are on branch **`main`** of <https://github.com/ARTYzz/Recovery-Score-Project>. Files are kept where the team created them; this page links to each one.

Evidence labels: **PROXY** = people outside the team who are not boxers; **TEAM** = measured by team members; **SECONDARY** = published research with source links. **No data in this repository comes from real target users (boxers in fight camp)** — see [no-real-user-test.md](../../test/no-real-user-test.md).

## 1. Discover

| Item | Link |
|---|---|
| Company Charter (members, roles) | [Company Charter.md](../01-requirements/Company%20Charter.md) |
| Problem evidence — SECONDARY review (no real-user interviews) | [problem-review-secondary.md](../01-requirements/problem-review-secondary.md) |
| Requirements / spec | [spec.md](../01-requirements/spec.md) |
| Product Backlog (MoSCoW, MUST marked) | [backlog.md](../01-requirements/backlog.md) |
| PDPA and legal requirements | [rule.md](../rule.md) |
| How the team uses AI | [CLAUDE.md](../../CLAUDE.md) |

## 2. Build

| Item | Link |
|---|---|
| Use case diagram | [use-case.jpg](../02-design/diagrams/use-case.jpg) |
| Activity / user flow diagram | [user-flow.png](../02-design/diagrams/user-flow.png) |
| ER diagram | [erd.png](../02-design/diagrams/erd.png) |
| Implemented architecture | [architecture-current.md](../02-design/architecture-current.md) |
| Original architecture diagram (design history) | [system-architecture.jpg](../02-design/diagrams/system-architecture.jpg) |
| User journey and feature list | [user-journey.md](../02-design/user-journey.md), [feature-list.md](../02-design/feature-list.md) |
| Source code | [lib/](../../lib/) |
| Our own tests (85 cases, 85/85 pass) | [test/](../../test/) |
| Latest automated test run | [automated-test-run-2026-11-18.md](../../test/automated-test-run-2026-11-18.md) |
| Recovery scoring rules | [RECOVERY_SCORING.md](../../RECOVERY_SCORING.md) |
| How to run (setup, .env.example, test account) | [README.md](../../README.md), [.env.example](../../.env.example) |
| Historical Android debug build (23 Sep 2026; use `flutter run` for current app) | [output/BoxerRecovery-debug.apk](../../output/BoxerRecovery-debug.apk) |

## 3. Test

| Item | Link |
|---|---|
| Test Plan | [Test-Plan.md](../03-Test/Test-Plan.md) |
| No real-user test (why, PROXY, test results, heuristic review, SECONDARY, plan) | [no-real-user-test.md](../../test/no-real-user-test.md) |
| Session logs (PROXY-01 – 08) | [session-logs.md](../03-Test/session-logs.md) |
| Before / After for MUST tasks | [no-real-user-test.md §3](../../test/no-real-user-test.md), [comparison-table.md](../04-Deliver/comparison-table.md) |
| SUS and acceptance survey (PROXY) | [sus-results.md](../03-Test/sus-results.md) |
| Issue log | [issue-log.md](../03-Test/issue-log.md) |

## 4. Deliver

| Item | Link |
|---|---|
| Case study (Problem, Process, Outcome, live URL) | [case-study.md](case-study.md) |
| AI logic (Where, How, Prove, Measure) | [ai-logic.md](ai-logic.md) |
| Comparison table (incl. AI row) | [comparison-table.md](../04-Deliver/comparison-table.md) |
| Role statement — Theerawut Khamsuetrong (6631503024) | [6631503024-Theerawut.md](role-statements/6631503024-Theerawut.md) |
| Role statement — Hassakorn Buaurai (6631503127) | [6631503127-Hassakorn.md](role-statements/6631503127-Hassakorn.md) |
| Role statement — Pawornpat Kongdaeng (6531503111), Product Owner | [6531503111-Pawornpat.md](role-statements/6531503111-Pawornpat.md) |
| Role statement — Thiraphat Kongkan (6631503023), AI Lead | [6631503023-Thiraphat.md](role-statements/6631503023-Thiraphat.md) |
| Role statement — Chisanucha Vongtalay (6631503125), Tech Lead | [6631503125-Chisanucha.md](role-statements/6631503125-Chisanucha.md) |

## 5. Other

| Item | Link |
|---|---|
| iOS build workflow | [.github/workflows/ios-sidestore-ipa.yml](../../.github/workflows/ios-sidestore-ipa.yml) |
| App screenshots | [screenshots/](../../screenshots/) |
| Research reference | [Recovery for Boxers.pdf](../02-design/references/Recovery%20for%20Boxers.pdf) |
