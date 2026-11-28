# S15-29 — The provenance sheet loads its records when it opens

**Status:** Landed in [#1024](https://github.com/Jake-Robins-Studios/provenencia/pull/1024) (2026-11-28)
**Spike / slice:** Spike 15 · Slice 8 — Provenance loading
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no new chrome: the record area keeps S15-D9's load area, and only its two strings change; S15-D18 descoped, user, 2026-11-28)
**Board:** —
**Depends on:** S15-21 (landed [#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930)), S15-28 (landed [#1016](https://github.com/Jake-Robins-Studios/provenencia/pull/1016)), S15-31 (landed [#1010](https://github.com/Jake-Robins-Studios/provenencia/pull/1010)), S16-09 (landed [#780](https://github.com/Jake-Robins-Studios/provenencia/pull/780))
**Blocks:** —
**Branch:** `s15-29-records-load-when-the-sheet-opens`
**Version bump:** minor, 0.51.0 → **0.52.0** (if `main`'s `VERSION` has moved, the next minor after it): the sheet's records move to a read on open, and an RPC only this build called goes ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (the key and registry arm), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** working rules "Records load when the sheet opens", "Citations render on demand, from SQL", "Today's line stays the fallback, in Swift" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); [`S15-28`](S15-28-records-load-on-their-own.md) (the read this PR calls, its D-5, D-6, D-8); [`macos-client-patterns.md`](../../../macos-client-patterns.md) "One detail key for every kind"
**Planned:** 2026-11-28 against `main` @ `82112d4`
**Review:** [`S15-29-records-load-when-the-sheet-opens.review.md`](S15-29-records-load-when-the-sheet-opens.review.md) — Fits with changes / Ready with changes, 2 rounds; every finding Fixed; the one To user answered (Go counts the pooled heading in this PR)

### Implementer — read this first

1. **This file is the whole task.** Read it top to bottom before you change code. Then read every file under **Current state** and load every skill under **Skills to load**.
2. **Check the base.** Compare `main` with the **Planned** commit. If a file under **Current state** has changed so a row is no longer true, stop and report which rows.
3. **Decisions are made.** Do not reopen a **Decision** or a **Scope** line, and do not swap in a design you like better. If one cannot work, stop: say which ID it is, what you found (path, line, output), and what you would need. Do not improvise around it.
4. **Do only In.** Out stays out, even when it is one line away. Do not refactor, rename, or tidy code the plan does not name.
5. **Work the Steps in order.** Run each step's check before you start the next. A failing check is fixed in that step.
6. **Hit a Stop condition → stop.** Report it. Do not work around it.
7. **Done is the Definition of done.** Report each box with its evidence: the command and its result, the test name, or the manual check you ran.
8. **Docs-only lines in the DoD are part of the PR.** Do not skip them.

---

## Landed

- The version bump is 0.53.0, not 0.52.0: `main`'s `VERSION` was already 0.52.1 when the PR was cut.
- T-15's last case (`GetProvenanceRecords` on S16-80's fixture) runs in `core/database/conclusiondetails` through `ProvenanceSheet` over a birth place with three Sources, and not through the handler: the handlers' tests have no Place life row fixture. The wire mapping of `pooled_support` is asserted in `TestReconcilerOutcomeProtoCarriesVoteAndArtifact`.
- The Event and Place test fixtures take their counts from `ReconciledValueDisplayTests.counted` (one record per outcome, the lead value's Sources), and the Person tests pass counts directly; `FakeStore`'s detail sets `recordCounts` the same way so the fake app's rows still show.
- T-12 measured 2,963 bytes for the detail of `researchedPerson(t, 30, 2)`.
- STEP-3 to STEP-6 are one commit: the row, key and sheet-content changes swap together and the Swift tree builds only with all of them.
- The manual check (section 10) was not run by the implementer.

## 1. Objective

A detail page no longer carries every record behind its values. Person, Event and Place rows show their Source and record counts from the engine's `FieldRecordCounts`. When a row's provenance sheet opens, it reads that row's records and their citations in one call (`GetProvenanceRecords`, S15-28). The sheet draws its header at once from the row and shows the kit's load area until the records arrive. Swift stops counting records and searching for deniers; on a life row's place sheet, Go also sends each pooled Place value's Source count. Then the detail read stops sending outcomes, and the old citation-only read (`RenderCitations`) goes.

**Why now.** S15-28 shipped the counts, the denial facts and the sheet read with the detail read still sending outcomes (S15-28 D-1). This PR switches the app over and removes what that leaves dead.

**What stays.** Every row's label, value, badge, count line, against line, other values and open arrow. The sheet's header, columns, owner lines, value headings, fold, copy buttons, the load area's loading and failed bodies, and Done. The Gallery and the likeness viewer still read their record from `PictureDetail.record`. A reload after a write swaps the records quietly behind the ones shown, and a failed reload stays silent (user, 2026-11-28).

## 2. User stories

**US-1.** As a researcher, when I open a Person, Event or Place page, I see each row's count lines as before, though the page no longer loads the records behind them.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A merged name with `record_counts` {4, 2} and no outcomes | The row reads "2 Sources" and offers the sheet; VoiceOver says "…merged from 2 Sources" |
| AC-1.2 | A mixed death date with `record_counts` {5, 3} | The row reads "3 Sources" |
| AC-1.3 | A Person field other than name (sex at birth) with `record_counts.records` 0 | No row for it; with records 1, the row shows |
| AC-1.4 | An Event date field and a Place toponym with `record_counts.records` 0 | The date row reads from the next dating Property; the Names row is the empty row |
| AC-1.5 | A birth date life row whose two owners have `record_counts.records` 3 and 1 | The row offers the sheet; `recordCount` 4 |

**US-2.** As a researcher, when I open a row's provenance sheet, its records load then, with their citations.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The Person page's name row (property `p-name`) of Person `P` | One `getProvenanceRecords` call, request `.fields([(P, p-name)])` |
| AC-2.2 | A Place's Period row over `start_date` and `end_date` of Place `L` | Request `.fields([(L, start_date), (L, end_date)])`, in the row's field order |
| AC-2.3 | The Person's birth place row | Request `.derived(personID: P, kind: .birthPlace)` |
| AC-2.4 | The sheet is open and its read has not answered | The title, the value header and its summary ("merged from 2 Sources · 4 records") and the column headings draw; the record area shows "Loading records" |
| AC-2.5 | The read answers | The table draws once, its records and citations from the answer; the summary does not change |
| AC-2.6 | The read fails | "Records could not be read", the error's message and Read again; Read again reads again |
| AC-2.7 | A write names a Source the sheet's read reported | The sheet's key reloads once and the table swaps when the reload answers; no loading state in between |
| AC-2.8 | The sheet closes | The key is released (`WorkspaceSession.release`) |

**US-3.** As a researcher, every record reads as it did, worded from what the engine says.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | A negative record with `denied_a_value` true | Reads "kept", check mark, primary ink |
| AC-3.2 | A negative record with `denied_a_value` false | Reads "disagrees · did not eliminate", minus mark, secondary ink |
| AC-3.3 | A denied record with `denied_by_source_title` "Court deposition, 1862" | Reads "denied by Court deposition, 1862" |
| AC-3.4 | A denied record with `denied_by_source_title` "" | Reads "denied" |
| AC-3.5 | Two links to one Place in a birth place sheet, a shared value whose records cite Sources A, A and B | The pooled heading reads "2 Sources" |

**US-4.** As a contributor, the detail read sends no records and the citation-only read is gone.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `GetConclusionDetail` on `namedPerson` | The name field has no outcomes, `record_counts` {2, 1}, and `inputs` still name the graphs and Sources of its records |
| AC-4.2 | `GetConclusionDetail` on a Person with a birth date row | The derived owner's field has no outcomes and `record_counts.records` 2 |
| AC-4.3 | `GetProvenanceRecords` on the same name pair | Its owner's field has 2 outcomes (unchanged) |
| AC-4.4 | The DoD's sweep command | No hit outside `macos/App/Platform/Generated/`, `api/proto/engine/engine.pb.go` and the `reserved "METHOD_RENDER_CITATIONS"` line |
| AC-4.5 | `GetProvenanceRecords` for a birth place row whose two links to York cite Sources s1 and s2, and a link to Leeds citing s3 | Each York link's displayed value has `pooled_support` 2; the Leeds link's 1; the detail read's values have 0 |

## 3. Scope

| In | Covered by |
| --- | --- |
| Go: each pooled Place value's Source count on the sheet read | STEP-1; AC-4.5 |
| Swift types for the counts, the denial facts, the sheet request; the store read | STEP-2; AC-2.1, AC-2.2, AC-2.3 |
| Row counts and record test from `FieldRecordCounts`; Person, Event and Place builders filter on counts | STEP-3; US-1 |
| Wording from `denied_a_value` and `denied_by_source_title`; the pooled heading reads Go's count | STEP-4; US-3 |
| The load area's two strings | STEP-5; AC-2.4, AC-2.6 |
| The sheet's key by request; its value holding owners and citations; its content built from the read; host and presenter | STEP-6; AC-2.1 – AC-2.8 |
| Go: the detail read sends no outcomes | STEP-7; AC-4.1, AC-4.2, AC-4.3 |
| `RenderCitations` and `citationrender.Render` go | STEP-8; AC-4.4 |
| Docs and skill lines the change makes false; `provenance-loading.md` retired | STEP-9 |

| Out | Home |
| --- | --- |
| An empty state for a sheet whose read answers no owners (owner merged or deleted since the page read) | not planned (user, 2026-11-28): D-9 |
| A notice when a reload behind shown records fails | not planned (user, 2026-11-28) |
| `PictureDetail.record` and the Gallery's records | not planned: the Gallery and viewer read one record per picture |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Sheet read (Go) | `core/database/conclusiondetails/conclusiondetails.go` `ProvenanceSheet` (life row case takes `PersonDerivedRow`'s owners), `ReconciledValue`, `ownerVerdict`; `api/proto/engine.proto` `ReconciledValueDetail` (last field `value = 5`); `api/ffi/handlers/conclusion_detail.go` `conclusionFieldProto` (maps values) | No count per pooled Place value; Swift computes it |
| Wire types | `macos/App/Platform/GenealogyStore.swift` `CatalogConclusionField` (`outcomes` has no doc comment), `CatalogReconciledValue`, `CatalogReconcilerOutcome`, `CatalogOwnerField`, `CatalogDerivedRowKind`, `CatalogRenderedCitations`, `CatalogProvenanceSheetRead` (`init(_ reply: CatalogRenderedCitations)`), protocol `renderCitations(projectDir:citationIDs:)` | No counts, no denial facts; the sheet's value holds renders only |
| Go store | `macos/App/Platform/GoStore.swift` `mapConclusionField` (maps values inline), `mapReconcilerOutcome`, `mapDerivedRow` (wire→Swift kind switch and owner mapping inline), `renderCitations` (render mapping inline); `macos/App/Platform/CoreInvoke.swift` `CoreMethod.renderCitations` | Drops `record_counts` and the two denial fields; no call for `GetProvenanceRecords` |
| Fake store | `macos/App/Platform/FakeStore.swift` `renderCitationsReplies`, `renderCitationsInputs`, `renderCitationsHold`, `renderCitationsCalls`, `renderCitationsError`, `renderCitations` | — |
| Counts and wording | `macos/App/Platform/ReconciledValueDisplay.swift` `sourceCount`, `distinctSourceCount`, `countLine`, `spokenState`, `counted`, `deniedSomething`, `outcomePhrase` (`.denied`, `.against`), `outcomeMark` | Count Sources and search deniers over `field.outcomes` |
| Row model | `macos/App/Features/Conclusions/ReconciledValueRowModel.swift` `RecordsSource` (doc names `provenanceContent()`), `recordCount`, `hasRecords`, `provenanceContent()` | `recordCount` counts outcomes; the sheet's content is built from the page's fields |
| Page builders | `PersonDetailContent.swift` `rows` (`!field.outcomes.isEmpty`), `EventDetailContent.swift` `dateRow` (`!$0.outcomes.isEmpty`), `PlaceDetailContent.swift` `namesRow` (`!field.outcomes.isEmpty`), all in `macos/App/Features/Conclusions/` | Filter on outcomes the page will no longer carry |
| Sheet content | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` type doc, `Record.init(outcome:in:)`, `init(field:title:shown:)` (summary calls `sourceCount` at line 322 and counts built records), `spanning`, `derived` (pools owners by `ownerID` inline), `valueGroups` (headings from the field it is given), `pooledValueGroups` (sums support and calls `distinctSourceCount`), `withRenders` | Header counts what it builds |
| Sheet recipe | `…/ProvenanceSheet/PVProvenanceSheet.swift` `PVFormLoadArea(loadingText: L10n.ProvenanceSheet.citationsLoading, errorTitle: L10n.ProvenanceSheet.citationsFailedTitle, …, accessibilityIdentifierPrefix: "\(idPrefix).citations")`; previews "Citations loading", "Citations failed" (message "The citations could not be rendered.") | Copy names citations |
| Host and presenter | `macos/App/Features/Conclusions/ProvenanceSheetHost.swift` (doc, `content:`, key from `content.records`' Citation ids); `ReconciledValueRow.swift` `ConclusionDetailRowsSection`; `ConclusionDetailPage.swift` `ConclusionDetailPageSectionsContext` (built at line 349), `ConclusionDetailDefaultPageSections`; `PersonDetailView.swift` `PersonDetailSections` (its own `entityId`); `macos/ProvenenciaTests/ConclusionAnchorRestoreTests.swift` line 81 builds `ConclusionDetailRowsSection(rows:…)` | The rows section knows no entity id |
| Key and registry | `macos/App/Features/Workspace/Session/CatalogQueryKey.swift` `provenanceSheet(project:citationIds:)`; `CatalogQueryRegistry.swift` arms `.provenanceSheet` (comment and `renderCitations` call) and `.conclusionDetail` (comment: a rename "reaches the provenance sheet, the Gallery captions and the viewer's record row") | — |
| Strings | `macos/App/Platform/L10n.swift` `L10n.ProvenanceSheet.citationsLoading`, `.citationsFailedTitle`; `macos/App/Resources/Localizable.xcstrings` their keys | — |
| Go detail mapping | `api/ffi/handlers/conclusion_detail.go` `conclusionFieldProto` (maps outcomes in a loop), `ownerFieldProto`, `derivedRowsProto`; `provenance_records.go` `GetProvenanceRecords` | One field mapper sends outcomes on both reads |
| Go render | `api/ffi/handlers/citation_render.go` `RenderCitations`, `renderedCitationsProto`; `api/ffi/dispatch.go` `MethodRenderCitations`; `core/database/citationrender/render.go` `Render`, the `MaxCitations` and `MaxBatchBytes` comments; `api/proto/engine.proto` `METHOD_RENDER_CITATIONS = 124`, `RenderCitationsRequest`, `RenderCitationsResponse`, `ConclusionField.outcomes` | `Render`'s only non-test caller is `RenderCitations` |
| Go tests | `api/ffi/handlers/conclusion_detail_test.go` `TestGetConclusionDetail`, `TestConclusionDetailProtoCarriesVoteArtifactAndMembers`, `TestGetConclusionDetailWarmReadsNoRecordSQL`, `TestGetConclusionDetailCarriesDerivedRows`; `provenance_records_test.go` `TestDetailPayloadWithoutRecords`, `TestGetProvenanceRecordsWarmReadsNoRecordSQL` (compares with `citationrender.Render`); `citation_render_test.go` `renderCitations`, `TestRenderCitations`; `core/database/citationrender/render_test.go` (calls `Render` at lines 200, 528, 543, 553), `TestRenderLimits`; `core/database/citationrender/scale_test.go` `TestRenderScale` (calls `Render`, asserts exact SELECT counts) | Assert outcomes on the detail, or call what goes |
| Swift tests | `macos/ProvenenciaTests/ReconciledValueDisplayTests.swift` (`field`, `outcome`, the static var `mergedName`, the count and denial tests); `ProvenanceSheetTests.swift` (`aRowBuildsItsContentOnCall`, `theSummarySaysOnlyWhatTheRowKnows`, `aPooledPlaceGroupHasOneHeadingPerValue`, `twoLinksToOnePlaceFormOneGroup`); `PersonDetailTests.swift`, `EventDetailTests.swift`, `PlaceDetailTests.swift` (call `provenanceContent()`); `WorkspaceSessionTests.swift` `ProvenanceSheetSessionTests`; `CatalogQueryRegistryTests.swift` `provenanceSheetKeySortsAndFollowsInputs`; `CatalogSessionStoreTests.swift` `renderCitationsAnswersTheAskedIds`; `OnboardingModelTests.swift` (stub `renderCitations`) | Build records by hand on the page's fields |
| Docs | `docs/macos-client-patterns.md` "One detail key for every kind" (says the detail carries every outcome and, for a Person, the records behind its life rows); `docs/design-system-layers.md` §2 Recipes and `.agents/skills/add-ui-component/SKILL.md` step 3 ("built when the recipe opens"); `.agents/skills/add-workspace-place/SKILL.md` line 102 (key factories); `docs/citation-formats.md` lines 70 and 76 (`RenderCitations`); `docs/deployment-plan/spike-15/provenance-loading.md` **Status** line | — |

**Precedent.** S15-21 ([#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930)) is the sheet's key, registry arm, host, `FakeStore` fakes and session tests; this PR changes what they carry, not their shape. `citationsByArtifact` in `CatalogQueryKey.swift` (`citationGraphId`, `citationArtifactId`) is the precedent for ids with positions read by named accessors. `PromoteTargetCode` in `macos/App/Platform/ConclusionVocabulary.swift` (`init(wire:)` and `var wire`) is the precedent for one two-way wire mapping. S15-28 ([#1016](https://github.com/Jake-Robins-Studios/provenencia/pull/1016)) pulled `ownerFieldProto` and `renderedCitationsProto` out so both handlers map one way.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | A row's request is built from the page's entity id: `.field` → one pair (entity, field); `.spanning` → one pair per field in the row's order; `.derived` with a kind → (entity, kind). A `.derived` row with no kind, or a row with no records, has no request | Every row's records belong to the page's entity, or to the Person for a life row; the row model needs no new id | An owner id on every row model — every builder and test changes for an id the page already has |
| D-2 | The page's entity id reaches the presenter through `ConclusionDetailPageSectionsContext.entityId` *(new)* and `ConclusionDetailRowsSection.entityId` *(new)*; `PersonDetailSections` loses its own `entityId` and reads `context.entityId` | `ConclusionDetailPage` holds `entityId`; sections learn the page one way | Reading it from the session's location — couples the section to navigation |
| D-3 | The key's ids start with a tag: `["fields", owner₁, property₁, …]` or `["life", person, kind.rawValue]`; `CatalogQueryKey.provenanceRequest` reads them back (precondition on kind, as `citationGraphId`). Pairs keep the row's order; a pair with an empty id is dropped and repeats are removed (first kept) | Keys are kind, project and ids (S16-25); Go answers in request order (S15-28 `FieldRecords`); the tag keeps one pair from reading as a life row | A second key kind for life rows — two registry arms for one read |
| D-4 | `CatalogDerivedRowKind` gets `String` raw values in Go's spelling (`birth_date`, `birth_place`, `death_date`, `death_place`) for the key, and one two-way wire mapping (`init?(wire: Provenencia_Engine_V1_DerivedRowKind)`, `var wire`) in a `GoStore.swift` extension; `mapDerivedRow` and `getProvenanceRecords` both use it | One spelling per layer, one mapping, as `PromoteTargetCode` does | A Swift-only camelCase spelling and a second switch |
| D-5 | The row computes the sheet's header counts once: `recordCount` (sum of `recordCounts.records` over its fields or owners) and, for a life row, `ownerCount` = `PVProvenanceSheetContent.ownerGroups(pageOwners, shownOwnerID:).count`. The content builders take those counts and never count records or owners themselves; `ownerGroups` is the one pooling rule (Place, else entity; shown owner first), used for the count and the groups | The header draws in every load state and does not jump; one count switch, one pooling rule | Builders re-deriving counts from page fields — the same sum in four places |
| D-6 | The row matches the read to itself before building: `.field` and `.spanning` take each read owner field whose `propertyID` matches one of the row's fields, in the row's order; a field the read left out gives no records. `.derived` takes the read's owners as they come, with the row's `shownOwnerID` and `kind` | Go leaves out a pair with no records (S15-28 D-8); the read is newer than the page | Matching by position — breaks when Go leaves one out |
| D-7 | `ReconciledValueDisplay.counted` and `outcomeMark` lose their `in field:` parameter and read `outcome.deniedAValue`; `outcomePhrase` `.against` reads it too; `.denied` reads `deniedBySourceTitle` ("" → the plain phrase). `outcomePhrase` and `Record.init(outcome:in:)` keep `in:` (folded value, Read as), so `ConclusionPictureViewer`'s `Record(outcome:in: nil)` is unchanged | S15-28 D-6 states Go's rule | Keeping an unused parameter |
| D-8 | Go counts a pooled Place value's Sources. `poolPlaceSupport(owners []OwnerField)` *(new, unexported)*, called by `ProvenanceSheet` in its life row case after the owners are built, sets `ReconciledValue.PooledSupport` *(new)* on each displayed value of each owner with a `Place`: the distinct `SourceID`s among outcomes whose `GroupRank` equals the value's rank, over every owner with the same `Place.Entity.ID` whose displayed value has the same `Value.Scalar` (a place link's value is a subject). Every other value, and every value on the detail read, has 0. Wire `ReconciledValueDetail.pooled_support = 6`; Swift `CatalogReconciledValue.pooledSupport` (default 0). `pooledValueGroups` gives a pooled heading `sourceCountLine(value.pooledSupport)` of the run's first member value; its support sum, the `counted` set and the run tuple's `outcomes` go (user, 2026-11-28) | Working rule "Records load when the sheet opens": Swift counts no Sources | Keeping a distinct count in Swift — bends the rule; a preparatory PR — the user chose this PR |
| D-9 | A read that answers no owners draws the ready table with no rows; nothing else is added. The same write moves the page's key, its refresh drops the row's records or the page, and `ConclusionDetailRowsSection`'s `onChange(of: rows)` closes the sheet (user, 2026-11-28) | An extreme edge case; rely on what exists | An empty state with its own copy — declined by the user |
| D-10 | `getProvenanceRecords` returns `CatalogProvenanceSheetRead { owners, citations: [String: CatalogRenderedCitation], inputs }` directly; `GoStore` builds the dictionary (first of a repeated id wins); `init(_ reply:)` and `CatalogRenderedCitations` go | The reply is sheet-only now, as `getConclusionDetail` returns its page value | A reply type beside the value type |
| D-11 | Go: `conclusionFieldProto` and `ownerFieldProto` map no outcomes for every caller. `GetProvenanceRecords` adds them after mapping each owner: `po := ownerFieldProto(o)`, then one `reconcilerOutcomeProto(out)` per outcome appended to `po.Field.Outcomes`; no new helper. `conclusionFieldProto` maps `PooledSupport` on every value. Go core still composes every outcome on the detail read | Counts, state and the read's inputs come from the composed outcomes; only the wire changes; the handler that sends records adds them | A flag or mapper parameter on shared mappers |
| D-12 | `METHOD_RENDER_CITATIONS` becomes `reserved 124;` and `reserved "METHOD_RENDER_CITATIONS";` under a comment line "Citations render with the sheet's records, in GetProvenanceRecords." | The file's convention for removed methods | — |
| D-13 | `TestRenderLimits`' id cap case goes (`RenderAll` has none); its byte cases become `RenderAll`'s: 70 big Citations → none rendered and no error, 60 → 60. `TestRenderScale`'s SELECT counts stay as they are | `RenderAll` leaves an over-budget batch out (S15-28 D-9); at ≤ 2,000 ids it runs `render` once, as `Render` did | — |
| D-14 | `TestRenderedCitationsProto` *(new)* holds the wire mapping `TestRenderCitations`' first case held; the rest of `TestRenderCitations` goes | Its rendering rules are core's tests (`TestRenderNearestLevel`, `TestRenderUnknownAndSupplied`) | Porting every case into `TestGetProvenanceRecords` — each needs a promoted Subject |
| D-15 | The `.conclusionDetail` arm's comment reads: "A rename, a credibility change or a Citation or Artifact label fix reaches the counts and states, the Gallery captions and the viewer's record row through the Sources and graphs its records cite." Its follows do not change | The detail still reports its records' graphs and Sources (D-11), and the counts and Gallery depend on them | Dropping the Source follow — a credibility change would leave counts stale |
| D-16 | `provenance-loading.md` is retired in place: its **Status** line says it shipped as S15-27, S15-28 and S15-29 and is deleted with the spike folder at close ([`archive-docs`](../../../../.agents/skills/archive-docs/SKILL.md)); no link to it changes | Every live link stays true; spike close deletes the folder anyway | Deleting it now — 15 links in plans, review logs and maps to rewrite |

**Rules this plan bends.** None (D-8 keeps the rule). The S15-28 ship log's UX note (an empty state after a merge) is declined by the user (D-9); the map's S15-29 scope entry says so.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `CatalogFieldRecordCounts { records, sources: Int }` *(new)*, `CatalogConclusionField.recordCounts` (default `.init()`), `CatalogConclusionField.hasRecords` *(new)*: `recordCounts.records > 0` | type, fields | `CatalogReconciledValue.support` | Mirrors `engine.FieldRecordCounts`; `hasRecords` is the one test the three page builders share |
| `CatalogReconcilerOutcome.deniedAValue: Bool = false`, `.deniedBySourceTitle: String = ""` *(new)* | fields | `deniedByObservationID` | Beside it, as on the wire |
| `CatalogProvenancePair { ownerID, propertyID }`, `CatalogProvenanceRequest { case fields([CatalogProvenancePair]); case derived(personID: String, kind: CatalogDerivedRowKind) }` *(new, `Sendable, Hashable`)* | types | `Provenencia_Engine_V1_GetProvenanceRecordsRequest` | The app's value of the wire's `oneof row` |
| `CatalogDerivedRowKind: String`; `init?(wire:)`, `var wire` *(new)* | raw values, mapping | `mapDerivedRow`'s switch | D-4 |
| `CatalogProvenanceSheetRead.owners` *(new)*, memberwise init | field | `CatalogProvenanceSheetRead` | D-10 |
| `GenealogyStore.getProvenanceRecords(projectDir:request:) async throws -> CatalogProvenanceSheetRead` *(new)*; `CoreMethod.getProvenanceRecords` *(new)* | store method | `renderCitations` | Replaces it |
| `GoStore.mapOwnerField`, `GoStore.mapRenderedCitation` *(new, private static)* | func | the inline code in `mapDerivedRow` and `renderCitations` | Two readers map one way |
| `FakeStore.provenanceRecordsReplies: [CatalogProvenanceRequest: CatalogProvenanceSheetRead]`, `provenanceRecordsHold`, `provenanceRecordsCalls: [CatalogProvenanceRequest]`, `provenanceRecordsError` *(new)* | fakes | the `renderCitations*` fakes | Same shape for the new read; an unlisted request answers no owners, no citations, `.init()` inputs |
| `CatalogQueryKey.provenanceSheet(project:request:)`, `CatalogQueryKey.provenanceRequest` *(new)* | factory, accessor | `provenanceSheet(project:citationIds:)`, `citationGraphId` | D-3 |
| `ReconciledValueRowModel.provenanceRequest(entityID:) -> CatalogProvenanceRequest?` *(new)*; `provenanceContent(records: [CatalogOwnerField]) -> PVProvenanceSheetContent` (replaces `provenanceContent()`) | funcs | `provenanceContent()` | D-1, D-5, D-6 |
| `PVProvenanceSheetContent.ownerGroups(_ owners: [CatalogOwnerField], shownOwnerID: String?) -> [[CatalogOwnerField]]` *(new, static)* | func | the `ownerIDs` / `membersOf` loop in `derived` | Pulled out: one pooling rule for the count and the groups (D-5) |
| `ProvenanceSheetHost(row:request:columns:idPrefix:open:)` | view init | `ProvenanceSheetHost(content:…)` | Builds content after the read |
| `ConclusionDetailPageSectionsContext.entityId`, `ConclusionDetailRowsSection.entityId` *(new)* | fields | `PersonDetailSections.entityId` (goes) | D-2 |
| `L10n.ProvenanceSheet.recordsLoading`, `.recordsFailedTitle` (replace the citations pair) | keys | the citations pair | Strings |
| `ReconciledValue.PooledSupport` *(new)*, `poolPlaceSupport` *(new, unexported)* in `conclusiondetails`; `ReconciledValueDetail.pooled_support = 6`; `CatalogReconciledValue.pooledSupport` *(new)* | field, func, wire | `recordCounts` (distinct Sources per field) | D-8: the same count, keyed by pooled Place value |
| `TestRenderedCitationsProto` *(new)* | test | `TestRenderCitations` | D-14 |

**Builds on.** S15-21's sheet key, registry arm, host and release; S15-28's `GetProvenanceRecords`, `record_counts`, denial facts, `ownerFieldProto`, `renderedCitationsProto`; S16-24's `followsInputs`; `session.conclusionContent` for content built from a key's value.
**Deletes.** `ReconciledValueDisplay.sourceCount`, `distinctSourceCount`, `deniedSomething`; `pooledValueGroups`' support sum and `counted` set; `ReconciledValueRowModel.provenanceContent()`; `ProvenanceSheetHost`'s `content:` and its key from Citation ids; `PersonDetailSections.entityId`; `CatalogQueryKey.provenanceSheet(project:citationIds:)`; `CatalogProvenanceSheetRead.init(_ reply:)`; `CatalogRenderedCitations`; `GenealogyStore.renderCitations` with its `GoStore`, `FakeStore` (five `renderCitations*` members) and `OnboardingModelTests` implementations; `CoreMethod.renderCitations`; `L10n.ProvenanceSheet.citationsLoading`, `.citationsFailedTitle` and their catalog entries; Go `RenderCitations`, `MethodRenderCitations` and its case, `RenderCitationsRequest`, `RenderCitationsResponse`, `citationrender.Render`; `citation_render_test.go` `renderCitations`, `TestRenderCitations`; `TestDetailPayloadWithoutRecords`. `MaxCitations` and `MaxBatchBytes` stay (`RenderAll` reads both).
**Next adds.** A new row kind on a detail page is a `RecordsSource` case, its request and its count; a new life row kind is one `CatalogDerivedRowKind` case and one wire mapping entry. A second key over a request with cases copies D-3 (STEP-9 writes it into `add-workspace-place`).

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| The sheet opened before its read answers | `PVProvenanceSheet` with `.loading` and `row.provenanceContent(records: [])` | Header from the row (D-5); a new key reads nil at once (`ProvenanceSheetHost`'s comment); T-6 |
| A read answering no owners, or a field the read left out | `PVProvenanceSheetContent` with no groups | Ready table with no rows; the page's refresh closes the sheet (D-9); T-5 |
| A row whose page field has counts and no outcomes | `ReconciledValueRowModel`, the three builders | Counts drive every test (`hasRecords`); T-2, T-3 |
| The page refreshes while the sheet is open | `ConclusionDetailRowsSection` | The host gets the new row; the key changes only when the request does; `onChange(of: key)` releases the old one, as today |

### Scale

At the map's Scale (up to 1,200 records on one value; 30 Sources on a Person page): the detail read stops sending outcomes (S15-28 T-7 measured 34,704 → 2,963 bytes at 30 Sources × 2 records). The sheet's read is S15-28's, 14.8 ms warm at 1,200 records (S15-28 T-8). Swift builds the content once per change of the key's revision or the row (`conclusionContent`), linear in the records now that no record searches its field (D-7). A write the sheet's inputs name reloads one key once. No list or loop grows with the page.

### Edges

- **Assumptions.** Go answers `.fields` owners in request order (S15-28 `FieldRecords`); D-6 matches by `propertyID`, so order does not decide which field is which. `PVProvenanceSheetContent.derived` puts the shown owner first itself (`ownerGroups`). A row's request is stable across a page refresh when its fields are, so the key does not churn. `recordCounts.sources` is 0 for an empty field, and `countLine` already returns nil for `.empty` from its state switch.
- **Neighbors.** A concluded field with no records: no sheet, as today. An Event Date row filters its fields with `hasRecords` before building (`EventDetailContent.dateRow`), so its request names only fields with records. The Place Period row does not filter, so its request names `start_date` and `end_date`; Go leaves out one with no records (D-6). A likeness record (no field): `counted` and `outcomeMark` read `deniedAValue` false, as before (S15-28 Edges).
- **Pool keys.** Go pools by Place and value scalar; Swift lays runs out by the value's text. Two different subjects that read the same on one Place would share a Swift heading and show the first one's count; a Place link's values are Places, which a Place group shares, so no fixture has them (T-15 asserts the key).
- **Removed inputs.** Owner merged or deleted, or records deleted, between page and sheet: D-9. A Citation deleted between records and render: no render, today's line (unchanged).
- **Real data.** None — no table or seed drives these rules.
- **Untrusted size.** None — the request is built by the app from its own page read; Go bounds the reply (S15-28 D-9).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/citationrender` | `Render` goes. `MaxCitations`' comment: "is the batch RenderAll renders at a time." `MaxBatchBytes`' comment: "is the most text one RenderAll call renders: the sum of the plain text of every full and short citation." |

### FFI

`api/proto/engine.proto`: D-12; `RenderCitationsRequest` and `RenderCitationsResponse` go. `ConclusionField.outcomes` gains the comment "Filled only by GetProvenanceRecords; GetConclusionDetail sends record_counts instead." Regenerate with `./scripts/generate-proto.sh` (Go and Swift). Handlers per D-11; `api/ffi/dispatch.go` loses `MethodRenderCitations` and its case; `citation_render.go` loses `RenderCitations` and keeps `renderedCitationsProto` and the preview handlers.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Provenance sheet | `PVProvenanceSheet` (recipe, Ship) | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` | The load area's strings and id prefix `"\(idPrefix).records"`; previews "Records loading" and "Records failed" (message "The records could not be read.") |
| Record area load state | `PVFormLoadArea` (component, Ship) | `macos/App/DesignSystem/Components/FormLoadArea/` | Loading and failed as S15-D9 drew them |
| Sheet content | `PVProvenanceSheetContent` (recipe content, Extend) | `…/ProvenanceSheet/PVProvenanceSheetContent.swift` | Builders below; `withRenders` unchanged |
| Host | `ProvenanceSheetHost` (snowflake, Extend) | `macos/App/Features/Conclusions/ProvenanceSheetHost.swift` | Below |
| Presenter | `ConclusionDetailRowsSection` | `macos/App/Features/Conclusions/ReconciledValueRow.swift` | `if let row = item.row(in: rows), let request = row.provenanceRequest(entityID: entityId)` draws `ProvenanceSheetHost(row: row, request: request, …)` |

The content builders (each keeps `locale:` and `orders:` last, defaulted):

```swift
// summary from `field` (state, against, recordCounts.sources) and `recordCount`; records AND value headings from
// `recordsField` (`valueGroups(records, field: recordsField)`), one snapshot; nil → no groups
init(field: CatalogConclusionField, recordsField: CatalogConclusionField?, recordCount: Int, title: String, shown: Shown, …)
// records from `recordFields` in order; summary "N records" from `recordCount` (nil when 0)
static func spanning(recordFields: [CatalogConclusionField], recordCount: Int, title: String, shown: Shown, …) -> Self
// groups from `owners` (the read's) through `ownerGroups`; summary from `recordCount` and `ownerCount`
static func derived(owners: [CatalogOwnerField], ownerCount: Int, recordCount: Int, shownOwnerID: String?, kind: CatalogDerivedRowKind?, title: String, shown: Shown, …) -> Self
```

The summary rules are today's, over the passed counts: `init(field:…)` joins the state line (`.single` → `stateSingle(sourceCountLine(field.recordCounts.sources))`, else `spokenState(field)`), `againstLine(field)`, and `recordCount(recordCount)` when it is above 0; `derived` says `recordsFromOwners` when `ownerCount > 1` and a kind is set, else `recordCount`, and nil at 0.

The host:

```swift
struct ProvenanceSheetHost: View {
    let row: ReconciledValueRowModel
    let request: CatalogProvenanceRequest
    let columns: PVProvenanceColumns
    let idPrefix: String
    let open: (PVProvenanceSheetContent.Record, PVProvenanceLink) -> Void
    // key = .provenanceSheet(project: session.projectKey, request: request)
    // content: handle?.value → session.conclusionContent(key, inputs: [key], extra: row, value: value) {
    //     value, row in row.provenanceContent(records: value.owners).withRenders(value.citations) }
    //   no value → row.provenanceContent(records: [])
    // load, Read again, .task, .onChange(of: key), .onDisappear: as today
}
```

States: loading — header and headings, "Loading records" (AC-2.4); failed — "Records could not be read" with Read again (AC-2.6); ready with no owners — the headings and no rows (D-9); a reload — the shown table until the reload answers (AC-2.7). Accessibility: the loading caption is spoken as shown; nothing else changes.

### Strings

L10n keys *(new)*: `L10n.ProvenanceSheet.recordsLoading` = "Loading records" (key `provenanceSheet.recordsLoading`, comment "Caption and VoiceOver label of the provenance sheet's record area while its records are being read"); `L10n.ProvenanceSheet.recordsFailedTitle` = "Records could not be read" (key `provenanceSheet.recordsFailedTitle`, comment "Title of the provenance sheet's notice when its records could not be read"). Removed: `provenanceSheet.citationsLoading`, `provenanceSheet.citationsFailedTitle`, from `L10n.swift` and `Localizable.xcstrings`. The area now covers records and citations; the preview message is the only other copy that named the old scope (macOS table).

## 7. Steps

This PR needs the Mac that builds the app: STEP-1 and STEP-8 run `./scripts/generate-proto.sh` (`protoc`, `protoc-gen-go`, `protoc-gen-swift`), and every Swift step runs `xcodebuild test` per `add-swift-test`. Without those tools, stop before STEP-1 and report; never edit generated code by hand. Within a step, the tree builds after each sub-part; the step's tests pass at its end.

**STEP-1 — Go counts each pooled Place value's Sources**
Files: `core/database/conclusiondetails/conclusiondetails.go`, `placerecords_test.go`, `api/proto/engine.proto`, `api/proto/engine/engine.pb.go`, `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/conclusion_detail.go`, `provenance_records_test.go`. Skill: `add-ffi-handler`.
Do: D-8's Go half: `ReconciledValue.PooledSupport`, `poolPlaceSupport`, its call in `ProvenanceSheet`, `pooled_support = 6` with the comment "distinct Sources behind this value across every link to the same Place, on a provenance sheet's life row; 0 elsewhere", `conclusionFieldProto` maps it; regenerate.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/conclusiondetails/ ./api/...` passes with T-15.

**STEP-2 — Wire types and the store read**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `CoreInvoke.swift`; `macos/ProvenenciaTests/CatalogSessionStoreTests.swift`, `OnboardingModelTests.swift`. Skill: `add-swift-test`.
Do: the types, fields, mapping, store method, mappers and fakes in Codebase fit, D-4, D-10, and `CatalogReconciledValue.pooledSupport`. `GoStore.getProvenanceRecords` builds `Provenencia_Engine_V1_GetProvenanceRecordsRequest` (`fields.pairs`, or `derived` with `kind.wire`); `mapDerivedRow` calls `mapOwnerField` for its owners and uses `init?(wire:)` for its kind; `mapConclusionField` sets `recordCounts` and each value's `pooledSupport`, `mapReconcilerOutcome` the two denial fields. Add the doc comment on `CatalogConclusionField.outcomes`: "Empty on a detail page's field; filled on a provenance sheet's read." `renderCitations` stays until STEP-8.
Check: `xcodebuild test` passes with T-1.

**STEP-3 — Rows count from the engine**
Files: `ReconciledValueRowModel.swift`, `ReconciledValueDisplay.swift`, `PVProvenanceSheetContent.swift` (the `.single` summary only), `PersonDetailContent.swift`, `EventDetailContent.swift`, `PlaceDetailContent.swift`; `ReconciledValueDisplayTests.swift`, `ProvenanceSheetTests.swift`, `PersonDetailTests.swift`, `EventDetailTests.swift`, `PlaceDetailTests.swift`.
Do: `recordCount` sums `recordCounts.records` per `RecordsSource` case; `countLine`, `spokenState` and `init(field:…)`'s `.single` summary read `field.recordCounts.sources`; the builders test `field.hasRecords`; `sourceCount` goes. The fixture `ReconciledValueDisplayTests.field` gains `counts: CatalogFieldRecordCounts = .init()`; page-field fixtures pass counts and no outcomes. A test that asserts a count line, a spoken state, a summary or a row's presence passes the counts the engine would send for its fixture: `records` = its records, `sources` = the Source count its assertion reads (`mergedName` passes {4, 2}).
Check: `xcodebuild test` passes with T-2, T-3; `rg -n 'ReconciledValueDisplay\.sourceCount\(|func sourceCount\(' macos` finds nothing.

**STEP-4 — Records worded from the engine's facts**
Files: `ReconciledValueDisplay.swift`, `PVProvenanceSheetContent.swift` (`Record.init`, `pooledValueGroups`); `ReconciledValueDisplayTests.swift`, `ProvenanceSheetTests.swift`.
Do: D-7; D-8's Swift half; `deniedSomething` and `distinctSourceCount` go. The fixture `ReconciledValueDisplayTests.outcome` gains `deniedAValue:` and `deniedBySourceTitle:` (defaults false, ""); `ReconciledValueDisplayTests.value` gains `pooledSupport:` (default 0).
Check: `xcodebuild test` passes with T-4; `rg -n 'deniedSomething|distinctSourceCount' macos` finds nothing.

**STEP-5 — The load area names records**
Files: `PVProvenanceSheet.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`; `ProvenanceSheetTests.swift`. Skill: `add-localized-string`.
Do: Strings; the macOS table's Provenance sheet row.
Check: `xcodebuild test` passes with T-8; `rg -n 'citationsLoading|citationsFailedTitle|citations could not|Loading citations' macos/App` finds nothing.

**STEP-6 — The sheet reads its row's records when it opens**
Files: `CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `ReconciledValueRowModel.swift`, `PVProvenanceSheetContent.swift`, `ProvenanceSheetHost.swift`, `ReconciledValueRow.swift`, `ConclusionDetailPage.swift`, `PersonDetailView.swift`; `CatalogQueryRegistryTests.swift`, `WorkspaceSessionTests.swift`, `ProvenanceSheetTests.swift`, `PersonDetailTests.swift`, `EventDetailTests.swift`, `PlaceDetailTests.swift`, `ConclusionAnchorRestoreTests.swift` (passes `entityId: "e1"`). Skills: `add-workspace-place`, `add-ui-component`.
These swap together: the old key's ids come from the content's records, and the new content needs the new key's value. Work them in this order:
1. Content: `ownerGroups` and the three builders (§6 macOS); `derived` groups through `ownerGroups`; the field builder's headings come from `recordsField`.
2. Row: `provenanceRequest(entityID:)` (D-1) and `provenanceContent(records:)` (D-5, D-6); `provenanceContent()` goes.
3. Key and registry: D-3; the `.provenanceSheet` loader returns `try await store.getProvenanceRecords(projectDir: key.project.projectDir, request: key.provenanceRequest)`; D-15.
4. Host, presenter and context: D-2; §6 macOS.
5. Comments: `RecordsSource` ("What the row's records are read with: the sheet asks for them by `provenanceRequest(entityID:)` when it opens."); the `PVProvenanceSheetContent` type doc (its first sentence ends "built from a row's header and the records its sheet read"); `ProvenanceSheetHost`'s doc ("A provenance sheet with its records: it holds the sheet's one cached read, its row's records with their citations, while the sheet is shown."); the `.provenanceSheet` arm's comment ("A provenance sheet's records and their citations, held only while the sheet is shown; a write that reaches its Sources, graphs or handles while it is open reloads it.").
Each test that called `provenanceContent()` calls `provenanceContent(records:)` with the owners its sheet's read would answer (`CatalogOwnerField(entity:, field:)` for a field row, its field carrying the outcomes).
Check: `xcodebuild test` passes with T-5, T-6, T-7; `rg -n 'provenanceContent\(\)|citationIds:' macos` finds nothing.

**STEP-7 — The detail read sends no records**
Files: `api/ffi/handlers/conclusion_detail.go`, `provenance_records.go`, `conclusion_detail_test.go`, `provenance_records_test.go`. Skill: `add-ffi-handler`.
Do: D-11.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes with T-9, T-10, T-11, T-12.

**STEP-8 — `RenderCitations` goes**
Files: `api/proto/engine.proto`, `api/proto/engine/engine.pb.go`, `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/citation_render.go`, `citation_render_test.go`, `api/ffi/dispatch.go`, `provenance_records_test.go`, `core/database/citationrender/render.go`, `render_test.go`, `scale_test.go`; `GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `CoreInvoke.swift`, `CatalogSessionStoreTests.swift`, `OnboardingModelTests.swift`.
Do: D-12, D-13, D-14; §6 FFI and Go core; the comment blocks above the two deleted messages go with them; every `Render` call in tests becomes `RenderAll`; `TestGetProvenanceRecordsWarmReadsNoRecordSQL` compares with a warm `RenderAll`; the Swift `renderCitations` method, `CatalogRenderedCitations`, `CoreMethod.renderCitations`, the five fakes and the stub go.
Check: `go build ./...`; `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/ ./api/...` passes with T-13, T-14; `xcodebuild test` passes; the DoD sweep holds.

**STEP-9 — Docs, skills and version**
Files: `docs/macos-client-patterns.md`, `docs/design-system-layers.md`, `.agents/skills/add-ui-component/SKILL.md`, `.agents/skills/add-workspace-place/SKILL.md`, `docs/citation-formats.md`, `docs/deployment-plan/spike-15/provenance-loading.md`, `../completed.md`, `../deployment-plan.md`, this plan; `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do:
- `macos-client-patterns.md` "One detail key for every kind": the detail carries each field's state, values and `record_counts`, not its records, and for a Person its life rows' owners with their counts; a provenance sheet reads its row's records with `GetProvenanceRecords` under the `provenanceSheet` key while it is shown.
- `design-system-layers.md` §2 and `add-ui-component` step 3: "built when the recipe opens" becomes "built when the recipe opens, or when the read it waits on answers (`PVProvenanceSheetContent`: its header from the row, its records from the sheet's read)".
- `add-workspace-place` after line 102: "A key over a request with cases puts a tag first in `ids` and reads it back through one accessor preconditioned on its kind (`provenanceSheet`, `provenanceRequest`): one kind, one arm."
- `citation-formats.md` line 70: "`citationrender.RenderAll` (behind `GetProvenanceRecords`), `RenderCitationPreview` and `ListCitationPlaceholders` (package `core/database/citationrender`) turn the formats into text;" with the rest of the sentence as it is. Line 76's paragraph: "**The batch.** `RenderAll` takes any number of Citation ids and returns, for each Citation found, the full and the short citation as styled runs and plain text, in input order, a repeated id once, an id with no Citation left out. It renders 2,000 ids at a time within one 8 MiB budget for the whole call; a batch that would pass the budget is left out, so its records show the app's own line. A Citation whose type has no full (short) format, or whose format does not parse, or whose graph, Source or type row is missing, comes back with an empty full (short). The reply's `inputs` name the Evidence graphs and Sources it read. A call reads a fixed number of queries per 500 ids."
- `provenance-loading.md`: D-16.
- Version bump per the header; the rest per the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log`. No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `CatalogSessionStoreTests.swift` `provenanceRecordsAnswersTheAskedRequest` *(new)* | a reply set for `.fields([(P, p-name)])` → that reply, one call recorded with the request; an unlisted request → no owners, no citations | AC-2.1 |
| T-2 | Swift | `ReconciledValueDisplayTests.swift` `countLineCountsSourcesNotRecords` (rewritten), `spokenStateReadsTheCounts` *(new)* | merged with counts {4, 2} → "2 Sources", spoken "merged from 2 Sources"; mixed {5, 3} → "3 Sources"; empty → nil; concluded → "by you" | AC-1.1, AC-1.2 |
| T-3 | Swift | `PersonDetailTests.swift` `aFieldShowsOnceARecordSpeaksToIt` *(new)*; `EventDetailTests.swift` `theDateRowSkipsAPropertyWithNoRecords` *(new)*; `PlaceDetailTests.swift` `namesRowIsEmptyWithNoRecords` *(new)*; `ProvenanceSheetTests.swift` `aRowCountsFromTheEngine` *(replaces `aRowBuildsItsContentOnCall`)* | sex at birth with records 0 → no row, 1 → a row, with no outcomes; Event date with records 0 on `start_date` → row from the next Property; toponym records 0 → empty row; a life row with owners {3, 1} → `recordCount` 4, `hasRecords`; `.empty` → 0 | AC-1.3, AC-1.4, AC-1.5 |
| T-4 | Swift | `ReconciledValueDisplayTests.swift` `aNegativeReadsFromItsDenialFact` *(new)*, `aDeniedRecordNamesItsDenier` *(new)*; `ProvenanceSheetTests.swift` `aPooledPlaceGroupHasOneHeadingPerValue` (rewritten) | negative with `deniedAValue` true → "kept", `.check`, counted; false → "disagrees · did not eliminate", `.circleMinus`, not counted; denied with title "Court deposition, 1862" → "denied by Court deposition, 1862"; "" → "denied"; two York links whose value has `pooledSupport` 2 → one heading "2 Sources" over both links' records; with `pooledSupport` 1 → "1 Source" | AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, D-7, D-8 |
| T-5 | Swift | `ProvenanceSheetTests.swift` `aRowAsksForItsOwnRecords` *(new)*, `contentTakesRecordsFromTheRead` *(new)*, `theSummarySaysOnlyWhatTheRowKnows` (rewritten over counts) | field row → `.fields([(P, p-name)])`; Period row over `start_date`, `end_date` → both pairs in that order; birth place → `.derived(P, .birthPlace)`; Event place row (no kind) → nil; `.empty` → nil. `records: []` → no groups, summary "merged from 3 Sources · 1 record disagrees · 4 records" from counts {4, 3}; the read's name field → its 4 records; a Period whose read lacks `end_date` → `start_date`'s records only; derived summary "4 records from 2 birth events" from page owners {3, 1}; derived with the read's owners → groups from them, shown owner first; two read owners on one Place → one group | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, D-1, D-5, D-6, D-9 |
| T-6 | Swift | `WorkspaceSessionTests.swift` `ProvenanceSheetSessionTests.hostReadsTheRowsRecordsOnTask` *(replaces `hostReadsTheSessionAndRendersOnTask`)* | a hosted `ProvenanceSheetHost` for a name row of entity `P` → one `getProvenanceRecords` call with `.fields([(P, p-name)])`; the handle's value holds the fake's owners and citations | AC-2.1, AC-2.5 |
| T-7 | Swift | `CatalogQueryRegistryTests.swift` `provenanceSheetKeyKeepsOrderAndFollowsInputs` *(replaces `provenanceSheetKeySortsAndFollowsInputs`)*; `WorkspaceSessionTests.swift` `releaseDropsTheKey`, `releaseDuringALoadNeverLandsOnTheNewHandle`, `provenanceSheetLoadStates`, `provenanceSheetReadAgainAfterFailure` (on the `provenanceRecords*` fakes) | pairs (b, x), (a, y), (b, x) → ids `["fields", "b", "x", "a", "y"]`, and `provenanceRequest` reads them back; `.derived(P, .deathPlace)` → `["life", "P", "death_place"]` and back; a write naming a reported Source reloads once; release, load states and Read again as before | AC-2.6, AC-2.7, AC-2.8, D-3, D-4 |
| T-8 | Swift | `ProvenanceSheetTests.swift` `theLoadAreaNamesRecords` *(new)* | `L10n.string(L10n.ProvenanceSheet.recordsLoading)` == "Loading records"; `.recordsFailedTitle` == "Records could not be read" | AC-2.4, AC-2.6 |
| T-9 | Go | `conclusion_detail_test.go` `TestGetConclusionDetail` (changed) | the name field: no outcomes, `record_counts` {2, 1}; then `rpc(t, GetProvenanceRecords, …)` with the pair (entity id, name `property_id`) and `wantInputs` on the detail with the graphs and Sources of that answer's outcomes | AC-4.1, AC-4.3, D-11 |
| T-10 | Go | `conclusion_detail_test.go` `TestGetConclusionDetailCarriesDerivedRows`, `TestGetConclusionDetailWarmReadsNoRecordSQL` (changed) | the owner field: no outcomes, records 2; the warm read's name field has records > 0 | AC-4.2 |
| T-11 | Go | `conclusion_detail_test.go` `TestReconcilerOutcomeProtoCarriesVoteAndArtifact` *(replaces `TestConclusionDetailProtoCarriesVoteArtifactAndMembers`)* | `reconcilerOutcomeProto` carries the outcome's vote, Artifact, labels, page and group rank; `conclusionDetailProto` of a field with that outcome carries the member count and no outcome | D-11 |
| T-12 | Go | `provenance_records_test.go` `TestDetailCarriesNoRecords` *(replaces `TestDetailPayloadWithoutRecords`)* | `researchedPerson(t, 30, 2)`: every field and derived owner of `GetConclusionDetail` has no outcomes; log the payload's bytes | AC-4.1 |
| T-13 | Go | `core/database/citationrender/render_test.go`, `core/database/citationrender/scale_test.go`: every `Render` call becomes `RenderAll`; `TestRenderLimits` per D-13 | the cases' results unchanged (no ids → nil; a 15-byte id → `citations.ErrInvalid`); 70 big → none, no error; 60 → 60; `TestRenderScale`'s SELECT counts unchanged | D-13 |
| T-14 | Go | `citation_render_test.go` `TestRenderedCitationsProto` *(new)* | `citationformat.Render(citationformat.Parse("*Ancestry*, {source.title}", …), resolver)` with a resolver as `core/citationformat/render_test.go` builds one, as full and the plain format `{source.title}` as short → the wire's runs with the italic run marked and the plain text of both | D-14 |
| T-15 | Go | `placerecords_test.go` `TestPoolPlaceSupport` *(new)*, table over hand-built `OwnerField`s through an `export_test.go` `PoolPlaceSupport` | two York links, kept records from s1 and s2 → `PooledSupport` 2 on both; from s1 and s1 → 1; a Leeds link with s3 → 1; a value not displayed → 0; date owners (no `Place`) → 0; two values with different scalars on one Place → counted apart; `GetProvenanceRecords` on S16-80's fixture (birth place) → each owner's displayed value carries it, and the detail read's values carry 0 | AC-4.5, D-8 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `ProvenanceSheetTests`, `PersonDetailTests`, `EventDetailTests`, `PlaceDetailTests` (fixtures without counts hide their rows from STEP-2 on), `TestGetProvenanceRecords`, `TestRenderScale`, any `runRPC` case with `exact: true` over a `ConclusionDetail`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; the two citations keys are gone from both
- [ ] Sweep (AC-4.4): rg -n 'provenanceContent\(\)|deniedSomething|distinctSourceCount|renderCitations|RenderCitations|citationrender\.Render\b|citationsLoading|citationsFailedTitle|CatalogRenderedCitations' .agents .cursor/rules docs/*.md macos/App macos/ProvenenciaTests api core finds only generated code and the reserved line; scripts/check-guidance-names.py passes (check-pr runs it)
- [ ] UI matches §6 macOS; no new kit primitive
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped, with T-12's payload bytes
- [ ] Docs and skills per STEP-9
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with a Person cited by several Sources, with a merged name and a birth date read off two Events (the dogfood catalog's James Robins, or any Person with a mixed birth date). Each Vitals row reads the counts it read before this PR.
2. Open the name row's provenance sheet. The title, value, badge and summary draw at once; "Loading records" shows under the headings until the table draws; the summary does not change.
3. Open the birth date row's sheet: two owner lines, the shown Event's first; Read as, Citation, Outcome and Record as before.
4. With a sheet open, rename a cited Source in another window: the sheet's citations update in place with no loading state.
5. Open an Event's Date row and a Place's Names and Period row sheets: their records as before.
6. Check each sheet at Regular and Wide: unchanged apart from the loading caption.
7. AC-4.4: run the DoD's sweep and see no hit beyond those it names.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The header and table disagree after a write moves counts before the sheet's reload answers | Both keys follow the same inputs and reload on the same write; the header reads the page's counts (D-5) |
| Fixtures in five test files build page fields with outcomes and no counts, hiding rows | STEP-3 gives the fixture `counts:`; the failing tests show where |
| The key churns on every page refresh | The request depends only on the row's fields' ids and the entity (D-1, D-3); T-7 |

**Stop and report if:**

- `xcodebuild`, `protoc`, `protoc-gen-go` or `protoc-gen-swift` is not available where you work: stop before STEP-1.
- After a merge or a records delete, the sheet stays open past the page's refresh (D-9 does not hold): report the steps.
- A page builder needs a record, not a count, to decide a row (a fourth `field.outcomes` reader outside the sheet).
- `TestRenderScale`'s SELECT counts or budget change once it calls `RenderAll`.
- Removing outcomes from the detail changes its reported `inputs` (T-9).

## 12. Open questions

None.

## 13. PR

**Title:** S15-29 — The provenance sheet loads its records when it opens
**Body:** objective in one sentence; what shipped against each US; AC evidence; T-12's payload bytes; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-29-records-load-when-the-sheet-opens.md`.
