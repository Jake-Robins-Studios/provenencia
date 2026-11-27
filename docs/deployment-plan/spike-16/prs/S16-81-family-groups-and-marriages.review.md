# Review — S16-81 Family groups siblings by their parents and shows each couple's marriage

**Verdict:** Fits with changes — Ready; every finding answered, nothing open.
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user
- None. Two product calls were asked and answered before review (2026-11-27): a place-only marriage line is spoken "married in Altona"; a line that names the other spouse is spoken as drawn, with no couple before it.

## Writer's own calls
- One PR, with the life-line copy table and the parity row as its first commits (D-1).
- Tile ids `l-g{k}-{personID}`; older anchors land at the section's top (D-6).
- The siblings fold reveals a new group at its first parent (D-7).
- Geometry constants (D-10): lines 6 pt below a tile; the 4 pt partner offset only when a partner has a marriage.
- `EventSecondaryDisplay` moves to Platform, and `L10n.list` takes over the three existing `ListFormatter` joins (D-16, STEP-3).
- `FamilyUnits` drops `rules` (D-13).
- `ConclusionSummaryDisplay` stays in `Features/`; only `EventSecondaryDisplay` moves (D-16).
- An empty `siblingGroups` draws nothing on the left (D-19).
- The version bump is 0.48.3 → 0.49.0 (minor), done in STEP-10.

## Round 1

### M-1 · blocker · The life-line words table splices a bare translated word into shared formats
**Answer:** Fixed. D-2 and D-3: `L10n.LifeLine.Copy` holds whole phrases per event type (stated, date and place, date only, place only, an optional bare phrase, and the with-spouse phrases for spouse types). No phrase takes a translated word. The `a11yLifeLine*` formats and the bare-word keys go (**Deletes**, **Strings**). The bare phrase is nil for birth and death, so the keep-or-drop rule is data, not a flag (this also answers M-6).

### M-2 · major · A Platform type calls a formatter in a feature view file
**Answer:** Fixed. D-16 and STEP-3 move `EventSecondaryDisplay` to `macos/App/Platform/EventSecondaryDisplay.swift`.

### M-3 · major · `FamilyUnits` keeps an unread `rules`
**Answer:** Fixed. D-13 drops it (this also answers X-7).

### M-4 · major · A fourth and fifth hand-rolled `ListFormatter` join
**Answer:** Fixed. `L10n.list(_:locale:)` (Codebase fit, STEP-3). D-5, D-8 and the three existing callers use it.

### M-5 · major · Reading order stored beside the arrays it orders
**Answer:** Fixed. D-11 gives each layout group one ordered `items: [Placed]`; `tiles`, `lines` and `more` are computed from it.

### M-6 · minor · The builder takes a Bool for one caller
**Answer:** Fixed with M-1: there is no `keepsBare`. `partner` stays, because the spoken whole phrase depends on it.

### M-7 · minor · The origin check belongs with the lookup
**Answer:** Fixed. `copy(eventTypeKey:origin:)` uses `CatalogOrigin.isProduct` (D-2).

### M-8 · minor · `marriage(…)` copies the event fixture
**Answer:** Fixed. `PersonTimelinePreviewData.eventSummary` is split out of `event`, and `When.about` is added; `marriage` calls it.

### M-9 · minor · Life-line copy in three namespaces
**Answer:** Fixed with M-1: all of a line's copy, including `lifeLine.text`, is in `L10n.LifeLine`.

### M-10 · minor · Two names for group gaps
**Answer:** Fixed. `siblingGroupGap` and `partnerGroupGap` (the renamed `betweenGroups`), in D-10.

### M-11 · minor · The sweep misses `person-page-audit.md`
**Answer:** Fixed. STEP-10 names it, and the DoD and STEP-10 `rg` cover `docs/`.

### M-12 · minor · Facts stated twice
**Answer:** Fixed. The Steps point at **Deletes** and §8, D-15 no longer lists tests, and the Precedent paragraph is trimmed.

### M-13 · nit · `accessibilitySortPriority` is a new pattern
**Answer:** Fixed. STEP-10 adds a line to `macos-client-patterns.md`.

### X-1 · blocker · New types have no shape
**Answer:** Fixed. §6 **Codebase fit** has "Swift shapes" with every field.

### X-2 · blocker · The builder's signatures and `text` rule
**Answer:** Fixed. The full signatures are in Swift shapes. `LifeLine.text` is today's text, then `trailing`. `eventLine` always uses `.omitted`.

### X-3 · major · How `trailing` is laid out
**Answer:** Fixed. §6 **macOS** says how: an inner zero-spacing `HStack` with the last drawn part, never cut, plus a preview.

### X-4 · major · Couple names without a focus tile, and their order
**Answer:** Fixed. D-5: names are in order i then j, or the person then the partner; with no focus, a partner's line is spoken by its own label (T-11).

### X-5 · major · Tests T-12 – T-14 leave judgment
**Answer:** Fixed. T-12 and T-13 give their formulas over `kin`; T-14 lists every deleted and changed row. The fuzz seeds are the existing `f.Add` corpus.

### X-6 · major · STEP-7 too large
**Answer:** Fixed. It is now three steps (STEP-7 persondetail and handler, STEP-8 kinship, STEP-9 proto), and each compiles on its own.

### X-7 · minor · `rules` unused
**Answer:** Fixed with M-3.

### X-8 · minor · Geometry gaps
**Answer:** Fixed. D-10 says the last parent's gap applies before the children, the left column uses `siblingGroupGap` 20, and the right column keeps its band and `partnerGroupGap` 28.

### X-9 · minor · Fixture contents
**Answer:** Fixed. §6 **macOS** has a fixtures table.

### X-10 – X-14 · minor/nit · Paths and line numbers
**Answer:** Fixed. `ConclusionVocabulary.swift` and `completed.md` are now full paths, the `PersonDetailTests` names are given, `FakeStore` is dropped from STEP-6, and the brief's `.review.md` archives too. The header says which checks need macOS or `protoc`.

## Round 2

### M-14 · blocker · `L10n.list` leaves `PVDeleteImpact.cascadeLines`' `.formatted(.list(type: .and))` beside it
**Answer:** Fixed. §4 "List joins" names it; STEP-3 moves it onto `L10n.list`.

### M-15 · blocker · A fourth hand-written `LifeLine` → `PVDatePlaceLine` mapping, which drops `trailing`
**Answer:** Fixed. D-4 and Codebase fit add one `PVDatePlaceLine(_ line:dateTone:showsExtraPlaces:)`, with `LifeLine.missing` set when the line is built. STEP-3 moves `PersonDetailLifeLines`, `PersonLifeLine` and `PVPersonCard.lines` onto it; Family uses it in STEP-5.

### Not raised (round 2 maintainability)
- `value-formatting.md` goes stale: Fixed (D-16, STEP-10 rewords it).
- The map's Scale line names parent sets: Fixed (STEP-10).
- `lifeLine.marriage.stated` has no reader: Fixed (`stated` is optional, nil for marriage).
- T-2 should reuse `namedTerms`: Fixed (STEP-2).

### X-1 · blocker · STEP-10's sweep cannot come back empty
**Answer:** Fixed. The check covers `.agents`, `.cursor`, `docs/*.md`, `docs/ideas` and the audit file. The map's scope entries, the working rules and the plans keep their history (STEP-10 Do).

### X-2 · blocker · The marriage copy's step
**Answer:** Fixed. STEP-1 adds the whole `L10n.LifeLine` table, `SpouseCopy` and all its keys included; STEP-2 is test-only.

### X-3 · blocker · The fixtures do not compile against `When`
**Answer:** Fixed. `eventSummary` takes `dating:` and `marriage` takes a `CatalogDateValueInput`. Their forms are given, and `When` is unchanged.

### X-4 · major · Other content tests and an empty `siblingGroups`
**Answer:** Fixed. T-7 names the five tests and their new inputs; D-19 and the `alone` fixture cover the empty case.

### X-5 · minor · `kinship.go` names no `parentUnits`
**Answer:** Fixed. The §4 row now names `siblings.go:28` and `families.go:173,191`.

### X-6 · minor · STEP-7's expected callers
**Answer:** Fixed. They are listed in its Check.

### X-7 · minor · Small choices
**Answer:** Fixed. The version bump is in STEP-10. `stated` is optional. Names are spoken with `spokenText` (D-5, D-8). A reversed couple is matched by lower and higher index, and lines at one position stack (D-9). `eventLine` keeps `extraPlaces` (T-3). The `L10n.list` locale is D-18. The patterns doc's place is § 1. The Review line is set.

## Cost
Plan: 7,710 words at round 1, 8,568 at round 2, 9,085 at the verdict (check-plan-docs info line).

| Round | Reviewer | Model | Tokens |
| --- | --- | --- | --- |
| 1 | maintainability | opus | 193k |
| 1 | executability | sonnet | 151k |
| 2 | maintainability | opus | 214k |
| 2 | executability | sonnet | 196k |
