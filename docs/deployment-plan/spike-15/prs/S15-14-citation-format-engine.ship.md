# Ship log — S15-14 The citation format engine

**Plan:** [`S15-14-citation-format-engine.md`](S15-14-citation-format-engine.md) · **Branch:** `s15-14-citation-format-engine` · **PR:** #868
**State:** ready

## Round 0 — implement
Head `33845b3d5`. Gate PASS (orchestrator run against `4dee2c9f3`). Report deviations: D-4 `formatSide` kept as the compact switch with a separate `citationSide` for the three citation styles (compact output unchanged, `TestCompactDisplay` untouched); `Ref` carries an unexported `fieldSpan` for `RewriteFields`; commits grouped by behavior, not one per step. Fuzz: `FuzzParse` 5 min, no crasher.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. UX: the diff adds error code `valuemark.invalid` in `core/apperr`. SEC+PRF: `core/citationformat` parses and renders format text stored in the catalog (bytes the app did not write), and the diff touches `core/catalogsession` (test only).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, MNT-1 | CON, MNT | blocker | `CitationDisplay` adds a second part-selection path (`citationSide`) beside `formatSide`, the shape D-4 rejected; PR body says no deviation | Fix now → F-1 | verified: `display.go` `formatSide` returns `citationSide(s, st)` before its switch for every non-compact style |
| SEC-1 | SEC/PRF | blocker | `Render` has no output bound; run merging copies quadratically | Fix now → F-2 | verified: `render.go` `add` does `Runs[n-1].Text += text`; reviewer probe 262 MB from a 4 KiB format and a 1 MiB value; `sourcemetadata.normalizeValue` has no length cap. One high total cap per [caps for adversarial-only costs] |
| SEC-2 | SEC | major | `RewriteFields` splices an answer's token without checking it is a valid key or id | Fix now → F-3 | verified: `rewrite.go` checks only both/neither; probe turned `#id` into `x}]*{citation.page` structure |
| MNT-2 | MNT | major | `TestRender`/`TestRequirements`/`TestMissing` read the seed corpus S15-20 deletes (D-16); three readers of one file | Fix now → F-4 | verified: `seedFormat(` in `render_test.go`, `requirements_test.go`; three opens of `seed-formats.txt` |
| MNT-3 | MNT/PRF | minor | Built-in row looked up again (and `Options` cloned) per render and requirement pass | Fix now → F-5 | code this PR adds; `printed`/`collect` call `LookupBuiltin` |
| CON-2 | CON | minor | `docs/citation-formats.md` Diagnostics rows `bad_escape` span and `unprefixed_meta` When narrower than the parser | Fix now → F-6 | verified against `parse.go` `scan` and `option` |
| UX-1 | UX | major | A missing `}` before a later `{` reports `bad_character` over the stretch, not `unclosed_placeholder` | To user → Fix now → F-7 (user, 2026-11-16: change it) | contradicts D-9 ("`{` opens a placeholder that runs to the next `}`") and T-4's row `{{source.title}` → `bad_character` |
| UX-2 | UX | minor | `bad_character` spans the whole option, not the offending character | To user → Fix now → F-8 (user, 2026-11-16: narrow it) | contradicts the plan's codes table (`bad_character` span: "The option") |
| UX-3 | UX | minor | `valuemark.invalid` has no Swift message | Later PR | already in S15-37's map scope entry, **Errors** line ("Maps S15-14's `valuemark.invalid` in `L10n.Errors`"); plan Out row agrees |
| MNT-4 | MNT | minor | `Ref` exported but unreachable through the exported API | Rejected | D-6 and the plan's file table name `Ref` as an exported type |

Nits (logged): `UX-4 · core/citationformat/builtins.go:30,34 · say "n.d."/"unpaginated" are not localized, as Dates does` · `MNT-5 · parse.go:197 · len(p.stack)-1+1 → len(p.stack)` · `MNT-6 · display.go:48-52 · three identical citation rows of qualifierWords` · `MNT-7 · datevalue.go:2-4 · package comment line width` · `CON-3 · parse_test.go · a too_deep row mixing groups and italic` · `CON-4 · add-date-value/SKILL.md:76 · the CitationDisplay line went mid-paragraph, not one line`

### Fix plan 1

**F-1 — One part selection for every date style, as D-4 says** (from CON-1, MNT-1)
Files: `core/datevalue/display.go`, `core/datevalue/display_test.go`. Skill: `add-date-value`.
Failing test first: none (structural; output already right). `TestCompactDisplay` and `TestCitationDisplay` stay green unchanged.
Do: delete `citationSide`. One function decides which parts print for any style, e.g. `printedParts(s side, st displayStyle) (year, month, day *int, clock bool)`, with the three style gates D-4 names: a day with no month is dropped unless compact; the clock prints only for compact; `styleCitationYear` keeps the year alone. One month-validity rule shared by both styles (an out-of-range month must keep printing as it does today in compact — `CompactDisplay` output stays byte for byte the same). Then one writer per style for the words: ISO digits for compact, day + month name (long or short) + year for citation. Make the `formatSide` doc comment true. Fold MNT-6 (the identical citation rows of `qualifierWords`) only if it falls out naturally. Correct the PR body: drop "None from Decisions"; D-4 is now done as written, so remove the D-4 deviation from the plan's Landed note.
Check: `rg -n "citationSide" core` prints nothing; both display tests pass; check-pr PASS.

**F-2 — One total bound on what `Render` produces, and a linear merge** (from SEC-1)
Files: `core/citationformat/render.go`, `render_test.go`, `fuzz_test.go`, `docs/citation-formats.md`, the plan's Security "Untrusted size" line.
Failing test first: `TestRender/over_cap` — `strings.Repeat("{source.title}", 250)` with a resolver returning a 1 MiB value must produce at most `MaxRenderedBytes` of text (today ~262 MB).
Do: add exported `MaxRenderedBytes` (one high cap: 64 KiB, far above the longest seeded format filled with real values) beside `MaxFormatBytes`. `Render` checks the running total before each copy and stops adding text once the cap is reached (truncate the value that crosses it; add nothing after). Apply the same per-value bound in `printed` so `Missing`/requirements never copy an unbounded value. Build each run's text without `+=` on the growing string (collect pieces or a `strings.Builder` per run, joined once), and do not re-copy a group's runs per nesting level more than once. Give `FuzzParse`'s resolver a value large enough to hit the cap on a short format. One line in `docs/citation-formats.md` stating the cap. Fix the plan's "copied once into runs" sentence to describe the cap (note it in the Landed note).
Check: `TestRender/over_cap` passes in well under a second; fuzz 60 s no crasher; check-pr PASS.

**F-3 — `RewriteFields` refuses an answer that is not a valid token** (from SEC-2)
Files: `core/citationformat/rewrite.go`, `rewrite_test.go`, `fuzz_test.go`.
Failing test first: `TestRewriteFields/invalid_key_answer` — rewrite `[{source.meta.#<id>}, ]{source.title}` with answer `FieldRef{Key: "x}]*{citation.page"}` → `ErrFieldRef`, empty text (today returns the spliced string, nil).
Do: check every answer with the existing `parseField(a.Token())` (the D-9 key/id rule; do not write a second validator) and return `ErrFieldRef` when it fails. Update the `RewriteFields` doc comment and the D-14 sentence in the Landed note ("or an answer that is not a valid key or id").
Check: the test passes; check-pr PASS.

**F-4 — Render and requirement tests stop reading the seed corpus; one reader of it** (from MNT-2)
Files: `core/citationformat/render_test.go`, `requirements_test.go`, `parse_test.go`, `fuzz_test.go`.
Failing test first: none (test structure).
Do: put the census full and short formats into package-level test constants (e.g. `censusFull`, `censusShort`) and use them in `TestRender`, `TestRequirements`, `TestMissing`; delete `seedFormat`. One helper reads `testdata/seed-formats.txt` (form, text pairs), used by both `TestSeedFormatsParse` and `FuzzParse`.
Check: `rg -n "seed-formats" core/citationformat` prints exactly one line (the helper); `rg -n "seedFormat\(" core/citationformat` prints nothing; check-pr PASS.

**F-5 — Keep the built-in row resolved at parse time** (from MNT-3)
Files: `core/citationformat/parse.go`, `render.go`, `requirements.go`.
Do: `option` already finds the `Builtin` row via `LookupBuiltin`; keep it (or its index into `builtins`) as an unexported field on `Ref` so `Target` stays comparable. `printed` and `collect` read it instead of calling `LookupBuiltin` (which clones `Options`) again.
Check: `rg -n "LookupBuiltin\(" core/citationformat --glob '!*_test.go'` prints only the parse-time call and the exported definition; check-pr PASS.

**F-6 — Diagnostics table matches the parser** (from CON-2)
Files: `docs/citation-formats.md`.
Do: `bad_escape` span → "The `\` and the character after it, or the `\` alone when last"; `unprefixed_meta` When → "An option whose first part is `meta`".
Check: `TestDocMatchesEngine` and plan-docs pass.

**F-7 — A `{` before the next `}` is an unclosed placeholder** (from UX-1; user decision 2026-11-16 amends D-9 and T-4)
Files: `core/citationformat/parse.go`, `parse_test.go`, `docs/citation-formats.md`, the plan (D-9, the codes table row, the T-4 row, Landed note citing the user's decision).
Failing test first: `TestParse/missing_close_before_next_placeholder` — `{source.title, p. {citation.page}.` → `unclosed_placeholder` at 0–1, and the later `{citation.page}` still parses (no other diagnostic). Change the T-4 row `{{source.title}` to expect `unclosed_placeholder` at 0–1 only.
Do: in `scan`'s `'{'` case use `strings.IndexAny(text[i+1:], "{}")`; when a `{` comes first, report `unclosed_placeholder` at `i` and resume scanning at that `{`; when neither is found, behave as today (report and stop). D-9 text becomes "`{` opens a placeholder that runs to the next `}`; a `{` met first leaves it unclosed". Codes-table and doc "When": "A `{` with no `}` before the next `{` or the end".
Check: the tests pass; fuzz 60 s no crasher; check-pr PASS.

**F-8 — `bad_character` spans the first offending character** (from UX-2; user decision 2026-11-16 amends the codes table)
Files: `core/citationformat/parse.go`, `parse_test.go`, `docs/citation-formats.md`, the plan's codes table row.
Failing test first: `TestParse/bad_character_trailing_space` — `{source.title }` → `bad_character` at 13–14 (today 1–14); update `{source.meta.a b}` and any other `bad_character` row spans.
Do: `k := strings.IndexAny(opt, " \\{[]*")`, span `start+k` to `start+k+1`. Span column: "The first space, `\`, `{`, `[`, `]` or `*` in the option".
Check: the tests pass; `TestDocMatchesEngine` passes; check-pr PASS.

Riding along (nits, optional, only in files already touched): MNT-5, CON-3, CON-4, UX-4.

## Round 1 — fix
Head `8068c2eec`. Gate PASS (orchestrator run against `4dee2c9f3`). F-1 – F-8 done, each new test red before its fix. Nits taken: MNT-5, CON-3; skipped MNT-6, CON-4, UX-4. Report deviations: commits grouped by behavior (the F-2 commit alone does not build; head does); `ErrFieldRef` message now "exactly one valid key or id"; `FuzzParse` also checks rewrite re-parse and the render cap (60 s, no crasher). Plan amended in `8068c2eec` (D-9, codes table, T-4, D-14, Untrusted size, Landed note) per the user's decision.

## Round 2 — review
Reviewers: CON (CON-1), MNT (MNT-1, MNT-2), SEC+PRF (SEC-1, SEC-2), UX (UX-1) — each had a Fix-now blocker or major. Scope `33845b3d5...8068c2eec`.

Round-1 status: CON-1/MNT-1 Resolved (`printedParts`; `rg citationSide core` empty). SEC-1 Resolved (probe: 1 MiB × 250 → 65,536 bytes in 152 µs). SEC-2 Resolved (`parseField(a.Token())`). MNT-2 Resolved (one `seedFormats` reader; `censusFull`/`censusShort`). UX-1 Resolved (F-7 rows). Minors riding (orchestrator/reviewers read): MNT-3 Resolved (`Ref.row`, `builtinRow`) but see CON-5; CON-2 Resolved; UX-2 Resolved (13–14 span). PR body still says "None from Decisions" and names `citationSide` — orchestrator fixes in step 8.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-5 (also SEC+PRF "not raised") | CON | blocker | `Missing` panics `index out of range [-1]` on a built-in target not in the table, a regression from F-5 | Fix now → F-9 | verified: `requirements.go:84` `ref.row, _ = builtinRow(...)` drops `ok`; `printed` indexes `builtins[r.row]`. SEC+PRF rated it below blocker as no catalog reaches it; kept at blocker — a panic in an exported function this PR adds, introduced by the fix round ("nothing calls it yet" does not rate down) |
| SEC+PRF outside-lens | CON | minor | `docs/citation-formats.md` Diagnostics intro still says scanning stops after `unclosed_placeholder` | Fix now → F-9 (rides) | verified line 59; F-7 resumes at the inner `{` |

### Fix plan 2

**F-9 — `Missing` never panics on a built-in that is not in the table** (from CON-5; doc line rides)
Files: `core/citationformat/requirements.go`, `render.go`, `requirements_test.go`, `docs/citation-formats.md`.
Failing test first: `TestMissing/unknown_builtin_target` — `Missing([]Requirement{{Targets: []Target{{Level: vocabkey.LevelSource, Builtin: "nope"}}, Need: NeedNeeded}}, r)` returns that requirement as missing, no panic (today: `index out of range [-1]`). Add a second row for a real built-in at the wrong level (`{Level: LevelArtifact, Builtin: "date"}`).
Do: in `Missing`, when `builtinRow` returns `!ok`, count the target as unanswered without calling `resolve` (the round-0 behavior). Also make `printed` refuse `r.row < 0` (treat as unanswered) so no `Ref` built outside `Parse` can index out of range. Doc: the Diagnostics intro says `unclosed_placeholder` stops scanning only when no `{` or `}` follows; before a later `{` scanning resumes there.
Check: the test passes; `FuzzParse` 30 s no crasher; check-pr PASS.

## Round 2 — fix
Head `1c192b0f9`. Gate PASS. F-9 done: `TestMissing/unknown_builtin_target` panicked `index out of range [-1]` before the fix; both new subtests pass. Orchestrator read the diff: `Missing` returns unanswered on `!ok`; `printed` guards `r.row` range. Merged `origin/main` (`3a2a2816c`, #867); gate PASS against it.

## Result
Gate PASS · CI see PR · open: none · follow-ups: none · to user: UX-1, UX-2 (answered 2026-11-16: change both) · later PR: UX-3 (S15-37 Errors line) · rejected: MNT-4
