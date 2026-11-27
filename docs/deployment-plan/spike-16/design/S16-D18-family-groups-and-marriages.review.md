# Review — S16-D18 Family: siblings grouped by their parents, and each couple's marriage

**Rewrite (user, 2026-11-27).** The parents half was rewritten around sibling groups before the board: each sibling once, grouped by the person's parents they share; a parent drawn in each group. The FP-* requirements and frames below are superseded by FG-*; findings on blocks, the missing-parent mark, the per-set rails and the person-tile note no longer apply. The marriage half (FM-*) carries over, with its parents option reworded for groups. Round 3 reviews the rewrite.

## Round 3 (the rewrite)

**Verdict:** Fits with changes — Ready with changes; every finding fixed by the writer. Reviewer: both lenses (opus).

- **X-30 · blocker · No group for a person with no parents.** Fixed: domain rows for a person with no parents (one group, captioned Siblings, as 11d) and a group with no parents (one line among its members); frame 6; 11d and 11h in the Previews row; S16-82's scope entry says it.
- **X-31 · major · The bracket sentence contradicted FG-7.** Fixed: no bracket; the Other siblings group stands on its own.
- **X-32 · major · FM-2 A for a non-adjacent couple.** Fixed: the line sits under the lower parent and names the other spouse; frames M4-A and M4-C (restores round-1 X-2's fix).
- **X-33 · major · Nothing draws the other spouse.** Fixed: `PVDatePlaceLine` Extend, a trailing part, the place cut first.
- **X-34 · major · The parity test is Go.** Fixed: S16-82 adds `kinship.SpouseEventTypes()`; S16-81's map row allows the one test row.
- **X-35 · major · The person's-group label for frames 4 and 6.** Fixed: FG-4 lists the variants.
- **M-20 · major · A hand-made couple format.** Fixed: the list formatter, one "Children of %@".
- **M-21 · major · Spoken order multiplies formats.** Fixed: drawn and spoken in one order, one "with %@" clause.
- **M-22 · minor · The empty slot redraws a kit outline.** Fixed: `PVCard(border: .dashed)`.
- **M-23 · minor · Three life-line loops.** Fixed for option C (one life-line view); `PVPersonCardTests` named.
- **X-36 · minor · "No parent on file".** Fixed: none of the person's parents.
- **X-37 · minor · Frame details.** Fixed: M5 drawn as if folded, M1-Word, frame 0's order.

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

## Merged from S16-D19 (marriages)

S16-D19 was reviewed on its own, then merged into this brief before the board (user, 2026-11-26). Its frames are this brief's M1–M5; its requirement IDs (FM-*) are unchanged.


**Verdict:** Fits with changes — Ready with changes (round 2's findings fixed by the writer; no round 3, per the two-round cap). The remaining calls are the board's options, To user.
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

#### To user
- The marriage line is text, not a link: opening the marriage from Family is out of S16-82 (the Timeline opens it). This answered four findings (X-4, X-9, M-3, M-5) and a nested button (X-6, M-7). Say if you want it to open the Event; that is a later PR with its own look.
- FM-2 (parents): A between the tiles, or C inside the lower parent's tile. FM-3 (partners): B over the partner's group, or C inside the partner's tile. FM-4: "m." or "Married". Writer's recommendation: C in both columns with "m.", since it is a life line like "b." and "d.". C is not free: tiles grow with their lines, a change to the kit tile every tile uses (X-13). A/B leave tiles alone but add room between them.

#### Writer's own calls
- No line for a spouse link without a marriage event (working rule).
- Two marriages are two lines, earliest first, undated last; the count option is struck (M-4).
- A marriage with neither date nor place shows "m." alone.
- A pivot with no summary (merged or gone mid-read) shows no line; the plan tests it.

#### Round 1

##### X-1 · blocker · FM-2 B (in the margin) has no room
**Answer:** Fixed. Option struck; §2 states the room.

##### X-2 · blocker · Non-adjacent couples in overlapping sets
**Answer:** Fixed. FM-2 says how each option handles it; frames 4-A and 4-C; the line sits with the lower parent of the couple in C.

##### X-3 · blocker · No room on the bus or in the gutter
**Answer:** Fixed. FM-3 A struck; FM-3 says why.

##### X-4 · blocker · `PVInkLink` does not fit a date · place line
**Answer:** Fixed by making the line not a link (To user).

##### X-5 · major · No container names a couple
**Answer:** Fixed. FM-6: a standalone line is its own element naming the couple; inside a tile it is read with the tile.

##### X-6 · major · Option C needs two targets in `PVTileCard`
**Answer:** Fixed. The line is text; the tile keeps one target.

##### X-7 · major · "+1" collides with the place count
**Answer:** Fixed with M-4: FM-5's count option struck; `extraCount` counts the marriage's places only.

##### X-8 · major · Edges
**Answer:** Fixed: neither date nor place (FM-4), undated order (FM-5), folds (FM-7); a pivot with no summary and the cap are in the scope entry's "Settled in the plan".

##### X-9 · major · Back restore of a marriage stop
**Answer:** Fixed: no stop (FM-6).

##### X-10 · major · Event wording homes misnamed
**Answer:** Fixed. The inventory names `EventSecondaryDisplay.content` and `PersonLifeDisplay.LifeLine`.

##### X-11 · minor · Sample data; S16-D18 not agreed yet
**Answer:** Fixed. Heinrich and Katharina abt 1816; the enhancement note says the brief is pasted after S16-D18 is agreed and uses its choices.

##### X-12 · minor · Frame naming
**Answer:** Fixed. Frames 1-A/B, 1-C, 1-W, 4-A, 4-C named.

##### M-1 · blocker · "m." / "Married" fixed to marriage
**Answer:** Fixed. FM-4: the word comes from the event type; the inventory adds one abbreviation and word per type beside the seeded event type terms.

##### M-2 · blocker · A third "abbreviation + date · place" builder
**Answer:** Fixed. The marriage line is a `PersonLifeDisplay.LifeLine`, worded by `EventSecondaryDisplay.content`, spoken through the `a11yLifeLine*` formats.

##### M-3 · major · `PVInkLink` cannot hold the line
**Answer:** Fixed: not a link.

##### M-4 · major · FM-5 B reuses `extraCount`
**Answer:** Fixed. Struck.

##### M-5 · major · Back restore needs a new stop kind
**Answer:** Fixed: no stop.

##### M-6 · major · The line's slot and container
**Answer:** Fixed. Inventory: a placed entry in the couple's group; FM-6 names the couple in the line's own label.

##### M-7 · minor · Option C nests buttons
**Answer:** Fixed: text, not a button.

#### Round 2

##### M-8 · major · Life-line words in two homes (M-1 only partly fixed)
**Answer:** Fixed. One life-line words table by event type (abbreviation, display word, inline word); birth and death move into it; a parity test ties it to the spouse-implying patterns.

##### X-13 · major · Option C needs room and touches the kit tile
**Answer:** Fixed. To user corrected; inventory rows for `PVTileCardSize` and per-tile heights; lines keyed by position; no "+N" on tile lines.

##### X-14 · major · A bare "m." has no builder path or spoken text
**Answer:** Fixed. FM-4 and the Life line row: a line from an event that exists is kept with both halves missing; FM-6 gives its spoken text.

##### X-15 · major · Whom a marriage is with in a block of several couples
**Answer:** Fixed. FM-2: in a block with more than one couple a marriage line names the other spouse, in either option; FM-6 speaks it; `LifeLine` gains the optional spouse part.

##### X-16 · minor · The couple format for A and B
**Answer:** Fixed. Copy row names it.

#### Cost

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 149k |
| 1 | executability | sonnet | 145k |
| 2 | both lenses | opus | 116k |
