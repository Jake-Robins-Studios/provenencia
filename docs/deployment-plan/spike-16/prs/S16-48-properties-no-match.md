# S16-48 — A Properties search with no match shows the kit's empty state

**Status:** Landed in [#899](https://github.com/Jake-Robins-Studios/provenencia/pull/899) (2026-11-19)
**Spike / slice:** Spike 16 · Slice 6c — Shared list helpers
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D8](../design/archive/S16-D8-properties-no-match.md), board agreed 2026-11-19
**Board:** [agreed 2026-11-19](https://claude.ai/artifact/XRS4WQDZbaDa7jAzVKYQdc) — Claude Design "Properties View", page `S7-D2 Subject Fields`, section "S16-D8 · No match" (frames N1a, N1b, N2, N3a, N3b, N4). Copy, icons (`text-search`, `list-tree`), the `space6` top-aligned inset and the wrapping title as briefed; Clear search drawn at the small size (`sm`), like the toolbar's controls
**Depends on:** S16-D8 (board agreed 2026-11-19)
**Blocks:** —
**Landed:** Differences from the plan: UX-2: a type-scoped no-match title, at the user's request on 2026-11-19, over the board's single title. Otherwise none beyond the version (0.24.0 → 0.24.1, `main` had moved) and the copy and view changes sharing one commit, as the app does not build with only one of them. Review round 1: `PropertiesTablePresentation.rows` carries its rows so the body filters once; every `PVEmptyState` icon init forwards to its glyph init (no behavior change, superseding D-9's "no change to any other init"); and the user approved centering the kit title (`.multilineTextAlignment(.center)`) over D-9's "No change to the body" (UX-1).
**Branch:** `s16-48-properties-no-match`
**Version bump:** patch — the next patch after `VERSION` on `main` when the branch is cut (0.23.5 → 0.23.6 at the planning base): two empty states a researcher sees on an existing page; no wire or catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** —
**Context:** brief [S16-D8](../design/archive/S16-D8-properties-no-match.md); map scope entry [S16-48](../deployment-plan.md#s16-48--a-properties-search-with-no-match-shows-the-kits-empty-state); bar 23; the precedent `SourcesListView.listBody`
**Planned:** 2026-11-19 against `main` @ `2d48e41`
**Review:** [`S16-48-properties-no-match.review.md`](S16-48-properties-no-match.review.md) — Fits with changes / Ready with changes, 1 round; board checked 2026-11-19

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

When a Properties search matches nothing, the table card's body shows the kit's compact `PVEmptyState` with a **Clear search** button, as the Sources list shows its no-filter-match state, instead of two hand-built lines of text with no button. A selected type with no Properties bound to it and an empty search gets its own compact empty state, titled with the type, instead of today's "No properties match" for a search nobody typed.

**Why now.** Batch 6 takes the parked ideas one PR at a time; this one is the "Properties empty search state" item of the retired shared-list-helpers idea file (bar 23).

**What stays.** A search that matches shows the table as today. The type strip, the toolbar (search field, Add combo), the inspector card, the load-failure Callout and the page header do not change. There is no Create property button in either state (user, 2026-11-19).

## 2. User stories

**US-1.** As a researcher, when my Properties search matches nothing, I see the same empty state as every other list, with a button that clears the search, so that I get my rows back in one press.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | All properties selected; type `zzz` in the search field | The table body is a compact empty state: search-empty icon, title `No property matches “zzz”`, message `Try another word, or clear the search.`, a secondary **Clear search** button. No table header, no rows |
| AC-1.2 | Person selected; type `zzz` | The same state with the title `No property on Person matches “zzz”`; the toolbar still shows the Add combo |
| AC-1.3 | Search `  zzz  ` (spaces around) | The title reads `No property matches “zzz”` |
| AC-1.4 | AC-1.1's state; press Clear search | The field is empty, every row shows again, and the search field has focus |
| AC-1.5 | Search `name` | The table shows the matching rows as today |
| AC-1.6 | Search of only spaces, or only `-` | No search: every row of the selected type shows, as today |

**US-2.** As a researcher, when the type I selected has no Properties, I am told so, not that my search matched nothing.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Source selected after Mentions and Remark were removed from it; search empty | The table body is a compact empty state: Properties icon, title `No properties on Source`, message `Add one with the field above.`, no button |
| AC-2.2 | AC-2.1's type; type `zzz` | AC-1.1's no-match state (search wins) |
| AC-2.3 | AC-2.1's state; add Remark back with the Add combo | The table shows Remark |

**US-3.** As a VoiceOver user, I hear the state and can reach its button.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | AC-1.1's state, VoiceOver on, move through the card | VoiceOver reads the title, the message, then "Clear search, button" |
| AC-3.2 | AC-2.1's state | VoiceOver reads the title and the message; there is no button |

## 3. Scope

| In | Covered by |
| --- | --- |
| PN-1 the no-match state with Clear search | STEP-1, STEP-2, STEP-3, AC-1.1, AC-1.2, AC-1.3 |
| PN-2 Clear search empties the field, rows return, focus to the field | STEP-1, STEP-3, AC-1.4 |
| PN-3 the empty-type state | STEP-1, STEP-2, STEP-3, AC-2.1, AC-2.3 |
| PN-4 search wins over the empty type | STEP-1, AC-2.2 |
| PN-5 placement under the toolbar, top-aligned, inset | STEP-3, manual check 1 |
| PN-6 a long query wraps | STEP-3, manual check 4 |
| PN-W1 Wide: nothing moves; the box spans the card | STEP-3, manual check 5 |
| VoiceOver reads each state (map Check) | STEP-3, AC-3.1, AC-3.2 |
| Delete the dead `prefillLabel` parameter of `openCreate` (D-6) | STEP-1 |

| Out | Home |
| --- | --- |
| A Create property button in the empty state | not planned (user, 2026-11-19: Clear search only) |
| The load-failure Callout; a catalog with no Properties at all (unreachable: the product's Properties cannot be deleted) | not planned |
| A loading indicator in the table body during the first load | not planned (the body draws nothing then, D-1) |
| The other items of the retired shared-list-helpers idea file | S16-49 – S16-57 |
| Any change to the Sources list's state, `PVEmptyState`'s look or its other inits, or the search field | not planned |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Table body | `macos/App/Features/Properties/PropertiesView.swift` `PropertiesContent.propertyTable` (≈ line 280) | When `model.visibleProperties.isEmpty`, a hand-built `VStack` of `Text(verbatim: L10n.Properties.emptySearchTitle(query:))` (display h4, secondary) and `Text(L10n.Properties.emptySearch)` (italic, muted), centered with `space9` padding; no button. Otherwise a `PVTable` |
| Table card | same file, `listCard`, `listToolbar` | `PVCard` holding the toolbar (`PVInput` bound to `model.searchQuery` with `focused: $searchFocused`; `PVComboBox` for Add when a type is selected), a `PVDivider`, then `propertyTable` |
| Search focus | same file, `PropertiesContent` `.onChange(of: model.searchFocused)` and `.onChange(of: searchFocused)` | Model → view: when `model.searchFocused` turns true the view focuses the field; view → model mirrors the field's focus. `model.focusSearch()` (⌘F) sets it |
| Filter | `macos/App/Features/Properties/PropertiesModel.swift` `PropertiesModel.visibleProperties` | Filters `snapshot.properties` by the selected type's bindings (`propertiesByTypeID`), then `TextMatch.Query(searchQuery).matches(label, key)`, sorted by label |
| Query key | `macos/App/Platform/TextMatch.swift` `TextMatch.Query` | `isEmpty` is true when the typed text has no letters or digits (spaces, punctuation and word breaks are dropped), so `"  "` and `"-"` are no search |
| Create | `PropertiesModel.openCreate(prefillLabel: String = "")` | `prefillLabel` has no caller: every call is `openCreate()` (view header, ⌘N). Arrived with the repo import (`2969116`) and never wired |
| Copy | `macos/App/Platform/L10n.swift` `L10n.Properties.emptySearchTitle(query:)` (≈ line 7642), `L10n.Properties.emptySearch` (≈ line 7657) | `emptySearchTitle` trims; empty → key `properties.table.emptySearchTitle` "No properties match", else `properties.table.emptySearchTitleQuery` "No property matches “%@”". `emptySearch` = `properties.table.emptySearch` "Clear the search, or create it as a user property". English is the only localization in `macos/App/Resources/Localizable.xcstrings` |
| Empty type reachable | `core/database/subjectvocab/registry.go` (bindings, lines ≈ 190–216) | Every type has a locked binding except `source`, whose `mentions` and `remark` bindings are unlocked: removing both leaves Source with no Properties |
| Kit | `macos/App/DesignSystem/Components/EmptyState/PVEmptyState.swift` `PVEmptyState` | `init(icon:verbatimTitle:message:compact:action:)` and `init(glyph:title:…)` exist, each with an `EmptyView`-action overload; there is no `glyph:verbatimTitle:` init. No accessibility grouping: VoiceOver reads title, message and the action as separate elements |
| Icons | `macos/App/DesignSystem/Components/Icon/PVIcon.swift` `PVSymbol.searchEmpty`; `macos/App/Features/Workspace/WorkspaceSection.swift` `WorkspaceSection.glyph` | `.searchEmpty` exists; `WorkspaceSection.properties.glyph` is `.symbol(.listTree)`, the sidebar's, and `MetadataListPane` / `SourceTypesListPane` already read their section's glyph for their empty states |
| Loading flag | `PropertiesModel.isLoading` | No caller in `macos/` (`rg`): dead |
| Tests | `macos/ProvenenciaTests/PropertiesModelTests.swift` `typeFilterShowsOnlyBoundProperties`, `searchMatchesLabelOrKeyIgnoringAccentsAndWordBreaks` | Cover the filter; nothing covers what the empty body shows. `makeModel(properties:types:fieldsByType:)` and `warm` build a loaded model; a type with no `fieldsByType` entry has no bound Properties |

**Precedent.** `SourcesListView.listBody` (`macos/App/Features/Sources/SourcesListView.swift` ≈ line 276): `PVEmptyState(icon: .filter, title:, message: L10n.string(…), compact: true) { PVButton(L10n.Sources.clearFilters, variant: .secondary) { model.clearFilters() }.accessibilityIdentifier("sources.clearFilters") }`, then padding and `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)`, with its own accessibility identifier. Copy that shape and its model method (`SourcesModel.clearFilters`). Do not copy its `.padding(.horizontal, PVSpacing.gutterPage)`: here the state sits inside a card, not on the page (D-4).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `PropertiesModel.tablePresentation` *(new)*, of type `PropertiesTablePresentation` *(new)*, decides the body: `.rows` when `visibleProperties` is non-empty; else `.nothing` when `snapshot.properties` is empty (no Properties loaded: the first load, or an empty catalog), which draws an empty body, so a query typed during the first load shows no no-match state; else `.noMatch(query:)` when `TextMatch.Query(searchQuery)` is not empty, with the query trimmed of whitespace and newlines; else `.emptyType(label: selectedType.label)` when `selectedType` is set; else `.nothing` (unreachable with Properties loaded and no type: All properties lists them all). A `selectedTypeKey` missing from `snapshot.types` gives `selectedType == nil` and no type filter (`visibleProperties` skips it), so the body is `.rows` | A pure value is tested without a window (AC-1.x, AC-2.x); the view only switches on it. "Searching" uses the same key the filter uses, so `"  "` and `"-"` never show a no-match state over rows (AC-1.6). Search wins (PN-4) | Branching on `searchQuery.isEmpty` in the view — whitespace and punctuation queries would show no-match while rows show; untestable |
| D-2 | `PropertiesModel.clearSearch()` *(new)* sets `searchQuery = ""` and calls `focusSearch()` | One model method, as `SourcesModel.clearFilters`; focus goes to the field because the button that had it disappears (PN-2). `focusSearch()` already drives the field's focus through the view's `onChange` | Setting `searchQuery` inline in the view — focus would be lost, and the behavior untested |
| D-3 | No match: `PVEmptyState(icon: .searchEmpty, verbatimTitle: L10n.Properties.noMatchTitle(query:), message: L10n.string(L10n.Properties.noMatchMessage), compact: true) { PVButton(L10n.Properties.clearSearch, variant: .secondary, size: .sm) { model.clearSearch() } }`. Empty type: `PVEmptyState(glyph: WorkspaceSection.properties.glyph, verbatimTitle: L10n.Properties.emptyTypeTitle(typeLabel:), message: L10n.string(L10n.Properties.emptyTypeMessage), compact: true)`, through the init D-9 adds | Brief inventory; the board draws Clear search `sm`, the size of the card's toolbar controls (`PVInput` and `PVComboBox` are `.sm`), where the Sources list keeps the default `.md`; the titles carry runtime text so they are verbatim. The empty type reads the section's glyph, as `MetadataListPane` and `SourceTypesListPane` do, so the Properties icon is declared once (`WorkspaceSection.glyph`) | `icon: .listTree` — a second declaration of the section icon; a type mark — the strip card above already shows it |
| D-4 | Each state: `.padding(PVSpacing.space6)` then `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)`, inside `propertyTable` where the hand-built `VStack` was | PN-5's inset as the agreed board draws it (`padding: var(--space-6)`, `justify-content: flex-start`); top-aligned as the Sources state | Centered in the card — not the Sources shape |
| D-5 | Copy: `emptySearchTitle(query:)` becomes `noMatchTitle(query:)`, a plain `L10n.format` of the unchanged key `properties.table.emptySearchTitleQuery` with no trim of its own (D-1's `tablePresentation` is the one place that trims, as `CatalogSearchModel.trimmedQuery` feeds `L10n.Workspace.omnibarNoMatchesTitle(query:)`); its empty-query branch and the key `properties.table.emptySearchTitle` go (D-1 never calls it with an empty query). Replace `emptySearch` with `noMatchMessage` *(new)*, a new key, because its meaning changes (no "create" any more). Add `clearSearch`, `emptyTypeTitle(typeLabel:)`, `emptyTypeMessage` *(new)*. Exact words in **Strings** | A changed meaning gets a new key (add-localized-string); an unchanged title keeps its key | Rewording `properties.table.emptySearch` in place — a stale comment and meaning under an old key |
| D-6 | `openCreate(prefillLabel:)` loses its parameter: `openCreate()`, `draft.label` starts `""` | The user chose no Create button (2026-11-19), so the parameter's only intended caller will not exist; it never had one | Keeping it "for later" — dead code the next reader has to trace |
| D-7 | Accessibility identifiers: `properties.noMatch` and `properties.emptyType` on each `PVEmptyState`, applied after its `.padding` and `.frame` (D-4), as `sources.filterEmpty`; `properties.clearSearch` on the `PVButton`, as `sources.clearFilters`. `.nothing` has none. No `.accessibilityElement` modifier: the kit's title, message and button stay separate elements (AC-3.1) | Same scheme as `sources.filterEmpty` / `sources.clearFilters`; UI tests and the manual check can find them | — |
| D-9 | `PVEmptyState` gains the one missing init pair: `init(glyph: PVGlyph, verbatimTitle: String, message: String? = nil, compact: Bool = false, @ViewBuilder action:)` and its `EmptyView` overload; `init(icon:verbatimTitle:…)` forwards to it with `.symbol(icon)`. No change to the body or any other init | It completes the existing icon/glyph × title/verbatimTitle grid (three of four exist); not a new primitive | — |
| D-8 | Tests are Swift Testing model tests in `PropertiesModelTests` (§8); no UI test | The branch logic is in the model (D-1); the layout and VoiceOver are in the manual check, as for the Sources state | An XCUITest — the repo has none for Properties, and S16-34 keeps tests windowless |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PropertiesTablePresentation` *(new)* in `PropertiesModel.swift` | type (enum: `rows`, `noMatch(query: String)`, `emptyType(label: String)`, `nothing`; `Equatable`) | `ConclusionListPage`'s `presentation` switch (`.loading`, `.empty`, `.failed`, `.rows`) | That enum is generic over a Conclusion list Kind and carries rows and errors; the Properties page's load and failure are handled above the table. A four-case local enum is the same pattern, not a copy |
| `PropertiesModel.tablePresentation` *(new)* | computed property | `PropertiesModel.visibleProperties`, `isLoading` | Built on `visibleProperties`; no other place decides the body |
| `PropertiesModel.clearSearch()` *(new)* | func | `SourcesModel.clearFilters()`, `PropertiesModel.focusSearch()` | Calls `focusSearch()`; the Sources method resets Sources settings, a different model |
| `PVEmptyState.init(glyph:verbatimTitle:message:compact:action:)` and its `EmptyView` overload *(new)* | init | `PVEmptyState.init(icon:verbatimTitle:…)`, `init(glyph:title:…)` | The missing cell of the existing grid; the icon form forwards to it (D-9) |
| `L10n.Properties.noMatchMessage`, `clearSearch`, `emptyTypeTitle(typeLabel:)`, `emptyTypeMessage` *(new)* | keys | `L10n.Sources.noFilterMatchesMessage`, `L10n.Sources.clearFilters` | Different words for a different list; `clearFilters` says "filters" |

Searched: `PVEmptyState(` call sites (17), `clearSearch`/`Clear search` in `macos/App` (no hit), `prefillLabel` (no caller).

**Builds on.** `PVEmptyState` and `PVButton` (kit); the Sources list's no-filter-match shape; `TextMatch.Query` for what counts as a search; `focusSearch()` and the view's existing focus bridge.
**Deletes.** The hand-built `VStack` in `propertyTable`; `PropertiesModel.isLoading`, which has no caller and whose fact ("no Properties loaded yet") `.nothing` now owns; the key `properties.table.emptySearchTitle` and the empty-query branch of `emptySearchTitle(query:)`; `L10n.Properties.emptySearch` and its key `properties.table.emptySearch`; the `prefillLabel` parameter of `openCreate` (D-6); the trim inside `emptySearchTitle` (D-5).
**Next adds.** The [Properties page and terms idea](../../../ideas/properties-and-terms.md)'s reorderable list of a type's bound Properties: it becomes a case or variant of `PropertiesTablePresentation` (its empty case is `.emptyType`), not a second branch beside the `switch` in `propertyTable`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Clear search from the empty state | `PropertiesModel.searchQuery`, the search field's focus | Clearing re-runs `visibleProperties`; the selection is untouched (the inspector keeps showing the selected Property, as when the field is cleared by hand) |
| The empty-type state | `propertyTable` with a selected type and no bound rows | Adding a binding through the Add combo reloads the snapshot and the body becomes `.rows` (AC-2.3); changing type re-runs `tablePresentation` |

### Scale

None — the filter and the list are unchanged; `tablePresentation` reads `visibleProperties`, which the body already computes.

### Edges

- **Assumptions.** `tablePresentation` reads `visibleProperties` once per body; it assumes the filter's notion of "searching" is `TextMatch.Query.isEmpty` (T-3 holds it).
- **Neighbors.** `zzz` → no match (T-1); `name` → rows (T-1); `"  "` and `"-"` with rows → rows (T-3); empty type + `zzz` → no match (T-4); empty type + `""` → empty type (T-4); type with rows + `""` → rows (T-4).
- **Removed inputs.** Removing the last binding of the selected type turns `.rows` into `.emptyType` on the next snapshot (T-4 builds that snapshot directly). A snapshot with no Properties → `.nothing`, whatever the query (T-5).
- **Real data.** Only `source` has no locked binding in `core/database/subjectvocab/registry.go`; every other seeded type always shows rows with an empty search.
- **Untrusted size.** A long query: the title is a verbatim `Text` with no line limit and wraps in the box (PN-6, manual check 4); no work grows with it beyond today's filter.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None —

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| No-match state | `PVEmptyState` (compact, `.searchEmpty`) + `PVButton` `.secondary`, `.sm` | `PropertiesView.swift` `propertyTable` | D-3, D-4, D-7 |
| Empty-type state | `PVEmptyState` (compact, `WorkspaceSection.properties.glyph`), no action | same | D-3, D-4, D-7 |
| Body decision | `PropertiesModel.tablePresentation` | `PropertiesModel.swift` | D-1 |
| Table | `PVTable` | same | Unchanged, drawn for `.rows` |

`propertyTable` becomes a `switch model.tablePresentation`: `.rows` → today's `PVTable`; `.noMatch(let query)` → the no-match state; `.emptyType(let label)` → the empty-type state; `.nothing` → `Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)`.

States: as above. Wide: nothing moves; the card is wider and the box spans it (PVEmptyState already fills its width and caps its message at `measureNarrow`). Accessibility: the kit reads title, message, button in order; the button's label is its title.

### Strings

L10n keys, all in `L10n.Properties`:

- `noMatchTitle(query:typeLabel:)` (renamed from `emptySearchTitle(query:)`): with a `nil` type label it formats key `properties.table.emptySearchTitleQuery` = "No property matches “%@”" (key and words unchanged), with no trim; with a label it formats new key `properties.table.noMatchOnTypeTitle` = "No property on %1$@ matches “%2$@”"; the empty-query branch and key `properties.table.emptySearchTitle` ("No properties match") are removed.
- `noMatchMessage` *(new)*: key `properties.table.noMatchMessage` = "Try another word, or clear the search." Comment: "Message of the Properties empty state when the search matches no Property".
- `clearSearch` *(new)*: key `properties.table.clearSearch` = "Clear search". Comment: "Button in the Properties empty state: empty the search field".
- `emptyTypeTitle(typeLabel:)` *(new)*: key `properties.table.emptyTypeTitle` = "No properties on %@". Comment: "Title of the Properties empty state when the selected subject type has no Properties; argument is the type's label".
- `emptyTypeMessage` *(new)*: key `properties.table.emptyTypeMessage` = "Add one with the field above." Comment: "Message of the Properties empty state for a type with no Properties; the field above is the Add a property combo box".
- Removed: `emptySearch` / `properties.table.emptySearch` ("Clear the search, or create it as a user property").

Kinds: `noMatchMessage`, `clearSearch` and `emptyTypeMessage` are `static let … = LocalizedStringResource(key, defaultValue:, comment:)`, as `L10n.Sources.clearFilters`; `emptyTypeTitle(typeLabel:)` is a `static func … -> String` returning `L10n.format(LocalizedStringResource(…), typeLabel)`, as `noMatchTitle(query:)`. Each sits beside `noMatchTitle` in `L10n.Properties`. In `Localizable.xcstrings` each entry copies the shape of `properties.table.emptySearchTitleQuery` (`comment`, `extractionState: manual`, an `en` `stringUnit` `translated`).

The agreed board (2026-11-19) uses these words exactly.

## 7. Steps

**STEP-1 — The body decision and Clear search in the model**
Files: `macos/App/Features/Properties/PropertiesModel.swift`, `macos/ProvenenciaTests/PropertiesModelTests.swift`. Skill: `add-swift-test`.
Do: write T-1 – T-6 first (a `sourceType()` fixture beside `personType()`, same shape: `id: "type-source"`, `key: "source"`, `origin: "provenencia"`, `label: "Source"`, `description: ""`, `refPrefix: "SRN"`, `candidateRefPrefix: "CSR"`); then add `PropertiesTablePresentation` and `tablePresentation` (D-1) beside `visibleProperties` and `clearSearch()` (D-2) beside `focusSearch()`, and delete the dead `isLoading`; commit. Then remove `openCreate`'s `prefillLabel` parameter (D-6) in its own commit.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PropertiesModelTests` passes.

**STEP-2 — Copy**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`. Skill: `add-localized-string`.
Do: the **Strings** list exactly: add the four keys, remove `properties.table.emptySearchTitle` and `properties.table.emptySearch` from both files, rename `emptySearchTitle(query:)` to `noMatchTitle(query:)` and make it a plain `L10n.format` with no trim and no empty branch (D-5).
Check: `python3 scripts/check-localizable-xcstrings.py` passes; `rg -n "properties.table.emptySearch\"|properties.table.emptySearchTitle\"|emptySearchTitle|L10n.Properties.emptySearch\b" macos` finds nothing.

**STEP-3 — The table body draws the states**
Files: `macos/App/DesignSystem/Components/EmptyState/PVEmptyState.swift`, `macos/App/Features/Properties/PropertiesView.swift`. Skill: `add-ui-component`.
Do: add D-9's init pair to `PVEmptyState` and forward the icon form to it; then replace the `if model.visibleProperties.isEmpty { VStack … } else { PVTable … }` in `propertyTable` with the `switch model.tablePresentation` in **Design → macOS**, the components of D-3, the layout of D-4 and the identifiers of D-7.
Check: the app builds; manual checks 1 – 6 pass.

**STEP-4 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (every `MARKETING_VERSION` line: 4 at the planning base, the app and test targets, Debug and Release).
Do: the next patch after `VERSION` on `main` when the branch is cut.
Check: the three agree.

**STEP-5 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan (status, Landed note), `docs/deployment-plan/spike-16/design/S16-D8-properties-no-match.md` → `design/archive/`, `docs/deployment-plan/spike-16/design/README.md` (Scheduled → Archived).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-48-properties-no-match.md` reports no errors; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

All in `macos/ProvenenciaTests/PropertiesModelTests.swift`, built with `makeModel` and `warm`. The Source type is a `CatalogSubjectType` (`id: "type-source"`, `key: "source"`, `label: "Source"`) with no `fieldsByType` entry.

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PropertiesModelTests` `tablePresentationShowsNoMatchForASearchThatMatchesNothing` *(new)* | Name and Event type loaded, All properties: `"zzz"` → `.noMatch(query: "zzz", typeLabel: nil)`; `"  zzz  "` → `.noMatch(query: "zzz", typeLabel: nil)`; `"name"` → `.rows` | AC-1.1, AC-1.3, AC-1.5, D-1 |
| T-2 | Swift | `tablePresentationShowsNoMatchWithATypeSelected` *(new)* | Person selected (Name bound), `"zzz"` → `.noMatch(query: "zzz", typeLabel: "Person")` | AC-1.2, D-1 |
| T-3 | Swift | `tablePresentationTreatsSpacesAndPunctuationAsNoSearch` *(new)* | All properties: `"   "` → `.rows`; `"-"` → `.rows` | AC-1.6, D-1 |
| T-4 | Swift | `tablePresentationShowsEmptyTypeUnlessSearching` *(new)* | Source selected with no bindings: `""` → `.emptyType(label: "Source")`; `"zzz"` → `.noMatch(query: "zzz", typeLabel: "Source")`; Person selected, `""` → `.rows` | AC-2.1, AC-2.2, D-1 |
| T-5 | Swift | `tablePresentationIsNothingWithNoPropertiesLoaded` *(new)* | No Properties, Source in types and selected, `""` → `.nothing`; `"zzz"` → `.nothing` | D-1 |
| T-6 | Swift | `clearSearchEmptiesTheQueryAndFocusesTheField` *(new)* | `"zzz"`, `searchFocused == false`; `clearSearch()` → `searchQuery == ""`, `searchFocused == true`, `tablePresentation == .rows` | AC-1.4, D-2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `PropertiesModelTests` (the `openCreate` signature, D-6) and `scripts/check-localizable-xcstrings.py` (removed keys).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (properties.table.emptySearch, properties.table.emptySearchTitle gone)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`L10n.Properties.emptySearch`, `emptySearchTitle`, `PropertiesModel.isLoading`, `prefillLabel`; the hits in this plan and the map's S16-48 scope entry are expected); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive (D-9 is an init on an existing one)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — patch
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] Domain doc updated if a rule in docs/*.md changed: none expected
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Open a project at the default window size (Regular), go to Properties.

1. All properties; type `zzz`. The table body shows the compact empty state under the toolbar, top-aligned and inset: search-empty icon, `No property matches “zzz”`, `Try another word, or clear the search.`, **Clear search**. Press it: the field is empty and focused, every row is back (AC-1.1, AC-1.4, PN-5).
2. Select Person; type `zzz`: the same state, titled `No property on Person matches “zzz”`, with the Add combo still in the toolbar (AC-1.2). Type `name`: the Name row shows (AC-1.5). Type three spaces: every Person row shows (AC-1.6).
3. Select Source; remove Mentions and Remark (select each, turn off Source in the inspector). With the search empty: `No properties on Source`, `Add one with the field above.`, no button (AC-2.1). Type `zzz`: the no-match state titled `No property on Source matches “zzz”` (AC-2.2). Clear it, then add Remark with the Add combo: the table shows Remark (AC-2.3). Put Mentions back.
4. All properties; paste a 120-character query: the title wraps inside the box (PN-6).
5. Widen the window so the pane passes 1600 pt and repeat 1 and 3: the box spans the table card, its content centered, the inspector keeps its width (PN-W1).
6. VoiceOver on: in state 1, moving through the card reads the title, the message, then "Clear search, button"; in state 3, the title and message (AC-3.1, AC-3.2).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The focus bridge does not move focus when `clearSearch()` sets `searchFocused` (the model flag was already true) | T-6 starts from `false`, as after a click on the button; manual check 1 confirms focus |
| The board and the plan drift | Checked 2026-11-19: copy, icons, inset, states and Wide match; only the button size was new (D-3) |

**Stop and report if:**

- `propertyTable` no longer has the hand-built `VStack`, or `visibleProperties` filters differently from §4.
- `PVEmptyState` has no `icon:verbatimTitle:message:compact:action:` init at your base, or already has a `glyph:verbatimTitle:` one.
- `PropertiesModel.isLoading` has gained a caller at your base.
- `openCreate(prefillLabel:)` has gained a caller at your base (D-6 would remove a used parameter).
- Clicking Clear search leaves the field unfocused after D-2 (the focus bridge needs a change outside §4).
- The agreed board draws a state or button this plan does not list.

## 12. Open questions

None.

## 13. PR

**Title:** S16-48 — A Properties search with no match shows the kit's empty state
**Body:** objective in one sentence; what shipped against US-1 – US-3; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-48-properties-no-match.md`.
