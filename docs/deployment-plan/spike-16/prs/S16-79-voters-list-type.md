# S16-79 — A seeded Voters list type cites a voter list down to the entry

**Status:** Planned
**Spike / slice:** Spike 16 · Slice 6j — A Voters list type
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: a seeded type, its fields and formats are catalog data that today's Source type, board and citation views already show)
**Board:** —
**Depends on:** S16-78 (Install derives suggestions), landed in [#993](https://github.com/Jake-Robins-Studios/provenencia/pull/993)
**Blocks:** —
**Branch:** `s16-79-voters-list-type`
**Version bump:** minor — a new Source type in new projects is a backward-compatible feature with no schema or wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`; the seed is data, so no test validates registry entries (user, 2026-11-26, `add-seeded-vocabulary` step 6)
**Context:** [`docs/citation-formats.md`](../../../citation-formats.md) (syntax, groups, nearest-level reads); [`docs/seeded-vocabulary.md`](../../../seeded-vocabulary.md) § Implementation, § 2.1, § 2.2, § 2.3; [Spike 15 citation map](../../spike-15/evidence-explained-citation-map.md) chapter 9 ("Voter registrations and poll books") and § 6.8; working rules "(Batch 6) A seeded citation format is written to find the record again" and the Spike 15 rule "The seed is the product default"
**Planned:** 2026-11-26 against `origin/main` @ `0886b43`; refreshed 2026-11-26 against `4f0806f`, after S16-78 landed (fetch it; a local `main` may be older)
**Review:** [`S16-79-voters-list-type.review.md`](S16-79-voters-list-type.review.md) — Fits with changes · Ready with changes, 2 rounds; refresh round below; no blocker open; To user answered

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

A new project seeds a **Voters list** Source type whose citation leads a reader from the jurisdiction and the election down to one voter's entry, then to the archive that holds the list, then to the copy the researcher viewed. One format serves a Canadian federal voters list, a British register of electors and an American great register or poll book, because the election, electoral district and polling division fields hold the list's own words.

**Why now.** The user cited a 1949 Canadian federal voters list from Ancestry.ca (2026-11-26). Ancestry's citation names only the collection ("Library and Archives Canada; Ottawa, Ontario, Canada; *Voters Lists, Federal Elections, 1935-1980*"), and no seeded type holds the polling division, the LAC reference (R1003-6-3-E) and the record group (RG113-B) together with a page and entry. The citation map files voter lists under P2, but `record_book` has no electoral geography and no archive references.

Every record type's online copy prints from one shared copy layer that adds the database title when it is filled in (user, 2026-11-26).

**What stays.** Every other seeded type's citations render as today, except the database title in its copy layer; existing projects are not changed (rule "The seed is the product default"). No test is added for seed content (user, 2026-11-26).

## 2. User stories

**US-1.** As a researcher citing a Canadian federal voters list seen on Ancestry, I get a full note that says which election, district, polling division, page and entry, which LAC series, reference and record group, and which online copy, so that anyone can find the entry again.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A new project's `voters_list` formats render with jurisdiction "Canada", election "1949 federal election", electoral district "St. Paul's, Ontario", polling division "urban polling division 52", page "3", entry "41", item "Ada Robins", collection "Voters Lists, Federal Elections, 1935–1980", call number "R1003-6-3-E", record group "113-B", repository "Library and Archives Canada, Ottawa", database title "Canada, Voters Lists, 1935–1980", format "digital image", provider "Ancestry", URL "https://www.ancestry.ca", accessed "26 November 2026" | Full: `Canada, 1949 federal election, St. Paul's, Ontario, urban polling division 52, p. 3, no. 41, Ada Robins; Voters Lists, Federal Elections, 1935–1980, R1003-6-3-E, Record Group 113-B, Library and Archives Canada, Ottawa; "Canada, Voters Lists, 1935–1980," digital image, *Ancestry* (https://www.ancestry.ca : accessed 26 November 2026).` |
| AC-1.2 | The same values, short form | `Canada, 1949 federal election, St. Paul's, Ontario, urban polling division 52, p. 3, no. 41, Ada Robins.` |
| AC-1.3 | The same values, list form | `Canada. Voters Lists, Federal Elections, 1935–1980. R1003-6-3-E. Record Group 113-B. Library and Archives Canada, Ottawa.` |

**US-2.** As a researcher citing another country's voter list, I fill the same fields with that list's own words and get a citation that reads right with nothing left dangling.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | British register: jurisdiction "Islington, London, England", election "1921 spring register", electoral district "Islington North", polling division "Highbury ward, polling district B", entry "1234", item "Ada Robins", collection "Electoral Registers", repository "London Metropolitan Archives, London", database title "London, England, Electoral Registers, 1832–1965", format "digital image", provider "Ancestry", URL "https://www.ancestry.co.uk", accessed "26 November 2026"; no page, no call number, no record group | Full: `Islington, London, England, 1921 spring register, Islington North, Highbury ward, polling district B, no. 1234, Ada Robins; Electoral Registers, London Metropolitan Archives, London; "London, England, Electoral Registers, 1832–1965," digital image, *Ancestry* (https://www.ancestry.co.uk : accessed 26 November 2026).` List: `Islington, London, England. Electoral Registers. London Metropolitan Archives, London.` |
| AC-2.2 | American great register: jurisdiction "Sacramento County, California", election "1890 great register", polling division "precinct 3", page "12", line "8", entry "4567", item "Ada Robins", collection "Great Registers, 1866–1898", repository "California State Library, Sacramento", film number "977250", format "digital image", provider "FamilySearch", URL "https://www.familysearch.org", accessed "26 November 2026"; no electoral district, no database title | Full: `Sacramento County, California, 1890 great register, precinct 3, p. 12, line 8, no. 4567, Ada Robins; Great Registers, 1866–1898, California State Library, Sacramento; film 977250; digital image, *FamilySearch* (https://www.familysearch.org : accessed 26 November 2026).` Short: `Sacramento County, California, 1890 great register, precinct 3, p. 12, line 8, no. 4567, Ada Robins.` |
| AC-2.3 | AC-1.1's values without collection; Source title "Poll book of Calder North, 1882" | Full contains `Ada Robins; Poll book of Calder North, 1882, R1003-6-3-E`; list: `Canada. Poll book of Calder North, 1882. R1003-6-3-E. Record Group 113-B. Library and Archives Canada, Ottawa.` |

**US-3.** As a researcher starting a Voters list Source, the board offers exactly the fields its formats read, and says which ones a citation needs.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | A new project's Voters list type | It suggests, in order: `jurisdiction`, `election`, `electoral_district`, `polling_division`, `volume`, `page`, `line_number`, `entry_number`, `item`, `collection`, `call_number`, `record_group`, `repository`, `film_number`, `database_title`, `format`, `provider`, `url`, `accessed_date` (19 fields; `suggestedKeys` derived this list at the planning base) |
| AC-3.2 | A Voters list Source's board | Jurisdiction, Election or register, and Repository are marked needed; Coverage shows as a used field the type does not suggest; no Source date is marked needed |
| AC-3.3 | A new project | Source types lists Voters list with the document icon; the three new fields have the labels "Election or register", "Electoral district" and "Polling division" |

**US-4.** As a researcher citing any record type seen in an online database, the database's title prints with the copy, so the reader finds the same database.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `record_book` full form with jurisdiction "Calder County, Westmark", creator "Calder County Recorder", book "Deed Book F", page "14", item "Ada Robins", database title "Calder County Deeds, 1850–1900", format "digital image", provider "Westmark Heritage", URL "https://example.org/calder", accessed "12 March 2025", repository "Calder County Archives, Port Ellis" | `Calder County, Westmark, Calder County Recorder, Deed Book F: 14, Ada Robins; "Calder County Deeds, 1850–1900," digital image, *Westmark Heritage* (https://example.org/calder : accessed 12 March 2025); Calder County Archives, Port Ellis.` |
| AC-4.2 | The same values without database title | `Calder County, Westmark, Calder County Recorder, Deed Book F: 14, Ada Robins; digital image, *Westmark Heritage* (https://example.org/calder : accessed 12 March 2025); Calder County Archives, Port Ellis.` — today's output |
| AC-4.3 | The twelve record types that print a copy (census, the three certificates, church register, record book, passenger list, case file, manuscript, government file, book, newspaper item) | Each format reads the copy through `copyLayer` and no other text of it changes; each type's derived suggestions gain `database_title` just before `format` |

## 3. Scope

| In | Covered by |
| --- | --- |
| Seeded fields `election`, `electoral_district`, `polling_division` | STEP-1, AC-3.3 |
| One shared copy layer with the database title, used by every record type's full format | STEP-2, AC-4.1 – AC-4.3 |
| Seeded type `voters_list` with its three formats; its suggestion list (derived) | STEP-3, AC-1.1 – AC-3.2 |
| `TestPlaceholders` stops restating the seeded type count | STEP-3 |
| Seeded vocabulary doc, citation map rows, the format rule in `add-seeded-vocabulary`, version | STEP-4 |

| Out | Home |
| --- | --- |
| A committed test of the new type's renders, suggestions, board needs or counts | not planned (user, 2026-11-26: the seed is data; `add-seeded-vocabulary` step 6) |
| The provider's image number ("image 37 of 412") in any seeded format | not planned (user, 2026-11-26: the URL and the path down to the entry find the image) |
| Adding the voters list to existing projects | not planned (rule "The seed is the product default": the product owner updates dogfood projects by hand) |
| A seeded province or state field | not planned (D-2: the electoral district or the jurisdiction carries it) |
| Any other change to another seeded type's formats | not planned |
| A voters-list-specific icon | not planned (D-1) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Types | `core/database/sourcevocab/registry.go` `seedTypes` | 26 types; voter lists have only `record_book` (P2 local: no electoral geography, no archive reference) |
| Fields | `core/database/sourcevocab/registry_fields.go` `seedFields` | 69 fields; the comment above it counts them ("The 69 metadata fields: …"); no election, electoral district or polling division |
| Suggestions | `core/database/sourcevocab/registry_suggestions.go` `suggestedKeys` | `Install` derives each type's list from its formats; no hand list to edit |
| Copy layer | `registry.go`: `[; {meta.format}, *{meta.provider}*][ ({meta.url}[ : accessed {meta.accessed_date}])]` typed by hand ten times (`certificateFormats`, census, church register, record book, passenger list, case file, manuscript, government file, book, newspaper item) | No format reads `database_title` |
| Seed tests | `core/database/sourcevocab/sourcevocab_test.go` `TestInstall`; `registry_test.go` `TestSuggestedKeys`, `TestFieldKeysMatchSeed` | Check `Install` row for row against the registry and the rule on synthetic formats; no count, no render, no per-type check. They stay green with no edit |
| Count | `core/database/citationrender/placeholders_test.go` `TestPlaceholders`, subtest "every seeded type's formats load with no diagnostic": `len(types) != 26` | Restates the seed's size; fails at 27 |
| Docs | `docs/seeded-vocabulary.md` § Implementation (line 83), § 2.1, § 2.2; `docs/deployment-plan/spike-15/evidence-explained-citation-map.md` chapter 9 table, § 6.8 "Source types"; `.agents/skills/add-seeded-vocabulary/SKILL.md` § Source vocabulary step 1 | 26 types, 69 fields; voter lists under P2 |

**Precedent.** [#967](https://github.com/Jake-Robins-Studios/provenencia/pull/967) (`5314ca4`, "Census citations print an optional sub-district after the enumeration district.") added a seeded field and changed formats with `seeded-vocabulary.md` and the citation map in one commit; copy its registry and docs shape, not its test edits, which [#993](https://github.com/Jake-Robins-Studios/provenencia/pull/993) retired. The S16-78 review checked behavior with uncommitted tests through `go test -overlay` (its ship log); D-11 copies that.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | One general type: key `voters_list`, label "Voters list", description "A voters list, poll book or register of electors made for an election or a registration year.", icon `type_document` (as `passenger_list`, the other national list of names) | User, 2026-11-26: one generic voter list | A Canada-only type — the user asked for one type for every country; a new icon — needs an asset, which is chrome |
| D-2 | The election, electoral district and polling division values carry the list's own words; the formats add no word before them ("urban polling division 52", "precinct 3", "Highbury ward, polling district B"). A province or state goes in the electoral district value or the jurisdiction | User, 2026-11-26: each country names these levels differently | A word in the format — wrong for a precinct or a ward; more fields per country — the board grows for every researcher |
| D-3 | Full form order: the record and its locators (jurisdiction, election, district, division, volume, page, line, entry, item); then the archive as one unit (series, reference, record group, repository); then microfilm; then the online copy | User, 2026-11-26: archive first, copy after | Copy first with "citing" (Ancestry's and census's shape); repository last (`government_file`'s shape) |
| D-4 | The record group prints `Record Group {meta.record_group}` | User, 2026-11-26: as `government_file` | Printing the value bare ("RG113-B") |
| D-5 | Needed (outside any group): `jurisdiction` and `election` in all three forms, `repository` in full and list. The series reads `{meta.collection\|source.title}`. Everything else is in a group | Rule "(Batch 6) A seeded citation format is written to find the record again" | Repository optional — a researcher's copy of the type can drop it |
| D-6 | No `source.date` in any form; the election value carries the year | "1949 1949 federal election" reads wrong | `{source.date:year}` as census does |
| D-7 | One `copyLayer` const in `registry.go`: `[; ["{meta.database_title}," ]{meta.format}, *{meta.provider}*][ ({meta.url}[ : accessed {meta.accessed_date}])]`. Every format that types the copy layer by hand uses it, and so does `voters_list`. The URL group stays beside the copy group, as the ten have it | User, 2026-11-26: share it, with the title everywhere; quoted as `website` quotes its title | Italic database title — two italic runs side by side; nesting the URL in the copy group — changes the ten types' output beyond the title |
| D-8 | The formats read no `creator`, no `citing`, no `film_publication` | The jurisdiction and the series name who made the list; the archive layer is what "citing" would say | Reading them — 3 more suggested fields no example needs |
| D-9 | The formats are exactly the text in **Go core** below | Rendered at the planning base (`citationformat.Render`) for AC-1.1 – AC-2.3, and `suggestedKeys` gave AC-3.1 | — |
| D-10 | Registry placement: the type follows `passenger_list`; the three fields follow `subdistrict`; `copyLayer` sits beside `certificateFormats` | Keeps the registers together | Appending at the end |
| D-11 | The AC renders are evidence, not tests: one scratch test file `zz_evidence_test.go` in package `sourcevocab`, kept outside the repo and run with `go test -overlay`, renders a `seedTypes` entry's three forms from a map of field values; the outputs go in the PR body. Its resolver answers a metadata target from `Target.Field.Key`, `source.title` from a string, every other built-in empty; it prints italic runs in asterisks, as the deleted `plainWithItalics` did (`git show ec7b579^:core/database/sourcevocab/render_test.go`). No file is committed for it | User, 2026-11-26: no committed test validates seed entries; the ACs still need evidence an agent can produce | A committed literal-render test — what the user retired; the app check alone — the implementer may not run the app |
| D-12 | New projects only | Spike 15 rule "The seed is the product default" | A migration insert — the skill forbids seed `INSERT`s |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `voters_list` *(new)* | seeded type | `record_book`, `passenger_list`, `government_file` | `record_book` is local and has no electoral geography or archive reference; `passenger_list` reads no reference or record group; `government_file` reads no page, line or entry |
| `election` *(new)* | seeded field | `schedule`, `source.date` | `schedule` is described as a census schedule; the date cannot hold "spring register" or "federal" |
| `electoral_district` *(new)* | seeded field | `enumeration_district` | Its description and the census format's "ED" say census |
| `polling_division` *(new)* | seeded field | `subdistrict` | Census sub-district by description and by the census format's "sub-district" word |
| `copyLayer` *(new)* | const | `certificateFormats`, `journalArticleFormats` (shared format text) | It is that pattern, for the one clause twelve types share |

**Builds on.** `sourcevocab` registries and `Install` (skill `add-seeded-vocabulary`), `suggestedKeys`, the citation engine's groups and chains.
**Deletes.** The ten hand-typed copy layers (D-7); the seeded type count in `TestPlaceholders`.
**Next adds.** Another country's register is a new set of values, not a type. A researcher who wants a word before the division copies the type (`CopyType`) and edits its formats.

### Reach

None — a seeded type is one more row in lists that already show any number of types.

### Scale

None — 27 types and 72 fields install once at create; no list or loop changes.

### Edges

- **Assumptions.** `suggestedKeys` derives suggestions in first-read order (AC-3.1 was derived with it). `TestInstall` compares the catalog with `seedTypes` and `seedFields`, so new rows need no test edit.
- **Neighbors.** The copy layer changes the twelve record types only when a database title is set (AC-4.2); the new fields are read by no other format.
- **Removed inputs.** An empty group drops with its punctuation; AC-2.1 (no page, reference or group) and AC-2.2 (no district, no database title) pin it. An empty `collection` falls to the Source title (AC-2.3).
- **Real data.** Three real-shaped lists from three countries (AC-1 – AC-2).
- **Untrusted size.** None — seeds are product data.

### Schema

None — no catalog change; `Install` writes rows.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcevocab` `registry_fields.go` | `seedFields` gains three rows after `subdistrict`; its comment drops the count (STEP-1) |
| `registry.go` | `copyLayer` *(new)* (D-7); the ten hand copies use it |
| `registry.go` | `seedTypes` gains `voters_list` (D-1) after `passenger_list`, with the formats below |

Formats (each one line in Go, a raw string; the full one joins `copyLayer`):

```text
Full:  {meta.jurisdiction}, {meta.election}[, {meta.electoral_district}][, {meta.polling_division}][, vol. {meta.volume}][, p. {meta.page}][, line {meta.line_number}][, no. {meta.entry_number}][, {meta.item}]; {meta.collection|source.title}[, {meta.call_number}][, Record Group {meta.record_group}], {meta.repository}[; film {meta.film_number}]` + copyLayer + `.
Short: {meta.jurisdiction}, {meta.election}[, {meta.electoral_district}][, {meta.polling_division}][, vol. {meta.volume}][, p. {meta.page}][, line {meta.line_number}][, no. {meta.entry_number}][, {meta.item}].
List:  {meta.jurisdiction}. {meta.collection|source.title}[, {meta.coverage}].[ {meta.call_number}.][ Record Group {meta.record_group}.] {meta.repository}.
```

Fields (all `metadatafields.DataTypeText`, no unknown text):

| Key | Label | Description |
| --- | --- | --- |
| `election` | Election or register | The election or registration the list was made for, with its year, in the list's own words, as it should appear in a citation (1882 general election; 1921 spring register). |
| `electoral_district` | Electoral district | The riding, constituency, division or other electoral district, with its province or state when the jurisdiction does not name it, as it should appear in a citation (St. Paul's, Ontario). |
| `polling_division` | Polling division | The polling division, polling district, ward, precinct or subdivision, with the word the list uses, as it should appear in a citation (urban polling division 52). |

Errors: none new.

### FFI

None — no wire change; the type and fields reach the app through today's reads.

### macOS

None — the Source types list, the board and the citation views show catalog rows.

### Strings

None — type and field labels are catalog data in English, as every seeded label.

## 7. Steps

**STEP-1 — Seed the three fields**
Files: `core/database/sourcevocab/registry_fields.go`. Skill: `add-seeded-vocabulary`.
Do: add the three rows of **Go core** after `subdistrict`. The comment above `seedFields` keeps no count and no breakdown: "The seeded metadata fields. `docs/seeded-vocabulary.md` § Implementation counts them and says where each came from. Each description says to enter the value as it should appear in a citation. Publisher and place of publication carry the unknown text \"n.p.\" and page carries \"unpaginated\"."
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/...` passes.

**STEP-2 — One copy layer with the database title**
Files: `core/database/sourcevocab/registry.go`.
Do: add `copyLayer` (D-7, D-10) and replace each of the ten hand copies with it (each format string splits at the old clause and joins `copyLayer`; no other character of a format changes).
Check: `rg -n '\{meta\.format\}, \*\{meta\.provider\}\*' core/database/sourcevocab/registry.go` prints one line, the `copyLayer` const; `rg -c '\+ copyLayer \+' core/database/sourcevocab/registry.go` prints 10; the D-11 scratch test renders AC-4.1 and AC-4.2 from `record_book` exactly; `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/... ./core/database/citationrender/...` passes.

**STEP-3 — Seed the type and its formats**
Files: `registry.go`, `core/database/citationrender/placeholders_test.go`.
Do: add `voters_list` (D-1, D-10) with the formats of **Go core**; its suggestions are derived. In `TestPlaceholders`, `len(types) != 26` and its `Fatalf` become `len(types) == 0` with `t.Fatal("no seeded types")`, since the subtest checks that each type's formats load.
Check: `rg -c '\+ copyLayer \+' core/database/sourcevocab/registry.go` prints 11; the D-11 scratch test renders AC-1.1 – AC-2.3 exactly and prints `suggestedKeys` of the `voters_list` formats as AC-3.1's list; `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/... ./core/database/citationrender/... ./core/database/sourcemetadata/... ./core/onboarding/...` passes; `git status --short` lists no `zz_evidence_test.go`.

**STEP-4 — Docs and version**
Files: `docs/seeded-vocabulary.md`, `.agents/skills/add-seeded-vocabulary/SKILL.md`, `docs/deployment-plan/spike-15/evidence-explained-citation-map.md`, `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do:
- `docs/seeded-vocabulary.md` line 83: "26 types" → "27 types"; "69 fields" → "72 fields"; "The 69 are the map's 64, plus `subdistrict` for a census sub-district (Canada), printed after the enumeration district when set (user, 2026-11-24), plus four place fields" → "The 72 are the map's 64, plus `subdistrict` for a census sub-district (Canada), printed after the enumeration district when set (user, 2026-11-24), plus `election`, `electoral_district` and `polling_division` for the voters list, whose values carry the list's own words (user, 2026-11-26), plus four place fields"; the government-records parenthesis "(census, the three certificates, record book, case file, statute)" gains "voters list" after "record book". § 2.1: `voters_list` after `passenger_list`. § 2.2: the three keys on the `source` line after `subdistrict`; after the sentence "`url` and `accessed_date` describe the copy a researcher used; the bytes of a capture still live on an Artifact/File." add "Every record type's full format prints that copy through one shared clause, `copyLayer` in `registry.go`: `\"database title,\" format, *provider* (url : accessed date)`, each part when set (user, 2026-11-26)."
- `docs/deployment-plan/spike-15/evidence-explained-citation-map.md`: the chapter 9 row "Voter registrations and poll books | P2 | |" becomes "Voter registrations and poll books | `voters_list` (P2, national variant) | Election, electoral district, polling division, page, entry; series, reference, record group, archive"; in § 6.8 "Source types", "26 types." → "27 types." and a row after `passenger_list`: "| `voters_list` | Voters list | P2 (national) | Voters lists, poll books, registers of electors, great registers |". Leave the rest of that file alone (§ 6.8 "Existing infrastructure", "Fields", and the Spike 15 `README.md` and `deployment-plan.md` are Spike 15's record, as #967 left them).
- `.agents/skills/add-seeded-vocabulary/SKILL.md` § Source vocabulary, step 1, after the `seedTypes` bullet: "A record type's full format reads general to specific: every locator from the jurisdiction down to the entry, then the archive that holds the original, then the copy the researcher viewed, through the shared `copyLayer`. Where a level's word differs by country (district, ward, precinct), the value carries the record's word and the format adds none. Rule: Spike 16 \"(Batch 6) A seeded citation format is written to find the record again\"."
- Version: `VERSION`, `core/version.go` `Version` and every `MARKETING_VERSION` in `macos/Provenencia.xcodeproj/project.pbxproj` move to the next minor of `origin/main`'s `VERSION` at the time (0.47.0 from 0.46.0), in one commit.
Check: `python3 scripts/check-guidance-names.py` passes; `rg -n '26 types|69 fields' docs/seeded-vocabulary.md` prints nothing.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Seed a Voters list type whose citation reaches the entry, the archive and the copy.").

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/citationrender/placeholders_test.go` `TestPlaceholders` | Every seeded type's formats load with no diagnostic, the voters list among them; no count | AC-1.1 – AC-2.3 (formats parse), D-9 |
| T-2 | Go | `core/database/sourcevocab/sourcevocab_test.go` `TestInstall` (no edit) | A new catalog holds `seedTypes` and `seedFields` row for row, the new rows among them | AC-3.3 |
| T-3 | Go | `core/database/sourcevocab/registry_test.go` `TestSuggestedKeys` (no edit) | The rule that derives AC-3.1 and AC-4.3's lists | AC-3.1, AC-4.3 |

The render ACs are checked by the D-11 scratch renders (STEP-2, STEP-3) and § 10, not by a committed test (user, 2026-11-26).

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestPlaceholders`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name, scratch render (D-11) or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored; no scratch test committed
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none: labels are catalog data
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — no brief
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together): minor
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status `Landed [#N](…)`; completed.md: `## S16-79 — A seeded Voters list type cites a voter list down to the entry` above the newest entry, `**Landed <date>** in [#N](…).`, and two sentences: new projects seed a Voters list type whose citation names the election, district, polling division, page and entry, then the archive, then the copy, in any country's words; every record type's citation prints the online database's title with the copy
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated: docs/seeded-vocabulary.md and the citation map, per STEP-4
- [ ] PR description: what shipped, the D-11 render outputs as AC evidence, deviations, manual check
```

## 10. Manual check

1. Create a new project. Open Source types: **Voters list** is listed with the document icon; its suggested fields read as AC-3.1, with the labels of AC-3.3. The Census type lists Database just before Format.
2. Add a Source of type Voters list titled "1949 federal election, St. Paul's". On the Source board, Jurisdiction, Election or register, and Repository are marked needed (AC-3.2). Set jurisdiction, election, electoral district, collection, call number, record group and repository to AC-1.1's values. On an Artifact set format, database title, provider, URL and accessed. On its Evidence graph set polling division, entry and item; give a Citation page 3.
3. The Citation's full, short and list citations read as AC-1.1 – AC-1.3.
4. Clear the record group on the Source: the full citation drops ", Record Group 113-B" and nothing else.
5. Add a Record book Source with AC-4.1's values: its full citation reads as AC-4.1; clear the database title and it reads as AC-4.2.
6. Without the app: the D-11 scratch renders of AC-1.1, AC-1.2, AC-1.3, AC-2.1, AC-2.2, AC-2.3, AC-4.1 and AC-4.2 each match the AC text exactly, and are pasted in the PR body.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Suggestion order differs from AC-3.1 | `suggestedKeys` gave AC-3.1 at the planning base; STEP-3's scratch render prints it |
| A copy-layer edit changes a format beyond the clause | STEP-2's two `rg` counts and the review of the diff |

**Stop and report if:**

- `suggestedKeys` derives a list other than AC-3.1's for `voters_list`.
- A D-11 render differs from its AC text.
- STEP-2's `rg` prints a hand copy of the copy clause other than `copyLayer`, or a format needs a change beyond the clause to use it.
- `TestInstall` or `TestSuggestedKeys` fails without an edit to them.
- `sourcetypes.ValidIconKeys` no longer holds `type_document`.

## 12. Open questions

None.

## 13. PR

**Title:** S16-79 — A seeded Voters list type cites a voter list down to the entry
**Body:** objective in one sentence; what shipped against US-1 – US-4; the D-11 render outputs as AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-79-voters-list-type.md`.
