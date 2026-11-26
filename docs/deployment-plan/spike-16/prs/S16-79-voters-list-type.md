# S16-79 — A seeded Voters list type cites a voter list down to the entry

**Status:** Blocked — on S16-78
**Spike / slice:** Spike 16 · Slice 6j — A Voters list type
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: a seeded type, its fields and formats are catalog data that today's Source type, board and citation views already show)
**Board:** —
**Depends on:** S16-78 (Install derives suggestions)
**Blocks:** —
**Branch:** `s16-79-voters-list-type`
**Version bump:** minor — a new Source type in new projects is a backward-compatible feature with no schema or wire change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [`docs/citation-formats.md`](../../../citation-formats.md) (syntax, groups, nearest-level reads); [`docs/seeded-vocabulary.md`](../../../seeded-vocabulary.md) § Implementation, § 2.1, § 2.2; [Spike 15 citation map](../../spike-15/evidence-explained-citation-map.md) chapter 9 ("Voter registrations and poll books") and § 6.8; working rules "(Batch 6) A seeded citation format is written to find the record again" and the Spike 15 rule "The seed is the product default"
**Planned:** 2026-11-26 against `origin/main` @ `0886b43` (fetch it; a local `main` may be older), with S16-78 as planned; the Suggestions rows of § 4 are refreshed when it lands
**Review:** [`S16-79-voters-list-type.review.md`](S16-79-voters-list-type.review.md) — Fits with changes · Ready with changes, 2 rounds; no blocker open; To user answered

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

**What stays.** Every other seeded type's citations render as today, except the database title in its copy layer; existing projects are not changed (rule "The seed is the product default").

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

**US-4.** As a researcher citing any record type seen in an online database, the database's title prints with the copy, so the reader finds the same database.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | The golden's full fixture (database title "Calder County Censuses, 1850–1900"), census full form | `1880 Westmark census, Calder County, Westmark, population schedule, ED 236, sub-district B-3, piece 1047, fol. 22, p. 14, schedule 9, dwelling 112, family 118, line 14, Ada Robins; "Calder County Censuses, 1850–1900," digital image, *Westmark Heritage* (https://example.org/calder/1880 : accessed 12 March 2025); citing county film 7, item 3.` |
| AC-4.2 | The golden after the copy-layer step | Exactly the twelve `full<TAB>full` lines of census, the three certificates, church register, record book, passenger list, case file, manuscript, government file, book and newspaper item change, each by `"Calder County Censuses, 1850–1900," ` inserted before `digital image`; no other line changes |
| AC-4.3 | A copy with no database title | Prints as today (`; digital image, *Westmark Heritage* (…)`), as the bare and the country renders without one show |
| AC-4.4 | The twelve types' suggestions | Each gains `database_title` just before `format` (S16-78 derives it) |

## 3. Scope

| In | Covered by |
| --- | --- |
| Seeded type `voters_list` with its three formats | STEP-3, AC-1.1 – AC-2.3 |
| Seeded fields `election`, `electoral_district`, `polling_division` | STEP-1, AC-3.3 |
| The type's suggestion list (derived) | STEP-3, AC-3.1 |
| One shared copy layer with the database title, used by every record type's full format | STEP-2, AC-4.1 – AC-4.4 |
| Golden render, literal country renders, registry and board tests | STEP-2, STEP-3, STEP-4 |
| Seeded vocabulary doc, citation map rows, the format rule in `add-seeded-vocabulary` | STEP-5 |

| Out | Home |
| --- | --- |
| The provider's image number ("image 37 of 412") in any seeded format | not planned (user, 2026-11-26: the URL and the path down to the entry find the image) |
| Adding the voters list to existing projects | not planned (rule "The seed is the product default": the product owner updates dogfood projects by hand) |
| A seeded province or state field | not planned (D-2: the electoral district or the jurisdiction carries it) |
| Any other change to another seeded type's formats | not planned |
| A voters-list-specific icon | not planned (D-1) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Types | `core/database/sourcevocab/registry.go` `seedTypes` | 26 types; voter lists have only `record_book` (P2 local: no electoral geography, no archive reference) |
| Fields | `core/database/sourcevocab/registry_fields.go` `seedFields` | 69 fields; the comment above it counts them; no election, electoral district or polling division |
| Suggestions | `core/database/sourcevocab/registry_suggestions.go` `suggestedKeys` (after S16-78) | `Install` derives each type's list from its formats; no hand list to edit |
| Copy layer | `core/database/sourcevocab/registry.go`: `[; {meta.format}, *{meta.provider}*][ ({meta.url}[ : accessed {meta.accessed_date}])]` typed by hand ten times (`certificateFormats`, census, church register, record book, passenger list, case file, manuscript, government file, book, newspaper item) | No format reads `database_title` |
| Field read checks | `core/database/sourcevocab/registry_test.go` `unreadFields`, `TestSeedFieldsAreRead` | `database_title` and `record_id` are read by no seeded format |
| Suggestion checks | `registry_test.go` `TestSuggestedKeys` (after S16-78), `TestSeededFormatsNeedOnlySuggestedFields`, `TestSeedPlaceFields` | Place map lists the government records that suggest `jurisdiction` |
| Golden | `core/database/sourcevocab/render_test.go` `TestSeedCitations` (with a literal census block), `fixture`, `fieldValues`, `fixtureTitles`; `core/database/sourcevocab/testdata/seed-citations.txt` | Six lines per type, plus court report's no-page line |
| Counts | `core/database/sourcevocab/sourcevocab_test.go` `TestInstall` (`26`, `69`); `core/database/citationrender/placeholders_test.go` (`26`); the comment above `seedFields` ("The 69 metadata fields: …") | `TestInstall` says "asserted once", yet two more places restate the counts |
| Board needs | `core/database/sourcemetadata/sourcemetadata_test.go` `seedExpectations`, `TestSeedAnnotations` | One row per seeded type; the test fails when a seeded type has no row, and ends with totals `neededAtSource != 31 \|\| neededBelow != 2*(31-4) \|\| unsuggested != 29 \|\| dates != 5` and their message |
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
| D-7 | One `copyLayer` const in `registry.go`: `[; ["{meta.database_title}," ]{meta.format}, *{meta.provider}*][ ({meta.url}[ : accessed {meta.accessed_date}])]`. Every format that types the copy layer by hand uses it, and so does `voters_list`. The database title is in quotes, the provider in italics, and the URL group stays beside the copy group, as the ten have it | User, 2026-11-26: share it, with the title everywhere; quoted as `website` quotes its title | Italic database title (Ancestry's own) — two italic runs side by side; nesting the URL in the copy group — changes the ten types' output beyond the title |
| D-8 | The formats read no `creator`, no `citing`, no `film_publication` | The jurisdiction and the series name who made the list; the archive layer is what "citing" would say; LAC and county films are cited by number | Reading them all — 3 more suggested fields no example needs |
| D-9 | The formats are exactly the text in **Go core** below | Rendered at planning against the engine (`citationformat.Render`) for AC-1.1 – AC-2.2 | — |
| D-10 | Registry placement: the type follows `passenger_list`; the three fields follow `subdistrict`; `copyLayer` sits beside `certificateFormats` | Keeps the registers together; golden lines land after `passenger_list` | Appending at the end |
| D-11 | The country renders are a literal table test over the installed catalog's stored formats (shape: Codebase fit) | The golden proves every seeded format on invented data; this proves the user's real case and two other countries | A second resolver type — copies `fixture` |
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
| `TestVotersListCitations` *(new)* | test | `TestSeedCitations` | The golden reads invented values; this pins literal citations from three countries |
| `seedRenderer` *(new)* | test helper | `TestSeedCitations`'s inline setup | Moved, not copied: both tests render through it |
| `copyLayer` *(new)* | const | `certificateFormats`, `journalArticleFormats` (shared format text) | It is that pattern, for the one clause eleven types share |

**Builds on.** `sourcevocab` registries and `Install` (skill `add-seeded-vocabulary`), the citation engine's groups and chains, #967's shape.
**Deletes.** The ten hand-typed copy layers (D-7); `database_title` leaves `unreadFields` (every record format now reads it), and the comment above it names only `record_id`.
**Next adds.** Another country's register is a new set of values, not a type. A researcher who wants a word before the division copies the type (`CopyType`) and edits its formats.

### Reach

None — a seeded type is one more row in lists that already show any number of types.

### Scale

None — 27 types and 72 fields install once at create; no list or loop changes.

### Edges

- **Assumptions.** `suggestedKeys` (S16-78) derives suggestions in first-read order; `TestSeedFieldsAreRead` requires every field read or listed in `unreadFields`; `TestSeedAnnotations` requires a row per seeded type; `TestSeedPlaceFields` allows `jurisdiction` only on government records. Each gains the new type (§ 8).
- **Neighbors.** The copy layer changes exactly the twelve full-fixture full lines (AC-4.2, STEP-2 check); the bare lines have no copy and stay. The new fixture values are read by no other format, so the type step adds lines and changes none (STEP-3 check).
- **Removed inputs.** An empty group drops with its punctuation; AC-2.1 (no page, reference or group) and AC-2.2 (no district, no database title) pin it. An empty `collection` falls to the Source title (AC-2.3).
- **Real data.** The golden renders the type in all three forms from the full and the bare fixture; the country table renders three real-shaped lists.
- **Untrusted size.** None — seeds are product data.

### Schema

None — no catalog change; `Install` writes rows.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcevocab` `registry.go` | `seedTypes` gains `voters_list` (D-1) after `passenger_list`, with the formats below |
| `registry_fields.go` | `seedFields` gains three rows after `subdistrict`; its comment drops the count (STEP-1) |
| `registry.go` | `copyLayer` *(new)* (D-7); the ten hand copies use it |

Formats (each one line in Go, a raw string; the full one joins `copyLayer`):

```text
Full:  {meta.jurisdiction}, {meta.election}[, {meta.electoral_district}][, {meta.polling_division}][, vol. {meta.volume}][, p. {meta.page|citation.page}][, line {meta.line_number}][, no. {meta.entry_number}][, {meta.item}]; {meta.collection|source.title}[, {meta.call_number}][, Record Group {meta.record_group}], {meta.repository}[; film {meta.film_number}]` + copyLayer + `.
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
Do: add the three rows of **Go core** after `subdistrict`. The comment above `seedFields` keeps no count and no breakdown: "The seeded metadata fields. `docs/seeded-vocabulary.md` § Implementation counts them and says where each came from. Each description says to enter the value as it should appear in a citation. Publisher and place of publication carry the unknown text \"n.p.\" and page carries \"unpaginated\"." Add fixture values `"election": "1882 general election"`, `"electoral_district": "Calder North"`, `"polling_division": "polling division 7"`. In `TestInstall` the literal condition and its `Fatalf` text become `len(seedTypes) != 26 || len(seedFields) != 72` and "the map says 26 and 72". Add the three keys to `unreadFields` for this step only; STEP-3 takes them out and rewrites its comment.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/...` passes.

**STEP-2 — One copy layer with the database title**
Files: `core/database/sourcevocab/registry.go`, `registry_test.go`, `render_test.go`, `core/database/sourcevocab/testdata/seed-citations.txt`.
Do: add `copyLayer` (D-7, D-10) and replace each of the ten hand copies with it (each format string splits at the old clause and joins `copyLayer`). In `registry_test.go`, `unreadFields` loses `database_title`. In `TestSeedCitations` the literal census full line becomes AC-4.1's text. Census now suggests `database_title` before `format`; `TestSuggestedKeys` (S16-78) pins no count, only `creator` first and `citing` last, so it stays green. Run `CGO_ENABLED=1 go test -tags fts5 -run TestSeedCitations ./core/database/sourcevocab -update`.
Check: `git diff core/database/sourcevocab/testdata/seed-citations.txt` shows the twelve changed lines of AC-4.2 and no other; `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/... ./core/database/sourcemetadata/... ./core/database/citationrender/...` passes.

**STEP-3 — Seed the type, its formats and its golden**
Files: `registry.go`, `registry_test.go`, `sourcevocab_test.go`, `render_test.go` (`fixtureTitles`), `core/database/sourcevocab/testdata/seed-citations.txt`, `core/database/citationrender/placeholders_test.go`, `core/database/sourcemetadata/sourcemetadata_test.go`.
Do: add `voters_list` (D-1, D-10) with the formats of **Go core**; its suggestions are derived (AC-3.1). In `registry_test.go`: `unreadFields` holds only `record_id` and its comment says so; `TestSeedPlaceFields` maps `voters_list` to `jurisdiction`. `TestInstall`'s condition and message read 27 and 72; `placeholders_test.go` stops restating the count: `len(types) != 26` becomes `len(types) == 0` with `t.Fatal("no seeded types")`, since its subtest checks that each type's formats load. `TestSeedAnnotations`'s closing totals become `neededAtSource != 34 || neededBelow != 2*(34-4) || unsuggested != 30 || dates != 5`, and its message "needed %d (want 34), needed below %d (60), unsuggested heads %d (30), needed dates %d (5)" (the row adds 3 needed, 3 on each of the two lower boards, 1 unsuggested head, no date). `fixtureTitles["voters_list"] = "Poll book of Calder North, 1882"`. `seedExpectations["voters_list"] = {needed: []string{"jurisdiction", "election", "repository"}, unsug: []string{"coverage:used"}}`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/... ./core/database/citationrender/... ./core/database/sourcemetadata/...` passes once the golden is rewritten: `CGO_ENABLED=1 go test -tags fts5 -run TestSeedCitations ./core/database/sourcevocab -update`. `git diff --stat` on `core/database/sourcevocab/testdata/seed-citations.txt`, against STEP-2's commit, shows 6 insertions and 0 deletions, after the `passenger_list` lines; the `voters_list full full` line reads `Calder County, Westmark, 1882 general election, Calder North, polling division 7, vol. 3, p. 14, line 14, no. 57, Ada Robins; Venn Family Papers, MS 1123, Record Group 45, Calder County Archives, Port Ellis; film 1022345; "Calder County Censuses, 1850–1900," digital image, *Westmark Heritage* (https://example.org/calder/1880 : accessed 12 March 2025).`

**STEP-4 — The country renders**
Files: `core/database/sourcevocab/render_test.go`.
Do: move `TestSeedCitations`'s setup (create, `install`, the field id → key map, `sourcetypes.Lookup` per seeded type, `storedFormats`, `Parse`, `Render`, `plainWithItalics`) into `seedRenderer(t *testing.T) func(typeKey string, fx fixture, form citationformat.Form) string` *(new)* in `render_test.go`; it creates and installs one catalog (closed by `t.Cleanup`), builds the key map once, looks up the type and its stored formats on each call, fills `fx.keys` itself and fails the test on a diagnostic. `TestSeedCitations` renders through it, its lines and literal census block unchanged. Add `values map[string]string` to `fixture`: when non-nil, `Resolve` answers a metadata field from it by key (a key it lacks answers `citationformat.Value{}`), ignores `bare`, `noPage` and the per-type creator, and built-ins answer as today. Add `TestVotersListCitations` *(new)*, table-driven over T-1 – T-4, through `seedRenderer`: each case's listed forms compare with the AC text exactly; T-4 also asserts the full form contains its substring.
Check: `CGO_ENABLED=1 go test -tags fts5 -run 'TestVotersListCitations|TestSeedCitations' ./core/database/sourcevocab` passes, and `git diff` on `core/database/sourcevocab/testdata/seed-citations.txt` is empty after STEP-3's commit.

**STEP-5 — Docs and version**
Files: `docs/seeded-vocabulary.md`, `.agents/skills/add-seeded-vocabulary/SKILL.md`, `docs/deployment-plan/spike-15/evidence-explained-citation-map.md`, `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan.
Do:
- `docs/seeded-vocabulary.md` line 83: "26 types" → "27 types"; "69 fields" → "72 fields"; "The 69 are the map's 64, plus `subdistrict` for a census sub-district (Canada), printed after the enumeration district when set (user, 2026-11-24), plus four place fields" → "The 72 are the map's 64, plus `subdistrict` for a census sub-district (Canada), printed after the enumeration district when set (user, 2026-11-24), plus `election`, `electoral_district` and `polling_division` for the voters list, whose values carry the list's own words (user, 2026-11-26), plus four place fields"; the government-records parenthesis "(census, the three certificates, record book, case file, statute)" gains "voters list" after "record book". § 2.1: `voters_list` after `passenger_list`. § 2.2: the three keys on the `source` line after `subdistrict`; after its sentence "`url` and `accessed_date` describe the copy a researcher used; the bytes of a capture still live on an Artifact/File." add "Every record type's full format prints that copy through one shared clause, `copyLayer` in `registry.go`: `\"database title,\" format, *provider* (url : accessed date)`, each part when set (user, 2026-11-26)."
- `docs/deployment-plan/spike-15/evidence-explained-citation-map.md`: the chapter 9 row "Voter registrations and poll books | P2 | |" becomes "Voter registrations and poll books | `voters_list` (P2, national variant) | Election, electoral district, polling division, page, entry; series, reference, record group, archive"; in § 6.8 "Source types", "26 types." → "27 types." and a row after `passenger_list`: "| `voters_list` | Voters list | P2 (national) | Voters lists, poll books, registers of electors, great registers |". Leave the rest of that file alone: § 6.8 "Existing infrastructure" (the 64 fields and 26 types it planned), "Fields" ("64 fields", its table) and the Spike 15 `README.md` and `deployment-plan.md` are Spike 15's record of what it planned, as #967 left them.
- `.agents/skills/add-seeded-vocabulary/SKILL.md` § Source vocabulary, step 1, after the `seedTypes` bullet: "A record type's full format reads general to specific: every locator from the jurisdiction down to the entry, then the archive that holds the original, then the copy the researcher viewed, through the shared `copyLayer`. Where a level's word differs by country (district, ward, precinct), the value carries the record's word and the format adds none. A type built for a real record also gets literal renders of that record beside the golden, through `seedRenderer` (`TestVotersListCitations`). Rule: Spike 16 \"(Batch 6) A seeded citation format is written to find the record again\"."
- Version: `VERSION`, `core/version.go` `Version` and every `MARKETING_VERSION` in `macos/Provenencia.xcodeproj/project.pbxproj` move to the next minor of `origin/main`'s `VERSION` at the time (0.44.0 from 0.43.0), in one commit.
- After the PR is open: this plan's status "Landed in [#N](https://github.com/Jake-Robins-Studios/provenencia/pull/N) (date)" with a Landed note; the map row's status `Landed #N`; `completed.md` gets `## S16-79 — A seeded Voters list type cites a voter list down to the entry` above the newest entry, then `**Landed <date>** in [#N](https://github.com/Jake-Robins-Studios/provenencia/pull/N).` and two sentences: new projects seed a Voters list type whose citation names the election, district, polling division, page and entry, then the archive, then the copy, in any country's words; every record type's citation prints the online database's title with the copy.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-79-voters-list-type.md` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Seed a Voters list type whose citation reaches the entry, the archive and the copy.").

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcevocab/render_test.go` `TestVotersListCitations` *(new)* | AC-1.1's values → AC-1.1, AC-1.2, AC-1.3 texts | AC-1.1 – AC-1.3, D-3, D-4, D-7 |
| T-2 | Go | same, case "register of electors" | AC-2.1's values → its full and list texts | AC-2.1, D-2 |
| T-3 | Go | same, case "great register" | AC-2.2's values → its full and short texts | AC-2.2, D-2 |
| T-4 | Go | same, case "no collection" | AC-1.1's values without `collection`; the Source title is the fixture's `fixtureTitles["voters_list"]`, "Poll book of Calder North, 1882" → full contains `Ada Robins; Poll book of Calder North, 1882, R1003-6-3-E`; list is `Canada. Poll book of Calder North, 1882. R1003-6-3-E. Record Group 113-B. Library and Archives Canada, Ottawa.` | AC-2.3 |
| T-5 | Go | `render_test.go` `TestSeedCitations` + golden | STEP-2: the twelve copy lines and the literal census line (AC-4.1); STEP-3: six `voters_list` lines, nothing else | AC-4.1, AC-4.2, D-7, D-9, D-10 |
| T-6 | Go | `registry_test.go` `TestSuggestedKeys`, `TestSeedFieldsAreRead`, `TestSeedTypes`, `TestSeededFormatsNeedOnlySuggestedFields`, `TestSeedPlaceFields` | The new type and fields pass every registry rule; the twelve types' derived lists hold `database_title` before `format` | AC-3.1, AC-4.4 |
| T-7 | Go | `sourcevocab_test.go` `TestInstall` | 27 types, 72 fields installed | AC-3.3 |
| T-9 | Go | `core/database/citationrender/placeholders_test.go` | Every seeded type's formats load, the voters list among them; no count | AC-3.3 |
| T-8 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSeedAnnotations` | `voters_list` row of STEP-3 | AC-3.2 |
| T-10 | Go | `TestVotersListCitations` case "great register" (AC-2.2, no database title) and the golden's bare lines | No title → the copy prints as before | AC-4.3 |

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
5. Add a Census Source with an Artifact whose database title, format and provider are set: its full citation prints `"<title>," digital image, *<provider>*`; clear the title and it prints as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Suggestion order differs from AC-3.1 | `suggestedKeys` derives it; the AC list was derived from the formats by hand at planning |
| Board expectation differs from STEP-2's row | `TestSeedAnnotations` measures it |

**Stop and report if:**

- `suggestedKeys` derives a list other than AC-3.1's for `voters_list`, or a census list without `database_title` just before `format`.
- S16-78 has not landed, or landed without `suggestedKeys`.
- STEP-2's `-update` changes a line other than AC-4.2's twelve.
- `TestSeedAnnotations` measures a `voters_list` row other than STEP-2's.
- STEP-3's `-update` changes any line that is not a `voters_list` line.
- A render of T-1 – T-4 differs from its AC text.
- `sourcetypes.ValidIconKeys` no longer holds `type_document`.

## 12. Open questions

None.

## 13. PR

**Title:** S16-79 — A seeded Voters list type cites a voter list down to the entry
**Body:** objective in one sentence; what shipped against US-1 – US-3; the T-1 – T-4 renders as AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-79-voters-list-type.md`.
