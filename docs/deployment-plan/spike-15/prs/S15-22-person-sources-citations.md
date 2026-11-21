# S15-22 — The Sources section groups a Source's Citations by citation

**Status:** Blocked — on board S15-D15
**Spike / slice:** Spike 15 · Slice 6 — Citations in the app
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D15](../design/S15-D15-person-sources-citations.md), board not agreed yet
**Board:** — (to be drawn on the [Person page board](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page *Sources*, the turn after 19; when agreed, this line names the turn, its frames and the `path` the implementer reads with the Artifact tool's `read`, and the board's decisions that change SC-1 – SC-11)
**Depends on:** S15-16 (landed [#914](https://github.com/Jake-Robins-Studios/provenencia/pull/914): `RenderCitations`), S15-05 (landed [#919](https://github.com/Jake-Robins-Studios/provenencia/pull/919): the section's Published column), S15-21 (landed [#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930): `renderCitations`, `CatalogCitationRender.styled`, the labelled copy track, `WorkspaceSession.release`), S16-03 (landed #769), S16-06 (landed #785), S16-07 (landed #761), S15-D15
**Blocks:** —
**Branch:** `s15-22-person-sources-citations`
**Version bump:** minor, 0.31.0 → **0.32.0** (if `main`'s `VERSION` is no longer 0.31.0 when you rebase, the next minor after it): the Person page shows citations it did not show before ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (a `CatalogQueryKey` kind, its descriptor, `followsInputs`, a view-held key), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md) (promoting the copy track to a recipe), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/versioning.mdc`; [`docs/design-system-layers.md`](../../../design-system-layers.md) (a recipe never names a `Features/` type); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) cache contract items 2 and 5
**Context:** working rules "Grouping is by the rendered full citation, computed when read", "Citations render on demand, from SQL", "One engine, in Go", "Build on Spike 16's caches", "One window; nothing is built for a second" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); map § 6.9 "One EE citation, many Provenencia Citations" and § 6.10 ("Copying a note stays where notes are used") in [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md); landed plans [`S15-21-provenance-sheet-citations.md`](S15-21-provenance-sheet-citations.md) (D-1 – D-4, D-9, D-11: the store method, the view-held key, the copy track) and [`S15-05-person-sources-date.md`](S15-05-person-sources-date.md); [`docs/catalog-caches.md`](../../../catalog-caches.md)
**Planned:** 2026-11-21 against `main` @ `496ffa9` (compare with `origin/main` after `git fetch origin main`)
**Review:** [`S15-22-person-sources-citations.review.md`](S15-22-person-sources-citations.review.md) — not reviewed yet

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

In the Person page's Sources section, each record reads its citation: under the record line, the full citation the engine renders from the Source, its Artifact and the Evidence graph, with its italics, shown **once** for all the record's Citations that render the same full citation, with the pieces beneath it (what each of those Citations says about the person: "Name Johann Weber · Age 34 · Birthplace Bremen") and the provenance sheet's Full and Short copy buttons beside it. The citations are fetched when the section appears, through one cached read held only while the section is shown; the rows do not wait for it, and a failure shows one notice with Read again. This is bar 7 in the Sources section ("One household, one citation").

**Why now.** The render (S15-16), the sheet's use of it with the store method, the styled text, the labelled copy buttons and the view-held key (S15-21), and the section's date (S15-05) have landed. The section is the second and last screen of slice 6.

**What stays.** The caption line, the Source cells, the record lines and Unpromote, the folds, the record links diagram and its highlight, the section's own loading, error and empty states. A record whose type has no full format draws as today (user, 2026-11-21). The claims read and the Go engine are unchanged.

## 2. User stories

**US-1.** As a researcher, on a person's Sources section, I read each record's citation once, with its pieces beneath it, so that the five Citations of one household row read as one citation.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A record with Observations o1 (Citation c1), o2 (c2), o3 (c3); renders c1 and c2 key `full:K`, c3 key `full:L`, all with full runs | Under the record line, two blocks in this order: K's citation with the pieces of o1 and o2; L's citation with the piece of o3 |
| AC-1.2 | K's full runs `"Hamburg, Germany, 1867 census, …; digital image, "`, `"Nordarchiv Online"` (italic), `" (… : accessed 12 March 2025)"` | The block draws those runs, "Nordarchiv Online" in italic; VoiceOver reads the plain text |
| AC-1.3 | o1 is Name "Johann Weber", o2 is Age "34" | The pieces line reads "Name Johann Weber · Age 34" and is spoken "Name Johann Weber, Age 34" |
| AC-1.4 | A negative Observation, Birthplace "Bremen"; an Observation with no text value, Likeness; an Observation with an empty property label and key `occupation` | Pieces "Birthplace not Bremen", "Likeness", "occupation …" (the key stands in for the label) |
| AC-1.5 | Two Observations of one block whose pieces read the same text | The piece shows once |
| AC-1.6 | A record whose Citations all render an empty full (no format), or are missing from the reply | No block under its line; the line draws as today |
| AC-1.7 | A record with c1 formatted and c4 not | One block (c1's); o4 is not a piece anywhere |

**US-2.** As a researcher, I copy a record's full or short citation from the section.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | A block whose render has full and short | **Full** and **Short** show, stacked; Full writes `.rtf` with the italic and `.string` with the plain full; Short the short; VoiceOver hears "Full citation copied" / "Short citation copied" |
| AC-2.2 | A block whose render `short` is empty | Only **Full** shows |

**US-3.** As a researcher, the section shows its rows at once and tells me when citations could not be read.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | The section appears; the render has not answered (`FakeStore.renderCitationsHold`) | The rows draw with no blocks and no notice; one `renderCitations` call carries the distinct Citation ids of every claim, folded or not |
| AC-3.2 | The render fails (`FakeStore.renderCitationsError`) | One compact danger callout titled "Citations could not be read" with the error's message and **Read again** sits under the caption line; the rows draw with no blocks |
| AC-3.3 | Read again after AC-3.2, the store now succeeding | The key is read again; the callout goes; the blocks draw |
| AC-3.4 | Unfolding a Source's lines or the Sources' Show more | No new `renderCitations` call (the key already holds every claim's ids) |
| AC-3.5 | An Unpromote removes one record; the claims read reloads, so the key's ids change | The remaining records' blocks stay drawn until the new key answers, then draw from it; the old key is released then |
| AC-3.6 | The section disappears (another section, another place) | Its keys are released; appearing again calls `renderCitations` again |
| AC-3.7 | Back to a record line on this page | The keyboard and scroll land on that line after the citations answered or failed, not before |

## 3. Scope

| In | Covered by |
| --- | --- |
| `CatalogRenderedCitation.isFormatted`, `CatalogRenderedCitations.byID`; the sheet's read and record use them (D-1) | STEP-1 |
| The section's key `CatalogQueryKey.personSourcesCitations` and value `CatalogPersonSourcesCitations` (D-2) | STEP-1, AC-3.1 |
| The copy track promoted to the recipe `PVCitationCopyButtons`, its strings to `L10n.CitationCopy` (D-7, brief SC-4) | STEP-2, AC-2.1, AC-2.2 |
| Content: pieces, every claim's Citation ids, `citing(_:)` grouping (D-5, D-6, brief SC-2, SC-3, SC-5) | STEP-3, AC-1.1, AC-1.3 – AC-1.7, AC-3.4 |
| The view-held key with its hold, `PersonSourcesCitationsHost` (D-3, D-4, brief SC-6, SC-8) | STEP-4, AC-3.1, AC-3.5, AC-3.6 |
| The citation block, the failed notice, the anchor waiting for the citations (D-8 – D-10, brief SC-1, SC-4, SC-7, SC-9 – SC-11, SC-W1) | STEP-5, AC-1.2, AC-2.1, AC-3.2, AC-3.3, AC-3.7 |
| Docs: catalog caches, client patterns, `add-workspace-place`, completed, map, brief | STEP-6 |

| Out | Home |
| --- | --- |
| Today's citation line for a record whose type has no full format | not planned (user, 2026-11-21: nothing new under such a line; the claims read lacks the line's Artifact label, Citation label and page) |
| Citation labels and refs as the pieces | not planned (user, 2026-11-21: the pieces are the Observations) |
| Gathering one citation across two record lines of one Source | not planned (user, 2026-11-21: blocks sit under each record line; Edges) |
| A count, heading, card or disclosure per block; a link on the citation text | not planned (brief § 2.1) |
| Re-ordering Sources | not planned (map scope entry) |
| The provenance sheet's fold and records on open | S15-27, S15-29 |
| Copy source-list entry | S15-23 |
| Moving the sheet's own copy strings (`copyCitation`, `citationCopied`) or the sheet's load strings | not planned: only the strings `PVCitationCopyButtons` draws move (D-7) |
| Batching more than 2,000 Citation ids per call | not planned (Scale is 300 per section; D-12) |
| Caching renders past the section | not planned (rule "Citations render on demand, from SQL") |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Section | `macos/App/Features/Conclusions/PersonSourcesSection.swift` `PersonSourcesSection` | `ConclusionPageSectionHost<CatalogPersonClaims, PersonSourcesContent.Inputs, PersonSourcesContent, PersonSourcesList>` builds `PersonSourcesContent(groups:sourceTypes:orders:folds:)` in `make` and draws `PersonSourcesList(content:entityId:accessibilityIdentifierRoot:open:expand:unpromote:beginUnpromote:confirmUnpromote:)` |
| List | same file `PersonSourcesList` | `rows`: `header`, a strong `PVDivider`, `PersonSourcesRowView` per row, the rows' Show more; `.conclusionAnchorRestore([.sourceTitle, .sourceLine], isReady: true, focus: $focus) { content.anchorTarget(for: $0) }`; `.onChange(of: content)` applies pending focus after Unpromote |
| Row and line | same file `PersonSourcesRowView.lines`, `PersonSourcesLineView` | A `VStack` of `PersonSourcesLineView` (`.id(line.id)`) and the line fold's `ConclusionShowMoreRow`, indented `PersonSourcesColumns.lineIndent` (16); the line pads 2pt vertical, `PVSpacing.space2` horizontal, wears `personSourcesHighlight` and `.onHover` |
| Columns | same file `PersonSourcesColumns` | `spacing`, `typeWidth` 176, `dateWidth` 120, `refWidth` 104, `lineIndent` 16, `citationMin` 200, `minWidth` |
| Content | `macos/App/Features/Conclusions/PersonSourcesContent.swift` `PersonSourcesContent`, `Row`, `Line`, `Inputs` | `Line { id (claim id), subjectID, graphID, graphTitle, graphRef, subjectName, subjectRef, accessibilityLabel, unpromoteAccessibilityLabel, location }`; built from `CatalogPersonClaimGroup.claims`; folds lines (5) and rows (50); no citations |
| Claims | `macos/App/Platform/GenealogyStore.swift` `CatalogPersonClaim` | `observations: [CatalogObservation]`, each with `citationID`, `propertyKey`, `propertyLabel`, `polarity`, value fields |
| Observation text | `macos/App/Platform/ObservationValueDisplay.swift` `ObservationValueDisplay.string(for:locale:orders:)`; `macos/App/Features/EvidenceGraph/EvidenceCitedPropertyMarks.swift` `isNegated(_:)` | The value as the graph card draws it (name, date, term, boolean, text, integer, else ""); negative polarity test |
| Render types | `macos/App/Platform/GenealogyStore.swift` `CatalogRenderedCitation`, `CatalogRenderedCitations`, `CatalogProvenanceSheetRead` | The sheet's read builds its dictionary with `Dictionary(…, uniquingKeysWith: { first, _ in first })` in its `init` |
| Formatted test | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` `Record.isFormatted` | `rendered?.full.runs.isEmpty == false` |
| Store | `GenealogyStore.renderCitations(projectDir:citationIDs:)`; `macos/App/Platform/FakeStore.swift` `renderCitationsReplies`, `renderCitationsInputs`, `renderCitationsHold`, `renderCitationsCalls`, `renderCitationsError` | Landed in S15-21 |
| Query keys | `macos/App/Features/Workspace/Session/CatalogQueryKey.swift` `Kind.provenanceSheet`, `provenanceSheet(project:citationIds:)`; `CatalogQueryRegistry.swift` `case .provenanceSheet`; `CatalogLastUpdated.swift` `extension CatalogProvenanceSheetRead: CatalogPageValue {}` | The shape to copy |
| View-held key | `macos/App/Features/Conclusions/ProvenanceSheetHost.swift` `ProvenanceSheetHost`; `macos/App/Features/Workspace/Session/WorkspaceSession.swift` `release(_:)`; `WorkspaceSession+Derived.swift` `conclusionContent(_:inputs:extra:value:make:)` | Warms in `.task(id: key)`, reads `queryHandle`, releases the old key on `onChange(of: key)` and on `onDisappear`; groups through `conclusionContent`. `release`'s doc names one holder, the provenance sheet |
| Copy track | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordRow.swift` `Copy`, `copies(for:)`, `copyButton(_:)`, `VerticalAlignment.citationFirstLineCenter` (private); `PVProvenanceColumns.swift` `copyTrackWidth` 72, `copyTrackSpacing` 8 | The stacked labelled `PVClipboardButton`s, private to the row; words and labels from `L10n.ProvenanceSheet.copyWordFull`, `copyWordShort`, `copyWordCitation`, `copyFullCitation`, `copyShortCitation`, `copyCitation`, `fullCitationCopied`, `shortCitationCopied`, `citationCopied` |
| Retry notice | `macos/App/DesignSystem/Components/Callout/PVRetryCallout.swift` `PVRetryCallout(title:message:retry:isRetrying:compact:retryIdentifier:failureRevision:onRetry:)` | Danger callout, announces, re-announces per `failureRevision` |
| Anchor | `macos/App/Features/Conclusions/ConclusionAnchorRestore.swift` `conclusionAnchorRestore(_:isReady:focus:…)` | Restores once per mount after `isReady` |
| Previews | `macos/App/Features/Conclusions/PersonSourcesPreviewData.swift` `johannClaims`, `previewSession` | Johann's claims; no renders |
| Tests | `macos/ProvenenciaTests/PersonSourcesContentTests.swift`; `ProvenanceSheetTests.swift` `copyButtonsFollowTheRender`; `CatalogQueryRegistryTests.swift` `provenanceSheetKeySortsAndFollowsInputs`; `WorkspaceSessionTests.swift` `releaseDropsTheKey`, `provenanceSheetLoadStates` | Cover the content, the sheet's copies, the sheet key, release |
| Docs | `docs/catalog-caches.md` "Per-view query results" row; `docs/macos-client-patterns.md` cache contract item 2 (`ProvenanceSheetHost`); `.agents/skills/add-workspace-place/SKILL.md` "View-held key" row | Name the provenance sheet as the one view-held key |

**Precedent.** S15-21 ([#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930)): copy its key and value (D-2), its view-held key (D-4: warm in `.task(id:)`, read with `queryHandle`, memo through `conclusionContent`), its row's styled citation (D-9) and its tests T-2, T-3, T-9, T-10. Do not copy its "no stale frame": the section keeps the old key's value until the new key answers (D-4 here). S15-05 ([#919](https://github.com/Jake-Robins-Studios/provenencia/pull/919)) promoted `PVPublishedDate` from a feature file to a recipe when it gained this section as a second caller; copy that move for the copy track.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **Shared render helpers.** `CatalogRenderedCitation.isFormatted: Bool` *(new, computed: `!full.runs.isEmpty`)* and `CatalogRenderedCitations.byID: [String: CatalogRenderedCitation]` *(new, computed: `Dictionary(citations.map { ($0.citationID, $0) }, uniquingKeysWith: { first, _ in first })`)*, beside them in `GenealogyStore.swift`. `CatalogProvenanceSheetRead.init` sets `citations = reply.byID`; `PVProvenanceSheetContent.Record.isFormatted` returns `rendered?.isFormatted == true` | Two screens test "formatted" and index a reply; one home for each rule | A copy of each in the section — two rules that can drift |
| D-2 | **Key and value.** `CatalogQueryKey.Kind.personSourcesCitations` *(new)*; `static func personSourcesCitations(project:citationIds:)` *(new)*, ids = the distinct non-empty ids, sorted, as `provenanceSheet`. Value `CatalogPersonSourcesCitations: Sendable, Equatable { citations: [String: CatalogRenderedCitation]; inputs: CatalogPageInputs }` *(new, in `GenealogyStore.swift`)* with `init(_ reply: CatalogRenderedCitations)` (`citations = reply.byID`); `extension CatalogPersonSourcesCitations: CatalogPageValue {}`. Descriptor: `.make(kind:, refreshes: CatalogQueryRefresh.followsInputs(CatalogPersonSourcesCitations.self), load: { key, store in CatalogPersonSourcesCitations(try await store.renderCitations(projectDir: key.project.projectDir, citationIDs: key.ids)) })`; default `whenHidden`; no `invalidateOn`, no patches. It is not in `ConclusionPageSection.reads` | A screen's renders are its own key (S15-21 D-2: "S15-22 gets its own key"); its ids come from the claims value, which a static section read cannot know | Sharing `provenanceSheet` — S15-29 grows that value with records; a section read — needs the claims first |
| D-3 | **Host.** `PersonSourcesCitationsHost` *(new, `macos/App/Features/Conclusions/PersonSourcesCitationsHost.swift` (new))* takes the section's `PersonSourcesContent` and the arguments `PersonSourcesList` takes today; `PersonSourcesSection`'s host content closure draws it in place of `PersonSourcesList`. It holds `@Environment(WorkspaceSession.self)` and `@State private var hold = CitationKeyHold()` (D-4). Key: `.personSourcesCitations(project: session.projectKey, citationIds: content.citationIDs)`. `.task(id: key) { let _: QueryHandle<CatalogPersonSourcesCitations> = session.query(key) }`. `.onChange(of: key) { old, _ in if let r = hold.move(from: old, oldHasValue: oldHandle(old)?.value != nil) { session.release(r) } }`. `.onChange(of: load != .loading) { _, settled in if settled, let r = hold.settle() { session.release(r) } }`. `.onDisappear { hold.all(current: key).forEach(session.release) ; hold = CitationKeyHold() }`. In `body`: `current = session.queryHandle(key)`; drawn renders = `current?.value`, else the held key's handle value; `load` = `.ready` when the held key is drawn, else `current?.read.formLoadState ?? .loading`. Cited content: when a value is drawn, `session.conclusionContent(drawnKey, inputs: [drawnKey], extra: content, value: drawn) { value, content in content.citing(value.citations) }`, else `content`. It passes `PersonSourcesList` the cited content, `citationsLoad: load`, `citationsFetching: current?.isFetching ?? false`, `citationsFailureRevision: current?.failureRevision ?? 0` and `readCitationsAgain: { let _: QueryHandle<CatalogPersonSourcesCitations> = session.reread(key) }` | The section's own read is the claims; the renders are a second, view-held read (cache contract item 2's view-held key), memoized through the session (item 5) | Querying in `PersonSourcesSection.body` — it has no content until the host's `make`; in `PersonSourcesList` — the previews draw it with no session reads |
| D-4 | **Hold.** `struct CitationKeyHold: Equatable` *(new, in `PersonSourcesCitationsHost.swift`)*: `private(set) var held: CatalogQueryKey?`; `mutating func move(from old: CatalogQueryKey, oldHasValue: Bool) -> CatalogQueryKey?` — when `oldHasValue`, the previous `held` is returned (to release) and `old` is held; else `old` is returned and `held` is kept; `mutating func settle() -> CatalogQueryKey?` returns `held` and clears it; `func all(current: CatalogQueryKey) -> [CatalogQueryKey]` is `current` then `held`. Pure | Brief SC-8: an Unpromote changes the ids, and a new key reads nil at once; drawing nothing until it answers would collapse every block and jump the scroll under the researcher's pointer. A key, not a handle or content, so cache contract item 5 holds | Dropping the old key at once as the sheet does — the blink; a `@State` copy of the renders — item 5 |
| D-5 | **Content.** `PersonSourcesContent` gains `let citationIDs: [String]` *(new)*: every claim's Observations' non-empty `citationID`s, folded or not, distinct, first appearance. `Line` gains `var observed: [Observed] = []` *(new; `struct Observed: Equatable { var citationID: String; var piece: String }`, one per Observation in the claim's order whose `piece(for:orders:)` (D-6) is non-nil)* and `var citations: [Citation] = []` *(new; `struct Citation: Equatable, Identifiable { var id: String (the group key); var rendered: CatalogRenderedCitation (the first Citation's render); var pieces: [String] }`)*. `func citing(_ renders: [String: CatalogRenderedCitation]) -> PersonSourcesContent` *(new, pure)* returns a copy whose shown lines each get `citations`: walk `observed` in order; skip one whose `renders[citationID]` is missing or not `isFormatted`; gather by `groupKey` in first-appearance order; append `piece` unless the block already holds that text. A line with none keeps `[]`. Swift adds no rule of its own about which keys group | Rule "Grouping is by the rendered full citation, computed when read"; rule "One engine, in Go": the engine's key decides. The key covers folded lines too, so unfolding never re-keys (AC-3.4). `citing` runs once per drawn value through `conclusionContent` | Grouping across a Source's record lines — user, 2026-11-21: blocks under each record line; storing pieces on `Citation` only — `citing` needs the observed list on a line built before the renders |
| D-6 | **Piece.** `static func piece(for observation: CatalogObservation, orders: NameFormatOrders) -> String?` *(new, on `PersonSourcesContent`)*: label = `propertyLabel` trimmed, else `propertyKey`; value = `ObservationValueDisplay.string(for:orders:)` trimmed; negative (`EvidenceCitedPropertyMarks.isNegated`) → `L10n.Conclusions.sourcesPieceNegated(property:value:)` = "{property} not {value}"; else `L10n.Conclusions.sourcesPiece(property:value:)` = "{property} {value}"; an empty value → the label alone (negative too); an empty label and key → nil (no piece). The line's `init` fills `observed` with it | User, 2026-11-21: the pieces are the Observations, from data the claims read already carries; the graph card's value text, so a piece reads as the card does | Citation labels — not in the claims read (Go change); a new value formatter — `ObservationValueDisplay` is the one |
| D-7 | **Copy track recipe.** `PVCitationCopyButtons` *(new, `macos/App/DesignSystem/Recipes/CitationCopy/PVCitationCopyButtons.swift` (new))*: `struct Copy: Equatable` (moved from `PVProvenanceRecordRow`, same `Kind` `.full`, `.short`, `.citation`, `text`, `rich`); `nonisolated static func formatted(_ rendered: CatalogRenderedCitation) -> [Copy]` (full, then short when its runs are non-empty); `nonisolated static func line(_ text: String) -> [Copy]` (`[.citation]`, plain); `static let trackWidth: CGFloat = 72`, `trackSpacing: CGFloat = 8`; `init(_ copies: [Copy], idPrefix: String)`; its body is the row's `VStack(alignment: .leading, spacing: PVSpacing.space1)` of `PVClipboardButton`s with the ids `\(idPrefix).copyFull`, `.copyShort`, `.copy`, framed `minWidth: trackWidth` with the first-line alignment guide. `VerticalAlignment.citationFirstLineCenter` and `View.citationFirstLineGuide(textSize: CGFloat)` *(new, internal, same file)* move out of the row file. `PVProvenanceRecordRow.copies(for:)` stays and returns `record.isFormatted ? .formatted(rendered) : .line(record.citation.line)`; the row draws `PVCitationCopyButtons(Self.copies(for: record), idPrefix: "\(idPrefix).\(record.id)")`. `PVProvenanceColumns.copyTrackWidth` and `copyTrackSpacing` read the recipe's constants. The nine copy strings move to `L10n.CitationCopy` *(new namespace)*: `wordFull`, `wordShort`, `wordCitation`, `copyFull`, `copyShort`, `copyCitation`, `fullCopied`, `shortCopied`, `citationCopied`, keys `citationCopy.*`, same English; the `provenanceSheet.copy*`, `*CitationCopied` and `citationCopied` keys leave `Localizable.xcstrings` | Brief inventory: a second caller promotes the track (as S15-05 promoted `PVPublishedDate`); the recipe owns its words, so a Person page section does not draw `ProvenanceSheet` strings | Drawing two `PVClipboardButton`s in the section — a near-copy of `copies(for:)` and the three button configurations; keeping the strings under `ProvenanceSheet` — a recipe that reads another recipe's namespace |
| D-8 | **Block.** `PersonSourcesCitationView` *(new, private, in `PersonSourcesSection.swift`)* draws one `Line.Citation`: `HStack(alignment: .citationFirstLineCenter, spacing: PVCitationCopyButtons.trackSpacing)` of the citation `Text(PVTitleText.italicizingEmphasis(citation.rendered.full.styled, font: PVFont.body(size: PVTypeScale.bodySmall)))` in `PVColor.textPrimary`, `.textSelection(.enabled)`, `.fixedSize(horizontal: false, vertical: true)`, `.frame(maxWidth: PersonSourcesColumns.citationMeasure, alignment: .leading)`, `.citationFirstLineGuide(textSize: PVTypeScale.bodySmall)`, `.accessibilityLabel(citation.rendered.full.plain)`; then `PVCitationCopyButtons(.formatted(citation.rendered), idPrefix: "\(root).citation.\(line.id).\(index)")`. Under the citation, `VStack` spacing `PVSpacing.space1`, the pieces `Text(verbatim: citation.pieces.joined(separator: " · "))` in `PVFont.body(size: PVTypeScale.caption)`, `PVColor.textSecondary`, same measure, `.accessibilityLabel(citation.pieces.joined(separator: ", "))`. `PersonSourcesColumns.citationMeasure: CGFloat = 680` *(new)*. In `PersonSourcesRowView.lines`, each line is a `VStack(alignment: .leading, spacing: PVSpacing.space2)` of `PersonSourcesLineView` and its blocks (`ForEach(Array(line.citations.enumerated()), id: \.element.id)`), the blocks padded `.leading` `PVSpacing.space2` (the line's own horizontal padding, so the citation starts under the graph link's text) and `.bottom` `PVSpacing.space1`; `.id(line.id)` moves to that `VStack`. The highlight and `.onHover` stay on `PersonSourcesLineView` only | Brief SC-1 – SC-4, SC-9 – SC-11, SC-W1; a snowflake, the section's only block | A recipe for the block — one call site; a link on the citation — a block spans several Citations, so no one target (brief § 2.1) |
| D-9 | **Failed notice.** `PersonSourcesList` gains `citationsLoad: PVFormLoadState = .ready`, `citationsFetching: Bool = false`, `citationsFailureRevision: Int = 0`, `readCitationsAgain: () -> Void = {}` *(new; defaults keep the previews)*. When `citationsLoad` is `.failed(message)`, `rows` draws `PVRetryCallout(title: L10n.Conclusions.sourcesCitationsFailedTitle, message: message, retry: L10n.DesignSystem.formReadAgain, isRetrying: citationsFetching, compact: true, retryIdentifier: "\(root).citations.readAgain", failureRevision: citationsFailureRevision, onRetry: readCitationsAgain)` after the strong divider, padded `PVSpacing.space3` vertical, id `\(root).citations.error`. Loading draws nothing | Brief SC-6, SC-7; the kit's retry callout, which announces | `PVFormLoadArea` — the rows do not wait on this read; the section host's error — that is the claims read's |
| D-10 | **Anchor waits.** `PersonSourcesList` gains `citationsSettled: Bool = true` *(new)*; the host passes `load != .loading`; `conclusionAnchorRestore([.sourceTitle, .sourceLine], isReady: citationsSettled, …)` | Brief SC-6: blocks arriving after the restore would push the restored row down | Restoring at once — the row slides away |
| D-11 | **Copy.** `L10n.Conclusions.sourcesCitationsFailedTitle` = "Citations could not be read", `sourcesPiece(property:value:)` = "%1$@ %2$@", `sourcesPieceNegated(property:value:)` = "%1$@ not %2$@" *(new)*; D-7's `L10n.CitationCopy` keys. Read again is the kit's `L10n.DesignSystem.formReadAgain`; the failed message is the load state's (`L10n.Errors.message(for:)`). The separators " · " and ", " are verbatim, as the record line's are | Brief SC-2, SC-7, SC-9 | — |
| D-12 | **Size.** No chunking: more than 2,000 distinct ids is the engine's `citations.invalid`, shown as the failed notice | Scale is 300 citations per section | Splitting calls — code for a case past Scale |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `CatalogRenderedCitation.isFormatted`, `CatalogRenderedCitations.byID` *(new)* | computed property | `PVProvenanceSheetContent.Record.isFormatted`; `CatalogProvenanceSheetRead.init` | They become the one home; both callers switch (D-1) |
| `Kind.personSourcesCitations`, `CatalogPersonSourcesCitations` *(new)* | query key, value | `provenanceSheet`, `CatalogProvenanceSheetRead` | Separate holder and lifetime; S15-29 grows the sheet's value (D-2) |
| `PersonSourcesCitationsHost` *(new)* | view | `ProvenanceSheetHost` | Same shape; adds the hold (D-4) and draws a section, not a sheet |
| `CitationKeyHold` *(new)* | type | — (searched `release(`, `onChange(of: key)`: only `ProvenanceSheetHost`, which drops at once) | The one view that keeps an old key's value |
| `PVCitationCopyButtons`, `citationFirstLineGuide` *(new, moved)* | recipe | `PVProvenanceRecordRow`'s private copy track | Promoted on its second caller (D-7) |
| `L10n.CitationCopy` *(new namespace, moved keys)* | key | `L10n.ProvenanceSheet.copy*` | The recipe's own words (D-7) |
| `Line.Observed`, `Line.Citation`, `citationIDs`, `citing(_:)`, `piece(for:orders:)` *(new)* | type, func | `PVProvenanceSheetContent.grouped(by:)`, `CitationRun` | The sheet groups records it already has; the section groups a record's Observations |
| `PersonSourcesCitationView` *(new)* | view | `PVProvenanceRecordRow.citation` | The sheet's cell is a link with Source and Observation links; the block is text, copy track and pieces |
| `PersonSourcesColumns.citationMeasure` *(new)* | constant | `PersonSourcesColumns.citationMin` | A maximum, not a minimum |
| L10n keys (D-11) *(new)* | key | `L10n.ProvenanceSheet.citationsFailedTitle` | The section's own namespace, as its other notices |

**Builds on.** The query registry and `followsInputs`; the view-held key and `release` (S15-21); `conclusionContent`; `CatalogCitationRender.styled` and `PVTitleText.italicizingEmphasis`; `PVClipboardButton(word:rich:)`; `PVRetryCallout`; `ObservationValueDisplay`.
**Deletes.** `PVProvenanceRecordRow.Copy`, its private `copyButton` functions and its private `VerticalAlignment.citationFirstLineCenter` (moved to the recipe, D-7); the nine `L10n.ProvenanceSheet` copy keys and their `Localizable.xcstrings` entries (moved, D-7); the inline dictionary build in `CatalogProvenanceSheetRead.init` (D-1).
**Next adds.** S15-23's Copy source-list entry draws `PVCitationCopyButtons(.line(…))` or one `PVClipboardButton` with `L10n.CitationCopy` words. A third screen that lists citations calls `renderCitations` under its own view-held key with `CitationKeyHold`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| The claims reload and change the ids (Unpromote, a promote elsewhere) | `PersonSourcesCitationsHost` | New key queried; old key held while it has a value, released when the new one settles (D-4, AC-3.5) |
| Another person's page in the same view | `PersonSourcesSection` remounts per page (`entityId`), so the host and its hold start fresh; the old page's `onDisappear` releases its keys |
| A Citation deleted between the claims read and the render | `citing(_:)` | Missing from the dictionary → its Observations make no piece; a line left with none has no block (AC-1.6) |
| A section with no claims | `PersonSourcesSection` | The section's empty state draws as today; the host is never built (the host closure runs on content only) |
| Section switch or leaving the page | `PersonSourcesCitationsHost.onDisappear` | Releases current and held keys (AC-3.6) |

### Scale

At the map's Scale (30 Sources, up to 300 citations per section): one `RenderCitations` call per appearance (S15-16 measured 9 SELECTs at 300). `citationIDs` is one pass over the claims' Observations. `citing(_:)` is one pass over the shown lines' Observations with a dictionary per line, run once per drawn value through `conclusionContent`. A write that reaches the key's inputs while shown reloads it once and keeps the drawn value meanwhile. An Unpromote makes one new call. The key holds up to 300 ids, hashed once per query.

### Edges

- **Assumptions.** `ConclusionPageSectionHost`'s content closure draws only when the claims value is present, so `content.citationIDs` is the claims' (STEP-4). `Line` equality now includes `citations`, so `PersonSourcesList.onChange(of: content)` also fires when the renders arrive; `applyPendingFocus` and the hover clear are idempotent for unchanged claims (T-4 checks content equality across `citing`).
- **Neighbors.** Two Citations, one key → one block (T-3). Same key on two record lines of one Source → a block under each (T-3). A key with an empty full → no block (T-3). Two blocks on one line → first-appearance order (T-3).
- **Removed inputs.** A Citation missing from the reply → no piece (T-3). An Observation with no label, no key and no value → no piece (T-5). An Unpromoted record → its line and blocks go with the claims; the held key covers the others (T-6).
- **Real data.** None — no table or seed drives a rule here; the seed's formats only decide which Citations render a full, which `isFormatted` reads.
- **Untrusted size.** The ids are bounded by the person's claims (Scale 300); past 2,000 the engine refuses (D-12). Pieces per block are bounded by the record's Observations; duplicates are dropped by text (D-5).

### Schema

None — no catalog change.

### Go core

None — S15-16 shipped the render; the claims read already carries the Observations.

### FFI

None — `RenderCitations` exists.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Record lines and rows | `PersonSourcesRowView`, `PersonSourcesLineView` | `Features/Conclusions/PersonSourcesSection.swift` | D-8; brief SC-10, SC-11 |
| Citation block | `PersonSourcesCitationView` *(new)* | same file | D-8; brief SC-1 – SC-3, SC-9, SC-W1 |
| Formatted citation | `CatalogCitationRender.styled` + `PVTitleText.italicizingEmphasis` | `Platform/CitationLineDisplay.swift`; `DesignSystem/Components/TitleText/` | Unchanged |
| Copy Full / Short | `PVCitationCopyButtons` *(new recipe)* | `DesignSystem/Recipes/CitationCopy/` *(new)* | D-7; brief SC-4 |
| Failed notice | `PVRetryCallout` | `DesignSystem/Components/Callout/` | D-9; brief SC-7 |
| Host | `PersonSourcesCitationsHost` *(new)* | `Features/Conclusions/` | D-3, D-4 |

Frames: the brief's § 5 (1a / 1b, 2 – 6), to be named on the **Board** line when agreed.

States: loading (rows, no blocks), failed (callout, rows, no blocks), ready (blocks); refetch keeps blocks; no claims → the section's empty state. Accessibility: the citation's plain text, the pieces line's comma-joined label, the copy buttons' labels and announcements, the callout's announcement (D-8, D-9, D-11). Previews: in `PersonSourcesPreviewData`, `johannRenders` *(new)* gives Johann's Citations a census render (full and short), two page renders without short, and leaves the address book's unrendered; new previews "Citations" (content `.citing(johannRenders)`), "Citations, Wide" (2296) and "Citations failed" (`citationsLoad: .failed("…")`).

### Strings

L10n keys *(new)* as D-11. Moved as D-7 (old `provenanceSheet.copyWordFull`, `copyWordShort`, `copyWordCitation`, `copyFullCitation`, `copyShortCitation`, `copyCitation`, `fullCitationCopied`, `shortCitationCopied`, `citationCopied` → `citationCopy.*`).

## 7. Steps

**STEP-1 — The section's key and the shared render helpers.**
Files: `macos/App/Platform/GenealogyStore.swift`, `macos/App/Features/Workspace/Session/CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `CatalogLastUpdated.swift`, `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`, `macos/ProvenenciaTests/WorkspaceSessionTests.swift`. Skill: `add-workspace-place`.
Do: D-1, D-2. A registry test that lists every `Kind` gains `.personSourcesCitations`.
Check: T-1, T-2 pass; `ProvenanceSheetTests` and `provenanceSheetKeySortsAndFollowsInputs` still pass.

**STEP-2 — The copy track becomes a recipe.**
Files: `macos/App/DesignSystem/Recipes/CitationCopy/PVCitationCopyButtons.swift` *(new)*, `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordRow.swift`, `PVProvenanceColumns.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-7. No visible change on the sheet.
Check: T-8 passes; `ProvenanceSheetTests.copyButtonsFollowTheRender` and `PVProvenanceColumnsTests` pass unchanged; `rg "ProvenanceSheet\.(copyWord|copyFull|copyShort|copyCitation|fullCitationCopied|shortCitationCopied|citationCopied)" macos` prints nothing.

**STEP-3 — Content carries pieces and groups them by citation.**
Files: `macos/App/Features/Conclusions/PersonSourcesContent.swift`, `macos/App/Platform/L10n.swift`, `Localizable.xcstrings`, `macos/ProvenenciaTests/PersonSourcesContentTests.swift`. Skills: `add-localized-string`, `add-swift-test`.
Do: D-5, D-6, D-11 (piece keys).
Check: T-3, T-4, T-5 pass; existing `PersonSourcesContentTests` pass.

**STEP-4 — The section holds its citations read.**
Files: `macos/App/Features/Conclusions/PersonSourcesCitationsHost.swift` *(new)*, `macos/App/Features/Conclusions/PersonSourcesSection.swift` (`PersonSourcesSection` draws the host), `macos/ProvenenciaTests/PersonSourcesCitationsTests.swift` *(new)*. Skill: `add-workspace-place`, `add-swift-test`.
Do: D-3, D-4.
Check: T-6, T-7 pass.

**STEP-5 — The section draws blocks and the failed notice.**
Files: `macos/App/Features/Conclusions/PersonSourcesSection.swift` (`PersonSourcesList`, `PersonSourcesRowView`, `PersonSourcesCitationView` *(new)*, `PersonSourcesColumns`), `macos/App/Features/Conclusions/PersonSourcesPreviewData.swift`, `L10n.swift`, `Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-8, D-9, D-10, D-11 (failed title); the previews of § 6 macOS.
Check: build with no Swift warning; the "Citations", "Citations, Wide" and "Citations failed" previews draw the brief's frames 1a, 1b and 3; existing tests pass.

**STEP-6 — Docs.**
Files: `docs/catalog-caches.md` (the "Per-view query results" row gains "`personSourcesCitations` is held only while the Person page's Sources section is shown, keeps the previous key's value until the new one answers, and is released then or when the section goes; it follows its inputs"), `docs/macos-client-patterns.md` (cache contract item 2: "(`ProvenanceSheetHost`, `PersonSourcesCitationsHost`)", and "a view that draws the old key's value until the new one answers holds it with `CitationKeyHold` and releases it then"), `.agents/skills/add-workspace-place/SKILL.md` ("View-held key" row: the same sentence), `macos/App/Features/Workspace/Session/WorkspaceSession.swift` (`release`'s doc: "the provenance sheet, the Sources section's citations"), `docs/deployment-plan/spike-15/deployment-plan.md` (map row status `Landed [#N](…)`), `docs/deployment-plan/spike-15/completed.md`, this plan, the brief → `design/archive/`, `design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-22-person-sources-citations.md` passes; `scripts/check-guidance-names.py` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log`. No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` `personSourcesCitationsKeySortsAndFollowsInputs` *(new)* | `personSourcesCitations(citationIds: ["b","a","a",""])` has ids `["a","b"]`; a reply holding id a twice builds one entry; with `renderCitationsInputs.sources = ["s1"]`, query and settle, then `session.apply(CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .sourceRecords, ids: ["s1"])]))` → a second store call is logged | D-2 |
| T-2 | Swift | `macos/ProvenenciaTests/ProvenanceSheetTests.swift` `renderHelpersIndexAndTestFormat` *(new)* | `CatalogRenderedCitations` with a, b, a → `byID` keys a, b, a's first entry kept; `isFormatted` true for full runs, false for empty; `Record.isFormatted` follows it | D-1 |
| T-3 | Swift | `macos/ProvenenciaTests/PersonSourcesContentTests.swift` `citingGroupsALinesCitationsByKey` *(new)* | Line o1(c1), o2(c2), o3(c3); c1, c2 `full:K`, c3 `full:L` → blocks [K: o1, o2], [L: o3]; c2 full empty → [K: o1], [L: o3]; c2 missing → same; all unformatted → `[]`; two lines of one Source with `full:K` → a block under each; a block's `rendered` is c1's | D-5, AC-1.1, AC-1.6, AC-1.7 |
| T-4 | Swift | `PersonSourcesContentTests.swift` `citationIDsCoverFoldedLines` *(new)* | Seven lines and 51 Sources (folds closed), Observations with ids incl. "" and repeats → `citationIDs` holds every non-empty id once, first appearance, folded lines included; unfolding leaves `citationIDs` equal; `citing([:])` equals the content | D-5, AC-3.4 |
| T-5 | Swift | `PersonSourcesContentTests.swift` `piecesReadPropertyAndValue` *(new)* | Name "Johann Weber" → "Name Johann Weber"; negative Birthplace "Bremen" → "Birthplace not Bremen"; Likeness with no text → "Likeness"; empty label, key `occupation`, "Cooper" → "occupation Cooper"; empty label, empty key → nil; two Observations of one block both "Age 34" → one piece | D-6, AC-1.3, AC-1.4, AC-1.5 |
| T-6 | Swift | `macos/ProvenenciaTests/PersonSourcesCitationsTests.swift` `holdKeepsTheLastValueUntilSettled` *(new)* | `move(from: k1, oldHasValue: true)` → nil, held k1; `move(from: k2, oldHasValue: true)` → k1, held k2; `move(from: k3, oldHasValue: false)` → k3, held k2; `settle()` → k2, held nil; `all(current: k4)` → [k4] | D-4, AC-3.5 |
| T-7 | Swift | `PersonSourcesCitationsTests.swift` `sectionCitationsLoadFailAndReadAgain` *(new)* | FakeStore held → `query(key).read.formLoadState` `.loading`, one call with the asked ids; `renderCitationsError` → `.failed(L10n.Errors.message(for:))`; clear the error, `reread` → value; `release` → `queryHandle(key)` nil | D-2, D-3, AC-3.1, AC-3.2, AC-3.3, AC-3.6 |
| T-8 | Swift | `macos/ProvenenciaTests/ProvenanceSheetTests.swift` `citationCopyButtonsFollowTheRender` *(new)* | `PVCitationCopyButtons.formatted` of a render with full and short → kinds [.full, .short], texts the plains, both with `rich` whose italic run is `.emphasized`; empty short → [.full]; `line("x")` → [.citation], `rich` nil | D-7, AC-1.2, AC-2.1, AC-2.2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PersonSourcesContentTests` (`Line` gains fields), `ProvenanceSheetTests`, `PVProvenanceColumnsTests`, `CatalogQueryRegistryTests` (a test that walks every `Kind`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`L10n.ProvenanceSheet.copyWordFull`, `copyWordShort`, `copyWordCitation`, `copyFullCitation`, `copyShortCitation`, `copyCitation`, `fullCitationCopied`, `shortCitationCopied`, `citationCopied`; `PVProvenanceRecordRow.Copy`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/catalog-caches.md, docs/macos-client-patterns.md (cache contract item 2), add-workspace-place "View-held key"
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project made after S15-19 (the seeded census type). On a census Source enter its jurisdiction and ED; on one household graph enter dwelling, family, line and item; draw five Citations on Ada Robins's row (name, age, birthplace, occupation, relationship) with an Observation each; promote her. Add a record for her from a Source whose type has no format.
2. Open Ada's Person page, Sources. The rows draw at once; under the census record line one citation in italics where the format italicizes, with "Name … · Age … · Birthplace … · Occupation … · Relationship …" beneath it, and Full and Short beside it (bar 7, AC-1.2). The other Source's record line has no block (AC-1.6).
3. Click Full; paste into TextEdit (rich): the italics hold. Short pastes the short form (AC-2.1).
4. Unpromote a record from another Source: the census block stays drawn, with no blink (AC-3.5).
5. Open the census graph from its record line, then Back: the line has the keyboard and is in view with its block drawn (AC-3.7).
6. Resize past 1600pt: the citation keeps its measure and wraps to fewer lines; the copy track follows its text.
7. With VoiceOver: the citation reads its text, the pieces read with pauses, the buttons speak their labels and announce the copy.
8. Open a provenance sheet: its Full, Short and Copy buttons look and copy as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The blocks push the scroll when they arrive on a visit | The restore waits for them (D-10); a first visit starts at the top |
| A held key never settles because the new key's read hangs | The hold releases on `onDisappear` too (D-3) |
| The board draws a heading, count, link or skeleton for a block | Brief non-goals; a board change goes to the user before this plan moves to Planned |

**Stop and report if:**

- `RenderCitationsResponse`, `CatalogRenderedCitation` or `CatalogPersonClaim.observations` no longer match § 4.
- `conclusionAnchorRestore` restores before `isReady` turns true, or never restores when `isReady` starts false (D-10).
- `ConclusionPageSectionHost`'s content closure can draw `PersonSourcesCitationsHost` with no claims value (Edges).
- Moving the copy track changes the sheet's layout in its previews or `PVProvenanceColumnsTests` (D-7).
- The agreed S15-D15 board differs from a Decision here (then the plan is refreshed first).

## 12. Open questions

None. (Status is Blocked on the board, not on a question.)

## 13. PR

**Title:** S15-22 — The Sources section groups a Source's Citations by citation
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-22-person-sources-citations.md`.
