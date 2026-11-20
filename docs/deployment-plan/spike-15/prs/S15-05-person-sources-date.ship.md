# Ship log — S15-05 The Person page's Sources section shows each Source's date

**Plan:** [`S15-05-person-sources-date.md`](S15-05-person-sources-date.md) · **Branch:** `s15-05-person-sources-date` · **PR:** #919
**State:** fixing 1

## Round 0 — implement
Base `main` @ `c3c0de193`. Head `db83945ca`. Gate PASS (orchestrator run). Report deviations: version bump is 0.28.1 → 0.29.0 because `main` had moved to 0.28.1; STEP-4 and STEP-5 in one commit (both edit `L10n.swift` and `Localizable.xcstrings`); STEP-1's test commit holds the Apply date rows, which fail at that commit and pass from STEP-2. Manual check (§10) not run.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none (diff touches `macos/App/**`, `Localizable.xcstrings`, `api/ffi/**`, `core/database/**`, and the Source record cache that loads `date_values`).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | minor | `publishedDate.*` translator comments name screens that never show them | Fix now → F-1 | verified: `SourcePageIdentityHeader.swift` and `SourceCopyModel.swift` call only `SourceDateText.line`; `.labeled` is used only by `SourcesListRow` |
| MNT-1 | MNT | minor | New Go tests hand-build dates that `datevaluetest.YMD` builds | Fix now → F-2 | verified: `records_test.go:135` `pointYear`, `:153` literal; `claims_test.go:208-231`. Tests this PR adds |
| PRF-2 | PRF | minor | `PVPublishedDate` formats each dated row twice per body | Fix now → F-3 | verified: `PVPublishedDate.swift:37,41` call `SourceDateText.help(date)`, which calls `line` again; file this PR adds |
| CON-1 / MNT-2 / MNT outside-lens | CON | minor (re-rated from nit: DoD box) | Plan has no Landed note though DoD asks for one | Fix now → F-4 | verified: plan line 322 DoD; only Status changed |
| SEC-1 | SEC | minor | Date reads never `datevalue.Validate` a stored row; crafted rows reach `Record.Date` as stored | Follow-up | gap covers every date read (Sources list, Observation dates), predates this PR; no crash path found, impact is wrong text bounded by a one-line cell. A read-side check changes what researchers see for rows that failed later-tightened rules, so it needs its own call |
| PRF-1 | PRF | minor | Each date edit runs the `sources.date_value_id` inbound lookup twice (scope + record) | Follow-up | indexed single-row lookup per changed date, grows with commit size not catalog; fix is a memo in `effects.walk`, a design change outside this PR |

Nits (logged): `UX-2 · macos/App/DesignSystem/README.md:210 · name both "Undated" (.bare) and "No published date" (.labeled)` (rides in F-1) · `MNT-3 · PVPublishedDate.swift:56 · L10n.Dates.rowUndated now has one reader` · `MNT-4 · records_bench_test.go:23 · rewrap doc comment` (rides in F-2) · `CON-2 · records_test.go:392 · "unknown" case starts undated; dated→unknown covered only by TestRecordsApply "date unknown"`

### Fix plan 1

**F-1 — Translator comments name only the screens that read each key** (from UX-1, UX-2)
Files: `macos/App/Platform/L10n.swift` (`L10n.PublishedDate`), `macos/App/Resources/Localizable.xcstrings` (`publishedDate.*` comments), `macos/App/DesignSystem/README.md:210`. Skill: `add-localized-string`.
Failing test first: none (copy comments).
Do: `label` and `none` → "a Source's published date on a Sources list row". `help` → "hover text on a Source's published date in the Sources list and the Person page's Sources section". `spoken` and `noneSpoken` → "VoiceOver part of a Source's row in the Sources list and the Person page's Sources section". Keep the Swift doc comment and the xcstrings comment identical. In the DesignSystem README PublishedDate row, say `.bare` shows "Undated" and `.labeled` shows "No published date", as the recipe's doc comment does.
Check: `python3 scripts/check-localizable-xcstrings.py` OK; `rg "Copy Source form|Source page header" macos/App/Platform/L10n.swift macos/App/Resources/Localizable.xcstrings` prints no `publishedDate` line; scripts/check-pr.sh PASS.

**F-2 — New Go tests build dates with `datevaluetest.YMD`** (from MNT-1, MNT-4)
Files: `core/database/sources/records_test.go`, `core/database/persondetail/claims_test.go`, `core/database/sources/records_bench_test.go:23`.
Failing test first: none (refactor; tests must stay green).
Do: delete `pointYear`; use `datevaluetest.YMD(y, 0, 0)` at every former call. In `TestRecordsDate` "supplied day" use `datevaluetest.YMD(1880, 6, 1)` and drop the `y1880, m6, d1` locals. In `TestClaimsSourceDate` make `setDate` take `*datevalue.Value`; pass `datevaluetest.YMD(1867, 0, 0)`, `YMD(1868, 0, 0)` and nil; drop `y1867, y1868`. Rewrap the edited doc comment in `records_bench_test.go` to its neighbours' width.
Check: `rg -n "pointYear|y1880|y1867" core/database/sources core/database/persondetail` prints nothing; `CGO_ENABLED=1 go test -tags fts5 ./core/database/sources/ ./core/database/persondetail/` ok; scripts/check-pr.sh PASS.

**F-3 — `PVPublishedDate` formats a dated row once per body** (from PRF-2)
Files: `macos/App/DesignSystem/Recipes/PublishedDate/PVPublishedDate.swift`.
Failing test first: none (same output; `publishedDateCell` and `publishedDateTextAndSpokenRow` pin it).
Do: in `dated(_ line:)`, replace both `.help(SourceDateText.help(date) ?? "")` with `.help(L10n.PublishedDate.help(date: line))`. Do not cache a string on `Row` (D-6).
Check: `rg -n "SourceDateText.help" macos/App/DesignSystem` prints nothing; scripts/check-pr.sh PASS (xcode-test).

**F-4 — Plan Landed note** (from CON-1, MNT-2, MNT outside-lens)
Files: `docs/deployment-plan/spike-15/prs/S15-05-person-sources-date.md`.
Do: under the Status line add a **Landed** note listing every difference from the plan: `fillRecordDates` is a named helper (D-2 had `loadRecords` call `lookupDates` directly; `lookupDates` and `settleDate` stay one each); version 0.28.1 → 0.29.0 because `main` had moved to 0.28.1; STEP-4 and STEP-5 in one commit; Build at 3,000 dated Sources is 32 ms / 6.6 MB (budget 50 ms / 8 MB); F-3's help built from the line already formatted. Tick the DoD box.
Check: `python3 scripts/check-plan-docs.py` OK; scripts/check-pr.sh PASS.
