# S15-D10 — Move to another Source: the Move buttons and the confirm

**Kind:** Claude Design board (**enhancement** of the Source page as shipped: S15-D14's Artifact rows, S15-D1's Evidence graph cards, at Regular and Wide. Draw on the existing Source page board; add the menu items and the Move dialog over the page)
**Spike:** Provenencia Spike 15, slice 7
**View:** the Source page's Artifact rows and Evidence graph cards (one Move button each; the row's right-click menu goes), and the Move dialog they open
**Implements later as:** PR **S15-25** (MV-1 – MV-14, MV-W1)
**Board:** [agreed 2026-11-22](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK): page *Move*, rows "Move: the buttons" (`mv-art-menu`, `mv-graph-menu`, each with a Wide frame), "Move dialog" (`mv-open` … `mv-failed`) and "After the move" (`mv-after`, `mv-after-wide`); decisions panel "S15-D10". Board decision (user, 2026-11-22): **no right-click menu** on Artifact rows or graph cards; Move is a visible icon button, and the Artifact row's existing menu goes. § 4 below is the requirement as drawn
**Depends on:** S15-24 (landed [#935](https://github.com/Jake-Robins-Studios/provenencia/pull/935)): the engine's preflight and move; S15-35 (landed [#824](https://github.com/Jake-Robins-Studios/provenencia/pull/824)): the Artifact rows and their right-click menu
**Related:** [`../move-artifact-between-sources.md`](../move-artifact-between-sources.md) (the feature: "Which graphs move", "Side effects to name in the confirm"); working rules "A move is the whole bundle", "One window; nothing is built for a second" in [`../deployment-plan.md`](../deployment-plan.md#working-rules); [S15-D14](S15-D14-source-page-artifacts.md) (the rows; SA-5 named where Move sits) and [S15-D1](S15-D1-source-page.md) (the graph cards; SD-14), which predate "One brief, one PR": this brief is S15-25's own and draws all of what it ships; plan [`../prs/S15-25-move-from-artifact-or-graph.md`](../prs/S15-25-move-from-artifact-or-graph.md)
**Design system layers:** [`docs/design-system-layers.md`](../../../design-system-layers.md)
**Skill:** [`add-design-brief`](../../../../.agents/skills/add-design-brief/SKILL.md); [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md)

Paste this entire document into Claude Design as the requirements for one board. This file is the whole prompt.

### Claude Design — do this first (in order)

Work **in place** on this board. Do not fork a parallel copy of the surface.
- **Rethink** (this brief says replace): throw away the old frames. Do not keep a before/after to ship.
- **Enhancement**: add to the existing frames. Do not start a second composer / graph / page.

1. **Clear this board’s local design-system cache.** Claude Design keeps a stale pack; drawing against it invents local copies of kit controls.
2. **Delete this board’s reference** to the design-system bundle.
3. **Pull a fresh copy** of the Provenencia design system from the main project. Do not continue until the fetched kit lists current components. If the kit looks stale or empty, delete the cache and refetch. Do **not** draw a replacement kit locally.
4. **Compose from that kit.** Instance existing components. Reach for a **bespoke / local** control only when the use is truly this domain. One call site is not a new design-system primitive.

**Reach for (kit).** Instance these first. The **UI building-block inventory** later in this brief names the snowflakes and which kit piece each situation should use.

| Situation | Use |
| --- | --- |
| Labeled value, textarea, or trailing control | Field + TextArea / Input |
| Primary / secondary / ghost action | Button; icon-only → IconButton |
| Choose one from a short list | Select |
| Searchable pick | ComboBox |
| Warning, error, or inline hint | Callout |
| Page- or pane-level empty | EmptyState |
| Confirm replace or destroy | Confirm (`item:` snapshot, not a Bool) |
| Resource delete with inbound check | DeleteImpact recipe (S8-D9 / **S8-13**) — confirm if allowed, notice if blocked |
| Short create / edit form | FormDialog |
| Status / count / polarity mark | Badge; compact token → Chip |
| Cover or file thumb | Thumbnail |
| Grouping / raised or sunken row | Card |
| Section title | SectionHeader |
| Transient after-save notice | Toast |
| Native menu of actions | ContextMenu |
| Record or detail page at Regular and Wide | Page columns |
| Choose one of a few options inline | Segmented control (ChipGroup segmented) |

Do **not** invent a local Field, Button, Card, Select, Callout, or Confirm.

### Two widths — draw both

The window opens at 1366 × 900pt but is often stretched across a large monitor.
Every view has two width classes, measured on the view's own pane (the window
minus the sidebar), not the screen. A view with a side pane (an inspector, a detail
pane) plans that pane inside its Wide frame:

- **Regular** — pane below 1600pt. Draw the pane at 1102 × 900 (the default 1366pt window minus the open sidebar).
- **Wide** — pane 1600pt and up. Draw the pane at 2296 × 1440 (a 2560pt window minus the sidebar).

Draw only the view's own pane. Do not draw the app's sidebar, its navigation items or the window's title bar: they are not part of the board. A frame that needs the toolbar (breadcrumbs, Back and Forward) says so in the brief, and draws only the toolbar above the pane.

Rules for Wide:

1. **The extra space does a job.** Show more at once: a second column of supporting content, the detail beside its list, more grid or table columns, an inspector docked open. If the view truly has nothing to add, center its content. Content jammed to one side with empty space beside it is never the Wide design.
2. **Readable things keep their measure.** Prose, forms and the primary column keep their Regular maximum widths, unless the section opts into Page columns' full-width mode (`primaryFill`: at Wide, with no secondary, the primary fills the pane between the gutters and the header keeps its band; with `fillSplitSideMax` the primary and the band are the main-and-side group the page lays out inside it, as the Source page does); its text still keeps its measure. Wide adds columns; it does not stretch text or fields.
3. **Fill the width only with something useful.** A list, table, grid or canvas takes the extra width when Wide has more to show in it: more columns, more cards, the detail beside the list. When it has nothing more to show, it keeps a maximum width (1600pt of content for a list) and is centered, with the page gutters outside it. Empty space stretched between a row's columns is never the Wide design. Cards keep their size and add columns.
4. **Same content, same actions.** Width changes arrangement only. Anything in the Wide second column is stacked below, in an inspector, or behind a disclosure at Regular.
5. **Crossing the line keeps state.** Selection, scroll position, focus and unsaved edits survive a resize across 1600.
6. **Past every column's maximum, center the group.** Page gutters are never narrower than at Regular; they take what is left.

Draw the **Regular** and **Wide** frame of each view side by side, using the same kit pieces in both.

### This brief is an enhancement

Draw on the Source page board as a new turn "S15-D10 · Move", starting from the Source page as S15-D14 (the Artifact rows, frames `art-list`, `art-list-wide`, `art-menu`) and S15-D1 (the Evidence graph cards) left it, at Regular and Wide. Keep the header, the Description, Credibility and Metadata sections, every row and card as drawn, and Notes. Add one menu item to each Artifact row's menu, give each graph card a right-click menu, and draw the Move dialog over the page.

---

## 1. Objective

A researcher files an Artifact under one Source, builds Evidence graphs on it, and later wants it under another Source: two census images were filed as one Source and should be two, a scan was attached to the wrong certificate. **Move to another Source…** on an Artifact row or an Evidence graph card opens a dialog that shows everything that moves together (the bundle), asks for the target Source, names the side effects, and moves it all in one step. Every ref stays the same; Citations, regions and claims to canonical people come along.

**What changes.**
- **The Artifact row** gains a **Move** button between Edit and Delete, and loses its right-click menu: every action is a button (board, 2026-11-22).
- **The Evidence graph card** gains a **Move** button between Edit and Delete. No menu.
- **The Move dialog** (new): the target picker, the bundle, the side-effect notes, Move and Cancel.
- **After the move** the app opens the target Source's page at its top, and a Toast names what moved and where (user, 2026-11-21).

**What stays.** The rows' and cards' other buttons, the page's layout at both widths, the Artifact sheet and the graph form (neither offers Move), the Evidence graph canvas.

---

## 2. Domain facts

| Fact | What it means on this board |
| --- | --- |
| The bundle | An Artifact and the Evidence graphs drawn on it move together: a graph cannot move without its Artifacts. The bundle is the picked Artifact or graph, every graph linked to its Artifacts, and every other Artifact linked to those graphs, repeated until nothing new joins. The researcher cannot split it or leave a part behind; the dialog shows it in full. |
| Common bundles | One Artifact with its one graph (a census image and its household); one Artifact in no graph (it moves alone); a graph with no Artifacts (a Source's Default graph before any image); a graph that holds two images pulls in both, and their other graphs. At most about 5 Artifacts and 5 graphs, holding up to 100 people in all. |
| What a row shows | An Artifact: its thumbnail, label ("Sheet 14 (image 1)") and ref (`ART-7QK2M`). A graph: its name ("Hale household, dwelling 113"), ref (`GPH-3RX8W`) and the count line the graph cards already show ("4 people · 6 citations"). |
| The target | Any other Source in the project: the current Source is not offered. Searched by title or ref as the researcher types; most recently changed first (user, 2026-11-21). A project holds up to 3,000 Sources. |
| Credibility | Assessments belong to a Source. After the move, the moved records are weighed with the target's credibility, so conclusions resting on them can change. The dialog says so only when the two Sources' grades weigh differently (an unassessed Source weighs as Standard). Grades read "Standard", "Low trust", "High trust" and the researcher's own. |
| Left behind | When every Artifact of the Source moves, the Source is left with none; it is not deleted. When every graph moves, the Source gets a new empty graph named "Default", so it keeps one. Both can happen at once. |
| Nothing is copied | Refs, Citations, regions, copy details and graph details all keep their values. Citations then read the target Source's title, date and details. The dialog does not compare the two Sources' details. |
| No undo | Moving the bundle back is the way back. The dialog does not offer Undo; the Toast has no Undo action. |
| One window | The app opens one window. Nothing on this board is drawn for another window changing the Source or the bundle while the dialog is open. |

### 2.1 What this board is not

- Merge Sources or Move to a new Source (refused this spike: a merge is moves, then the Source delete; a split starts with Copy Source).
- Undo of a move (refused this spike).
- Move from the Artifact sheet, the graph form, the Evidence graph canvas, the Sources list or the Person page (not planned).
- A note about the two Sources' metadata, or about the old Source's cover reverting to the type icon when the cover Artifact moves (not drawn; the page shows the type icon on return).
- Moving several unrelated Artifacts at once (the bundle is the only multi-row unit).
- The Sources list, the Artifact sheet, the graph form: unchanged.

---

## 3. Implementation gate

| PR | Ships | Not that PR |
| --- | --- | --- |
| **S15-25** | MV-1 – MV-14, MV-W1 | Undo, Merge Sources, Move to a new Source (refused); Move anywhere but the Source page's rows and cards (not planned) |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| MV-1 | **Artifact row.** Every action is a visible button: Set cover (when offered; its space kept when hidden), Edit (pencil), **Move** (an IconButton with the folder-input glyph, labelled and tooltipped "Move {label} to another Source"), Delete. The row has no right-click menu: today's menu goes (board, user 2026-11-22). |
| MV-2 | **Graph card.** Open, Edit, **Move** (the same IconButton, "Move {name} to another Source"), Delete. Open is dimmed on a graph with no Artifacts, as today; Move is not. No right-click menu. |
| MV-3 | **The dialog.** A FormDialog, 520pt wide (as Copy Source), titled "Move to another Source", subtitle the picked row: the Artifact's label and ref ("Sheet 14 (image 1) · ART-7QK2M") or the graph's name and ref. From the top: the **Move to** field, the bundle, the notes, then the buttons Cancel and **Move** (primary, not danger). Move is dimmed until a target is picked and the bundle has loaded. Escape and Cancel close it without asking: nothing is typed, and a pick is not work to lose. |
| MV-4 | **Move to.** A Field labeled "Move to" holding a ComboBox of the project's other Sources: each option the Source's title, with its ref as subtext; most recently changed first; typing filters by title or ref; placeholder "Choose a Source"; no match reads "No Source matches". The current Source is never offered. Empty when the dialog opens. |
| MV-5 | **The bundle.** Under the field, the kit SubsectionHeader "Moves together" (not a hand-made caption), then the Artifacts, then a hairline, then the graphs, in one list, each a compact row at least 40pt tall: an Artifact as a 32pt Thumbnail, its label and its mono ref; a graph as the branch glyph, its name, its mono ref and its count line ("4 people · 6 citations"). The picked row is first in its group and carries no special mark. The rows are read-only: no checkbox, no link, no hover. When more than one Artifact moves, one line of secondary text above the rows says why: "A graph moves with all its Artifacts, so these move together." Otherwise no such line (as drawn). |
| MV-6 | **A big bundle.** At 5 Artifacts and 5 graphs the rows fit without scrolling at 900pt tall; a crafted bundle that does not fit scrolls the dialog body, the buttons staying put. |
| MV-7 | **Credibility note.** Once a target is picked and the two grades weigh differently, a Callout (warning tone) under the bundle: title "Credibility changes", message "“{old title}” is assessed {old grade}; “{target title}” is {target grade}. The moved records will be weighed as {weighed-as grade}, so conclusions that rest on them can change." An unassessed Source reads "not assessed" in the grade's place; the engine names the grade it weighs as (Standard). No note when they weigh the same, and none before a target is picked. |
| MV-8 | **Left-behind notes.** When every Artifact moves: a neutral Callout "“{old title}” will have no Artifacts left. It is not deleted." When every graph moves: a neutral Callout "“{old title}” gets a new empty graph named Default, so it keeps one." Both may show; they show from the moment the bundle loads, before a target is picked. |
| MV-9 | **Loading.** While the bundle is read (the dialog opens at once), the bundle area shows the kit's form load area: skeleton bars with the caption "Reading what moves with it"; the field is usable; Move is dimmed. Picking a target reads again for the credibility note: the bundle stays drawn, Move stays dimmed until that read answers, and nothing flickers. |
| MV-10 | **Bundle read fails.** The bundle area shows the kit's load-area failure: a compact danger Callout titled "What moves could not be read." with the message "Nothing was moved. Try reading it again. {engine message}" and the kit's **Read again**. Move stays dimmed. |
| MV-11 | **Nowhere to move.** A project with no other Source: the field is replaced by a neutral Callout "There is no other Source to move to. Add a Source first, or copy this one." Move stays dimmed; the bundle still shows. |
| MV-12 | **Moving.** Move shows the kit's running state on the button; every control is dimmed; the dialog cannot be closed until the write answers. |
| MV-13 | **Move fails.** The dialog stays open with the pick and the bundle; a danger Callout at the top of the dialog body, title "Couldn’t move", message "Nothing was moved." followed by the engine's message. Move can be pressed again. |
| MV-14 | **After the move.** The dialog closes; the app opens the target Source's page at its top (Back returns to the old Source's page, which no longer lists what moved); a success Toast over the workspace: title "Moved to “{target title}”", body counting what moved: "2 Artifacts and 2 graphs", "1 Artifact and 1 graph", "1 Artifact" (an Artifact in no graph), "1 graph" (a graph with no Artifacts). No Undo in the Toast. The moved rows appear on the target page in their usual place and order. |
| MV-W1 | **Wide.** The page keeps the arrangement S15-D14 SA-W1 and S15-D1 SD-W1 drew; the buttons are the same at both widths. The dialog is a sheet and keeps its 520pt width at Wide, centered over the pane as at Regular: it is a short form, so the extra width has no job here. |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Source page: Artifact rows and graph cards | As S15-D14 and S15-D1 drew them, with the Move button | The same rows and cards in the main column beside the Metadata side column | Nothing: one button on existing pieces |
| Move dialog | 520pt sheet over the page | The same 520pt sheet, centered over the pane | Nothing moves: a short form keeps its measure (MV-W1) |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440). Data (invent every person and record): Source "1880 census, Ottawa County, Kansas, ED 236" (`SRC-4KD2P`, type Census, assessed Low trust), holding Artifacts "Sheet 14 (image 1)" (`ART-7QK2M`, the cover), "Sheet 14 (image 2)" (`ART-9TB3C`), "Sheet 20" (`ART-2HX5D`) and graphs "Hale household, dwelling 113" (`GPH-3RX8W`, on images 1 and 2, 4 people · 6 citations), "Robins household, dwelling 112" (`GPH-6MQ4P`, on image 2, 5 people · 9 citations), "Default" (`GPH-8ZT1K`, no Artifacts, 0 people). Target "1880 census, Ottawa County, Kansas, ED 237" (`SRC-7WN3R`, not assessed); other Sources "Kansas state census 1885, Ottawa County" (`SRC-2PL8F`, Standard) and "Ottawa County marriages, book B" (`SRC-5VC9Q`, High trust).

| Frame | Requirement | Draw |
| --- | --- | --- |
| 1a / 1b | MV-1, MV-W1 | The page's Artifacts section: image 2's row with Set cover, Edit, Move, Delete (as drawn: `mv-art-menu`) |
| 2a / 2b | MV-2, MV-W1 | The graphs section: the "Hale household" card with Open, Edit, Move, Delete; Default with Open dimmed (as drawn: `mv-graph-menu`) |
| 3a / 3b | MV-3, MV-4, MV-5, MV-8, MV-W1 | The dialog over the page, opened from image 1 before a target is picked: the field empty; Moves together with the "why" line; images 1 and 2; the Hale and Robins graphs; no left-behind note (Sheet 20 and Default stay); Move dimmed |
| 4 | MV-4 | Regular, the ComboBox open with "ED 2" typed: the ED 237 Source first, ref as subtext; the current Source absent |
| 5 | MV-7 | Regular, frame 3a with ED 237 picked: the credibility Callout "“1880 census, Ottawa County, Kansas, ED 236” is assessed Low trust; “1880 census, Ottawa County, Kansas, ED 237” is not assessed. The moved records will be weighed as Standard, …"; Move enabled |
| 6 | MV-5, MV-8 | Regular, on another Source, "1885 census, Ottawa County, Kansas, ED 12" (`SRC-6JD4T`), whose only Artifact is "Sheet 3" (`ART-4RM6N`) and whose only graph "Weber household" (`GPH-1QW7S`, 3 people · 4 citations) links it: the dialog opened from Sheet 3 shows one Artifact, one graph, no "why" line, both left-behind Callouts |
| 7 | MV-5 | Regular, the dialog opened from the "Default" graph card (no Artifacts): one graph row, no Artifact group |
| 8 | MV-9 | Regular, the dialog just opened: the bundle area as skeleton rows |
| 9 | MV-10 | Regular, the bundle read failed: the load-area failure with Read again |
| 10 | MV-11 | Regular, a project with one Source: the neutral Callout in the field's place, the bundle below |
| 11 | MV-12, MV-13 | Regular, two states side by side: Move running; then the "Couldn’t move" Callout at the top of the body with the pick kept |
| 12a / 12b | MV-14 | The target Source's page at its top after the move, with the Toast "Moved to “1880 census, Ottawa County, Kansas, ED 237”" / "2 Artifacts and 2 graphs" (draw the Toast's position as the workspace draws it today) |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Artifact row | Snowflake | Extend | `macos/App/Features/Sources/SourcePageArtifactRow.swift` `SourcePageArtifactRow` | A Move IconButton between Edit and Delete (MV-1); the row's right-click menu and `ArtifactRowAction` go |
| Evidence graph card | Snowflake | Extend | `macos/App/Features/Sources/SourcePageGraphsView.swift` `SourcePageGraphRow` | A Move IconButton between Edit and Delete (MV-2) |
| Move button | Component | Ship | `macos/App/DesignSystem/Components/IconButton/` `PVIconButton`; `PVSymbol.folderInput` *(new glyph)* | The folder-input glyph, small, labelled "Move {name} to another Source". Not a menu |
| Move dialog | Snowflake | New | `macos/App/Features/Sources/SourceMoveDialog.swift` *(new)* | The form body; a Source page feature view, like `SourceCopyDialog` |
| Dialog frame | Component | Ship | `macos/App/DesignSystem/Components/FormDialog/` `pvFormDialog(item:…)`, `PVFormDialogCopy` | Title, subtitle, Move / Cancel, running and closing rules (MV-3, MV-12). Not Confirm: the dialog holds a field |
| Target picker | Component | Ship | `macos/App/DesignSystem/Components/ComboBox/` `PVComboBox`, `PVComboBoxOption` in a `PVField` | Title with ref as subtext (MV-4), as the format editor's "Preview with" picker draws it. Not Select: up to 3,000 Sources need typing |
| Bundle load area | Component | Ship | `macos/App/DesignSystem/Components/FormLoadArea/` `PVFormLoadArea` | Skeleton bars and caption while reading, failure with Read again (MV-9, MV-10), as Copy Source's parts load |
| Bundle rows | Snowflake | New | in `SourceMoveDialog.swift` | Compact read-only rows composed of kit pieces: `CachedThumbnail` (32pt) for an Artifact; `PVIcon(.gitBranch)` and the existing `SourcesGraphCountLine` for a graph. Not `PVArtifactChecklist`: these rows cannot be unticked. Not cards |
| Section caption | Component | Ship | `macos/App/DesignSystem/Components/SubsectionHeader/` `PVSubsectionHeader` | "Moves together" |
| Notes | Component | Ship | `macos/App/DesignSystem/Components/Callout/` `PVCallout` | Credibility (warning), left behind (neutral), nowhere to move (neutral), move failed (danger) |
| After-move notice | Component | Ship | `WorkspaceSession.noticeToast`, drawn by `WorkspaceView` through `vocabularyToastOverlay` | The workspace's notice Toast, which survives the page change, as Promote's success notice does (MV-14) |
| Toast | Component | Ship | `macos/App/DesignSystem/Components/Toast/` | Success tone, no action |

**Non-goals.** No new kit component: the dialog and its rows are one call site. No right-click menu on a row or card. No Undo. No per-row control in the bundle. No metadata comparison, cover note or reification note.

---

## 7. Handoff

When the board is agreed: record the link, the frames and the board's decisions on the **Board** line here, in [`README.md`](README.md) and on S15-25's plan **Board** line; the plan copies MV-1 – MV-14 and MV-W1 and moves from `Blocked — on board S15-D10` to `Planned`. When S15-25 lands, this brief, [S15-D1](S15-D1-source-page.md) and [S15-D14](S15-D14-source-page-artifacts.md) (S15-25 is the last PR each gates) move to the spike's design archive.
