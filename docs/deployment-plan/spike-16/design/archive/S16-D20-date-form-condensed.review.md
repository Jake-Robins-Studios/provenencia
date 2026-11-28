# Review — S16-D20 The date form, condensed and keyboard-first

**Verdict:** Ready with changes; no blockers. All changes made. **Reviewer:** brief review (inventory reuse, facts against the code), 2026-11-28.

## To user

- **B20-3 · A range's time when the latest side's time block is closed.** Asked; the user answered by making the time fields always visible on both sides (rule "The time fields always show", 2026-11-28). The Add time / Remove time link goes, so the latest bound always has a visible time field to follow into.

## Findings

- **B20-1 · major** — The composer host is the 520 pt New observation dialog, not a page column. **Fixed:** View, DF-W1, § 4.1, frame 9 (about 452 pt).
- **B20-2 · major** — The latest side's time block had no Sec or Ms. **Fixed**, then superseded: with the time always shown, both sides get the same five fields (DF-5).
- **B20-4 · major** — The links were local plain buttons. **Fixed:** the Calendar and phrase link becomes `PVButton(variant: .link, size: .sm)`; the time link goes.
- **B20-5 · major** — HelpIcon was described wrongly and adds a Tab stop and copy. **Fixed** in DF-2, DF-9 and the Copy row.
- **B20-6 · minor** — The parts' captions are the form's own text. **Fixed** in § 1 and the inventory.
- **B20-7 · minor** — Month 13 can't be entered. **Fixed:** frame 6 uses Day 32.
- **B20-8 · minor** — Only Add Source shows a can't-be-saved line. **Fixed** in § 1, § 2 and DF-7.
- **B20-9 · minor** — The 560 pt width is shared, and S15-42 adds a marks row. **Fixed** in DF-10.
- **B20-10 · minor** — Two open Tab stops missing. **Fixed** in DF-9.
- **B20-11 · minor** — Inventory statuses for the Tab work. **Fixed:** Kind and Qualifier Extend; a `PVFieldFocus` row.
- **B20-12 · minor** — The Copy row and the map's Deletes disagreed. **Fixed:** the Copy row keeps the accessible names and hints; the handoff corrects the map's Deletes once the board is agreed.
- **B20-13 · nit** — The no-month option is "—". **Fixed.**
- **B20-14 · nit** — The leave-empty hint is on the first side only; two callouts stay. **Fixed.**
- **B20-15 · nit** — Height saved measured against today's form in the same state. **Fixed.**
