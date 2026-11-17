# Issue Log

Issues found in the PROXY usability test ([session-logs.md](session-logs.md)), the survey ([sus-results.md](sus-results.md)) and the heuristic review ([no-real-user-test.md §2.2](../../test/no-real-user-test.md)).

Severity uses Nielsen's scale: 4 = catastrophe, 3 = major, 2 = minor, 1 = cosmetic.

| ID | Issue | Source | Severity | Status | Fix commit | Retest |
|---|---|---|---|---|---|---|
| I-01 | T5: duration/intensity entry unclear; nutrition part easy to leave unsaved | PROXY-04, -05, -08 (4 errors) | 3 | Open | | |
| I-02 | Thai language: some text stays English or is translated word by word ([lib/ui/app_text.dart:7-21](../../lib/ui/app_text.dart)) | Survey S6, S7, S8 | 3 | Open | | |
| I-03 | No first-use guide / tutorial | Survey S7, S8 | 2 | Open | | |
| I-04 | Two green buttons on the morning check-in screen; unclear main action | PROXY-08; survey S6 | 2 | Open | | |
| I-05 | Placeholder text on profile page looks like a filled-in value | Survey S6 | 2 | Open | | |
| I-06 | Privacy Notice can almost be skipped without noticing the checkbox | PROXY-03 | 2 | Open | | |
| I-07 | Hard to see which domain causes the limiter; "Learning baseline" unclear | PROXY-03, -07 | 2 | Open | | |
| I-08 | Unclear whether severe pain must be reported by editing the morning check-in | PROXY-03 | 2 | Open | | |
| I-09 | Conditioning advice read before Sparring advice | PROXY-01 | 1 | Open | | |
| I-10 | Too much text, too few icons; font colour too light | PROXY-05; survey S5 | 1 | Open | | |

**How to close an issue:** fix it, commit, put the short commit hash in "Fix commit", then repeat the related task with at least one person who has not seen the fix and write the result in "Retest" (e.g. "T5 by TEAM-02, 0 errors, 48 s"). Label who did the retest (TEAM / PROXY / U).
