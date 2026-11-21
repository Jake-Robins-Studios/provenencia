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
**Context:** working rules "Citations render on demand, from SQL", "Grouping is by the rendered full citation, computed when read", "Today's line stays the fallback, in Swift", "One engine, in Go", "Build on Spike 16's caches", "One window; nothing is built for a second" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../provenance-loading.md`](../provenance-loading.md) "Load records when the sheet opens"; landed plans [`S15-16-citations-render.md`](S15-16-citations-render.md) (D-6, the group key), [`S15-17-format-editor.md`](S15-17-format-editor.md) (D-6: `CatalogCitationRender`; **Next adds**: this PR replaces `CitationRunsText` with `styled`); [`docs/catalog-caches.md`](../../../catalog-caches.md)
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

When a researcher opens a value's provenance sheet, each record's citation reads like a citation: the full citation the engine renders from the Source, its Artifact and its Evidence graph, with its italics, where the Source's type has a full format, and today's line where it has none. Two buttons copy the full and the short citation as rich text (italics kept) and plain text. Records whose full citations read the same sit together with no rule between them, so the pieces of one household row read as one citation. The citations are fetched when the sheet opens, through one cached read held only while the sheet is shown; until they arrive the record area shows the kit's load area, and on failure its notice with Read again. This is bar 4's sheet and bar 7 on the sheet.

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
| AC-3.4 | Records of two different Citations whose type has no full format (keys `citation:<id1>`, `citation:<id2>`), and a record missing from the reply | Each Citation is its own run (the engine's key); two records of one such Citation share its run; the missing one is its own run |

**US-4.** As a researcher, I see that citations are loading or could not be read.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | The render has not answered | Header and headings draw; the record area shows the kit's load area (skeleton bars captioned and spoken "Loading citations"); no rows |
| AC-4.2 | The render fails (`FakeStore.renderCitationsError`) | The record area shows only the load area's danger callout titled "Citations could not be read" with the error's message and **Read again**; no rows |
| AC-4.3 | Read again after AC-4.2, the store now succeeding | The key is read again and the table draws grouped |

## 3. Scope

| In | Covered by |
| --- | --- |
| Store method `renderCitations` (Go store, fake store) and `CatalogRenderedCitations` (US-1) | STEP-1, AC-1.3 |
| The sheet's key `CatalogQueryKey.provenanceSheet` with its descriptor and value; `WorkspaceSession.release(_:)` (D-2, D-3) | STEP-2, AC-1.3 |
| `CatalogCitationRender.styled`; `CitationRunsText` goes (PC-1) | STEP-3, AC-1.1 |
| Rich-text payload in `PVClipboardCopyState` and `PVClipboardButton` (PC-4) | STEP-4, AC-2.1 |
| Citation runs in `PVProvenanceSheetContent` and the grouping (PC-5) | STEP-5, AC-3.1 – AC-3.4 |
| The row's formatted citation, two copy buttons, the table's rules (PC-1 – PC-3, PC-8, PC-9, PC-W1) | STEP-6, AC-1.1, AC-1.2, AC-2.3, AC-2.4 |
| The sheet's record area in `PVFormLoadArea` and the feature host (PC-6, PC-7) | STEP-7, AC-4.1 – AC-4.3 |
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
| A spinner or a "Try again" style on `PVFormLoadArea` | not planned (user, 2026-11-21: the kit's load area as it is) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Sheet presenter | `macos/App/Features/Conclusions/ReconciledValueRow.swift` `ConclusionDetailRowsSection` | `.pvSheet(item: $provenanceItem)` draws `PVProvenanceSheet(content: row.provenanceContent(), columns:, idPrefix: "conclusion.detail.provenance", open:)`; closes the sheet when its row leaves |
| Sheet recipe | `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` `PVProvenanceSheet` | `PVPanel` with header, `PVProvenanceColumnHeadings`, a `ScrollView` of `PVProvenanceRecordTable` (max 560pt), Done |
| Content | `…/ProvenanceSheet/PVProvenanceSheetContent.swift` `PVProvenanceSheetContent`, `Record`, `Group`, `Group.ValueGroup` | `ValueGroup { heading; records: [Record] }`, two inits on `Group`; `Record.citation: CitationLineDisplay.Parts`; `Record.spoken` joins `citation.line` |
| Table | `…/ProvenanceSheet/PVProvenanceRecordTable.swift` `PVProvenanceRecordTable` | A `PVDivider` before every record but the first under a line (`index > 0 \|\| !followsLine`); runs keyed by `\.offset`, records by `\.element.id`; `PVProvenancePreviewData` builds records with `titleIsRef: false` |
| Row | `…/ProvenanceSheet/PVProvenanceRecordRow.swift` `PVProvenanceRecordRow.citation` | `PVInkLink` labelled `Text(verbatim: record.citation.line)` with `accessibilityLabel` of the line; one `PVClipboardButton(text: record.citation.line, label: L10n.ProvenanceSheet.copyCitation, copiedAnnouncement: …citationCopied)` in a 26pt track, aligned on `.citationFirstLineCenter` |
| Columns | `…/ProvenanceSheet/PVProvenanceColumns.swift` | `copyTrackWidth = 26`, `copyTrackSpacing = 6` |
| Clipboard | `macos/App/DesignSystem/Components/ClipboardButton/PVClipboardButton.swift` `PVClipboardCopyState` | `write: (String) -> Void`; `copy(_ text:)`; `writeToGeneralPasteboard` sets `.string` only |
| Load area | `macos/App/DesignSystem/Components/FormLoadArea/PVFormLoadArea.swift` `PVFormLoadState`, `PVFormLoadArea`; `QueryHandle.swift` `QueryRead.formLoadState` | One body for an area waiting on a read: skeleton bars and a caption, a compact `PVRetryCallout` with Read again, then `ready`. `QueryRead.formLoadState` maps a handle's `read` to it (a retry after a failure reads `.loading`) |
| Styled text | `macos/App/Platform/NameValueDisplay.swift` `NameDisplay.styled`; `DesignSystem/Components/TitleText/PVTitleText.swift` `italicizingEmphasis(_:font:)` | Platform returns an `AttributedString` with emphasis marked `.emphasized`; the view draws `Text(PVTitleText.italicizingEmphasis(styled, font:))` |
| Run text | `macos/App/Features/SourceTypes/SourceTypeFormatsSection.swift` `CitationRunsText` | A View concatenating runs, italic where marked; one caller (the format preview, which sets font, ink and its own spoken label) |
| Render types | `macos/App/Platform/GenealogyStore.swift` `CatalogCitationRun`, `CatalogCitationRender`, `CatalogPageInputs` | Decoded by `GoStore.mapCitationRender`; no store method calls `RenderCitations` |
| Wire | `api/proto/engine.proto` `RenderCitationsRequest` (`project_dir`, `citation_ids`), `RenderCitationsResponse` (`citations`, `inputs`), `RenderedCitation` (`citation_id`, `full`, `short`, `group_key`) | The generated `Provenencia_Engine_V1_Method.renderCitations` (124) exists; `macos/App/Platform/CoreInvoke.swift` `CoreMethod` has `renderCitationPreview` but no `renderCitations` wrapper. Go refuses more than 2,000 ids or 8 MiB (`citations.invalid`) |
| Group key | `core/database/citationrender/render.go` `groupKey` | `"full:<sha256>"` for a rendered full citation; `"citation:<id>"` when none, so each such Citation stands alone |
| Query keys | `macos/App/Features/Workspace/Session/CatalogQueryKey.swift` `CatalogQueryKey`, `Kind`; `CatalogQueryRegistry.swift` `CatalogQueryDescriptor.make`, `Kind.descriptor`; `CatalogLastUpdated.swift` `CatalogPageValue`, `CatalogQueryRefresh.followsInputs` | Value keys. A key not in `visibleKeys` (a place's keys) follows its descriptor's `whenHidden`; `.revalidate` (default) reloads it on a write that reaches it. There is no `.evict` policy and no public way to drop a key: `evict(_ key:)` is private; `evict(_:ids:)` skips `visibleKeys` |
| Empty-title fallback | `macos/App/Platform/CitationLineDisplay.swift` `sourceTitle(for:)`, `Parts.titleIsRef`; readers `ReconciledValueDisplay.swift` (denier name), `Features/Conclusions/ConclusionGallerySection.swift:308` (ref font), `PVProvenanceRecordTable.swift` preview | Guards a Source with no title, which the catalog refuses |
| Tests | `macos/ProvenenciaTests/ProvenanceSheetTests.swift`, `PVClipboardButtonTests.swift`, `CatalogQueryRegistryTests.swift`, `WorkspaceSessionTests.swift`, `PersonDetailTests.swift` (`tile.citation.titleIsRef`, lines 228 and 240), `ReconciledValueDisplayTests.swift` (`deniedFallsBackToTheRefThenToAPlainPhrase`) | Cover the content assembler, the copy state, the registry, the session and the denier phrase |

**Precedent.** The Copy forms (`Features/Sources/SourceCopyModel.swift` `loadState`, `Features/SourceTypes/SourceTypeCopyModel.swift`) draw `PVFormLoadArea` from `QueryRead.formLoadState` with Read again calling `session.reread(key)`; copy that. `CatalogPersonClaims` (S16-24) is a `CatalogPageValue` whose key follows its inputs through `followsInputs`; copy that for the sheet's value. `NameDisplay.styled` with `PVTitleText.italicizingEmphasis` is the styled-text shape. S15-17's `renderCitationPreview` is the store method shape (Go store, `FakeStore` reply, call log and error).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **Store.** `GenealogyStore.renderCitations(projectDir: String, citationIDs: [String]) async throws -> CatalogRenderedCitations` *(new)*. `CatalogRenderedCitation { citationID: String; full: CatalogCitationRender; short: CatalogCitationRender; groupKey: String }` *(new)*, `CatalogRenderedCitations { citations: [CatalogRenderedCitation]; inputs: CatalogPageInputs }` *(new, reply order)*, both `Sendable, Equatable`, beside `CatalogCitationRender`. The Go store sends `citationIDs` as given. Empty `citationIDs` returns an empty value without a call | One decoder of the wire (S15-17 D-6); reply order kept for S15-22, which shows Citations in its own order | A dictionary in the store — the screen that needs lookups builds it |
| D-2 | **Key and value.** `CatalogQueryKey.Kind.provenanceSheet` *(new)*, `static func provenanceSheet(project:citationIds:)` *(new)* with `ids` = the distinct non-empty ids, sorted. Value `CatalogProvenanceSheetRead: CatalogPageValue { citations: [String: CatalogRenderedCitation]; inputs: CatalogPageInputs }` *(new, `Sendable, Equatable`)* with `init(_ reply: CatalogRenderedCitations)` *(new)*, whose dictionary is built with `Dictionary(_:uniquingKeysWith: { first, _ in first })`. Descriptor: `.make(kind:, refreshes: CatalogQueryRefresh.followsInputs(CatalogProvenanceSheetRead.self), load: { key, store in let reply = try await store.renderCitations(projectDir: key.project.projectDir, citationIDs: key.ids); return CatalogProvenanceSheetRead(reply) })`; `whenHidden` is the default `.revalidate`, so a write reaching its inputs while the sheet is open reloads it. No `invalidateOn`, no patches. Only the provenance sheet uses this kind | Rule "Citations render on demand": one key while shown, the registry's refresh on its inputs. Named for the sheet's read, not its first payload: S15-29 adds records to this value and re-keys it, with no rename (rule "Records load when the sheet opens"). S15-22 gets its own key, so it never shares this one | `citationRenders` — S15-29 would rename kind, value, docs and tests; `whenHidden: .evict` — see D-3 |
| D-3 | **Release.** `WorkspaceSession.release(_ key: CatalogQueryKey)` *(new, internal)*: does nothing for a key in `visibleKeys`, else calls the private `evict(_ key:)`. Its doc says a released kind has exactly one holder, the view that queried it. The sheet host calls it (D-4) | "Nothing outlives the sheet" over the existing eviction; the visibility guard matches `evict(_:ids:)`, so a release can never pull a page's live handle | `whenHidden: .evict` (the rule's old wording) — the sheet's key is never in `visibleKeys`, so it would drop on the first write while open (user, 2026-11-21: reword the rule); a held-keys set — machinery for one caller |
| D-4 | **Host.** `ProvenanceSheetHost` *(new)* in `macos/App/Features/Conclusions/ProvenanceSheetHost.swift` *(new)* takes the row's `PVProvenanceSheetContent`, `columns`, `idPrefix`, `open`; holds `@Environment(WorkspaceSession.self)`; derives the key from `content.records.map(\.outcome.citationID)`. Modifiers: `.task(id: key) { handle = session.query(key) }` (the handle in `@State`; nil before the first run reads `.loading`), `.onChange(of: key) { old, _ in session.release(old) }`, `.onDisappear { session.release(key) }`; a cancelled task releases nothing. Load state: `handle?.read.formLoadState ?? .loading`. Read again: `session.reread(key)`. On a key change the host also sets `handle = nil` and `grouped = nil`, so the load area shows until the new key's handle arrives (no regrouping against the old renders). A key with no ids is still queried; its load returns at once with no store call. Grouped content: `@State grouped: PVProvenanceSheetContent?`, set to `content.grouped(by: value.citations)` in `.onChange(of: GroupInput(revision: handle?.revision, content: content), initial: true)` *(`GroupInput` new, a private `Equatable` pair)* when the handle has a value; the recipe gets `grouped ?? content`. The sheet content reads `WorkspaceSession` from the environment the `pvSheet` presenter inherits (`ConclusionDetailRowsSection` already reads `WorkspaceNavigation` there). `ConclusionDetailRowsSection` draws the host in place of `PVProvenanceSheet` | The recipe cannot name `WorkspaceSession` or `QueryHandle` (`docs/design-system-layers.md`); grouping runs once per value, not per body pass (§2 of that doc: recipe content is built when it opens) | Querying in `ConclusionDetailRowsSection` — it presents every row's sheet; a new recipe state enum — a third read-to-state mapping beside `PVFormLoadState` and `ConclusionDetailPresentation` |
| D-5 | **Size.** No chunking: more than 2,000 distinct ids, or 8 MiB of text, is the engine's `citations.invalid`, shown as the failed state | Scale is 1,200 records on one value; one call keeps the key one read | Splitting into calls of 2,000 — code for a case past Scale |
| D-6 | **Recipe states.** `PVProvenanceSheet` gains `load: PVFormLoadState = .ready` and `onReadAgain: () -> Void = {}` *(new; the defaults keep the existing previews compiling)*. Under the column headings it draws `PVFormLoadArea(state: load, loadingText: L10n.ProvenanceSheet.citationsLoading, errorTitle: L10n.ProvenanceSheet.citationsFailedTitle, errorMessage: { $0 }, onReadAgain: onReadAgain, accessibilityIdentifierPrefix: "\(idPrefix).citations") { ScrollView { PVProvenanceRecordTable(…) } }`, padded `PVSpacing.space5` on top. The header and column headings draw in every state. A refetch behind a value reads `.ready`, so the table stays | User, 2026-11-21: the kit's load area as it is; no rows until the read ends; only the notice on failure | Today's lines while loading — the table would reflow when runs form |
| D-7 | **Grouping.** `Group.ValueGroup` stores `citations: [CitationRun]` *(new: `struct CitationRun: Equatable { var key: String; var records: [Record] }`)*; `records` becomes computed (`citations.flatMap(\.records)`); `init(heading:records:)` stays and puts each record in its own run (key `"record:<record id>"`). `PVProvenanceSheetContent.grouped(by renders: [String: CatalogRenderedCitation]) -> PVProvenanceSheetContent` *(new, pure)* sets each record's `rendered` (D-8) and, inside each value run, gathers records by `renders[citationID]?.groupKey`, else `"record:<record id>"`, in first-appearance order. Swift adds no rule of its own about which keys group | Rule "Grouping is by the rendered full citation, computed when read" and rule "One engine, in Go": the engine's key already keeps a no-format Citation alone. A run never crosses a value heading or owner group because those say which value the records went into (AC-3.2). S15-27 folds over `citations` | Grouping across value runs — it would hide which value a record counted for; a Swift empty-full check — a second copy of `groupKey`'s rule |
| D-8 | **Record.** `Record` gains `rendered: CatalogRenderedCitation? = nil` *(new)* and `isFormatted: Bool` *(new, computed: `rendered?.full.runs.isEmpty == false`, the one test of a formatted row)* and `citationText: String` *(new, computed: `rendered.full.plain` when `isFormatted`, else `citation.line`)*; `spoken` uses `citationText` | One rule for the fallback (rule "Today's line stays the fallback") | Overwriting `citation.line` — the Source link's spoken label reads `citation.title` |
| D-9 | **Row.** When `record.isFormatted`, the link label is `Text(PVTitleText.italicizingEmphasis(rendered.full.styled, font: PVFont.body(size: PVTypeScale.bodySmall)))`; else `Text(verbatim: citation.line)`. The link's `accessibilityLabel` reads `record.citationText`. The copy track holds two `PVClipboardButton`s: full (`text: full.plain`, `rich: full.styled`, `label: L10n.ProvenanceSheet.copyFullCitation`, announcement `fullCitationCopied`, id `.copyFull`) and short (same from `short`, `copyShortCitation`, `shortCitationCopied`, `.copyShort`), the short one only when `rendered.short.runs` is non-empty; a fallback row keeps today's one button (`copyCitation`, `citationCopied`, id `.copy`). The buttons are listed by `static func copies(for record: Record) -> [Copy]` *(new, pure; `Copy` new: `.full`, `.short`, `.citation`)*. `PVProvenanceColumns` gains `var copySlots = 2` *(new)*; `copyTrackWidth` becomes an instance property, `26 * copySlots + copyTrackSpacing * (copySlots - 1)` (58 for two). The buttons sit in an `HStack(spacing: PVProvenanceColumns.copyTrackSpacing)` framed to `columns.copyTrackWidth` with `alignment: .leading`, so one button sits in the first slot. The likeness viewer (`Features/Conclusions/ConclusionPictureViewer.swift` `record`), whose row has no render, passes `copySlots: 1` in its columns and is unchanged. The styled label is one `Text`, so the `.citationFirstLineCenter` guide holds. **Rules (table):** inside a value run, a `PVDivider` is drawn before the first record of each `CitationRun` except the first run after a heading or owner line (today's `followsLine` test), and never before a later record of the same run. `ForEach` over a value run's `citations` is keyed by `\.key`, records inside by `\.element.id` | User, 2026-11-21: two buttons; rows repeat their citation and a run drops its rules | A menu or split button — a new kit control for one call site |
| D-10 | **Fallback cleanup.** `CitationLineDisplay.sourceTitle(for:)` and `Parts.titleIsRef` go: `parts` takes `title = outcome.sourceTitle` (an empty title is not handled: the catalog refuses it); `ReconciledValueDisplay`'s denier name reads `denier?.sourceTitle`; `ConclusionGallerySection`'s ref font branch goes (the title font always) | Map scope "Also": a Source title is required, so the branch guards nothing | Keeping it — dead code the map names |
| D-11 | **Styled citation and rich copy.** `CatalogCitationRender.styled: AttributedString` *(new, in `macos/App/Platform/CitationLineDisplay.swift`)*: the runs joined, each italic run marked `inlinePresentationIntent = .emphasized`, as `NameDisplay.styled` does. `PVClipboardPayload: Equatable { plain: String; rich: AttributedString? }` *(new, in `PVClipboardButton.swift`)*. `PVClipboardCopyState.write` becomes `(PVClipboardPayload) -> Void`; `copy(_ text: String, rich: AttributedString? = nil)`; `writeToGeneralPasteboard` writes `.rtf` from `static func rtfData(_ rich: AttributedString) -> Data?` *(new)* when `rich` is set, then `.string`. `rtfData` builds `NSMutableAttributedString(string: String(rich.characters), attributes: [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)])`, then for each run of `rich` with `.emphasized` sets `.font` to `NSFontManager.shared.convert(base, toHaveTrait: .italicFontMask)` over `NSRange(run.range, in: rich)`, and returns `data(from:documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])`. `PVClipboardButton` gains `rich: AttributedString? = nil` | One styled-text convention in the app; the kit turns emphasis into the italic trait without knowing what a citation is. S15-23 reuses both | HTML on the pasteboard — RTF is what macOS editors read first; a pasteboard-only builder beside a drawing one — two builders of the same text |
| D-12 | **Run text goes.** `CitationRunsText` is deleted; the format preview in `SourceTypeFormatsSection` draws `Text(PVTitleText.italicizingEmphasis(render.styled, font: PVFont.body(size: PVTypeScale.bodySmall)))` with its existing modifiers | D-11 makes it a copy of `styled` | Moving the View to `Platform/` — Platform holds formatters, not views |
| D-13 | **Copy.** `L10n.ProvenanceSheet.copyFullCitation` = "Copy full citation", `copyShortCitation` = "Copy short citation", `fullCitationCopied` = "Full citation copied", `shortCitationCopied` = "Short citation copied", `citationsLoading` = "Loading citations", `citationsFailedTitle` = "Citations could not be read" *(new)*. The failed message is the load state's (`L10n.Errors.message(for:)`); Read again is the kit's `L10n.DesignSystem.formReadAgain` | Brief PC-3, PC-6 – PC-8 | — |

**Rules this plan bends.** Rule "Citations render on demand, from SQL" names `whenHidden: .evict` for the sheet's key → that policy cannot hold a key no place shows (D-3) → user, 2026-11-21: reword it to "released when the sheet closes (`WorkspaceSession.release`)" → this planning PR rewords the rule and S15-21's scope entry in `deployment-plan.md`.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `renderCitations` *(new)* | store method | `renderCitationPreview` | Different RPC and reply; shares `mapCitationRender` and `mapPageInputs` |
| `CatalogRenderedCitation`, `CatalogRenderedCitations` *(new)* | type | `CatalogCitationPreview` | Preview carries missing and diagnostics; the batch carries a group key and inputs |
| `Kind.provenanceSheet`, `CatalogProvenanceSheetRead` *(new)* | query key, value | `personClaims`, `CatalogPersonClaims` | Keyed by citation ids, not a handle; not an entity page. Same `followsInputs` |
| `WorkspaceSession.release` *(new)* | func | private `evict(_ key:)`, `evict(_:ids:)`'s `visibleKeys` guard | Exposes the first with the second's guard; no second eviction path |
| `ProvenanceSheetHost` *(new)* | view | `ConclusionPageSectionHost`; the Copy forms' `PVFormLoadArea` use | That host draws a page section with gone and empty states; the sheet uses the forms' load area |
| — (no recipe state enum) | — | `PVFormLoadState`, `QueryRead.formLoadState`, `ConclusionDetailPresentation` | Reused: the recipe takes `PVFormLoadState` |
| `CitationRun` *(new)* | type | `Group.ValueGroup` | One level below a value run |
| `CatalogCitationRender.styled` *(new)* | func | `NameDisplay.styled`, `PVTitleText.italicizingEmphasis` | Same convention, for citation runs; replaces `CitationRunsText` |
| `PVClipboardPayload`, `rtfData` *(new)* | type, func | `PVClipboardCopyState.write`'s `String` | Extends it with an optional rich half |
| `copies(for:)`, `Copy` *(new)* | func, enum | — | The row's button list, testable without a view |
| L10n keys (D-13) *(new)* | key | `copyCitation`, `citationCopied`, `formReadAgain` | Two forms need two names; Read again is reused |

**Builds on.** The query registry and `followsInputs` (S16-24, S16-25); `PVFormLoadArea` and `QueryRead.formLoadState`; the `.emphasized` styled-text convention; S15-17's render decoder; the kit's `PVClipboardButton`.
**Deletes.** `CitationLineDisplay.sourceTitle(for:)`, `Parts.titleIsRef` and their readers' branches (D-10); `CitationRunsText` (D-12).
**Next adds.** S15-27 folds `citations` runs 50 at a time. S15-29 adds a `records` field to `CatalogProvenanceSheetRead` and re-keys `provenanceSheet` by (owner, Property) pairs. S15-23 copies with `PVClipboardButton(rich:)` and `styled`. S15-22 calls `renderCitations` under its own key and draws `styled`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A sheet's row changes records while open (a page refresh) | `ProvenanceSheetHost` | The key changes; `onChange` releases the old key and clears `handle` and `grouped` (the load area shows), `.task(id: key)` queries the new key (D-4) |
| The likeness viewer's record row | `ConclusionPictureViewer.record` | It passes `copySlots: 1`, so its row is unchanged (D-9) |
| A Citation deleted between the page read and the render | `grouped(by:)` | Missing from the dictionary → today's line, own run (AC-1.2) |
| The row leaves the page | `ConclusionDetailRowsSection.onChange(of: rows)` | Closes the sheet as today; `onDisappear` releases the key |

### Scale

At the map's Scale (300 citations per sheet, up to 1,200 records on one value): one `RenderCitations` call per sheet open (S15-16 measured 9 SELECTs at 300 and 11 at 1,200). `grouped(by:)` is one pass per value run with a dictionary of first positions, O(records), run once per value (D-4). The key holds up to 1,200 id strings; it is hashed once per query. A write reaching the key's inputs while open reloads it once (one call).

### Edges

- **Assumptions.** The table and `Group.records` assume `ValueGroup.records` is the run's records in order; `records` stays (computed) and keeps that order after gathering (T-5).
- **Neighbors.** Two records, same Citation id → the engine's same key, one run, whether or not the type has a format (T-5). Same key in two value runs → two runs (T-5). Two no-format Citations → two keys, two runs (T-5).
- **Removed inputs.** A record whose Citation is gone → fallback, own run (T-5). An empty `citationID` → not sent, fallback (T-4).
- **Real data.** None — no table or seed drives a rule here.
- **Untrusted size.** The id list is bounded by the row's records (Scale 1,200); past 2,000 the engine refuses (D-5). A duplicate id in a reply is dropped by `uniquingKeysWith` (D-2).

### Schema

None — no catalog change.

### Go core

None — S15-16 shipped the render.

### FFI

None — `RenderCitations` (124) exists.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Record area states | `PVFormLoadArea` | `DesignSystem/Components/FormLoadArea/` | D-6, unchanged. Frames 4 and 5 |
| Sheet | `PVProvenanceSheet` | `DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheet.swift` | D-6 |
| Table rules | `PVProvenanceRecordTable` | same folder | D-9. Frames 1a, 3 |
| Row citation and copy track | `PVProvenanceRecordRow` | same folder | D-9. Frames 1a, 2, 6, 7 |
| Formatted citation | `CatalogCitationRender.styled` + `PVTitleText.italicizingEmphasis` | `Platform/CitationLineDisplay.swift`; `DesignSystem/Components/TitleText/` | D-11 |
| Copy buttons | `PVClipboardButton` | `DesignSystem/Components/ClipboardButton/` | D-11 |
| Host | `ProvenanceSheetHost` *(new)* | `Features/Conclusions/` | D-4 |

Frames in words until the board is agreed: **1a** the Birth date sheet with three records, two 1880-census records with the same full citation and no rule between them, each with two copy buttons, and a parish-register record with today's line and one button; **1b** the same at 1280pt; **2** Copy short citation in its check state; **3** owner groups with a same-citation pair in the first group; **4** loading (the kit load area's skeleton bars, "Loading citations"); **5** failed (the load area's callout with Read again); **6** a five-line citation with buttons level with its first line; **7** a formatted row with no short format; **8** spoken annotations.

States: loading and failed (D-6), ready; a sheet with no citation ids loads with no store call (D-4). Accessibility: spoken lines (D-8), button labels and announcements (D-13), the load area's own label and callout.

### Strings

L10n keys *(new)* as D-13. Kept: `L10n.ProvenanceSheet.copyCitation` and `citationCopied` (the fallback row).

## 7. Steps

**STEP-1 — The store renders a batch.**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `CoreInvoke.swift`, `macos/ProvenenciaTests/OnboardingModelTests.swift`. Skill: `add-swift-test`.
Do: D-1. `CoreMethod.renderCitations = Int32(Provenencia_Engine_V1_Method.renderCitations.rawValue)` *(new)*. `OnboardingModelTests`' `ThrowingStore` gains `renderCitations` throwing `StoreBoom.boom`, as its `renderCitationPreview` does. `FakeStore`: `renderCitationsReplies: [String: CatalogRenderedCitation]` (by id; the reply is the asked ids found there, in asked order), `renderCitationsInputs: CatalogPageInputs` (the reply's inputs, default empty), `renderCitationsHold = FakeHold()` (awaited before the reply, as the other held methods do), `renderCitationsCalls: [[String]]`, `renderCitationsError: Error?`. The `GoStore` mapping is checked by the manual check (no test reaches `GoStore`, as for `renderCitationPreview`).
Check: `xcodebuild test … -only-testing:ProvenenciaTests/CatalogSessionStoreTests` builds; T-1 passes.

**STEP-2 — The sheet's key and release.**
Files: `CatalogQueryKey.swift`, `CatalogQueryRegistry.swift`, `CatalogLastUpdated.swift` (`extension CatalogProvenanceSheetRead: CatalogPageValue {}`), `GenealogyStore.swift` (`CatalogProvenanceSheetRead`), `WorkspaceSession.swift`, `macos/ProvenenciaTests/CatalogQueryRegistryTests.swift` (any test that lists every `Kind` gains `.provenanceSheet`). Skill: `add-workspace-place`.
Do: D-2, D-3.
Check: T-2, T-3 pass.

**STEP-3 — Citations are styled text.**
Files: `Platform/CitationLineDisplay.swift`, `Features/SourceTypes/SourceTypeFormatsSection.swift`.
Do: D-11 (`styled`), D-12.
Check: build passes; T-7 passes; the format editor's preview still draws italics (its existing tests pass).

**STEP-4 — The clipboard writes rich text.**
Files: `DesignSystem/Components/ClipboardButton/PVClipboardButton.swift`, `macos/ProvenenciaTests/PVClipboardButtonTests.swift`. Skill: `add-ui-component`.
Do: D-11 (the payload, `rtfData`, the write, the button's `rich:`). Existing view callers compile unchanged. The tests' `state(...)` helper records payloads: `written` becomes `[PVClipboardPayload]` and existing expectations read `.map(\.plain)`.
Check: T-6, T-7b pass; existing `PVClipboardButtonTests` pass.

**STEP-5 — Content groups by citation.**
Files: `PVProvenanceSheetContent.swift`, `PVProvenanceRecordTable.swift` (preview data), `macos/ProvenenciaTests/ProvenanceSheetTests.swift`.
Do: D-7, D-8.
Check: T-4, T-5 pass; existing `ProvenanceSheetTests` pass.

**STEP-6 — The row and table draw it.**
Files: `PVProvenanceRecordRow.swift`, `PVProvenanceRecordTable.swift`, `PVProvenanceColumns.swift`, `Features/Conclusions/ConclusionPictureViewer.swift`, `Platform/L10n.swift`, `Localizable.xcstrings`, `macos/ProvenenciaTests/PVProvenanceColumnsTests.swift`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-9, D-13 (copy keys). Previews: a formatted row, a fallback row, a same-citation run.
Check: build; T-8 passes; `PVProvenanceColumnsTests.columnsFollowTheWidthClass` gains `#expect(PVProvenanceColumns().copyTrackWidth == 58)` and `#expect(PVProvenanceColumns(copySlots: 1).copyTrackWidth == 26)`.

**STEP-7 — The sheet's load area and its host.**
Files: `PVProvenanceSheet.swift`, `Features/Conclusions/ProvenanceSheetHost.swift` *(new)*, `Features/Conclusions/ReconciledValueRow.swift`, `L10n.swift`, `Localizable.xcstrings`.
Do: D-4, D-6, D-13 (state keys). Previews for loading and failed.
Check: T-9, T-10 pass.

**STEP-8 — The empty-title fallback goes.**
Files: `Platform/CitationLineDisplay.swift`, `Platform/ReconciledValueDisplay.swift`, `Features/Conclusions/ConclusionGallerySection.swift`, `PVProvenanceRecordTable.swift`, `macos/ProvenenciaTests/PersonDetailTests.swift`, `macos/ProvenenciaTests/ReconciledValueDisplayTests.swift`.
Do: D-10. In `PersonDetailTests` delete the untitled-picture block (lines 236–240: a Source with no title is a state the catalog refuses) and the `!tile.citation.titleIsRef` line (228). In `ReconciledValueDisplayTests.deniedFallsBackToTheRefThenToAPlainPhrase` drop the `noTitle` case and rename the test `deniedNamesTheDeniersSourceOrAPlainPhrase`, keeping the `gone` case ("denied") and adding a titled denier ("denied by <title>").
Check: `rg "titleIsRef|sourceTitle\(for" macos/App macos/ProvenenciaTests` prints only the Evidence graph file rows' own `titleIsRef` (`Features/EvidenceGraph/EvidenceGraphFiles.swift`, `EvidenceGraphView.swift`, `EvidenceGraphModelTests.swift`); tests pass.

**STEP-9 — Docs.**
Files: `docs/catalog-caches.md` (the "Per-view query results" row gains: "`provenanceSheet` is held only while a provenance sheet is shown and released when it closes (`WorkspaceSession.release`); it follows its inputs"), `docs/deployment-plan/spike-15/deployment-plan.md` (map row status `Landed [#N](…)`), `docs/deployment-plan/spike-15/provenance-loading.md` (the first step landed: key `provenanceSheet`), `docs/deployment-plan/spike-15/completed.md`, this plan, the brief → `design/archive/`, `design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-21-provenance-sheet-citations.md` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log`. No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/CatalogSessionStoreTests.swift` `renderCitationsAnswersTheAskedIds` *(new)* | A FakeStore reply for ids a, b; ask a, b, c → `citations` holds a then b; empty ids → empty value, no call logged | D-1, AC-1.2 |
| T-2 | Swift | `CatalogQueryRegistryTests.swift` `provenanceSheetKeySortsAndFollowsInputs` *(new)* | `provenanceSheet(citationIds: ["b","a","a",""])` has ids `["a","b"]`; a reply holding id a twice builds one entry; with `renderCitationsInputs.sources = ["s1"]`, query and settle, then `session.apply(CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .sourceRecords, ids: ["s1"])]))` → a second store call is logged | D-2 |
| T-3 | Swift | `WorkspaceSessionTests.swift` `releaseDropsTheKey` *(new)* | Query, then `release` → `queryHandle(key)` is nil; a second `query` calls the store again; `release` while the first load is in flight (`renderCitationsHold` on) → that load's value never lands on the new handle; `release` of a key in `visibleKeys` (a place's key) leaves its handle | D-3, AC-1.3 |
| T-4 | Swift | `ProvenanceSheetTests.swift` `citationTextFallsBack` *(new)* | Record with rendered full runs → `citationText` is the plain; empty full or nil → `citation.line`; `spoken` contains `citationText` | D-8, AC-1.1, AC-1.2 |
| T-5 | Swift | `ProvenanceSheetTests.swift` `groupedGathersByEngineKeyWithinARun` *(new)* | Run a(K), b(L), c(K) → runs [a,c], [b]; K in two value runs → separate; `citation:1` and `citation:2` → two runs; two records of `citation:1` → one run; a record missing from the renders → own run; `records` order a, c, b | D-7, AC-3.1, AC-3.2, AC-3.4 |
| T-6 | Swift | `PVClipboardButtonTests.swift` `copyWritesRichAndPlain` *(new)* | `copy("x", rich: r)` → write receives payload with plain "x" and rich r; `copy("x")` → rich nil | D-11, AC-2.1, AC-2.4 |
| T-7 | Swift | `ProvenanceSheetTests.swift` `styledMarksItalicRuns` *(new)* | Runs plain "a", italic "b" → `styled` text "ab", "b" `.emphasized`, "a" not | D-11, AC-1.1 |
| T-7b | Swift | `PVClipboardButtonTests.swift` `rtfKeepsEmphasisAsItalic` *(new)* | `rtfData` of "a" + emphasized "b", read back with `NSAttributedString(rtf:documentAttributes:)` → "b" has the italic trait, "a" does not | D-11, AC-2.1 |
| T-8 | Swift | `ProvenanceSheetTests.swift` `copyButtonsFollowTheRender` *(new)* | `PVProvenanceRecordRow.copies(for:)`: full+short → [.full, .short]; empty short → [.full]; fallback → [.citation] | D-9, AC-2.2, AC-2.3, AC-2.4 |
| T-9 | Swift | `WorkspaceSessionTests.swift` `provenanceSheetLoadStates` *(new)* | Held store: `query(key).read.formLoadState` is `.loading`; with `renderCitationsError` → `.failed(L10n.Errors.message(for:))`; success → `.ready` | D-4, D-6, AC-4.1, AC-4.2 |
| T-10 | Swift | `WorkspaceSessionTests.swift` `provenanceSheetReadAgainAfterFailure` *(new)* | FakeStore error, query → failure; clear error, `reread` → value | AC-4.3 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `ProvenanceSheetTests`, `PersonDetailTests`, `ReconciledValueDisplayTests`, `PVProvenanceColumnsTests`, `CatalogQueryRegistryTests` (a test that walks every `Kind`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`CitationLineDisplay.sourceTitle`, `titleIsRef` on `CitationLineDisplay.Parts`, `CitationRunsText`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (the planning PR reworded it; check it still reads "released when the sheet closes")
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated: docs/catalog-caches.md (provenanceSheet row); provenance-loading.md note
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project made after S15-19 (the seeded census type). On a census Source enter Jurisdiction, ED, page and, on one household graph, dwelling, family and item; cite Ada Robins's birth date from two Citations on that household row and from a Source whose type has no format.
2. Open Ada's Birth date provenance sheet. See the load area briefly, then the two census records with the formatted citation ("1880 U.S. census, …; digital image, *Ancestry* …") and no rule between them (AC-3.3), and the third record with today's line and one button (bar 4, bar 7 on the sheet).
3. Click Copy full citation; paste into TextEdit (rich): "Ancestry" is italic. Paste into a plain field: plain text. Copy short citation pastes the short form.
4. Resize past 1600pt and reopen: the sheet is 1280pt and the citations wrap to fewer lines.
5. With VoiceOver: a row reads its formatted citation; the buttons speak their labels and announce the copy.
6. Open a likeness in the Person page gallery: the viewer's record row looks as before (one copy button, no wider track).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| RTF italic lost because the font has no italic face | D-11 uses the system font, which has one; T-7b checks the trait after a round trip |
| A write while the sheet is open reloads the key and flashes the load area | A refetch keeps the value, so `read.formLoadState` stays `.ready` (D-6) |
| The board draws a group heading, a menu or its own loading state | Brief non-goals and inventory; a board change goes to the user before this plan moves to Planned |

**Stop and report if:**

- `RenderCitationsResponse` or `CatalogCitationRender` no longer match § 4.
- `WorkspaceSession` cannot drop a key without changing `trimHiddenEntities` or `apply` (D-3).
- `Group.ValueGroup.records` cannot become computed without changing a caller outside the files in § 4 (D-7).
- The agreed S15-D9 board differs from a Decision here (then the plan is refreshed first).
- T-7b shows `rtfData` dropping the italic trait.
- `PVFormLoadArea` cannot sit inside `PVPanel` above a `ScrollView` without a kit change (D-6).

## 12. Open questions

None. (Status is Blocked on the board, not on a question.)

## 13. PR

**Title:** S15-21 — The provenance sheet shows formatted citations
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-21-provenance-sheet-citations.md`.
