# Stacked toasts

**Status:** pulled into Spike 16 Batch 6 as S16-58 and S16-59 (2026-11-17). Parked 2026-11-12 from dogfood while testing portrait swaps (user). The bug a quick replacement exposed, where a new toast vanished on the old toast's timer, was fixed in `PVToast` (quick PR #796). This doc is the feature the bug pointed at.

## Problem

A screen shows one toast at a time. A second message replaces the first, so a researcher who acts twice in a row (two portrait choices, two saves) sees only the latest message, and the earlier one is gone before it could be read.

It is worse than replacement. A toast is drawn by whichever overlay owns it, and several overlays share the window's top-trailing corner:
- `WorkspaceView` draws two: the counts toast (`countsToast`) and the session's notices (`session.noticeToast`).
- Each workspace page draws its own through `vocabularyToastOverlay($model.toast, …)`: Properties, the Source page, the Sources list, the Source type page, Metadata, the Evidence graph, the Conclusion detail page.
- The Citation composer draws `bridgeToast` with `PVToast` directly, at the foot of its observations column. In the stack it moves to the window's top-trailing corner like every other toast (user, 2026-11-17), so S16-58 moves it and S16-D10 draws it.

Two of these can show at once, one on top of the other.

## Shape

- **One stack per window** (user, 2026-11-17). The workspace window holds one toast list (an `@Observable` model, named in S16-58's plan, put in the environment by `WorkspaceView`). Every workspace surface adds to it, and one kit view draws it top-trailing, so no two toasts overlap. A sheet (the likeness viewer, `ConclusionPictureViewer` under `.pvSheet`) covers the window and keeps its own overlay, so the viewer's rule that only one surface shows the lead's toast (`ConclusionLeadModel.toastInViewer`, S13-15 D-10) is unchanged. Onboarding has no workspace and keeps its single `PVToast`.
- **A stack view in the kit.** `PVToastStack` (design-system layer, [`add-ui-component`](../../../.agents/skills/add-ui-component/SKILL.md)) draws a list of entries, newest at the top. Each entry has its own id and leaves on its own timer (five seconds, `PVToast`'s default) or its dismiss button; dismissing one never touches another's timer. `PVToast` stays the single card.
- **No cap** (user, 2026-11-17). Every toast shows until its own timer or its dismiss. The stack never pushes one out early. A burst taller than the window is clipped at the window's bottom edge; S16-D10 draws how the clipped edge looks.
- **A caller refreshes its own card by id** (user, 2026-11-17; changed 2026-11-22). Every add makes a new card and returns its id: a researcher's action happened each time, so each gets its card, and the list never compares toasts by their text. A caller that wants one card for a repeating event (the failed catalog recount) keeps the id and passes it back: while that card is on screen it takes the new text, restarts its five seconds and moves to the top, with no second card and no second announcement when the text is unchanged; once it has gone, a new card is added.
- **VoiceOver.** A new card announces itself once, as a single toast does today. A refreshed card does not, so a burst of the same message is one announcement.
- **Reduce Motion.** Cards fade in and out instead of sliding, as the single toast does.
- **Callers add, they do not set.** S16-58 keeps today's callers working: `vocabularyToastOverlay` inside the workspace forwards a toast set on its binding into the window stack and clears the binding. S16-59 then moves each caller to add to the stack directly, and the forwarding goes.

## Check

Two toasts added within five seconds both show, stacked, and each leaves five seconds after it appeared. Dismissing the lower one leaves the upper one's timer untouched. A workspace notice and a page's toast never overlap.
