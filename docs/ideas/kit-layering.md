# Kit layering

**Status:** idea only — not roadmapped. Split out of the retired `structural-debt.md` on 2026-11-17 (checked against the code that day). No user-visible change unless a section says so; pull one in when a feature next changes that code. Places where the design system and the features cross their line, or one control is built twice ([`design-system-layers.md`](../design-system-layers.md), [`add-ui-component`](../../.agents/skills/add-ui-component/SKILL.md)).

## The kit's delete impact takes a Features type

`PVDeleteImpact` takes `WorkspaceLocation`, a `Features/` type, so the kit check allows it (`scripts/check-guidance-names.allow`); move the type out of `Features/Workspace` or pass the destination in. (A-39, S13-34)

## Hovering focus rings built by hand

The Sources list graph button and its ring are gone (S16-66). S13-28 added a bare-button ring, `CircularLinkNodeStyle` / `CircularLinkNodeStyleBody` (`CircularLinkDiagram.swift` 306–336), with the same `PVHoverEffect`, `isFocused` and `.pvFocusRing` (Person page audit P-25): give `PVFocusRingButtonStyle` a hover variant (`hoverFill:`, `onHoverChange:`) and move both onto it. (A-41, S13-35)

## The bound-list overflow repeats the badge's count

`L10n.Properties.boundOverflow` ("+%lld") duplicates `PVBadge.moreCount`; move it onto the badge. (A-38, S13-34)

## Page column metrics with one Features caller

`PVPageColumnsMetrics.pinOffset` and `sideColumnWidths` live in the kit with one Features caller (`ConclusionPinnedSideColumn`), and `PVPageColumnsTests` reads `PersonSourcesColumns.minWidth`. (P-26, Person page audit)

## The circular link diagram's unused options

`CircularLinkDiagramStyle` has one value and `CircularLinkArc.color` is set only in a preview and a test, and the adapter's `mappingNodes` second pass reads `neighborCount` (it also builds the node labels, help and accessibility text, so only the counting is extra). (P-26, Person page audit)

## Promote's record picker pads its hit rows twice

The combo box's row padding and `PVSearchHitRow`'s own both apply, so a hit row in Promote's picker sits further in than in the omnibar's list. (S16-52 review M-3)

## A remote combo box highlights nothing when its results arrive

`PVComboBox.resetActiveRow` lands before the remote options exist, so the first hit is not highlighted; the omnibar lands on arrival through `CatalogSearchModel.scheduleSearch(onResults:)`. (S16-52 review M-9)

## The table writes its own movement keys

`PVTable.handleKey` writes out ⌥↑/↓, Home/End and Page Up/Down itself, with a literal `10` for `PVListKeyboard.pageStep`, and `PVTableSelection.moveIndex` is the no-edge branch of `PVFloatingMenuSelection.moveIndex`. Move the movement cases onto one `PVListKeyboard.moveIndex` call and delete `PVTableSelection.moveIndex` and its tests in `PVTableTests.swift`; no behaviour change. The table keeps its selection, type-to-select and Escape. (S16-65 review M-3)

## Micro-caps type written by hand

`PVMicroCaps` (S16-71) holds the micro-caps font and tracking that `pvMicroCaps()`, `PVBadge` and the Sources table's column titles read, yet nine sites still write `PVTypeScale.micro * PVTracking.caps` by hand: `NameValueEditorForm` (three), `EvidenceCardView`, `DateValueEditorForm`, `PropertiesView` (two), `MetadataBoardView` and `PVContextMenu`. Point each at `PVMicroCaps.tracking` (or `pvMicroCaps()` where the line also sets the font and case). No behaviour change. (S16-71)

## Whether `PVTable` follows the native list

`PVList` is the platform's list since S16-67 (selection, ↑/↓, Page Up/Down and scrolling from SwiftUI's `List`), while `PVTable` stays custom chrome: two selection looks (the system accent bar, a 2 pt accent bar on `surfaceSelected`) and two meanings of Page Up/Down (the platform's screen, a clamped ten rows). Decide whether Source types, Metadata and Properties move onto the native list, taking `PVColor.onSelection` and `PVListPageHeader` with them, or keep the table and its type-to-select and ⌥↑/⌥↓ until a brief draws them. STEP-8's findings on the native list: type-select not yet checked (user's manual check); ⌥↑/⌥↓ not yet checked (user's manual check). A hosted `NSTableView` handled Home and End itself (scrolled to the first and last row, selection unchanged), so `PVList`'s own Home/End handler may be redundant on this macOS. (S16-67) S16-71 put the Sources list on SwiftUI's `Table`, which gives the answer for a table with columns: the platform draws the header band, the sort arrow, the rules and the selection, and `pvNativeListBehavior` gives it focus on arrival, Home/End, the scrolls and the row menu with no AppKit reach-in. Its limits: a column's width cannot be a range that holds (the widths drift on resize, so `SourcesTableWidths` fixes every column but Title), a column cannot be left out by an `if` below macOS 14.4 (the Type column is hidden through `TableColumnCustomization`), `DisclosureTableRow` draws no graphs for a Source opened in code deep in the table (the rows are the outline's flat array instead), and a graph row's wheel step is its content height, 26 pt, not the 34 pt row. Source types, Metadata and Properties would move onto it by the same pattern; none is planned. (S16-71)
