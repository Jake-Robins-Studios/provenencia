# S15-14 — The citation format engine

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: three pure Go packages that nothing in the app calls yet; every view looks the same)
**Board:** —
**Depends on:** S15-06 (landed [#782](https://github.com/mendahu/provenencia/pull/782))
**Blocks:** S15-15, S15-37, S15-38, S15-43, S15-44
**Branch:** `s15-14-citation-format-engine`
**Version bump:** none — new engine packages with no caller, no wire and no catalog change; nothing a researcher can see ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests; a fuzz target for a parser of bytes the app did not write), `.cursor/rules/date-values.mdc`
**Context:** working rules "Follow the *Evidence Explained* style; never copy the book", "One level type", "Citation formats are data on the Source type", "Every placeholder names its level; fallback is written", "A format's fields are needed or used", "A value can be marked unknown or supplied", "Dates in citations use citation terms", "No transforms on metadata", "Formats name fields by id", "One engine, in Go", "Built-in placeholders are one table" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../README.md`](../README.md#working-rules); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) §§ 2, 6.3, 6.8 "Formats", 6.10; map review K3-3 ([`../deployment-plan.review.md`](../deployment-plan.review.md))
**Planned:** 2026-11-16 against `main` @ `eb7ee08` (compare with `origin/main` after `git fetch origin main`; a local `main` may be stale)
**Review:** [`S15-14-citation-format-engine.review.md`](S15-14-citation-format-engine.review.md) — Fits / Ready, 2 rounds; every blocker Fixed; nothing to the user

### Implementer — read this first

1. **This file is the whole task.** Read it top to bottom before you change code. Then read every file under **Current state** and load every skill under **Skills to load**.
2. **Check the base.** Compare `main` with the **Planned** commit. If a file under **Current state** has changed so a row is no longer true, stop and report which rows.
3. **Decisions are made.** Do not reopen a **Decision** or a **Scope** line, and do not swap in a design you like better. If one cannot work, stop: say which ID it is, what you found (path, line, output), and what you would need. Do not improvise around it.
4. **Do only In.** Out stays out, even when it is one line away. Do not refactor, rename, or tidy code the plan does not name.
5. **Work the Steps in order.** Run each step's check before you start the next. A failing check is fixed in that step.
6. **Hit a Stop condition → stop.** Report it. Do not work around it.
7. **Done is the Definition of done.** Report each box with its evidence: the command and its result, the test name, or the manual check you ran.
8. **Docs-only lines in the DoD are part of the PR.** Do not skip them.

---

## 1. Objective

A Source type's citation formats (full note, short note, source-list entry) are text in a small syntax of our own (map § 6.3). This PR builds the one engine that reads that syntax, in Go and with no database: it parses a format into a tree with positioned diagnostics, renders it through a resolver into italic and plain runs, derives which fields each format needs or uses, says which needed ones are missing, prints marked-unknown and supplied values, writes dates in citation terms through `core/datevalue`, declares the built-in placeholders once, and rewrites a format's field references between keys and ids. It also adds `core/valuemark`, the one unknown-and-supplied type the later stores share.

**Why now.** Every later PR of slices 4, 5, 6 and 9 that touches a format builds on it: S15-15 stores formats (key↔id rewrite, list-form rule, diagnostics), S15-16 renders Citations (resolver, runs, built-ins), S15-38 annotates boards (requirements), and S15-37, S15-43 and S15-44 store marks (`valuemark`). The rules it implements are settled in the map.

**What stays.** No table, RPC, Swift file or screen changes. The app keeps showing today's citation line (`CitationLineDisplay`). `datevalue.CompactDisplay`'s output and every date the app's pages show are unchanged.

## 2. User stories

**US-1.** As the engine, when I parse a format, I get its tree or every diagnostic with its byte position, so the editor (S15-17) can point at the mistake and storage (S15-15) can refuse it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Each of the 66 formats of map § 6.8 "Formats", parsed in its form | No diagnostic |
| AC-1.2 | `{meta.page}` (full) | One diagnostic `unprefixed_meta` spanning `meta.page` (bytes 1–10) |
| AC-1.3 | `p. [{citation.page}` (full) | One diagnostic `unclosed_group` at the `[` (bytes 3–4) |
| AC-1.4 | `{source.title}]` (full) | One diagnostic `stray_close_bracket` at bytes 14–15 |
| AC-1.5 | `{graph.meta.line_number}` in the list form | One diagnostic `not_in_list_form` spanning `graph.meta.line_number` (bytes 1–23) |
| AC-1.6 | `{source.date:week}` · `{source.title:year}` · `{source.meta.url:year}` (full) | Each one diagnostic `unknown_option` spanning the text after `:` |
| AC-1.7 | `[, ]{source.title}` (full) | One diagnostic `group_without_placeholder` at bytes 0–4 |
| AC-1.8 | `{source.foo} and {citation.meta.x} and {parish.title}` (full) | Three diagnostics in order: `unknown_builtin`, `meta_not_at_level`, `unknown_level` |
| AC-1.9 | A format of 4,097 bytes | One diagnostic `too_long` at 0–4097; nothing else is scanned |

**US-2.** As the engine, when I render a parsed format through a resolver, I get styled runs and plain text in which values print exactly as typed.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The census full format (map § 6.8) with the values of T-6 spread over Source, Artifact, graph and Citation | Plain text: `1880 U.S. census, Ottawa County, Kansas, population schedule, ED 236, p. 14, dwelling 112, family 118, Ada Robins; digital image, Ancestry (https://www.ancestry.com : accessed 12 March 2025); citing NARA microfilm publication T9, roll 393.` with one italic run, `Ancestry` |
| AC-2.2 | `[, ED {source.meta.enumeration_district}]` with no ED value | Prints nothing |
| AC-2.3 | `[ ({artifact.meta.url}[ : accessed {artifact.meta.accessed_date}])]` with URL `https://example.org/1` and no accessed date | ` (https://example.org/1)` |
| AC-2.4 | `{source.title}` where the title is `*Kansas* [draft]` | Prints `*Kansas* [draft]`, not italic |
| AC-2.5 | `\{a\} \[b\] \*c\* \\` | Prints `{a} [b] *c* \` |
| AC-2.6 | `{graph.meta.line_number|source.meta.line_number}` with the graph empty and the Source `12` | `12` |

**US-3.** As the engine, a value marked unknown or supplied prints the way citation style marks it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `{source.meta.publication_place}: {source.meta.publisher}` with both marked unknown and unknown text `n.p.` | `n.p.: n.p.` |
| AC-3.2 | `{source.meta.publication_place}` supplied `Topeka` | `[Topeka]` |
| AC-3.3 | `{source.date}` supplied, ABT 1880 | `[ca. 1880]` |
| AC-3.4 | `{source.date}` marked unknown · `{citation.page}` marked unknown | `n.d.` · `unpaginated` |
| AC-3.5 | `[, {source.meta.edition}]` marked unknown with no unknown text | Prints nothing (the group drops); `Missing` does not list it |
| AC-3.6 | `{graph.meta.line_number|source.meta.line_number}` with the graph marked unknown (no unknown text) and the Source `12` | Prints nothing: the graph's answer wins |
| AC-3.7 | `*{artifact.meta.provider}*` supplied `Ancestry` | One italic run `[Ancestry]` |

**US-4.** As the engine, I derive a type's requirements from its formats and say which needed ones are missing.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Census full: `{source.meta.jurisdiction}` outside any group | One requirement, needed, targets `[source.meta.jurisdiction]` |
| AC-4.2 | Census full: `[, line {graph.meta.line_number|source.meta.line_number}]` | One requirement, used, targets `[graph.meta.line_number, source.meta.line_number]` |
| AC-4.3 | `{source.meta.short_title|source.title}` outside any group | One requirement, used (its chain holds an always-set built-in) |
| AC-4.4 | `Missing` over the census full and short formats with every value empty except the date | Exactly one requirement: `source.meta.jurisdiction` (both formats need it) |
| AC-4.5 | A chain needed in the short form and used in the full | One requirement, needed |
| AC-4.6 | `{source.date:year}` in full and `{source.date}` in list; the date is month-only (March) | One requirement for `source.date`, needed; `Missing` does not list it, whichever template comes first |

**US-5.** As the engine, I write a DateValue in citation terms.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | 3 March 1830, long / short | `3 March 1830` / `3 Mar. 1830` |
| AC-5.2 | ABT 1880 · BEF 3 March 1830 · AFT 1880 | `ca. 1880` · `bef. 3 March 1830` · `aft. 1880` |
| AC-5.3 | Range 1878 to 1882 | `1878–1882` (en dash) |
| AC-5.4 | Year style on 3 March 1830 | `1830` |
| AC-5.5 | Phrase-only `Christmas` · 1882 with phrase `Christmas` | `Christmas` · `1882` |

**US-6.** As the engine, I rewrite a format's field references between keys and ids, leaving every other byte as typed.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-6.1 | `{graph.meta.line_number|source.meta.line_number}` rewritten key → id → key | The original text, byte for byte |
| AC-6.2 | `{source.meta.url}` with `url` → id `0192f3a4-0000-7000-8000-000000000001` | `{source.meta.#0192f3a4-0000-7000-8000-000000000001}` |
| AC-6.3 | `{source.meta.#not-a-uuid}` · `{source.meta.#00000000-0000-0000-0000-000000000000}` · `{source.meta.#0192F3A4-0000-7000-8000-000000000001}` | `bad_field` each |

**US-7.** As a store (S15-37, S15-43, S15-44), I check a value's unknown and supplied facts with one rule.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-7.1 | Unknown with a value · supplied without a value · both with a value · both without | `valuemark.ErrInvalid` each |
| AC-7.2 | Unknown without a value · supplied with a value · neither with a value · neither without | `nil` each |

## 3. Scope

| In | Covered by |
| --- | --- |
| `core/valuemark`: `Mark`, `Validate`, `ErrInvalid` (`valuemark.invalid`); a purity-guard row | STEP-1, AC-7.1, AC-7.2 |
| `datevalue.CitationDisplay` and `CitationStyle`, on one shared end formatter with `CompactDisplay` | STEP-2, AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5 |
| `core/citationformat`: `Form`, `Option`, `Target`, the built-ins table; a purity-guard row | STEP-3, AC-1.6, AC-1.8 |
| `Parse` to a `Template` with diagnostics and positions (every code in the codes table), the list-form rule, limits | STEP-4, AC-1.1 – AC-1.9 |
| `Render` through a `Resolver` to runs and plain text, with marks and citation dates | STEP-5, AC-2.1 – AC-2.6, AC-3.1 – AC-3.7 |
| `Requirements` and `Missing` | STEP-6, AC-4.1 – AC-4.6 |
| The field-id token, `Fields` and `RewriteFields` | STEP-7, AC-6.1, AC-6.2, AC-6.3 |
| `FuzzParse` and the seed-format corpus | STEP-8, AC-1.1 |
| One doc-section test helper, `core/internal/doctable`, used by the existing doc-parity readers and this PR's | STEP-9 |
| `docs/citation-formats.md` *(new)* with a parity test; link from `source-layer-data-model.md`; `add-date-value` and `date-values.mdc` name `CitationDisplay` | STEP-10 |

| Out | Home |
| --- | --- |
| Format columns on `source_types`, key → id resolution against the catalog, delete-impact probe, type RPCs | S15-15 |
| The catalog resolver, the batch render RPC, the preview request, the built-ins over FFI, the group key | S15-16 |
| Swift parity rows for `Form`, `Option`, `DiagnosticCode` and the built-in names in `api/ffi/swift_vocabulary_test.go` | S15-16 (the first PR that sends them over FFI) |
| L10n copy for `valuemark.invalid` · for each diagnostic code | S15-37 · S15-17 |
| `is_unknown`, `is_supplied`, `unknown_text` storage and the proto `ValueMark` | S15-37 |
| The Source date's marks · the page's marks | S15-43 · S15-44 |
| Board annotations, "met at another level" | S15-38 |
| Seeding the formats; deleting this PR's seed corpus and `TestSeedFormatsParse` | S15-20 |
| Calendar marks (O.S., N.S., dual dating) and times of day in a citation date | not planned |
| Any whitespace or punctuation clean-up after an empty needed placeholder | not planned (rule "No transforms on metadata"; groups are the mechanism) |
| A diagnostic for options after an always-set built-in in a chain | not planned |
| Retiring the spike's design note `docs/deployment-plan/spike-15/citation-formats.md` | S15-99 |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Level type | `core/vocabkey/vocabkey.go` `Level`, `Levels`, `MetadataLevels`, `Valid`, `HoldsMetadata` | Four levels, `citation` holds no metadata. Used as is |
| Date display | `core/datevalue/display.go` `CompactDisplay`, `applyQualifier`, `appendPhrase`, `formatSide` | `formatSide` takes six loose pointers and both chooses which parts print and writes them as ISO digits; `applyQualifier` is the one qualifier-word switch (`About`, `Before`, `After`). No citation style |
| Date type | `core/datevalue/datevalue.go` `Value`, `side`, `Validate`, `KindPoint`, `KindRange`, `QualifierABT` / `BEF` / `AFT`; package comment says "its compact display" | `Validate` builds the two `side` values inline |
| Date tests | `core/datevalue/display_test.go` `TestCompactDisplay`; `core/datevalue/validate_test.go`; `core/datevalue/datevaluetest/datevaluetest.go` `YMD`, `About`, `Before`, `After`, `Part` | Pin `CompactDisplay` and `Validate`; fixture builders this PR's tests reuse |
| Error codes | `core/apperr/apperr.go` `CodeDateValuesInvalid`, `CodeLocatorInvalid`, `New`, `KindUser` | No `valuemark` code. Codes are permanent once shipped |
| Purity guard | `core/matchregistry/guard_test.go` `layerPackages`, `TestLayerPackages` | "A new layer package or pure value package adds a row"; `core/datevalue` and `core/vocabkey` have rows (`false`) |
| Field keys | `core/database/metadatafields/metadatafields.go` `Create` (key from `slug.Kebab`); `core/slug/slug.go` `Kebab` (`unicode.ToLower`, `unicode.IsLetter`, `unicode.IsDigit`, `-`); `core/database/sourcevocab/registry.go` (`document_number`, `record_date`) | User keys are kebab-case; product keys snake_case. No key holds `#`, `.`, `:`, `|`, `{`, `}` or a space |
| Field ids | `metadatafields.Create` mints `uuid.NewV7()`; audit writes `uid.String()` | 16-byte UUIDv7; canonical string is 36 lowercase characters |
| Always-set values | `core/database/sources/sources.go` (`in.Title == ""` refused), `core/database/sourcetypes/sourcetypes.go` (`label == ""` refused), `core/database/artifacts/artifacts.go` (`in.Label == ""` refused), `core/database/evidencegraphs/evidencegraphs.go` (`in.Name == ""` refused) | Source title, type label, Artifact label and graph name are never empty |
| Not always set | `core/database/migrations/000059.sql` (`citations.label TEXT`, nullable); `core/locator/depiction.go` `PageRef`, `Page` | A Citation's label, printed page and file page can be absent |
| Citation line today | `macos/App/Platform/CitationLineDisplay.swift` `CitationLineDisplay` | Stays the fallback (rule "Today's line stays the fallback, in Swift"); untouched |
| Citation engine | — | No template, placeholder or format parser exists in `core/` or `api/` (searched `text/template`, `placeholder`, `func Parse`) |
| Doc-section readers | `core/matchregistry/inventory_test.go` `inventoryKeys` (first backticked span of rows under `## Knob inventory`) and `notKnobsSection` (body under `## Not knobs`); `core/catalogsession/cache_doc_test.go` `TestCacheDocListsEveryEntry` (inline loop over `## Registry entries`) | Three hand-written splitters on `## ` headings, the only `docs/` readers in `*_test.go` |
| Fuzz precedent | `core/raster/jpegdc_test.go` `FuzzDecodeJPEGDC` | `f.Add` seeds; crashers under `testdata/fuzz/<Target>/` |
| Domain docs | `docs/source-layer-data-model.md` § 3 `source_types`; `.agents/skills/add-date-value/SKILL.md` (line 12 "compact display", "Package" tree, "Display (macOS)"); `.cursor/rules/date-values.mdc` first bullet | Name `CompactDisplay` only; no citation-format doc |

**Precedent.** `core/datevalue` (pure value type, its own `ErrInvalid` code passed through by every store, table tests) is the shape for `core/valuemark`: copy its `ErrInvalid` declaration and doc-comment style. `inventoryKeys` is the parsing rule `core/internal/doctable` keeps (first backticked span of the first cell). `FuzzDecodeJPEGDC` is the shape for the fuzz target.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Packages: `core/valuemark` (pure, imports `core/apperr`), `core/citationformat` (pure, imports `core/vocabkey`, `core/datevalue`, `core/valuemark`, `github.com/google/uuid`), and `CitationDisplay` in `core/datevalue`. None imports `core/database`; both new packages get a `layerPackages` row with `numbers: false` (their limits are facts, not tunables) | Rules "One engine, in Go", "A value can be marked unknown or supplied" (`valuemark` stands alone so `locator`, `sourcemetadata` and `sources` use it without importing the engine), "Dates in citations use citation terms"; the guard's own instruction | `Mark` inside `citationformat` — `core/locator` would import the format engine for two booleans |
| D-2 | `valuemark.Mark{Unknown, Supplied bool}`; `func Validate(m Mark, hasValue bool) error` returns `ErrInvalid` when both are set, when `Unknown` and `hasValue`, or when `Supplied` and not `hasValue`; else `nil`. `ErrInvalid = apperr.New(apperr.CodeValueMarkInvalid, apperr.KindUser)`, `CodeValueMarkInvalid = "valuemark.invalid"` *(new)* | The rule: never both; unknown has no text. A supplied fact with nothing supplied says nothing, so it is refused too. Its own code, passed through by stores, as `datevalue.ErrInvalid` is | Each store mapping to its own code — three copies of the rule's error; a method `m.Validate` — the map and S15-37's Check name `valuemark.Validate` |
| D-3 | `type CitationStyle int` with `CitationLong`, `CitationShort`, `CitationYear` *(new)*; `func CitationDisplay(v Value, s CitationStyle) string`. Output: parts in day-month-year order; months spelled out (`CitationLong`) or `Jan.`, `Feb.`, `Mar.`, `Apr.`, `May`, `June`, `July`, `Aug.`, `Sept.`, `Oct.`, `Nov.`, `Dec.` (`CitationShort`); `CitationYear` prints the year alone; qualifier prefix `ca. ` / `bef. ` / `aft. `, kept in every style; a range prints `start–end` (U+2013), and the side once when both print the same; when either side of a range prints empty, or the kind is neither point nor range, the result is the trimmed phrase (as `CompactDisplay` does); a point with no printed part is its trimmed phrase; a point with a printed part ignores its phrase; calendar is ignored; a year prints as the integer (`0`, `-50`); month and day with no year print `3 March`; a day alone prints nothing (then the phrase); `CitationYear` on an end with no year prints nothing for it. The unexported styles are `styleCompact`, `styleCitationLong`, `styleCitationShort`, `styleCitationYear` | Rule "Dates in citations use citation terms"; the map's examples ("ca. 1880", "bef. 3 March 1830", "1878–1882"). One enum: a year-only flag with abbreviated months has no meaning (review M-9). Not a citation `Form`: `datevalue` cannot import `citationformat`, which imports it; the rule's sketch `CitationDisplay(v, form)` names the argument | Two booleans — an impossible pair; extending `CompactDisplay` with a flag — the app's pages keep their style |
| D-4 | One end formatter for both styles in `display.go`. `formatSide` becomes `func formatSide(s side, st displayStyle) string` with an unexported `displayStyle` (`styleCompact` *(new)*, and one per `CitationStyle`): one switch decides which parts print, and the style decides only (a) a day without a month (compact: `1882--03`; citation: dropped), (b) the clock (compact: printed; citation: dropped), (c) the words (ISO digits, month names, abbreviations, year alone). `applyQualifier(qual, point string, st displayStyle)` holds one table of qualifier words keyed by style (`About`/`Before`/`After`; `ca.`/`bef.`/`aft.`). `func (v Value) startSide() side` and `endSide() side` *(new)* in `datevalue.go` are the one way to read an end; `Validate`, `CompactDisplay` and `CitationDisplay` all use them | Map rule: `CitationDisplay` shares `formatSide`'s precision handling; the K3-3 answer ("one package turns a DateValue into text"). One place changes when precision rules change (review M-1) | A second switch and a second qualifier table beside the first — two formatters in one package |
| D-5 | `type Form string` (`FormFull = "full"`, `FormShort = "short"`, `FormList = "list"`), `Forms()` (new slice, that order), `(f Form) Valid() bool`. `type Option string` (`OptionYear = "year"`, `OptionFull = "full"`). Date style: `:year` → `CitationYear`; otherwise `FormShort` → `CitationShort`, else `CitationLong` | The three forms of map § 6.3 and the two date options, as typed keys like `vocabkey.Level` (review M-6) | Strings — a renamed option would silently print nothing |
| D-6 | `type Target struct{ Level vocabkey.Level; Builtin string; Field FieldRef }` is what a placeholder option points at: exactly one of `Builtin` (the bare name, `date`) and `Field` is set. It is comparable, and it is the identity requirements, the resolver and S15-16's batch keys use. `Ref{Target; Option Option; Span Span}` is one occurrence in a format (review M-3, M-12) | One definition of identity by Go equality; parse positions stay out of the resolver API | `Ref` alone with "Option and Span ignored" — three hand-rolled identities |
| D-7 | The built-ins table: `type Builtin struct{ Level vocabkey.Level; Name string; Date bool; Options []Option; AlwaysSet bool; UnknownText string }`; `func Builtins() []Builtin` (new slice); `func LookupBuiltin(l vocabkey.Level, name string) (Builtin, bool)`; `func ListFormAllows(l vocabkey.Level) bool` (Source only) for built-ins and metadata alike, and `func (b Builtin) InListForm() bool` returns `ListFormAllows(b.Level)` (review M-7). Rows in order: `source.title` (always set), `source.type` (always set), `source.date` (date, options `year`, `full`, unknown text `n.d.`), `artifact.label` (always set), `graph.name` (always set), `citation.page` (unknown text `unpaginated`), `citation.image`, `citation.label` | Rule "Built-in placeholders are one table" (name, level, allowed in the list form, options); map § 6.3; always-set from § 4's write checks; unknown texts from the rule "A value can be marked unknown or supplied" | A per-row `InListForm` field — it would repeat the level and could disagree with the metadata rule; `citation.label` always set — `citations.label` is nullable |
| D-8 | `func Parse(text string, form Form) (*Template, []Diagnostic)`. A non-nil template comes back only with zero diagnostics. `Diagnostic{Code DiagnosticCode; Span Span}`; `Span{Start, End int}` in UTF-8 byte offsets of `text`, half-open. `DiagnosticCodes()` lists the codes of the codes table below, in its order. Diagnostics come back sorted by `Span.Start`, ties in the order found (stable sort). When scanning stops, nothing after it is reported, and groups and italic spans still open are not reported. Each option yields at most one diagnostic: the first that applies in the table's order from `empty_option` down | Rule "One render request for previews" (diagnostics with positions). Byte offsets are Go's native index; S15-17 converts with Swift's `utf8` view, which is not parsing. Typed codes so S15-16 can add a Swift parity row | Rune or UTF-16 offsets — a second index in Go that only Swift needs; returning an `error` — the editor needs all of them |
| D-9 | Grammar. Outside a placeholder: `\` escapes exactly `\ { } [ ] *`; `{` opens a placeholder that runs to the next `}`; `[` opens a group and `]` closes the innermost; `*` opens italic and the next `*` in the same group closes it; `|` and everything else are literal. Inside a placeholder there are no escapes; options split on `|`. An option is `level.meta.field[:option]` or `level.name[:option]`; the text after its first `:` is the option. A key is one or more characters each `unicode.IsLetter`, `unicode.IsDigit`, `_` or `-` (every `slug.Kebab` output and every snake_case product key); an id is `#` plus a string `s` with `uuid.Parse(s)` succeeding, `id != uuid.Nil` and `id.String() == s`. A group's own placeholders exclude those in nested groups; italic is transparent. Limits: `MaxFormatBytes = 4096`, `MaxDepth = 8` open groups and italic spans together | Map § 6.3 "The syntax"; `\}` and `\]` join the map's escapes so every special has a literal form. 66 of 66 map § 6.8 formats pass (checked while planning and again by review: longest 691 bytes, deepest 2 groups, every group has a placeholder of its own). Limits bound work on text the app did not write before it is done | Trimming spaces inside braces — two spellings of one placeholder; a group whose only placeholders are nested — no seeded format has one, and its drop rule would need a second rule |
| D-10 | Group rule: a group prints when every placeholder of its own prints non-empty text; otherwise it and everything inside it, nested groups included, print nothing. A nested group decides for itself only when its parent prints | Map § 6.3: a group is removed entirely if a placeholder inside it is empty, and groups nest; the census URL group needs its inner accessed-date group to drop alone | Counting nested placeholders as the parent's — the URL would drop whenever the accessed date is empty |
| D-11 | `Resolver` is `interface{ Resolve(t Target) Value }`; `Value{Text string; Date *datevalue.Value; Mark valuemark.Mark; UnknownText string}`. A date built-in reads `Value.Date` only; every other target reads `Value.Text` only. One unexported `func printed(r Ref, v Value, form Form) (text string, answered bool)` serves `Render` and `Missing`: unknown → answered, text is the built-in row's `UnknownText` for a built-in or `Value.UnknownText` for metadata (unknown wins if a resolver sends both marks); otherwise the text (a date's is `CitationDisplay` in D-5's style) is answered when `strings.TrimSpace` of it is non-empty, and prints as given, wrapped in `[` and `]` when supplied. A chain prints its first answered option, in order; none answered prints nothing | Rules "Every placeholder names its level; fallback is written" (COALESCE), "A value can be marked unknown or supplied", "No transforms on metadata". An unknown answer at the graph is the item's answer, so the chain stops there (AC-3.6). `Resolve` has no error: S15-16 loads values in batches first | Skipping an unknown option in a chain — a graph marked "line not given" would print the Source's line for it |
| D-12 | `func Render(t *Template, r Resolver) Rendered`; `Rendered{Runs []Run}`, `Run{Text string; Italic bool}`, `func (r Rendered) Plain() string`. Values go in as literal text after parsing. Adjacent runs of one style merge; empty runs are dropped. A supplied value's brackets take the value's style. A nil or empty template renders no runs | Rule "One engine, in Go" (values never format); map § 6.3 "The engine" (styled runs; the caller builds rich text) | A missing list from `Render` — rule "A format's fields are needed or used": the batch render has none |
| D-13 | `type Need string` (`NeedNeeded = "needed"`, `NeedUsed = "used"`); `Requirement{Targets []Target; Need Need}`; `func Requirements(ts ...*Template) []Requirement` (nil templates skipped). A placeholder outside every group is needed; inside any group, used; a chain holding an always-set built-in is used. One requirement per distinct `[]Target` sequence (compared with `slices.Equal`; options kept as written, a repeated option included; a field named by key and by id is two targets — S15-15 stores ids only), in order of first appearance; needed in any template makes it needed. `func Missing(reqs []Requirement, r Resolver) []Requirement` returns the needed requirements with no answered target, in input order, testing each target with `printed` at `FormFull` and no option (the most a date can print) | Rule "A format's fields are needed or used"; map § 6.3: a built-in in a chain whose last option always has a value is never needed — it is used, since its first option still shapes the citation. No option in `Missing` so the answer does not depend on which template came first (AC-4.6, review M-3) | Per-form requirement lists — S15-38 annotates from all three at once; used ones in `Missing` — an empty used field drops its group cleanly |
| D-14 | `FieldRef{Key string; ID uuid.UUID}`, exactly one set; `(f FieldRef) ByID() bool` is `f.ID != uuid.Nil`; `(f FieldRef) Token() string` is the key, or `#` + `ID.String()`. `(t *Template) Fields() []FieldRef`: distinct refs in order of first appearance. `(t *Template) RewriteFields(to func(FieldRef) (FieldRef, error)) (string, error)` calls `to` once per distinct field, in `Fields()` order, and replaces only each occurrence's bytes with the token of its answer; it returns the first error in that order that `to` returns, or `ErrFieldRef` *(new, `errors.New`)* when an answer has both or neither set; on error the string is empty | Rule "Formats name fields by id": one stored token, one rewrite. `#` cannot occur in a key, so a token is never a key. Span replacement keeps the researcher's spacing and escapes through key → id → key | Re-printing the tree — it would rewrite what the researcher typed; a raw 32-hex token — audit and logs use the canonical form |
| D-15 | The tree is unexported. `Template` exports `Form()`, `Text()`, `Fields()`, `RewriteFields`; callers use `Render`, `Requirements` and `Missing`. On a nil `*Template`, `Text` is `""`, `Fields` is nil and `RewriteFields` returns `""` and nil. A nil `Resolver` answers nothing: every target is unanswered | Every caller the map names is served by these | Exported node types — nothing outside the package walks the tree |
| D-16 | Tests live in `package citationformat_test`, table-driven. `core/citationformat/testdata/seed-formats.txt` *(new)* holds the 66 map § 6.8 formats, one per line as `form<TAB>text`, each wrapped format joined with nothing between its lines; `TestSeedFormatsParse` parses them; `FuzzParse(f, text string, form string)` seeds from it and from the T-4 inputs, which live in a package-level `parseCases` var shared with `TestParse`. S15-20 deletes the file and `TestSeedFormatsParse` once its registry render test proves AC-1.1; `FuzzParse` then keeps the T-4 seeds and `testdata/fuzz/FuzzParse/` (review M-4) | `go-tests.mdc` (fuzz target; seeds from `testdata/`); one hand-off so the seed formats have one home after S15-20 | Seeds only in code — the rule asks for `testdata/` |
| D-17 | `core/internal/doctable` *(new)*: `func Section(t testing.TB, path, section string) string` returns the text under the `## <section>` heading up to the next `## ` heading, and fails the test when the heading is missing or the section is empty; `func FirstColumn(t testing.TB, path, section string) []string` reads `Section` and returns the first backticked span of the first cell of each table row, failing when there is none. `inventoryKeys`, `notKnobsSection` and the loop in `TestCacheDocListsEveryEntry` move onto them; `TestDocMatchesEngine` *(new)* uses `FirstColumn` twice (review M-5, M-13) | This PR would add a fourth copy of the heading splitter | A fourth copy; a helper that leaves `notKnobsSection` beside it |
| D-18 | `docs/citation-formats.md` *(new)*, the domain doc, has sections `## Forms`, `## Syntax`, `## Built-in placeholders` (columns: `level.name` in backticks, Value, Options, Unknown text), `## Needed and used`, `## Unknown and supplied`, `## Dates`, `## Diagnostics` (columns: the code in backticks, When, Span). `TestDocMatchesEngine` checks each named table's first column holds the same set as `Builtins()` and `DiagnosticCodes()`. `docs/source-layer-data-model.md` § 3 gains, at the end of its first paragraph, the sentence "A Source type's citation formats are written in the syntax of citation-formats.md.", with the file name linked to `docs/citation-formats.md` *(new)*. | The scope entry ("Writes the syntax as a domain doc"); a doc table beside a registry drifts without a check | Generating the doc from Go — no doc generator exists |

**Diagnostic codes** (D-8; spans in bytes; "stops" means scanning ends there):

| Code | When | Span |
| --- | --- | --- |
| `unknown_form` | `form` is not in `Forms()`; stops | 0–0 |
| `too_long` | `len(text) > MaxFormatBytes`; stops | 0–len |
| `too_deep` | Opening a group or italic span makes `MaxDepth + 1` open; stops | That `[` or `*` |
| `unclosed_placeholder` | `{` with no `}` after it; stops | That `{` alone |
| `stray_close_brace` | `}` outside a placeholder | That `}` |
| `unclosed_group` | A `[` still open at the end of the text | That `[` |
| `stray_close_bracket` | `]` with no open group | That `]` |
| `unclosed_italic` | A `*` still open when its group closes or the text ends | That `*` |
| `bad_escape` | `\` followed by another character, or last | The `\` and the rune after it, or the `\` alone |
| `group_without_placeholder` | A closed group with no placeholder of its own | `[` through `]` |
| `empty_option` | An empty option (`{}`, `{source.title|}`) | Zero width at its place |
| `bad_character` | An option holding a space, `\`, `{`, `[`, `]` or `*` | The option |
| `unprefixed_meta` | An option whose first part is `meta` | The option |
| `unknown_level` | Any other first part not `vocabkey.Level(x).Valid()`, including an option with no `.` (`{title}`) | The option |
| `meta_not_at_level` | `level.meta` at a level that does not `HoldsMetadata` | The option |
| `bad_field` | `level.meta` with no field, or a field that is neither a key nor an id (D-9) | The text after `meta.` (zero width when none) |
| `unknown_builtin` | A name not in the built-ins table at that level, including empty (`{source}`, `{source.}`) | The option |
| `unknown_option` | An option on metadata, or one not in the row's `Options`, including empty (`{source.title:}`) and `year:full` | The text after the first `:` |
| `not_in_list_form` | In `FormList`, `!ListFormAllows(level)` | The option |

**Rules this plan bends.** None. D-3's enum is the argument the rule's sketch calls `form` (import direction), and STEP-10 updates the sketch in the rule and map § 6.3 to match; D-2's "supplied needs a value" is map § 6.10's "Supplied (text; prints in square brackets)"; D-7 keeps the rule's per-row "allowed in the list form" as `InListForm()`. All three are under **Writer's own calls** in the review log for the user to veto.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/valuemark` *(new)* | package | `core/datevalue` (pure value + `Validate`) | A mark sits beside text, dates and pages; it is not a date |
| `apperr.CodeValueMarkInvalid` *(new)* | error code | `CodeDateValuesInvalid` | One code per pure value package |
| `datevalue.CitationDisplay`, `CitationStyle` *(new)* | func, type | `CompactDisplay`, `formatSide`, `applyQualifier` | Extended: the citation style is a case of the one end formatter and qualifier table (D-4) |
| `startSide`, `endSide`, `displayStyle` *(new)* | unexported | inline `side` literals in `Validate`; loose pointers in `CompactDisplay` | Replace both (D-4) |
| `core/citationformat` *(new)* | package | none (searched `text/template`, `placeholder`, `func Parse` in `core/`, `api/`) | No template engine exists |
| `Form`, `Option`, `Target` *(new)* | types | `vocabkey.Level` (typed key shape) | Not vocabulary keys; levels are reused inside `Target` |
| `Builtin`, `Builtins`, `LookupBuiltin`, `ListFormAllows`, `InListForm` *(new)* | table, funcs | `vocabkey.Levels` | The rule's one declaration |
| `Parse`, `Template`, `Diagnostic`, `DiagnosticCode`, `DiagnosticCodes`, `Span`, `Ref`, `FieldRef` *(new)* | funcs, types | `core/locator/validate.go` (JSON, one error) | Different syntax; the editor needs positions |
| `Render`, `Resolver`, `Value`, `Run`, `Rendered` *(new)* | funcs, types | — | First renderer |
| `Requirements`, `Missing`, `Requirement`, `Need` *(new)* | funcs, types | — | First requirement derivation |
| `Token`, `ByID`, `Fields`, `RewriteFields`, `ErrFieldRef` *(new)* | funcs, error | — | First stored field reference in text |
| `FuzzParse`, `testdata/seed-formats.txt` *(new)* | test, fixture | `FuzzDecodeJPEGDC` | Same shape; the fixture is deleted by S15-20 |
| `core/internal/doctable` `Section`, `FirstColumn` *(new)* | test helper | `inventoryKeys`, `notKnobsSection`, the loop in `TestCacheDocListsEveryEntry` | Replaces all three |
| `TestDocMatchesEngine` *(new)* | test | `TestKnobInventoryMatchesRegistry` | Same check, on the helper |
| `docs/citation-formats.md` *(new)* | doc | the spike's design note of the same name (retired at S15-99) | The domain doc outlives the spike |

**Builds on.** `vocabkey.Level` for every prefix; `datevalue`'s end formatter; the `apperr` registry; the `layerPackages` guard; the raster fuzz precedent.
**Deletes.** The inline `side` literals in `datevalue.Validate` and `CompactDisplay`'s six-pointer calls (D-4); `formatSide`'s old signature; `inventoryKeys`, `notKnobsSection` and the inline reader loop in `TestCacheDocListsEveryEntry` (D-17). Nothing else becomes dead: no caller of the engine exists yet.
**Next adds.** S15-15: `Parse(text, form)` refuses a save with diagnostics; `Fields()` → `metadatafields.ResolveKeysTx` → `RewriteFields` to ids on write and to keys on read; the delete-impact probe searches the format columns for `FieldRef{ID: id}.Token()`. S15-16: a `Resolver` keyed by `Target` over batched reads, `Render` per Citation, `Missing` for the preview, `Builtins()` over FFI, Swift parity rows for `Form`, `Option`, `DiagnosticCode` and built-in names. S15-37 / S15-43 / S15-44: `valuemark.Mark` in `sourcemetadata.Input`, the Source date write and `locator.PageRef`, checked with `valuemark.Validate`; S15-37 maps `valuemark.invalid` in `L10n.Errors`. S15-38: `Requirements(full, short, list)` per type, grouped by `Target.Level`. S15-17: copy per diagnostic code. S15-20: deletes the seed corpus (D-16). A later doc-parity test is one `doctable.FirstColumn` call.

### Reach

None — no new path into existing code, no new state reachable. Nothing calls the new packages; the `datevalue` refactor keeps `Validate` and `CompactDisplay` behavior (T-2), and the doc-table refactor keeps both existing tests' results (T-13).

### Scale

None — no write, list or loop changes in the app. At the map's Scale the engine's work is bounded by D-9's limits: `Parse` is one pass over at most 4,096 bytes; `Render` resolves each placeholder of one template once (the census full format has 18 placeholders, 24 options), so 300 Citations is under 8,000 `Resolve` calls. S15-16 measures its render RPC at 300 and 1,200 Citations; this PR sets no budget.

### Edges

- **Assumptions.** A chain is ordered (first answered wins; T-6 swaps graph and Source). Requirements are one per distinct target sequence, so a field in two different chains is two requirements (T-9). A group's drop depends only on its own placeholders (D-10; T-6's nested URL group). `RewriteFields` assumes field spans are disjoint and in text order, which one forward scan guarantees (T-10). Values go in after parsing, so no value changes structure (T-6 rows with `*`, `[`, `{`, `\`). `formatSide`'s compact output is unchanged by the style parameter (T-2).
- **Neighbors.** Unknown with unknown text vs. without (prints vs. drops its group, both met: T-7, T-9). Supplied text vs. supplied date (both bracketed; the date keeps its qualifier: T-7). Whitespace-only text is unanswered; text with surrounding spaces prints as given (T-6). `{source.date}` vs. `{source.date:full}` print the same; `:year` keeps `ca.` (T-7). A range whose sides print the same prints once (T-3). `{meta.x}` / `{source.meta.x}` / `{citation.meta.x}` (T-4). Keys `line_number`, `1880-census`, `île`, `Île` parse; `a.b` is `bad_field`; `a b` is `bad_character`; `{source.meta.A:B}` is `unknown_option` (T-4); every non-empty `slug.Kebab` output parses as a key (T-11).
- **Removed inputs.** A field a format names cannot be deleted (S15-15's probe). A target the resolver does not know returns the zero `Value`: unanswered, so a needed placeholder prints nothing and `Missing` lists it, and a used one drops its group (T-6, T-9).
- **Real data.** The 66 formats of map § 6.8 parse with no diagnostic (T-5); longest 691 bytes with keys, about 1,300 with id tokens; deepest nesting 2.
- **Untrusted size.** Format text comes from the catalog, which a crafted project can fill. Bounds, checked before work: bytes ≤ 4,096; open groups and italic ≤ 8; options per chain and placeholders per format bounded by the byte limit. Values come from the resolver and are copied once into runs. `FuzzParse` runs 5 minutes (STEP-8).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/apperr` | `CodeValueMarkInvalid = "valuemark.invalid"` *(new)* |
| `core/valuemark` *(new)* | `Mark`, `ErrInvalid`, `Validate` (D-2) |
| `core/datevalue` | `display.go`: `CitationStyle`, `CitationLong`, `CitationShort`, `CitationYear`, `CitationDisplay` *(new)*; `formatSide(s side, st displayStyle)`, `applyQualifier(qual, point string, st displayStyle)` reshaped (D-3, D-4). `datevalue.go`: `startSide`, `endSide` *(new)*; package comment names both display styles |
| `core/citationformat` *(new)* | `form.go` (package comment; `Form`, `Forms`, `Valid`, `Option`), `builtins.go` (`Builtin`, `Builtins`, `LookupBuiltin`, `ListFormAllows`, `InListForm`), `parse.go` (`Target`, `FieldRef`, `Ref`, `Span`, `Template` and its `Form`/`Text`, `Diagnostic`, `DiagnosticCode` constants, `DiagnosticCodes`, `MaxFormatBytes`, `MaxDepth`, `Parse`), `render.go` (`Resolver`, `Value`, `Run`, `Rendered`, `Plain`, `Render`, `printed`), `requirements.go` (`Need`, `Requirement`, `Requirements`, `Missing`), `rewrite.go` (`Token`, `ByID`, `Fields`, `RewriteFields`, `ErrFieldRef`) |
| `core/internal/doctable` *(new)* | `Section`, `FirstColumn` (D-17) |

```go
// citationformat, signatures only
func Parse(text string, form Form) (*Template, []Diagnostic)
func Render(t *Template, r Resolver) Rendered
func Requirements(ts ...*Template) []Requirement
func Missing(reqs []Requirement, r Resolver) []Requirement
func (t *Template) RewriteFields(to func(FieldRef) (FieldRef, error)) (string, error)

type Target struct {
	Level   vocabkey.Level
	Builtin string   // bare name ("date"); empty for metadata
	Field   FieldRef // zero for a built-in
}
type Resolver interface{ Resolve(t Target) Value }
type Value struct {
	Text        string
	Date        *datevalue.Value
	Mark        valuemark.Mark
	UnknownText string // metadata only; a built-in's comes from its row
}
```

Errors: `valuemark.invalid` when `valuemark.Validate` refuses a mark. `citationformat` returns only `RewriteFields`' errors (`to`'s, or `ErrFieldRef`).

### FFI

None — S15-15 and S15-16 carry the engine over FFI.

### macOS

None — no Swift change.

### Strings

None — no user-facing copy. The engine's literal output (`n.d.`, `unpaginated`, `ca.`, month names) is English citation text, like the formats' own literals, and is not localized; STEP-10 says so in `add-date-value`.

## 7. Steps

**STEP-1 — The value mark**
Files: `core/apperr/apperr.go`, `core/valuemark/valuemark.go` *(new)*, `core/valuemark/valuemark_test.go` *(new)*, `core/matchregistry/guard_test.go`.
Do: add `CodeValueMarkInvalid` beside `CodeLocatorInvalid`; add the package per D-2, its comment naming the three stores that use it; add `{"core/valuemark", false}` to `layerPackages`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/valuemark/ ./core/apperr/ ./core/matchregistry/` passes (T-1).

**STEP-2 — Citation dates on one end formatter**
Files: `core/datevalue/datevalue.go`, `core/datevalue/display.go`, `core/datevalue/display_test.go`. Skill: `add-date-value`.
Do: D-4 first, with no output change: `startSide` / `endSide` in `Validate`; `formatSide` and `applyQualifier` take a `displayStyle`; `CompactDisplay` passes `styleCompact`; run the Check. Then D-3: `CitationStyle` and `CitationDisplay`, month names and abbreviations as unexported tables; the package comment names both styles.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/datevalue/...` passes (T-2 unchanged, T-3).

**STEP-3 — Forms, targets and the built-ins table**
Files: `core/citationformat/form.go` *(new)*, `core/citationformat/builtins.go` *(new)*, `core/citationformat/parse.go` *(new)*, `core/citationformat/builtins_test.go` *(new)*, `core/matchregistry/guard_test.go`.
Do: D-5, D-7, and the `Target` and `FieldRef` declarations of D-6 and D-14 in `parse.go`, which STEP-4 fills. Package comment: pure, no database; the syntax is in the domain doc STEP-10 writes. Add `{"core/citationformat", false}` to `layerPackages`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/citationformat/ ./core/matchregistry/` passes (T-8).

**STEP-4 — Parse**
Files: `core/citationformat/parse.go`, `core/citationformat/parse_test.go` *(new)*.
Do: D-8, D-9, D-15 and the codes table: `Ref`, `Span`, `Diagnostic`, the codes, `Template`, `Parse` — one forward scan over bytes with a stack of open groups and italic spans; each option checked in the codes table's order; diagnostics collected and stably sorted; the template keeps the text, the form, the tree and each metadata option's field byte span.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestParse' ./core/citationformat/` passes (T-4).

**STEP-5 — Render**
Files: `core/citationformat/render.go` *(new)*, `core/citationformat/render_test.go` *(new)*.
Do: D-10, D-11, D-12; dates through `datevalue.CitationDisplay` in D-5's style.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestRender' ./core/citationformat/` passes (T-6, T-7).

**STEP-6 — Requirements and missing**
Files: `core/citationformat/requirements.go` *(new)*, `core/citationformat/requirements_test.go` *(new)*.
Do: D-13, using `printed` from STEP-5.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestRequirements|TestMissing' ./core/citationformat/` passes (T-9).

**STEP-7 — Field tokens and the rewrite**
Files: `core/citationformat/rewrite.go` *(new)*, `core/citationformat/rewrite_test.go` *(new)*.
Do: D-14.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestRewriteFields|TestFields' ./core/citationformat/` passes (T-10).

**STEP-8 — The seed corpus and the fuzz target**
Files: `core/citationformat/testdata/seed-formats.txt` *(new)*, `core/citationformat/fuzz_test.go` *(new)*, `core/citationformat/parse_test.go`.
Do: write the 66 formats of map § 6.8 "Formats" (`docs/deployment-plan/spike-15/evidence-explained-citation-map.md`) per D-16 (every wrap falls between `]`, `}` or `*` and `[` or `{`, so lines join with nothing between). Add `TestSeedFormatsParse` (T-5) and `FuzzParse` (T-11). Run the fuzzer for 5 minutes; commit any crasher under `core/citationformat/testdata/fuzz/FuzzParse/` *(new)* with its fix.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/citationformat/` passes; `CGO_ENABLED=1 go test -tags fts5 -run '^$' -fuzz FuzzParse -fuzztime 5m ./core/citationformat/` ends with no failure (report its last line).

**STEP-9 — One doc-table reader**
Files: `core/internal/doctable/doctable.go` *(new)*, `core/matchregistry/inventory_test.go`, `core/catalogsession/cache_doc_test.go`.
Do: D-17; replace `inventoryKeys` with `doctable.FirstColumn(t, "../../docs/matching-model.md", "Knob inventory")`, `notKnobsSection` with `doctable.Section(t, "../../docs/matching-model.md", "Not knobs")`, and the loop in `TestCacheDocListsEveryEntry` with `doctable.FirstColumn(t, "../../docs/catalog-caches.md", "Registry entries")`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/matchregistry/ ./core/catalogsession/` passes (T-13).

**STEP-10 — Docs**
Files: `docs/citation-formats.md` *(new)*, `core/citationformat/doc_test.go` *(new)*, `docs/source-layer-data-model.md`, `.agents/skills/add-date-value/SKILL.md`, `.cursor/rules/date-values.mdc`, `docs/deployment-plan/spike-15/completed.md`, `docs/deployment-plan/spike-15/deployment-plan.md`, `docs/deployment-plan/spike-15/evidence-explained-citation-map.md`, this plan.
Do: write the domain doc per D-18 from map § 6.3 and this plan's Decisions, in Provenencia's words, with invented examples only (AC-2.1's census example is ours); add `TestDocMatchesEngine` (T-12); add D-18's sentence to § 3 of `source-layer-data-model.md`. In `add-date-value`: line 12's "compact display" becomes "compact and citation display", the "Package" tree and types line name `CitationDisplay`, and "Display (macOS)" gains one line: citation terms are English citation text in Go's `CitationDisplay`, not L10n. In `date-values.mdc`, the first bullet names `CitationDisplay` beside `CompactDisplay`. In `deployment-plan.md`'s rule "Dates in citations use citation terms" and `evidence-explained-citation-map.md` § 6.3, `CitationDisplay(v, form)` becomes `CitationDisplay(v, style)` with a `CitationStyle`. Then the Definition of done's docs lines.
Check: `CGO_ENABLED=1 go test -tags fts5 -run TestDocMatchesEngine ./core/citationformat/` passes; `python3 scripts/check-plan-docs.py --links docs/citation-formats.md` reports no error.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/valuemark/valuemark_test.go` `TestValidate` *(new)* | The eight rows of AC-7.1 and AC-7.2; the refusal's code is `valuemark.invalid` | AC-7.1, AC-7.2, D-2 |
| T-2 | Go | `core/datevalue/validate_test.go`, `core/datevalue/display_test.go` `TestCompactDisplay` (existing) | Unchanged results after D-4 | D-4 |
| T-3 | Go | `core/datevalue/display_test.go` `TestCitationDisplay` *(new)* | AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5; month-only → `March`; day and month → `3 March`; year and day without month → `1882`; `CitationYear` on ABT 3 March 1830 → `ca. 1830`; range 1882-01 to 1882-12 `CitationYear` → `1882`; `Sept.`, `June` short; month and day without year → `3 March`; day alone → empty; `CitationYear` on month-only → empty; time only → empty; range with a time-only end and phrase `Lent` → `Lent`; year `-50` → `-50`; kind `""` with phrase `x` → `x` | AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5, D-3 |
| T-4 | Go | `core/citationformat/parse_test.go` `TestParse` *(new)* | AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8, AC-1.9 and AC-6.3 rows with codes and spans; one row per code of the codes table with its span; `*a [{source.title}* c]` → `unclosed_italic` at 0–1 and at 18–19 (sorted, 0 first); `{source.date:year:full}` → `unknown_option` at `year:full`; `{{source.title}` → `bad_character`; `{citation.meta.x}` in list → only `meta_not_at_level`; `[{a` → only `unclosed_placeholder`; nine `[` → only `too_deep`, at the ninth; keys `line_number`, `1880-census`, `île`, `Île` parse; `{source.meta.a.b}` → `bad_field`; `{source.meta.a b}` → `bad_character`; `{source.meta.A:B}` → `unknown_option` | AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8, AC-1.9, AC-6.3, D-8, D-9 |
| T-5 | Go | `core/citationformat/parse_test.go` `TestSeedFormatsParse` *(new)* | Each of the 66 lines of `core/citationformat/testdata/seed-formats.txt` *(new)* → a template, no diagnostic | AC-1.1, D-16 |
| T-6 | Go | `core/citationformat/render_test.go` `TestRender` *(new)* | Subtest `census_full`: census full with date 1880; Source `creator` `U.S.`, `jurisdiction` `Ottawa County, Kansas`, `schedule` `population schedule`, `enumeration_district` `236`; graph `dwelling_number` `112`, `family_number` `118`, `item` `Ada Robins`; page `14`; Artifact `format` `digital image`, `provider` `Ancestry`, `url` `https://www.ancestry.com`, `accessed_date` `12 March 2025`, `citing` `NARA microfilm publication T9, roll 393` → AC-2.1 runs and plain; subtest `census_item_on_source`: the item on the Source only → same text; AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6; values `a*b`, `[x]`, `{y}`, `\` print as given; `  spaced  ` prints with its spaces; whitespace-only is unanswered; an unknown target → unanswered; nil template → no runs | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, D-10, D-11, D-12 |
| T-7 | Go | `core/citationformat/render_test.go` `TestRenderMarks` *(new)* | AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, AC-3.6, AC-3.7; short form `{source.date}` on 3 March 1830 → `3 Mar. 1830`; `{source.date:year}` ABT 1880 → `ca. 1880`; `{source.date}` and `{source.date:full}` print the same; unknown and supplied both sent → unknown text | AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, AC-3.6, AC-3.7, D-5, D-11 |
| T-8 | Go | `core/citationformat/builtins_test.go` `TestBuiltins`, `TestForms` *(new)* | Eight rows in D-7's order with their facts; `LookupBuiltin(LevelCitation, "page")` found, `(LevelSource, "page")` not; `ListFormAllows` and `InListForm` true for Source only; every row's `Level` is `Valid()`; `Builtins()` and `Forms()` return new slices; `Form("x").Valid()` false | D-5, D-7 |
| T-9 | Go | `core/citationformat/requirements_test.go` `TestRequirements`, `TestMissing` *(new)* | AC-4.1, AC-4.2, AC-4.3, AC-4.4, AC-4.5, AC-4.6; a field in two different chains → two requirements; nil templates skipped; an unknown-without-text needed field → not missing; a zero `Value` → missing | AC-3.5, AC-4.1, AC-4.2, AC-4.3, AC-4.4, AC-4.5, AC-4.6, D-6, D-13 |
| T-10 | Go | `core/citationformat/rewrite_test.go` `TestRewriteFields`, `TestFields` *(new)* | AC-6.1, AC-6.2; escapes and spaces outside fields kept byte for byte; a `to` error → that error, empty text; an answer with both or neither set → `ErrFieldRef`; `Fields` distinct in first-appearance order; `Token` of a key and of an id | AC-6.1, AC-6.2, D-14 |
| T-11 | Go | `core/citationformat/fuzz_test.go` `FuzzParse` *(new)* | `(text, form)`: `Parse(text, Form(form))` does not panic; a template exactly when no diagnostics; every span inside `[0, len(text)]`; with a template, `Render` with a resolver answering every target does not panic, and `RewriteFields` with the identity returns `text`; for `slug.Kebab(text)` non-empty and at most 4,000 bytes, `{source.meta.<it>}` parses with no diagnostic | D-8, D-9, D-14, D-16 |
| T-12 | Go | `core/citationformat/doc_test.go` `TestDocMatchesEngine` *(new)* | `## Built-in placeholders` first column = `Builtins()` as `level.name`; `## Diagnostics` first column = `DiagnosticCodes()` | D-18 |
| T-13 | Go | `core/matchregistry/inventory_test.go` `TestKnobInventoryMatchesRegistry`, `core/catalogsession/cache_doc_test.go` `TestCacheDocListsEveryEntry` (existing) | Pass on `doctable.FirstColumn` and `doctable.Section`, with the same row sets as before | D-17 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `core/datevalue` (STEP-2), `core/matchregistry` and `core/catalogsession` (STEP-9).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none in this PR
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`inventoryKeys`, `notKnobsSection`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — no UI
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] FuzzParse ran 5 minutes; its last output line is in the PR description; any crasher is committed under core/citationformat/testdata/fuzz/FuzzParse/
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc: docs/citation-formats.md (new) written and linked from docs/source-layer-data-model.md § 3; add-date-value and date-values.mdc name CitationDisplay
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None in the app — nothing calls the engine yet; slice 4's Check ("the census example renders in a handler test") is S15-16's. The reviewer checks the engine from the command line:

1. `CGO_ENABLED=1 go test -tags fts5 -v -run 'TestRender/census_full' ./core/citationformat/` shows `--- PASS: TestRender/census_full`; read its expected text against map § 6.8's census example.
2. `CGO_ENABLED=1 go test -tags fts5 -v -run TestSeedFormatsParse ./core/citationformat/` shows `--- PASS`: every map format parses.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A seeded format in map § 6.8 does not parse under D-9 | Checked twice while planning (66 of 66); T-5 holds it |
| The `formatSide` reshape changes the app's compact dates | Done first in STEP-2 with no new style; T-2 pins it |
| Citation terms ("ca.", month abbreviations, "unpaginated", "n.d.") differ from the edition on hand | Each is one table row; the user's edition check (map § 7) changes the row, not the code |
| A later PR needs the tree exported | D-15 lists every map caller; a new need is a change with its own decision |

**Stop and report if:**

- A line of `core/citationformat/testdata/seed-formats.txt` *(new)* copied from map § 6.8 gets a diagnostic (name the line and the code).
- `core/citationformat` or `core/valuemark` would need to import a `core/database` package.
- `TestCompactDisplay` or `datevalue`'s validate tests fail after STEP-2's reshape and the fix would change a test's expectation.
- `TestKnobInventoryMatchesRegistry` or `TestCacheDocListsEveryEntry` reads a different row set or section on `doctable` than before.
- A key in `core/database/sourcevocab/registry.go` or any test fixture holds a character outside D-9's key set.
- The fuzzer finds a crash whose fix needs a change to a Decision (a limit, a code, the grammar).

## 12. Open questions

None.

## 13. PR

**Title:** S15-14 — The citation format engine
**Body:** objective in one sentence; what shipped against each US; AC evidence (test names); the fuzz run's last line; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-14-citation-format-engine.md`.
