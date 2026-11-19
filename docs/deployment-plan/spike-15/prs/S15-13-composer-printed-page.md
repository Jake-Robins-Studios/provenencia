# S15-13 — The composer records the printed page

**Status:** Landed in [#863](https://github.com/Jake-Robins-Studios/provenencia/pull/863) (2026-11-16)
**Spike / slice:** Spike 15 · Slice 3 — Printed page
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D8](../design/archive/S15-D8-citation-composer-printed-page.md), board agreed 2026-11-16
**Board:** agreed 2026-11-16 (user) — [Claude Design — Citation Composer](https://claude.ai/artifact/3GSFQZjqdQjL8v2rpgMiDc), page *Citation Composer*, section "S15-D8 · The printed page, on the app’s width classes": frames 1a, 1b, 2a, 2b, 3 (empty, "iv" typed), Tab order note, 4a, 4b, 5, 6, 7, 8a, 8b, Kit used. Board decisions: Label and Printed page share a row when the form's column fits both (Label at least 180pt, Printed page 140pt), else Printed page sits directly under Label (the stacked form at 1102pt stacks; at 1464pt it fits beside; the 440pt side form always shares a row); the help is the Input's tooltip, not a hint line; neither column widens at Wide (form 440pt, Observations 520pt, the viewer takes the rest); copy as § 2.1. The implementer opens the link; § 6 macOS also describes each frame's layout in words
**Depends on:** S15-50 (`PVFieldFocus(_:equals:in:)`, PR #862, not yet merged: this PR is stacked on its branch `s15-50-forms-list-their-tab-order`), S15-D8
**Blocks:** S15-45
**Branch:** `s15-13-composer-printed-page`
**Version bump:** minor, 0.16.0 (today's `VERSION`) → **0.17.0** (or the next minor after `main`'s `VERSION` when you rebase): `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`. A backward-compatible feature: a new composer field, and the locator accepts a page selector that holds only `page_label` ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table-driven Go tests)
**Context:** [`interpretation-layer-data-model.md` § 3.2](../../../interpretation-layer-data-model.md#32-page-selector); [`evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 1 and § 6.9; [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide); [`docs/ideas/wide-layout.md`](../../../ideas/wide-layout.md) (the Citation composer row); working rule "Citations carry no metadata"
**Planned:** 2026-11-16 against `main` @ `0a90a17`. Refreshed 2026-11-16 against S15-50's head `a4ce91c61` (PR #862): `CitationFormFocus { label, transcription }` is internal in `CitationComposerEvidenceColumn.swift`, held as `@FocusState private var formFocus` there, with `sideForm` `[.label, .transcription]` and `panelForm` `[.transcription, .label]` through `PVFieldFocus($formFocus, equals:, in: order)`; D-12, D-13 and STEP-4 hold as written. S15-50 also made `init(_:equals:next:previous:)` private: neighbours come only from `in:`
**Review:** [`S15-13-composer-printed-page.review.md`](S15-13-composer-printed-page.review.md) — Fits with changes — Ready with changes, round 1

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

A citation names the page of the original record ("p. 14", "fol. 17r", "iv"), not where that page sits in the researcher's file. The locator has a slot for it (`page_label` on the `page` selector), but the composer never writes it, so every citation line reads "image 37". After this PR the composer has a **Printed page** field next to **Label** on image and PDF Artifacts, it saves with the Citation, and the citation line on the Person, Event and Place pages reads "p. 14". An image Artifact (a census page saved as a JPEG) has no file page, so the locator's page selector may now hold the printed page alone (user, 2026-11-16). The composer also moves off its own 1400pt layout switch onto the app's Regular and Wide classes (user, 2026-11-16).

**Why now.** Slice 3 of the map; S15-16's `{citation.page}` built-in and S15-21's grouping by rendered citation read this value, and S15-45 marks it.

**What stays.** The locator strip, the file viewer, the Observations column, the authoring box, the edit dialog, depiction rules and the citation line's words. The Citation carries no metadata (working rule).

## 2. User stories

**US-1.** As a researcher citing a census page saved as an image, I type the printed page in the composer so that the citation names the page a reader can find.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Image Artifact, Citation CIT-7KQ2M open; type "14" in Printed page; Save | The stored locator is `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","page_label":"14"},{"type":"region",…}]}`; the citation line on the Person page reads "…, p. 14" |
| AC-1.2 | PDF Artifact, the Citation on page 37; type "23"; Save | The page selector is `{"type":"page","artifact_page":37,"page_label":"23"}`; the citation line reads "…, p. 23" |
| AC-1.3 | A PDF Citation with Entire artifact (no file page); type "iv"; Save | Saved as a label-only page selector; the citation line reads "…, p. iv" |
| AC-1.4 | Printed page "  14 " typed; Save | Stored `"page_label":"14"` |
| AC-1.5 | Printed page holds only spaces; Save | No `page_label` is written; with no file page, no page selector is written |
| AC-1.6 | An audio Artifact | No Printed page field |

**US-2.** As a researcher, I edit and switch Citations without losing or leaking the printed page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Open a saved Citation whose locator has `page_label` "23" | The field shows "23"; the form is not dirty |
| AC-2.2 | Change the printed page | The form is dirty, Save is enabled, leaving asks |
| AC-2.3 | Printed page "23", then Reset to entire artifact, remove the page, or clear the region | The printed page is still "23" |
| AC-2.4 | **New citation** from the Citation menu | The printed page is empty |
| AC-2.5 | Citation menu rows on a PDF: CIT-3HW8D (page 37, "23", region), a Citation on page 40 with no printed page, one on Entire artifact with none; on an image: CIT-7KQ2M ("14", region), one with "15" and no region | "p. 23 · image 37 · region", "image 40", ""; "p. 14 · region", "p. 15" — in the composer's menu and the Observation dialog's |
| AC-2.6 | Delete the open Citation (the composer keeps its spot for a new one) | The blank Citation keeps the locator and the printed page, as it keeps the page and region today (D-5) |
| AC-2.7 | Pick another Artifact in the Artifact menu | The printed page is empty (the locator resets to Entire artifact) |

**US-3.** As a researcher on a big monitor or a laptop, the composer lays out by the app's width class.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Pane 1102pt or 1464pt (Regular) | The form stacked above the viewer, Observations beside (today's `.panel`) |
| AC-3.2 | Pane 1600pt or 2296pt (Wide) | Viewer, 440pt form, 520pt Observations side by side (today's `.side`) |
| AC-3.3 | Cursor in Printed page with unsaved "23a"; resize across 1600pt | The text, the dirty state and the cursor in Printed page stay |
| AC-3.4 | Tab from Label in each layout | Side: Label → Printed page → Transcription; panel: Transcription → Label → Printed page; Shift-Tab reverses; on an audio Artifact Printed page is skipped |

**US-4.** As the engine, I accept a page selector that holds only the printed page and keep depiction rules on file pages.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `{"type":"page","page_label":"14"}` | Valid; `locator.Page` → `PageRef{ArtifactPage: 0, Label: "14"}` |
| AC-4.2 | `{"type":"page"}`, `{"type":"page","page_label":"  "}`, `{"type":"page","artifact_page":0,"page_label":"4"}` | `ErrInvalid` |
| AC-4.3 | Any locator with two page selectors (label-only or not) | `Validate` → `ErrInvalid` |
| AC-4.4 | Depiction region with no page, Citation locator label-only | Valid (no file page on either) |
| AC-4.5 | Depiction region on page 1, Citation locator label-only | `ErrInvalid` |
| AC-4.6 | Depiction region document whose page selector is label-only | `ErrInvalid` (a region names a file page) |
| AC-4.7 | `{"type":"page","artifact_page":37,"page_label":""}` | Valid; `Page` → `{37, ""}` (unchanged) |

## 3. Scope

| In | Covered by |
| --- | --- |
| Go: label-only page selector, one page selector per document, `locator.PageRef` | STEP-1, AC-4.* |
| CP-1, CP-2, CP-3, CP-4: the Printed page field, when offered, independent of the locator strip, saving | STEP-2, STEP-3, STEP-4, AC-1.*, AC-2.1 – AC-2.4, AC-2.6, AC-2.7 |
| CP-5: the Citation menu rows, one shared menu for both Citation menus | STEP-5, AC-2.5 |
| CP-6, CP-7: VoiceOver, Tab order through S15-50's ordered `PVFieldFocus` | STEP-4, AC-3.4 |
| CP-W1, CP-W2: Regular and Wide, focus and edits kept across the line | STEP-6, AC-3.1 – AC-3.3 |
| Domain doc § 3.2, `wide-layout.md` row, map row | STEP-7 |

| Out | Home |
| --- | --- |
| The ordered focus handle itself and moving `PVTabPair`'s callers | S15-50 |
| Unknown, Supplied and the needed flag on the printed page | S15-44 (Go), S15-45 (Swift, S15-D24) |
| Keeping the page selector's unmodeled keys on a Swift save (none exist until S15-44 adds `page_unknown`, `page_supplied`) | S15-45 (it models them) |
| A per-Artifact page map ("image 37 is page 23") | not planned (map § 7, "Refused in this spike") |
| `{citation.page}` in formats, grouping | S15-14, S15-16, S15-21 |
| Changing the citation line's words | not planned: it already prints "p. 14" |
| Showing the printed page in the locator strip | not planned (S15-D8 non-goal) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Locator validation | `core/locator/validate.go` `validatePage`, `validateDoc` | `validatePage` refuses a page selector without `artifact_page ≥ 1`; `validateDoc` checks selectors one at a time and accepts two page selectors |
| Locator page read | `core/locator/depiction.go` `citationPage`, `Page` | `citationPage` derefs `*sel.ArtifactPage`, refuses a second page selector itself; `Page(json) (int, string)` returns `(artifact_page, trimmed page_label)`; its one caller is `core/database/graphfill/load.go:217` |
| Depiction rule | `core/locator/depiction.go` `ValidateDepictionRegion`, `regionDocPages` | Compares the region's page with the Citation's; `regionDocPages` derefs `*sel.ArtifactPage` and counts pages itself (`len(pages) > 1`) |
| Locator writes | `core/database/citations/citations.go` (lines 169, 321) | `locator.Validate` on create and update |
| Citation line words | `core/database/graphfill/load.go` `loadGraphObservations` (`citationWords`) | `locator.Page` per Citation into `ArtifactPage`, `PageLabel`; a `citations` row change refills the graph (`core/database/effects/registry.go` `"citations"`) |
| Citation line | `macos/App/Platform/CitationLineDisplay.swift` `parts` | `L10n.Conclusions.citationPagePrinted` "p. %@" from `pageLabel`, else `citationPageImage` "image %lld" |
| Swift locator draft | `macos/App/Features/CitationComposer/CitationLocatorDraft.swift` `CitationLocatorDraft` | `page`, `region`, `extras`, an unused `hasPage`. `decode` ignores `page_label` and drops a page selector with no `artifact_page`; `encodeJSON` never writes `page_label`. So editing a Citation that has a label and saving erases it |
| Capabilities | `macos/App/Features/ArtifactViewer/ArtifactViewerKind.swift` `ArtifactLocatorCapabilities`, `locatorCapabilities` | `supportsPageLocator` (PDF), `supportsRegionLocator` (image, PDF), `supportsSpatialZoom`, `supportsTimeRangeLocator`. `ArtifactViewerModel.kind` starts `.unsupported` until a file loads |
| Fields draft | `macos/App/Features/CitationComposer/CitationFieldsDraft.swift` `Values`, `isDirty`, `replace(from:)`, `resetBlank(keepLocator:)` | The locator is in `Values`, so a locator change marks the form dirty |
| Model | `macos/App/Features/CitationComposer/CitationComposerModel.swift` `citationDescription`, `locator`, `removePage`, `resetToEntireArtifact`, `clearRegion`, `applySelectedArtifact` (sets `fields.locator = .artifactOnly()`), `confirmPendingImpact` (after a Citation delete: `resetComposerIdentity(keepLocator: true)`) | Bindings over `fields` |
| Citation form | `macos/App/Features/CitationComposer/CitationComposerEvidenceColumn.swift` `sideForm`, `panelForm`, `labelField`, `transcriptionColumn` | `@FocusState private var formFocus: CitationFormFocus?` in the column, with ordered `PVFieldFocus(_:equals:in:)` handles (S15-50); side: Label then transcription; panel: transcription (1.5) beside Label (1) |
| Citation menus | `CitationComposerEvidenceColumn.citationSelect`, `citationOptions`, `menuLocator`; `CitationComposerAuthoringBox.swift` (around line 570: its own `PVSelect`, `citationOptions`, `menuLocator`) | Two copies of the menu: the options, the "New citation · on this artifact" row, `CitationStepMenuRow(listed:locator:)`, and `menuLocator`, which prints `L10n.CitationComposer.menuPage` "p. %lld" for the **file** page. They differ in size, `menuWidth`, `maxVisibleRows`, `rowHeight`, the disabled condition, the accessibility id |
| Composer split | `macos/App/Features/CitationComposer/CitationComposerView.swift` `composeSplit`, `evidence(threeUp:height:)` | `GeometryReader`; `threeUp = geo.size.width >= 1400` picks `.side` vs `.panel`; Observations at 520pt |
| Width class | `macos/App/DesignSystem/Components/WidthClass/PVWidthClass.swift`; `WorkspaceDestinationHost` measures every destination, the composer included | Not read by the composer |
| Focus across widths | `macos/App/Platform/FocusKeeper.swift` `focusKeeper(_:focus:isShown:fallback:map:scroll:)` | Used by `ConclusionGallerySection`, `PersonTimelineSection` |
| Fake store | `macos/App/Platform/FakeStore.swift` `updateCitation` | Writes the locator to `citationsByID[id].locatorJSON` |
| Tests | `core/locator/validate_test.go` `TestValidate`, `TestPage`; `core/locator/depiction_test.go` `TestValidateDepictionRegion`; `core/database/citations/citations_test.go`; `core/database/graphfill/records_test.go` `TestGraphRecordsCarryCitationWords`; `macos/ProvenenciaTests/CitationLocatorDraftTests.swift`; `CitationComposerModelTests.swift`; `ArtifactViewerModelTests.swift` | No label-only case; no `page_label` round trip in Swift |

**Precedent.** The width-class read: `SourcesListColumns.init(listWidth:widthClass:)` and `PromoteView` (`@Environment(\.pvWidthClass)`). Focus kept across the line: `ConclusionGallerySection.swift` `.focusKeeper(...)`. A model binding over the fields draft: `CitationComposerModel.citationDescription`. Table rows in Go: `TestPage`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | A `page` selector is valid with `artifact_page ≥ 1`, or with no `artifact_page` and a non-blank `page_label`. `artifact_page` present and `< 1` stays invalid; a blank label beside a valid file page is valid and reads as none | Images have no file page; the user asked for an optional field (2026-11-16) | `artifact_page: 1` on images — breaks `ValidateDepictionRegion` (a region on an image has no page); a new selector type — two homes for one fact |
| D-2 | "At most one page selector" moves into `validateDoc`, once, for Citation locators and region documents; `citationPage` and `regionDocPages` drop their own counts. `citationPage` returns `page = 0` for a label-only selector. `ValidateDepictionRegion` compares file pages only: a document "has a file page" when `page > 0` | One rule in one place; AC-4.3 holds at write time; S15-44 extends `validatePage` without touching the counts. Only the composer writes locators, always with one page selector, so stored documents keep validating | Keeping the two counts — the rule in two read paths and not at write |
| D-3 | `regionDocPages` refuses a page selector without `artifact_page` (`ErrInvalid`) | A depiction region names the file page it is drawn on; no client writes a label there | Allowing it — nil deref today |
| D-4 | `locator.Page(json) PageRef` *(changed)*, `type PageRef struct { ArtifactPage int; Label string }` *(new)*; zero value = no page selector. `graphfill` reads its fields | S15-44 adds the mark as a field, not a signature change, before S15-16 becomes a second caller | Keeping the tuple — widened twice |
| D-5 | Swift: `CitationLocatorDraft.pageLabel: String` *(new)*, `""` = none. `encodeJSON` writes one page selector when `page ≥ 1` or the trimmed label is non-empty, with `artifact_page` only when `page` is set and `page_label` (trimmed) only when non-empty. `decode` reads a string `page_label` (trimmed) from the page selector, with or without `artifact_page`, and ignores a non-string one. `hasPage` (unused) is deleted | One value with the locator it lives in; the dirty check, the leave guard and keep-locator resets already follow `Values.locator` | A separate value in `CitationFieldsDraft.Values` — two values merged at encode |
| D-6 | `isArtifactOnly`, `removePage`, `resetToEntireArtifact`, `clearRegion`, `setPage`, `setRegion` and `peelIllegalLayers` leave `pageLabel` alone. `resetBlank(keepLocator: true)` (after a Citation delete) keeps it with the locator (AC-2.6); `applySelectedArtifact` and **New citation** reset the locator to `.artifactOnly()`, so it is empty (AC-2.4, AC-2.7) | CP-3: not a layer of where the Citation is in the file; after a delete the composer keeps the spot, and the printed page belongs to the spot | Clearing it with the page — loses typed text |
| D-7 | `ArtifactLocatorCapabilities.supportsPrintedPage` *(new)*: `true` for `.image` and `.pdf`, `false` for `.audio`, `.video`, `.unsupported`. The field shows only when it is true, so it is hidden while the viewer is still loading (`kind` `.unsupported`), as Paste and Auto transcribe are. A stored label on a Citation of another kind is kept on save and not shown | Capabilities are the kind-gated flags hosts read ("Hosts must not branch on MIME strings"); lossless | `isImageArtifact \|\| isPDFArtifact` in the view — a second kind switch |
| D-8 | `CitationComposerModel.pageLabel: String` *(new)* get/set over `fields.locator.pageLabel`, as `citationDescription` is. Data names say `pageLabel` (the wire's `page_label`, `CatalogReconcilerOutcome.pageLabel`); copy, the capability and the view say "printed page". The field binds raw; trimming happens only in `encodeJSON` | One data name; same shape as Label | Trimming on each keystroke — moves the cursor |
| D-9 | One Citation menu: `CitationStepMenu` *(new, in `CitationComposerEvidenceColumn.swift`)* takes `selection`, `size`, `menuWidth`, `maxVisibleRows`, `rowHeight`, `isDisabled`, `accessibilityIdentifier`, and owns the options, the "New citation · on this artifact" row and `CitationStepMenuRow`. Both call sites use it; both `citationOptions` and both `menuLocator` go. `CitationStepMenuRow` computes its locator text with `static func locatorText(_ locator: CitationLocatorDraft) -> String` *(new)*: `[printed page, file page, region]`, each when present, joined by " · " | CP-5 changes both menus; one row and one menu make the next change (S15-45's flag) once | Editing both copies |
| D-10 | The page words have one home: `CitationLineDisplay.printedPage(_ label: String) -> String` and `filePage(_ page: Int) -> String` *(new)* wrap the existing `L10n.Conclusions.citationPagePrinted` and `citationPageImage`; `parts` and `locatorText` both call them. `L10n.CitationComposer.menuPage` is deleted; no menu key is added | "p." means the printed page everywhere, in one translation | New composer keys with the same words |
| D-11 | `CitationComposerColumnLayout.init(_ widthClass: PVWidthClass)` *(new)*: `.wide` → `.side`, `.regular` → `.panel`. `composeSplit` reads `@Environment(\.pvWidthClass)`; `evidence(threeUp:height:)` becomes `evidence(layout:height:)`. The `GeometryReader` stays for the panel's 55% height | CP-W1 (user, 2026-11-16) | Keeping 1400pt — the user asked for the move |
| D-12 | Tab order: S15-50's `CitationFormFocus` gains `printedPage` (`{ label, printedPage, transcription }`) and `static func order(_ layout: CitationComposerColumnLayout, printedPageOffered: Bool) -> [CitationFormFocus]` *(new)*: `.side` → label, printedPage, transcription; `.panel` → transcription, label, printedPage; `printedPage` dropped when not offered. Each field's handle is `PVFieldFocus($formFocus, equals: field, in: order)` (S15-50), with `formFocus` held by `CitationComposerView` (above the layout switch) and passed down as a `FocusState<CitationFormFocus?>.Binding`; S15-50's `@FocusState` in `CitationComposerEvidenceColumn` goes | The order is the composer's one real decision; the mechanism is the kit's (user, 2026-11-16) | A feature-private next/previous ring — a second mechanism |
| D-13 | Focus across the line: `CitationComposerView` holds `@FocusState var formFocus: CitationFormFocus?` and `@State var formKeeper: FocusKeeper<CitationFormFocus>`, and applies `.focusKeeper($formKeeper, focus: $formFocus, isShown: { order.contains($0) }, fallback: { _ in nil }, map: { $0 }, scroll: { _ in })` | CP-W2: the column is rebuilt when the layout changes; focus held above it survives, and `FocusKeeper` re-claims on a width change | `@FocusState` in the column — lost on rebuild |
| D-14 | Copy and keys follow § 6 Strings, which the agreed board uses word for word ("Printed page", "As printed, such as 14 or iv", the help sentence as the Input's tooltip, "Save citation" unchanged) | The board matched the brief's copy | — |
| D-16 | Placement (board): `labelAndPrintedPage` *(new, private view in `CitationComposerEvidenceColumn.swift`)* is `ViewThatFits(in: .horizontal)` over an `HStack` (Label `.frame(minWidth: 180)`, Printed page `.frame(width: 140)`) and a `VStack` (Label, then Printed page); both forms use it, so the side form (440pt) always shares a row and the stacked form's right column stacks at 1102pt and shares a row at 1464pt. Help: `printedPageHelp` as `.help(...)` on the Input and its accessibility hint, not `PVField(hint:)`. At Wide no column widens (`440`, `520` stay). The panel's Tab order stays transcription, Label, Printed page in both placements | The agreed board (frames 1a, 1b, 7, "Where the field sits") | Measuring the column width by hand — `ViewThatFits` decides from the space it is given |
| D-15 | No length cap on the printed page beyond the locator's `MaxDocumentBytes` (64 KiB) | Matches every other locator string | A new cap — a rule with no need |

**Rules this plan bends.** None. The `PVTabPair` rule in `add-ui-component` and `DesignSystem/README.md` is replaced by S15-50 before this PR (user, 2026-11-16). The map row's scope grew to Go + Swift and the width-class move; the map says so (user, 2026-11-16).

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `locator.PageRef` *(new)* | type | `Page`'s tuple | Replaces it (D-4) |
| `CitationLocatorDraft.pageLabel` *(new)* | field | `CitationLocatorDraft.page` | Extends the draft that owns the JSON round trip (searched `pageLabel`, `page_label` in Swift: the proto and `CatalogReconcilerOutcome`) |
| `ArtifactLocatorCapabilities.supportsPrintedPage` *(new)* | field | `supportsPageLocator` | That flag means a file page; images need the printed page without it |
| `CitationComposerModel.pageLabel` *(new)* | property | `citationDescription` | Same shape, new value |
| `CitationStepMenu` *(new)* | view | the two `PVSelect` blocks in `CitationComposerEvidenceColumn` and `CitationComposerAuthoringBox` | Replaces both |
| `CitationStepMenuRow.locatorText(_:)` *(new)* | func | the two private `menuLocator` | Replaces both |
| `CitationLineDisplay.printedPage(_:)`, `filePage(_:)` *(new)* | func | the inline branches in `CitationLineDisplay.parts` | Same words, now shared |
| `labelAndPrintedPage` *(new, private)* | view | `labelField(focus:)` | Places Label and Printed page together by the space given (D-16); `labelField` stays its first part |
| `CitationComposerColumnLayout.init(_:)` *(new)* | init | `CitationComposerColumnLayout` | Extends the existing enum |
| `CitationFormFocus.printedPage`, `CitationFormFocus.order(_:printedPageOffered:)` *(new)* | case, func | S15-50's `CitationFormFocus` | Extends it |
| L10n keys in § Strings *(new)* | key | `L10n.CitationComposer.descriptionLabel` / `descriptionPrompt` | New field |

**Builds on.** S15-50's `PVFieldFocus(_:equals:in:)` and `CitationFormFocus`; `FocusKeeper` for Wide rule 5; `PVWidthClass` from `WorkspaceDestinationHost`; the locator's `page` selector; `CitationLineDisplay` as the one home of the page words.
**Deletes.** `L10n.CitationComposer.menuPage` and its `Localizable.xcstrings` entry `citationComposer.menuPage`; both private `citationOptions` and `menuLocator` (in `CitationComposerEvidenceColumn.swift` and `CitationComposerAuthoringBox.swift`); `CitationStepMenuRow`'s `locator:` parameter; `CitationLocatorDraft.hasPage`; the page counts in `citationPage` and `regionDocPages`; the `1400` threshold and the `threeUp` parameter in `CitationComposerView.swift`.
**Next adds.** S15-44 adds `page_unknown` and `page_supplied` to `validatePage` and a `Mark` field to `PageRef`; S15-45 puts the Unknown/Supplied control beside this field (one more entry in its tab order) and models those keys in `CitationLocatorDraft`; S15-16 resolves `{citation.page}` through `locator.Page`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Label-only page selector stored | `graphfill.loadGraphObservations` → `CitationLineDisplay.parts` | `ArtifactPage` 0, `PageLabel` "14" → "p. 14" (the existing printed branch); T-4 |
| Label-only page selector on a Citation with a depiction | `depictionvalues.FromJoin` / `depictionvalue.Readable` via `ValidateDepictionRegion` | Image: region has no page → valid (T-2). PDF with no file page: `depictionNeedsPage` already refuses a region; unchanged. Swift readers (`CitationComposerAuthoring.position(of:)`, `depictionPageCheck`) read `page`, nil for label-only |
| A Citation switch, an Artifact switch, a delete with a label | `CitationFieldsDraft.replace(from:)`, `applySelectedArtifact`, `resetBlank(keepLocator:)` | AC-2.1, AC-2.6, AC-2.7; T-6 |
| Width class change mid-edit | `CitationComposerView` | Focus re-claimed by `FocusKeeper`; values in the model (T-8, manual) |

### Scale

None — no new write path, list or loop: one string in an existing locator write; the graph refill on a `citations` row change already runs for Label edits.

### Edges

- **Assumptions.** `citationPage` callers assumed `ok ⇒ page ≥ 1`. After D-2 only `ValidateDepictionRegion` compares pages, and it uses `page > 0`; `Page` passes 0 through as "no file page", which `graphfill` and `CitationLineDisplay` already treat as none (`artifactPage > 0`). A page above `math.MaxInt32` stays "no page selector" (today's rule), label included. T-1, T-2, T-4.
- **Neighbors.** `{"artifact_page":1}` valid; `{"page_label":"1"}` valid (new); `{}` invalid; `{"page_label":""}` invalid; `{"artifact_page":0,"page_label":"x"}` invalid; `{"artifact_page":37,"page_label":""}` valid, reads `{37, ""}`; two page selectors invalid at write (new). T-1.
- **Removed inputs.** Clearing the field removes `page_label`; with no file page the page selector goes too (T-5). Deleting the Citation: nothing else holds the label.
- **Real data.** No table drives this. Only the composer writes locators (`CitationLocatorDraft.encodeJSON`), always with at most one page selector that has `artifact_page`, so every stored document keeps validating under D-1 and D-2.
- **Untrusted size.** The label is bounded by `MaxDocumentBytes`, checked in `decode` before parsing.

### Schema

None — the label lives in `citations.locator_json`; no migration.

### Go core

| Package | Change |
| --- | --- |
| `core/locator` `validate.go` | `validatePage`: D-1. `validateDoc`: a second page selector → `ErrInvalid` (D-2). Package doc: a page selector holds `artifact_page`, `page_label`, or both |
| `core/locator` `depiction.go` | `type PageRef` *(new)*; `Page(json) PageRef` (D-4). `citationPage`: no count; `page` 0 when `ArtifactPage` is nil. `ValidateDepictionRegion`: `hasPage := ok && page > 0`, compared with the region's. `regionDocPages`: no count; `ErrInvalid` on a page selector with nil `ArtifactPage` |
| `core/database/graphfill` `load.go` | `ref := locator.Page(…)`; `w.page, w.pageLabel = ref.ArtifactPage, ref.Label` |

Errors: `locator.invalid` (existing `ErrInvalid`) for AC-4.2, AC-4.3, AC-4.6.

### FFI

None — the locator travels as a JSON string; `engine.proto`'s `page_label` is unchanged.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Printed page field | `PVField` + `PVInput` size `.sm` | `CitationComposerEvidenceColumn.printedPageField(focus:)` *(new)* | Label `printedPageLabel`, prompt `printedPagePrompt`, help `printedPageHelp` as the Input's `.help` and accessibility hint (D-16); `accessibilityIdentifier("citationComposer.printedPage")`; shown only when `model.locatorCapabilities.supportsPrintedPage` |
| Side form | — | `sideForm` | `labelAndPrintedPage` (D-16) above the transcription; on the 440pt column it is always one row |
| Panel form | `PVWeightedColumns` [1.5, 1] | `panelForm` | Right column: `labelAndPrintedPage` (D-16): stacked at 1102pt (frame 1a), one row at 1464pt (frame 7) |
| Tab order | `PVFieldFocus(_:equals:in:)` (S15-50) | `sideForm`, `panelForm` | D-12 |
| Citation menu | `PVSelect` | `CitationStepMenu` *(new)* | D-9 |
| Split | `PVWidthClass` | `CitationComposerView.composeSplit` | D-11 |
| Focus across widths | `FocusKeeper` | `CitationComposerView` | D-13 |

States: an audio, video or unsupported Artifact, or a file still loading, draws no field and no gap. Accessibility: the field's label and help (CP-6); menu row text as drawn.

Frames in words (the agreed board): 1a — CIT-7KQ2M on Folio 23 at 1102pt, two columns, the form stacked above the viewer, Printed page "14" under Label in the form's right column, saved. 1b — the same at 2296pt, three columns, the 440pt form beside the viewer, Label and Printed page in one row above the transcription. 2a/2b — CIT-3HW8D on the PDF, strip "Entire artifact › Page 37 › Rectangle", Printed page "23". 3 — CIT-9RX4T, empty field with its prompt and focus ring, Save citation disabled; then "iv" typed and Save citation enabled. 4a/4b — the Citation menu rows of AC-2.5. 5 — an audio Artifact: Label alone, no gap. 6 — after Reset to entire artifact: Printed page still "23", Save citation enabled. 7 — 1464pt: two columns, Printed page beside Label. 8a/8b — "23a" unsaved with the cursor in it at 1599pt and 1600pt, unchanged across the line.

### Strings

L10n keys *(new)*, under `L10n.CitationComposer`, added in STEP-4:

- `printedPageLabel` = "Printed page" (comment: "Label of the citation's printed-page field")
- `printedPagePrompt` = "As printed, such as 14 or iv" (comment: "Placeholder in the printed-page field")
- `printedPageHelp` = "The page number the original prints. It goes in the citation; the page in the file does not." (comment: "Help for the printed-page field")

Removed in STEP-5: `menuPage` ("p. %lld"), key `citationComposer.menuPage`; the menu uses `L10n.Conclusions.citationPagePrinted` and `citationPageImage` through `CitationLineDisplay` (D-10). Old-scope copy: `locatorPage` "Page %lld" (the strip chip) stays; it names the file page.

## 7. Steps

**STEP-1 — The locator accepts a printed page alone.**
Files: `core/locator/validate.go`, `core/locator/depiction.go`, `core/database/graphfill/load.go`, `core/locator/validate_test.go`, `core/locator/depiction_test.go`, `core/database/citations/citations_test.go`, `core/database/graphfill/records_test.go`.
Do: D-1 – D-4; T-1 – T-4.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/locator/... ./core/database/citations/... ./core/database/graphfill/...` passes.

**STEP-2 — The Swift locator draft carries the printed page.**
Files: `macos/App/Features/CitationComposer/CitationLocatorDraft.swift`, `macos/ProvenenciaTests/CitationLocatorDraftTests.swift`. Skill: `add-swift-test`.
Do: D-5, D-6 (the draft's mutators); T-5.
Check: `xcodebuild test` on `CitationLocatorDraftTests` passes.

**STEP-3 — Image and PDF Artifacts offer a printed page.**
Files: `macos/App/Features/ArtifactViewer/ArtifactViewerKind.swift`, `macos/App/Features/CitationComposer/CitationComposerModel.swift`, `macos/ProvenenciaTests/ArtifactViewerModelTests.swift`.
Do: D-7, D-8; T-7.
Check: tests pass.

**STEP-4 — The citation form shows Printed page, in tab order.**
Files: `macos/App/Features/CitationComposer/CitationComposerEvidenceColumn.swift`, `CitationComposerView.swift` (the `@FocusState` only), `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/CitationComposerModelTests.swift`. Skills: `add-ui-component`, `add-localized-string`.
Do: the field in both forms per § 6 macOS and the board; the three keys of § Strings; D-12 with S15-50's `PVFieldFocus(_:equals:in:)`; T-6, T-8's order cases.
Check: `xcodebuild test` passes; Frames 1a, 2a, 3, 5 match in the app; Tab follows AC-3.4.

**STEP-5 — One Citation menu names the printed page.**
Files: `CitationComposerEvidenceColumn.swift`, `CitationComposerAuthoringBox.swift`, `macos/App/Platform/CitationLineDisplay.swift`, `L10n.swift`, `Localizable.xcstrings`, `CitationComposerModelTests.swift`.
Do: D-9, D-10; remove `menuPage`; T-9.
Check: `rg -n "menuPage\b|func menuLocator|func citationOptions" macos/App` returns nothing; tests pass; Frame 4a, 4b match.

**STEP-6 — The composer lays out by width class and keeps focus.**
Files: `CitationComposerView.swift`, `CitationComposerEvidenceColumn.swift`, `CitationComposerModelTests.swift`.
Do: D-11, D-13; T-8's layout cases.
Check: tests pass; Frames 1b, 2b, 7, 8 match; manual check step 5.

**STEP-7 — Docs.**
Files: `docs/interpretation-layer-data-model.md` § 3.2 (schema `artifact_page?`, the label-only rule, one page selector per document, an image example), `docs/ideas/wide-layout.md` (the Citation composer row marked landed: on the width class, S15-13), `docs/deployment-plan/spike-15/deployment-plan.md` (map row status), `completed.md`, this plan, the brief to `design/archive/` with its `design/README.md` row.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-13-composer-printed-page.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Record the printed page in the citation composer."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/locator/validate_test.go` `TestValidate`, `TestPage` | Rows for AC-4.1, AC-4.2, AC-4.3, AC-4.7; `Page` of `{"type":"page","page_label":" 14 "}` → `{0, "14"}`; the existing "two page selectors" `TestPage` row stays `{0, ""}` | AC-4.1, AC-4.2, AC-4.3, AC-4.7, D-1, D-2, D-4 |
| T-2 | Go | `core/locator/depiction_test.go` `TestValidateDepictionRegion` | "label-only citation, region without page" → ok; "label-only citation, region on page 1" → err; "region page selector label-only" → err | AC-4.4, AC-4.5, AC-4.6, D-2, D-3 |
| T-3 | Go | `core/database/citations/citations_test.go` (its create/update table) | Create and update with a label-only locator → saved; with two page selectors → `locator.invalid` | AC-1.1, AC-4.3 |
| T-4 | Go | `core/database/graphfill/records_test.go` `TestGraphRecordsCarryCitationWords` (a new row) | A Citation with `{"type":"page","page_label":"14"}` → `ArtifactPage` 0, `PageLabel` "14" | AC-1.1, D-4 |
| T-5 | Swift | `CitationLocatorDraftTests` `printedPageRoundTrips` *(new)*, `printedPageAloneEncodesALabelOnlySelector` *(new)*, `blankPrintedPageWritesNoSelector` *(new)*, `printedPageSurvivesLocatorResets` *(new)*, `nonStringPageLabelIsIgnored` *(new)* | AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-2.3 inputs → the JSON / draft stated; `"page_label":14` → `pageLabel` "" | AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-2.3, D-5, D-6 |
| T-6 | Swift | `CitationComposerModelTests` `pageLabelLoadsSavesAndResets` *(new)* | Seed a Citation with `page_label` "23" → `pageLabel` "23", not dirty; set "24" → dirty, `canSaveCitation`; `saveCitation()` → `store.citationsByID["cit-1"]?.locatorJSON` contains `"page_label":"24"`; `selectCitation(nil)` → ""; delete the Citation through `confirmPendingImpact` → "24" kept; select another Artifact → "" | AC-2.1, AC-2.2, AC-2.4, AC-2.6, AC-2.7 |
| T-7 | Swift | `ArtifactViewerModelTests` `printedPageIsOfferedOnImagesAndPDFs` *(new)* | `supportsPrintedPage` per `ArtifactViewerKind`: image, pdf true; audio, video, unsupported false | AC-1.6, D-7 |
| T-8 | Swift | `CitationComposerModelTests` `formLayoutFollowsWidthClassAndTabOrder` *(new)* | `CitationComposerColumnLayout(.regular)` → `.panel`, `(.wide)` → `.side`; `CitationFormFocus.order` for both layouts, with and without the printed page | AC-3.1, AC-3.2, AC-3.4, D-11, D-12 |
| T-9 | Swift | `CitationComposerModelTests` `menuRowNamesPrintedAndFilePage` *(new)* | `CitationStepMenuRow.locatorText` for (label "23", page 37, region) → "p. 23 · image 37 · region"; (page 40) → "image 40"; none → ""; ("14", region) → "p. 14 · region"; ("15") → "p. 15" | AC-2.5, D-9, D-10 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `CitationComposerDepictionTests` (the depiction page rule), `ProvenanceSheetTests` and `PersonDetailTests` (citation line).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`menuPage`, `menuLocator`, `hasPage`, `threeUp`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: interpretation-layer-data-model.md § 3.2; docs/ideas/wide-layout.md composer row
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with a Census Source whose graph links an image Artifact (one JPEG page) and a PDF Artifact. Open a Citation on the image with a rectangle. Type "14" in Printed page; Save. Open the Person the Citation's Observation supports, open the value's provenance sheet: the record's citation line ends "p. 14".
2. On the PDF, open a Citation on page 37; type "23"; Save; the line reads "p. 23". Reset to entire artifact: Printed page still "23", Save enabled; Save; the line reads "p. 23".
3. Open the Citation menu: rows read as AC-2.5; open an Observation's dialog Citation menu: the same.
4. Pick **New citation**: Printed page empty. Pick another Artifact: empty. Open an audio Artifact if the project has one: no Printed page field.
5. AC-3.1, AC-3.2, AC-3.3, AC-3.4: default window (Regular): form above the viewer; Tab runs Transcription → Label → Printed page. Stretch past a 1600pt pane: three columns; Tab runs Label → Printed page → Transcription. With the cursor in Printed page and unsaved text, cross the line both ways: text and cursor stay. At a 1464pt pane (16" laptop full screen): two columns.
6. Each frame of the agreed board at Regular and Wide matches.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| An older app opens a project with a label-only selector: its `Validate` refuses it, so its citation line shows no page and an edit there drops the label | Pre-1.0 minor bump; no older app is in use on dogfood projects after the bump |
| Focus lost on the layout switch despite `FocusKeeper` | T-8 covers the order; manual step 5 covers the claim |
| `ViewThatFits` picks the stacked layout in the 440pt side form (Label 180 + 140 + spacing must fit in 440 minus the column's padding) | Frame 1b; if it stacks, stop (Stop conditions) |

**Stop and report if:**

- A `FocusState<CitationFormFocus?>.Binding` passed from `CitationComposerView` cannot build S15-50's ordered handles in the column (D-12, D-13 need it).
- A stored locator in a dogfood project or test fixture has two page selectors or a page selector without `artifact_page` before this PR (`rg -n '"type":"page"' core api macos` and the dogfood projects' `citations.locator_json`): the Real data claim is wrong.
- A caller of `citationPage` outside `core/locator/depiction.go` depends on `ok` meaning "has a file page" (`rg -n "citationPage\(" core`).
- `FocusKeeper` cannot re-claim a text field after the column is rebuilt (CP-W2 cannot hold without a new mechanism).
- The agreed board's frames disagree with an AC here.
- In the 440pt side form Label and Printed page do not share one row (frame 1b), or in the 1102pt stacked form they do not stack (frame 1a).

## 12. Open questions

None.

## 13. PR

**Title:** S15-13 — The composer records the printed page
**Body:** objective in one sentence; what shipped against US-1 – US-4; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-13-composer-printed-page.md`.

## Landed

- `CitationStepMenu` takes the `model` and the `ordered` Citations (the plan's parameter list omitted them): the menu reads `model.citationStepLabel(for:)` for its closed label.
- `CitationComposerEvidenceColumn` takes the form's focus as `formFocus: FocusState<CitationFormFocus?>.Binding`.
- The menu, field, width-class and focus changes share one commit: they edit the same files.
- Not run in the app by the implementer: the board frames and manual check (§ 10), including `ViewThatFits` placement of Label and Printed page (frames 1a, 1b, 7) and focus across 1600pt.
- Printed page help and prompt changed from the board copy after review (UX-2, UX-3; user 2026-11-16).
