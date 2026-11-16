# Review — S15-14 The citation format engine

**Verdict:** Fits with changes — Not ready (round 1); every finding Fixed, round 2 pending
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user

None.

## Writer's own calls

- D-2: `valuemark.Validate` also refuses **supplied with no value**, beyond the map's "never both; unknown has no text".
- D-11: in a chain, an option **marked unknown stops the chain** (the graph's "not given" wins over the Source's value).
- D-11 / D-10: unknown with **no unknown text** prints nothing and drops its group, and still counts as answered (not missing).
- D-13: a chain holding an **always-set built-in** (title, type, Artifact label, graph name) is **used**, never needed.
- D-3: short-note month abbreviations `Jan.`, `Feb.`, `Mar.`, `Apr.`, `May`, `June`, `July`, `Aug.`, `Sept.`, `Oct.`, `Nov.`, `Dec.`; range with an en dash, printed once when both sides match.
- D-8 / D-9: `\}` and `\]` added to the map's escapes; limits 4,096 bytes and 8 levels of nesting; UTF-8 byte offsets; a group must hold a placeholder of its own; no spaces inside braces.
- D-14: stored field token is `#` + the canonical UUID; the rewrite replaces only field spans.

## Round 1

### M-1 · blocker · `CitationDisplay` adds a second end formatter beside `formatSide`, against the map rule and K3-3
**Answer:** Fixed — D-4 reshapes `formatSide(s side, st displayStyle)` and `applyQualifier` into one switch and one word table keyed by style; `CompactDisplay` moves onto `startSide`/`endSide` with unchanged output (T-2); STEP-2 does the reshape first.

### M-2 · blocker · The two new pure packages skip the purity guard
**Answer:** Fixed — D-1; STEP-1 and STEP-3 add `layerPackages` rows (`numbers: false`). Same as X-3.

### M-3 · major · `Ref` mixes identity with occurrence; `Missing` depends on template order
**Answer:** Fixed — D-6 adds comparable `Target`; `Resolver.Resolve(Target)`; `Requirement.Targets []Target`; D-13 tests `Missing` with no option at `FormFull`; AC-4.6 pins order independence.

### M-4 · major · The seed corpus has no retirement
**Answer:** Fixed — D-16 and Next adds: S15-20 deletes the file and `TestSeedFormatsParse`; Out row added; the map's S15-20 scope entry says so.

### M-5 · major · Third hand-written doc-table reader
**Answer:** Fixed — D-17, STEP-9: `core/internal/doctable.FirstColumn`, both existing tests move onto it (T-13).

### M-6 · minor · Untyped options
**Answer:** Fixed — D-5 `Option`, `OptionYear`, `OptionFull`.

### M-7 · minor · D-6 departed from the rule's per-row "allowed in the list form"
**Answer:** Fixed — D-7 adds `Builtin.InListForm()` over `ListFormAllows`.

### M-8 · minor · Key grammar not tied to `slug.Kebab`
**Answer:** Fixed — D-9 uses the same `unicode` predicates; T-11 checks every non-empty `Kebab` output parses.

### M-9 · minor · `CitationStyle` booleans allow a meaningless pair
**Answer:** Fixed — D-3 enum `CitationLong`, `CitationShort`, `CitationYear`.

### M-10 · minor · Docs still describe `datevalue` as compact display only
**Answer:** Fixed — STEP-10 updates the skill's line 12, its "Display (macOS)" note on citation terms, and the package comment (STEP-2).

### M-11 · nit · Same file name as the spike's design note
**Answer:** Fixed — the plan calls the new file the domain doc and names the spike note by full path.

### M-12 · nit · "Empty Builtin means metadata" is a convention
**Answer:** Fixed — folded into `Target` (D-6).

### X-1 · blocker · T-4's `unclosed_italic` input also triggers `group_without_placeholder`
**Answer:** Fixed — T-4 uses `*a [{source.title}* c]` with both spans.

### X-2 · blocker · `A:B` is `unknown_option`, not `bad_field`; character class unstated
**Answer:** Fixed — T-4 row corrected; D-9 states `unicode.IsLetter` / `IsDigit` / `_` / `-`; `bad_character` code for spaces and specials.

### X-3 · major · Purity guard rows
**Answer:** Fixed — see M-2.

### X-4 · major · Spans and stop behavior unspecified
**Answer:** Fixed — the codes table gives each code's trigger and span; D-8: stable sort, nothing reported after a stop (open groups included), one diagnostic per option in table order; `group_without_placeholder` only for closed groups.

### X-5 · major · Option shapes undecided
**Answer:** Fixed — codes table covers `{title}`, `{meta}`, spaces, `{source.}`, `{source.title:}`, `year:full`, `\` and `{` inside a placeholder.

### X-6 · minor · Field token edges
**Answer:** Fixed — D-9 refuses Nil and non-canonical UUIDs (AC-6.3); D-14 adds `ErrFieldRef` for an answer with both or neither set (T-10).

### X-7 · minor · `CitationDisplay` edges
**Answer:** Fixed — D-3 covers a one-sided range, unknown kind, year 0 and negative years; T-3 rows added.

### X-8 · minor · Doc headings and the § 3 sentence
**Answer:** Fixed — D-18 names the sections and gives the sentence.

### X-9 · minor · Small test gaps
**Answer:** Fixed — T-1 eight rows (AC-7.1 now names both "both" cases); T-8 adds `TestForms`; T-6 names subtests `census_full`, `census_item_on_source`; `FuzzParse(text, form string)`; `printed` signature in D-11.

### X-10 · minor · STEP-4 used types from later steps
**Answer:** Fixed — STEP-3 declares `Target` and `FieldRef`; STEP-4 declares `Ref` and `Span`; `Target.Builtin` holds the bare name.

## Round 2

Maintainability: every round-1 answer checked against the code and resolved; M-5 partly (see M-13). D-2 confirmed not a bend: map § 6.10 already gives supplied as "text; prints in square brackets".

### M-13 · blocker · `notKnobsSection` stays a third doc-section splitter beside `doctable`
**Answer:** Fixed — D-17 adds `doctable.Section`, which `FirstColumn` reads; STEP-9 moves `notKnobsSection` onto it; §4, Codebase fit, Deletes, T-13, DoD sweep and the stop condition updated.
