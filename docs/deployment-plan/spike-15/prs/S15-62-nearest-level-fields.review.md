# Review — S15-62 A format reads a field from the nearest level

**Verdict:** round 1: Fits with changes — Ready with changes; round 2: see below
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user

None. The one product call, where an unsuggested format field shows before S15-63, was asked while planning: every board (user, 2026-11-22; D-10).

## Writer's own calls

- D-4: a list-form `{meta.key}` is pinned to the Source in the parse tree (`ListFormLevel`), not by passing the form to the resolver.
- D-4: a chain keeps each target once, so a migrated `{meta.#X|meta.#X}` reads as `{meta.#X}`; the stored text keeps the repeat until the researcher edits it.
- D-2/D-3: `meta_not_at_level` goes along with `unprefixed_meta`; `{citation.meta.x}` is `meta_at_level`.
- D-11: completion lists the built-ins level by level, then every field once.
- D-18: a missing option with no level prints its name alone ("Missing: Jurisdiction"); the list form's says "on the Source".
- D-19: the `meta_at_level` copy, "Write meta. with no level: a field is read from the nearest level that has it".
- D-12: the migration's `replace()` also rewrites a literal `\{source.meta.` in a format's plain text; accepted as not planned.

## Round 1

### M-1 · blocker · D-8 turns list-only needs into needed, undismissable rows on every lower board
A Source-pinned list-form head under D-8 headed every board, so a book's Artifact board showed `author_sort` needed and undismissable, though the list form reads only the Source; rule "The list entry reads the Source; a board flags a list field set below it" says hint, not refusal.
**Answer:** Fixed. D-8 keeps `fieldAt` and widens it to `t.Level == "" || t.Level == level`; `fieldOf` is dropped. D-10 says a list-only head shows and is refused only on the Source board. T-7 and T-8 gain the book `author_sort` cases.

### M-2 · major · One board-level `above` resolver instead of a per-call `Without`
**Answer:** Fixed. D-9: callers build `above := r.Without(o.Level)` once per board on `boardInput.above`; `annotate` takes `above`; the head is tested from `ch.Targets[0]`, and `buildEntries` passes a head with no level. Codebase fit row added.

### M-3 · major · D-14 made `usualLevel` a second level table; `TestSeededFormatsNeedOnlySuggestedFields` keyed by target level
**Answer:** Fixed. D-14: `derivedSuggestions` returns one level-free list; `TestSeedSuggestionsFollowFormats` compares sets over all levels; `TestSeededFormatsNeedOnlySuggestedFields` keys by type and field. Levels stay only in `registry_suggestions.go`. T-12 names both tests.

### M-4 · major · The spoken completion label is built in two places
**Answer:** Fixed. D-17 adds `SourceTypeFormatsModel.spokenLabel(of:)`, used by the row's accessibility label and the `.highlighted` announcement; T-14 covers it.

### M-5 · minor · The list form's level declared twice
**Answer:** Fixed. D-4 adds `ListFormLevel` in `builtins.go`; `ListFormAllows` compares against it.

### X-1 · blocker · STEP-2 – STEP-6 checks cannot pass before the seed is rewritten
`sourcevocab.Install` refuses a seed format with any diagnostic, so every test that installs the seed fails once the parser refuses level-named tokens.
**Answer:** Fixed. The seed rewrite (D-13) and its tests (D-14) moved into STEP-2; the old STEP-7 is gone and the steps renumbered (nine).

### X-2 · major · T-10 named twice; the migration step had no check
**Answer:** Fixed. STEP-6 no longer cites T-10 and gains a `sqlite3` run of the step on AC-3.1's text. T-11 and T-12 are cited by STEP-2.

### X-3 · major · The T-5 rename described two ways
**Answer:** Fixed. D-5 now says `TestMetaPlaceholder` is renamed `TestMetaFieldPlaceholder`, as T-5.

### X-4 · major · The head `buildEntries` passes to `annotate`
**Answer:** Fixed in D-9: no level; the chain's own first option is what is tested.

### X-5 · major · Which `needsAt` callers change
**Answer:** Fixed. D-8 and STEP-4: `readTypeBoards`' (type, level) keying and `buildEntries`' emit loop do not change; `needOfTx` is unchanged code. Skipping a head already valued at the owner is today's behavior (the value's own entry carries it).

### X-6 · major · `TestListWorkspacesAnnotationsScale`'s budget
**Answer:** Fixed. It has no time budget; it asserts the annotations of 121 boards. Scale says its expected annotations are updated where D-8 – D-10 change them and its query count does not; the stop condition now names a change beyond that.

### X-7 · minor · Paths and the map's section list
**Answer:** Fixed. `completed.md` is written in full; STEP-9 updates the rule "A format reads a field…" (`slices.Reverse`, and §§ 6.3, 6.6, 6.8, 6.9); § 6.9 joins the docs list. The map's Plan link is wired with this log.

### X-8 · minor · Swift checks need macOS
**Answer:** Fixed. § 7 opens by saying `check-pr.sh` and the Swift checks run on macOS with Xcode.

### X-9 · minor · Smaller choices
**Answer:** Fixed: D-17 writes `row.level.map(L10n.CitationFormats.levelName)`; D-18 says a nil-level option never uses `missingOptionSameName`, and T-15 tests the mixed case; D-16 names the id change in `GoStore`. The website measurement no longer matters (D-14 has no levels). The token count is left as is (it counts `{`/`|`-prefixed and bare tokens alike).

## Round 2

Maintainability: every round-1 answer holds; one new blocker from the M-2 fix.

### M-6 · blocker · `Without` kept the built-ins, but D-9 relied on `above` having none
`listWorkspaces` puts `SourceDate` in `r.Builtins`, so `r.Without(source)` still answered it, and the Source board's own date would read met elsewhere.
**Answer:** Fixed. D-7: `Without(l)` also drops every built-in at level `l`. D-9's wording follows. T-6 gains `Without(source)` → zero for `SourceDate`; T-7 gains a set Source date on the Source board → not met elsewhere.

Stale lines (not blockers): § 6 Go core's `sourcemetadata` row now says callers pass `above`; the `citationformat` row names `ListFormLevel` in `builtins.go`. Fixed.
