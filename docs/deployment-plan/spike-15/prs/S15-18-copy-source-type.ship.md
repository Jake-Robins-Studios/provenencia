# Ship log — S15-18 A Source type can be copied

**Plan:** [`S15-18-copy-source-type.md`](S15-18-copy-source-type.md) · **Branch:** `s15-18-copy-source-type` · **PR:** #877
**State:** ready

## Round 0 — implement
Head `74970834e`. Gate PASS (orchestrator run). Report deviations: version 0.20.0 → 0.21.0 (main already at 0.20.0, the plan's rebase rule); `OnboardingModelTests.ThrowingStore` gained `copySourceType` and `citationFormats` stubs (own commit, file not named in the plan); STEP-7 and STEP-8 in one commit; two `DesignSystem/README.md` rows (FormLoadArea, CopyPartTick) for the guidance check; `SourceTypesModelTests` and `SourceTypePageModelTests` accessor `labelError` → `labelCheck.error`, same assertions. § 10 manual check not run.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none (diff touches `macos/App/**`, `Localizable.xcstrings`, `api/ffi/**`, `core/database/**`, and the copy loops over catalog rows).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | Handler test does not check AC-3.1's action or D-6's revision user | Fix now → F-1 | verified: `TestCopySourceType` checks only `GetRevision() > 0` (`source_defs_test.go:905`); no `assertLatestAuditAction(…, "copy_source_type")` |
| UX-1 | UX | major | Copy type's save-error callout is not announced | Fix now → F-2 | verified: `SourceTypeCopyDialog.swift:47` has no `announces:`; Add type announces through `PVFormColumns`. Copy Source's callout (`SourceCopyDialog.swift:47`, file this PR edits) gets the same fix as a minor riding along |
| MNT-1 | MNT | major | Two hand-written `QueryRead` → `PVFormLoadState` conversions | Fix now → F-3 (same-pass cleanup) | verified: `SourceTypeCopyModel.swift:81-92` and `SourceCopyModel.swift:77-83`; this PR promotes `PVFormLoadState` and adds the second copy |
| MNT-2, CON-2 | MNT, CON | minor | `partTick` survives and the new sheet adds a matching `tick` wrapper; STEP-5 check false | Fix now → F-4 | verified: `rg partTick macos` prints `SourceCopyDialog.swift:100,107,114,121,131` |
| MNT-3 | MNT | minor | Copy model rebuilds per-level keys and keeps parallel dictionaries | Fix now → F-5 | minor in a file this PR adds; `SourceTypePageModel` already reads via `session.queryHandle` |
| SEC-1 | SEC | minor | `sourcetypes.Create` stores `Formats` without the parser's check | Fix now → F-6 | minor in a file this PR changes; reads stay bounded by `citationformat.MaxFormatBytes`, so a doc contract suffices (rule "caps for adversarial-only costs") |
| UX-2 | UX | minor | Keep editing after Copy type leaves no sign the copy exists | To user → **Fix now → F-7** | user, 2026-11-17: toast only when the move is held and cancelled; the page-opens path stays toast-free (CT-7). Supersedes D-10's "no toast" for that path |
| CON-3 | CON | minor | § 10 manual check not run | To user (manual check at finish) | UI-only paths; the user runs § 10 before merge |

Nits (logged): `MNT-4/UX-3 · macos/App/Platform/L10n.swift:7987 · stale "Maps stable Go/FFI error codes…" doc now attaches to CitationForms (ride along in F-2)` · `MNT-5 · SourceTypePageModel.swift:17 · labelCheck comment still says "validation message"` · `CON-4 · SourceTypePageModel.swift:170 · editLabel writes draft when label unchanged` · `CON-5 · source_defs_test.go:110 · fixture assigns the same field twice`

### Fix plan 1

**F-1 — Prove the copy's audit action and revision user** (from CON-1)
Files: `api/ffi/handlers/source_defs_test.go`.
Failing test first: in `TestCopySourceType` "copies the ticked parts and answers with the count", add `assertLatestAuditAction(t, dir, "copy_source_type")` and a read of the latest `audit_transactions.user_id` that must be non-nil and equal the request's user (as `sources_test.go:1011,1042` do for `CopySource`). Confirm it would fail by temporarily dropping `UserID` from the handler's `writes.Op`, then restore.
Do: test only, unless it fails at head.
Check: `go test -tags fts5 ./api/ffi/handlers -run TestCopySourceType` passes; scripts/check-pr.sh PASS.

**F-2 — Announce a failed copy** (from UX-1, nit MNT-4/UX-3)
Files: `macos/App/Features/SourceTypes/SourceTypeCopyDialog.swift`, `macos/App/Features/Sources/SourceCopyDialog.swift`, `macos/App/Platform/L10n.swift`.
Do: pass `announces: true` to the danger `PVCallout` in both copy sheets (as `SourceDateDialog.swift:44`). In `L10n.swift`, move the stale "/// Maps stable Go/FFI error codes to localized user-facing copy." line from above `enum CitationForms` to above `enum Errors`.
Check: `rg -n 'PVCallout\(tone: \.danger' macos/App/Features/Sources/SourceCopyDialog.swift macos/App/Features/SourceTypes/SourceTypeCopyDialog.swift` shows both with `announces: true` (multi-line call allowed); scripts/check-pr.sh PASS.

**F-3 — One conversion from a cached read to `PVFormLoadState`** (from MNT-1; same-pass cleanup)
Files: `macos/App/Features/Workspace/Session/QueryHandle.swift` (or a file beside it in the session layer, not DesignSystem), `macos/App/DesignSystem/Components/FormLoadArea/PVFormLoadArea.swift`, `macos/App/Features/SourceTypes/SourceTypeCopyModel.swift`, `macos/App/Features/Sources/SourceCopyModel.swift`.
Failing test first: a Swift test of `PVFormLoadState.combining(_:)` (first failure wins, else loading, else ready, empty is ready) and of `QueryRead.formLoadState` for the three cases.
Do: add `extension QueryRead { var formLoadState: PVFormLoadState }` beside `QueryRead` (`.loaded` → `.ready`, `.failed(e)` → `.failed(L10n.Errors.message(for: e))`, `.loading` → `.loading`), and `static func combining(_ states: [PVFormLoadState]) -> PVFormLoadState` on `PVFormLoadState`. Move `SourceCopyModel.loadState` and `SourceTypeCopyModel.loadState` onto them; the formats state joins the combined list as it does now. Delete both hand-written switches.
Check: `rg -n 'case \.failed\(let error\)\??:.*L10n\.Errors\.message' macos/App/Features` prints no line in `SourceCopyModel.swift` or `SourceTypeCopyModel.swift`; existing copy-model tests unchanged and passing; scripts/check-pr.sh PASS.

**F-4 — No private tick wrappers** (from MNT-2, CON-2)
Files: `macos/App/DesignSystem/Components/CopyPartTick/PVCopyPartTick.swift`, `macos/App/Features/Sources/SourceCopyDialog.swift`, `macos/App/Features/SourceTypes/SourceTypeCopyDialog.swift`.
Do: give `PVCopyPartTick` an initializer taking `label: LocalizedStringResource` (convert with `L10n.string` inside), and call `PVCopyPartTick` directly at every tick in both sheets with `.accessibilityIdentifier(…)`. Delete `SourceCopyForm.partTick` and `SourceTypeCopyForm.tick`. Keep the existing String initializer only if a caller still needs it; otherwise replace it.
Check: `rg -n 'partTick|func tick\(' macos` prints nothing; STEP-5's `rg -n 'SourceFormLoad|formReadAgain|partTick' macos docs/*.md .agents .cursor` prints nothing; scripts/check-pr.sh PASS.

**F-5 — Read the three suggestion lists the way the page does** (from MNT-3)
Files: `macos/App/Features/SourceTypes/SourceTypeCopyModel.swift`.
Do: warm the lists with `CatalogQueryKey.typeSuggestionsKeys(project:typeId:)`; read each level through one `suggestionsKey(at:)` and `session.queryHandle(_:)`, as `SourceTypePageModel.suggestionsHandle(at:)` / `rereadSuggestions(at:)` do. Drop `levelKeys` and `levelHandles`. Ride along: fix nit MNT-5 (the `labelCheck` comment in `SourceTypePageModel.swift:17`).
Check: `rg -n 'levelKeys|levelHandles' macos/App` prints nothing; `SourceTypeCopyModelTests` pass unchanged; scripts/check-pr.sh PASS.

**F-6 — State `CreateInput.Formats`'s contract** (from SEC-1)
Files: `core/database/sourcetypes/sourcetypes.go`.
Do: doc comment on `CreateInput.Formats`: the text is stored as is, without `citationformat` parsing; callers pass text already in stored form (`StoredFormatsTx` output), and fresh researcher text goes through `UpdateFormats`. No code change.
Check: gofmt/go-vet PASS; scripts/check-pr.sh PASS.

**F-7 — Say the copy was made when the move to it is held and kept** (from UX-2; user 2026-11-17)
Files: `macos/App/Features/SourceTypes/SourceTypeCopyDialog.swift` (and the page's leave-guard path in `SourceTypePageView.swift` / `SourceTypePageModel.swift` if the hook lives there), `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Failing test first: a Swift model test: after a successful copy whose navigation to the new page is held and then kept (Keep editing), the session's `noticeToast` names the new type; when the navigation goes through (not held, or held then Discard), `noticeToast` stays nil.
Do: when `navigation.go(to: .sourceTypePage(…))` after Copy type is held by the leave guard and the researcher keeps editing, set `session.noticeToast = VocabularyToast(title: <new string naming the new type's label>, body: "", tone: .info)`, as `LeavesForSectionRoot.leave` does. No toast when the new page opens (CT-7 stands for that path). New string, e.g. `SourceTypes.copyMadeKeptEditing(label)`: "Copied as “%@”." — plain, names the new type. Record in the plan's Landed note that this supersedes D-10's "no toast" for the held-and-kept path (user, 2026-11-17).
Check: the new test passes; localizable check PASS; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `0a2f25379`. Gate PASS (orchestrator run). F-1 – F-7 done. Deviations: F-1 added an `assertLatestAuditUser` helper (the cited `sources_test.go` lines check only the action); F-1 confirmed red with the handler's user emptied. F-3 and F-7 tests written first but could not compile before their APIs existed. STEP-5's `rg` still matches `L10n.DesignSystem.formReadAgain`, a live string key used by `PVFormLoadArea`, not a leftover. Commits grouped (F-4+F-5, F-2+F-7). Plan Landed note and `completed.md` record F-7 superseding D-10's "no toast" for the held-and-kept path.
SEC-1 (minor, no re-review): **Resolved**, doc comment on `CreateInput.Formats` in `76d5adac8`.

## Round 2 — review
Reviewers: CON (CON-1), MNT (MNT-1), UX (UX-1); scope `74970834e...0a2f25379`. Not sent: SEC+PRF (only a minor, resolved above).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | (round 1) audit action and revision user | Resolved | `source_defs_test.go:909-910`; `go test … -run TestCopySourceType` ok at `0a2f25379` |
| MNT-1 | MNT | major | (round 1) two `PVFormLoadState` conversions | Resolved | `QueryHandle.swift:31-40` `formLoadState`, `PVFormLoadArea.swift:9-14` `combining`; old switch pattern found only in the new extension |
| UX-1 | UX | major | (round 1) failed copy not announced | Resolved | `announces: true` at `SourceTypeCopyDialog.swift:50` and `SourceCopyDialog.swift:48-53` |

No new findings from any round-2 reviewer. Round-1 minors checked by the orchestrator: MNT-2/CON-2 **Resolved** (`rg 'partTick|func tick\(' macos` empty; STEP-5's `formReadAgain` hit is the live `L10n.DesignSystem.formReadAgain` key, not a leftover); MNT-3 **Resolved** (`levelKeys`/`levelHandles` gone); UX-2/F-7 **Resolved** (`copyMadeWhileMoveHeldIsToastedOnKeepEditing`; the UX and CON round-2 reviewers traced both exits clearing the held label); nits MNT-4/UX-3, MNT-5 fixed; CON-4, CON-5 left as logged.

Fix-round implementer kept re-sending its report after finishing; the orchestrator stopped it (tree clean, nothing pushed after `0a2f25379`).

## Finish
Merged `origin/main` (`4d36820d0`) → `5f830d47b`. One conflict in `spike-15/deployment-plan.md`: kept this PR's S15-18 row (Landed #877, brief in `design/archive/`) and main's S15-19/S15-20 rows (merged seed PR). Gate PASS after the merge.

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: CON-3 (§ 10 manual check, not run); UX-2 answered (toast when held and kept, 2026-11-17)
