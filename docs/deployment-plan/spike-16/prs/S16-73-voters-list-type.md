# S16-73 — A seeded Voters list type cites a voter list down to the entry

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 6j — A Voters list type
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: a seeded type, its fields and formats are catalog data that today's Source type, board and citation views already show)
**Board:** —
**Depends on:** —
**Blocks:** —
**Branch:** `s16-73-voters-list-type`
**Version bump:** minor — a new Source type in new projects is a backward-compatible feature with no schema or wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [`docs/citation-formats.md`](../../../citation-formats.md) (syntax, groups, nearest-level reads); [`docs/seeded-vocabulary.md`](../../../seeded-vocabulary.md) § Implementation, § 2.1, § 2.2; [Spike 15 citation map](../../spike-15/evidence-explained-citation-map.md) chapter 9 ("Voter registrations and poll books") and § 6.8; working rules "(Batch 6) A seeded citation format is written to find the record again" and the Spike 15 rule "The seed is the product default"
**Planned:** 2026-11-26 against `main` @ `0886b43`
**Review:** — (not reviewed yet)

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

**What stays.** Every other seeded type, field, suggestion and format renders as today; existing projects are not changed (rule "The seed is the product default").

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
| AC-2.3 | A Voters list Source with no collection | The full and list forms print the Source title where the series goes |

**US-3.** As a researcher starting a Voters list Source, the board offers exactly the fields its formats read, and says which ones a citation needs.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | A new project's Voters list type | It suggests, in order: `jurisdiction`, `election`, `electoral_district`, `polling_division`, `volume`, `page`, `line_number`, `entry_number`, `item`, `collection`, `call_number`, `record_group`, `repository`, `film_number`, `database_title`, `format`, `provider`, `url`, `accessed_date` (19 fields) |
| AC-3.2 | A Voters list Source's board | `jurisdiction`, `election` and `repository` are marked needed; `coverage` heads the board as an unsuggested used field; no Source date annotation |
| AC-3.3 | A new project | It holds 27 seeded Source types and 72 seeded fields; the three new fields have the labels "Election or register", "Electoral district" and "Polling division" |

## 3. Scope

| In | Covered by |
| --- | --- |
| Seeded type `voters_list` with its three formats | STEP-2, AC-1.1 – AC-2.3 |
| Seeded fields `election`, `electoral_district`, `polling_division` | STEP-1, AC-3.3 |
| The type's suggestion list | STEP-2, AC-3.1 |
| `database_title` read by a seeded format for the first time | STEP-2, AC-1.1 |
| Golden render, literal country renders, registry and board tests | STEP-3, STEP-4 |
| Seeded vocabulary doc, citation map rows | STEP-5 |

| Out | Home |
| --- | --- |
| The provider's image number ("image 37 of 412") in any seeded format | not planned (user, 2026-11-26: the URL and the path down to the entry find the image) |
| Adding the voters list to existing projects | not planned (rule "The seed is the product default": the product owner updates dogfood projects by hand) |
| A seeded province or state field | not planned (D-2: the electoral district or the jurisdiction carries it) |
| Changing `record_book`, `government_file` or any other seeded type's formats | not planned |
| A voters-list-specific icon | not planned (D-1) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Types | `core/database/sourcevocab/registry.go` `seedTypes` | 26 types; voter lists have only `record_book` (P2 local: no electoral geography, no archive reference) |
| Fields | `core/database/sourcevocab/registry_fields.go` `seedFields` | 69 fields; the comment above it counts them; no election, electoral district or polling division |
| Suggestions | `core/database/sourcevocab/registry_suggestions.go` `seedSuggestions` | One list per type, derived from its formats |
| Field read checks | `core/database/sourcevocab/registry_test.go` `unreadFields`, `TestSeedFieldsAreRead` | `database_title` and `record_id` are read by no seeded format |
| Suggestion checks | `registry_test.go` `TestSeedSuggestionsFollowFormats`, `TestSeededFormatsNeedOnlySuggestedFields`, `TestSeedPlaceFields` | Place map lists the government records that suggest `jurisdiction` |
| Golden | `core/database/sourcevocab/render_test.go` `TestSeedCitations`, `fixture`, `fieldValues`, `fixtureTitles`; `core/database/sourcevocab/testdata/seed-citations.txt` | 156 lines, six per type |
| Counts | `core/database/sourcevocab/sourcevocab_test.go` `TestInstall` (`26`, `69`); `core/database/citationrender/placeholders_test.go` (`26`) | Literal counts |
| Board needs | `core/database/sourcemetadata/sourcemetadata_test.go` `seedExpectations`, `TestSeedAnnotations` | One row per seeded type; the test fails when a seeded type has no row |
| Docs | `docs/seeded-vocabulary.md` § Implementation, § 2.1, § 2.2; `docs/deployment-plan/spike-15/evidence-explained-citation-map.md` chapter 9 table, § 6.8 "Source types" and "Fields" | 26 types, 69 fields; voter lists under P2 |

**Precedent.** [#967](https://github.com/Jake-Robins-Studios/provenencia/pull/967) (`5314ca4`, "Census citations print an optional sub-district after the enumeration district.") added a seeded field and changed formats: registry, suggestion, counts in `TestInstall`, fixture value, golden via `-update`, `seeded-vocabulary.md` and the citation map in one commit. Copy its shape; this PR adds a type as well.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | One general type: key `voters_list`, label "Voters list", description "A voters list, poll book or register of electors made for an election or a registration year.", icon `type_document` (as `passenger_list`, the other national list of names) | User, 2026-11-26: one generic voter list | A Canada-only type — the user asked for one type for every country; a new icon — needs an asset, which is chrome |
| D-2 | The election, electoral district and polling division values carry the list's own words; the formats add no word before them ("urban polling division 52", "precinct 3", "Highbury ward, polling district B"). A province or state goes in the electoral district value or the jurisdiction | User, 2026-11-26: the format flexes to other countries' fields; each country names these levels differently | A word in the format ("polling division {meta.polling_division}") — wrong for a precinct or a ward; more fields per country — the board grows for every researcher |
| D-3 | Full form order: the record and its locators (jurisdiction, election, district, division, volume, page, line, entry, item); then the archive as one unit (series, reference, record group, repository); then microfilm; then the online copy | User, 2026-11-26: archive first, copy after; each layer is complete and reads general to specific inside the record | Copy first with "citing" (Ancestry's and census's shape); repository last (`government_file`'s shape) |
| D-4 | The record group prints `Record Group {meta.record_group}` | User, 2026-11-26: as `government_file`, the researcher types "113-B" | Printing the value bare ("RG113-B") |
| D-5 | Needed (outside any group): `jurisdiction` and `election` in all three forms, `repository` in full and list. The series reads `{meta.collection\|source.title}`. Everything else is in a group | Rule "(Batch 6) A seeded citation format is written to find the record again": without the jurisdiction, the election and the holder no one finds the list | Repository optional — a voter list in private hands is rare and the researcher's own copy of the type can drop it |
| D-6 | No `source.date` in any form; the election value carries the year | The year in both the election and a date prints twice | `{source.date:year}` as census does — a register's year and an election's date differ, and "1949 1949 federal election" reads wrong |
| D-7 | The copy layer is `["{meta.database_title}," ]{meta.format}, *{meta.provider}*` with the URL group after it: the database title in quotes, the provider in italics | As the `website` type quotes its title and italicizes the site; this is the first seeded format to read `database_title` | Italic database title (Ancestry's own) — two italic runs side by side |
| D-8 | The formats read no `creator`, no `citing`, no `film_publication` | The jurisdiction and the series name who made the list; the archive layer is what "citing" would say; LAC and county films are cited by number | Reading them all — 3 more suggested fields no example needs |
| D-9 | The formats are exactly the text in **Go core** below | Rendered at planning against the engine (`citationformat.Render`) for AC-1.1 – AC-2.2 | — |
| D-10 | Registry placement: the type and its suggestion follow `passenger_list`; the three fields follow `subdistrict` | Keeps the registers together; golden lines land after `passenger_list` | Appending at the end |
| D-11 | The country renders (AC-1.x, AC-2.x) are one new table test over the installed catalog's stored formats, reusing `fixture` with a new `values` map | The golden proves every seeded format against invented data; this proves the user's real case and two other countries literally | A second resolver type — copies `fixture` |
| D-12 | New projects only | Spike 15 rule "The seed is the product default" | A migration insert — the skill forbids seed `INSERT`s |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `voters_list` *(new)* | seeded type | `record_book`, `passenger_list`, `government_file` | `record_book` is local and has no electoral geography or archive reference; `passenger_list` reads no reference or record group; `government_file` reads no page, line or entry |
| `election` *(new)* | seeded field | `schedule`, `source.date` | `schedule` is described as a census schedule; the date cannot hold "spring register" or "federal" |
| `electoral_district` *(new)* | seeded field | `enumeration_district` | Its description and the census format's "ED" say census; a voter list board would mislead |
| `polling_division` *(new)* | seeded field | `subdistrict` | Census sub-district by description and by the census format's "sub-district" word |
| `fixture.values` *(new)* | test field | `fieldValues` | One map shared by every type's golden; the country cases need their own values |
| `TestVotersListCitations` *(new)* | test | `TestSeedCitations` | The golden reads invented values; this pins three literal citations |

**Builds on.** `sourcevocab` registries and `Install` (skill `add-seeded-vocabulary`), the citation engine's groups and chains, #967's shape.
**Deletes.** `database_title` leaves `unreadFields` (a format now reads it); the comment above it names only `record_id`.
**Next adds.** Another country's register is a new set of values, not a type. A researcher who wants a word before the division copies the type (`CopyType`) and edits its formats.

### Reach

None — a seeded type is one more row in lists that already show any number of types.

### Scale

None — 27 types and 72 fields install once at create; no list or loop changes.

### Edges

- **Assumptions.** `TestSeedSuggestionsFollowFormats` derives suggestions in first-read order; `TestSeedFieldsAreRead` requires every field read or listed in `unreadFields`; `TestSeedAnnotations` requires a row per seeded type; `TestSeedPlaceFields` allows `jurisdiction` only on government records. Each gains the new type (§ 8).
- **Neighbors.** The new fixture values (`election`, `electoral_district`, `polling_division`) are read by no other format, so every other golden line stays byte for byte (STEP-3 check).
- **Removed inputs.** An empty group drops with its punctuation; AC-2.1 (no page, reference or group) and AC-2.2 (no district, no database title) pin it. An empty `collection` falls to the Source title (AC-2.3).
- **Real data.** The golden renders the type in all three forms from the full and the bare fixture; the country table renders three real-shaped lists.
- **Untrusted size.** None — seeds are product data.

### Schema

None — no catalog change; `Install` writes rows.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcevocab` `registry.go` | `seedTypes` gains `voters_list` (D-1) after `passenger_list`, with the formats below |
| `registry_fields.go` | `seedFields` gains three rows after `subdistrict`; the comment counts 72: the map's 64, `subdistrict`, the four place fields and the three voters list fields |
| `registry_suggestions.go` | `seedSuggestions` gains the AC-3.1 list after `passenger_list` |

Formats (each one line in Go, a raw string):

```text
Full:  {meta.jurisdiction}, {meta.election}[, {meta.electoral_district}][, {meta.polling_division}][, vol. {meta.volume}][, p. {meta.page|citation.page}][, line {meta.line_number}][, no. {meta.entry_number}][, {meta.item}]; {meta.collection|source.title}[, {meta.call_number}][, Record Group {meta.record_group}], {meta.repository}[; film {meta.film_number}][; ["{meta.database_title}," ]{meta.format}, *{meta.provider}*[ ({meta.url}[ : accessed {meta.accessed_date}])]].
Short: {meta.jurisdiction}, {meta.election}[, {meta.electoral_district}][, {meta.polling_division}][, vol. {meta.volume}][, p. {meta.page|citation.page}][, line {meta.line_number}][, no. {meta.entry_number}][, {meta.item}].
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
Files: `core/database/sourcevocab/registry_fields.go`, `core/database/sourcevocab/render_test.go` (`fieldValues`), `core/database/sourcevocab/sourcevocab_test.go` (`TestInstall` counts). Skill: `add-seeded-vocabulary`.
Do: add the three rows of **Go core** after `subdistrict`; update the count comment. Add fixture values `"election": "1882 general election"`, `"electoral_district": "Calder North"`, `"polling_division": "polling division 7"`. `TestInstall` counts stay 26 types and become 72 fields until STEP-2. Add the three keys to `unreadFields` for this step only, with the comment unchanged.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/...` passes.

**STEP-2 — Seed the type, its formats and its suggestions**
Files: `registry.go`, `registry_suggestions.go`, `registry_test.go`, `sourcevocab_test.go`, `render_test.go` (`fixtureTitles`), `core/database/citationrender/placeholders_test.go`, `core/database/sourcemetadata/sourcemetadata_test.go`.
Do: add `voters_list` (D-1, D-10) with the formats of **Go core**; add its suggestion list (AC-3.1). In `registry_test.go`: `unreadFields` holds only `record_id` and its comment says so; `TestSeedPlaceFields` maps `voters_list` to `jurisdiction`. `TestInstall` counts 27 and 72; `placeholders_test.go` counts 27. `fixtureTitles["voters_list"] = "Poll book of Calder North, 1882"`. `seedExpectations["voters_list"] = {needed: []string{"jurisdiction", "election", "repository"}, unsug: []string{"coverage:used"}}`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/... ./core/database/citationrender/... ./core/database/sourcemetadata/...` passes except `TestSeedCitations` (six new lines, STEP-3).

**STEP-3 — Golden**
Files: `core/database/sourcevocab/testdata/seed-citations.txt`.
Do: `CGO_ENABLED=1 go test -tags fts5 -run TestSeedCitations ./core/database/sourcevocab -update`.
Check: `git diff --stat` on the file shows 6 insertions and 0 deletions, after the `passenger_list` lines; the `voters_list full full` line reads `Calder County, Westmark, 1882 general election, Calder North, polling division 7, vol. 3, p. 14, line 14, no. 57, Ada Robins; Venn Family Papers, MS 1123, Record Group 45, Calder County Archives, Port Ellis; film 1022345; "Calder County Censuses, 1850–1900," digital image, *Westmark Heritage* (https://example.org/calder/1880 : accessed 12 March 2025).`

**STEP-4 — The country renders**
Files: `core/database/sourcevocab/render_test.go`.
Do: add `values map[string]string` to `fixture`: when non-nil, `Resolve` answers a field from it by key, and `creator` gets no per-type default. Add `TestVotersListCitations` *(new)*: install into a new catalog, read the stored `voters_list` formats as `TestSeedCitations` does, and render the cases of § 8 T-1 – T-3 with `plainWithItalics`.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestVotersListCitations|TestSeedCitations' ./core/database/sourcevocab` passes.

**STEP-5 — Docs**
Files: `docs/seeded-vocabulary.md`, `docs/deployment-plan/spike-15/evidence-explained-citation-map.md`, `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan.
Do: `seeded-vocabulary.md` § Implementation: 27 types and 72 fields; add after the `subdistrict` clause "plus `election`, `electoral_district` and `polling_division` for the voters list, whose values carry the list's own words (user, 2026-11-26)"; add "voters list" to the government records that keep `jurisdiction`. § 2.1: `voters_list` after `passenger_list`. § 2.2: the three keys on the `source` line after `subdistrict`. Citation map: chapter 9's voter row Pattern becomes "`voters_list` (P2, national variant)" with Notes "Election, electoral district, polling division, page, entry; series, reference, record group, archive"; § 6.8 "Source types": "27 types." and a `voters_list` row after `passenger_list` (Voters list · P2 (national) · Voters lists, poll books, registers of electors, great registers); § 6.8 "Fields": the three keys in the "Record numbers" row. Then the DoD's docs lines.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-73-voters-list-type.md` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Seed a Voters list type whose citation reaches the entry, the archive and the copy.").

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcevocab/render_test.go` `TestVotersListCitations` *(new)* | AC-1.1's values → AC-1.1, AC-1.2, AC-1.3 texts | AC-1.1 – AC-1.3, D-3, D-4, D-7 |
| T-2 | Go | same, case "register of electors" | AC-2.1's values → its full and list texts | AC-2.1, D-2 |
| T-3 | Go | same, case "great register" | AC-2.2's values → its full and short texts | AC-2.2, D-2 |
| T-4 | Go | same, case "no collection" | AC-1.1's values without `collection`; the Source title is the fixture's `fixtureTitles["voters_list"]`, "Poll book of Calder North, 1882" → full contains `Ada Robins; Poll book of Calder North, 1882, R1003-6-3-E`; list is `Canada. Poll book of Calder North, 1882. R1003-6-3-E. Record Group 113-B. Library and Archives Canada, Ottawa.` | AC-2.3 |
| T-5 | Go | `render_test.go` `TestSeedCitations` + golden | Six `voters_list` lines; every other line unchanged | D-9, D-10 |
| T-6 | Go | `registry_test.go` `TestSeedSuggestionsFollowFormats`, `TestSeedFieldsAreRead`, `TestSeedTypes`, `TestSeededFormatsNeedOnlySuggestedFields`, `TestSeedPlaceFields` | The new type and fields pass every registry rule | AC-3.1 |
| T-7 | Go | `sourcevocab_test.go` `TestInstall` | 27 types, 72 fields installed | AC-3.3 |
| T-8 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSeedAnnotations` | `voters_list` row of STEP-2 | AC-3.2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestSeedAnnotations`, `placeholders_test.go`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none: labels are catalog data
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — no brief
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together): minor
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated: docs/seeded-vocabulary.md and the citation map, per STEP-5
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Create a new project. Open Source types: **Voters list** is listed with the document icon.
2. Add a Source of type Voters list titled "1949 federal election, St. Paul's". On the Source board set jurisdiction, election, electoral district, collection, call number, record group and repository to AC-1.1's values. On an Artifact set format, database title, provider, URL and accessed. On its Evidence graph set polling division, entry and item; give a Citation page 3.
3. The Citation's full, short and list citations read as AC-1.1 – AC-1.3.
4. Clear the record group on the Source: the full citation drops ", Record Group 113-B" and nothing else.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Suggestion order differs from AC-3.1 | `TestSeedSuggestionsFollowFormats` derives it; the AC list was derived from the formats by hand at planning |
| Board expectation differs from STEP-2's row | `TestSeedAnnotations` measures it |

**Stop and report if:**

- `TestSeedSuggestionsFollowFormats` derives a list other than AC-3.1's.
- `TestSeedAnnotations` measures a `voters_list` row other than STEP-2's.
- STEP-3's `-update` changes any line that is not a `voters_list` line.
- A render of T-1 – T-4 differs from its AC text.
- `sourcetypes.ValidIconKeys` no longer holds `type_document`.

## 12. Open questions

None.

## 13. PR

**Title:** S16-73 — A seeded Voters list type cites a voter list down to the entry
**Body:** objective in one sentence; what shipped against US-1 – US-3; the T-1 – T-4 renders as AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-73-voters-list-type.md`.
