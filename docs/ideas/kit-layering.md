# Kit layering

**Status:** idea only — not roadmapped. Split out of the retired `structural-debt.md` on 2026-11-17 (checked against the code that day). No user-visible change unless a section says so; pull one in when a feature next changes that code. Places where the design system and the features cross their line, or one control is built twice ([`design-system-layers.md`](../design-system-layers.md), [`add-ui-component`](../../.agents/skills/add-ui-component/SKILL.md)).

## The kit's delete impact takes a Features type

`PVDeleteImpact` takes `WorkspaceLocation`, a `Features/` type, so the kit check allows it (`scripts/check-guidance-names.allow`); move the type out of `Features/Workspace` or pass the destination in. (A-39, S13-34)

## Hovering focus rings built by hand

`SourcesGraphButtonBody`'s focus ring with hover is a third bare-button ring; fold it into `PVFocusRingButtonStyle` (or a hover variant of it) and delete the body. S13-28 added a fourth, `CircularLinkNodeStyle` / `CircularLinkNodeStyleBody` (`CircularLinkDiagram.swift` 306–336), with the same `PVHoverEffect`, `isFocused` and `.pvFocusRing` (Person page audit P-25): give `PVFocusRingButtonStyle` a hover variant (`hoverFill:`, `onHoverChange:`) and move both onto it. (A-41, S13-35)

## The bound-list overflow repeats the badge's count

`L10n.Properties.boundOverflow` ("+%lld") duplicates `PVBadge.moreCount`; move it onto the badge. (A-38, S13-34)

## Page column metrics with one Features caller

`PVPageColumnsMetrics.pinOffset` and `sideColumnWidths` live in the kit with one Features caller (`ConclusionPinnedSideColumn`), and `PVPageColumnsTests` reads `PersonSourcesColumns.minWidth`. (P-26, Person page audit)

## The circular link diagram's unused options

`CircularLinkDiagramStyle` has one value and `CircularLinkArc.color` is set only in a preview and a test, and the adapter's `mappingNodes` second pass reads `neighborCount` (it also builds the node labels, help and accessibility text, so only the counting is extra). (P-26, Person page audit)
