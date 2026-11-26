# Review — S16-D19 Family: when and where a couple married

**Verdict:** Fits with changes — Ready with changes (round 2's findings fixed by the writer; no round 3, per the two-round cap). The remaining calls are the board's options, To user.
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- The marriage line is text, not a link: opening the marriage from Family is out of S16-82 (the Timeline opens it). This answered four findings (X-4, X-9, M-3, M-5) and a nested button (X-6, M-7). Say if you want it to open the Event; that is a later PR with its own look.
- FM-2 (parents): A between the tiles, or C inside the lower parent's tile. FM-3 (partners): B over the partner's group, or C inside the partner's tile. FM-4: "m." or "Married". Writer's recommendation: C in both columns with "m.", since it is a life line like "b." and "d.". C is not free: tiles grow with their lines, a change to the kit tile every tile uses (X-13). A/B leave tiles alone but add room between them.

## Writer's own calls
- No line for a spouse link without a marriage event (working rule).
- Two marriages are two lines, earliest first, undated last; the count option is struck (M-4).
- A marriage with neither date nor place shows "m." alone.
- A pivot with no summary (merged or gone mid-read) shows no line; the plan tests it.

## Round 1

### X-1 · blocker · FM-2 B (in the margin) has no room
**Answer:** Fixed. Option struck; §2 states the room.

### X-2 · blocker · Non-adjacent couples in overlapping sets
**Answer:** Fixed. FM-2 says how each option handles it; frames 4-A and 4-C; the line sits with the lower parent of the couple in C.

### X-3 · blocker · No room on the bus or in the gutter
**Answer:** Fixed. FM-3 A struck; FM-3 says why.

### X-4 · blocker · `PVInkLink` does not fit a date · place line
**Answer:** Fixed by making the line not a link (To user).

### X-5 · major · No container names a couple
**Answer:** Fixed. FM-6: a standalone line is its own element naming the couple; inside a tile it is read with the tile.

### X-6 · major · Option C needs two targets in `PVTileCard`
**Answer:** Fixed. The line is text; the tile keeps one target.

### X-7 · major · "+1" collides with the place count
**Answer:** Fixed with M-4: FM-5's count option struck; `extraCount` counts the marriage's places only.

### X-8 · major · Edges
**Answer:** Fixed: neither date nor place (FM-4), undated order (FM-5), folds (FM-7); a pivot with no summary and the cap are in the scope entry's "Settled in the plan".

### X-9 · major · Back restore of a marriage stop
**Answer:** Fixed: no stop (FM-6).

### X-10 · major · Event wording homes misnamed
**Answer:** Fixed. The inventory names `EventSecondaryDisplay.content` and `PersonLifeDisplay.LifeLine`.

### X-11 · minor · Sample data; S16-D18 not agreed yet
**Answer:** Fixed. Heinrich and Katharina abt 1816; the enhancement note says the brief is pasted after S16-D18 is agreed and uses its choices.

### X-12 · minor · Frame naming
**Answer:** Fixed. Frames 1-A/B, 1-C, 1-W, 4-A, 4-C named.

### M-1 · blocker · "m." / "Married" fixed to marriage
**Answer:** Fixed. FM-4: the word comes from the event type; the inventory adds one abbreviation and word per type beside the seeded event type terms.

### M-2 · blocker · A third "abbreviation + date · place" builder
**Answer:** Fixed. The marriage line is a `PersonLifeDisplay.LifeLine`, worded by `EventSecondaryDisplay.content`, spoken through the `a11yLifeLine*` formats.

### M-3 · major · `PVInkLink` cannot hold the line
**Answer:** Fixed: not a link.

### M-4 · major · FM-5 B reuses `extraCount`
**Answer:** Fixed. Struck.

### M-5 · major · Back restore needs a new stop kind
**Answer:** Fixed: no stop.

### M-6 · major · The line's slot and container
**Answer:** Fixed. Inventory: a placed entry in the couple's group; FM-6 names the couple in the line's own label.

### M-7 · minor · Option C nests buttons
**Answer:** Fixed: text, not a button.

## Round 2

### M-8 · major · Life-line words in two homes (M-1 only partly fixed)
**Answer:** Fixed. One life-line words table by event type (abbreviation, display word, inline word); birth and death move into it; a parity test ties it to the spouse-implying patterns.

### X-13 · major · Option C needs room and touches the kit tile
**Answer:** Fixed. To user corrected; inventory rows for `PVTileCardSize` and per-tile heights; lines keyed by position; no "+N" on tile lines.

### X-14 · major · A bare "m." has no builder path or spoken text
**Answer:** Fixed. FM-4 and the Life line row: a line from an event that exists is kept with both halves missing; FM-6 gives its spoken text.

### X-15 · major · Whom a marriage is with in a block of several couples
**Answer:** Fixed. FM-2: in a block with more than one couple a marriage line names the other spouse, in either option; FM-6 speaks it; `LifeLine` gains the optional spouse part.

### X-16 · minor · The couple format for A and B
**Answer:** Fixed. Copy row names it.

## Cost

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 149k |
| 1 | executability | sonnet | 145k |
| 2 | both lenses | opus | 116k |
