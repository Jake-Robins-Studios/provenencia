# Ship log — S15-54 Citations hold metadata

**Plan:** [`S15-54-citations-hold-metadata.md`](S15-54-citations-hold-metadata.md) · **Branch:** `s15-54-citations-hold-metadata` · **PR:** #965
**State:** ready

Base: `main` @ `4db4944fa`. `VERSION` there is 0.38.0, so this PR takes 0.39.0.

## Round 0 — implement
Head `df4171b7b`. Gate PASS (run by the orchestrator). Deviations: STEP-1 and STEP-2 are one commit; T-11 is two new test functions and T-15 is split in two; `TestListByOwnersTx` and `TestReadDraftsTx` use a 15-byte Citation id where they asserted a Citation is refused; a stale citation-map sentence was deleted; one DoD sweep pattern matches the new, correct text.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| PRF-1 | PRF | blocker | A Citation value save reloads the hidden field list and its counts | Fix now → F-1 | verified: `.metadataFieldsList` has no `whenHidden`, so `applyHiddenPolicy` revalidates; siblings use `.markStale`. Measured about 0.2 ms at Scale, linear |
| CON-2, UX-1, MNT-3 | CON, UX, MNT | major | Copy and comments list three holders of a field's values | Fix now → F-2 | verified by `rg`; plan § 6 Strings missed the enumerations |
| CON-1, MNT-3 | CON, MNT | major | DoD doc lines skipped; one contradicts the code | Fix now → F-3 | plain in `effects/README.md`, `source-layer-data-model.md` |
| MNT-1 | MNT | major | `MetadataLevels` and Swift `metadataLevels` equal the whole level set | To user → F-4 | user (2026-11-24): remove both; supersedes D-4, D-12 and the list in rule "One level type" |
| MNT-2 | MNT | major | `fillValues` pairs each level with its id twice | Fix now → F-5 | verified in `load.go`; D-8's behavior is unchanged |
| MNT-4 | MNT | minor | "Exactly one marked up" worked out in two places | Fix now → F-6 | verified; D-1's signature and messages kept |
| MNT-5 | MNT | minor | The bare-Citation fixture is copied | Fix now → F-7 | same-pass cleanup: the PR adds three copies |
| CON-3 | CON | minor | AC-1.4 is not true for `Clear`; only `Set` is tested on a missing Citation | Fix now → F-8 | code right, AC wording wrong: Landed note plus tests |
| CON-4 | CON | minor | AC-3.5's Observation count cannot fail | Fix now → F-8 | plain |
| UX-1, CON-2 (`sourceTypes.suggested.meaning`), CON-1 (e) | UX, CON | minor | "Offered on every Source, Artifact and Evidence graph" and the board list in § 5.2 | Later PR → S15-56 | true of the app until S15-56 draws the board; written into its map entry |

Nits (logged): `MNT-6, CON-7 · sourcemetadata_test.go:1830, 2226 · failure text "citation owner" now tests a short id` · `MNT-7 · vocabkey.go:48, owner.go:13 · re-wrap` · `CON-5 · TestDeleteCitationReleasesMetadata checks only the first delete's order` · `CON-6 · Landed T-11 line says three functions, names two`. All ride with F-4 and F-8.

### Fix plan 1

**F-1 — A hidden field list is marked stale, not reloaded** (PRF-1)
Files: `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` and any test that assumed the reload. Skill: `add-swift-test`.
Failing test first: beside `metadataFieldUsageRevalidatesFieldsList`, a hidden warmed fields key on `apply(CatalogWriteEffects(lists: [.metadataFieldUsage]))` fetches nothing, keeps its value, and reloads on the next `query`; a visible one reloads at once.
Do: `whenHidden: .markStale` on `.metadataFieldsList`. First check that every mounted reader of the key (`SourcePageModel`, `SourcePageContext`, `SourceTypePageModel`, `MetadataModel`) runs in a place whose `queryKeys` list it in `PlaceRegistry`, so it counts as visible; if one does not, add the key to that place. Where a test applied effects on a key no place shows, make it visible or re-query; never drop its assertion.
Check: the test; the Xcode tests pass.

**F-2 — Copy and comments name the Citation as a holder** (CON-2, UX-1, MNT-3)
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/App/Platform/GenealogyStore.swift`, `CatalogQueryRegistry.swift`, `CatalogMutation.swift` (near line 67), `api/proto/engine.proto` (line 377; regenerate), `core/database/metadatafields/metadatafields.go` (75), `core/database/effects/registry.go` (126), `core/database/sourcemetadata/sourcemetadata.go` (package comment). Skill: `add-localized-string`.
Do: `error.metadatafields.in_use` → "That metadata field still holds a value on a Source, Artifact, Evidence graph or Citation." `sourceTypes.toast.removedBodyWithValues`: "Source, Artifact, graph, Citation or Source type that uses it is unchanged" / "Sources, Artifacts, graphs, Citations and Source types that use it are unchanged", with its `defaultValue`, comments and doc comments (and `removedBodyNoValues`' comment). Leave `sourceTypes.suggested.meaning` alone (S15-56).
Check: `rg -i "sources?, artifacts?,? (and|or) (an )?(evidence )?graphs?|sources?, an artifact or an evidence graph|artifacts, graphs (and|or)" core api macos/App -g '!*.sql'` prints only `sourceTypes.suggested.meaning` and lines that are not about who holds a value.

**F-3 — The domain docs the Definition of done names** (CON-1, MNT-3)
Files: `core/database/effects/README.md` (17), `docs/source-layer-data-model.md` (290, 452, § 10 table list; "merges the three tables" at 321 only if it is about levels), `docs/deployment-plan/spike-15/deployment-plan.md` (S15-56 entry).
Do: README line 17 excepts the Citation's values; line 290 names `citation_metadata`; the anchor becomes `#55-metadata-at-four-levels`; the list gains `citation_metadata` and `citation_metadata_layout`. In S15-56's **Ships**, append: "`sourceTypes.suggested.meaning` (\"Offered on every Source, Artifact and Evidence graph of this type\") and the board list in `docs/source-layer-data-model.md` § 5.2 name the Citation (S15-54 ship log, UX-1)."
Check: `rg '55-metadata-at-three' .` finds nothing; `python3 scripts/check-plan-docs.py` passes.

**F-4 — One list of levels** (MNT-1; user, 2026-11-24; supersedes D-4 and D-12)
Files: `core/vocabkey/vocabkey.go`, its test, `core/database/sourcemetadata/sourcemetadata.go` (771) and test, `core/database/catalogmodel/metadata.go` (comment) and test, `api/ffi/swift_vocabulary_test.go`, `api/proto/engine.proto` (769; regenerate), `macos/App/Platform/Level.swift`, `docs/deployment-plan/spike-15/deployment-plan.md` (working rules that name `MetadataLevels()`).
Do: delete `MetadataLevels` (Go) and `metadataLevels` (Swift), the "metadata levels" parity row and `levelListEntry` with its comment. `NearestFirst` reverses `Levels()`; every reader uses `Levels()`. Re-wrap the comments (MNT-7). In the map, "One level type" and the rules that name the subset say: all four levels hold metadata, `vocabkey.Levels()` is the set (user, 2026-11-24); leave landed PRs' scope entries and plans as history. Rename the two "citation owner" failure texts (MNT-6, CON-7).
Check: `rg -i 'MetadataLevels\b' core api macos .agents docs/*.md` finds nothing (type `MetadataLevelTables` aside); `TestLevels` and `TestSwiftVocabularyMatchesGo` pass.

**F-5 — A subject lists its owners once** (MNT-2)
Files: `core/database/citationrender/load.go`.
Do: one `func (s *subject) owners() []sourcemetadata.Owner` (match the real type and its nil guards); the first loop appends it, the second sets `v.Rows[o.Level] = byOwner.Of(o)` for each. Nothing else.
Check: `go test -tags fts5 ./core/database/citationrender/...`, `TestRenderScale` at 10 and 14 SELECTs.

**F-6 — One check of the marked up** (MNT-4)
Files: `core/database/catalogmodel/metadata.go`.
Do: an unexported `sourceUp() (*MetadataUp, error)` owns the count and D-1's two error texts; `SourcePath` uses it; exported `SourceUp` keeps D-1's signature and wraps it.
Check: `TestSourcePath`, `TestMetadataEffects` pass with messages unchanged.

**F-7 — A shared bare-Citation fixture** (MNT-5)
Files: `core/database/citations/citationstest/` *(new)*; the bare copies.
Do: `Create(c, userID, citations.CreateInput) (citations.Citation, error)` through the write pipeline with no Observations, shaped like `artifactstest.Create`, defaulting an empty `LocatorJSON` to the page-1 locator. Move onto it every test whose body is a `writes.Run` around `citations.CreateWithObservations(..., nil)` and needs only the Citation: `artifacts_test.go` (524, 1218), `sourcemetadata_test.go` (1947), `deleteimpact/impact_test.go` (720), `facets_test.go` (267, 446). Leave sites that need the tx or the changes (`effects/*`) and any an import cycle blocks, naming them in the report. A copy whose locator matters passes its own.
Check: `grep -rnE -A6 "citations\.CreateWithObservations\(" core api --include='*_test.go' | grep "}, nil)"` prints only the `effects/` sites and those named.

**F-8 — Tests and notes that say what is true** (CON-3, CON-4, CON-5, CON-6)
Files: `sourcemetadata_test.go` `TestOwnerTables`, `api/ffi/handlers/citations_test.go`, the plan's Landed note.
Do: the missing-owner check also runs Dismiss, Reorder, Apply and CreateAll (each `ErrInvalid`, no row); do not change `Clear`. AC-3.5 sends one Observation. `TestDeleteCitationReleasesMetadata` checks every `citation_metadata` delete precedes the citation's. Landed: `Clear` on a missing owner returns no changes, as at every level (AC-1.4's wording); T-11 names two functions; F-1's hidden policy; F-4 supersedes D-4 and D-12; § 6 Strings missed the enumerations.
Check: the tests pass; `scripts/check-pr.sh` PASS.

## Round 1 — fix
Head `42a41a600`. Gate PASS (run by the orchestrator). F-1 to F-8 done; none "not reproduced". `bin/reseed-source-vocab` is gitignored (the user's local one-off, broken since S15-63), not tracked as the report says; it also names `MetadataLevels` now.

## Round 2 — review
Scope `df4171b7b...42a41a600`. Reviewers: CON, MNT, UX, SEC+PRF (each had a Fix-now major or blocker).

MNT, UX, SEC+PRF: Clean; MNT-1, MNT-2, MNT-3, UX-1, PRF-1 Resolved. CON: CON-2 Resolved; **CON-1 Not resolved** in one part (`effects/README.md` line 17; F-3 edited line 15 instead). No new finding. The orchestrator read the minors' fixes: MNT-4, MNT-5, CON-3, CON-4 Resolved.

Nits (logged): `MNT-8 · metadatafields_test.go:424 · the case name lists three holders` (rides with F-3b).

### Fix plan 2
No round-2 blocker; this only completes F-3, an open major.

**F-3b — effects/README.md line 17** (CON-1, MNT-8)
Files: `core/database/effects/README.md`, `core/database/metadatafields/metadatafields_test.go`.
Do: line 17's sentence becomes "so a note, credibility, or file write, or a metadata write other than a Citation's value, moves activity and drops no cached Evidence graph." Rename the test case at line 424 only if it covers no Citation to "UsedBy and List count every level alike"-style wording that is true of its body; otherwise name the Citation. No other change.
Check: `scripts/check-pr.sh` PASS.

## Round 2 — fix
Head `2d0ebe794`. Gate PASS (run by the orchestrator). F-3b done; CON-1 Resolved (read by the orchestrator). MNT-8 left: the name is true of the case's body. The commit's subject misstates it (a Citation's value is the one metadata write that does drop cached graphs); the README text is right.

## Result
Gate PASS · CI on the PR · open: none · follow-ups: none · later PR: S15-56 (`sourceTypes.suggested.meaning`, § 5.2 board list) · to user: MNT-1 (answered: remove both lists)
