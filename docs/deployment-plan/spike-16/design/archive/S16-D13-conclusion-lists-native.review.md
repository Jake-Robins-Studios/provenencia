# Review — S16-D13 The Persons, Events and Places lists on the native list

**Verdict:** Fits with changes — Ready with changes, 2 rounds; no blocker open
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- M-2 (Wide): the user chose the list filling the whole pane at every width, to judge on the board (2026-11-23). The brief records the bent § 9 rule 3 and asks the board to draw two row-content options at Wide.
- M-4 (accent): the user accepted the system accent for the selection (2026-11-23).

## Writer's own calls
- Home/End scroll without changing the selection (Finder's behavior), and are the one key the app adds.
- On arrival from the sidebar nothing is selected; Back selects the opened row.
- The failure Callout keeps its readable width.

## Round 1

### M-1 · blocker · Rebuild `PVList` on `List` instead of deleting it
**Answer:** Fixed — inventory "Browse list: `PVList`, Rethink"; map S16-67 rebuilds `PVList` on `List` and keeps its slots.

### M-2 · blocker · CL-W1 adds a third Wide arrangement
**Answer:** To user → full width at every width (user). Fixed — header "Rules this brief bends", CL-W1 with options (a) and (b), § 4.1, the working rule.

### M-3 · major · Reuse the list pages' header
**Answer:** Fixed — CL-1 draws `VocabularyHeader`'s shape; inventory "List page header: Extend"; S16-67 moves it into the kit and the Sources copy onto it.

### M-4 · major · Selection claims on macOS 14
**Answer:** Fixed — § 2.1: system accent (iron on Multicolor), `textInverse` light ink, the row background question proven in S16-67; CL-4 draws blue, grey and iron.

### M-5 · major · Keyboard limits not in § 2.1
**Answer:** Fixed — § 2 Keyboard row: platform keys, Home/End added by the app (scroll, no selection change), the rest "expected, proven in S16-67"; map and bar 37 aligned.

### M-6 · minor · `PVReorderableList` precedent; density 11/16
**Answer:** Fixed — § 2.1 and the inventory.

### M-7 · nit · Failure state at Wide
**Answer:** Fixed — CL-9, CL-W2.

### K-1 · blocker · The working rule contradicts S16-67 and over-claims
**Answer:** Fixed — renamed "(Batch 6) The Conclusion lists are native lists", Home/End named as the one added key, `PVTable` excluded, binds S16-67 only.

### K-2 · blocker · A second Back-restore mechanism
**Answer:** Fixed — S16-67's entry: one named history field stamped on the entry being left; `ListScrollAnchorModifier` leaves only these pages; `add-workspace-location` updated.

### K-3 · major · Deletes and docs list
**Answer:** Fixed — `PVList` stays (M-1); S16-67's "Docs and skills" names the README sections, § 9, both idea files, the comments and the skill.

### K-4 · minor · Two selection looks and Page-key meanings
**Answer:** Fixed — S16-67 adds the `kit-layering.md` entry.

### K-5, K-6, K-7 · nits
**Answer:** Fixed — S16-66's entry cut to the re-scope line; S16-65's slice name; bar 37 states outcomes.

### X-1 · blocker · Header band build
**Answer:** Fixed with M-3 (the existing header, its hairline, no "board decides").

### X-2 · blocker · Row inset 24 vs 16
**Answer:** Fixed — 16 pt.

### X-3 · major · Empty secondary line
**Answer:** Fixed — § 2 Row height, CL-3, L1 draws a row with no life line.

### X-4 · major · Sample copy
**Answer:** Fixed — the app's count strings, the life line's badge, the italic place chain.

### X-5 · major · Skeleton Extend vs map
**Answer:** Fixed — skeleton stays (Extend, no card, fills the area); `PVList` stays.

### X-6 · major · Wide for empty, failure, loading
**Answer:** Fixed — CL-W2; L5a/b, L6a/b.

### X-7 · major · Selected ink
**Answer:** Fixed — `textInverse`, with what keeps its color.

### X-8 · major · Keyboard and VoiceOver claims
**Answer:** Fixed with M-5.

### X-9 · minor · Frames
**Answer:** Fixed — realistic visible counts, the scroll bar, Events and Places at Wide, a selected row with a badge.

### X-10 · minor · Board and PR number
**Answer:** Fixed — the user names the board; the PR is S16-67 (the branch name is local).

### X-11 · nit · Boilerplate Reach-for table
**Answer:** Declined — the Paste block is verbatim by the skill's rule.

## Round 2

Executability: X-1, X-4, X-5, X-7, X-11 hold; X-2 half fixed (X-12).

### X-12 · blocker · Row inset and header gutter disagree (16 vs 32)
**Answer:** Fixed — § 2.1 Row insets: the page gutter on both sides (32 / 56), aligning the thumbnail with the title and the ref with the count line; CL-3; CL-W1 (b) caps and centers the header's content with the rows.

### X-13 · blocker · L6a/L6b ambiguous; Wide failure undrawn
**Answer:** Fixed — L6a/b empty (Regular, Wide), L7a/b failure (Regular, Wide, L7b under both CL-W1 options).

### X-14 · major · Which CL-W1 option the other Wide frames use
**Answer:** Fixed — L3b, L5b and L7b are drawn under both options.

### X-15 · minor · CL-6 and the L2 style
**Answer:** Fixed — CL-6 is a caption on L1a; L2's crops use the board's chosen selection style.

Maintainability round 2: M-1, M-2, M-3, K-3 – K-7, M-6, M-7 resolved; M-4/X-7, X-2, K-2 and bar 37 not resolved (below).

### M-8 · blocker · `textInverse` is dark in dark appearance
**Answer:** Fixed — § 2.1, CL-4 and the inventory use the system's on-selection ink through `PVList` (background prominence), drawn white on blue in both appearances; iron in dark is proven in S16-67.

### M-9 · blocker · The 16 pt inset cannot align with the header
**Answer:** Fixed with X-12 (page gutter on both sides).

### K-8 · blocker · Bar 37 promises focus on arrival
**Answer:** Fixed — focus on arrival is a promise in the brief (§ 2 Keyboard, CL-6), the S16-67 entry (claimed on first appearance) and bar 37.

### K-9 · blocker · The Back-restore field is unnamed
**Answer:** Fixed — S16-67 uses the existing `WorkspaceLocation.listScrollAnchor`, no new field: the opened row (stamped as it opens) or the selected row on leaving another way. CL-6 covers Back without an opened row.

Below blocker: the S16-67 entry gains Deletes (`pvListChrome`, `PVListRowStyle`'s home) and § 9's "List → detail page" row; rule 3's text is not changed, so the Paste block stays.
