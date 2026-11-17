# CLAUDE.md

Instructions for AI coding assistants working in this repository, and a record of how the team uses AI.

## Project

Boxer Recovery: a Flutter app (iOS/Android, browser preview) that helps professional boxers in fight camp decide what is safe to train today. Specs: [.docs/01-requirements/spec.md](.docs/01-requirements/spec.md), backlog: [.docs/01-requirements/backlog.md](.docs/01-requirements/backlog.md), scoring rules: [RECOVERY_SCORING.md](RECOVERY_SCORING.md).

## Rules for the assistant

1. **Read [.docs/rule.md](.docs/rule.md) before touching user data, health data, wearable integrations or recommendations.** PDPA applies; health data is sensitive.
2. **Never invent data.** Missing wearable values stay `Unavailable`, never 0. Do not create synthetic health data outside clearly labelled mocks (FightCamp is the only runtime mock).
3. **Safety first.** The Safety Gate runs before scoring. Never write code that diagnoses, gives medical clearance, or gives weight-cut / dehydration advice.
4. **No secrets in the repo.** No API keys, passwords or `.env` files.
5. **Test every rule change.** Add or update a test in `test/` and run `flutter test` and `flutter analyze` before committing.
6. **Keep the layers:** `lib/domain/` rules and models, `lib/data/` storage and sources, `lib/app/` state, `lib/ui/` screens. All visible text goes through `AppCopy.of` with a Thai entry in [lib/ui/app_text.dart](lib/ui/app_text.dart).
7. **Evidence in docs must have a source.** Label test data REAL / PROXY / TEAM / SECONDARY. No real names of test participants.

## Commands

```powershell
flutter pub get
flutter test
flutter analyze
flutter run -d chrome
```

## How the team uses AI

From members' AI disclosures in [.docs/final/role-statements/](.docs/final/role-statements/). These describe development assistance; the app has no runtime AI model.

| Tool | Used for | Who | How output was checked |
|---|---|---|---|
| Google Gemini | Requirement analysis; prompts for Stitch AI | Theerawut (Designer) | Flows and layouts reviewed and refined manually |
| Stitch AI | Initial UI prototype screens | Theerawut (Designer) | Reviewed and adjusted manually |
| Google Gemini | SUS/TAM calculation, Markdown tables, editing tone | Hassakorn (QA/Tester) | Calculations and tables checked against the survey responses in [.docs/03-Test/sus-results.md](.docs/03-Test/sus-results.md) |
| Claude Code | Test documentation: no-real-user test, session log formatting, SUS recalculation by script, issue log, heuristic review draft, AI logic | team (this repository) | Numbers recomputed by script from raw data; tests run with `flutter test`; reviewed before commit |
| ChatGPT/Codex | Flutter and HealthKit implementation support, troubleshooting, documentation | Chisanucha (Tech Lead) | Reviewed against requirements and safety rules, then checked with tests and device runs |
| Claude Code, Gemini, ChatGPT | Analysis, documentation, implementation approaches | Thiraphat (AI Lead) | Reviewed against specification, scoring rules, and automated tests |

Agreed practice:

- AI output is reviewed by a team member before it is committed.
- Generated code must pass `flutter test` and `flutter analyze`.
- AI is not used to create or fill in user-test data.
- Each member discloses AI use in their role statement.
