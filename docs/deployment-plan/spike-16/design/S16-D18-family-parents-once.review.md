# Review — S16-D18 Family: each parent drawn once

**Verdict:** Fits with changes — Ready with changes (round 2's findings fixed by the writer; no round 3, per the two-round cap). The remaining calls are the board's options, To user.
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- FP-3: how the missing parent shows (A dashed stub, B join dots, C per-parent lines, D a tile note). Writer's recommendation: A, the page's existing "not recorded" mark, with FP-6 A spoken. Choosing C changes the working rule "(Batch 6) The Family section draws each parent once" (one line per set).
- FP-5: a block of overlapping sets: A caption only, or C a rule inside the block. Writer's recommendation: A.
- FP-6: a marked sibling's spoken phrase: A "child of ⟨parents⟩" only, or B that plus "other parent not recorded". Writer's recommendation: B, so the missing link is heard as it is seen.
- The siblings' order is the engine's: a sibling recorded with only the mother is drawn before the full siblings. If it reads wrong once parents are drawn once, it is a Go change and a new decision.

## Writer's own calls
- The mark applies only when a sibling's set lies inside another set of the block (X-5): overlapping sets mark nobody.
- The parents' fold counts parent tiles (FP-8); what a folded parent does to its lines is left to the S16-81 plan.
- Captions keep today's rule (X-7).
- More than ten parents keeps one block per parent, as today (X-8).

## Round 1

### X-1 · blocker · Frame sibling orders were not the engine's
**Answer:** Fixed. §1 states the order rule; frames 0–4 and 6 list siblings in `originSiblings`' order (checked by hand against `core/database/persondetail/family.go`); frame 3 fixes the link order.

### X-2 · blocker · FP-6 needs a spoken slot the tile lacks
**Answer:** Fixed with M-2. The Person tile is Extend: `PVPersonCardContent` gains one optional note, always spoken, drawn only for FP-3 D.

### X-3 · blocker · FP-3 D pointed at `lines`, which hold no free text
**Answer:** Fixed with M-2 (the note, not `lines`).

### X-4 · blocker · The parent-sets fold had no meaning once tiles are distinct
**Answer:** Fixed. FP-8: the fold counts parent tiles and looks as today; the folded-parent edge is the plan's (map scope entry "Settled in the plan").

### X-5 · major · The mark is a false claim on overlapping sets
**Answer:** Fixed. FP-3 marks only a set inside another, against the parents that set adds; frame 2 draws no mark.

### X-6 · major · Line geometry undecided
**Answer:** Fixed as far as a board decides it: FP-3 and FP-4 ask the board to draw how two sets' lines meet at a shared parent and how a sibling in two sets is joined. Exact x positions are the plan's.

### X-7 · major · Caption rule changed a lone first parent's caption
**Answer:** Fixed. FP-5 keeps today's rule; frame 6 draws two unpaired parents.

### X-8 · major · Past the pairing bound
**Answer:** Fixed. FP-2 says it stays one block per parent.

### X-9 · minor · FP-5 B and C undefined
**Answer:** Fixed. B struck (M-1); C says where the rule falls.

### X-10 · minor · Copy details
**Answer:** Fixed. FP-6 gives the phrase's place (after the name, before the life lines), the two-parent form, and D's words; FP-7 runs across blocks.

### X-11 · minor · Wide's extra space
**Answer:** Fixed. §4.1 says the columns and gutter widen and the lines' geometry is the same.

### X-12 · nit · Inventory omits files
**Answer:** Fixed: previews and copy rows; the tests named under the inventory.

### M-1 · blocker · "Records disagree" badge is a client reconciliation judgment and a reused phrase
**Answer:** Fixed. FP-5 B struck, with the reason in FP-5.

### M-2 · blocker · FP-6 needs a tile slot; D pointed at `lines`
**Answer:** Fixed. Person tile row: Extend, one generic note feeding spoken, help and drawn text.

### M-3 · major · A dashed not-recorded stub already exists on the Timeline
**Answer:** Fixed. FP-3 A names it; the diagram row uses `PVStroke.dashPattern` and S16-81 moves the Timeline's `[3, 3]` onto it.

### M-4 · major · Blocks derived in two places
**Answer:** Fixed. Content works out blocks, captions and marks; the layout only reads them.

### M-5 · minor · Option C bends the working rule; B adds a second line style
**Answer:** Fixed. C says it changes the rule and is the user's; B applies dots to the whole diagram.

### M-6 · minor · Doc comments and names made false
**Answer:** Fixed in the Handoff.

### M-7 · nit · Lines as one typed list
**Answer:** Fixed in the Handoff.

### M-8 · minor · Where the distinct-parents step lives
**Answer:** Fixed. A line in `docs/ideas/kinship-view.md`.

## Round 2

### X-13 · blocker · FP-6 was narrower than bar 50 ("VoiceOver says which parents each sibling is recorded with")
**Answer:** Fixed. FP-6: every sibling not in all of their block's sets is spoken "child of ⟨parents⟩"; the marked case chooses only whether to add "other parent not recorded". Frame 2 annotated.

### M-9 · blocker · The dash token answer would change the Timeline's look and overload the outline token
**Answer:** Fixed. A new `PVStroke.notRecordedDash` ([3, 3]); the Timeline's three literals move onto it with no visual change; `dashPattern` stays for outlines.

### X-14 · major · A set inside several sets
**Answer:** Fixed. FP-3: the mark is against every parent those sets add.

### Noted · The right column's description contradicted 11a
**Answer:** Fixed: the right column is 11a's, named as the preview has it.

## Cost

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 137k |
| 1 | executability | sonnet | 113k |
| 2 | both lenses | opus | 112k |
