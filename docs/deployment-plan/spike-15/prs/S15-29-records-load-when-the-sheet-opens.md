# S15-29 — The provenance sheet loads its records when it opens

**Status:** Draft
**Spike / slice:** Spike 15 · Slice 8 — Provenance loading
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no new chrome: the record area keeps S15-D9's load area, and only its two strings change; S15-D18 descoped, user, 2026-11-28)
**Board:** —
**Depends on:** S15-21 (landed [#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930)), S15-28 (landed [#1016](https://github.com/Jake-Robins-Studios/provenencia/pull/1016)), S15-31 (landed [#1010](https://github.com/Jake-Robins-Studios/provenencia/pull/1010)), S16-09 (landed [#780](https://github.com/Jake-Robins-Studios/provenencia/pull/780))
**Blocks:** —
**Branch:** `s15-29-records-load-when-the-sheet-opens`
**Version bump:** minor, 0.51.0 → **0.52.0** (if `main`'s `VERSION` has moved, the next minor after it): the sheet's records move to a read on open, and an RPC only this build called goes ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (the key and registry arm), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** working rules "Records load when the sheet opens", "Citations render on demand, from SQL", "Today's line stays the fallback, in Swift" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); [`S15-28`](S15-28-records-load-on-their-own.md) (the read this PR calls, its D-5, D-6, D-8); [`macos-client-patterns.md`](../../../macos-client-patterns.md) "One detail key for every kind"
**Planned:** 2026-11-28 against `main` @ `82112d4`
**Review:** — (not reviewed yet)

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

## 1. Objective

A detail page no longer carries every record behind its values. Person, Event and Place rows show their Source and record counts from the engine's `FieldRecordCounts`. When a row's provenance sheet opens, it reads that row's records and their citations in one call (`GetProvenanceRecords`, S15-28). The sheet draws its header at once from the row and shows the kit's load area until the records arrive. Swift stops counting records and searching for deniers. Then the detail read stops sending outcomes, and the old citation-only read (`RenderCitations`) goes.

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
| AC-2.2 | An Event date row spanning `start_date` and `end_date` of Event `E` | Request `.fields([(E, start_date), (E, end_date)])`, in the row's field order |
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
| AC-4.4 | `rg -n "RenderCitations\|renderCitations\|citationrender\.Render\b" api core macos/App macos/ProvenenciaTests docs/*.md` | No hit outside generated code's reserved name and `METHOD_RENDER_CITATIONS`'s `reserved` line |

## 3. Scope

| In | Covered by |
| --- | --- |
| Swift types for the counts, the denial facts, the sheet request and its reply; the store method | STEP-1; AC-2.1 – AC-2.3 |
| Row counts and record test from `FieldRecordCounts`; Person, Event and Place builders filter on counts | STEP-2; US-1 |
| Wording from `denied_a_value` and `denied_by_source_title`; the pooled heading counts its records' Sources | STEP-3; US-3 |
| The sheet's key by request, its loader over `getProvenanceRecords`, its value holding owners and citations | STEP-4; AC-2.1 – AC-2.3, AC-2.7, AC-2.8 |
| The sheet's content built from the read; its header from the row; the host and presenter | STEP-4; AC-2.4, AC-2.5 |
| The load area's two strings | STEP-4; AC-2.4, AC-2.6 |
| Go: the detail read sends no outcomes | STEP-5; AC-4.1 – AC-4.3 |
| `RenderCitations` and `citationrender.Render` go | STEP-6; AC-4.4 |
| Docs the change makes false; `provenance-loading.md` retired | STEP-7 |

| Out | Home |
| --- | --- |
| An empty state for a sheet whose read answers no owners (owner merged or deleted since the page read): the page's refresh closes the sheet (D-9) | not planned (user, 2026-11-28) |
| A notice when a reload behind shown records fails | not planned (user, 2026-11-28) |
| `PictureDetail.record` and the Gallery's records | not planned: the Gallery and viewer read one record per picture |
| Rendering a likeness viewer row's citation | not planned |
| Converting the sheet's key to S16-25's value keys | S16-25 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Wire types | `macos/App/Platform/GenealogyStore.swift` `CatalogConclusionField`, `CatalogReconcilerOutcome`, `CatalogOwnerField`, `CatalogDerivedRowKind`, `CatalogRenderedCitations`, `CatalogProvenanceSheetRead` (`init(_ reply: CatalogRenderedCitations)`), protocol `renderCitations(projectDir:citationIDs:)` | No counts, no denial facts; the sheet's value holds renders only |
| Go store | `macos/App/Platform/GoStore.swift` `mapConclusionField`, `mapReconcilerOutcome`, `mapDerivedRow` (owner mapping inline), `renderCitations` (render mapping inline); `macos/App/Platform/CoreInvoke.swift` `CoreMethod.renderCitations` | Drops `record_counts` and the two denial fields; no call for `GetProvenanceRecords` |
| Fake store | `macos/App/Platform/FakeStore.swift` `renderCitationsReplies`, `renderCitationsInputs`, `renderCitationsHold`, `renderCitationsCalls`, `renderCitationsError`, `renderCitations` | — |
| Counts and wording | `macos/App/Platform/ReconciledValueDisplay.swift` `sourceCount`, `distinctSourceCount`, `countLine`, `spokenState`, `counted`, `deniedSomething`, `outcomePhrase` (`.denied`, `.against`), `outcomeMark` | Count Sources and search deniers over `field.outcomes` |
| Row model | `macos/App/Features/Conclusions/ReconciledValueRowModel.swift` `RecordsSource`, `recordCount`, `hasRecords`, `provenanceContent()` | `recordCount` counts outcomes; the sheet's content is built from the page's fields |
| Page builders | `macos/App/Features/Conclusions/PersonDetailContent.swift` `rows` (`!field.outcomes.isEmpty`), `EventDetailContent.swift` `dateRow` (`!$0.outcomes.isEmpty`), `PlaceDetailContent.swift` `namesRow` (`!field.outcomes.isEmpty`) | Filter on outcomes the page will no longer carry |
| Sheet content | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` `init(field:title:shown:)`, `spanning`, `derived`, `pooledValueGroups`, `records`, `withRenders` | Summary counts the records it builds; `pooledValueGroups` calls `distinctSourceCount` |
| Sheet recipe | `…/ProvenanceSheet/PVProvenanceSheet.swift` `PVFormLoadArea(loadingText: L10n.ProvenanceSheet.citationsLoading, errorTitle: L10n.ProvenanceSheet.citationsFailedTitle, …, accessibilityIdentifierPrefix: "\(idPrefix).citations")` | Copy names citations |
| Host and presenter | `macos/App/Features/Conclusions/ProvenanceSheetHost.swift` (`content:`; key from `content.records`' Citation ids); `ReconciledValueRow.swift` `ConclusionDetailRowsSection` (`ProvenanceSheetHost(content: row.provenanceContent(), …)`); `ConclusionDetailPage.swift` `ConclusionDetailPageSectionsContext`, `ConclusionDetailDefaultPageSections`; `PersonDetailView.swift` `PersonDetailSections` | The section knows no entity id |
| Key and registry | `macos/App/Features/Workspace/Session/CatalogQueryKey.swift` `provenanceSheet(project:citationIds:)`; `CatalogQueryRegistry.swift` arms `.provenanceSheet` (calls `renderCitations`) and `.conclusionDetail` (comment: a rename "reaches the provenance sheet, the Gallery captions and the viewer's record row") | — |
| Strings | `macos/App/Platform/L10n.swift` `L10n.ProvenanceSheet.citationsLoading`, `.citationsFailedTitle`; `macos/App/Resources/Localizable.xcstrings` keys `provenanceSheet.citationsLoading`, `provenanceSheet.citationsFailedTitle` | — |
| Go detail mapping | `api/ffi/handlers/conclusion_detail.go` `conclusionFieldProto` (maps outcomes), `ownerFieldProto`, `derivedRowsProto`; `provenance_records.go` `GetProvenanceRecords` (calls `ownerFieldProto`) | One field mapper for the detail and the sheet |
| Go render | `api/ffi/handlers/citation_render.go` `RenderCitations`, `renderedCitationsProto`; `api/ffi/dispatch.go` `MethodRenderCitations`; `core/database/citationrender/render.go` `Render`, the `MaxCitations` and `MaxBatchBytes` comments; `api/proto/engine.proto` `METHOD_RENDER_CITATIONS = 124`, `RenderCitationsRequest`, `RenderCitationsResponse`, `ConclusionField.outcomes` | `Render`'s only non-test caller is `RenderCitations` |
| Go tests | `api/ffi/handlers/conclusion_detail_test.go` `TestGetConclusionDetail`, `TestConclusionDetailProtoCarriesVoteArtifactAndMembers`, `TestGetConclusionDetailWarmReadsNoRecordSQL`, `TestGetConclusionDetailCarriesDerivedRows`; `provenance_records_test.go` `TestDetailPayloadWithoutRecords`, `TestGetProvenanceRecordsWarmReadsNoRecordSQL` (compares with `citationrender.Render`); `citation_render_test.go` `renderCitations`, `TestRenderCitations`; `core/database/citationrender/render_test.go` (calls `Render` at lines 200, 528, 543, 553), `TestRenderLimits`; `scale_test.go` `TestRenderScale` (calls `Render`) | Assert outcomes on the detail, or call what goes |
| Swift tests | `macos/ProvenenciaTests/ReconciledValueDisplayTests.swift` (`field`, `mergedName`, the count and denial tests); `ProvenanceSheetTests.swift` (`aRowBuildsItsContentOnCall`, `theSummarySaysOnlyWhatTheRowKnows`, `aPooledPlaceGroupHasOneHeadingPerValue`, `twoLinksToOnePlaceFormOneGroup`, `withRendersSetsEachRecordsRender`); `PersonDetailTests.swift`, `EventDetailTests.swift`, `PlaceDetailTests.swift` (call `provenanceContent()`); `WorkspaceSessionTests.swift` `ProvenanceSheetSessionTests`; `CatalogQueryRegistryTests.swift` `provenanceSheetKeySortsAndFollowsInputs`; `CatalogSessionStoreTests.swift` `renderCitationsAnswersTheAskedIds`; `OnboardingModelTests.swift` (stub `renderCitations`) | Build records by hand on the page's fields |
| Docs | `docs/macos-client-patterns.md` "One detail key for every kind" (says the detail carries every outcome); `docs/design-system-layers.md` §2 Recipes and `.agents/skills/add-ui-component/SKILL.md` step 3 ("built when the recipe opens"); `docs/citation-formats.md` (lines 70 and 76 name `RenderCitations`); `docs/deployment-plan/spike-15/provenance-loading.md` and the links to it | — |

**Precedent.** S15-21 ([#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930)) is the sheet's key, registry arm, host, `FakeStore` fakes and session tests; this PR changes what they carry, not their shape. `citationsByArtifact` in `CatalogQueryKey.swift` is the precedent for a key whose ids have positions read by named accessors. S15-28 ([#1016](https://github.com/Jake-Robins-Studios/provenencia/pull/1016)) pulled `ownerFieldProto` and `renderedCitationsProto` out so both handlers map one way; this PR splits the field mapper the same way.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | A row's request is built from the page's entity id: `.field` → one pair (entity, field), `.spanning` → one pair per field in the row's order, `.derived` with a kind → (entity, kind); a `.derived` row with no kind, or a row with no records, has no request | Every row's records belong to the page's entity, or to the Person for a life row; the row model needs no new id | An owner id on every row model — every builder and test changes for an id the page already has |
| D-2 | The page's entity id reaches the presenter through `ConclusionDetailPageSectionsContext.entityId` *(new)* and `ConclusionDetailRowsSection.entityId` *(new)* | `ConclusionDetailPage` holds `entityId`; the context is how sections learn the page | Reading it from the session's location — couples the section to navigation |
| D-3 | The key's ids start with a tag: `["fields", owner₁, property₁, …]` or `["life", person, kind.rawValue]`; `CatalogQueryKey.provenanceRequest` *(new)* reads them back. Pairs keep the row's order, repeats removed (first kept) | Keys are kind, project and ids (S16-25 keeps that shape); the order sets the records' order (S15-28 `FieldRecords` answers in request order); a tag keeps one pair from colliding with a life row | A second key kind for life rows — two registry arms for one read |
| D-4 | The sheet's header (title, shown value, summary) comes from the row's page fields; its groups from the read's owners. The summary counts with `FieldRecordCounts`: a field's `records`; a span's sum; a life row's sum over its owners, and its owner count over distinct owner ids (Places pooled), as today | The header draws in every load state and does not jump when the read answers; the counts are Go's (rule "Records load when the sheet opens") | Building the header from the read — a blank header while loading |
| D-5 | For `.field` and `.spanning`, a read owner's field is matched to the row's field by `propertyID`; a field the read left out contributes no records. For `.derived`, the read's owners replace the page's, with the row's `shownOwnerID` and `kind` | Go leaves out a pair with no records (S15-28 D-8); the read is newer than the page | Matching by position — breaks when Go leaves one out |
| D-6 | `ReconciledValueDisplay.counted` and `outcomeMark` lose their `in field:` parameter and read `outcome.deniedAValue`; `outcomePhrase` `.against` reads it too; `.denied` reads `deniedBySourceTitle` ("" → the plain phrase). `outcomePhrase` keeps `in field:` for "folded into" | S15-28 D-6 states Go's rule; the field is still needed for the folded value's text | Keeping the parameter unused — callers pass a field that means nothing |
| D-7 | A pooled heading's Source count is the distinct `sourceID`s of the records in its run; the `outcomes` member of the run tuple goes | The sheet holds those records; the summed-support fallback can never apply to a run that has records | Asking Go for a per-heading count — no read groups by pooled value |
| D-8 | The loading caption is "Loading records" and the failed title "Records could not be read"; the load area's id prefix becomes `<prefix>.records` | The area waits on records now; no test or UI test reads the old id (`rg "\.citations\"" macos`) | — |
| D-9 | A read that answers no owners draws the ready table with no rows. Nothing else is added: the same write moves the page's key, its refresh drops the row's records or the page, and `ConclusionDetailRowsSection`'s `onChange(of: rows)` closes the sheet (user, 2026-11-28) | An extreme edge case; rely on what exists | An empty state with its own copy — S15-28's UX note; declined by the user |
| D-10 | `conclusionFieldProto` maps a field without outcomes; `conclusionFieldRecordsProto` *(new)* adds them. `ownerFieldProto` takes the field mapper as a parameter: `derivedRowsProto` passes `conclusionFieldProto`, `GetProvenanceRecords` passes `conclusionFieldRecordsProto`. Go core still composes every outcome on the detail read | Counts, state and the read's inputs come from the composed outcomes; only the wire changes | A `withRecords bool` on every mapper — a flag at each call; clearing in core — counts would be wrong |
| D-11 | `RenderCitations` goes: its handler function, dispatch case, `CoreMethod`, store methods, fakes and tests; `METHOD_RENDER_CITATIONS` becomes `reserved 124; reserved "METHOD_RENDER_CITATIONS";` and the two messages are deleted. `citationrender.Render` goes; its tests call `RenderAll` | Its last caller is the old sheet key; `reserved` is the file's convention for removed methods | Keeping `Render` for tests — dead public API |
| D-12 | `TestRenderLimits`' id cap case goes (`RenderAll` has none); its byte cases become `RenderAll`'s: 70 big Citations → none rendered and no error, 60 → 60 | `RenderAll` leaves an over-budget batch out (S15-28 D-9) | — |
| D-13 | `renderedCitationsProto` stays in `citation_render.go` with the preview handlers; `TestRenderedCitationsProto` *(new)* holds the wire mapping `TestRenderCitations`' first case held | The rendering rules are core's tests (`TestRenderNearestLevel`, `TestRenderUnknownAndSupplied`); only the mapping is the handler's | Porting every `TestRenderCitations` case into `TestGetProvenanceRecords` — each needs a promoted Subject for a pair |
| D-14 | The `.conclusionDetail` arm's comment reads: "A rename, a credibility change or a Citation or Artifact label fix reaches the counts and states, the Gallery captions and the viewer's record row through the Sources and graphs its records cite." Its follows do not change | The detail still reports the graphs and Sources of its records (D-10), and the counts and the Gallery depend on them | Dropping the Source follow — a credibility change would leave counts stale |

**Rules this plan bends.** None. The S15-28 ship log's UX note (an empty state after a merge) is declined by the user (D-9); the map's S15-29 scope entry is updated in the planning commit.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `CatalogFieldRecordCounts { records, sources: Int }` *(new)*, `CatalogConclusionField.recordCounts` (default `.init()`), `CatalogConclusionField.hasRecords` *(new)*: `recordCounts.records > 0` | type, field | `CatalogReconciledValue.support` | Mirrors `engine.FieldRecordCounts`; `hasRecords` is the one test the three page builders share |
| `CatalogReconcilerOutcome.deniedAValue: Bool = false`, `.deniedBySourceTitle: String = ""` *(new)* | fields | `deniedByObservationID` | Beside it, as on the wire |
| `CatalogProvenancePair { ownerID, propertyID }`, `CatalogProvenanceRequest { case fields([CatalogProvenancePair]); case derived(personID: String, kind: CatalogDerivedRowKind) }` *(new, `Sendable, Hashable`)*; `CatalogDerivedRowKind` gains `String` raw values `birthDate`, `birthPlace`, `deathDate`, `deathPlace` | types | `Provenencia_Engine_V1_GetProvenanceRecordsRequest` | The app's own value of the wire's `oneof row` |
| `CatalogProvenanceRecords { owners: [CatalogOwnerField]; citations: [CatalogRenderedCitation]; inputs }` *(new)* replaces `CatalogRenderedCitations` | type | `CatalogRenderedCitations` | Same reply, now with owners |
| `CatalogProvenanceSheetRead.owners` *(new)*; `init(_ reply: CatalogProvenanceRecords)` | field | `CatalogProvenanceSheetRead` | Grows as S15-21 D-2 planned, no rename |
| `GenealogyStore.getProvenanceRecords(projectDir:request:)` *(new)*; `CoreMethod.getProvenanceRecords` *(new)* | store method | `renderCitations` | Replaces it |
| `GoStore.mapOwnerField`, `GoStore.mapRenderedCitation` *(new, private static)* | func | the inline loops in `mapDerivedRow` and `renderCitations` | Two readers map one way |
| `FakeStore.provenanceRecordsReplies: [CatalogProvenanceRequest: CatalogProvenanceRecords]`, `provenanceRecordsHold`, `provenanceRecordsCalls: [CatalogProvenanceRequest]`, `provenanceRecordsError` *(new)* | fakes | the `renderCitations*` fakes | Renamed for the new read; an unlisted request answers an empty reply with `.init()` inputs |
| `CatalogQueryKey.provenanceSheet(project:request:)`, `CatalogQueryKey.provenanceRequest` *(new)* | factory, accessor | `provenanceSheet(project:citationIds:)`, `citationGraphId` | D-3 |
| `ReconciledValueRowModel.provenanceRequest(entityID:)` *(new)*, `provenanceContent(records:)` (replaces `provenanceContent()`) | funcs | `provenanceContent()` | D-1, D-4, D-5 |
| `ProvenanceSheetHost(row:entityID:request:columns:idPrefix:open:)` | view init | `ProvenanceSheetHost(content:…)` | Builds content after the read |
| `ConclusionDetailPageSectionsContext.entityId`, `ConclusionDetailRowsSection.entityId` *(new)* | fields | `PersonDetailSections.entityId` | D-2 |
| `L10n.ProvenanceSheet.recordsLoading`, `.recordsFailedTitle` (replace the citations pair) | keys | the citations pair | D-8 |
| `conclusionFieldRecordsProto` *(new)* in `conclusion_detail.go` | func | `conclusionFieldProto` | D-10 |
| `TestRenderedCitationsProto` *(new)* | test | `TestRenderCitations` | D-13 |

**Builds on.** S15-21's sheet key, registry arm, host and release; S15-28's `GetProvenanceRecords`, `record_counts`, denial facts, `ownerFieldProto`, `renderedCitationsProto`; S16-24's `followsInputs`; `session.conclusionContent` for the content built from a key's value.
**Deletes.** `ReconciledValueDisplay.sourceCount`, `distinctSourceCount`, `deniedSomething`; `ReconciledValueRowModel.provenanceContent()`; `ProvenanceSheetHost`'s `content:` and its key from Citation ids; `CatalogQueryKey.provenanceSheet(project:citationIds:)`; `CatalogRenderedCitations`; `GenealogyStore.renderCitations` and its `GoStore`, `FakeStore` (five `renderCitations*` members) and `OnboardingModelTests` implementations; `CoreMethod.renderCitations`; `L10n.ProvenanceSheet.citationsLoading`, `.citationsFailedTitle` and their catalog entries; Go `RenderCitations`, `MethodRenderCitations` and its case, `RenderCitationsRequest`, `RenderCitationsResponse`, `citationrender.Render`; `citation_render_test.go` `renderCitations`, `TestRenderCitations`; `provenance-loading.md`. `MaxCitations` and `MaxBatchBytes` stay (`RenderAll` reads both).
**Next adds.** S16-25 converts `provenanceSheet` with the other keys; its tag-first ids are plain ids. A new row kind on a detail page needs only a `RecordsSource` case and its request.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| The sheet opened before its read answers | `PVProvenanceSheet` with `.loading` and header-only content | Header from the row (D-4); a new key reads nil at once (`ProvenanceSheetHost` comment); T-6 |
| A read answering no owners, or a field the read left out | `PVProvenanceSheetContent` with no groups | Ready table with no rows; the page's refresh closes the sheet (D-9); T-5 |
| A row whose page field has counts but no outcomes | `ReconciledValueRowModel`, the three builders | Counts drive every test (D-1, `hasRecords`); T-2, T-3 |
| The page refreshes while the sheet is open | `ConclusionDetailRowsSection` | The host gets the new row; the key changes only when the request does; `onChange(of: key)` releases the old one, as today |

### Scale

At the map's Scale (up to 1,200 records on one value; 30 Sources on a Person page): the detail read stops sending outcomes (S15-28 T-7 measured 34,704 → 2,963 bytes at 30 Sources × 2 records). The sheet's read is S15-28's, 14.8 ms warm at 1,200 records (S15-28 T-8). Swift builds the content once per change of the key's revision or the row (`conclusionContent`), linear in the records now that no record searches its field (D-6). A write the sheet's inputs name reloads one key once. No list or loop grows with the page.

### Edges

- **Assumptions.** Go answers owners in request order (S15-28 `FieldRecords`); `PVProvenanceSheetContent.derived` orders the shown owner first itself, so Go's order is not relied on there. A row's request is stable across a page refresh when its fields are, so the key does not churn. `recordCounts.sources` is 0 for an empty field, so `countLine` keeps returning nil for `.empty` from its state switch, not from the count.
- **Neighbors.** A row with records 0 but a displayed value (a concluded field with no records): no sheet, as today, where `outcomes` was empty. A span where one field has records and one has none: the request names both; Go leaves the empty one out; its records are the other's (D-5). A likeness record (no field): `counted` and `outcomeMark` read `deniedAValue` false, as before (S15-28 Edges).
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

`api/proto/engine.proto`: in `Method`, `METHOD_RENDER_CITATIONS = 124;` becomes `reserved 124;` and `reserved "METHOD_RENDER_CITATIONS";` under a comment line "Citations render with the sheet's records, in GetProvenanceRecords."; `RenderCitationsRequest` and `RenderCitationsResponse` go. `ConclusionField.outcomes` gains the comment "Filled only by GetProvenanceRecords; GetConclusionDetail sends record_counts instead." Regenerate with `./scripts/generate-proto.sh` (Go and Swift). Handlers per D-10, D-11; `api/ffi/dispatch.go` loses `MethodRenderCitations` and its case.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Provenance sheet | `PVProvenanceSheet` (recipe, Ship) | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` | Only the load area's strings and id prefix change (D-8) |
| Record area load state | `PVFormLoadArea` (component, Ship) | `macos/App/DesignSystem/Components/FormLoadArea/` | Loading and failed as S15-D9 drew them |
| Sheet content | `PVProvenanceSheetContent` (recipe content, Extend) | `…/ProvenanceSheet/PVProvenanceSheetContent.swift` | `init(field:records:title:shown:locale:orders:)`, `spanning(fields:records:…)`, `derived(owners:records:shownOwnerID:kind:…)`: header from the first argument, groups from `records` (D-4, D-5). `withRenders` unchanged |
| Host | `ProvenanceSheetHost` (snowflake, Extend) | `macos/App/Features/Conclusions/ProvenanceSheetHost.swift` | Key `.provenanceSheet(project:request:)`; content `session.conclusionContent(key, inputs: [key], extra: row, value:) { value, row in row.provenanceContent(records: value.owners).withRenders(value.citations) }`; with no value, `row.provenanceContent(records: [])` |
| Presenter | `ConclusionDetailRowsSection` | `ReconciledValueRow.swift` | `if let row = item.row(in: rows), let request = row.provenanceRequest(entityID: entityId)` draws the host |

States: loading — header and headings, "Loading records" (AC-2.4); failed — "Records could not be read" with Read again (AC-2.6); ready with no owners — the headings and no rows (D-9); a reload — the shown table until the reload answers (AC-2.7). Accessibility: the loading caption is spoken as shown; nothing else changes.

### Strings

L10n keys *(new)*: `L10n.ProvenanceSheet.recordsLoading` = "Loading records" (key `provenanceSheet.recordsLoading`, comment "Caption and VoiceOver label of the provenance sheet's record area while its records are being read"); `L10n.ProvenanceSheet.recordsFailedTitle` = "Records could not be read" (key `provenanceSheet.recordsFailedTitle`, comment "Title of the provenance sheet's notice when its records could not be read"). Removed: `provenanceSheet.citationsLoading`, `provenanceSheet.citationsFailedTitle`. The area now covers records and citations; no other copy names the old scope (`rg -n "citations could not\|Loading citations" macos/App`).

## 7. Steps

**STEP-1 — Wire types and the store read**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `CoreInvoke.swift`; `macos/ProvenenciaTests/CatalogSessionStoreTests.swift`, `OnboardingModelTests.swift`. Skill: `add-swift-test`.
Do: the types, fields, store method, mappers and fakes in Codebase fit. `GoStore.getProvenanceRecords` builds `Provenencia_Engine_V1_GetProvenanceRecordsRequest` (`fields.pairs` or `derived` with the wire kind) and maps owners with `mapOwnerField`, citations with `mapRenderedCitation`; `mapConclusionField` sets `recordCounts`, `mapReconcilerOutcome` the two denial fields. Keep `renderCitations` in this step; its caller goes in STEP-4.
Check: `xcodebuild test` (per `add-swift-test`) passes with T-1.

**STEP-2 — Rows count from the engine**
Files: `ReconciledValueRowModel.swift`, `ReconciledValueDisplay.swift`, `PersonDetailContent.swift`, `EventDetailContent.swift`, `PlaceDetailContent.swift`; `ReconciledValueDisplayTests.swift`, `PersonDetailTests.swift`, `EventDetailTests.swift`, `PlaceDetailTests.swift`.
Do: `recordCount` sums `recordCounts.records` per source; `countLine` and `spokenState` read `field.recordCounts.sources`; the builders test `field.hasRecords`; `sourceCount` goes. The test fixture `ReconciledValueDisplayTests.field` gains `counts: CatalogFieldRecordCounts? = nil` (nil → `records: outcomes.count, sources: 0`); `mergedName` passes {4, 2}; every test asserting a Source count passes its counts.
Check: Swift tests pass with T-2, T-3.

**STEP-3 — Records worded from the denial facts**
Files: `ReconciledValueDisplay.swift`, `PVProvenanceSheetContent.swift`; `ReconciledValueDisplayTests.swift`, `ProvenanceSheetTests.swift`.
Do: D-6 and D-7; `deniedSomething` and `distinctSourceCount` go. The `ReconciledValueDisplayTests.outcome` fixture gains `deniedAValue:` and `deniedBySourceTitle:` (defaults false, "").
Check: Swift tests pass with T-4; `rg -n "deniedSomething\|distinctSourceCount\|sourceCount(" macos` finds nothing.

**STEP-4 — The sheet reads its row's records when it opens**
Files: `CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `GenealogyStore.swift` (`CatalogProvenanceSheetRead`), `GoStore.swift`, `FakeStore.swift`, `CoreInvoke.swift`, `ReconciledValueRowModel.swift`, `PVProvenanceSheetContent.swift`, `PVProvenanceSheet.swift`, `ProvenanceSheetHost.swift`, `ReconciledValueRow.swift`, `ConclusionDetailPage.swift`, `PersonDetailView.swift`, `L10n.swift`, `Localizable.xcstrings`; `CatalogQueryRegistryTests.swift`, `WorkspaceSessionTests.swift`, `CatalogSessionStoreTests.swift`, `OnboardingModelTests.swift`, `ProvenanceSheetTests.swift`, `PersonDetailTests.swift`, `EventDetailTests.swift`, `PlaceDetailTests.swift`. Skills: `add-workspace-place`, `add-ui-component`, `add-localized-string`.
Do: D-1 – D-5, D-8, D-9, D-14; the macOS table and Strings. The `.provenanceSheet` loader calls `getProvenanceRecords(projectDir:request: key.provenanceRequest)`. `renderCitations`, `CatalogRenderedCitations` and their fakes go. Each test that called `provenanceContent()` calls `provenanceContent(records:)` with the owners its fixture's fields would have come back as (`CatalogOwnerField(entity:, field:)` for a field row). The previews keep building content through `PVProvenancePreviewData`.
Check: Swift tests pass with T-5 – T-8; `rg -n "renderCitations\|CatalogRenderedCitations\|provenanceContent()" macos docs/*.md .agents` finds only `macos/App/Platform/Generated/`.

**STEP-5 — The detail read sends no records**
Files: `api/ffi/handlers/conclusion_detail.go`, `provenance_records.go`, `conclusion_detail_test.go`, `provenance_records_test.go`. Skill: `add-ffi-handler`.
Do: D-10.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes with T-9 – T-12.

**STEP-6 — `RenderCitations` goes**
Files: `api/proto/engine.proto`, `api/proto/engine/engine.pb.go`, `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/citation_render.go`, `citation_render_test.go`, `api/ffi/dispatch.go`, `provenance_records_test.go`, `core/database/citationrender/render.go`, `render_test.go`, `scale_test.go`.
Do: D-11, D-12, D-13; the FFI and Go core sections. `TestGetProvenanceRecordsWarmReadsNoRecordSQL` compares with a warm `RenderAll`. Run `./scripts/generate-proto.sh` on the Mac that runs `xcodebuild`.
Check: `go build ./...`; `CGO_ENABLED=1 go test -tags fts5 ./core/database/citationrender/ ./api/...` passes with T-13, T-14; AC-4.4's `rg` holds.

**STEP-7 — Docs**
Files: `docs/macos-client-patterns.md`, `docs/design-system-layers.md`, `.agents/skills/add-ui-component/SKILL.md`, `docs/citation-formats.md`, `docs/deployment-plan/spike-15/provenance-loading.md` (deleted), `docs/deployment-plan/spike-15/README.md`, `docs/deployment-plan/spike-15/deployment-plan.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (line 825), `docs/ideas/person-page-performance.md`, `../completed.md`, this plan; `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: "One detail key for every kind": the detail carries each field's state, values and `record_counts`, not its records; a provenance sheet reads its row's records with `GetProvenanceRecords` under the `provenanceSheet` key while it is shown. In `design-system-layers.md` §2 and `add-ui-component` step 3, "built when the recipe opens" becomes "built when the recipe opens, or when the read it waits on answers (`PVProvenanceSheetContent`: header from the row, records from the sheet's read)". In `citation-formats.md`, line 70 names `GetProvenanceRecords` in place of `RenderCitations`; line 76's paragraph describes `citationrender.RenderAll` (any number of ids, a batch of 2,000 at a time, one 8 MiB budget per call, an over-budget batch left out so its records show today's line). Delete `provenance-loading.md`; each live link to it becomes the plan link `prs/S15-28-records-load-on-their-own.md` or `prs/S15-29-records-load-when-the-sheet-opens.md` (the "Load records" section) or `prs/S15-27-provenance-table-fold.md` (the "Cap" section), and the feature-context row in `deployment-plan.md` reads "Provenance loading and drawing (S15-27 – S15-29 plans)". Version bump per the header. The rest per the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`; `rg -n "provenance-loading.md" docs .agents` finds only files under `docs/deployment-plan/spike-15/design/archive/` and `docs/deployment-plan/spike-15/prs/`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log`. No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `CatalogSessionStoreTests.swift` `provenanceRecordsAnswersTheAskedRequest` *(replaces `renderCitationsAnswersTheAskedIds`)* | a reply set for `.fields([(P, p-name)])` → that reply, one call recorded with the request; an unlisted request → empty owners and citations | AC-2.1 |
| T-2 | Swift | `ReconciledValueDisplayTests.swift` `countLineCountsSourcesNotRecords` (rewritten), `spokenStateReadsTheCounts` *(new)* | merged with counts {4, 2} → "2 Sources", spoken "merged from 2 Sources"; mixed {5, 3} → "3 Sources"; empty → nil; concluded → "by you" | AC-1.1, AC-1.2 |
| T-3 | Swift | `PersonDetailTests.swift` `aFieldShowsOnceARecordSpeaksToIt` *(new)*; `EventDetailTests.swift` `theDateRowSkipsAPropertyWithNoRecords` *(new)*; `PlaceDetailTests.swift` `namesRowIsEmptyWithNoRecords` *(new)*; `ProvenanceSheetTests.swift` `aRowCountsFromTheEngine` *(replaces `aRowBuildsItsContentOnCall`)* | sex at birth with records 0 → no row, 1 → a row, both with no outcomes; Event date with records 0 on `start_date` → row from the next Property; toponym records 0 → empty row; a life row with owners {3, 1} → `recordCount` 4, `hasRecords`; `.empty` → 0 | AC-1.3, AC-1.4, AC-1.5 |
| T-4 | Swift | `ReconciledValueDisplayTests.swift` `aNegativeReadsFromItsDenialFact` *(new)*, `aDeniedRecordNamesItsDenier` *(new)*; `ProvenanceSheetTests.swift` `aPooledPlaceGroupHasOneHeadingPerValue` (extended) | negative with `deniedAValue` true → "kept", `.check`, counted; false → "disagrees · did not eliminate", `.circleMinus`, not counted; denied with title "Court deposition, 1862" → "denied by Court deposition, 1862"; "" → "denied"; pooled run over Sources A, A, B → "2 Sources" | AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, D-6, D-7 |
| T-5 | Swift | `ProvenanceSheetTests.swift` `aRowAsksForItsOwnRecords` *(new)*, `contentTakesRecordsFromTheRead` *(new)*, `theSummarySaysOnlyWhatTheRowKnows` (rewritten over counts) | field row → `.fields([(P, p-name)])`; span over `start_date`, `end_date` → both pairs in that order; birth place → `.derived(P, .birthPlace)`; Event place row (no kind) → nil; `.empty` → nil. Content with `records: []` → no groups, summary "merged from 3 Sources · 1 record disagrees · 4 records" from counts {4, 3}; with the read's field → its 4 records; a span whose read lacks `end_date` → `start_date`'s records only; derived summary "4 records from 2 birth events" from page counts {3, 1}; derived with read owners → groups from them, shown owner first | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, D-1, D-4, D-5, D-9 |
| T-6 | Swift | `WorkspaceSessionTests.swift` `ProvenanceSheetSessionTests.hostReadsTheRowsRecordsOnTask` *(replaces `hostReadsTheSessionAndRendersOnTask`)* | a hosted `ProvenanceSheetHost` for a name row of entity `P` → one `getProvenanceRecords` call with `.fields([(P, p-name)])`; the handle's value holds the fake's owners and citations | AC-2.1, AC-2.5 |
| T-7 | Swift | `CatalogQueryRegistryTests.swift` `provenanceSheetKeyKeepsOrderAndFollowsInputs` *(replaces `provenanceSheetKeySortsAndFollowsInputs`)*; `WorkspaceSessionTests.swift` `releaseDropsTheKey`, `releaseDuringALoadNeverLandsOnTheNewHandle`, `provenanceSheetLoadStates`, `provenanceSheetReadAgainAfterFailure` (moved to the `provenanceRecords*` fakes) | pairs (b, x), (a, y), (b, x) → ids `["fields", "b", "x", "a", "y"]` and `provenanceRequest` reads them back; `.derived(P, .deathPlace)` → `["life", "P", "deathPlace"]` and back; a write naming a reported Source reloads once; release, load states and Read again as before | AC-2.6, AC-2.7, AC-2.8, D-3 |
| T-8 | Swift | `ProvenanceSheetTests.swift` `theLoadAreaNamesRecords` *(new)* | `L10n.string(L10n.ProvenanceSheet.recordsLoading)` == "Loading records"; `.recordsFailedTitle` == "Records could not be read" | AC-2.4, AC-2.6, D-8 |
| T-9 | Go | `conclusion_detail_test.go` `TestGetConclusionDetail` (changed) | the name field: no outcomes, `record_counts` {2, 1}; `wantInputs` with the graphs and Sources of `GetProvenanceRecords`' outcomes for the same pair | AC-4.1, AC-4.3, D-10 |
| T-10 | Go | `conclusion_detail_test.go` `TestGetConclusionDetailCarriesDerivedRows`, `TestGetConclusionDetailWarmReadsNoRecordSQL` (changed) | the owner field: no outcomes, records 2; the warm read's name field has records > 0 | AC-4.2 |
| T-11 | Go | `conclusion_detail_test.go` `TestOwnerFieldProtoCarriesVoteAndArtifact` *(replaces `TestConclusionDetailProtoCarriesVoteArtifactAndMembers`)* | `ownerFieldProto(o, conclusionFieldRecordsProto)` carries the outcome's vote, Artifact, labels, page and group rank; `conclusionDetailProto` carries the member count and no outcome | D-10 |
| T-12 | Go | `provenance_records_test.go` `TestDetailCarriesNoRecords` *(replaces `TestDetailPayloadWithoutRecords`)* | `researchedPerson(t, 30, 2)`: every field and derived owner of `GetConclusionDetail` has no outcomes; log the payload's bytes | AC-4.1 |
| T-13 | Go | `core/database/citationrender/render_test.go`, `core/database/citationrender/scale_test.go`: every `Render` call becomes `RenderAll`; `TestRenderLimits` per D-12 | the cases' results unchanged; 70 big → none, no error; 60 → 60 | D-11, D-12 |
| T-14 | Go | `citation_render_test.go` `TestRenderedCitationsProto` *(new)* | one `RenderedCitation` with an italic run in full and plain short → the wire's runs, italics and plain text for both | D-13 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `ProvenanceSheetTests`, `PersonDetailTests`, `EventDetailTests`, `PlaceDetailTests` (fixtures with outcomes and no counts hide their rows until STEP-2 sets counts), `TestGetProvenanceRecords` (it maps owners through the new mapper), `TestRenderScale`, any `runRPC` case with `exact: true` over a `ConclusionDetail`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; the two citations keys are gone from both
- [ ] Sweep: `rg -n "provenanceContent()\|deniedSomething\|distinctSourceCount\|renderCitations\|RenderCitations\|citationrender\.Render\b\|citationsLoading\|citationsFailedTitle" .agents .cursor/rules docs/*.md macos/App api core` finds only generated code and the `reserved` line; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] UI matches §6 macOS; no new kit primitive
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped, with T-12's payload bytes
- [ ] Domain docs: macos-client-patterns.md, design-system-layers.md, add-ui-component, citation-formats.md (STEP-7); provenance-loading.md deleted and its links moved
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with a Person cited by several Sources, with a merged name and a birth date read off two Events (the dogfood catalog's James Robins, or any Person with a mixed birth date). Each Vitals row reads the counts it read before this PR.
2. Open the name row's provenance sheet. The title, value, badge and summary draw at once; "Loading records" shows under the headings until the table draws; the summary does not change.
3. Open the birth date row's sheet: two owner lines, the shown Event's first; Read as, Citation, Outcome and Record as before.
4. With a sheet open, edit a cited Source's title in another window (or rename it and come back): the citations update in place with no loading state.
5. Open an Event's Date row and a Place's Names row sheet: their records as before.
6. Check each sheet at Regular and Wide: unchanged apart from the loading caption.
7. AC-4.4: run the `rg` in AC-4.4 and see no hit beyond those it names.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The header and table disagree after a write moves counts before the sheet's reload answers | Both keys follow the same inputs and reload on the same write; the header reads the page's counts (D-4) |
| Fixtures in five test files build page fields with outcomes and no counts, hiding rows | STEP-2 gives the fixture `counts:`; the failing tests show where |
| The key churns on every page refresh | The request depends only on the row's fields' ids and the entity (D-1, D-3); T-7 |

**Stop and report if:**

- After a merge or a records delete, the sheet stays open past the page's refresh (D-9 does not hold): report the steps.
- `GetProvenanceRecords` answers owners out of request order for a `.fields` request.
- A page builder needs a record, not a count, to decide a row (a fourth `field.outcomes` reader outside the sheet).
- `TestRenderScale`'s budget fails once it calls `RenderAll`.
- Removing outcomes from the detail changes its reported `inputs` (T-9).

## 12. Open questions

None.

## 13. PR

**Title:** S15-29 — The provenance sheet loads its records when it opens
**Body:** objective in one sentence; what shipped against each US; AC evidence; T-12's payload bytes; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-29-records-load-when-the-sheet-opens.md`.
