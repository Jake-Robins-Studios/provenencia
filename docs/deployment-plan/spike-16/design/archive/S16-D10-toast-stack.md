# S16-D10 — The workspace window's toast stack

**Kind:** Claude Design board (**enhancement**: a ToastStack component composed from the kit's Toast, and the workspace window frames that show it; the Toast card itself does not change)
**Spike:** Provenencia Spike 16 (odds and ends), batch 6
**View:** the workspace window's content pane (any destination under the toolbar): the toasts in its top-trailing corner; the Citation composer's saved-bridge toast, which moves there from the foot of its observations column
**Implements later as:** PR **S16-58** (Toasts stack in one list per window)
**Board:** agreed 2026-11-22: [design system](https://claude.ai/artifact/7AZ8cscWF3f5Wz7gQ39cMe), component PVToastStack (K1 on its component sheet); [main app layout](https://claude.ai/artifact/1UzGb9TQCd7ZQrmuAN5AY8), page "Workspace Chrome", section "Toast stack" (T1a, T1b, T2–T4), drawn by `PVToastStackHost` in "App Layout"; T5 on the composer's board. Values as briefed; motion added by the board: a 28 pt slide with a fade, 200 ms ease-out in and ease-in out, a 200 ms linear fade under Reduce Motion. The callers' boards send to the stack
**Depends on:** the kit's Toast (`components/feedback/Toast.jsx`, Swift `PVToast`) as drawn today; the agreed workspace frames (the toolbar above the content pane) and the agreed Citation composer frames
**Related:** design [`../stacked-toasts.md`](../stacked-toasts.md); working rule "(Batch 6) One toast stack per window" in [`../deployment-plan.md`](../deployment-plan.md#batch-6--idea-follow-ups); plan [`../prs/S16-58-toast-stack.md`](../prs/S16-58-toast-stack.md); [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
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

### What this board adds

This is an **enhancement**. In the **design-system project** (the main project the boards pull from), add a component `components/feedback/ToastStack/` beside Toast, composed of Toast instances, and a ToastStack section on the component sheet. Then, on the board that holds the workspace window frames, add a turn "S16-D10 · Toast stack" with the frames in §5, drawn from the agreed page frames. Do not redraw a page, the toolbar or the sidebar: only the toasts over the content pane change. The Toast card keeps every value it has today (its tone bar, icon, title, message, dismiss button, 360 pt width, radius and shadow).

---

## 1. Objective

The workspace window shows one toast at a time per surface, and several surfaces share the window's top-trailing corner: the window's own toasts (a failed count of the sidebar's badges, a notice after leaving a place) and each page's toasts (a save, a portrait chosen, a delete). A second toast replaces the first, so a researcher who acts twice in a row reads only the latest message; and two surfaces' toasts can land on top of each other.

This board draws **one stack of toasts per window**: every toast in the window joins one list in the content pane's top-trailing corner, newest on top. Each card leaves on its own five-second timer or its dismiss button. There is no cap. The same message again does not add a second card: the card on screen moves to the top and its five seconds start again.

The Citation composer's toast after a bridge is saved (`Bridge saved`) is drawn today at the foot of the composer's observations column. It moves into the stack, like every other toast in the window (user, 2026-11-17). It is the one toast that changes place.

**What stays.** The Toast card, its tones and its copy; the pages, the toolbar and the sidebar; the likeness viewer's sheet, which covers the window and keeps drawing its own single toast inside the sheet; Onboarding's single toast (no workspace window there).

## 2. Domain facts

| Fact | Meaning for the board |
| --- | --- |
| A toast | A short notice after an action: a tone (info, success, warning, danger), a title, an optional message line, and a dismiss button. It leaves by itself after five seconds |
| One window | Provenencia opens one workspace window (Spike 16 Batch 7). It holds one stack |
| Who adds | Any page under the toolbar (Sources list, Source page, Source type page, Metadata, Properties, an Evidence graph, a Person, Event or Place page, the Citation composer) and the window itself (counts, navigation history, notices after leaving a place) |
| Order | Newest on top. Cards below keep their order; when one leaves, the cards below it move up |
| Own timer | Each card leaves five seconds after it was added (or last refreshed). Dismissing one card never changes another's time left |
| No cap | Nothing pushes a card out early. A burst taller than the pane runs past the pane's bottom edge and is cut there; the cards below the edge still leave on their own timers |
| A repeat | A toast equal to one on screen (same tone, title and message) moves that card to the top and restarts its five seconds. No second card, and VoiceOver does not read it again |
| VoiceOver | A new card is read once when it appears (a danger card interrupts). A refreshed card is not read again |
| Reduce Motion | Cards fade in and out instead of sliding |
| Sheets | A sheet (the likeness viewer) covers the window. A toast raised inside it draws inside the sheet, as today, not in the window's stack |

### 2.1 What this board is not

- Not a change to the Toast card: no new tone, no action button inside a toast, no progress bar for the timer, no count of hidden cards.
- Not a cap, a "clear all" button, a collapsed pile or a "+N more" line (no cap, user 2026-11-17).
- Not Onboarding's toast, the likeness viewer's toast or any sheet's toast.
- Not a toast's wording: every card on this board uses copy the app already shows.
- Not the omnibar's results or any popup: those are their own windows above the pane.

---

## 3. Implementation gate

| S16-58 ships | Not S16-58 |
| --- | --- |
| TS-1 – TS-8, TS-W1 | Each page adding to the window's list directly (S16-59, no visible change); Onboarding's toast; a sheet's toast joining the stack |

---

## 4. Requirements

| ID | Requirement |
| --- | --- |
| TS-1 | **ToastStack component** (`components/feedback/ToastStack/`). A column of Toast instances, newest at the top, each card the Toast as it is today (360 pt wide, its own dismiss button). 8 pt between cards (`space-4`). Props: the list of toasts (tone, title, message), and a dismiss per card. Add it to the component sheet with one, two and five cards |
| TS-2 | **Placement.** The stack sits in the **content pane's** top-trailing corner, under the toolbar, 24 pt (`space-8`) in from the pane's top and trailing edges: where a page's toast sits today. It never covers the toolbar (Back, Forward, the breadcrumbs, the omnibar) or the sidebar. The cards' trailing edges line up |
| TS-3 | **Two toasts.** On a Person page, choose two portraits in a row: two success cards `Portrait updated` / `Using the likeness from Parish register, 1851 as the portrait.` and `Portrait updated` / `Using the likeness from Census 1861 as the portrait.`, the second on top. Caption: each leaves five seconds after it appeared; dismissing the lower one leaves the upper one's timer alone |
| TS-4 | **Two surfaces at once.** A page's toast and the window's toast in one stack, never on top of each other: a danger card `Couldn’t refresh catalog counts` / `The catalog session is closed.` above a page's success card `Source saved`. The window's toast is a card like any other; it is not pinned or styled apart |
| TS-5 | **A refreshed card.** The counts failure twice within five seconds: one danger card, now at the top above a success card that was added between the two failures. Caption: no second card; its five seconds restart; VoiceOver does not read it again |
| TS-6 | **A burst.** Fourteen cards (a mix of tones, some with a message line, some title-only) in a Regular pane: the column runs past the pane's bottom edge and is cut by it, the last visible card cut through. No fade, no scroll bar, no "+N more" line. The page under the stack stays clickable everywhere outside a card |
| TS-7 | **The composer's toast moves.** The Citation composer after a bridge is saved: the success card `Bridge saved` / `James Robins · Mary Ann Robins. Its card is on the evidence graph, halfway between the two.` is in the window's stack, top-trailing over the composer, not at the foot of the observations column. The observations column draws no toast of its own |
| TS-8 | **Entering and leaving.** A new card slides in from the trailing edge and fades in at the top; the cards below move down. A card that leaves slides out to the trailing edge and fades; the cards below move up. With Reduce Motion on, cards only fade in and out. Draw as captions or a small strip of before/after states on the component sheet, not as separate pane frames |
| TS-W1 | **Wide.** The stack does not change with the pane's width class: it stays 360 pt wide in the content pane's top-trailing corner, 24 pt from the pane's top and trailing edges, at Regular and at Wide. The page under it keeps its agreed Wide arrangement |

### 4.1 Wide layout

| View | Regular (pane below 1600 pt) | Wide (pane 1600 pt and up) | What moves where |
| --- | --- | --- | --- |
| Workspace content pane (any page) | The page as agreed; the stack top-trailing, 24 pt in, 360 pt wide | The page as agreed at Wide; the stack top-trailing, 24 pt in, 360 pt wide | Nothing: a toast is a notice, not page content, so it gains no width or column (TS-W1) |
| Citation composer | As agreed; the stack top-trailing over the composer | As agreed at Wide; the same | The bridge toast leaves the observations column's foot (TS-7) |

---

## 5. Suggested frames

Frames with an a / b pair are drawn at **Regular** (pane 1102 × 900) and **Wide** (pane 2296 × 1440), each with the toolbar above the pane, so TS-2's placement under it shows; the others at Regular. Do not draw the sidebar.

| Frame | Requirement | Draw |
| --- | --- | --- |
| K1 | TS-1, TS-8 | Component sheet: ToastStack with one, two and five cards (each tone once, one title-only card); the entering and leaving strip, and the Reduce Motion caption |
| T1a / T1b | TS-2, TS-3, TS-W1 | A Person page on its Gallery section with the two portrait cards stacked |
| T2 | TS-4 | Regular: a Source page with the counts danger card above a `Source saved` success card |
| T3 | TS-5 | Regular: the same Source page after a second counts failure: the danger card on top, the success card below it, one danger card only |
| T4 | TS-6 | Regular: the Sources list with fourteen cards, the column cut at the pane's bottom edge |
| T5a / T5b | TS-7, TS-W1 | The Citation composer with the `Bridge saved` card in the stack; the observations column's foot empty |

---

## 6. UI building-block inventory

| Building block | Layer | Status | Home | Notes |
| --- | --- | --- | --- | --- |
| Toast | Component | Ship | `macos/App/DesignSystem/Components/Toast/PVToast.swift` `PVToast`; web `components/feedback/Toast.jsx` | Every card in the stack. Unchanged: tone bar, icon, title, message, dismiss, 360 pt |
| Toast stack | Component | New | `macos/App/DesignSystem/Components/Toast/PVToastStack.swift` *(new)*; web `components/feedback/ToastStack/` *(new)* | The one place toasts draw in the workspace window. A kit piece by the working rule "(Batch 6) One toast stack per window" (user, 2026-11-17): content-agnostic, a column of Toasts. Second call site: none known; a sheet that later wants a stack would be one. Not a Card, not a list with rows |
| The window's toasts | Snowflake | Rethink | `macos/App/Features/Workspace/WorkspaceView.swift` (`countsToast`, `session.noticeToast` overlays) | Its two overlays go; the window's list lives on the workspace session, and the stack draws over the content pane (`WorkspaceContent`) |
| A page's toast | Snowflake | Rethink | `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift` `vocabularyToastOverlay` | Inside the workspace a page's toast joins the stack instead of drawing its own card; inside a sheet it draws its own card, as today |
| The composer's bridge toast | Snowflake | Remove | `macos/App/Features/CitationComposer/CitationComposerSubjectGroups.swift` `CitationComposerObservationsColumn` (its `.overlay(alignment: .bottom)` `PVToast`) | The overlay at the column's foot goes; the toast joins the stack (TS-7) |
| The likeness viewer's toast | Snowflake | Ship | `macos/App/Features/Conclusions/ConclusionPictureViewer.swift` | Unchanged: the sheet draws its own single toast. Not drawn on this board |

**Non-goals.** No new token, tone, color or card style; no change to Toast; no cap, pile, fade-out edge or counter; no ToastStack inside a sheet; no second stack per window.

---

## 7. Handoff

When the board is agreed: record the board's link, its turn and frames on the **Board** line here, in [`README.md`](README.md) and on the plan's **Board** line, with any value the board changed (the gap between cards, the inset, the clip). The plan copies TS-1 – TS-8 and TS-W1 into its Scope (already there) and moves from `Blocked` to `Planned`. When S16-58 lands, the brief moves to the spike's design archive.
