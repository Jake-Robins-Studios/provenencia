# S15-49 — The Source types list is redesigned

**Status:** Landed in [#852](https://github.com/mendahu/provenencia/pull/852) (2026-11-15)
**Spike / slice:** Spike 15 · Slice 2 — Metadata at three levels
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D28](../design/archive/S15-D28-source-types-list.md), board agreed 2026-11-15 (user)
**Board:** [Claude Design — Source Types](https://claude.ai/artifact/R94Wfp97eC9cBLaSNBQEga): page *S2-03 Source Types Board*, section "01 Columns, sort and the Wide band" (frames L1a / L1b, L2a / L2b, L3, L4a / L4b and its notes on TL-1, TL-W1, TL-W2), drawn by the component *Source Types List* (`Source Types List.dc.html`, its `columns`). The board confirms D-1 – D-4 as written (Used by 120pt with Associated fields' count cell; Description a flexible column splitting the free width evenly with Label, 562pt each in the band; the band; no sort on Description) and adds one thing: the full description as a hover tooltip (D-3). Section 02 is S15-D26's Add type dialog, already built. Open the link in a browser; if you cannot, D-1 – D-4 and § 6 macOS describe each frame
**Depends on:** S15-48 (landed [#848](https://github.com/mendahu/provenencia/pull/848)), S15-D28
**Blocks:** —
**Branch:** `s15-49-source-types-list`
**Version bump:** patch, 0.15.3 (today's `VERSION`) → **0.15.4** (or the next patch after `main`'s `VERSION` when you rebase): `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj` — a Mac UI change to an existing destination, no new capability and no wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`
**Context:** working rule "A Source type has its own page" ([map](../deployment-plan.md#working-rules)); [`docs/macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide) (rule 3 and `pvListBand`); [`docs/ideas/wide-layout.md`](../../../ideas/wide-layout.md) (Properties, Metadata row); [`docs/design-system-layers.md`](../../../design-system-layers.md)
**Planned:** 2026-11-15 against `main` @ `887339a`
**Review:** [`S15-49-source-types-list.review.md`](S15-49-source-types-list.review.md) — Fits with changes / Ready with changes, round 1; board agreed; no open blocker or To user item

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

The Source types list shows how many Sources use each type, sortable, and at Wide it centers in the Sources list's band and adds each type's description. S15-48 took the side pane away and left three columns stretched across the pane; at 2296pt that is a wide empty band between the label and the counts (rule 3 of § 9). The columns and the Wide arrangement are the user's answers of 2026-11-15, drawn on S15-D28.

**Why now.** The type page (S15-48) took the list's last reason to stay narrow; S15-48's plan and S15-D27 left the list's columns and Wide to this PR.

**What stays.** The header and Add type, the Label cell (mark, label, origin pill), Key and Associated fields as drawn today, the footer, the empty, loading and failed states, the sort rule (a new column starts ascending; a second click reverses; ties by label in the column's direction), a click or Return opening the page, Back restoring the scroll. The Metadata list is unchanged: it shares `VocabularyListPane` and passes the same parameters as today.

## 2. User stories

**US-1.** As a researcher, when I look over my Source types, I see how many Sources each one classifies and can sort by it, so that I find the types I rely on and the unused ones I could delete.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The list at any width | Columns in order: Label, Key, Associated fields, Used by. Census (used by 41) shows "41"; Letter (used by 0) shows "—" (TL-1) |
| AC-1.2 | Types A "Atlas" (5), B "Book" (0), C "Census" (5); click Used by | Order B, A, C (ascending, ties by label) (TL-2) |
| AC-1.3 | Click Used by again | Order C, A, B (descending, ties reversed with the column, as Associated fields today) (TL-2) |
| AC-1.4 | Sort by Used by, then click Label | Sorted by Label ascending (a new column starts ascending, as today) |
| AC-1.5 | A Source of type Letter is created elsewhere in the window | Letter's Used by reads "1" when the list is next shown (the `.sourceTypesList` key invalidates on `.createdSource`, as today) |

**US-2.** As a researcher on a wide monitor, I see the list centered at a readable width with each type's description, so that I can tell types apart without opening each one.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Pane 2296pt (Wide) | Header, table and footer are centered at 1600pt of content plus the page gutters, a hairline down each side (TL-W1) |
| AC-2.2 | Pane 2296pt | A Description column sits between Label and Key; Book reads "A published monograph." on one line, a long description ends in "…"; Family scrapbook with no description shows an empty cell (TL-W2) |
| AC-2.3 | Pane 2296pt; click the Description header | Nothing happens: no sort arrow, the sort is unchanged (TL-3) |
| AC-2.4 | Pane 1102pt (Regular) | No Description column; the list fills the pane as today, no hairlines |
| AC-2.5 | A row highlighted and the list scrolled, then the window is resized across 1600pt | Highlight and scroll are kept (rule 5): the table is one view at both widths |
| AC-2.6 | An empty project at Wide | The empty state sits inside the band (TL-4) |

## 3. Scope

| In | Covered by |
| --- | --- |
| TL-1: Used by column at every width, "—" for 0 | STEP-2, AC-1.1, T-2 |
| TL-2: Used by sorts; ties by label in the column's direction | STEP-1, AC-1.2, AC-1.3, T-1 |
| TL-3: Description is not sortable | STEP-2, AC-2.3, T-2 |
| TL-4: empty, loading, failed states unchanged, inside the band at Wide | STEP-3, AC-2.6 |
| TL-W1: the Wide band (`pvListBand`) around header, table and footer | STEP-3, AC-2.1, AC-2.4 |
| TL-W2: Description column at Wide only | STEP-2, AC-2.2, AC-2.4, T-2 |
| The "—" key shared by both count columns (D-5) | STEP-2 |
| Doc comments and § 9 / `wide-layout.md` rows that S15-48 left to this PR | STEP-4 |

| Out | Home |
| --- | --- |
| What Associated fields counts (all three levels) | S15-12 |
| An Origin column | not planned (user, 2026-11-15: the origin stays a pill) |
| A detail beside the list at Wide (§ 9 "List → detail page" long term) | not planned for Source types: the page opens in place of the list |
| The Metadata page's list, its columns and Wide | [`docs/ideas/wide-layout.md`](../../../ideas/wide-layout.md) Properties, Metadata row |
| Column filters, resizing, search in the list | not planned (the omnibar finds a type) |
| Keeping `usedBy` fresh by a reported usage read or a row patch, as `.metadataFieldsList` does, instead of reloading the list on a Source write | not planned (review M-3: about 30 rows reload on `.createdSource`, `.deletedSource`, `.changedSourceType`) |
| Remembering the sort across launches | not planned (today's sort lives on the model; S15-04 saved the Sources list's because its board asked) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| List columns | `macos/App/Features/SourceTypes/SourceTypesListPane.swift` `SourceTypesListPane`, `columns`, `keyColumnWidth` (160), `fieldsColumnWidth` (132) | An instance property `columns` builds Label (flexible: `PVMark`, label, `OriginPill`), Key, Fields (`suggestedFieldCount` or `L10n.SourceTypes.fieldCountNone`). No width class read. Doc comment says "The left pane of `SourceTypesView` (T-1/T-2/T-3/T-4)": there is no other pane since S15-48 |
| List shell | `macos/App/Features/CatalogVocabulary/VocabularyListPane.swift` `VocabularyListPane`, `VocabularyListStrings` | `PVTable` + footer; columns are a parameter; shared with `MetadataListPane`. Doc comment: "The left pane both vocabulary destinations share". No change to its shape needed |
| Destination | `macos/App/Features/SourceTypes/SourceTypesView.swift` `SourceTypesContent.body` | `VStack { header; PVDivider(); callout or SourceTypesListPane }` then `.frame(maxWidth: .infinity, maxHeight: .infinity)`, `.background(PVColor.surfacePage)`, `.sourceTypeAddDialog($model.adding)`. No band at Wide |
| Model sort | `macos/App/Features/SourceTypes/SourceTypesModel.swift` `SourceTypesModel.SortColumn` (`label`, `key`, `fields`), `sortBy(_:)`, `compare(_:_:)` | `fields` compares `suggestedFieldCount`, ties by `label` case-insensitive; `visibleTypes` reverses the whole order when descending |
| Row data | `macos/App/Platform/GenealogyStore.swift` `CatalogSourceType.usedBy`, `.description` | Both already on every listed row (`listSourceTypes`, `updateSourceType`); a created row has `usedBy` 0 |
| Freshness of `usedBy` | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `case .sourceTypesList` | `invalidateOn: [.createdSource, .deletedSource, .changedSourceType]`; the page header's usage line already reads this |
| Table | `macos/App/DesignSystem/Components/Table/PVTable.swift` `PVTableColumn(id:title:width:sortable:filter:cell:)` | A `nil` width is flexible; two flexible columns share the free width equally (`frame(maxWidth: .infinity)` on each) |
| Wide band | `macos/App/DesignSystem/Components/PageColumns/PVPageColumns.swift` `pvListBand(_:)`; `PVSpacing.widthListWideMax` | One caller: `SourcesListView` (`SourcesListView.swift:86`) |
| Width class | `macos/App/DesignSystem/Components/WidthClass/PVWidthClass.swift` `\.pvWidthClass` | Measured once at `WorkspaceDestinationHost`; read with `@Environment(\.pvWidthClass)` |
| Copy | `macos/App/Platform/L10n.swift` `L10n.SourceTypes.columnLabel`, `columnKey`, `columnFields`, `fieldCountNone` (`sourceTypes.list.fieldCountNone` = "—"), `usage(count:)` (the page's line) | No Used by or Description header |
| Tests | `macos/ProvenenciaTests/SourceTypesModelTests.swift` `sortingTogglesWithinAColumnAndResetsAcrossColumns`; fixtures `macos/ProvenenciaTests/CatalogFixtures.swift` `catalogSourceType(_:label:key:origin:description:usedBy:)` | Sort covered for label and fields; no column test |
| Docs | `docs/macos-client-patterns.md` § 9 pattern row "List with a side pane (Properties, Metadata, Source types)" and the rule-3 paragraph ("as the Sources list does"); `docs/ideas/wide-layout.md` row "Properties, Metadata" | Still name Source types as a list with a side pane; S15-48 left both to this PR |

**Precedent.** S15-04 ([#774](https://github.com/mendahu/provenencia/pull/774)) gave the Sources list its Wide frame: `.pvListBand(widthClass)` right after the content `VStack`'s `.frame(maxWidth: .infinity, maxHeight: .infinity)` in `SourcesListView`, with `.background`, the toast and the dialogs after it, and a column that exists only at Wide (Published, `SourcesListColumns.published`). Copy the band's placement and the Wide-only column idea; do not copy `SourcesListColumns` (that list is a hand-built row layout; this one is a `PVTable` whose columns are already the single source of widths).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | **Columns.** `SourceTypesListPane.columns(_ widthClass: PVWidthClass) -> [PVTableColumn<CatalogSourceType>]` *(new, `static`)* replaces the private instance `columns`; it, `usedByColumnWidth` and `descriptionColumnID` are internal (no `private`) so T-2 reads them. Regular: `label` (flexible), `key` (160), `fields` (132), `usedBy` (120) *(new)*. Wide: `label` (flexible), `description` *(new, flexible, `sortable: false`)*, `key`, `fields`, `usedBy`. Every column but `description` is `sortable: true`. Column ids are `SourceTypesModel.SortColumn` raw values, except `description`, a `static let descriptionColumnID = "description"` on the pane, with a doc comment saying a column that does not sort takes a pane constant | TL-1, TL-W2, TL-3; static so the order is tested without a view (T-2); the cells read only the row | An `isWide` flag on the model — width is a view concern; a `SourceTypesListColumns` type like the Sources list's — `PVTable` already owns the widths |
| D-2 | **One count cell.** `private static func countCell(_ count: Int) -> some View` *(new)* on `SourceTypesListPane` holds today's Fields cell (`Text(count > 0 ? "\(count)" : L10n.string(L10n.SourceTypes.countNone))`, `PVFont.mono(size: PVTypeScale.micro)`, `PVColor.textSecondary`, `PVColor.textFaint` at 0); the `fields` column calls it with `suggestedFieldCount`, the `usedBy` column with `usedBy`. Width `usedByColumnWidth: CGFloat = 120` *(new)* beside the two width constants. No identifier beyond what `PVTable` gives the header (`sourceTypes.sortBy.usedBy`); the row stays one combined element | TL-1; one count look in one place (review M-1), with D-5's one dash | A copy of the Fields cell — two copies of one rule; a "41 sources" phrase — the header names the unit |
| D-3 | **Description cell.** `Text(type.description)`, `PVFont.body(size: PVTypeScale.bodySmall)`, `PVColor.textMuted`, `.lineLimit(1)`, `.truncationMode(.tail)`; an empty description draws the empty `Text`; a non-empty one carries `.help(type.description)`, so the cut text reads in full on hover (board L3 notes, the cell's `title`). Flexible width, sharing the free width equally with Label (D-1; board TL-W2: 562pt each in the band) | TL-W2; `PVTable` already splits flexible columns | A wrapped two-line cell — rows would change height between widths and between types |
| D-4 | **Band.** `SourceTypesContent` reads `@Environment(\.pvWidthClass) private var widthClass` and applies `.pvListBand(widthClass)` right after the `VStack`'s `.frame(maxWidth: .infinity, maxHeight: .infinity)` and before `.background(PVColor.surfacePage)`, as `SourcesListView` does. The spinner `SourceTypesView.body` shows before the handle exists stays outside the band: it is a centered `ProgressView` filling the pane, so it sits in the same place banded or not. Header, divider, callout and list sit inside the band; background and the Add dialog stay full width. `SourceTypesListPane` reads the same environment value for D-1 | TL-W1, TL-4; the kit modifier's second caller; one structure at both widths keeps highlight and scroll (AC-2.5) | A frame in `VocabularyListPane` — Metadata would change too (Out) |
| D-5 | **One dash key.** `L10n.SourceTypes.fieldCountNone` (`sourceTypes.list.fieldCountNone`) is renamed `countNone` (`sourceTypes.list.countNone`, "—", comment "Shown in a count column (Associated fields, Used by) when the count is 0"); the old key leaves `Localizable.xcstrings` | Two columns, one meaning; a second "—" key is a copy | Keeping the field-named key for both — its name and comment would lie |
| D-6 | **Sort.** `SourceTypesModel.SortColumn` gains `case usedBy`. `compare` routes `.fields` and `.usedBy` through `private func compareCount(_ a: CatalogSourceType, _ b: CatalogSourceType, by count: KeyPath<CatalogSourceType, Int>) -> ComparisonResult` *(new)*: equal counts → `label.localizedCaseInsensitiveCompare`, else by count; today's `.fields` branch becomes that call. `sortBy` is unchanged (a new column starts ascending) | TL-2 and "Sort behaves as today" (map scope); ties follow the direction as Fields' do (brief § 2); one count compare (review M-1) | A second copy of the `.fields` branch; ties always A→Z — would change the Fields column too |
| D-7 | **Shell stays shared.** `VocabularyListPane` keeps its shape; only its doc comment changes ("The list both vocabulary destinations share" — no "left pane"). No move into `Features/Metadata/` | Map scope: the list stays on it while its columns are parameters, which D-1 – D-4 need no more than | Moving the shell — nothing in this PR needs it |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `SourceTypesListPane.columns(_:)` *(new, static; replaces the instance `columns`)* | func | `SourceTypesListPane.columns` (instance) | It is that property, given the width class (D-1) |
| `SourceTypesListPane.usedByColumnWidth`, `descriptionColumnID` *(new)* | constants | `keyColumnWidth`, `fieldsColumnWidth` | Same home, same pattern |
| `SourceTypesModel.SortColumn.usedBy` *(new)* | case | `.fields` | A new case of the existing sort, not a second sort |
| `SourceTypesListPane.countCell(_:)`, `SourceTypesModel.compareCount(_:_:by:)` *(new, private)* | funcs | the Fields cell; `compare`'s `.fields` branch | They are those, shared by the two count columns (D-2, D-6) |
| `L10n.SourceTypes.columnUsedBy`, `columnDescription` *(new)*; `countNone` *(renamed from `fieldCountNone`)* | keys | `columnFields`, `fieldCountNone`; searched `L10n.swift` for "Description": every hit is a form label in another namespace (`sources.add.formDescription` and the detail forms), none a list column header; keys stay in the feature's namespace (`VocabularyListStrings`' rule) | New headers; the dash is shared (D-5) |
| `.pvListBand` caller | kit call | `SourcesListView` | Reused as is |

**Builds on.** `PVTable` columns as the one source of widths; `pvListBand` and `PVSpacing.widthListWideMax` (S15-04); `\.pvWidthClass`; the `.sourceTypesList` key's existing invalidation.
**Deletes.** `L10n.SourceTypes.fieldCountNone` and its xcstrings entry (renamed, D-5); the instance `columns` property (replaced, D-1). The "left pane" wording in the two doc comments; Source types in § 9's "List with a side pane" row.
**Next adds.** S15-12 changes what `suggestedFieldCount` counts: the `fields` column is unchanged. A later Wide-only column is one more entry in `columns(.wide)`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| Sort by `usedBy` | `SourceTypesModel.visibleTypes` | A gone or new type is a row change of the cached list; the sort recomputes from `types` |
| The list inside the band at Wide | `SourceTypesContent` | Loading, empty and failed states draw inside it (TL-4); the Add dialog is attached outside it |

### Scale

At the map's Scale (about 30 types; a seeded project has 26): two more cells per row, no new read, no new write. `usedBy` and `description` come with the one `listSourceTypes` read that exists today. Sorting 30 rows per click is negligible.

### Edges

- **Assumptions.** `compare` returns a strict order: `usedBy` falls back to label, as `fields` does. Two types with the same label and the same count compare equal; their relative order is whatever `sorted(by:)` gives, as for `fields` today, and no test pins it.
- **Neighbors.** `usedBy` 0 → "—" (not "0"); 1 → "1". Description empty → empty cell (no "—": a dash would read as a count). Pane exactly 1600pt → Wide (`PVWidthClass(paneWidth:)` uses `>=`, unchanged).
- **Removed inputs.** A Source deleted or retyped elsewhere: `.deletedSource` and `.changedSourceType` invalidate the list (AC-1.5 for create); the count is never derived in Swift.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** A long description is cut to one line by the cell (D-3); a plugin's long label is cut as today.

### Schema

None — no catalog change.

### Go core

None — `usedBy` and `description` are already on the wire.

### FFI

None — no new method or field.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Header | `VocabularyHeader` | `VocabularyChrome.swift` | Unchanged, inside the band |
| Table and footer | `VocabularyListPane` → `PVTable` | `VocabularyListPane.swift` | Unchanged shape; doc comment (D-7) |
| Columns | `PVTableColumn` | `SourceTypesListPane.swift` | D-1 – D-3 |
| Label cell | `PVMark` + `OriginPill` | as today | Unchanged |
| Wide band | `.pvListBand(_:)` | `PVPageColumns.swift` | D-4 |
| Empty / failed | `PVEmptyState`, `PVCallout` | as today | Inside the band |

Frames (board section 01): L1a Regular — header, then a table Label · Key · Associated fields · Used by across 1102pt; L1b Wide — the same header and table centered in a 1600pt band with hairlines, columns Label · Description · Key · Associated fields · Used by, L2a/L2b — sorted by Used by descending, the arrow on Used by, L3 — Wide, Description header with no sort affordance, L4a/L4b — empty project. Accessibility: the new header is a sort button with the column's title, as the others (`PVTable`); a row stays one combined element.

### Strings

L10n keys *(new)*: `L10n.SourceTypes.columnUsedBy` (`sourceTypes.list.columnUsedBy`) = "Used by", comment "Source types list column header: how many sources are classified as the type"; `L10n.SourceTypes.columnDescription` (`sourceTypes.list.columnDescription`) = "Description", comment "Source types list column header, shown on wide windows: the type's description". Renamed: `fieldCountNone` → `countNone` (D-5). No copy names an old scope.

## 7. Steps

**STEP-1 — Sort by Used by**
Files: `macos/App/Features/SourceTypes/SourceTypesModel.swift`, `macos/ProvenenciaTests/SourceTypesModelTests.swift`. Skill: `add-swift-test`.
Do: D-6 (with `compareCount`); T-1.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS'` passes `SourceTypesModelTests`.

**STEP-2 — Columns by width class**
Files: `SourceTypesListPane.swift`, `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `SourceTypesModelTests.swift`. Skills: `add-ui-component`, `add-localized-string`.
Do: D-1, D-2 (with `countCell`), D-3, D-5; the pane reads `@Environment(\.pvWidthClass)` and passes `Self.columns(widthClass)`; its doc comment reads "The Source types list's table (S15-D28 TL-1 – TL-W2): the shared `VocabularyListPane` around this destination's columns — label with origin pill, Description at Wide, mono key, suggested-field count, usage — sortable by all but Description." T-2.
Check: `xcodebuild test` passes T-2; `rg -n 'fieldCountNone' macos .agents .cursor docs/*.md` prints nothing (this plan keeps the old name). The new xcstrings entries go where Xcode sorts them (by key); the old `sourceTypes.list.fieldCountNone` entry is removed.

**STEP-3 — The Wide band**
Files: `macos/App/Features/SourceTypes/SourceTypesView.swift`, `macos/App/Features/CatalogVocabulary/VocabularyListPane.swift` (doc comment only).
Do: D-4, D-7.
Check: build passes; manual check 2 and 4 at both widths.

**STEP-4 — Version and docs**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj` (every `MARKETING_VERSION`); `docs/macos-client-patterns.md` § 9; `docs/ideas/wide-layout.md`; `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md` (the S15-49 map row's status), this plan (status and Landed note), `git mv` of `docs/deployment-plan/spike-15/design/S15-D28-source-types-list.md` into `design/archive/` and its row in `design/README.md` from Scheduled to Archived (its link pointing into the archive folder, Built by "S15-49 (#N)").
Do: the version bump in the header. § 9: the pattern row "List with a side pane (Properties, Metadata, Source types)" becomes "(Properties, Metadata)"; the "List → detail page" row's Wide cell adds "the Source types list's Description column" beside "the Sources list's Published column"; the rule-3 paragraph's "as the Sources list does" becomes "as the Sources and Source types lists do (S15-04, S15-49)". `wide-layout.md` Properties, Metadata row: the sentence on Source types reads "Source types left the shape in Spike 15: a list and its own page (S15-48), the list centered at `widthListWideMax` with a Description column at Wide (S15-49); Metadata keeps it (user, 2026-11-14)". Then per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-49-source-types-list.md` reports no errors; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `macos/ProvenenciaTests/SourceTypesModelTests.swift` `sortingByUsedByOrdersByCountThenLabel` *(new)* | `catalogSourceType("a", label: "Atlas", origin: "user", usedBy: 5)`, `catalogSourceType("b", label: "Book", origin: "user", usedBy: 0)`, `catalogSourceType("c", label: "Census", origin: "user", usedBy: 5)`, through `makeModel(store:types:)` and `warm`; `sortBy("usedBy")` → `sortColumn == .usage`, ascending, ids `["b","a","c"]`; `sortBy("usedBy")` → `["c","a","b"]`; `sortBy("label")` → ascending, `["a","b","c"]` | AC-1.2, AC-1.3, AC-1.4, D-6 |
| T-2 | Swift | `SourceTypesModelTests.swift` `listColumnsFollowTheWidthClass` *(new)* | `SourceTypesListPane.columns(.regular).map(\.id) == ["label","key","fields","usedBy"]`; `.columns(.wide).map(\.id) == ["label","description","key","fields","usedBy"]`; in `.wide`, `sortable` is false only for `"description"`; widths: `usedBy` 120, `description` nil, `label` nil | AC-1.1, AC-2.2, AC-2.3, AC-2.4, D-1 |

**Where checks run.** `xcodebuild`, `scripts/check-pr.sh` and the manual check need a Mac with Xcode; `rg`, `python3 scripts/check-plan-docs.py` and `python3 scripts/check-guidance-names.py` run anywhere.

Not tested in code: the band (a kit modifier with its own caller and no logic of its own; manual check 2 and 4), the cells' text (manual check 1, 3).

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourceTypesModelTests`, `MetadataModelTests`, `PVTableTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`fieldCountNone`, `sourceTypes.list.fieldCountNone`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: § 9 rows and rule-3 paragraph, wide-layout.md row (STEP-4)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Use a project with the seed's types and a few Sources (Census used by at least two Sources; at least one type unused).

1. Open Source types at the default window (Regular). See Label · Key · Associated fields · Used by; an unused type shows "—" under Used by; no hairlines at the sides (AC-1.1, AC-2.4).
2. Stretch the window so the pane is 1600pt or more. The header, table and footer center with a hairline down each side; a Description column appears after Label, long descriptions end in "…", a type with none is blank (AC-2.1, AC-2.2).
3. Click Used by: least used first; again: Census near the top. Click Description: nothing changes (AC-1.2, AC-1.3, AC-2.3).
4. Highlight a row with the arrow keys, scroll down, then shrink the window below 1600 and back: the highlight and scroll stay (AC-2.5).
5. Create a Source of an unused type from the Sources list, return to Source types: its Used by reads "1" (AC-1.5).
6. Click a row: its page opens; Back returns to the list at its scroll. The Metadata page's list looks as before.
7. A seeded project always has types, so check the empty state in the `SourceTypesView` `#Preview` with `store.sourceTypesByProject[projectDir] = []`, framed at 2296 × 1440: the empty state sits inside the band (AC-2.6). Revert the preview edit.
8. Compare frames L1a – L4b of the board's section 01 at both widths.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Two flexible columns give Label too little room at Wide for a long label with a plugin pill | The board splits them evenly (562pt each); the label cuts with "…" as today |
| Applying the band inside `SourceTypesContent` but after `.sourceTypeAddDialog` would narrow the dialog's host | D-4 fixes the order: band before background and dialog |

**Stop and report if:**

- The agreed board shows a column, a column order or a Regular arrangement that D-1 – D-4 do not describe, and this plan has not been updated to it.
- `SourceTypesListPane` or `SourceTypesContent` no longer look as § 4 says (S15-12 or S15-17 landed first and moved them).
- `PVTable` gives two flexible columns unequal widths, or a non-sortable column still responds to a click.
- Passing columns by width class makes `VocabularyListPane` or `MetadataListPane` change.

## 12. Open questions

None.

## 13. PR

**Title:** S15-49 — The Source types list is redesigned
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-49-source-types-list.md`.

## Landed

- The base had moved (`VERSION` was already 0.15.4), so the version is 0.15.5.
- T-1 asserts `sortColumn == .usedBy`, the case D-6 names (the plan's `.usage` was a typo).
- Not run: the manual check (section 10) and the board comparison in a browser.
- On the user's request (2026-11-15) this PR adds `FakeHold.untilSuspended(_:)` and moves every positive hold wait onto it, fixing a full-suite hang in `SourceTypePageModelTests.aSaveInFlightIsNotHeld` (landed in S15-48); the count cells also carry spoken labels for VoiceOver (on-screen text unchanged).
