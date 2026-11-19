# Ship log — S15-44 The printed page can be marked unknown or supplied

**Plan:** [`S15-44-page-marks.md`](S15-44-page-marks.md) · **Branch:** `s15-44-page-marks` · **PR:** #905
**State:** ready

Base: `main` at `90e33274f`.

## Round 0 — implement
Head `3a922f363`. Gate PASS (orchestrator run: all nine checks). Report: no deviations in code or scope; the plan's Status line uses the "Landed in [#905](…) (date)" form `check-plan-docs.py` accepts. `FuzzValidate` ran 5 minutes, 42,463,050 execs, no crasher.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF (`core/locator` parses `locator_json` the app may not have written). Skipped: UX (no `macos/App/**`, strings, or error codes; `project.pbxproj` changes only `MARKETING_VERSION`).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| SEC-note | SEC (outside lens) | minor | Go reads locator keys case-insensitively; Swift's `CitationLocatorDraft` reads them by exact key, so a crafted `"Page_Unknown"` could make the composer and the citation disagree | Later PR → S15-45 | Pre-existing for `artifact_page` / `page_label`; Swift does not read the mark until S15-45 (`CitationLocatorDraft.swift:76-122`). Written into S15-45's map entry as a **Review note** |

No blocker, major or minor finding from CON, MNT or SEC+PRF. Each ran the locator, citations, graphfill and depictionvalue tests; CON and SEC+PRF each ran `FuzzValidate` for 45s (about 3.6M execs, no crasher).

Nits (logged): `MNT-1 / CON-1 · core/locator/depiction.go:13-19 · re-wrap the edited ValidateDepictionRegion doc lines` · `MNT-2 · core/locator/fuzz_test.go:29 · inner err shadows the outer Validate err; rename one` · `CON-2 · core/locator/fuzz_test.go:229 · seed AC-1.3's documents (label + supplied, no file page) as T-5 asks`

No fix plan: nothing is Fix now. No round 2.

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: —
