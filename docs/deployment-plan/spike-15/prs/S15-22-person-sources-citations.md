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
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (a `CatalogQueryKey` kind, its descriptor, `followsInputs`, a view-held key, the Conclusions retry notice), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md) (promoting the copy track to a recipe), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/versioning.mdc`; [`docs/design-system-layers.md`](../../../design-system-layers.md) (a recipe never names a `Features/` type); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) cache contract items 2 and 5; `add-workspace-place` "Stale-while-revalidate" (a Conclusions reader draws `PVRetryCallout(title:message:handle:id:onRetry:)`)
**Context:** working rules "Grouping is by the rendered full citation, computed when read", "Citations render on demand, from SQL", "One engine, in Go", "Build on Spike 16's caches", "One window; nothing is built for a second" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); map § 6.9 "One EE citation, many Provenencia Citations" and § 6.10 ("Copying a note stays where notes are used") in [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md); landed plans [`S15-21-provenance-sheet-citations.md`](S15-21-provenance-sheet-citations.md) (D-1 – D-4, D-7, D-9, D-11: the store method, the view-held key, the grouping, the copy track) and [`S15-05-person-sources-date.md`](S15-05-person-sources-date.md); [`docs/catalog-caches.md`](../../../catalog-caches.md)
**Planned:** 2026-11-21 against `main` @ `496ffa9` (compare with `origin/main` after `git fetch origin main`)
**Review:** [`S15-22-person-sources-citations.review.md`](S15-22-person-sources-citations.review.md) — Fits with changes / Not ready → fixed, 1 round (2026-11-21); one To user item (the retry word)

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

In the Person page's Sources section, each record reads its citation: under the record line, the full citation the engine renders from the Source, its Artifact and the Evidence graph, with its italics, shown **once** for all the record's Citations that render the same full citation, with the pieces beneath it (what each of those Citations says about the person: "Name Johann Weber · Age 34 · Birthplace Bremen") and the provenance sheet's Full and Short copy buttons beside it. The citations are fetched when the section appears, through one cached read held only while the section is shown; the rows do not wait for it, and a failure shows one notice with a retry. This is bar 7 in the Sources section ("One household, one citation").

**Why now.** The render (S15-16), the sheet's use of it with the store method, the styled text, the labelled copy buttons and the view-held key (S15-21), and the section's date (S15-05) have landed. The section is the second and last screen of slice 6.

**What stays.** The caption line, the Source cells, the record lines and Unpromote, the folds, the record links diagram and its highlight, the section's own loading, error and empty states. A record whose type has no full format draws as today (user, 2026-11-21). The claims read and the Go engine are unchanged. The provenance sheet looks and behaves as today; its host moves onto the shared view-held query (D-3) and its copy track onto the recipe (D-7).

## 2. User stories

**US-1.** As a researcher, on a person's Sources section, I read each record's citation once, with its pieces beneath it, so that the five Citations of one household row read as one citation.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A record with Observations o1 (Citation c1), o2 (c2), o3 (c3); renders c1 and c2 key `full:K`, c3 key `full:L`, all with full runs | Under the record line, two blocks in this order: K's citation with the pieces of o1 and o2; L's citation with the piece of o3 |
| AC-1.2 | K's full runs `"Hamburg, Germany, 1867 census, …; digital image, "`, `"Nordarchiv Online"` (italic), `" (… : accessed 12 March 2025)"` | The block draws those runs, "Nordarchiv Online" in italic; VoiceOver reads the plain text |
| AC-1.3 | o1 is Name "Johann Weber", o2 is Age "34" | The pieces line reads "Name Johann Weber · Age 34" and is spoken as `L10n.DesignSystem.spokenJoin` of the two pieces |
| AC-1.4 | A negative Observation, Birthplace "Bremen"; an Observation with no text value, Likeness; an Observation with an empty property label and key `occupation`, "Cooper" | Pieces "Birthplace not Bremen", "Likeness", "occupation Cooper" |
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
| AC-3.1 | The section appears with at least one Citation id; the render has not answered (`FakeStore.renderCitationsHold`) | The rows draw with no blocks and no notice; one `renderCitations` call carries the distinct Citation ids of every claim, folded or not. With no ids, no call is made (the store's empty reply) |
| AC-3.2 | The render fails (`FakeStore.renderCitationsError`) and nothing is drawn from an earlier key | One compact danger callout titled "Citations could not be read" with the error's message and the Conclusions retry button sits under the caption line; the rows draw with no blocks |
| AC-3.3 | Retry after AC-3.2, the store now succeeding | The key is read again; the callout goes; the blocks draw |
| AC-3.4 | Unfolding a Source's lines or the Sources' Show more | No new `renderCitations` call (the key already holds every claim's ids) |
| AC-3.5 | An Unpromote removes one record; the claims read reloads, so the key's ids change | The remaining records' blocks stay drawn from the old key, including in the first frame after the change, until the new key answers; then they draw from it and the old key is released. If the new key fails instead, the old key is released, no block draws, and AC-3.2's callout shows |
| AC-3.6 | The section disappears (another section, another place) | Its keys are released; appearing again calls `renderCitations` again |
| AC-3.7 | Back to a record line on this page | The keyboard and scroll land on that line after the citations answered or failed, not before |

## 3. Scope

| In | Covered by |
| --- | --- |
| `CatalogRenderedCitation.isFormatted`, `CatalogRenderedCitations.byID`, `CitationGroups.gather`, `CatalogObservation.displayLabel`; the sheet, its record and the graph card use them (D-1, D-6) | STEP-1, T-2 |
| The section's key `CatalogQueryKey.personSourcesCitations`, its value `CatalogRenderedCitations` (D-2) | STEP-1, AC-3.1 |
| One view-held query `HeldQuery` with `HeldQueryKey`; `ProvenanceSheetHost` moves onto it (D-3, D-4) | STEP-2, AC-3.5, AC-3.6 |
| The copy track promoted to the recipe `PVCitationCopyTrack`, its strings to `L10n.CitationCopy` (D-7, brief SC-4) | STEP-3, AC-2.1, AC-2.2 |
| Content: pieces, every claim's Citation ids, `citing(_:)` (D-5, D-6, brief SC-2, SC-3, SC-5) | STEP-4, AC-1.1, AC-1.3 – AC-1.7, AC-3.4 |
| The section holds its read; `PersonSourcesList` takes the citations read (D-8, D-10) | STEP-5, AC-3.1, AC-3.7 |
| The citation block and the failed notice (D-9, D-11, brief SC-1, SC-4, SC-6, SC-7, SC-9 – SC-11, SC-W1) | STEP-6, AC-1.2, AC-2.1, AC-3.2, AC-3.3 |
| Docs: catalog caches, client patterns, `add-workspace-place`, completed, map, brief | STEP-7 |

| Out | Home |
| --- | --- |
| Today's citation line for a record whose type has no full format | not planned (user, 2026-11-21: nothing new under such a line; the claims read lacks the line's Artifact label, Citation label and page) |
| Citation labels and refs as the pieces | not planned (user, 2026-11-21: the pieces are the Observations) |
| Gathering one citation across two record lines of one Source | not planned (user, 2026-11-21: blocks sit under each record line; Edges) |
| A count, heading, card or disclosure per block; a link on the citation text | not planned (brief § 2.1) |
| A list-form (source-list entry) copy word, label and announcement | S15-23 (its copy is S15-D19's; D-7) |
| Re-ordering Sources | not planned (map scope entry) |
| The provenance sheet's fold and records on open | S15-27, S15-29 |
| Batching more than 2,000 Citation ids per call | not planned (Scale is 300 per section; D-12) |
| Caching renders past the section | not planned (rule "Citations render on demand, from SQL") |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Section | `macos/App/Features/Conclusions/PersonSourcesSection.swift` `PersonSourcesSection` | `ConclusionPageSectionHost<CatalogPersonClaims, PersonSourcesContent.Inputs, PersonSourcesContent, PersonSourcesList>` builds `PersonSourcesContent(groups:sourceTypes:orders:folds:)` in `make` and draws `PersonSourcesList(content:entityId:accessibilityIdentifierRoot:open:expand:unpromote:beginUnpromote:confirmUnpromote:)`. The host's content closure runs only with a claims value |
| List | same file `PersonSourcesList` | `rows`: `header`, a strong `PVDivider`, `PersonSourcesRowView` per row, the rows' Show more; `.conclusionAnchorRestore([.sourceTitle, .sourceLine], isReady: true, focus: $focus) { content.anchorTarget(for: $0) }`; `.onChange(of: content)` applies pending focus after Unpromote and clears a stale hover |
| Row and line | same file `PersonSourcesRowView.lines`, `PersonSourcesLineView` | A `VStack` of `PersonSourcesLineView` (`.id(line.id)`) and the line fold's `ConclusionShowMoreRow`, indented `PersonSourcesColumns.lineIndent` (16); the line pads 2pt vertical, `PVSpacing.space2` horizontal, wears `personSourcesHighlight` and `.onHover`; the line joins its parts with `Text(verbatim: " · ")` between differently styled `Text`s |
| Columns | same file `PersonSourcesColumns` | `spacing`, `typeWidth` 176, `dateWidth` 120, `refWidth` 104, `lineIndent` 16, `citationMin` 200, `minWidth` |
| Content | `macos/App/Features/Conclusions/PersonSourcesContent.swift` `PersonSourcesContent`, `Row`, `Line`, `Inputs` | `let rows`, private `let revealed`, `foldedGraphs`, `hiddenSourceIDs`; one `init(groups:sourceTypes:orders:folds:)` builds every `Line` by its memberwise init inside `groups.map`; no citations |
| Claims | `macos/App/Platform/GenealogyStore.swift` `CatalogPersonClaim` | `observations: [CatalogObservation]`, each with `citationID`, `propertyKey`, `propertyLabel`, `polarity`, value fields |
| Observation text | `macos/App/Platform/ObservationValueDisplay.swift` `ObservationValueDisplay.string(for:locale:orders:)`; `macos/App/Features/EvidenceGraph/EvidenceCitedPropertyMarks.swift` `isNegated(_:)`; `macos/App/Features/EvidenceGraph/EvidenceCardView.swift` (line 461: `label.isEmpty ? observation.propertyKey : label`) | The value as the graph card draws it; the negative test; the card's inline label fallback |
| Negative wording | `macos/App/Platform/L10n.swift` `L10n.Conclusions.readAsNot(_:)` ("not %@"), read by `macos/App/Platform/ReconciledValueDisplay.swift` | How the sheet words a negative record |
| Joins | `L10n.DesignSystem.spokenJoin(_ parts: [String])` (returns `String?`); `L10n.Conclusions.lineJoin(first:rest:)` ("%1$@ · %2$@") | The app's spoken and secondary-line joins |
| Render types | `macos/App/Platform/GenealogyStore.swift` `CatalogRenderedCitation`, `CatalogRenderedCitations { citations; inputs }`, `CatalogProvenanceSheetRead` | The sheet's read builds its dictionary in its `init` with `uniquingKeysWith: { first, _ in first }` |
| Sheet grouping | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` `grouped(by:)`, `Record.isFormatted` | A `position: [String: Int]` gather by `rendered?.groupKey ?? "record:<id>"` per value run; `isFormatted` = `rendered?.full.runs.isEmpty == false` |
| Store | `GenealogyStore.renderCitations(projectDir:citationIDs:)` (empty ids → empty value, no call); `macos/App/Platform/FakeStore.swift` `renderCitationsReplies`, `renderCitationsInputs`, `renderCitationsHold`, `renderCitationsCalls`, `renderCitationsError` | Landed in S15-21 |
| Query keys | `macos/App/Features/Workspace/Session/CatalogQueryKey.swift` `Kind.provenanceSheet`, `provenanceSheet(project:citationIds:)`; `CatalogQueryRegistry.swift` `case .provenanceSheet`; `CatalogLastUpdated.swift` `CatalogPageValue` (requires `inputs`), `extension CatalogProvenanceSheetRead: CatalogPageValue {}` | The shape to copy |
| View-held key | `macos/App/Features/Conclusions/ProvenanceSheetHost.swift` `ProvenanceSheetHost`; `macos/App/Features/Workspace/Session/WorkspaceSession.swift` `release(_:)`; `WorkspaceSession+Derived.swift` `conclusionContent(_:inputs:extra:value:make:)` | The only view-held key: warms in `.task(id: key)`, reads `queryHandle`, releases the old key on `onChange(of: key)` and on `onDisappear`; groups through `conclusionContent`. `release`'s doc names one holder |
| Copy track | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordRow.swift` `citation` (the `HStack(alignment: .citationFirstLineCenter, …)` with both alignment guides), `Copy`, `copies(for:)`, `copyButton(_:)`, private `VerticalAlignment.citationFirstLineCenter`; `PVProvenanceColumns.swift` `copyTrackWidth` **84**, `copyTrackSpacing` 8; `macos/ProvenenciaTests/PVProvenanceColumnsTests.swift` asserts both | Private to the row; words and labels from `L10n.ProvenanceSheet.copyWordFull`, `copyWordShort`, `copyWordCitation`, `copyFullCitation`, `copyShortCitation`, `copyCitation`, `fullCitationCopied`, `shortCitationCopied`, `citationCopied` |
| Retry notice | `macos/App/Features/Workspace/Session/QueryHandle+RetryCallout.swift` `PVRetryCallout.init(title:message:handle:compact:id:onRetry:)` | The Conclusions notice: "Try again" (`L10n.Conclusions.readNoticeTryAgain`), `isReading`, `failureRevision`, id `\(id).tryAgain`; `ConclusionPageSectionHost` uses it |
| Anchor | `macos/App/Features/Conclusions/ConclusionAnchorRestore.swift` `conclusionAnchorRestore(_:isReady:focus:…)` | Restores once per mount after `isReady` |
| Measures | `macos/App/DesignSystem/Tokens/PVSpacing.swift` `measureProse` 480, `measureNarrow` 340, `measureForm` 560 | Readable widths |
| Remount | `macos/App/Features/Workspace/Session/PlaceRegistry.swift` `.personDetail` `viewIdentity: { $0.entityId }` | Another person remounts the page |
| Previews | `macos/App/Features/Conclusions/PersonSourcesPreviewData.swift` `johannClaims`, `record(…)`, `previewSession`; `PersonSourcesSection.swift` `PersonSourcesPreview` | Every claim has `observations: []`; the census has two lines, the Konfirmandenbuch two lines |
| Tests | `macos/ProvenenciaTests/PersonSourcesContentTests.swift` (`nameObservation`, `claim(…)` helpers); `ProvenanceSheetTests.swift` `copyButtonsFollowTheRender`, `groupedGathersByEngineKeyWithinARun`; `CatalogQueryRegistryTests.swift` `provenanceSheetKeySortsAndFollowsInputs`; `WorkspaceSessionTests.swift` `releaseDropsTheKey`, `provenanceSheetLoadStates`; `CatalogFixtures.swift` `renderedCitation(_:key:full:short:)` | Cover the content, the sheet's copies and grouping, the sheet key, release |
| Docs | `docs/catalog-caches.md` "Per-view query results" row; `docs/macos-client-patterns.md` cache contract item 2 (`ProvenanceSheetHost`); `.agents/skills/add-workspace-place/SKILL.md` "View-held key" row | Describe the sheet's host as the view-held key |

**Precedent.** S15-21 ([#930](https://github.com/Jake-Robins-Studios/provenencia/pull/930)): copy its key (D-2), its view-held key (D-4) and its tests T-2, T-3, T-9, T-10. S15-05 ([#919](https://github.com/Jake-Robins-Studios/provenencia/pull/919)) promoted `PVPublishedDate` from a feature file to a recipe when it gained this section as a second caller; copy that move for the copy track.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **Shared render helpers** (in `macos/App/Platform/CitationLineDisplay.swift`, beside `styled`). `extension CatalogRenderedCitation { var isFormatted: Bool { !full.runs.isEmpty } }` *(new)*; `extension CatalogRenderedCitations { var byID: [String: CatalogRenderedCitation] }` *(new: `Dictionary(citations.map { ($0.citationID, $0) }, uniquingKeysWith: { first, _ in first })`)*; `enum CitationGroups { static func gather<T>(_ items: [T], by key: (T) -> String) -> [(key: String, items: [T])] }` *(new: one pass, a `[String: Int]` of first positions, runs in first-appearance order)*. `CatalogProvenanceSheetRead.init` sets `citations = reply.byID`; `Record.isFormatted` returns `rendered?.isFormatted == true`; `grouped(by:)` builds each value run's `citations` from `CitationGroups.gather(records, by: { $0.rendered?.groupKey ?? "record:\($0.id)" })` | Two screens test "formatted", index a reply and gather by the engine's key: one home for each, so S15-27's fold and any change to the rule touch one function | A copy of each in the section — the sheet's and the section's grouping would drift |
| D-2 | **Key and value.** `CatalogQueryKey.Kind.personSourcesCitations` *(new)*; `static func personSourcesCitations(project:citationIds:)` *(new)*, ids = the distinct non-empty ids, sorted, as `provenanceSheet`. Its value is `CatalogRenderedCitations` itself: `extension CatalogRenderedCitations: CatalogPageValue {}` *(new, in `CatalogLastUpdated.swift`)*. Descriptor: `.make(kind:, refreshes: CatalogQueryRefresh.followsInputs(CatalogRenderedCitations.self), load: { key, store in try await store.renderCitations(projectDir: key.project.projectDir, citationIDs: key.ids) })`; default `whenHidden`; no `invalidateOn`, no patches. It is not in `ConclusionPageSection.reads` | A screen's renders are its own key (S15-21 D-2: "S15-22 gets its own key"; `release` does not count holders, and S15-29 grows the sheet's value). The reply already carries `inputs`, so no wrapper type. Its ids come from the claims value, which a static section read cannot know | Sharing `provenanceSheet`; a `CatalogPersonSourcesCitations` wrapper — a field-for-field copy of `CatalogProvenanceSheetRead`; a section read — needs the claims first |
| D-3 | **One view-held query.** `macos/App/Features/Workspace/Session/HeldQuery.swift` *(new)* holds `HeldQueryKey` (D-4), `struct HeldQueryRead<Value>` *(new)* `{ key: CatalogQueryKey (the current key); handle: QueryHandle<Value>? (the current key's); shownKey: CatalogQueryKey? (the key whose value is drawn); value: Value? (that key's value); var load: PVFormLoadState { value != nil ? .ready : handle?.read.formLoadState ?? .loading }; var settled: Bool { load != .loading } }`, and `struct HeldQuery<Value, Content: View>: View` *(new)*: `init(_ key: CatalogQueryKey, keepsPreviousValue: Bool = false, @ViewBuilder content: @escaping (HeldQueryRead<Value>) -> Content)`. It holds `@Environment(WorkspaceSession.self)` and `@State private var hold = HeldQueryKey()`. `body`: builds the read (`handle = session.queryHandle(key)`; `shownKey = hold.shown(current: key, currentHasValue: handle?.value != nil, keepsPrevious: keepsPreviousValue)`; `value` from `session.queryHandle(shownKey)`), draws `content(read)`, and adds `.task(id: key) { let _: QueryHandle<Value> = session.query(key) }`; `.onChange(of: key) { old, _ in if let r = hold.move(from: old, keepsPrevious: keepsPreviousValue) { session.release(r) } }`; `.onChange(of: currentSettled, initial: true) { _, settled in if settled, let r = hold.settle(key) { session.release(r) } }` where `currentSettled` is `handle.map { $0.value != nil || $0.read.formLoadState != .loading } ?? false` (the current key's own state, never the drawn one's); `.onDisappear { hold.all(current: key).forEach(session.release); hold = HeldQueryKey() }`. `ProvenanceSheetHost` moves onto it: `HeldQuery<CatalogProvenanceSheetRead, _>(key) { read in PVProvenanceSheet(content: grouped(read), …, load: read.load, onReadAgain: { … session.reread(read.key) }) }`, its own `.task`, `.onChange` and `.onDisappear` going | One mechanism owns "warm, read, release when the key moves or the view goes", so the next view-held screen passes a flag instead of copying host code, and the docs name it once (review M-1) | A second hand-written host with its own hold — two lifecycles to keep in step |
| D-4 | **The hold.** `struct HeldQueryKey: Equatable` *(new, pure)*: `private(set) var drawn: CatalogQueryKey?` (the last key that settled). `func shown(current:currentHasValue:keepsPrevious:) -> CatalogQueryKey?`: `current` when `currentHasValue`; else `drawn` when `keepsPrevious` and `drawn != current` and `drawn` is set; else nil. `mutating func move(from old: CatalogQueryKey, keepsPrevious: Bool) -> CatalogQueryKey?`: when `keepsPrevious && old == drawn`, nil (kept for its value); else `old` (and `drawn = nil` when it was `old`). `mutating func settle(_ current: CatalogQueryKey) -> CatalogQueryKey?`: the previous `drawn` when it is set and not `current`, else nil; then `drawn = current`. `func all(current:) -> [CatalogQueryKey]`: `current`, then `drawn` when set and different | Brief SC-8: an Unpromote changes the ids and a new key reads nil at once. `shown` reads `drawn`, which is set before the key moves, so even the first frame after the move draws the old value (review X-4). Settling is the current key's own state, so it fires when the new key answers or fails (review X-3). A failure settles too: the old key goes and the notice shows (AC-3.5). With `keepsPrevious: false` it behaves as the sheet's host today | Settling on the drawn load state — never changes while a held value is drawn; a `@State` copy of the value — cache contract item 5 |
| D-5 | **Content.** `PersonSourcesContent.rows` becomes `private(set) var`. It gains `let citationIDs: [String]` *(new)*, filled in `init` from every group's every claim's Observations (folded or not): non-empty `citationID`s, distinct, first appearance. `Line` gains `var observed: [Observed] = []` *(new; `struct Observed: Equatable { var citationID: String; var piece: String }`)*, passed to the `Line(…)` memberwise call inside `init` as `claim.observations.compactMap { o in Self.piece(for: o, orders: orders).map { Observed(citationID: o.citationID, piece: $0) } }`, and `var citations: [Citation] = []` *(new; `struct Citation: Equatable, Identifiable { var id: String (the group key); var rendered: CatalogRenderedCitation (the first Citation's render); var pieces: [String] }`)*. `func citing(_ renders: [String: CatalogRenderedCitation]) -> PersonSourcesContent` *(new, pure)*: `var copy = self`; for each shown line, keep the `observed` whose `renders[citationID]?.isFormatted == true`, `CitationGroups.gather(kept, by: { renders[$0.citationID]!.groupKey })`, and make one `Citation` per run: `rendered` = the run's first entry's render, `pieces` = the run's pieces with repeats dropped (first kept). A line with none keeps `[]`. Swift adds no rule of its own about which keys group | Rule "Grouping is by the rendered full citation, computed when read"; rule "One engine, in Go": the engine's key decides. The key covers folded lines, so unfolding never re-keys (AC-3.4). `citing` runs once per drawn value through `conclusionContent` | Grouping across a Source's record lines — user, 2026-11-21: blocks under each record line; a second init — the folds and anchors are built once |
| D-6 | **Piece.** `extension CatalogObservation { var displayLabel: String }` *(new, in `macos/App/Platform/ObservationValueDisplay.swift`)*: `propertyLabel` trimmed, else `propertyKey`; `EvidenceCardView` (line 461) reads it in place of its inline fallback. `static func piece(for observation: CatalogObservation, orders: NameFormatOrders) -> String?` *(new, on `PersonSourcesContent`)*: label = `displayLabel`; an empty label → nil (no piece); value = `ObservationValueDisplay.string(for:orders:)` trimmed; when negative (`EvidenceCitedPropertyMarks.isNegated`) value = `L10n.Conclusions.readAsNot(value)`, or the label alone when the value is empty; an empty value → the label alone; else `L10n.Conclusions.sourcesPiece(property:value:)` = "%1$@ %2$@" | User, 2026-11-21: the pieces are the Observations, from data the claims read already carries; the graph card's value text and the sheet's negative wording, so the section words a record as they do; one label rule | Citation labels — not in the claims read; a second "not" string — `readAsNot` exists |
| D-7 | **Copy track recipe.** `PVCitationCopyTrack<Citation: View>` *(new, `macos/App/DesignSystem/Recipes/CitationCopy/PVCitationCopyTrack.swift` (new))* owns the pairing: `init(_ copies: [Copy], idPrefix: String, textSize: CGFloat, @ViewBuilder citation: () -> Citation)`; its body is the row's `HStack(alignment: .citationFirstLineCenter, spacing: trackSpacing)` of the citation (with the first-line guide at `textSize`) and the `VStack(alignment: .leading, spacing: PVSpacing.space1)` of `PVClipboardButton`s framed `minWidth: trackWidth` with its guide; ids `\(idPrefix).copyFull`, `.copyShort`, `.copy`. `static let trackWidth: CGFloat = 84`, `trackSpacing: CGFloat = 8` (moved with their comment); `VerticalAlignment.citationFirstLineCenter` is private to the file. `struct Copy: Equatable` moves from `PVProvenanceRecordRow` (same `Kind` `.full`, `.short`, `.citation`, `text`, `rich`); `nonisolated static func formatted(_ rendered: CatalogRenderedCitation) -> [Copy]` (full, then short when its runs are non-empty); `nonisolated static func line(_ text: String) -> [Copy]` (`[.citation]`). `PVProvenanceRecordRow.copies(for:)` stays and returns `record.isFormatted ? .formatted(rendered) : .line(record.citation.line)`; the row's citation becomes `PVCitationCopyTrack(Self.copies(for: record), idPrefix: "\(idPrefix).\(record.id)", textSize: PVTypeScale.bodySmall) { PVInkLink(…) }`. `PVProvenanceColumns.copyTrackWidth` and `copyTrackSpacing` are deleted; `PVProvenanceColumnsTests` asserts `PVCitationCopyTrack.trackWidth == 84` and `trackSpacing == 8` instead. The nine copy strings move to `L10n.CitationCopy` *(new namespace, placed after `L10n.ProvenanceSheet`)*: `wordFull`, `wordShort`, `wordCitation`, `copyFull`, `copyShort`, `copyCitation`, `fullCopied`, `shortCopied`, `citationCopied`, keys `citationCopy.*`, same English; the old `provenanceSheet.*` entries leave `Localizable.xcstrings` | Brief inventory: a second caller promotes the track (as S15-05 promoted `PVPublishedDate`); the recipe owns the alignment, the widths and its words, so neither caller reassembles them (review M-6) | Drawing two `PVClipboardButton`s in the section — a near-copy; exporting the alignment guide — two hand-built pairings; keying `Kind` on `CitationForm` now (review M-5) — needs list-form copy that S15-D19 decides for S15-23 |
| D-8 | **The section holds its read.** `PersonSourcesSection`'s host content closure draws `PersonSourcesCitations` *(new, private view in `PersonSourcesSection.swift`)*, which takes the content and the list's other arguments and draws `HeldQuery<CatalogRenderedCitations, _>(.personSourcesCitations(project: session.projectKey, citationIds: content.citationIDs), keepsPreviousValue: true) { read in PersonSourcesList(content: cited(read), …, citations: read) }`, where `cited(read)` is `read.value.map { value in session.conclusionContent(read.shownKey!, inputs: [read.shownKey!], extra: content, value: value) { value, content in content.citing(value.byID) } } ?? content`. `PersonSourcesList` gains `citations: HeldQueryRead<CatalogRenderedCitations>? = nil` *(new; nil in the previews that pass none)*. `.conclusionAnchorRestore(…, isReady: citations?.settled ?? true, …)` | Brief SC-6, SC-8; the shared mechanism (D-3) with the hold on | Querying in `PersonSourcesList` — previews draw it with no session reads |
| D-9 | **Block.** `PersonSourcesCitationView` *(new, private, in `PersonSourcesSection.swift`)* draws one `Line.Citation`: `VStack(alignment: .leading, spacing: PVSpacing.space1)` of `PVCitationCopyTrack(.formatted(citation.rendered), idPrefix: "\(root).citation.\(line.id).\(index)", textSize: PVTypeScale.bodySmall) { Text(PVTitleText.italicizingEmphasis(citation.rendered.full.styled, font: PVFont.body(size: PVTypeScale.bodySmall))).foregroundStyle(PVColor.textPrimary).textSelection(.enabled).fixedSize(horizontal: false, vertical: true).frame(maxWidth: PVSpacing.measureCitation, alignment: .leading).accessibilityLabel(citation.rendered.full.plain) }` and the pieces `Text(verbatim: <the pieces folded with L10n.Conclusions.lineJoin(first:rest:)>)` in `PVFont.body(size: PVTypeScale.caption)`, `PVColor.textSecondary`, `.frame(maxWidth: PVSpacing.measureCitation, alignment: .leading)`, `.accessibilityLabel(L10n.DesignSystem.spokenJoin(citation.pieces) ?? "")`. `PVSpacing.measureCitation: CGFloat = 680` *(new)*. In `PersonSourcesRowView.lines`, each line is a `VStack(alignment: .leading, spacing: PVSpacing.space2)` of `PersonSourcesLineView` and its blocks (`ForEach(Array(line.citations.enumerated()), id: \.element.id)`), the blocks padded `.leading` `PVSpacing.space2` (so the citation starts under the graph link's text) and `.bottom` `PVSpacing.space1`; `.id(line.id)` moves to that `VStack`. The highlight and `.onHover` stay on `PersonSourcesLineView` only; the blocks have no hover handler, so moving the pointer onto a block clears the line's hover as moving off the line does today. The copy buttons take no `PersonSourcesFocus` stop: Tab reaches them in the system order after the line's Unpromote | Brief SC-1 – SC-4, SC-9 – SC-11, SC-W1; a snowflake, the section's only block. A readable width is a token (review M-9) | A recipe for the block — one call site; a link on the citation — a block spans several Citations (brief § 2.1); literal separators — the app's joins exist (review M-8) |
| D-10 | **Failed notice.** In `PersonSourcesList.rows`, after the strong `PVDivider` under the caption line and before the first row, inside the rows `VStack`: when `citations?.value == nil` and `citations?.load` is `.failed(message)` and `citations?.handle` is set, `PVRetryCallout(title: L10n.Conclusions.sourcesCitationsFailedTitle, message: message, handle: handle, compact: true, id: "\(root).citations.error", onRetry: { let _: QueryHandle<CatalogRenderedCitations> = session.reread(citations.key) })` with `.accessibilityIdentifier("\(root).citations.error")`, padded `PVSpacing.space3` vertical. Loading draws nothing | `add-workspace-place` "Stale-while-revalidate": a Conclusions reader draws the handle init, which passes `isReading` and `failureRevision` (review M-2). Its word is the page's "Try again" | `PVFormLoadArea` — the rows do not wait on this read; the kit init with "Read again" — bends that skill row (To user: the review log) |
| D-11 | **Copy.** `L10n.Conclusions.sourcesCitationsFailedTitle` = "Citations could not be read", `sourcesPiece(property:value:)` = "%1$@ %2$@" *(new)*; D-7's `L10n.CitationCopy` keys. The retry word is `L10n.Conclusions.readNoticeTryAgain`; the failed message is the load state's (`L10n.Errors.message(for:)`) | Brief SC-2, SC-7, SC-9 | — |
| D-12 | **Size.** No chunking: more than 2,000 distinct ids is the engine's `citations.invalid`, shown as the failed notice | Scale is 300 citations per section | Splitting calls — code for a case past Scale |

**Rules this plan bends.** None. (D-10 follows `add-workspace-place` "Stale-while-revalidate"; the brief's SC-7 word follows it.)

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `isFormatted`, `byID`, `CitationGroups.gather` *(new)* | computed property, func | `Record.isFormatted`; `CatalogProvenanceSheetRead.init`; `PVProvenanceSheetContent.grouped(by:)` | They become the one home; the sheet's callers switch (D-1) |
| `CatalogObservation.displayLabel` *(new)* | computed property | `EvidenceCardView`'s inline fallback | The one rule; the card switches (D-6) |
| `Kind.personSourcesCitations` *(new)* | query key | `provenanceSheet` | Separate holder and lifetime; its value is the reply type, no wrapper (D-2) |
| `HeldQuery`, `HeldQueryRead`, `HeldQueryKey` *(new)* | view, type | `ProvenanceSheetHost`'s lifecycle | Extracted from it; the sheet moves onto it (D-3) |
| `PVCitationCopyTrack` *(new, moved)* | recipe | `PVProvenanceRecordRow`'s private copy track; `PVProvenanceColumns.copyTrack*` | Promoted on its second caller; the columns' constants go (D-7) |
| `L10n.CitationCopy` *(new namespace, moved keys)* | key | `L10n.ProvenanceSheet.copy*` | The recipe's own words (D-7) |
| `Line.Observed`, `Line.Citation`, `citationIDs`, `citing(_:)`, `piece(for:orders:)` *(new)* | type, func | `PVProvenanceSheetContent.CitationRun`, `grouped(by:)` | The section groups a record's Observations; the gather itself is shared (D-1) |
| `PersonSourcesCitations`, `PersonSourcesCitationView` *(new)* | view | `PVProvenanceRecordRow.citation` | The block is text, copy track and pieces with no links |
| `PVSpacing.measureCitation` *(new)* | token | `measureProse` 480, `measureForm` 560 | A citation line reads at 680; none of the measures fits |
| `L10n.Conclusions.sourcesCitationsFailedTitle`, `sourcesPiece` *(new)* | key | `L10n.ProvenanceSheet.citationsFailedTitle`; `readAsNot` (reused) | The section's notices live in its namespace |

**Builds on.** The query registry and `followsInputs`; `release` and `conclusionContent`; `CatalogCitationRender.styled` and `PVTitleText.italicizingEmphasis`; `PVClipboardButton(word:rich:)`; `PVRetryCallout`'s handle init; `ObservationValueDisplay`, `readAsNot`, `spokenJoin`, `lineJoin`.
**Deletes.** `ProvenanceSheetHost`'s own `.task`, `.onChange(of: key)` and `.onDisappear` (D-3); `PVProvenanceRecordRow.Copy`, its private `copyButton` functions and `VerticalAlignment.citationFirstLineCenter` (moved, D-7); `PVProvenanceColumns.copyTrackWidth` and `copyTrackSpacing` (D-7); the nine `L10n.ProvenanceSheet` copy keys and their `Localizable.xcstrings` entries (moved, D-7); the inline gather in `grouped(by:)` and the inline dictionary in `CatalogProvenanceSheetRead.init` (D-1); `EvidenceCardView`'s inline label fallback (D-6).
**Next adds.** S15-23's Copy source-list entry draws `PVCitationCopyTrack` or one `PVClipboardButton` with copy its brief S15-D19 names. S15-27 folds the sheet's `CitationGroups` runs. Another view-held read is one `HeldQuery`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| The claims reload and change the ids (Unpromote, a promote elsewhere) | `HeldQuery` with `keepsPreviousValue: true` | The old key keeps drawing until the new one settles, then is released; a failed new key releases it and shows the notice (D-4, AC-3.5) |
| Another person's page | `PlaceRegistry` `.personDetail` `viewIdentity: { $0.entityId }` | The page remounts, so the `HeldQuery` state starts fresh; the old page's `onDisappear` releases its keys |
| The sheet's key changes while open (a page refresh) | `ProvenanceSheetHost` on `HeldQuery` with `keepsPreviousValue: false` | As today: the old key is released at once and the new key reads loading (T-6 covers `move` with `keepsPrevious: false`) |
| A Citation deleted between the claims read and the render | `citing(_:)` | Missing from the dictionary → its Observations make no piece; a line left with none has no block (AC-1.6) |
| A section with no claims | `PersonSourcesSection` | The section's empty state draws as today; the host closure runs on content only |
| No Citation ids | `GenealogyStore.renderCitations` | An empty value, no call; no blocks, no notice |
| Section switch or leaving the page | `HeldQuery.onDisappear` | Releases current and drawn keys (AC-3.6) |

### Scale

At the map's Scale (30 Sources, up to 300 citations per section): one `RenderCitations` call per appearance (S15-16 measured 9 SELECTs at 300). `citationIDs` is one pass over the claims' Observations. `citing(_:)` is one pass over the shown lines' Observations, run once per drawn value through `conclusionContent`. A write that reaches the key's inputs while shown reloads it once and keeps the drawn value meanwhile. An Unpromote makes one new call. The key holds up to 300 ids, hashed once per query.

### Edges

- **Assumptions.** `ConclusionPageSectionHost`'s content closure draws only with a claims value, so `content.citationIDs` is the claims' (§ 4). `Line` equality now includes `citations`, so `PersonSourcesList.onChange(of: content)` also fires when the renders arrive; `applyPendingFocus` and the hover clear do nothing for unchanged claims (T-4 checks `citing([:])` equals the content). `grouped(by:)` keeps its output after moving onto `CitationGroups.gather` (`groupedGathersByEngineKeyWithinARun` stays green).
- **Neighbors.** Two Citations, one key → one block (T-3). Same key on two record lines of one Source → a block under each (T-3). A key with an empty full → no block (T-3). Two blocks on one line → first-appearance order (T-3). A held key with `keepsPrevious: false` → released at once (T-6).
- **Removed inputs.** A Citation missing from the reply → no piece (T-3). An Observation with no label and no key → no piece (T-5). An Unpromoted record → its line and blocks go with the claims; the drawn key covers the others until the new key settles (T-6).
- **Real data.** None — no table or seed drives a rule here; the seed's formats only decide which Citations render a full, which `isFormatted` reads.
- **Untrusted size.** The ids are bounded by the person's claims (Scale 300); past 2,000 the engine refuses (D-12). Pieces per block are bounded by the record's Observations; repeats are dropped (D-5).

### Schema

None — no catalog change.

### Go core

None — S15-16 shipped the render; the claims read already carries the Observations.

### FFI

None — `RenderCitations` exists.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Record lines and rows | `PersonSourcesRowView`, `PersonSourcesLineView` | `Features/Conclusions/PersonSourcesSection.swift` | D-9; brief SC-10, SC-11 |
| Citation block | `PersonSourcesCitationView` *(new)* | same file | D-9; brief SC-1 – SC-3, SC-9, SC-W1 |
| Formatted citation with Full / Short | `PVCitationCopyTrack` *(new recipe)* around `CatalogCitationRender.styled` + `PVTitleText.italicizingEmphasis` | `DesignSystem/Recipes/CitationCopy/` *(new)* | D-7; brief SC-1, SC-4 |
| Failed notice | `PVRetryCallout` handle init | `Features/Workspace/Session/QueryHandle+RetryCallout.swift` | D-10; brief SC-7 |
| View-held read | `HeldQuery` *(new)* | `Features/Workspace/Session/` | D-3, D-4, D-8 |

Frames: the brief's § 5 (1a / 1b, 2, 3a / 3b, 4 – 6), to be named on the **Board** line when agreed.

States: loading (rows, no blocks), failed (callout, rows, no blocks), ready (blocks); refetch keeps blocks; no claims → the section's empty state. Accessibility: the citation's plain text, the pieces' `spokenJoin`, the copy buttons' labels and announcements, the callout's announcement (D-9, D-10, D-11). Previews: in `PersonSourcesPreviewData`, `johannCitedClaims` *(new; `johannClaims` stays for the other previews)* holds the brief's § 5 data with Observations and Citation ids (census: one line, five Observations on five Citations; address book: one line, one Observation; Konfirmandenbuch: one line, three Observations on two pages' Citations), and `johannRenders` *(new)* gives the census Citations one render with full and short, the two pages one render each without short, and leaves the address book's out. `PersonSourcesPreview` gains `renders: [String: CatalogRenderedCitation]? = nil` and `citationsFailure: Bool = false`: with renders it draws `PersonSourcesList(content: content.citing(renders), …)`; with `citationsFailure` its `previewSession` sets `renderCitationsError` and it draws the whole `PersonSourcesSection`. New previews "Citations", "Citations, Wide" (2296) and "Citations failed".

### Strings

L10n keys *(new)* as D-11. Moved as D-7 (old `provenanceSheet.copyWordFull`, `copyWordShort`, `copyWordCitation`, `copyFullCitation`, `copyShortCitation`, `copyCitation`, `fullCitationCopied`, `shortCitationCopied`, `citationCopied` → `citationCopy.*`). Reused: `L10n.Conclusions.readAsNot`, `lineJoin`, `readNoticeTryAgain`; `L10n.DesignSystem.spokenJoin`.

## 7. Steps

**STEP-1 — Shared render helpers and the section's key.**
Files: `macos/App/Platform/CitationLineDisplay.swift`, `macos/App/Platform/GenealogyStore.swift` (`CatalogProvenanceSheetRead.init`), `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift`, `macos/App/Features/Workspace/Session/CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `CatalogLastUpdated.swift`, `macos/ProvenenciaTests/ProvenanceSheetTests.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift`. Skill: `add-workspace-place`.
Do: D-1, D-2. A registry test that lists every `Kind` gains `.personSourcesCitations`.
Check: T-1, T-2 pass; `groupedGathersByEngineKeyWithinARun` and `provenanceSheetKeySortsAndFollowsInputs` pass unchanged.

**STEP-2 — One view-held query; the sheet moves onto it.**
Files: `macos/App/Features/Workspace/Session/HeldQuery.swift` *(new)*, `macos/App/Features/Conclusions/ProvenanceSheetHost.swift`, `macos/ProvenenciaTests/HeldQueryTests.swift` *(new)*. Skills: `add-workspace-place`, `add-swift-test`.
Do: D-3, D-4.
Check: T-6 passes; `releaseDropsTheKey`, `provenanceSheetLoadStates` and `ProvenanceSheetTests` pass unchanged.

**STEP-3 — The copy track becomes a recipe.**
Files: `macos/App/DesignSystem/Recipes/CitationCopy/PVCitationCopyTrack.swift` *(new)*, `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceRecordRow.swift`, `PVProvenanceColumns.swift`, `macos/ProvenenciaTests/PVProvenanceColumnsTests.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-7. No visible change on the sheet (the track stays 84pt).
Check: T-8 passes; `copyButtonsFollowTheRender` passes unchanged; `PVProvenanceColumnsTests` passes with its two assertions moved; `rg "ProvenanceSheet\.(copyWord|copyFull|copyShort|copyCitation|fullCitationCopied|shortCitationCopied|citationCopied)|copyTrackWidth|copyTrackSpacing" macos` prints nothing; `rg '"provenanceSheet\.(copy|fullCitationCopied|shortCitationCopied|citationCopied)' macos/App/Resources/Localizable.xcstrings` prints nothing.

**STEP-4 — Content carries pieces and groups them by citation.**
Files: `macos/App/Platform/ObservationValueDisplay.swift`, `macos/App/Features/EvidenceGraph/EvidenceCardView.swift`, `macos/App/Features/Conclusions/PersonSourcesContent.swift`, `macos/App/Platform/L10n.swift`, `Localizable.xcstrings`, `macos/ProvenenciaTests/PersonSourcesContentTests.swift` (an `observation(_ citationID:, label:, key:, value:, polarity:)` helper beside `nameObservation`; `renderedCitation` from `CatalogFixtures.swift`). Skills: `add-localized-string`, `add-swift-test`.
Do: D-5, D-6, D-11 (`sourcesPiece`).
Check: T-3, T-4, T-5 pass; existing `PersonSourcesContentTests` pass.

**STEP-5 — The section holds its citations read.**
Files: `macos/App/Features/Conclusions/PersonSourcesSection.swift` (`PersonSourcesSection`, `PersonSourcesCitations` *(new)*, `PersonSourcesList`'s `citations` parameter and anchor), `macos/ProvenenciaTests/HeldQueryTests.swift`. Skill: `add-workspace-place`.
Do: D-8. The list does not draw blocks or the notice yet.
Check: build; T-7 passes.

**STEP-6 — The section draws blocks and the failed notice.**
Files: `macos/App/Features/Conclusions/PersonSourcesSection.swift` (`PersonSourcesList`, `PersonSourcesRowView`, `PersonSourcesCitationView` *(new)*, `PersonSourcesPreview`), `macos/App/Features/Conclusions/PersonSourcesPreviewData.swift`, `macos/App/DesignSystem/Tokens/PVSpacing.swift`, `L10n.swift`, `Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-9, D-10, D-11 (`sourcesCitationsFailedTitle`); the previews of § 6 macOS.
Check: build with no Swift warning; the "Citations", "Citations, Wide" and "Citations failed" previews draw the agreed frames 1a, 1b and 3a; existing tests pass.

**STEP-7 — Docs.**
Files: `docs/catalog-caches.md` (the "Per-view query results" row: "a view-held key (`HeldQuery`: `provenanceSheet`, and `personSourcesCitations`, which keeps the previous key's value until the new one answers) is released when its key moves or its view goes (`WorkspaceSession.release`); it follows its inputs"), `docs/macos-client-patterns.md` (cache contract item 2: "A key no place shows, held by one view while it is up, goes through `HeldQuery` …", replacing the `ProvenanceSheetHost` example and naming `keepsPreviousValue`), `.agents/skills/add-workspace-place/SKILL.md` ("View-held key" row: the view draws `HeldQuery(key, keepsPreviousValue:)` rather than wiring `.task`, `onChange` and `onDisappear` itself), `macos/App/Features/Workspace/Session/WorkspaceSession.swift` (`release`'s doc: "the view that holds it through `HeldQuery`"), `docs/deployment-plan/spike-15/deployment-plan.md` (map row status `Landed [#N](…)`), `docs/deployment-plan/spike-15/completed.md`, this plan, the brief → `design/archive/`, `design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-22-person-sources-citations.md` passes; `scripts/check-guidance-names.py` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log`. No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` `personSourcesCitationsKeySortsAndFollowsInputs` *(new)* | `personSourcesCitations(citationIds: ["b","a","a",""])` has ids `["a","b"]`; with `renderCitationsInputs.sources = ["s1"]`, query and settle, then `session.apply(CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .sourceRecords, ids: ["s1"])]))` → a second store call is logged | D-2 |
| T-2 | Swift | `macos/ProvenenciaTests/ProvenanceSheetTests.swift` `renderHelpersIndexTestAndGather` *(new)* | `CatalogRenderedCitations` with a, b, a → `byID` keys a, b, a's first entry kept; `isFormatted` true for full runs, false for empty; `Record.isFormatted` follows it; `CitationGroups.gather([1,2,3,4], by: { $0 % 2 == 0 ? "e" : "o" })` → [("o",[1,3]), ("e",[2,4])] | D-1 |
| T-3 | Swift | `macos/ProvenenciaTests/PersonSourcesContentTests.swift` `citingGroupsALinesCitationsByKey` *(new)* | Line o1(c1), o2(c2), o3(c3); c1, c2 `full:K`, c3 `full:L` → blocks [K: o1, o2], [L: o3]; c2 full empty → [K: o1], [L: o3]; c2 missing → same; all unformatted → `[]`; two lines of one Source with `full:K` → a block under each; a block's `rendered` is c1's | D-5, AC-1.1, AC-1.6, AC-1.7 |
| T-4 | Swift | `PersonSourcesContentTests.swift` `citationIDsCoverFoldedLines` *(new)* | Seven lines and 51 Sources (folds closed), Observations with ids incl. "" and repeats → `citationIDs` holds every non-empty id once, first appearance, folded lines included; unfolding leaves `citationIDs` equal; `citing([:])` equals the content | D-5, AC-3.4 |
| T-5 | Swift | `PersonSourcesContentTests.swift` `piecesReadPropertyAndValue` *(new)* | Name "Johann Weber" → "Name Johann Weber"; negative Birthplace "Bremen" → "Birthplace " + `readAsNot("Bremen")`; Likeness with no text → "Likeness"; empty label, key `occupation`, "Cooper" → "occupation Cooper"; empty label, empty key → nil; two Observations of one block both "Age 34" → one piece; `displayLabel` of an empty label is the key. No date values (the date text follows the machine's locale) | D-6, AC-1.3, AC-1.4, AC-1.5 |
| T-6 | Swift | `macos/ProvenenciaTests/HeldQueryTests.swift` `holdKeepsTheDrawnKeyUntilTheNextSettles` *(new)* | keepsPrevious true: `settle(k1)` → nil, drawn k1; `shown(current: k2, currentHasValue: false)` → k1; `move(from: k1)` → nil; `settle(k2)` → k1, drawn k2; `move(from: k2)` then `settle(k3)` after k3 failed → k2, `shown(current: k3, currentHasValue: false)` → nil; `move(from: k4)` where k4 never settled → k4; `all(current: k5)` → [k5, k3]. keepsPrevious false: `settle(k1)`, `move(from: k1)` → k1, drawn nil, `shown(current: k2, currentHasValue: false)` → nil | D-3, D-4, AC-3.5 |
| T-7 | Swift | `HeldQueryTests.swift` `sectionCitationsLoadFailAndReadAgain` *(new)* | FakeStore held → `query(key).read.formLoadState` `.loading`, one call with the asked ids; `renderCitationsError` → `.failed(L10n.Errors.message(for:))`; clear the error, `reread` → value; `release` → `queryHandle(key)` nil; empty ids → no call | D-2, D-8, AC-3.1, AC-3.2, AC-3.3, AC-3.6 |
| T-8 | Swift | `macos/ProvenenciaTests/ProvenanceSheetTests.swift` `citationCopyTrackFollowsTheRender` *(new)* | `PVCitationCopyTrack.formatted` of a render with full and short → kinds [.full, .short], texts the plains, both with `rich` whose italic run is `.emphasized`; empty short → [.full]; `line("x")` → [.citation], `rich` nil | D-7, AC-1.2, AC-2.1, AC-2.2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PersonSourcesContentTests` (`Line` gains fields), `ProvenanceSheetTests`, `PVProvenanceColumnsTests`, `WorkspaceSessionTests` (the sheet's host moves), `CatalogQueryRegistryTests` (a test that walks every `Kind`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`L10n.ProvenanceSheet.copyWordFull`, `copyWordShort`, `copyWordCitation`, `copyFullCitation`, `copyShortCitation`, `copyCitation`, `fullCitationCopied`, `shortCitationCopied`, `citationCopied`; `PVProvenanceRecordRow.Copy`; `PVProvenanceColumns.copyTrackWidth`, `copyTrackSpacing`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/catalog-caches.md, docs/macos-client-patterns.md (cache contract item 2), add-workspace-place "View-held key", the `release` doc
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
8. Open a provenance sheet: it loads, groups, and its Full, Short and Copy buttons look and copy as before; close and reopen it: it reads again.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The blocks push the scroll when they arrive on a visit | The restore waits for them (D-8); a first visit starts at the top |
| A drawn key never settles because the new key's read hangs | `onDisappear` releases both (D-3) |
| Moving the sheet's host changes its behavior | `keepsPreviousValue: false` keeps today's release-at-once; the sheet's tests and manual step 8 |
| The board draws a heading, count, link or skeleton for a block | Brief non-goals; a board change goes to the user before this plan moves to Planned |

**Stop and report if:**

- `RenderCitationsResponse`, `CatalogRenderedCitation` or `CatalogPersonClaim.observations` no longer match § 4.
- `conclusionAnchorRestore` restores before `isReady` turns true, or never restores when `isReady` starts false (D-8).
- `.onChange(of:initial:)` on `HeldQuery` fires before the handle exists so that `settle` runs for a key with no read (D-3).
- `ConclusionPageSectionHost`'s content closure can draw with no claims value (Edges).
- Moving the copy track changes the sheet's layout in its previews or `PVProvenanceColumnsTests` (D-7).
- The agreed S15-D15 board differs from a Decision here (then the plan is refreshed first).

## 12. Open questions

None. (Status is Blocked on the board, not on a question; the review's one To user item, the retry word, is answered by D-10's default unless the user overrides it.)

## 13. PR

**Title:** S15-22 — The Sources section groups a Source's Citations by citation
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-22-person-sources-citations.md`.
