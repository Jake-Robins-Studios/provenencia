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

## The other toggles do not dim under `.disabled(_:)`

`PVFormDialog` disables its form body while it runs, and `PVCheckbox` dims then (S16-73). `PVSwitch`, `PVRadio` and `PVArtifactChecklist` still dim only on their own parameter, so inside a running form they refuse clicks and keep full strength; their disabled opacity is 0.5 where `PVHoverEffect`'s is 0.45. Read `\.isEnabled` in each, and pick one disabled opacity. (S16-73)

## The table writes its own movement keys

`PVTable.handleKey` writes out ⌥↑/↓, Home/End and Page Up/Down itself, with a literal `10` for `PVListKeyboard.pageStep`, and `PVTableSelection.moveIndex` is the no-edge branch of `PVFloatingMenuSelection.moveIndex`. Move the movement cases onto one `PVListKeyboard.moveIndex` call and delete `PVTableSelection.moveIndex` and its tests in `PVTableTests.swift`; no behaviour change. The table keeps its selection, type-to-select and Escape. (S16-65 review M-3)

## Whether `PVTable` follows the native list

`PVList` is the platform's list since S16-67 (selection, ↑/↓, Page Up/Down and scrolling from SwiftUI's `List`), while `PVTable` stays custom chrome: two selection looks (the system accent bar, a 2 pt accent bar on `surfaceSelected`) and two meanings of Page Up/Down (the platform's screen, a clamped ten rows). Decide whether Source types, Metadata and Properties move onto the native list, taking `PVColor.onSelection` and `PVListPageHeader` with them, or keep the table and its type-to-select and ⌥↑/⌥↓ until a brief draws them. STEP-8's findings on the native list: type-select not yet checked (user's manual check); ⌥↑/⌥↓ not yet checked (user's manual check). `PVList`'s own Home/End handler is needed: without it End stops short at 100 Sources (S16-71). (S16-67) The Sources list's SwiftUI `Table` (S16-71, `pvNativeListBehavior` around it) is the pattern a move would reuse; its limits are that a column's width must be fixed (a range drifts on resize) and a column cannot be left out by an `if` below macOS 14.4.
