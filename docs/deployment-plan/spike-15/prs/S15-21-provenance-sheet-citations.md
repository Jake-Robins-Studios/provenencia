# S15-21 — The provenance sheet shows formatted citations

**Status:** Blocked — on board S15-D9
**Spike / slice:** Spike 15 · Slice 6 — Citations in the app
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D9](../design/S15-D9-provenance-sheet-citations.md), board not agreed yet
**Board:** — (set when S15-D9 is agreed: the link and the frame names; until then § 6 macOS describes each frame in words)
**Depends on:** S15-16 (landed [#914](https://github.com/Jake-Robins-Studios/provenencia/pull/914)), S16-30 (landed [#812](https://github.com/Jake-Robins-Studios/provenencia/pull/812)), S16-04 (landed [#776](https://github.com/Jake-Robins-Studios/provenencia/pull/776)), S16-25 (landed [#847](https://github.com/Jake-Robins-Studios/provenencia/pull/847): keys are values), S15-17 (landed [#924](https://github.com/Jake-Robins-Studios/provenencia/pull/924): `CatalogCitationRender`, `CitationRunsText`), S15-D9
**Blocks:** S15-23 (the rich-payload copy), S15-27 (the fold counts this PR's citation runs), S15-29 (grows this PR's key)
**Branch:** `s15-21-provenance-sheet-citations`
**Version bump:** minor, 0.30.0 → **0.31.0** (if `main`'s `VERSION` is no longer 0.30.0 when you rebase, the next minor after it): the app's first screen to show rendered citations, and a new store method ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-workspace-place`](../../../../.agents/skills/add-workspace-place/SKILL.md) (a `CatalogQueryKey` kind, its descriptor and `followsInputs`), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-client.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/versioning.mdc`; [`docs/design-system-layers.md`](../../../design-system-layers.md) (a recipe never names a `Features/` type); [`docs/macos-client-patterns.md`](../../../macos-client-patterns.md) §4 (AppKit in a small wrapper)
**Context:** working rules "Citations render on demand, from SQL", "Grouping is by the rendered full citation, computed when read", "Today's line stays the fallback, in Swift", "One engine, in Go", "Build on Spike 16's caches", "One window; nothing is built for a second" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../provenance-loading.md`](../provenance-loading.md) "Load records when the sheet opens"; landed plans [`S15-16-citations-render.md`](S15-16-citations-render.md) (D-6, the group key), [`S15-17-format-editor.md`](S15-17-format-editor.md) (D-6: `CatalogCitationRender`; **Next adds**: this PR moves `CitationRunsText`); [`docs/catalog-caches.md`](../../../catalog-caches.md)
**Planned:** 2026-11-21 against `main` @ `b317d6e` (compare with `origin/main` after `git fetch origin main`)
**Review:** [`S15-21-provenance-sheet-citations.review.md`](S15-21-provenance-sheet-citations.review.md)

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

When a researcher opens a value's provenance sheet, each record's citation reads like a citation: the full citation the engine renders from the Source, its Artifact and its Evidence graph, with its italics, where the Source's type has a full format, and today's line where it has none. Two buttons copy the full and the short citation as rich text (italics kept) and plain text. Records whose full citations read the same sit together with no rule between them, so the pieces of one household row read as one citation. The citations are fetched when the sheet opens, through one cached read held only while the sheet is shown; until they arrive the record area shows a loading indicator, and on failure a notice with Try again. This is bar 4's sheet and bar 7 on the sheet.

**Why now.** The render (S15-16), the sheet's records from the records tier (S16-30), the failed-read reading and notice (S16-04) and the run decoder (S15-17) have landed. No screen shows a rendered Citation yet.

**What stays.** The sheet's header, column headings, owner lines, value headings, Outcome and Record cells, links and widths. `CitationLineDisplay` stays as the fallback and for its other callers (Gallery captions, the likeness viewer, a denier's Source name), minus the empty-title fallback (D-10). The page read is unchanged: records still arrive with the page (S15-29 moves them). The render is never cached past the sheet.

## 2. User stories

**US-1.** As a researcher, when I open a value's provenance sheet, I read each record's formatted citation, so that I see the citation I would write.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A record whose Citation's type has a full format rendering runs `"1880 U.S. census, …; digital image, "`, `"Ancestry"` (italic), `" (… : accessed 12 March 2025)"` | Its Citation cell's link shows those runs, "Ancestry" in italic; the row's spoken line contains the plain text |
| AC-1.2 | A record whose type has no full format (render `full` empty), or whose Citation is missing from the reply | The cell shows today's line ("Census of Canada West, 1851, Vol. 3, p. 23") as before |
| AC-1.3 | The sheet opens | One `renderCitations` call carries the distinct citation ids of the row's records, sorted; closing the sheet drops the key (a reopen calls again) |

**US-2.** As a researcher, I copy a citation's full or short form and paste it with its italics.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | A formatted row; click **Copy full citation** | The pasteboard holds `.rtf` with "Ancestry" italic and `.string` with the full plain text; VoiceOver hears "Full citation copied" |
| AC-2.2 | Same row; click **Copy short citation** | The pasteboard holds the short form, rich and plain; "Short citation copied" |
| AC-2.3 | A formatted row whose render `short` is empty | Only Copy full citation shows |
| AC-2.4 | A fallback row | One **Copy citation** button copies today's line as plain text, as today |

**US-3.** As a researcher, the five records from one household row read as one citation.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | A value run with records a(key K), b(key L), c(key K), in that order | Order becomes a, c, b; a and c form one citation run, b its own |
| AC-3.2 | Two records with key K in different value runs | They stay in their own runs (a run never crosses a value heading or owner group) |
| AC-3.3 | A run of a and c | No rule is drawn between a and c; a rule is drawn before b |
| AC-3.4 | Fallback records (keys `citation:<id>`, or no render) | Each is its own run |

**US-4.** As a researcher, I see that citations are loading or could not be read.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | The render has not answered | Header and headings draw; the record area shows a progress indicator spoken "Loading citations"; no rows |
| AC-4.2 | The render fails (`FakeStore.renderCitationsError`) | The record area shows only `PVRetryCallout` titled "Citations could not be read" with the error's message; no rows |
| AC-4.3 | Try again after AC-4.2, the store now succeeding | The key is read again and the table draws grouped |

## 3. Scope

| In | Covered by |
| --- | --- |
| Store method `renderCitations` (Go store, fake store) and `CatalogRenderedCitations` (US-1) | STEP-1, AC-1.3 |
| `CatalogQueryKey.citationRenders` with its descriptor; `WorkspaceSession.release(_:)` (D-2, D-3) | STEP-2, AC-1.3 |
| Rich-text payload in `PVClipboardCopyState` and `PVClipboardButton` (PC-4) | STEP-3, AC-2.1 |
| `CitationRunsText` moves to `Platform/`; `CatalogCitationRender.pasteboardText` (PC-1) | STEP-4, AC-1.1 |
| Citation runs in `PVProvenanceSheetContent` and the grouping (PC-5) | STEP-5, AC-3.1 – AC-3.4 |
| The row's formatted citation, two copy buttons, the table's rules (PC-1 – PC-3, PC-8, PC-9, PC-W1) | STEP-6, AC-1.1, AC-1.2, AC-2.3, AC-2.4 |
| The sheet's record-area states and the feature host (PC-6, PC-7) | STEP-7, AC-4.1 – AC-4.3 |
| The empty-Source-title fallback goes (map scope "Also") | STEP-8 |
| Docs: catalog caches, provenance-loading note, completed, map | STEP-9 |

| Out | Home |
| --- | --- |
| The fold of the table, Show more | S15-27 |
| Records loading on open; `FieldRecordCounts` | S15-28, S15-29 |
| The Sources section's grouping | S15-22 |
| Copy source-list entry | S15-23 |
| Event and Place rows opening the sheet | S15-31 |
| A group heading, a group count, a disclosure per group | not planned (user, 2026-11-21: rows repeat their citation; a run is marked only by its missing rules) |
| Batching more than 2,000 citation ids per call | not planned (Scale is 1,200 records on one value; D-5) |
| Caching renders past the sheet | not planned (rule "Citations render on demand, from SQL") |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Sheet presenter | `macos/App/Features/Conclusions/ReconciledValueRow.swift` `ConclusionDetailRowsSection` | `.pvSheet(item: $provenanceItem)` draws `PVProvenanceSheet(content: row.provenanceContent(), columns:, idPrefix: "conclusion.detail.provenance", open:)`; closes the sheet when its row leaves |
| Sheet recipe | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` `PVProvenanceSheet` | `PVPanel` with header, `PVProvenanceColumnHeadings`, a `ScrollView` of `PVProvenanceRecordTable` (max 560pt), Done |
| Content | `…/ProvenanceSheet/PVProvenanceSheetContent.swift` `PVProvenanceSheetContent`, `Record`, `Group`, `Group.ValueGroup` | `ValueGroup { heading; records: [Record] }`, two inits on `Group`; `Record.citation: CitationLineDisplay.Parts`; `Record.spoken` joins `citation.line` |
| Table | `…/ProvenanceSheet/PVProvenanceRecordTable.swift` `PVProvenanceRecordTable` | A `PVDivider` before every record but the first under a line; `PVProvenancePreviewData` builds records with `titleIsRef: false` |
| Row | `…/ProvenanceSheet/PVProvenanceRecordRow.swift` `PVProvenanceRecordRow.citation` | `PVInkLink` labelled `Text(verbatim: record.citation.line)`; one `PVClipboardButton(text: record.citation.line, label: L10n.ProvenanceSheet.copyCitation, copiedAnnouncement: …citationCopied)` in a 26pt track |
| Columns | `…/ProvenanceSheet/PVProvenanceColumns.swift` | `copyTrackWidth = 26`, `copyTrackSpacing = 6` |
| Clipboard | `macos/App/DesignSystem/Components/ClipboardButton/PVClipboardButton.swift` `PVClipboardCopyState` | `write: (String) -> Void`; `copy(_ text:)`; `writeToGeneralPasteboard` sets `.string` only |
| Run text | `macos/App/Features/SourceTypes/SourceTypeFormatsSection.swift` `CitationRunsText` | Concatenates runs, italic where marked, `accessibilityLabel(render.plain)`; one caller in the same file |
| Render types | `macos/App/Platform/GenealogyStore.swift` `CatalogCitationRun`, `CatalogCitationRender`, `CatalogPageInputs` | Decoded by `GoStore.mapCitationRender`; no store method calls `RenderCitations` |
| Wire | `api/proto/engine.proto` `RenderCitationsRequest` (`project_dir`, `citation_ids`), `RenderCitationsResponse` (`citations`, `inputs`), `RenderedCitation` (`citation_id`, `full`, `short`, `group_key`) | Method `CoreMethod.renderCitations` (124). Go refuses more than 2,000 ids or 8 MiB (`citations.invalid`) |
| Group key | `core/database/citationrender/render.go` `groupKey` | `"full:<sha256>"` for a rendered full citation; `"citation:<id>"` when none |
| Query keys | `macos/App/Features/Workspace/Session/CatalogQueryKey.swift` `CatalogQueryKey`, `Kind`; `CatalogQueryRegistry.swift` `CatalogQueryDescriptor.make`, `Kind.descriptor`; `CatalogLastUpdated.swift` `CatalogPageValue`, `CatalogQueryRefresh.followsInputs` | Value keys. A key not in `visibleKeys` (a place's keys) follows its descriptor's `whenHidden`; `.revalidate` (default) reloads it on a write that reaches it. There is no `.evict` policy and no public way to drop a key: `evict(_ key:)` is private |
| Failure reading | `QueryHandle.swift` `reading`, `noticeError`, `isReading`, `failureRevision`; `QueryHandle+RetryCallout.swift` | The S16-04 reading the Conclusions sections use |
| Empty-title fallback | `macos/App/Platform/CitationLineDisplay.swift` `sourceTitle(for:)`, `Parts.titleIsRef`; readers `ReconciledValueDisplay.swift` (denier name), `Features/Conclusions/ConclusionGallerySection.swift:308` (ref font), `PVProvenanceRecordTable.swift` preview | Guards a Source with no title, which the catalog refuses |
| Tests | `macos/ProvenenciaTests/ProvenanceSheetTests.swift`, `PVClipboardButtonTests.swift`, `CatalogQueryRegistryTests.swift`, `WorkspaceSessionTests.swift`, `PersonDetailTests.swift` (`tile.citation.titleIsRef`, lines 228 and 240) | Cover the content assembler, the copy state, the registry and the session |

**Precedent.** The Conclusion section hosts (`Features/Conclusions/ConclusionPageSectionHost.swift`) read a `QueryHandle`'s `reading` and draw `PVRetryCallout(handle:)` with Try again calling `session.reread(key)`; copy that shape for the sheet's notice. `CatalogPersonClaims` (S16-24) is a `CatalogPageValue` whose key follows its inputs through `followsInputs`; copy that for the render value. S15-17's `renderCitationPreview` is the store method shape (Go store, `FakeStore` reply, call log and error).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **Store.** `GenealogyStore.renderCitations(projectDir: String, citationIDs: [String]) async throws -> CatalogRenderedCitations` *(new)*. `CatalogRenderedCitation { citationID: String; full: CatalogCitationRender; short: CatalogCitationRender; groupKey: String }` *(new)*, `CatalogRenderedCitations: CatalogPageValue { byID: [String: CatalogRenderedCitation]; inputs: CatalogPageInputs }` *(new)*, beside `CatalogCitationRender`. Empty `citationIDs` returns an empty value without a call | One decoder of the wire (S15-17 D-6); a dictionary because the sheet looks up by a record's citation id | An array in reply order — every reader would build the dictionary |
| D-2 | **Key.** `CatalogQueryKey.Kind.citationRenders` *(new)*, `static func citationRenders(project:citationIds:)` *(new)* with `ids` = the distinct non-empty ids, sorted. Descriptor: `.make(kind:, refreshes: CatalogQueryRefresh.followsInputs(CatalogRenderedCitations.self), load: { key, store in try await store.renderCitations(projectDir: key.project.projectDir, citationIDs: key.ids) })`; `whenHidden` is the default `.revalidate`, so a write reaching its inputs while the sheet is open reloads it. No `invalidateOn`, no patches | Rule "Citations render on demand": one key while shown, the registry's refresh on the inputs its read reports. Sorting makes the key independent of record order | `whenHidden: .evict` as the rule's parenthetical says — the sheet's key is never in `visibleKeys` (only places are), so an evict-when-hidden policy would drop it on the first write while open. D-3 gives the same outcome; the rule's text is updated (STEP-9) |
| D-3 | **Release.** `WorkspaceSession.release(_ key: CatalogQueryKey)` *(new, internal)* calls the private `evict(_ key:)`. The sheet host queries the key in `.task(id: key)` and calls `release` in `.onDisappear` and when its key changes (the old key) | "Nothing outlives the sheet" with one public line over the existing eviction | A `CatalogHiddenPolicy.evict` case plus a "held keys" set — more machinery for one caller |
| D-4 | **Host.** `ProvenanceSheetHost` *(new)* in `macos/App/Features/Conclusions/ProvenanceSheetHost.swift` *(new)* takes the row's `PVProvenanceSheetContent`, `columns`, `idPrefix`, `open`; holds `@Environment(WorkspaceSession.self)`; derives the key from `content.records.map(\.outcome.citationID)`; maps the handle's `reading` to `PVProvenanceSheet.Citations` (D-6) and Try again to `session.reread(key)`. `ConclusionDetailRowsSection` draws it in place of `PVProvenanceSheet` | The recipe cannot name `WorkspaceSession` or `QueryHandle` (`docs/design-system-layers.md`) | Querying in `ConclusionDetailRowsSection` — it presents every row's sheet and would hold keys for closed sheets |
| D-5 | **Size.** No chunking: more than 2,000 distinct ids, or 8 MiB of text, is the engine's `citations.invalid`, shown as the failed notice | Scale is 1,200 records on one value; one call keeps the key one read | Splitting into calls of 2,000 — code for a case past Scale |
| D-6 | **Recipe states.** `PVProvenanceSheet` gains `citations: Citations` *(new nested enum)*: `.loading`, `.failed(message: String, isRetrying: Bool, failureRevision: Int, onRetry: () -> Void)`, `.ready([String: CatalogRenderedCitation])`. `.loading` draws `ProgressView().controlSize(.small)` centred in a frame of `minHeight: 120` with `accessibilityLabel(L10n.ProvenanceSheet.citationsLoading)`; `.failed` draws only `PVRetryCallout(title: L10n.ProvenanceSheet.citationsFailedTitle, message:, retry: L10n.Conclusions.readNoticeTryAgain, isRetrying:, retryIdentifier: "\(idPrefix).citations.tryAgain", failureRevision:, onRetry:)` with identifier `"\(idPrefix).citations.error"`; `.ready` draws the table over `content.grouped(by:)` (D-7). The header and column headings draw in every state. A `.ready` that arrives behind a value (refetch) keeps the table; a refresh failure behind a value shows the table (the S16-04 stale notice is not drawn on a sheet) | User, 2026-11-21: spinner while loading, notice only on failure. Reading map: `.loading` and `.failed(noValue)` from `reading`; a value wins | Today's lines while loading — the table would reflow when runs form |
| D-7 | **Grouping.** `Group.ValueGroup` stores `citations: [CitationRun]` *(new: `struct CitationRun: Equatable { var key: String; var records: [Record] }`)*; `records` becomes computed (`citations.flatMap(\.records)`); `init(heading:records:)` stays and puts each record in its own run (key = record id). `PVProvenanceSheetContent.grouped(by renders: [String: CatalogRenderedCitation]) -> PVProvenanceSheetContent` *(new, pure)* sets each record's `rendered` (D-8) and, inside each value run, gathers records by `renders[citationID]?.groupKey` in first-appearance order; a record with no render or an empty full keeps its own run | Rule "Grouping is by the rendered full citation, computed when read"; a run never crosses a value heading or owner group because those say which value the records went into (AC-3.2). S15-27 folds over `citations` | Grouping across value runs — it would hide which value a record counted for |
| D-8 | **Record.** `Record` gains `rendered: CatalogRenderedCitation? = nil` *(new)* and `citationText: String` *(new, computed: `rendered.full.plain` when non-empty, else `citation.line`)*; `spoken` uses `citationText` | One rule for the fallback (rule "Today's line stays the fallback") | Overwriting `citation.line` — the Source link's spoken label reads `citation.title` |
| D-9 | **Row.** With a non-empty `rendered.full`, the link label is `CitationRunsText(render: rendered.full)`; else `Text(verbatim: citation.line)`. The copy track holds two `PVClipboardButton`s: full (`label: L10n.ProvenanceSheet.copyFullCitation`, announcement `fullCitationCopied`, ids `.copyFull`) and short (`copyShortCitation`, `shortCitationCopied`, `.copyShort`), the short one only when `rendered.short.runs` is non-empty; a fallback row keeps today's one button (`copyCitation`, `.copy`). `PVProvenanceColumns.copyTrackWidth` becomes `58` (two 26pt buttons and a 6pt gap) on every row. The table draws no `PVDivider` between two records of one `CitationRun` | User, 2026-11-21: two buttons; rows repeat their citation and a run drops its rules | A menu or split button — a new kit control for one call site |
| D-10 | **Fallback cleanup.** `CitationLineDisplay.sourceTitle(for:)` and `Parts.titleIsRef` go: `parts` takes `title = outcome.sourceTitle`; `ReconciledValueDisplay`'s denier name reads `denier?.sourceTitle`; `ConclusionGallerySection`'s ref font branch goes (the title font always) | Map scope "Also": a Source title is required, so the branch guards nothing | Keeping it — dead code the map names |
| D-11 | **Rich copy.** `PVClipboardPayload { plain: String; rich: AttributedString? }` *(new, in `PVClipboardButton.swift`)*. `PVClipboardCopyState.write` becomes `(PVClipboardPayload) -> Void`; `copy(_ text: String, rich: AttributedString? = nil)`; `writeToGeneralPasteboard` writes `.rtf` (from `NSAttributedString(rich)` via `data(from:documentAttributes: [.documentType: .rtf])`) when `rich` is set, then `.string`. `PVClipboardButton` gains `rich: AttributedString? = nil`. `CatalogCitationRender.pasteboardText: AttributedString` *(new)* in `Platform/CitationRunsText.swift` *(new)* sets `.appKit.font` to `NSFont.systemFont(ofSize: NSFont.systemFontSize)` and, for italic runs, `NSFontManager.shared.convert(_:toHaveTrait: .italicFontMask)` | Map: "one rich-payload write added to `PVClipboardCopyState`"; S15-23 reuses it. RTF needs a font trait, not a presentation intent | HTML on the pasteboard — RTF is what macOS editors read first |
| D-12 | **Run text moves.** `CitationRunsText` moves unchanged to `macos/App/Platform/CitationRunsText.swift` *(new)* | Its second caller is a recipe, which cannot name `Features/` (S15-17 **Next adds**) | A kit component — a snowflake with two callers (brief inventory) |
| D-13 | **Copy.** `L10n.ProvenanceSheet.copyFullCitation` = "Copy full citation", `copyShortCitation` = "Copy short citation", `fullCitationCopied` = "Full citation copied", `shortCitationCopied` = "Short citation copied", `citationsLoading` = "Loading citations", `citationsFailedTitle` = "Citations could not be read" *(new)*. The failed message is `L10n.Errors.message(for: error)` | Brief PC-3, PC-6 – PC-8 | — |

**Rules this plan bends.** None. D-2 implements rule "Citations render on demand, from SQL" with `release` instead of the `whenHidden: .evict` its parenthetical names; the rule's intent (one key only while shown, nothing outlives the sheet) holds, and STEP-9 corrects the parenthetical.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `renderCitations` *(new)* | store method | `renderCitationPreview` | Different RPC and reply; shares `mapCitationRender` and `mapPageInputs` |
| `CatalogRenderedCitation`, `CatalogRenderedCitations` *(new)* | type | `CatalogCitationPreview`, `CatalogPersonClaims` | Preview carries missing and diagnostics; the batch carries a group key and inputs |
| `Kind.citationRenders` *(new)* | query key | `personClaims` (a page value with inputs) | Keyed by citation ids, not a handle; not an entity page |
| `WorkspaceSession.release` *(new)* | func | private `evict(_ key:)` | Exposes it; no second eviction path |
| `ProvenanceSheetHost` *(new)* | view | `ConclusionPageSectionHost` | That host draws a page section with gone and empty states; the sheet needs neither |
| `PVProvenanceSheet.Citations` *(new)* | enum | `ConclusionDetailPresentation` | Feature type; a recipe cannot name it |
| `CitationRun` *(new)* | type | `Group.ValueGroup` | One level below a value run |
| `PVClipboardPayload` *(new)* | type | `PVClipboardCopyState.write`'s `String` | Extends it with an optional rich half |
| `pasteboardText` *(new)* | func | `CitationRunsText` | Same runs, AppKit attributes for the pasteboard |
| L10n keys (D-13) *(new)* | key | `copyCitation`, `citationCopied` | Two forms need two names |

**Builds on.** The query registry and `followsInputs` (S16-24, S16-25); the S16-04 reading and `PVRetryCallout`; S15-17's render decoder; the kit's `PVClipboardButton`.
**Deletes.** `CitationLineDisplay.sourceTitle(for:)`, `Parts.titleIsRef` and their readers' branches (D-10); `CitationRunsText` in `SourceTypeFormatsSection.swift` (moved).
**Next adds.** S15-27 folds `citations` runs 50 at a time. S15-29 adds records to this key's value and re-keys it by (owner, Property) pairs. S15-23 copies with `PVClipboardButton(rich:)` and `pasteboardText`. S15-22 reuses `renderCitations` and `CitationRunsText`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A sheet's row changes records while open (a page refresh) | `ProvenanceSheetHost` | The key changes; `.task(id: key)` queries the new key and releases the old (D-3) |
| A Citation deleted between the page read and the render | `grouped(by:)` | Missing from `byID` → today's line, own run (AC-1.2) |
| The row leaves the page | `ConclusionDetailRowsSection.onChange(of: rows)` | Closes the sheet as today; `onDisappear` releases the key |

### Scale

At the map's Scale (300 citations per sheet, up to 1,200 records on one value): one `RenderCitations` call per sheet open (S15-16 measured 9 SELECTs at 300 and 11 at 1,200). `grouped(by:)` is one pass per value run with a dictionary of first positions: O(records). The key holds up to 1,200 id strings; it is hashed once per query. A write reaching the key's inputs while open reloads it once (one call).

### Edges

- **Assumptions.** The table assumes `ValueGroup.records` is the run's records in order; `records` stays (computed) and keeps that order after gathering (T-5).
- **Neighbors.** Two records, same Citation id (two outcomes from one Citation) → same key, one run (T-5). Same key in two value runs → two runs (T-5). Empty `full` with a key `citation:<id>` → own run (T-5).
- **Removed inputs.** A record whose Citation is gone → fallback (T-5). An empty `citationID` → not sent, fallback (T-4).
- **Real data.** None — no table or seed drives a rule here.
- **Untrusted size.** The id list is bounded by the row's records (Scale 1,200); past 2,000 the engine refuses (D-5).

### Schema

None — no catalog change.

### Go core

None — S15-16 shipped the render.

### FFI

None — `RenderCitations` (124) exists.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Sheet with record-area states | `PVProvenanceSheet` | `DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` | D-6. Frames 4 and 5 |
| Table rules | `PVProvenanceRecordTable` | same folder | D-9: no divider inside a `CitationRun`. Frames 1a, 3 |
| Row citation and copy track | `PVProvenanceRecordRow` | same folder | D-9. Frames 1a, 2, 6, 7 |
| Formatted citation | `CitationRunsText` | `Platform/CitationRunsText.swift` *(new)* | D-12 |
| Copy buttons | `PVClipboardButton` | `DesignSystem/Components/ClipboardButton/` | D-11 |
| Failed notice | `PVRetryCallout` | `DesignSystem/Components/Callout/` | D-6 |
| Host | `ProvenanceSheetHost` *(new)* | `Features/Conclusions/` | D-4 |

Frames in words until the board is agreed: **1a** the Birth date sheet with three records, two 1880-census records with the same full citation and no rule between them, each with two copy buttons, and a parish-register record with today's line and one button; **1b** the same at 1280pt; **2** Copy short citation in its check state; **3** owner groups with a same-citation pair in the first group; **4** loading; **5** failed and retrying; **6** a five-line citation with buttons level with its first line; **7** a formatted row with no short format; **8** spoken annotations.

States: loading (D-6), failed (D-6), ready; a sheet with no citation ids is ready at once. Accessibility: spoken lines (D-8), button labels and announcements (D-13), the loading label, the notice announced by `PVRetryCallout`.

### Strings

L10n keys *(new)* as D-13. Kept: `L10n.ProvenanceSheet.copyCitation` and `citationCopied` (the fallback row).

## 7. Steps

**STEP-1 — The store renders a batch.**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`. Skill: `add-swift-test`.
Do: D-1. `FakeStore`: `renderCitationsReplies: [String: CatalogRenderedCitation]` (by id; the reply is the asked ids found there, inputs empty), `renderCitationsCalls: [[String]]`, `renderCitationsError: Error?`.
Check: `xcodebuild test … -only-testing:ProvenenciaTests/CatalogSessionStoreTests` builds; T-1 passes.

**STEP-2 — The sheet's key and release.**
Files: `CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `CatalogLastUpdated.swift` (`extension CatalogRenderedCitations: CatalogPageValue {}`), `WorkspaceSession.swift`. Skill: `add-workspace-place`.
Do: D-2, D-3.
Check: T-2, T-3 pass.

**STEP-3 — The clipboard writes rich text.**
Files: `DesignSystem/Components/ClipboardButton/PVClipboardButton.swift`, `macos/ProvenenciaTests/PVClipboardButtonTests.swift`. Skill: `add-ui-component`.
Do: D-11 (the payload, the write, the button's `rich:`). Existing callers compile unchanged.
Check: T-6 passes; existing `PVClipboardButtonTests` pass.

**STEP-4 — Run text moves to Platform.**
Files: `Platform/CitationRunsText.swift` *(new)*, `Features/SourceTypes/SourceTypeFormatsSection.swift`.
Do: D-12; add `CatalogCitationRender.pasteboardText` (D-11).
Check: build passes; T-7 passes.

**STEP-5 — Content groups by citation.**
Files: `PVProvenanceSheetContent.swift`, `PVProvenanceRecordTable.swift` (preview data), `macos/ProvenenciaTests/ProvenanceSheetTests.swift`.
Do: D-7, D-8.
Check: T-4, T-5 pass; existing `ProvenanceSheetTests` pass.

**STEP-6 — The row and table draw it.**
Files: `PVProvenanceRecordRow.swift`, `PVProvenanceRecordTable.swift`, `PVProvenanceColumns.swift`, `Platform/L10n.swift`, `Localizable.xcstrings`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-9, D-13 (copy keys). Previews: a formatted row, a fallback row, a same-citation run.
Check: build; T-8 passes; `PVProvenanceColumnsTests` updated for 58.

**STEP-7 — The sheet's states and its host.**
Files: `PVProvenanceSheet.swift`, `Features/Conclusions/ProvenanceSheetHost.swift` *(new)*, `Features/Conclusions/ReconciledValueRow.swift`, `L10n.swift`, `Localizable.xcstrings`.
Do: D-4, D-6, D-13 (state keys). Previews for loading and failed.
Check: T-9, T-10 pass.

**STEP-8 — The empty-title fallback goes.**
Files: `Platform/CitationLineDisplay.swift`, `Platform/ReconciledValueDisplay.swift`, `Features/Conclusions/ConclusionGallerySection.swift`, `PVProvenanceRecordTable.swift`, `macos/ProvenenciaTests/PersonDetailTests.swift`.
Do: D-10. Remove the "OBS-b" title-is-ref expectations (lines 236–240).
Check: `rg "titleIsRef|sourceTitle\(for" macos/App/Platform macos/App/Features/Conclusions macos/App/DesignSystem` finds only `EvidenceGraphFiles`'s unrelated `titleIsRef`; tests pass.

**STEP-9 — Docs.**
Files: `docs/catalog-caches.md` (a `citationRenders` row: held while the sheet is shown, released on close, follows its inputs), `docs/deployment-plan/spike-15/deployment-plan.md` (map row status; rule "Citations render on demand": replace "(`whenHidden: .evict`)" with "(released when the sheet closes, `WorkspaceSession.release`)"), `provenance-loading.md` (the first step landed), `completed.md`, this plan, the brief → `design/archive/`, `design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-21-provenance-sheet-citations.md` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log`. No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/CatalogSessionStoreTests.swift` `renderCitationsMapsTheReply` *(new)* | A FakeStore reply for ids a, b; ask a, b, c → `byID` holds a and b; empty ids → empty value, no call logged | D-1, AC-1.2 |
| T-2 | Swift | `CatalogQueryRegistryTests.swift` `citationRendersKeySortsAndFollowsInputs` *(new)* | `citationRenders(citationIds: ["b","a","a",""])` has ids `["a","b"]`; a write whose effects name a Source in the value's inputs reloads the key | D-2 |
| T-3 | Swift | `WorkspaceSessionTests.swift` `releaseDropsTheKey` *(new)* | Query, then `release` → `queryHandle(key)` is nil; a second `query` calls the store again | D-3, AC-1.3 |
| T-4 | Swift | `ProvenanceSheetTests.swift` `citationTextFallsBack` *(new)* | Record with rendered full runs → `citationText` is the plain; empty full or nil → `citation.line`; `spoken` contains `citationText` | D-8, AC-1.1, AC-1.2 |
| T-5 | Swift | `ProvenanceSheetTests.swift` `groupedGathersByKeyWithinARun` *(new)* | Run a(K), b(L), c(K) → runs [a,c], [b]; K in two value runs → separate; `citation:` keys and missing renders → own runs; `records` order a, c, b | D-7, AC-3.1, AC-3.2, AC-3.4 |
| T-6 | Swift | `PVClipboardButtonTests.swift` `copyWritesRichAndPlain` *(new)* | `copy("x", rich: r)` → write receives payload with plain "x" and rich r; `copy("x")` → rich nil | D-11, AC-2.1, AC-2.4 |
| T-7 | Swift | `ProvenanceSheetTests.swift` `pasteboardTextKeepsItalic` *(new)* | Runs plain "a", italic "b" → the `b` run's `.appKit.font` has the italic trait; text "ab" | D-11, AC-2.1 |
| T-8 | Swift | `ProvenanceSheetTests.swift` `copyButtonsFollowTheRender` *(new)* | A pure helper `PVProvenanceRecordRow.copies(for:)` *(new, returns the button list)*: full+short → [full, short]; empty short → [full]; fallback → [citation] | D-9, AC-2.2, AC-2.3, AC-2.4 |
| T-9 | Swift | `ProvenanceSheetTests.swift` `hostMapsReadingToCitations` *(new)* | A pure `ProvenanceSheetHost.citations(for reading:)` *(new)*: loading → `.loading`; failure with no value → `.failed`; value → `.ready` | D-6, AC-4.1, AC-4.2 |
| T-10 | Swift | `WorkspaceSessionTests.swift` `citationRendersRetryAfterFailure` *(new)* | FakeStore error, query → failure; clear error, `reread` → value | AC-4.3 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `ProvenanceSheetTests`, `PersonDetailTests`, `PVProvenanceColumnsTests`, `CatalogQueryRegistryTests` (a test that walks every `Kind`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`CitationLineDisplay.sourceTitle`, `titleIsRef` on `CitationLineDisplay.Parts`, `CitationRunsText` in `SourceTypeFormatsSection`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none; the rule's parenthetical is corrected in STEP-9)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/catalog-caches.md (citationRenders row); provenance-loading.md note
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project made after S15-19 (the seeded census type). On a census Source enter Jurisdiction, ED, page and, on one household graph, dwelling, family and item; cite Ada Robins's birth date from two Citations on that household row and from a Source whose type has no format.
2. Open Ada's Birth date provenance sheet. See the loading indicator briefly, then the two census records with the formatted citation ("1880 U.S. census, …; digital image, *Ancestry* …") and no rule between them (AC-3.3), and the third record with today's line and one button (bar 4, bar 7 on the sheet).
3. Click Copy full citation; paste into TextEdit (rich): "Ancestry" is italic. Paste into a plain field: plain text. Copy short citation pastes the short form.
4. Resize past 1600pt and reopen: the sheet is 1280pt and the citations wrap to fewer lines.
5. With VoiceOver: a row reads its formatted citation; the buttons speak their labels and announce the copy.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| RTF italic lost because the font has no italic face | D-11 uses the system font, which has one; T-7 checks the trait |
| A write while the sheet is open reloads the key and flashes the spinner | A refetch keeps the value (`reading` has a value), so the table stays (D-6) |
| The board draws a group heading or a menu | Brief non-goals; a board change goes to the user before this plan moves to Planned |

**Stop and report if:**

- `RenderCitationsResponse` or `CatalogCitationRender` no longer match § 4.
- `WorkspaceSession` cannot drop a key without changing `trimHiddenEntities` or `apply` (D-3).
- `Group.ValueGroup.records` cannot become computed without changing a caller outside the files in § 4 (D-7).
- The agreed S15-D9 board differs from a Decision here (then the plan is refreshed first).
- `NSAttributedString.data(from:documentAttributes:)` drops the italic trait in T-7.

## 12. Open questions

None. (Status is Blocked on the board, not on a question.)

## 13. PR

**Title:** S15-21 — The provenance sheet shows formatted citations
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-21-provenance-sheet-citations.md`.
