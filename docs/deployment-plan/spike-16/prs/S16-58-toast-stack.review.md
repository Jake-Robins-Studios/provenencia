# Review — S16-58 Toasts stack in one list per window

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet). Plan and brief S16-D10 reviewed together.

No round 2: round 1's blockers (M-1, M-2) were a rule moved into the kit `add` and a missing Rules-bent row, both fixed without a reshape; X-1 is the board, which is the user's.

## To user

- **X-1 · The S16-D10 board.** The plan stays `Blocked — on board S16-D10` until the board is drawn and agreed.

- **How the agreed board reaches the implementer.** Recommendation: the board's artifact link and turn on the **Board** line, as S16-D8 and S16-D9 did.

## Writer's own calls

- D-1, D-2: the list is a kit type (`PVToastList`) owned by `WorkspaceSession` (`session.toasts`), so S16-59's models reach it through the session they already hold.
- D-3: expiry lives in the list with an injected sleep (the `PVClipboardCopyState` pattern), not in each card's view.
- D-5: `PVSheetChrome` clears the list for every sheet, not only the likeness viewer.
- D-8 / TS-2: the stack sits over the content pane under the toolbar, not over the whole window as the window's toasts do today.
- D-11 (from M-3): the composer adds its toast to `session.toasts` in this PR and `bridgeToast` goes; the S16-59 map scope entry no longer lists it.
- D-10: `CatalogCounts.lastRefreshError` and `clearRefreshError()` go; the model adds the toast itself (QCK-1).
- Edges: a page toast already in the stack when the likeness viewer opens stays until its timer.

## Round 1

### M-1 · blocker · The empty-message rule sits in a feature adapter, not in the kit's `add`
`VocabularyToast.body` uses `""` for no message; `PVToastEntry` uses `nil`. Only the adapter converted, so an S16-59 caller passing `""` to `add(tone:title:message:)` would draw a blank line and miss D-4's repeat match.
**Answer:** Fixed — D-4: `add(tone:title:message:)` turns an empty title or message into `nil` before matching; D-6: `add(_: VocabularyToast)` is a one-line forward beside `VocabularyToast` in `VocabularyPane.swift`; T-6 covers `nil` and `""` matching; Next adds names the call S16-59 uses.

### M-2 · blocker · Two one-caller kit types, but "Rules this plan bends: None"
`add-ui-component` and `design-system-layers.md` ask for two call sites.
**Answer:** Fixed — §5 Rules this plan bends lists it with the user's answer (working rule "(Batch 6) One toast stack per window", 2026-11-17); STEP-8 records it in the README row.

### M-3 · major · The composer can add to `session.toasts` now instead of being retyped, then deleted in S16-59
**Answer:** Fixed — D-11, STEP-7: the bridge save calls `session.toasts.add`; `bridgeToast` and the column's overlay go; the S16-59 scope entry drops `bridgeToast`. The suggested model test is not added: no test saves a bridge today, and building that harness is outside this PR; AC-3.1 stays on manual check 4.

### M-4 · major · After S16-59, `\.pvToastList` and D-5's sheet rule have no reader
**Answer:** Fixed — D-8: the stack reads `session.toasts`, so the key's one reader is the forwarding; D-5 calls it transitional; Next adds and the S16-59 scope entry say S16-59 deletes the key and the sheet clear, and that a model raising a toast under a sheet decides where it draws, as `ConclusionLeadModel.toastInViewer` does.

### M-5 · major · `use-catalog-session` tells agents to set `lastRefreshError`
**Answer:** Fixed — STEP-5 names the skill and gives the new line. (Same as X-2.)

### M-6 · minor · Two expiry mechanisms in the kit
**Answer:** Fixed — STEP-8's README text names the split; merging them is an Out line, not planned.

### M-7 · minor · `noticeToast` could go in this PR
**Answer:** Declined — the map assigns `noticeToast` to S16-59 (scope entry S16-59), and unlike the composer no retype is saved; D-9 names the modifier order and manual check 2 covers it.

### M-8 · nit · `WorkspaceSession`'s doc comment
**Answer:** Fixed — STEP-5.

### M-9 · nit · T-7 tests a feature extension in the kit suite
**Answer:** Fixed — T-7 moves to `VocabularyToastTests.swift` *(new)*.

### M-10 · nit · Brief says `WorkspaceView` holds the list
**Answer:** Fixed — the brief's inventory row says the workspace session holds it.

### X-1 · blocker · The board is not drawn
**Answer:** To user — the gate; status stays Blocked.

### X-2 · major · The sweep hits `use-catalog-session/SKILL.md`
**Answer:** Fixed — see M-5.

### X-3 · major · The preview empties itself after five seconds
**Answer:** Fixed — STEP-3 builds the preview's list with a sleep that never returns.

### X-4 · major · `CatalogCounts` test seam unspecified
**Answer:** Fixed — STEP-5: `makeCounts(store:toasts:)` with a `ManualSleep` list by default; T-8 passes its own list and dismisses `entries[0].id`; T-9 names the renamed tests.

### X-5 · major · STEP-5 and STEP-6 could not build apart
**Answer:** Fixed — STEP-5 now adds `session.toasts`, the `CatalogCounts` parameter, `WorkspaceView.init`'s call and the removal of the counts `.onChange` in one commit; STEP-6 draws the stack.

### X-6 · minor · `identifier:` is dead in the forwarding branch
**Answer:** Fixed — D-6: used only on the card path.

### X-7 · minor · Coalesced equal sets
**Answer:** Fixed — Edges, "Coalesced sets".

### X-8 · minor · Empty column
**Answer:** Fixed — D-7: no entries, no view.

### X-9 · minor · Hit-testing unproven
**Answer:** Fixed — D-7 states no background or `contentShape`; a failed manual check 7 is a Stop condition.

### X-10, X-11 · minor
**Answer:** X-10: Next adds notes new sheets use `.pvSheet`. X-11: no change (the reviewer found the brief meets the lens).
