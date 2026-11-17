# Automated Test Run — 18 Nov 2026

**Evidence type:** AUTOMATED. This is a run of the existing tests from the repository checkout, not a user study or a test of live HealthKit access.

| Item | Observed value |
|---|---|
| Git commit tested | `c79e6321e578cb84550d1533191d929728c0aca3` (`main`, before documentation-only audit edits) |
| Host | Windows, local Flutter SDK |
| Flutter / Dart | Flutter 3.47.6 stable / Dart 3.13.5 |
| Test command | `flutter test --reporter expanded` |
| Test result | Exit code 0; final line `00:16 +85: All tests passed!` |
| Analysis command | `flutter analyze --no-pub` |
| Analysis result | Exit code 0; `No issues found! (ran in 19.7s)` |

The test runner required access to a local WebSocket, so the final test command was run outside the restricted sandbox. These results verify the checked Dart scenarios. They do not verify the current app on an iPhone, a real wearable read, the Android APK, usability with boxers, or the open issues in [issue-log.md](../.docs/03-Test/issue-log.md).
