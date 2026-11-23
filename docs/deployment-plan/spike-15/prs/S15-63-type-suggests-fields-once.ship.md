# Ship log — S15-63 A type suggests fields once

**Plan:** [`S15-63-type-suggests-fields-once.md`](S15-63-type-suggests-fields-once.md) · **Branch:** `s15-63-type-suggests-fields-once` · **PR:** #955
**State:** ready

## Round 0 — implement
Head `c53d44232`. Gate PASS (orchestrator run). Report: deviations — board frames D32-1 – D32-10 not compared by eye (claude.ai board unreachable to the implementer); manual check § 10 not run (AC-1.3 open of a pre-PR project untested); two unnamed files edited to compile (`PVComboBox.swift` preview, `L10nResolutionTests.swift`); `TestSeedAnnotations` unsuggested-heads total regenerated 120 → 29; `TestMetadataBoardsKeepTheirLevel` → `TestMetadataBoardsOfferTheTypeList`; `formatsReadFailureThenReadAgain` folded into `aFailedFormatsReadFailsTheSheetAndReloads`; STEP-5 and STEP-6 one Swift commit; gitignored `bin/reseed-source-vocab` no longer builds (not in PR).

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF (diff touches `macos/App/**`, `Localizable.xcstrings`, migration `000069.sql`, `api/ffi/**`, `core/database/**`, `macos/App/Features/**` models). Skipped: none. SEC+PRF: clean.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | Page header counts the list; the types column and Copy sheet use the engine's `suggestedFieldCount` | Fix now → F-1 | verified: `SourceTypeSuggestedFields.swift:23` `suggestions.count`; `SourceTypeCopyModel.suggestionCount` is `original.suggestedFieldCount`. D-9 names where the count shows, not its source |
| CON-1 | CON | major | AC-1.3 (open a pre-PR project) has no run evidence; PR body cites it as checked | Fix now → F-3 | verified: round-0 report says § 10 not run; Landed note silent. The run itself is the user's manual check (no migration tests, user rule); the defect is the claim |
| CON-2 | CON | minor | Valued, unsuggested format-head case lost when the test was repurposed | Fix now → F-2 | verified: `sourcemetadata_test.go:3006` renamed to the suggested path; no other case reaches `buildEntries`' valued-head skip for an unsuggested head |
| UX-1 | UX | minor | Copy sheet's loading caption still says it reads suggested fields | To user → Fix now (F-5, user 2026-11-23) | plan § 6 Strings: "`sourceTypes.copy.loading` … stays"; D-19 dropped the read, so the copy is stale but the plan keeps it |
| CON-3 | CON | nit | `GetDraftMetadataBoard` doc says "suggestions at the level" | Fix now → F-4 (rider) | stale comment this PR made stale |
| CON-4 | CON | nit | `sources_test.go:492,539` messages name a suggestion level | Fix now → F-4 (rider) | stale text in a file this PR changes |
| MNT-4 | MNT | nit | `readTypeBoards` named after the deleted `typeBoard` | Fix now → F-4 (rider) | stale name in code this PR changes |

Nits (logged): `UX-2 · SourceTypeSuggestedFields.swift · locked empty card asks to assign (OL-6 chose it)` · `UX-3 · SourceTypeSuggestedFields.swift:498-515 · count spoken twice (OL-8)` · `MNT-2 · SourceTypePageView.swift:282 · preview's artifactFields/graphFields names` · `MNT-3 · L10n.swift:8680 · listAccessibilityLabel title param always the same` · `MNT-5 · sourcetypes.go:70 · long rewrapped comment line` · `MNT-6 · FakeStore.swift · draftMetadataBoardCalls tuple array vs Equatable struct` · `MNT-7 · sourcevocab.go:113 · ListSuggestions opens a tx for one query (D-2)`

### Fix plan 1

**F-1 — The type page's Suggested fields count comes from the engine** (from MNT-1)
Files: `macos/App/Features/SourceTypes/SourceTypePageModel.swift`, `macos/App/Features/SourceTypes/SourceTypeSuggestedFields.swift`, `macos/ProvenenciaTests/SourceTypePageModelTests.swift`. Skill: `add-swift-test`.
Failing test first: a `SourceTypePageModelTests` case where FakeStore's type row carries `suggestedFieldCount` different from the list length (e.g. row says 5, list has 3); the model's new `suggestionCount` reads 5.
Do: add `var suggestionCount: Int` on `SourceTypePageModel` returning `type?.suggestedFieldCount ?? 0` (same source as `SourceTypeCopyModel.suggestionCount`). Use it for the `PVSectionHeader` `meta` (keep the `isLoaded` guard) and for the spoken list label at `SourceTypeSuggestedFields.swift:65`. Leave `suggestions.count` nowhere as a displayed count.
Check: the test passes; `grep -n "suggestions.count" macos/App/Features/SourceTypes/SourceTypeSuggestedFields.swift` prints nothing used as a count; scripts/check-pr.sh PASS.

**F-2 — Restore the valued, unsuggested format-head case** (from CON-2)
Files: `core/database/sourcemetadata/sourcemetadata_test.go`.
Failing test first: not applicable (coverage restore; the code is unchanged). Add the case beside "a valued suggested field is annotated once" and run it.
Do: new `t.Run("a valued unsuggested head is annotated once", …)`: census Source; `sourcevocab.DeleteSuggestion(c, censusTypeID, itemFieldID)` so census no longer suggests `item`; set `item` to "Roll 4"; assert exactly one `item` entry on the Source board with `Value != nil`, `!Suggested`, and the head's need (`NeedUsed` or whatever the census formats give `item`; read it from the formats, do not guess).
Check: the case passes; `go test -tags fts5 ./core/database/sourcemetadata/` PASS.

**F-3 — Say AC-1.3 is the user's manual check, not done** (from CON-1)
Files: `docs/deployment-plan/spike-15/prs/S15-63-type-suggests-fields-once.md` (Landed note).
Do: add a Landed bullet: "AC-1.3 is checked only by § 10 step 4 (D-15), and that open of a pre-PR project was not run by the implementer; it is left to the product owner's manual check." Do not edit the PR body; the orchestrator rewrites it.
Check: scripts/check-plan-docs.py passes.

**F-4 — Stale level wording** (from CON-3, CON-4, MNT-4)
Files: `api/ffi/handlers/metadata.go:263`, `api/ffi/handlers/sources_test.go:492,539`, `core/database/sourcemetadata/sourcemetadata.go` (`readTypeBoards`).
Do: CON-3 — the `GetDraftMetadataBoard` doc comment says "the type's suggestions and the fields its formats head at the level", matching the proto comment. CON-4 — the two failure messages drop "artifact-level"/"graph-level" (say what the type suggests). MNT-4 — rename `readTypeBoards` to `readTypeNeedsAndSuggestions` at its definition and both callers, and fix the rewrapped `listWorkspaces` comment's short middle line.
Check: `rg -n "readTypeBoards|artifact-level suggestion|graph-level suggestions" core api` prints nothing; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `209569d94`. Gate PASS (orchestrator run). F-1 done (`suggestionCountComesFromTheEngine`; red by compile failure, not a run). F-2 done ("a valued unsuggested head is annotated once", `NeedUsed` from the census formats). F-3 done (Landed bullet). F-4 done. CON-3, CON-4, MNT-4: Resolved (rg over the old names prints nothing).

## Round 2 — review
Reviewers: CON (CON-1), MNT (MNT-1). UX and SEC+PRF not sent: no Fix-now blocker or major in their lenses. CON-2 (minor): Resolved, read by orchestrator (`sourcemetadata_test.go:3025`). Both reviewers clean; MNT-1 and CON-1 Resolved; no new findings. PR body's AC-1.3 row rewritten by the orchestrator.

## User answer — UX-1
User approved the change (2026-11-23). F-5: `sourceTypes.copy.loading` → "Reading the original's formats"; Landed note records it superseding § 6's "stays". Head `7861562f2`. Gate PASS (orchestrator run). Minor, so no re-review.

## User decision — seeded suggestions are formats only
User, 2026-11-23, spot-checking the dogfood project: the certificates suggested film and database fields no format reads. Cause: the seed's record-type rule added every copy field to 10 types (2–6 fields each); before S15-63 that reached Artifact boards only, now every board. User: "formats only". F-6: rule dropped, `seedSuggestions` regenerated from `derivedSuggestions` (census 21 → 16, `citing` last; certificates 17 → 11), § 2.3, plan ACs, § 10 and Landed note updated. Head `8cc0db3bd`. Gate PASS (orchestrator run). Seed data and docs only; no re-review.

## Result
Gate PASS (`8cc0db3bd`) · CI green · open: none · follow-ups: none · to user: — (UX-1 answered) · manual check § 10 incl. AC-1.3 left to the product owner
