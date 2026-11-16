# Deployment plan — Spike 15

Spike 15 makes Sources carry what a standard genealogical citation needs and turns it into citations. It pulls in every design doc in this folder: the Source date ([`source-provenance-date.md`](source-provenance-date.md)), citation formats and the seed ([`evidence-explained-citation-map.md`](evidence-explained-citation-map.md), which supersedes the arrival steps of [`citation-formats.md`](citation-formats.md)), moving an Artifact ([`move-artifact-between-sources.md`](move-artifact-between-sources.md)), the privacy toggle ([`2026-10-27-source-privacy-toggle.md`](2026-10-27-source-privacy-toggle.md)), the credibility field ([`2026-10-18-credibility-field-truncates-and-ignores-enter.md`](2026-10-18-credibility-field-truncates-and-ignores-enter.md)) and the metadata rethink ([`2026-10-25-rethink-source-metadata-and-type-suggestions.md`](2026-10-25-rethink-source-metadata-and-type-suggestions.md), settled: metadata stays). One behavior, one PR.

**One brief, one PR.** A PR that adds, changes or removes chrome waits on its own brief; a removal is gated too. A brief gates exactly one PR, and draws only what that PR ships; a later PR on the same view gets its own brief (user, 2026-11-13). Briefs and PR plans are written just before the PR ([`add-design-brief`](../../../.agents/skills/add-design-brief/SKILL.md), [`plan-pr`](../../../.agents/skills/plan-pr/SKILL.md)). Only a PR whose views look the same before and after is not gated. S15-D1 and S15-D14 were written before this rule and gate several PRs; they stay as written.

## Status

**Open.** Per-PR status is the [PR map](#pr-map).

> **Goal of this spike:** a researcher gets a correct, editable *Evidence Explained*-style citation for any Citation from data entered once on the Source, the Artifact and the Evidence graph, and can re-file Artifacts between Sources.

## Goal (dogfood bar)

**By spike close**, each of these is true on a real project:

1. **A Source has a date.** Set, change and clear it on the Source page with the app's date entry. The Sources list shows it on each row and sorts by it, undated last. The Person page's Sources section shows it on each Source.
2. **A Source can be marked not public.** A switch on the Source page; it is saved and survives reopening. Nothing else changes yet.
3. **Copy and item details live where they belong.** On a census Source, the Artifact holds provider, URL and accessed date (also offered when the Artifact is added), and each household's Evidence graph holds dwelling, family and line. The citation composer gains only the printed page.
4. **Citations read like citations.** A census Citation's provenance sheet reads "1880 U.S. census, Ottawa County, Kansas, population schedule, ED 236, p. 14, dwelling 112, family 118, Ada Robins; digital image, *Ancestry* (… : accessed 12 March 2025)". Copy citation gives the full or short form. Each metadata board flags the fields its type's citation needs and are empty (the census Artifact: "URL, needed for citation"); the Source page copies its source-list entry.
5. **Formats are the researcher's.** Editing the census full format on its Source type page updates a live preview against a real Source. A new type can **Copy from** an existing one and starts with its formats and suggestions.
6. **A new project knows the citation styles.** It starts with the 26 seeded types, 63 fields, suggestions at each level and formats (map § 6.8). The product owner's dogfood project gets them by running Install once.
7. **One household, one citation.** The five Citations drawn on one household row show as one citation, with the highlighted pieces beneath it, on the provenance sheet and in the Person page's Sources section.
8. **An Artifact moves with its graphs.** **Move to another Source…** from an Artifact or a graph shows everything that moves together, keeps every ref, and the moved Citations then read the target Source.
10. **A heavy provenance sheet stays quick.** Person, Event and Place rows all open the same provenance sheet (the Why accordion is gone); a page loads without any record behind its values; a value's records arrive when its sheet opens, with a loading state and a Try again on failure; a value with 1,200 records opens on a page of rows with Show more.
9. **The credibility argument behaves like a text area.** A long argument wraps, and it saves with the Save button, like the Source description.
11. **A researcher can say a value is unknown or supplied.** A book Source with no place of publication marked unknown cites "n.p."; an undated letter dated from its postmark cites "[12 March 1880]"; marked-unknown values are no longer flagged as needed. A date in a citation reads "ca. 1880", where the app's pages read "abt 1880".

**Scale** (user, 2026-11-09). A census Source with **60 household graphs of 1 to 10 Citations each** (600 Citations); a Person page citing **30 Sources**, so a provenance sheet or Sources section renders up to **300 citations**; a move bundle of **5 Artifacts and 5 graphs**; up to **1,200 records on one value** (a crafted project, or a Place's name row; [`provenance-loading.md`](provenance-loading.md)); the seed's **26 types and 63 fields**. Also: a project of **3,000 Sources** (Spike 16's Scale) for the Sources list; a Source with up to **60 Artifacts**; a move bundle's graphs holding up to **100 Subjects** in all; a format or field edit on a type used by **500 Sources**. Plans write their fan-out against these.

## Where the notes went

| Dogfood note or idea | PR | Brief |
| --- | --- | --- |
| [Credibility field truncates and ignores Enter](2026-10-18-credibility-field-truncates-and-ignores-enter.md) | S15-01 | — (working rule) |
| [Source privacy toggle](2026-10-27-source-privacy-toggle.md) | S15-02, S15-03 | S15-D1 |
| [Source provenance date](source-provenance-date.md) | S15-02, S15-03, S15-04, S15-05 | S15-D1, S15-D2, S15-D3 |
| [Rethink Source metadata](2026-10-25-rethink-source-metadata-and-type-suggestions.md) | Settled: metadata stays (map § 6.1); S15-06 – S15-12 build on it | — |
| [Evidence Explained citation map](evidence-explained-citation-map.md) | S15-06 – S15-23 | S15-D1, S15-D3 – S15-D9 |
| User review of the citation preview (2026-11-13): too much space for a rare copy; missing fields belong where they are fixed; unknown and supplied values | S15-23 (re-scoped), S15-37 – S15-46, S15-14 – S15-16, S15-19 | S15-D19 – S15-D25 |
| User review of S15-12's brief (2026-11-14): the type's side pane has no room for three suggestion lists and three formats; a type gets its own page, the list loses its side pane, Add type becomes a dialog | S15-47, S15-48, S15-49, S15-12, S15-17, S15-18 | S15-D26, S15-D27, S15-D28, S15-D6, S15-D7 |
| [Move an Artifact to another Source](move-artifact-between-sources.md) | S15-24, S15-25 | S15-D1, S15-D10, S15-D14 |
| User review of S15-09 (2026-11-12): the Artifact cards grow too tall with their metadata; edit in a sheet; thumbnails pixelated | S15-33 – S15-36, S15-10 | S15-D14 |
| [Provenance loading and drawing](provenance-loading.md), from `ideas/provenance.md` (retired 2026-11-09) | S15-27, S15-28, S15-29 | S15-D9 |

**Back in the ideas folder** — [`ideas/source-type-packages.md`](../../ideas/source-type-packages.md): citation styles as installable packages. [`ideas/copy-source-list-entries.md`](../../ideas/copy-source-list-entries.md): copying the source-list entries of several Sources at once. [`source-structure-later.md`](source-structure-later.md) stays in this folder as reference and moves to `ideas/` at close: nested Sources, derivation links, named templates, per-graph credibility.

## Working rules

These are the calls for this spike. PR plans treat them as binding.

- **Follow the *Evidence Explained* style; never copy the book.** Seeded formats, examples, tests, fixtures and UI copy are written for Provenencia; every example uses invented people, places and records; no product or feature name uses the book's name; nothing is called official. The full rule: [`README.md`](README.md#working-rules). Binds S15-14, S15-19, S15-20 and every PR with copy.
- **The Source date is one optional DateValue on `sources`.** `sources.date_value_id` into `date_values` ([`add-date-value`](../../../.agents/skills/add-date-value/SKILL.md)); its meaning is the original publication, or when the record was made; no backfill. Copy Source carries it only when the Copy form's Published date tick is on (S15-32; user, 2026-11-09). The Sources list sorts by it, undated last. Metadata dates stay text. Binds S15-02 – S15-05. Design: [`source-provenance-date.md`](source-provenance-date.md).
- **Not public is a stored switch and nothing else.** `sources.is_public INTEGER NOT NULL DEFAULT 1`, toggled on the Source page by a switch labeled "Private", off by default (user, 2026-11-09). No filtering, hiding, list glyph, cascade or Copy Source carry. Binds S15-02, S15-03. Design: [`2026-10-27-source-privacy-toggle.md`](2026-10-27-source-privacy-toggle.md).
- **Metadata lives at three levels with one vocabulary.** The Source (the record), the Artifact (the copy used) and the Evidence graph (the item cited) each hold values and layout, with the same fields from `source_metadata_fields`, which keeps its name. Tables: `artifact_metadata`, `artifact_metadata_layout`, `evidence_graph_metadata`, `evidence_graph_metadata_layout`. Layout rules (order, dismiss) are the Source's at every level. Binds S15-07 – S15-12. Design: map § 6.6.
- **One level type.** Source, Artifact, graph and Citation are one Go `Level` type in the pure package `core/vocabkey`, used by suggestion rows, metadata owners, the format prefixes and the built-ins table, and the RPCs. Only the first three hold metadata: `vocabkey.MetadataLevels()` is that subset, and suggestions, owners and the suggestion table's `CHECK` use it; the Citation level has only built-ins. Swift mirrors the whole type as one enum `Level` with a `metadataLevels` subset, each with a row in `api/ffi/swift_vocabulary_test.go` (user, 2026-11-11). S15-06 adds it; S15-14 uses it. (K-6, K-20.)
- **Metadata saves with its owner's write.** Values entered while adding or editing an Artifact, or saving the Evidence graph form, go in the same transaction as the Artifact or graph (`CreateArtifactRequest`, `UpdateArtifactRequest` from S15-33, the graph create and update requests). Drafts save through one `sourcemetadata.Apply(tx, owner, draft)`, which compares the draft with what is stored and runs the steps `Set`, `Clear`, `DismissSuggestion` and `Reorder` use; `CreateAll` becomes its empty-owner case. Live boards save per field, as the Source page does; since S15-34 the Source's own board is the only live one (user, 2026-11-12). (K-1, K-19.) Binds S15-08, S15-10, S15-11, S15-33, S15-34. (K-1.)
- **One metadata board.** The Swift board model and view take an owner (kind, id, its entries and its write operations); the Source page, the Artifact sheet (add and edit), and the graph form all use it. Binds S15-26, S15-09 – S15-11, S15-34. (K-2.)
- **An Artifact is added and edited in one sheet.** The Artifact sheet holds the label, the description, the Evidence graphs it is in and its copy details (the board on a draft, with the type's `artifact`-level suggestions); nothing saves until Save, and Cancel discards. Editing saves in one `UpdateArtifact` write with the draft; adding is one `CreateArtifact` write with the draft, then the file's ingest as its own write, as today. Both replies carry the Artifact's saved rows, so the page patches its cached workspace (`.wroteMetadataBoard`) instead of reloading. Editing on the card goes; the list shows each Artifact's saved copy details read-only, more tightly than a form, with a square thumbnail tile of at most 80pt: a square crop fills from the short edge (about 170 pixels of the engine's 256-pixel thumbnail on a census page), so 80pt is the largest that stays sharp at 2x; no derivative size changes (user: "just display a smaller thumbnail"). Rows or compact cards is the board's call (user, 2026-11-12). Replaces S15-D1 SD-9 and SD-10 and folds S15-D4 into S15-D14. Binds S15-33 – S15-36, S15-10, S15-25.
- **A board adds a field in an inline row.** Add field on every metadata board, the Source's own included, is an inline row in the board (pick a field, type a value), not the Add metadata dialog, which goes (user, 2026-11-12). On the Source's own Metadata section only the header's Add field opens the row; there is no second button at its foot (user, 2026-11-13). On a live board the row saves at once; on a draft it adds to the draft. A draft board clears a row with no confirm (Cancel restores it). Binds S15-34, S15-36, S15-11.
- **No engineering for two windows editing the same data.** Each window keeps its own page cache; a form opened from a stale cache may overwrite what another window saved meanwhile. That is accepted: forms open from the page's values with no fresh read, and the bar is that the app does not crash (user, 2026-11-14). Binds S15-11 and every later form.
- **One date order.** The rule for where a date sits in an order (today the private `datePlace`, `dateKeyOf` and `dateKeyLess` in `conclusionsummaries`) moves to `core/valuecompare` beside `DateEnds` as an exported key and comparison, which `conclusionsummaries` and `sources` both call; it gives each Source a date sort key on the wire; Swift's Sources list sorts by that key, undated last, and never orders dates itself. Binds S15-02, S15-04. (K-12.)
- **Suggestions have a level.** `source_type_metadata_fields.level` is `source`, `artifact` or `graph`, in the table's key. An Artifact's and a graph's suggestions are their Source's type's rows at that level. Binds S15-06, S15-09 – S15-12, S15-19.
- **The item is a graph field.** What a graph is about ("Ada Robins", "baptism of Ada Smith, 3 March 1830") is the seeded graph-level field `item`, typed once per graph and read as `{graph.meta.item|source.meta.item}`; nothing derives it from a Citation's Subjects, and no Subject is marked as the graph's principal (parked in [`ideas/evidence-graph-followups.md`](../../ideas/evidence-graph-followups.md) "Primary subject") (user, 2026-11-09). Binds S15-16, S15-19, S15-20. Design: map § 6.5.
- **Citations carry no metadata.** The composer's only new input is the printed page (`page_label` on the `page` selector, already in the locator). Binds S15-13. Design: map § 6.9.
- **Citation formats are data on the Source type.** Three nullable columns, `citation_full`, `citation_short`, `citation_list`, in the syntax of map § 6.3: `{source.meta.key}`, `{artifact.meta.key}`, `{graph.meta.key}`, built-ins directly under their level (`{source.title}`, `{source.date:year}`, `{citation.page}`, `{citation.label}` …), `[optional groups]`, `{a|b}`, `*italic*`, backslash escapes. The list form reads the Source only. A type with no full format shows today's citation line. Binds S15-14 – S15-23.
- **Every placeholder names its level; fallback is written.** There is no unprefixed `{meta.key}` and no hidden graph-else-Artifact-else-Source rule: a format that falls back writes the chain, `{graph.meta.line_number|source.meta.line_number}`, read like SQL `COALESCE`. An unprefixed `{meta.key}` is a parse error. The seed reads each field at its usual level, and item fields as `{graph.meta.key|source.meta.key}` so a researcher who files one Source per household still gets them (user, 2026-11-13). Binds S15-14, S15-16, S15-17, S15-20. Design: map §§ 6.3, 6.6.
- **A format's fields are needed or used.** A placeholder outside any group is needed; inside a group, used. A chain is one requirement, met when any option has a value; empty everywhere, it is flagged on its first option, with a hint naming the others. `core/citationformat` derives the requirements from a type's three formats, and one function there turns (requirements, resolved values) into what is missing, which the format editor's preview shows; the batch render returns no missing list. Swift never parses a format (user, 2026-11-13; map review K3-4). Binds S15-14, S15-16, S15-38. Design: map §§ 6.3, 6.10.
- **Requirements need a refresh signal; renders do not.** Renders are never cached, so a format edit needs no signal for them. Requirements ride the cached board reads, so S15-15's format write reports a typed mutation (`.changedCitationFormats(typeId)`), and S15-38 adds it to `.sourceWorkspace`'s invalidation and to the graph board's key, and records it in `docs/catalog-caches.md` (map review K3-2). Binds S15-15, S15-38.
- **Boards flag needed fields; the engine decides the rows.** `sourcemetadata.listWorkspaces`, which already merges suggestions, values, dismissals and extras per type and level, also merges the type's requirements: each entry carries needed, used or none, and whether its chain is met at another level (one more batched read of the Source's values). A needed or used field is emitted even when not suggested or dismissed; a field both suggested and needed comes out once; `DismissSuggestion` refuses a needed field; `TypeSuggestion` carries the same annotation for a draft with no owner. Every board read and write reply carries it, so Swift only draws `entry.requirement`, on every board at once (rule "One metadata board"). The Source date's requirement rides the Source workspace read; the printed page's, the composer's read. The Source page's "Citation" section of S15-D1 (SD-11 – SD-13) is not built; the Source page offers only **Copy source-list entry**, because that form belongs to the Source, and notes are copied where Citations are shown (S15-21) (user, 2026-11-13; map review K3-1, K3-7). Binds S15-38, S15-39, S15-40, S15-42, S15-45, S15-23. Design: map § 6.10.
- **A value can be marked unknown or supplied.** Every metadata value, the Source date and a Citation's printed page carry two facts: **unknown** (the record does not give it; no text) and **supplied** (the value is not on the record; the researcher took it from elsewhere). They are independent of a date's precision. Unknown meets the requirement and prints the field's `unknown_text` (seeded "n.p." on `publication_place` and `publisher`; editable on the Metadata page), "n.d." for the date, "unpaginated" for the page; supplied prints in square brackets. **One type:** the pure package `core/valuemark` (S15-14) declares the pair and its `Validate` (never both; unknown has no text); `sourcemetadata`, the Source date write, `core/locator`'s page and the resolver value all use it, and the proto has one `ValueMark` message. **One control:** S15-41 builds the Unknown and Supplied control once, beside the board row, and S15-42 and S15-45 reuse it. Storage: `is_unknown` and `is_supplied` on the three value tables and `unknown_text` on `source_metadata_fields` (S15-37); `date_unknown` and `date_supplied` on `sources` (S15-43); `page_unknown` and `page_supplied` in the locator JSON (S15-44). Copy Source and a move carry them; the audit records them with the value (user, 2026-11-13; map review K3-5, K3-6). Binds S15-14, S15-16, S15-19, S15-37, S15-41 – S15-46. Design: map § 6.10.
- **Dates in citations use citation terms.** A DateValue in a citation prints "ca.", "bef.", "aft." and day-month-year, months spelled out except in the short note; the app's pages keep "abt". It is `core/datevalue`'s second display style, `CitationDisplay(v, form)` beside `CompactDisplay`, sharing `formatSide`'s precision handling, so one package turns a DateValue into text; `citationformat` calls it. Check the terms against the edition on hand (user, 2026-11-13; map review K3-3). Binds S15-14, S15-16. Design: map § 6.3.
- **No transforms on metadata.** Values print exactly as typed; only the Source date (a DateValue) has formatting options (`:year`, `:full`). Each field's description says to enter the value as it should appear. Refused: inverting, reversing, abbreviating. Binds S15-14, S15-19.
- **Formats name fields by id.** `core/citationformat` defines the stored token for a field id and one rewrite of the parse tree between keys and ids; one `metadatafields.ResolveKeysTx(tx, keys, preferOrigin)`, beside `lookupTx`, maps keys to ids, and both the `sourcetypes` format write and `sourcevocab.Install` call it. A field named in any format is in use: its delete is refused by a delete-impact probe over the three format columns, listing the types ([`add-catalog-delete`](../../../.agents/skills/add-catalog-delete/SKILL.md), which gains the text-reference case). Field keys stay unrenamable, as today. Binds S15-14, S15-15, S15-17, S15-20. (K-7.)
- **One engine, in Go.** `core/citationformat` parses and renders; values go in after parsing, so a `*` or `[` in a value never formats. The app renders only through FFI. Binds S15-14, S15-16, S15-21 – S15-23.
- **Citations render on demand, from SQL.** One Go function renders a batch of Citations and returns, per Citation, the styled runs, the plain text, the missing fields and a group key. It reads the catalog directly in a few batched queries (types and formats; Source, Artifact and graph values through S15-07's batch read by owners; Source titles and dates), not Spike 16's caches, and nothing it produces is cached in Go or Swift: a screen asks for its citations when it shows them (the provenance sheet when it opens, the Sources section when it appears), so a format or field edit needs no refresh signal; a screen already open while a format is edited elsewhere catches up the next time it is shown. The provenance sheet holds its on-open call as one `CatalogQueryKey` only while it is shown (`whenHidden: .evict`), so it gets S16-04's failure reading and the registry's refresh on the inputs its read reports; nothing outlives the sheet (map review K-26). Measured at Scale (300 Citations per call) in S15-16; caching is a later decision if it is slow (user, 2026-11-09). This is a deliberate exception to Spike 16's "A Source's words live once". It is the first step of [`provenance-loading.md`](provenance-loading.md) "Load records when the sheet opens": the sheet's on-open call is the one that idea grows, not a second one. Binds S15-16, S15-21 – S15-23. (Replaces the round-1 answer to K-3; closes K-18.)
- **One render request for previews and the list entry.** The format editor's preview and the Source page's Copy source-list entry go through one request: a form, an optional unsaved format, and a target (Citation ids, or a Source for the list form); it returns runs, missing fields and parse diagnostics. Swift never parses a format. Binds S15-16, S15-17, S15-23. (K-10, K3-12.)
- **Built-in placeholders are one table.** `core/citationformat` declares each built-in once (name, level, allowed in the list form, options such as `:year`, `:full`); parsing, the list-form rule, missing fields, the resolver and the editor's Insert field list (over FFI) all read it. Binds S15-14, S15-16, S15-17. (K-5.)
- **Today's line stays the fallback, in Swift.** For a type with no full format the engine returns no text, and the app shows today's localized line from `CitationLineDisplay`, which stays for that and for its other callers (Gallery captions, the likeness viewer, a denier's Source name). Go does not write a second copy. Binds S15-16, S15-21. (K-4.)
- **Build on Spike 16's caches.** The Person page date comes from the Source records (S16-12, S16-13); the provenance sheet and the Sources section are edited after S16-30 and S16-13 have reshaped them; the move lands after S16-12, S16-13 and S16-15 so their Apply sees it. Citation rendering reads SQL instead (rule "Citations render on demand, from SQL"). Spike 15 PRs that touch those land after them; the rest run alongside Spike 16 (user, 2026-11-09). Spike 16's map names this spike in **Shared with Spike 15**. Spike 15's new Swift query keys are added to today's `CatalogQueryKey` enum and converted with the rest by S16-25, rather than waiting for it, so slices 1 to 4 can run alongside Spike 16 (user, 2026-11-09). Binds S15-05, S15-16, S15-21, S15-22, S15-24.
- **The seed is the product default.** The 26 types, 63 fields, suggestions and formats of map § 6.8 go into `core/database/sourcevocab` and install at create through `sourcevocab.Install`. No plugin, no opt-out, no install on open, no seed-version row. The dogfood projects are updated by running Install once against them; the PR says how. Binds S15-19, S15-20.
- **Grouping is by the rendered full citation, computed when read.** Citations whose full citation renders the same are one citation with their Citations beneath; nothing is stored. Binds S15-21, S15-22.
- **A move is the whole bundle.** The bundle is the closure of the picked Artifact or graph over `evidence_graph_artifacts`. One flow from an Artifact or a graph; one function computes the bundle for the preflight and the write; one transaction updates `source_id` on `artifacts`, `evidence_graphs` and `subjects` with deferred foreign keys, recording per-row changes so audit scopes (both Sources), `Reads`, search and Spike 16's caches all follow from the effects registry, with no hand-written cache update or scope tag; a Source left with no graph gets `evidencegraphs.CreateDefault`. Source-level values are not looked at. Binds S15-24, S15-25. Design: [`move-artifact-between-sources.md`](move-artifact-between-sources.md).
- **The credibility fix is idiomatic and needs no brief.** The argument becomes the same `PVTextArea` the Source description uses, with the platform's text-area behavior (Return is a new line) and the existing Save button. It adds no new chrome beyond the control the page already uses (user, 2026-11-09). Binds S15-01.
- **The provenance table folds a page at a time.** `PVProvenanceRecordTable` folds with the kit's paged fold: S16-07's fold rule and fold state move to `macos/App/Platform/` and its Show more row becomes a kit component, `PVShowMoreRow`, so a recipe can use them (`docs/design-system-layers.md`: a recipe never names a `Features/` type). The fold counts citation groups (a group's full citation with its Citations), never splitting a group, 50 at a time. Binds S15-30, S15-27. Design: [`provenance-loading.md`](provenance-loading.md) "Cap". (K-25, K-33.)
- **The Why accordion goes.** It is deprecated: Event and Place rows open the provenance sheet as Person rows do, and the Why and its code are deleted before records leave the page read (user, 2026-11-09). Binds S15-31. (K-30.)
- **Records load when the sheet opens.** The detail page read stops carrying each value's records. It keeps what it already sends (`Support`, `Against`, the values and their state) and adds `FieldRecordCounts` per field (the record count and, for a mixed field, the distinct Source count), composed from the node's outcome rows and the records tier after S16-11 and S16-30, with no new SQL query. A sheet's records come from one read that takes the row's (owner, Property) pairs, mirroring `RecordsSource` (`.field`, `.spanning`, `.derived`), and returns them grouped by pair, each outcome carrying whether it denied a value and the denier's Source title; it reports its inputs as S16-24's reads do. The sheet's on-open call (S15-21's key) carries these records with their citations. Swift's `distinctSourceCount`, `recordCount` derivation, `deniedSomething` and denier search go. Binds S15-28, S15-29. Design: [`provenance-loading.md`](provenance-loading.md) "Load records when the sheet opens". (K-24, K-27, K-28, K-34.)
- **A Source type has its own page.** The Source types list keeps no side pane: a row opens the type's own page, a deep place under Source types (`WorkspaceLocation.typeId`, today's breadcrumb "Source types › Census", Back and Forward, restore, the omnibar's `source_type` hits and delete-impact rows that name a type, which already route by `typeId`; the crumb's label resolves live from the cached types list, as a Source's title does), with room for the three suggestion lists (S15-12) and the three citation formats (S15-17) beside the name, icon, description and delete. **Add type** sits at the top right of the list and opens a short dialog (label, icon, description), as Add Source does; Save creates the type and opens its page, where suggestions and formats are added, all optional. S15-18's **Copy from** goes in that dialog. The Metadata page keeps its list and side pane: its fields gain no new data this spike (user, 2026-11-14). Binds S15-47 – S15-49, S15-12, S15-17, S15-18.
- **Refused in this spike.** A shared Repository record; per-Source format overrides; a fourth citation form; source type packages ([idea](../../ideas/source-type-packages.md)); install on open; undo of a move; Merge Sources; moving to a new Source; filling the jurisdiction from the graph; a per-Artifact page map; a citation preview on the Source page (user, 2026-11-13); copying several Sources' list entries at once ([idea](../../ideas/copy-source-list-entries.md)). Each is recorded in the map (§ 7) or the move doc.

## PR map

| PR | Title | Slice | Scope | Brief | Depends on | Plan | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S15-01 | The credibility argument is a text area | 1 | Swift: `PVTextArea` with the description's behavior; Save as today | — | — | [plan](prs/S15-01-credibility-argument-text-area.md) | Landed #758 |
| S15-02 | Sources carry a date and a not-public flag | 1 | Go: one migration (`date_value_id`, `is_public`), Source read and write, a date sort key from the shared date order | — | — | [plan](prs/S15-02-source-date-and-public-flag.md) | Landed #762 |
| S15-03 | The Source page shows the date and the Private switch | 1 | Swift: set, change, clear the date in a dialog; the Private switch; the page on Page columns. Go: `sources.not_found` for a missing Source | S15-D1 | S15-02, S15-D1 | [plan](prs/S15-03-source-page-date-and-private-switch.md) | Landed #766 |
| S15-04 | The Sources list shows and sorts by the date | 1 | Swift: the date on each row; a date sort by Go's key, undated last | S15-D2 | S15-02, S15-D2 | [plan](prs/S15-04-sources-list-date.md) | Landed #774 |
| S15-05 | The Person page's Sources section shows each Source's date | 5 | Go and Swift: the date on the Source record and in the section | S15-D3 | S15-02, S16-12, S16-13, S16-03, S16-06, S16-07, S15-D3 | — | Scoped |
| S15-06 | Type suggestions have a level | 2 | Go: one `Level` type; migration rebuilding `source_type_metadata_fields` with `level`; readers and RPCs take it | — | — | [plan](prs/S15-06-type-suggestions-have-a-level.md) | Landed #782 |
| S15-07 | Metadata operations take an owner | 2 | Preparatory, Go: every `sourcemetadata` function on an owner, a batch read by owners, and `Apply` for drafts; Sources unchanged | — | S15-06 | [plan](prs/S15-07-metadata-operations-take-an-owner.md) | Landed #787 |
| S15-08 | Artifacts and graphs hold metadata | 2 | Go: the four tables, model, audit, delete, Copy Source, FFI; values in the Artifact and graph writes; Used by from delete impact | — | S15-06, S15-07 | [plan](prs/S15-08-artifacts-and-graphs-hold-metadata.md) | Landed #791 |
| S15-09 | Artifacts show their metadata on the Source page | 2 | Swift: a metadata board per Artifact; **trimmed before merge (user, 2026-11-12)** to the board write's cache patch and its fixes; the per-Artifact chrome moved to S15-34 | S15-D1 | S15-08, S15-26, S15-D1 | [plan](prs/S15-09-artifact-metadata-boards.md) | Landed [#802](https://github.com/mendahu/provenencia/pull/802) (trimmed) |
| S15-10 | Adding an Artifact asks for its copy details | 2 | Swift: Add Artifact opens the Artifact sheet in add mode; copy details save with the new Artifact | S15-D14 | S15-34, S15-36, S15-D14 | [plan](prs/S15-10-artifact-sheet-add-mode.md) | Landed [#829](https://github.com/mendahu/provenencia/pull/829) |
| S15-11 | Evidence graphs show their metadata | 2 | Go: the Source page read carries each graph's board; the graph write replies answer its rows. Swift: the graph form in two columns with a metadata board; each graph row shows its saved values read-only | S15-D5 | S15-36, S15-34, S15-35, S15-D5 | [plan](prs/S15-11-graph-metadata.md) | Landed [#834](https://github.com/mendahu/provenencia/pull/834) |
| S15-12 | Source types suggest fields at each level | 2 | Swift: the type page edits three suggestion lists; the Fields count spans all three | [S15-D6](design/archive/S15-D6-source-type-suggestion-levels.md) | S15-06, S15-48, S15-D6 | [plan](prs/S15-12-type-suggestions-at-each-level.md) | Landed #856 |
| S15-13 | The composer records the printed page | 3 | Go and Swift: a Printed page field on image and PDF Citations, written as `page_label` (a page selector may hold the label alone); the composer on Regular and Wide (user, 2026-11-16) | [S15-D8](design/archive/S15-D8-citation-composer-printed-page.md) | S15-50, S15-D8 | [plan](prs/S15-13-composer-printed-page.md) | Landed [#863](https://github.com/mendahu/provenencia/pull/863) — stacked on S15-50 (#862) |
| S15-14 | The citation format engine | 4 | Go: `core/citationformat` parse (levels named, no shorthand), render (unknown, supplied, citation dates through `core/datevalue`), needed and used requirements, `core/valuemark`, diagnostics, the built-ins table and the field-id token; table tests; syntax doc | — | S15-06 | [plan](prs/S15-14-citation-format-engine.md) | Planned |
| S15-15 | Source types store citation formats | 4 | Go: migration (three columns), id-keyed storage, delete impact, type read and write; a typed mutation on a format write | — | S15-14 | — | Scoped |
| S15-16 | Citations render through their type's formats | 4 | Go: the SQL resolver with unknown and supplied values; one batch render RPC (no missing list); one render request for previews; built-ins over FFI | — | S15-08, S15-15, S15-02, S15-37, S15-43, S15-44 | — | Scoped |
| S15-17 | The format editor | 5 | Swift: three formats, Insert field by level, live preview, warnings, on the Source type page | S15-D16 | S15-16, S15-12, S15-48, S15-D16 | — | Scoped |
| S15-18 | A new type can copy another's formats and suggestions | 4 | Go and Swift: one write; **Copy from** in the Add type dialog (S15-47) | S15-D7 | S15-15, S15-06, S15-47, S15-12, S15-D7 | — | Scoped |
| S15-19 | Seed the citation types, fields and suggestions | 4 | Go: `sourcevocab` registry and Install for 26 types, 63 fields, levelled suggestions; `unknown_text` | — | S15-06, S15-37 | — | Scoped |
| S15-20 | Seed the citation formats | 4 | Go: each seeded type's three formats; a render test per type | — | S15-19, S15-15 | — | Scoped |
| S15-21 | The provenance sheet shows formatted citations | 6 | Swift: the sheet's on-open key renders and groups; Copy citation copies rich text | S15-D9 | S15-16, S16-30, S16-04, S15-D9 | — | Scoped |
| S15-22 | The Sources section groups a Source's Citations by citation | 6 | Swift: the section renders on demand and groups | S15-D15 | S15-16, S15-05, S16-03, S16-06, S16-07, S15-D15 | — | Scoped |
| S15-23 | The Source page copies its source-list entry | 9 | Swift: **Copy source-list entry** on the Source page; **re-scoped (user, 2026-11-13)**: the citation preview is not built | S15-D19 | S15-16, S15-21, S15-D19 | — | Scoped |
| S15-24 | Move a bundle to another Source in the engine | 7 | Go: closure, preflight and move RPCs, one transaction through the effects registry | — | S16-12, S16-13, S16-15 | — | Scoped |
| S15-25 | Move from an Artifact or a graph | 7 | Swift: the menu items and the bundle confirm | S15-D10, S15-D1, S15-D14 | S15-24, S15-35, S15-D10, S15-D1, S15-D14 | — | Scoped |
| S15-26 | The metadata board takes an owner | 2 | Preparatory, Swift: the board model and view take an owner; the Source page unchanged | — | — | [plan](prs/S15-26-metadata-board-takes-an-owner.md) | Landed #798 |
| S15-27 | The provenance table folds a page at a time | 8 | Swift: the record table folds 50 citation groups at a time with the kit fold | S15-D17 | S15-30, S15-21, S15-D17 | — | Scoped |
| S15-28 | A value's records load on their own | 8 | Go: `FieldRecordCounts` from the node; one records read by (owner, Property) pairs with denial facts; reports its inputs | — | S16-11, S16-19, S16-24, S16-30 | — | Scoped |
| S15-29 | The provenance sheet loads its records when it opens | 8 | Swift: rows from the counts; the sheet's key carries records; Swift's count and denial rules go | S15-D18 | S15-28, S15-21, S15-31, S16-09, S15-D18 | — | Scoped |
| S15-30 | The paged fold moves to the kit | 8 | Preparatory, Swift: S16-07's fold rule and state to `Platform/`, `PVShowMoreRow` in the kit; the Conclusion sections unchanged | — | S16-07 | — | Scoped |
| S15-31 | Event and Place rows open the provenance sheet | 8 | Swift: `.sheet` provenance on Event and Place pages; the Why accordion and its code go | S15-D11, S15-D12 | S15-D11, S15-D12 | — | Scoped |
| S15-32 | Copy Source can carry the date | 1 | Go and Swift: a `copy_date` choice on `CopySourceRequest` and `sourcecopy`; a Published date tick on the Copy form | [S15-D13](design/archive/S15-D13-copy-source-dialog.md) | S15-02, S15-D13 | [plan](prs/S15-32-copy-source-date.md) | Landed #778 |
| S15-33 | Editing an Artifact can save its metadata | 2 | Go: a `MetadataDraft` on `UpdateArtifactRequest`; both Artifact write replies return its saved rows; a refused draft value names its field | — | S15-08 | [plan](prs/S15-33-artifact-update-saves-metadata.md) | Landed #806 |
| S15-34 | Artifacts are edited in a sheet | 2 | Swift: the Artifact sheet (label, description, graphs, copy details on the draft board, one Save); read-only copy details on each card; the inline Add field row on every board; card edit goes; the Metadata header's tooltip and no count; Wide | S15-D14 | S15-09, S15-33, S15-36, S15-D14 | [plan](prs/S15-34-artifact-edit-sheet.md) | Landed [#819](https://github.com/mendahu/provenencia/pull/819) |
| S15-35 | The Artifact list shows each Artifact's copy details | 2 | Swift: the list's new layout (rows), a 64pt square thumbnail; Wide's copy-details column; the header's type pill as a ported `PVTag` (Badge unchanged) and a meta row that never clips; the description at caption size | S15-D14 | S15-34, S15-D14 | [plan](prs/S15-35-artifact-list-rows.md) | Landed [#824](https://github.com/mendahu/provenencia/pull/824) |
| S15-36 | A metadata board can hold a draft | 2 | Preparatory, Swift: the draft board host, a Swift metadata draft, `metadata:` on the four Artifact and graph writes; no chrome | — | S15-26, S15-33 | [plan](prs/S15-36-metadata-board-holds-a-draft.md) | Landed #810 |
| S15-37 | Metadata values can be marked unknown or supplied | 4 | Go: one migration (the two facts on the three value tables, `unknown_text` on fields); `sourcemetadata` and `metadatafields` writes and reads, FFI, Copy Source, audit | — | S15-08, S15-14 | — | Scoped |
| S15-38 | Boards carry their citation's requirements | 4 | Go: `listWorkspaces` and `TypeSuggestion` annotate each entry needed, used or none and met elsewhere; `DismissSuggestion` refuses a needed field; the date's and page's requirements; the cache signal | — | S15-14, S15-15, S15-37 | — | Scoped |
| S15-39 | Metadata boards flag needed fields | 9 | Swift: every board (Source page, Artifact sheet in both modes, graph form) draws needed and used entries; a needed row offers no dismiss | S15-D20 | S15-38, S15-34, S15-11, S15-D20 | — | Scoped |
| S15-40 | The Artifact list marks a missing citation field | 9 | Swift: an Artifact list entry with a needed field empty carries a mark that opens the sheet at Copy details | S15-D21 | S15-39, S15-35, S15-D21 | — | Scoped |
| S15-41 | A metadata row can be marked unknown or supplied | 9 | Swift: the Unknown and Supplied control, built once; on every board's row | S15-D22 | S15-37, S15-39, S15-D22 | — | Scoped |
| S15-42 | The Source date can be unknown, supplied or flagged | 9 | Swift: the date dialog's No date and Supplied (S15-41's control); the header shows them and flags an empty date the type needs | S15-D23 | S15-43, S15-38, S15-41, S15-D23 | — | Scoped |
| S15-43 | The Source date can be marked unknown or supplied | 4 | Go: one migration (`date_unknown`, `date_supplied` on `sources`); the Source read and date write; Copy Source with its date tick; audit | — | S15-02, S15-14 | — | Scoped |
| S15-44 | The printed page can be marked unknown or supplied | 4 | Go: `page_unknown` and `page_supplied` in the locator's page selector; `validatePage`; `locator.Page` returns the mark | — | S15-14 | — | Scoped |
| S15-45 | The composer marks and flags the printed page | 9 | Swift: Unknown and Supplied on the printed page (S15-41's control); flagged when the type needs `{citation.page}` | S15-D24 | S15-13, S15-38, S15-41, S15-44, S15-D24 | — | Scoped |
| S15-46 | A field's unknown text is editable | 9 | Swift: the Metadata page edits a field's unknown text | S15-D25 | S15-37, S15-D25 | — | Scoped |
| S15-47 | Adding a Source type opens a dialog | 2 | Swift: Add type at the list's top right opens a form dialog (label, icon, description); Save opens the new type; the side pane's add mode goes | [S15-D26](design/archive/S15-D26-add-source-type-dialog.md) | S15-D26 | [plan](prs/S15-47-add-source-type-dialog.md) | Landed #843 |
| S15-48 | Source types open on their own page | 2 | Swift: a Source type page (header, details, the Source suggestions, delete, locked plugin types) as a deep place; list rows open it; the side pane goes | [S15-D27](design/archive/S15-D27-source-type-page.md) | S15-47, S15-D27 | [plan](prs/S15-48-source-type-page.md) | Landed #848 |
| S15-49 | The Source types list is redesigned | 2 | Swift: a sortable Used by column; at Wide the list centers in the Sources list's band and adds Description | [S15-D28](design/archive/S15-D28-source-types-list.md) | S15-48, S15-D28 | [plan](prs/S15-49-source-types-list.md) | Landed #852 |
| S15-50 | Forms list their tab order | 3 | Preparatory, Swift: a form holds its focus and lists its fields' Tab order, any number, on the kit's handle (`PVFieldFocus(_:equals:in:)`); `PVTabPair` goes from every caller; skill and README; no chrome change | — | — | [plan](prs/S15-50-forms-list-their-tab-order.md) | Landed [#862](https://github.com/mendahu/provenencia/pull/862) |

## Design track

| Brief | View | Gates | Notes |
| --- | --- | --- | --- |
| S15-D1 | Source page | **S15-03**, S15-09, S15-25 | Where the date sits (it reads as the Source's own date, not a metadata row) and whether the page moves onto Page columns ([`wide-layout.md`](../../ideas/wide-layout.md)); the not-public switch; an Artifact's metadata board; the citation preview (not built, below); Move on Artifact rows and graphs. One board for the page, drawn before S15-03. SD-9 and SD-10 (the Artifact's board) are replaced by S15-D14 (user, 2026-11-12). Its "Citation" section (SD-11 – SD-13) is not built: S15-23 is re-scoped to S15-D19, and needed fields go to S15-D20 (user, 2026-11-13). Written before "One brief, one PR"; stays as written |
| S15-D2 | Sources list | **S15-04** | The date on rows and as a sort |
| S15-D3 | Person page Sources section | **S15-05** | The date on each Source. Split under "One brief, one PR": the grouping is S15-D15 |
| S15-D4 | Adding an Artifact | — | **Descoped (2026-11-12):** folded into S15-D14, which draws the Artifact sheet in add mode |
| [S15-D5](design/archive/S15-D5-evidence-graph-form.md) | Evidence graph form, graph rows | **S15-11** | A two-column form: Name, Description and the graph's metadata board beside the Artifacts checklist; a long Artifact list scrolls in its checklist, never the form (user, 2026-11-14); each graph row shows its saved values read-only (user, 2026-11-14) |
| [S15-D6](design/archive/S15-D6-source-type-suggestion-levels.md) | Source type page | **S15-12** | Suggestions at three levels, stacked in the page's Suggested fields column (S15-D27 TP-7); Return adds a picked field. Rewritten 2026-11-15 as an enhancement of S15-D27's page board. The format editor is S15-D16 |
| S15-D7 | Add type dialog | **S15-18** | Copy from, in S15-D26's dialog |
| [S15-D8](design/archive/S15-D8-citation-composer-printed-page.md) | Citation composer | **S15-13** | The printed page next to Label on image and PDF Citations; the composer's split moves onto Regular and Wide (user, 2026-11-16) |
| S15-D9 | Provenance sheet | **S15-21** | The formatted citation, grouped Citations, Copy citation; the loading and failed states of the on-open call. Split under "One brief, one PR": the fold is S15-D17, records on open S15-D18 |
| S15-D10 | Move confirm | **S15-25** | The bundle, the target picker, the credibility note |
| S15-D11 | Event page | **S15-31** | Value rows open the provenance sheet; the Why accordion is removed |
| S15-D12 | Place page | **S15-31** | Value rows open the provenance sheet; the Why accordion is removed |
| S15-D13 | Copy Source dialog | **S15-32** | A Published date tick beside Description, Metadata and Credibility ([brief](design/archive/S15-D13-copy-source-dialog.md)) |
| S15-D14 | Source page Artifacts | **S15-34**, S15-35, S15-10, S15-25 | The Artifact list with each Artifact's copy details shown read-only and a thumbnail of at most 80pt (rows or compact cards: the board decides); the Artifact sheet in edit and add mode: label, description, graphs, copy details with suggestions, one Save; where Move sits on the new list. Replaces S15-D1 SD-9, SD-10 and S15-D4. Written before "One brief, one PR"; stays as written |
| S15-D15 | Person page Sources section | **S15-22** | Citations grouped under one citation |
| S15-D16 | Source type page | **S15-17** | The three formats, Insert field, live preview, warnings |
| S15-D17 | Provenance sheet | **S15-27** | The record table's fold |
| S15-D18 | Provenance sheet | **S15-29** | Records loading when the sheet opens, and their failure |
| S15-D19 | Source page | **S15-23** | Where Copy source-list entry sits |
| S15-D20 | Metadata board row | **S15-39** | A needed and a used entry on every board, its hint for a chain, no dismiss |
| S15-D21 | Source page Artifacts | **S15-40** | The list entry's mark for a missing citation field |
| S15-D22 | Metadata board row | **S15-41** | The Unknown and Supplied control (reused by S15-42, S15-45), how a marked row reads |
| S15-D23 | Source date dialog and header | **S15-42** | No date and Supplied; how the header shows them; the header's flag on an empty date |
| S15-D24 | Citation composer | **S15-45** | Unknown, Supplied and the needed flag on the printed page |
| S15-D25 | Metadata page | **S15-46** | A field's unknown text |
| [S15-D26](design/archive/S15-D26-add-source-type-dialog.md) | Add type dialog | **S15-47** | Label, icon, description; Add type at the list's top right, as Add Source; how Icon is picked from inside a dialog (a sheet over it or an inline grid) |
| [S15-D27](design/archive/S15-D27-source-type-page.md) | Source type page | **S15-48** | The page from scratch at Regular and Wide: header, details, delete, locked plugin types, today's Source suggestions; it names where S15-12's lists and S15-17's formats will sit (drawn by their own briefs); the list without its side pane as far as rows opening the page |
| [S15-D28](design/archive/S15-D28-source-types-list.md) | Source types list | **S15-49** | A sortable Used by column at every width; at Wide the Sources list's band and a Description column; the origin stays a pill (user, 2026-11-15) |

## Slices

**✎ = design brief**, just before the PR it gates. **Check** = what you can verify in the app when the slice lands.

```text
SLICE 1 — Source date, privacy, credibility           (alongside Spike 16)
  S15-01  The credibility argument is a text area
  S15-02  Sources carry a date and a not-public flag
  ✎ S15-D1 ──▶ S15-03  The Source page shows the date and the Private switch
  ✎ S15-D2 ──▶ S15-04  The Sources list shows and sorts by the date
  ✎ S15-D13 ──▶ S15-32  Copy Source can carry the date
  Check: bar 1 (Source page and list), bar 2, bar 9; a copied Source keeps the date when its tick is on (S15-32).

SLICE 2 — Metadata at three levels                    (alongside Spike 16)
  S15-06  Type suggestions have a level
  S15-07  Metadata operations take an owner
  S15-08  Artifacts and graphs hold metadata
  S15-26  The metadata board takes an owner
  S15-09  Artifacts show their metadata on the Source page   (S15-D1)
  S15-33  Editing an Artifact can save its metadata
  S15-36  A metadata board can hold a draft
  ✎ S15-D14 ──▶ S15-34  Artifacts are edited in a sheet
  S15-35  The Artifact list shows each Artifact's copy details   (S15-D14)
  S15-10  Adding an Artifact asks for its copy details           (S15-D14)
  ✎ S15-D5 ──▶ S15-11  Evidence graphs show their metadata
  ✎ S15-D26 ──▶ S15-47  Adding a Source type opens a dialog
  ✎ S15-D27 ──▶ S15-48  Source types open on their own page
  ✎ S15-D28 ──▶ S15-49  The Source types list is redesigned
  ✎ S15-D6 ──▶ S15-12  Source types suggest fields at each level
  Check: bar 3 except the composer; a Source type opens on its own page from the list, the omnibar and Back.

SLICE 3 — Printed page                                (alongside Spike 16)
  S15-50  Forms list their tab order
  ✎ S15-D8 ──▶ S15-13  The composer records the printed page
  Check: bar 3's composer.

SLICE 4 — Formats as data                             (alongside Spike 16)
  S15-14  The citation format engine
  S15-15  Source types store citation formats
  ✎ S15-D7 ──▶ S15-18  A new type can copy another's formats and suggestions
  S15-19  Seed the citation types, fields and suggestions
  S15-20  Seed the citation formats
  S15-37  Metadata values can be marked unknown or supplied
  S15-43  The Source date can be marked unknown or supplied
  S15-44  The printed page can be marked unknown or supplied
  S15-38  Boards carry their citation's requirements
  S15-16  Citations render through their type's formats
  Check: bar 6 on a new project; bar 5's Copy from; the census example renders in a handler test.

SLICE 5 — Person page date and the format editor
  S15-05  The Person page's Sources section shows each Source's date   (S15-D3, after S16-12, S16-13)
  ✎ S15-D16 ──▶ S15-17  The format editor
  Check: bar 1 on the Person page; bar 5.

SLICE 6 — Citations in the app                        (after S16-30)
  ✎ S15-D9 ──▶ S15-21  The provenance sheet shows formatted citations
  ✎ S15-D15 ──▶ S15-22  The Sources section groups a Source's Citations by citation
  Check: bar 4's provenance sheet and copy, bar 7.

SLICE 7 — Move                                        (after S16-12, S16-13, S16-15)
  S15-24  Move a bundle to another Source in the engine
  ✎ S15-D10 ──▶ S15-25  Move from an Artifact or a graph
  Check: bar 8.

SLICE 8 — Provenance loading                         (after S16-07, S16-09, S16-11, S16-19, S16-24, S16-30)
  S15-30  The paged fold moves to the kit
  ✎ S15-D17 ──▶ S15-27  The provenance table folds a page at a time
  ✎ S15-D11, S15-D12 ──▶ S15-31  Event and Place rows open the provenance sheet
  S15-28  A value's records load on their own
  ✎ S15-D18 ──▶ S15-29  The provenance sheet loads its records when it opens
  Check: bar 10.

SLICE 9 — Needed fields, unknown and supplied values   (after slices 2, 3 and 4; S15-23 after S15-21)
  ✎ S15-D20 ──▶ S15-39  Metadata boards flag needed fields
  ✎ S15-D21 ──▶ S15-40  The Artifact list marks a missing citation field
  ✎ S15-D22 ──▶ S15-41  A metadata row can be marked unknown or supplied
  ✎ S15-D23 ──▶ S15-42  The Source date can be unknown, supplied or flagged
  ✎ S15-D24 ──▶ S15-45  The composer marks and flags the printed page
  ✎ S15-D25 ──▶ S15-46  A field's unknown text is editable
  ✎ S15-D19 ──▶ S15-23  The Source page copies its source-list entry
  Check: bar 4's boards and copy, bar 11.

S15-99 — Dogfood close / docs
```

**In parallel with Spike 16:** slices 1 to 4 need nothing from it. Within them, S15-01, S15-02, S15-06 and S15-26 have no dependencies and can start at once, with S15-07 and S15-14 right after S15-06; slice 1's UI waits on S15-D1 and S15-D2. In slice 5, S15-17 needs only slice 4; S15-05 waits for S16-12 and S16-13 (and S16-03, S16-06 and S16-07, which edit the same Sources section files); slice 6 when S16-30 lands, slice 7 when S16-15 lands as well. Slice 9 needs slices 2, 3 and 4, and S15-23 also S15-21's rich copy.

### Dependencies at a glance

```text
S15-02 ──▶ S15-03, S15-04, S15-05, S15-16, S15-32, S15-43
S15-06 ──▶ S15-07, S15-08, S15-12, S15-14, S15-18, S15-19
S15-07 ──▶ S15-08 ──▶ S15-09, S15-10, S15-11, S15-16, S15-33, S15-37
S15-26 ──▶ S15-09
S15-26, S15-33 ──▶ S15-36 ──▶ S15-34, S15-10, S15-11
S15-09, S15-33 ──▶ S15-34 ──▶ S15-35, S15-10, S15-11
S15-35 ──▶ S15-25, S15-40
S15-11, S15-34 ──▶ S15-39
S15-50 ──▶ S15-13 ──▶ S15-45
S15-14 ──▶ S15-15 ──▶ S15-16, S15-18, S15-20, S15-38
S15-14 ──▶ S15-37, S15-43, S15-44
S15-37 ──▶ S15-16, S15-19, S15-38, S15-41, S15-46
S15-43 ──▶ S15-16, S15-42      S15-44 ──▶ S15-16, S15-45
S15-38 ──▶ S15-39, S15-42, S15-45
S15-39 ──▶ S15-40, S15-41 ──▶ S15-42, S15-45
S15-19 ──▶ S15-20
S15-16 ──▶ S15-17, S15-21, S15-22, S15-23
S15-21 ──▶ S15-23
S15-12 ──▶ S15-17
S15-47 ──▶ S15-48 ──▶ S15-49
S15-48 ──▶ S15-12, S15-17
S15-47 ──▶ S15-18      S15-12 ──▶ S15-18
S15-05 ──▶ S15-22
S15-24 ──▶ S15-25
S15-21 ──▶ S15-27, S15-29
S15-30 ──▶ S15-27
S15-28 ──▶ S15-29
S15-31 ──▶ S15-29

Spike 16:
S16-12, S16-13 ──▶ S15-05
S16-03, S16-06, S16-07 ──▶ S15-05, S15-22
S16-30 ──▶ S15-21
S16-12, S16-13, S16-15 ──▶ S15-24
S16-07 ──▶ S15-30
S16-11, S16-19, S16-24, S16-30 ──▶ S15-28
S16-04 ──▶ S15-21
S16-09 ──▶ S15-29

Briefs:
S15-D1 ──▶ S15-03, S15-09, S15-25 (written before one brief, one PR)
S15-D14 ──▶ S15-34, S15-35, S15-10, S15-25 (written before one brief, one PR)
S15-D2 ──▶ S15-04                              S15-D3 ──▶ S15-05
S15-D5 ──▶ S15-11                              S15-D6 ──▶ S15-12
S15-D7 ──▶ S15-18                              S15-D8 ──▶ S15-13
S15-D9 ──▶ S15-21                              S15-D10 ──▶ S15-25
S15-D11, S15-D12 ──▶ S15-31
S15-D15 ──▶ S15-22   S15-D16 ──▶ S15-17   S15-D17 ──▶ S15-27   S15-D18 ──▶ S15-29
S15-D19 ──▶ S15-23   S15-D20 ──▶ S15-39   S15-D21 ──▶ S15-40   S15-D22 ──▶ S15-41   S15-D23 ──▶ S15-42
S15-D24 ──▶ S15-45   S15-D25 ──▶ S15-46
S15-D26 ──▶ S15-47   S15-D27 ──▶ S15-48   S15-D28 ──▶ S15-49
```

---

## PR scopes

Input to [`plan-pr`](../../../.agents/skills/plan-pr/SKILL.md). Two to six lines each. Link, do not restate.

### Slice 1 — Source date, privacy, credibility

#### S15-01 — The credibility argument is a text area

**Ships.** The credibility argument on the Source page is a `PVTextArea` like the description (wraps, grows, then scrolls), with the platform's text-area keys and the existing Save button.
**Not this PR.** A shared Save shortcut for every inline editor (the note's idea about `PVInlineEditActions`).
**Check.** A 500-character argument is fully visible and editable; Return adds a line; Save saves it.
**Context.** Rule "The credibility fix is idiomatic and needs no brief"; [note](2026-10-18-credibility-field-truncates-and-ignores-enter.md); `SourcePageCredibilityView.swift`, `SourcePageDescriptionView.swift`.

#### S15-02 — Sources carry a date and a not-public flag

**Ships.** One migration adds `sources.date_value_id` and `sources.is_public`; the catalog model, the Source read and write, the FFI `Source` message and the Sources list read carry both, plus a date sort key from the date-order rule, moved from `conclusionsummaries` to `core/valuecompare`. Audit picks the columns up through the `sources` effect. The list read fetches every date in one batched lookup, never one query per row (3,000 Sources at Scale). The Observation's value-row code for dates, names and depictions moves into the value packages so a Source owns its date the same way, and the auto-reconciler's stored date `sort_key` follows the same date order (user, 2026-11-09).
**Not this PR.** Any chrome (S15-03, S15-04); the Person page (S15-05); Copy Source carrying either (refused for privacy; the date is S15-32, user 2026-11-09).
**Check.** Handler tests: set, read and clear a date and the flag; sort keys order exact, `abt.`, `bef.` and range dates as the Timeline does; an upgraded catalog reads every Source as undated and public.
**Context.** Rules "The Source date is one optional DateValue", "Not public is a stored switch", "One date order" (`core/database/conclusionsummaries/compose.go` `datePlace`, `dateKeyOf`, `dateKeyLess`; `core/valuecompare/datewindow.go` `DateEnds`); [`source-provenance-date.md`](source-provenance-date.md); [privacy note](2026-10-27-source-privacy-toggle.md) "Likely code locations"; skills `add-catalog-migration`, `add-catalog-model`, `add-date-value`, `add-ffi-handler`. Updates [`source-layer-data-model.md`](../../source-layer-data-model.md) § 4.

#### S15-03 — The Source page shows the date and the Private switch

**Ships.** On the Source page, the date is set, changed and cleared from the header with the app's structured date form in a FormDialog (user, 2026-11-09), and a switch labeled "Private" (off by default) is shown and saved. The page moves onto Page columns with its header pinned; at Wide Metadata takes the secondary column (user, 2026-11-09: the move rides in this PR). A write to, or a read of, a Source deleted elsewhere returns `sources.not_found` from `sources`, and the page says so and leaves for the Sources list (UX-1; user, 2026-11-09). A refused date says which field is wrong (UX-2).
**Not this PR.** The Sources list (S15-04); the rest of S15-D1's board (S15-09, S15-23, S15-25); not-found handling for note, metadata and Artifact writes.
**Check.** Bar 1 on the Source page; bar 2.
**Context.** S15-D1; `SourcePageIdentityHeader.swift`, `SourceIdentitySection.swift`, `SourcePageView.swift`, `PVSwitch`, `PVPageColumns`; [`add-localized-string`](../../../.agents/skills/add-localized-string/SKILL.md).

#### S15-04 — The Sources list shows and sorts by the date

**Ships.** Each Sources list row shows the date as its published date, as S15-D2 draws it (under the type at Regular, a Published column at Wide, "No published date" when it has none; the list centers at 1600 at Wide), and `SourcesModel`'s `Sort` gains "Source date, oldest first" and "newest first", ordered by Go's sort key, undated last in both (user, 2026-11-10).
**Not this PR.** Filtering by date or by not public.
**Check.** Bar 1's list half, on a project with dated and undated Sources.
**Context.** S15-D2; `SourcesListRow.swift`, `SourcesListSettings.swift`, `SourcesModel.swift`.

#### S15-32 — Copy Source can carry the date

**Ships.** `CopySourceRequest` gains `copy_date`; `sourcecopy` reads the original's date into the draft and, when chosen, gives the copy its own `date_values` row through `sources.SetDate`. The Copy form shows a Published date tick as S15-D13 draws it, ticked when the original is dated, disabled with "None on this Source" when it is not.
**Not this PR.** Carrying the not-public flag (refused: the copy starts public).
**Check.** Copy a dated Source with the tick on: the copy has the same date and its own row; with it off: undated.
**Context.** S15-D13; rule "The Source date is one optional DateValue"; `core/database/sourcecopy/sourcecopy.go`, `SourceCopyDialog.swift`, `SourceCopyModel.swift`; [`source-layer-data-model.md`](../../source-layer-data-model.md) § 4.2.

### Slice 2 — Metadata at three levels

#### S15-06 — Type suggestions have a level

**Ships.** One `Level` type in `core/vocabkey` (Swift enum and vocabulary parity row). A migration rebuilds `source_type_metadata_fields` with `level` in its key (existing rows become `source`); `sourcevocab` and `sourcetypes` read it (the effects registry and catalog model are unchanged, D-7); the suggestion RPCs take a level and return the type's Source-level field count, and the Source page's board reads `source` only.
**Not this PR.** Artifact and graph values (S15-08); the type page's three lists (S15-12).
**Check.** The Source page's suggestions are unchanged; handler tests add and list suggestions per level; a field suggested at two levels keeps both rows.
**Context.** Rule "Suggestions have a level"; map § 6.6; skills `add-catalog-migration`, `add-catalog-model`, `add-seeded-vocabulary` (update its suggestion shape).

#### S15-07 — Metadata operations take an owner

**Ships.** Preparatory: every exported function of `core/database/sourcemetadata` (`Set`, `Clear`, `DismissSuggestion`, `Reorder`, `ListWorkspace`, `ListBySourceTx`, `ListLayoutTx`, `CreateAll` and the rest) takes an owner (`Level` and id) instead of a Source id, with only the Source wired, one batch read of values by owners is added, and `Apply(tx, owner, draft)` saves a form's draft by comparing it with what is stored, with `CreateAll` as its empty-owner case; `ListWorkspace` reads its fields in one query instead of one per extra value. S15-08 then adds tables, not a second copy of the logic.
**Not this PR.** New tables (S15-08).
**Check.** Every existing metadata test passes unchanged; the Source page behaves the same.
**Context.** Rule "Metadata lives at three levels"; [`source-layer-data-model.md`](../../source-layer-data-model.md) § 5.4 (the merge rules); `core/database/sourcecopy` (its callers). Updates the `sourcemetadata.ListLayoutTx` example in [`add-catalog-query`](../../../.agents/skills/add-catalog-query/SKILL.md).

#### S15-08 — Artifacts and graphs hold metadata

**Ships.** The four tables of map § 6.6, wired for the Artifact and graph owners: catalog model, audit under the Source's scope, delete impact (a field in use in any of the three value tables; layout rows cascade and do not keep a field), release with the Artifact or graph, Copy Source copies a chosen Artifact's values and layout; FFI for the board operations per owner, with suggestions from the Source's type at that level; metadata values and their layout (a `sourcemetadata.Draft`) on `CreateArtifactRequest` and the graph create and update requests, written in the same transaction through `sourcemetadata.Apply`; `metadatafields.UsedBy` and the Metadata page's count come from the delete-impact totals, as do `sourcetypes.UsedBy` and `properties.UsedBy` (plan review M-3; user, 2026-11-11); a Source delete releases each graph's metadata through one graph removal, and the `effects` second-hop ghost lookup is fixed so released rows scope their Source. The Source page's workspace read returns its Artifacts' boards in one query (60 Artifacts at Scale).
**Not this PR.** Search over Artifact or graph values (not this spike); any chrome (S15-09 – S15-11).
**Check.** Handler tests per owner: set, clear, dismiss, reorder, list with suggestions; an Artifact created with values is one audited write; a field in use only on a graph refuses delete and its Used by counts it; Copy Source carries Artifact values; a graph delete releases its rows.
**Context.** Map § 6.6 "Knock-on work"; skills `add-catalog-migration`, `add-catalog-model`, `add-audit-scope`, `add-catalog-delete`, `add-ffi-handler`. Updates [`source-layer-data-model.md`](../../source-layer-data-model.md) §§ 5, 7, 7.1 and [`catalog-deletes.md`](../../catalog-deletes.md).

#### S15-26 — The metadata board takes an owner

**Ships.** Preparatory: `SourceMetadataSection` and `SourcePageMetadataView` become one board model and view over a host (an owner's entries, its write operations and where its failures show), with the page's Add dialog and clear confirm as one page-level model that targets a board; the Swift store's four metadata writes take a `MetadataOwner` (level, id); Set and Clear answer the owner's rows like dismiss and reorder (two wire fields), so Swift stops re-deriving row placement and the Clear rule; `.mutatedSourceMetadata` goes (it reaches the same key as `.mutatedSourceWorkspace` since S15-08). The Source page moves onto it with no visible change.
**Not this PR.** Any new board (S15-09 – S15-11); the draft owner a form uses (S15-10, its first caller; plan D-4 leaves it a slot).
**Check.** The Source page's metadata behaves as before; Swift tests drive the board against a fake owner.
**Context.** Rule "One metadata board"; `macos/App/Features/Sources/SourceMetadataSection.swift`, `SourcePageMetadataView.swift`; [`add-swift-test`](../../../.agents/skills/add-swift-test/SKILL.md).

#### S15-09 — Artifacts show their metadata on the Source page

**Ships.** Each Artifact on the Source page has a metadata board, the S15-26 board with the Artifact as owner, as S15-D1 draws it.
**Also (from S15-08 review, CON-2).** A test that runs the real `artifacts.Delete` and `evidencegraphs.Delete` and resolves each released `*_metadata` and `*_metadata_layout` change on its own, with the rest of the revision as ghosts, to the Source scope. Today only the stub `TestScopeThroughDeletedParent` pins this; resolving the whole revision cannot tell, because the Artifact's own delete already scopes the Source.
**Also (from S15-26 review, MNT-1; required, not only if slow).** A board write patches the cached `sourceWorkspace` instead of reloading it: declare a patch in `CatalogQueryRegistry` (beside `.updatedSourceShell()`) that sets one owner's rows from a mutation carrying them, and have the board host's `didWrite` apply that mutation in place of `.mutatedSourceWorkspace`. Today every save sets the rows, then reloads the whole workspace (every Artifact's board); the reload can also reset a row edit begun before it lands (`SourcePageModel.apply` compares against `appliedWorkspace`).
**Not this PR.** The add flow (S15-10).
**Check.** Bar 3's Artifact half on a census Source.
**Trimmed (user, 2026-11-12).** After review the user rejected the Copy details disclosure on each card (cards grow too tall; S15-D14). Before merge, #802 drops the disclosure, the per-Artifact live boards and the compact board style; it keeps the board write's cache patch, the page-only Artifact write fix (`SourcePageContext.setWorkspace`), the released-metadata scope test, the shared test fixtures, the field-named VoiceOver labels, the pencil inside `PVInlineEdit`, and the reworded refusal; `MetadataBoardStyle` goes with `.compact`. Bar 3's Artifact half moves to S15-34 and S15-35.
**Context.** S15-D1; `SourcePageArtifactsView.swift`, `SourcePageMetadataView.swift`, `MetadataBoardHost.swift`, `MetadataBoardModel.swift`, `MetadataBoardView.swift`.

#### S15-33 — Editing an Artifact can save its metadata

**Ships.** `UpdateArtifactRequest` gains `MetadataDraft metadata` (absent = metadata unchanged; present = the stored values and layout become the draft), saved through `sourcemetadata.Apply` in the update's transaction, as `UpdateEvidenceGraphRequest` field 7 does since S15-08. `UpdateArtifactResponse` and `CreateArtifactResponse` gain `repeated MetadataWorkspaceEntry metadata`, the Artifact's board after the write, as `SetMetadataResponse` returns it (map review K-1). A refused value names its field: `ErrInvalid.WithParams(fieldID)`, as `metadatafields.ErrDuplicateKey.WithParams` does, from one value step that `Set` and `Apply` share, so a form or a live board can put the message under its row (brief review M-1; plan review M-1). One Save is one write and one `Apply` over one owner.
**Not this PR.** Any Swift (S15-36, S15-34).
**Check.** Handler tests: an update with a draft sets, clears, dismisses and reorders in one write and one audit revision, and returns the rows; an update without one leaves the metadata alone; a refused value refuses the whole update and names its field.
**Context.** Rule "Metadata saves with its owner's write"; `api/proto/engine.proto` (`UpdateEvidenceGraphRequest`, `UpdateArtifactRequest`, `SetMetadataResponse`); `core/database/sourcemetadata/sourcemetadata.go` (`Apply`, `ErrInvalid`); `api/ffi/handlers/metadata.go`; skills `add-ffi-handler`, `add-audit-scope`. Precedent: S15-08's graph update.

#### S15-36 — A metadata board can hold a draft

**Ships.** Preparatory, no chrome: the draft board host (conforms to `MetadataBoardHost`, answers rows with the typed value (the board trims) and an empty `openHref` until Save, keeps the clear-a-suggestion rule, sends the whole order; S15-26 plan **Next adds**); a Swift `CatalogMetadataDraft` and its proto mapping; `metadata:` on `GenealogyStore`'s `createArtifact`, `updateArtifact`, `createEvidenceGraph` and `updateEvidenceGraph`, in `GoStore` and `FakeStore`; the add row's state on `MetadataBoardModel` for every host, kept across `resetDrafts`; a no-confirm clear for a draft; a refused value's field param mapped to its row; the starting rows of a draft with no owner yet, mapped from the type's suggestions the form reads (`unsavedRows(from:)`); the returned `metadata` on the Artifact write replies mapped into Swift. Swift tests drive a draft board against `FakeStore`.
**Not this PR.** Any chrome: the sheet and the inline Add field row (S15-34), the graph form (S15-11).
**Check.** Swift tests: a draft collects set, clear, dismiss, reorder and add, writes nothing, and the store write receives the whole draft; a refused value lands on its row.
**Context.** Rules "One metadata board", "A board adds a field in an inline row", "Metadata saves with its owner's write"; S15-26's plan (**Next adds**, D-4); `MetadataBoardHost.swift`, `MetadataBoardModel.swift`, `GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`; skills `add-swift-test`.

#### S15-34 — Artifacts are edited in a sheet

**Ships.** The Artifact's edit control opens the Artifact sheet S15-D14 draws: label, description, the Evidence graphs it is in (with today's unlink locks), and its copy details on S15-36's draft board with the type's `artifact`-level suggestions. One Save sends one `UpdateArtifact` with the draft (S15-33) and applies its effects with `.wroteMetadataBoard` from the returned rows, never `.mutatedSourceWorkspace` (map review K-1); Cancel discards. The sheet's model follows `SourceGraphFormModel` (a `Mode`, one `Draft`, `isDirty = draft != prefill`) so S15-10 adds a mode; `PVFormDialog` gains a scrolling body with a fixed footer, which S15-11's graph form also uses. Each card shows its saved copy details read-only (SA-4) through one value view pulled out of the board's `displayValue` (today's mono text and plain link button, with a line limit; brief review M-6, round 2). "Link to a graph" and "+n more" open the sheet at their section (SA-14). It never calls `SourceArtifactsSection.replace` (which reloads); the Artifact row is patched through `setWorkspace`. Every board's Add field becomes the inline row (S15-36 holds its state): the Add dialog goes with `MetadataBoardAddForm`, its `SourcePageView` presentation and binding, and `isAdding` in `SourcePageModel.acceptsArtifactPageDrop`; the Metadata section's header button opens the row and the empty state loses its button; `MetadataBoardDialogs` keeps only the clear confirm. `PVFormDialog` gains an opt-in scrolling body, and `PVSheet`'s Escape yields to an open row edit or add row; Return in a row confirms the row (SA-15). Card edit state goes (`editingArtifactID`, `PendingEditSwitch`, `labels`, `descriptions`, `fieldErrors`, `cardSaveError`, `saveFields`, `editFields`); `LinkEdit`'s unlink preflight, lock load and the graph-keeps message move into the sheet's model. When a reload clears the add row's picked field because another window added it (S15-36 `resetDrafts`), the row says so and announces it (a new L10n string), instead of blanking the picker silently (S15-36 review UX-2). At Scale: one write per Save, no page reload.
**Also ships (user, 2026-11-13).** The Metadata section's header follows the agreed board: the intro text (`L10n.Sources.metadataIntro`) moves into a help icon's tooltip beside the title (`PVSectionHeader`'s aside slot), the field count (`metadataFieldCount`) goes, and the header button is the ghost "Add field" that opens the inline row. **Wide:** the inline row draws in the 480pt side column at Wide (board frame `meta-add-row-wide`); the sheet is the same at both widths.
**Not this PR.** The list's new layout (S15-35); add mode (S15-10).
**Check.** On a census Source, edit an Artifact: change its label, fill provider and URL, add a field inline, reorder, Save; the card shows the values read-only; Cancel after edits asks to discard; the Source's own board adds a field inline, at Regular and at Wide; the Metadata header shows no count and its help in a tooltip.
**Context.** Rules "An Artifact is added and edited in one sheet", "A board adds a field in an inline row", "One metadata board"; S15-D14; S15-09's plan and Landed note; `SourcePageArtifactsView.swift`, `SourceArtifactsSection.swift`, `MetadataBoardView.swift`, `MetadataBoardDialogs.swift`, `SourceGraphFormModel.swift`, `PVFormDialog.swift`; skills `add-ui-component`, `add-localized-string`, `add-swift-test`. Updates `add-workspace-place` and `docs/macos-client-patterns.md` (an Artifact Save writes `.wroteMetadataBoard`), `macos/App/DesignSystem/README.md` (`pvExpandedState` callers), and the **Next adds** of S15-26's and S15-09's plans (superseded).

#### S15-35 — The Artifact list shows each Artifact's copy details

**Ships.** The Source page's Artifact list takes S15-D14's agreed layout (rows; see the brief's **Board** line): each Artifact shows a 64pt square thumbnail tile (`CachedThumbnail` `.tile`), its label, ref and description, its graphs, its saved copy details (S15-34's read-only view), and its actions and right-click menu (`.pvRightClickMenu`). The card grid and `ArtifactSquarePreview` go. Values come from the workspace read; no new query (60 Artifacts at Scale). **Wide (SA-W1):** the copy-details column is 320pt at Regular and 440pt at Wide, the rows staying in the main column beside the Metadata side column. **The header's type pill (user, 2026-11-13, a long-standing mismatch):** the board draws the type as the kit's **Tag**, not its **Badge**. The kit keeps both, and this PR must not merge them: `PVBadge` (square `radius-xs`, tone fill, uppercase micro caption) stays exactly as it is, and the web kit's `PVTag` (full pill radius, raised surface, subtle border, secondary caption text, a 7pt colour dot, optional remove) is ported to Swift as a new kit component, `macos/App/DesignSystem/Components/Tag/PVTag.swift` (`add-ui-component`; the DesignSystem README lists Tag as not yet ported, and it has two callers: the Source page header and `PersonSourcesSection`). `CatalogSourceTypePill` composes `PVTag` with the record colour as its dot, no icon. **The header's meta row never clips (user, 2026-11-13):** today the type pill is cut off; the ref, type, date and Private wrap as the board's flex row does, and no item is drawn past the row's edge (`PVFlowLayout` places a group at its ideal width even when it is wider than the row; the plan finds and fixes the clip). **The Source description reads smaller (user, 2026-11-13):** the resting description is caption size, muted, normal line height, at the prose measure, as the board draws it (`SourcePageDescriptionView`, today body size, secondary).
**Not this PR.** Editing (S15-34); Move (S15-25).
**Check.** A census Source with 12 Artifacts, three with copy details, reads as a list whose height does not grow with a form; every thumbnail is sharp at 2x; at Wide the copy-details column is wider; the header's type pill matches the board's Tag and is never cut off, at Regular and Wide, with a long type and a range date; `PVBadge` callers look unchanged; the description reads at caption size.
**Context.** Rule "An Artifact is added and edited in one sheet"; S15-D14; `SourcePageArtifactsView.swift` (`ArtifactSquarePreview`), `macos/App/Platform/CachedThumbnail.swift`, `core/derivatives/ensure.go` (`ThumbnailSpec`, 256); `SourcesListRow.swift` (`.pvRightClickMenu` precedent); `SourceTypeMarkers.swift` (`CatalogSourceTypePill`), `SourcePageIdentityHeader.swift` (`metaRow`), `PVFlowLayout.swift`, `PVBadge.swift` (unchanged), `PersonSourcesSection.swift`, `SourcePageDescriptionView.swift`. Updates `macos/App/DesignSystem/README.md` (Tag moves from not-yet-ported to the component table).

#### S15-10 — Adding an Artifact asks for its copy details

**Ships.** Add Artifact opens the Artifact sheet in add mode (S15-D14): the file, label, description, graphs and the type's `artifact`-level copy details on S15-36's draft board. The Artifact and its copy details save in one `CreateArtifact` write; the file then ingests as its own write, as today; a retry after a refused file sends the draft on `UpdateArtifact` (S15-33). The Add Artifact dialog (`addForm`) and its separate `Draft` go.
**Wide:** the sheet is the same at both widths; the page behind it is the Wide Source page (board frames at 2296).
**Not this PR.** Filling them automatically ([`registry-source-import.md`](../../ideas/registry-source-import.md)).
**Check.** Adding a downloaded census image offers provider, URL and accessed date, and the values show on the Artifact afterwards.
**Context.** S15-D14 (S15-D4 was folded into it, 2026-11-12); map § 1 "Copy details are captured when the Artifact is added"; `IngestFileDropRow.swift`, `SourceFormLoadArea.swift`, `SourceArtifactsSection.create()`.

#### S15-11 — Evidence graphs show their metadata

**Ships.** The Evidence graph form becomes the app's first two-column form (880pt at every window width; no fallback, user 2026-11-14): Name, Description and a metadata board for the graph (S15-36's draft board, with S15-34's inline Add field and key order) beside the Artifacts checklist, which keeps its own 264pt scroll; the body uses the kit's scrolling body (user, 2026-11-14). The board carries the type's `graph`-level suggestions and saves with the form's one write. Each graph row on the Source page shows the graph's saved values read-only, through the Artifact row's read-only view made owner-neutral (user, 2026-11-14). Data path (brief review M-1): `GetSourceWorkspaceResponse` carries each graph's board as it carries each Artifact's; the graph create and update replies answer the graph's rows (`ownerBoardProto`, as S15-33's Artifact replies), so a graph Save patches the page through `.wroteMetadataBoard` and never reloads the workspace (S15-33 review M-6 settled). Which graphs the Source has stays with the graph list; the page read adds only values keyed by graph (brief review M2-1). Edit opens at once from the page's values (rule "No engineering for two windows editing the same data"); Add reads the suggestions first through `SourcePageContext.unsavedMetadataRows(level: .graph)`, as Add artifact. One `SourcePageContext` helper applies a Save's rows for the Artifact sheet and the graph form; the open-field message and the "+n more" label become owner-neutral keys (brief review M-3, M-4, M2-2, M2-3). At Scale: 60 graph boards in the page read's one batched `ListWorkspaces`; one write per Save.
**Not this PR.** Nudging researchers toward one graph per household (map § 7); needed-field marks (S15-39); metadata on the graph canvas.
**Check.** Bar 3's graph half: dwelling, family and line on a household graph, shown on its row after Save; a Source with 60 Artifacts opens the form without the body scrolling.
**Context.** S15-D5; map § 6.9; `SourceGraphFormDialog.swift`, `SourceGraphFormModel.swift`, `SourceGraphsSection.swift`, `SourcePageGraphsView.swift`, `ArtifactCopyDetailsView.swift`, `api/ffi/handlers/sources.go` (`GetSourceWorkspace`), `api/ffi/handlers/metadata.go` (`artifactBoardsProto`), `api/ffi/handlers/evidence_graphs.go`; skills `add-ffi-handler`, `add-ui-component`, `add-localized-string`, `add-swift-test`.

#### S15-47 — Adding a Source type opens a dialog

**Ships.** **Add type** at the Source types list's top right opens a form dialog with Label (required), Icon and Description, as Add Source does from the Sources list; Save creates the type through today's `createSourceType` and opens its place (`WorkspaceLocation(section: .sourceTypes, typeId:)`), which shows the side pane until S15-48. The side pane's add mode, its add-suggestions note and `SourceTypesModel`'s `.adding` mode go. The dialog has its own model, opened fresh each time and held by the list model as one optional, as Copy Source's `SourceCopyModel` is (user, 2026-11-14), not `VocabularyPaneMode.adding`; a created type reaches the list through a declared row patch (`.createdSourceType`), and the type's other writes move onto it in S15-48 (user, 2026-11-14); `VocabularyHeader`'s existing top-right Add is rewired (`onAdd`), not moved. The dialog is two columns (board S15-D26, redrawn 2026-11-14): Label, Key and Description on the left, the icon grid inline on the right. The grid (`SourceTypeIconPickerForm`, private in `SourceTypesDetailPane.swift`) moves to its own file in `Features/SourceTypes/` as `SourceTypeIconGrid`, drawn by the dialog and by the side pane's "Choose an icon" sheet now and by the page in S15-48 (`docs/design-system-layers.md` names it as its snowflake example). The owner forms' two-column body (`SourceOwnerFormColumns`) moves to the kit as `PVFormColumns`, its right column's width a parameter, and the dialog uses it (user, 2026-11-14). Rule "A Source type has its own page".
**Not this PR.** The type's own page (S15-48); Copy from (S15-18).
**Check.** Add type, type "Parish register", pick an icon, Save: the new type is selected; Cancel with text asks before discarding.
**Context.** S15-D26; `SourceTypesView.swift` (`VocabularyHeader` add action), `SourceTypesModel.swift` (`openAdd`, `cancelAdd`, `submit`), `SourceTypesDetailPane.swift` (add mode, `SourceTypeIconPickerForm`); precedent the Sources list's Add Source dialog in `SourcesListView.swift`; skills `add-ui-component`, `add-localized-string`, `add-swift-test`.

#### S15-48 — Source types open on their own page

**Ships.** A Source type page: a new presentation in `PlaceRegistry` for `.sourceTypes` with a `typeId` (today's `.sourceTypesDetail` spec, which mounts the list), drawn from scratch on S15-D27's board with Page columns: the header (icon, label, key, origin, usage, delete through DeleteImpact), the details (label, icon, description, Save and Revert), the locked note on a plugin type, and today's Source suggestion list. The list's rows open the page; the list loses its side pane and otherwise looks as today until S15-49. Breadcrumbs ("Source types › Census"), Back and Forward, restore and the omnibar's `source_type` hits already route by `typeId`; the PR checks each lands on the page, and a missing `typeId` falls back to the list (`.missingDeepId`, as today). Delete on the page applies its effects with `session.apply(_:_:leavingPage:)`, as `SourcePageModel` does. Leaving the page with unsaved details asks with the kit's discard confirm (a leave guard, as the citation composer's); Add opens the new type's page and Delete returns to the list, neither with a toast, as Add source and a Source delete (user, 2026-11-15). A click or Return opens a row; the arrow keys only move the highlight (`PVTable` gains `onActivate`, as `PVList` has). A suggestion add or remove applies one `.wroteTypeSuggestions` mutation whose declared patches write the list and the row's count from the reply, and `.typeSuggestions` marks stale when hidden: S15-12's D-1 (`markStale`), D-2 and D-5 at the Source level, moved here (user, 2026-11-15).
**Shape.** `SourceTypesModel` splits: the list model keeps sort, `countLine`, the Add dialog and create; `SourceTypePageModel` *(new)*, built for one `typeId`, holds the edit draft, the locked state, the Source suggestions and delete; `mode`, `syncSelection`, `applySelection`, `clearHistorySelection` and the table's selection binding go (the Sources list → Source page split: `SourcesModel`, `SourcePageModel`). The place declares `viewIdentity: typeId` and a new presentation (`.sourceTypePage`); the place id keeps its name `.sourceTypesDetail`. `WorkspaceLocation.sourceTypePage(typeId:title:)` (added by S15-47) builds the location for the row, Add's Save and later callers. The type's update and delete move onto S15-47's `.sourceTypeRow()` patch and `patchTypesList` goes. `LocationNames` gains a type-label resolver over the cached `sourceTypesList`, used for the leaf crumb and the history menu. `isListRoot` is true for `.sourceTypes` without a `typeId`, and the list restores its scroll anchor on Back, as the Sources list does. The page header and sections reuse `VocabularyPanelHeader`, `VocabularyLabeledSection` and `VocabularyFormActions` when the board's header matches them; otherwise those pieces and `VocabularyPaneMode` move into `Features/Metadata/` in this PR, and `VocabularyPane.swift`'s doc comment stops saying both destinations share them. Tests that change: `PlaceRegistryTests.resolvesSourceTypesWithSelection` (and its table), `WorkspaceDestinationHostTests.presentationSourceTypesRootAndRow`, `WorkspaceSessionTests.applyLocationSourceTypesWithSelection`.
**Not this PR.** The three suggestion lists (S15-12); formats (S15-17); the list's columns and Wide (S15-49); the Metadata page (rule "A Source type has its own page").
**Check.** Click Census in the list: its page opens, the breadcrumb reads "Source types › Census"; Back returns to the list; an omnibar search for "census" opens the page; relaunch restores it; rename the type on its page and the crumb follows; a field's delete-impact row that names a type opens its page; Back to the list keeps its scroll.
**Context.** S15-D27; rule "A Source type has its own page"; `PlaceRegistry.swift` (`.sourceTypesDetail`), `WorkspaceDestinationHost.swift`, `WorkspaceToolbar.swift` (`breadcrumbItems`), `SourceTypesView.swift`, `SourceTypesDetailPane.swift`, `SourceTypesModel.swift`; precedent the Sources list → Source page (`.sourceDetail`, `.sourcePage`); skills `add-workspace-place`, `add-workspace-location`, `add-ui-component`, `add-localized-string`, `add-swift-test`. Updates `add-workspace-place` § 4 and `add-workspace-location` (Source types leaves the master–detail examples: "fields/types" becomes fields).

#### S15-49 — The Source types list is redesigned

**Ships.** The Source types list drawn without a side pane on S15-D28's board: a Used by column at every width, sortable; the origin stays a pill in the Label cell, with no column of its own; at Wide the list centers at `widthListWideMax` with hairlines (`pvListBand`, as the Sources list) and adds a one-line Description column ([`macos-client-patterns.md` § 9](../../macos-client-patterns.md#9-window-widths-regular-and-wide)) (user, 2026-11-15). Sort behaves as today. The list stays on `VocabularyListPane` (its columns are parameters), so the shell stays shared with Metadata; if the board needs more than parameters, the list leaves it and `VocabularyListPane` and `CatalogVocabularyRow` move into `Features/Metadata/`, and `VocabularyListPane.swift`'s doc comment is corrected.
**Not this PR.** The type page (S15-48); the Metadata page's list.
**Check.** The list at Regular and Wide matches the board; sorting by each column still works; a row opens its page.
**Context.** S15-D28; `SourceTypesListPane.swift`, `SourceTypesView.swift`, `Features/CatalogVocabulary/` (`VocabularyListPane`); [`docs/ideas/wide-layout.md`](../../ideas/wide-layout.md) (Source types row); skills `add-ui-component`, `add-localized-string`. Updates `macos-client-patterns.md` § 9 (Source types moves from "List with a side pane" to "List → detail page") and marks the `wide-layout.md` row landed.

#### S15-12 — Source types suggest fields at each level

**Ships.** The Source type page edits three suggestion lists (Source, Artifact, Evidence graph), stacked in its Suggested fields column (S15-D27 TP-7), each in its stored order; a new field goes last, with no reorder (user, 2026-11-14). Return in a list's picker adds the picked field and leaves focus in the empty picker (user, 2026-11-15). The types list's Associated fields column counts all three lists (user, 2026-11-14). How each list's title, meaning and count sit is the board's call.
**Not this PR.** Formats (S15-17); reordering suggestions (not planned).
**Check.** Adding `line_number` to a type's graph list makes it a suggestion on that type's graphs.
**Context.** S15-D6 (an enhancement of S15-D27's page board); `SourceTypePageModel.swift`, `SourceTypeSuggestionList.swift`. S15-48 landed the suggestion-write mutation, its patches and `SourceTypeSuggestionList` at the Source level; S15-12 adds `level` to them (user, 2026-11-15).

### Slice 3 — Printed page

#### S15-50 — Forms list their tab order

**Ships.** A form holds its own `@FocusState` and lists its fields in order, any number; each field's handle is `PVFieldFocus($focus, equals: field, in: order)` *(new)*, whose Tab and Shift-Tab follow that order and leave the ends to the key loop. It replaces `PVTabPair` at every caller, and `PVTabPair` is deleted. A text area's own Tab handling (`PVTextAreaTabRouter`: Tab leaves the area, Option-Tab types a tab) is unchanged. The rule in `add-ui-component` and `DesignSystem/README.md` becomes: when Tab must move from a field that claims Tab to a `PVTextArea`, the form lists the fields in order (user, 2026-11-16: tab order belongs to the form, not to a pair of fields, and lives on the focus handle; review of S15-50, M-1).
**Not this PR.** The composer's third field (S15-13); any form's field order or layout.
**Check.** In each form that used `PVTabPair` (Properties, the Artifact sheet, the graph form, Add type, the composer, the Evidence graph page), Tab and Shift-Tab move between the input and the text area as before.
**Context.** `PVTabPair.swift`, `PVFieldFocus.swift`, `PVTextArea.swift` (`PVTextAreaTabRouter`), `PVInput.swift` (`PVInputTabClaim`); S15-13's review M-1; S15-50's review M-1; skills `add-ui-component`, `add-swift-test`. No brief: no view looks different.

#### S15-13 — The composer records the printed page

**Ships.** The citation composer offers a Printed page field next to Label on image and PDF Artifacts and writes it as `page_label` on the `page` selector; `core/locator` accepts a page selector holding the label alone, since an image has no file page, and depictions still compare file pages only (user, 2026-11-16). The composer chooses its two arrangements by the Regular and Wide classes instead of its own 1400pt rule (user, 2026-11-16).
**Not this PR.** A per-Artifact page map (map § 7); Unknown, Supplied and the needed flag (S15-44, S15-45).
**Check.** A Citation saved with printed page "14" shows "p. 14" on today's citation line.
**Context.** S15-D8; rule "Citations carry no metadata"; [`interpretation-layer-data-model.md`](../../interpretation-layer-data-model.md) § 3.2; `core/locator`; `CitationLocatorDraft.swift`, `CitationFieldsDraft.swift`, `CitationComposerView.swift`. Updates § 3.2 and marks the composer's [`wide-layout.md`](../../ideas/wide-layout.md) row landed.

### Slice 4 — Formats as data

#### S15-14 — The citation format engine

**Ships.** `core/citationformat`: `Parse` to a tree (literals, placeholders with alternatives, groups, italic spans), `Render` through a resolver interface to styled runs and plain text (a resolved value carries its unknown and supplied facts: unknown prints its unknown text, supplied prints in brackets; a date prints with citation terms), each format's needed and used requirements per level, one function from (requirements, resolved values) to what is missing, the pure `core/valuemark` (the unknown and supplied pair and its `Validate`), dates through a new `datevalue.CitationDisplay`, and diagnostics with positions for unknown syntax, an unprefixed `{meta.key}` and unbalanced brackets; the built-ins table; the stored token for a field id and the rewrite between keys and ids. No database.
**Not this PR.** The resolver over the catalog (S15-16); storage (S15-15).
**Check.** Table tests: every syntax rule of map § 6.3, nested groups, escapes, a value holding `*` and `[`, the census example of map § 6.8; requirements for a chain and a group; "n.p.", "[Topeka]", "[ca. 1880]".
**Context.** Rules "Citation formats are data", "Every placeholder names its level", "A format's fields are needed or used", "Dates in citations use citation terms", "A value can be marked unknown or supplied", "No transforms", "One engine, in Go", "Built-in placeholders are one table", "Formats name fields by id"; map § 6.3. Writes the syntax as a domain doc (new `docs/citation-formats.md`, linked from [`source-layer-data-model.md`](../../source-layer-data-model.md)) and adds `CitationDisplay` to [`add-date-value`](../../../.agents/skills/add-date-value/SKILL.md); S15-99 retires the spike's `citation-formats.md`.

#### S15-15 — Source types store citation formats

**Ships.** A migration adds `citation_full`, `citation_short`, `citation_list` to `source_types`; writes resolve `{…meta.key}` to field ids through `metadatafields.ResolveKeysTx`, and reads show keys; a delete-impact probe over the format columns refuses deleting a field a format names, listing the types; the type read and write RPCs carry the formats and their diagnostics; the list form rejects non-Source placeholders. A format edit reports `ListSourceVocabulary`.
**Not this PR.** Rendering a Citation (S15-16); the editor (S15-17).
**Cache signal.** A format write reports `.changedCitationFormats(typeId)` for S15-38's board keys (rule "Requirements need a refresh signal").
**Check.** Handler tests: save and read a format; a key held by a product and a user field resolves to the one chosen; relabel a field and the format still reads; delete a field in use is refused with its types.
**Context.** Rule "Formats name fields by id"; map § 6.3 "Storage"; `core/database/deleteimpact/register.go` (`joinEdge`); skills `add-catalog-migration`, `add-catalog-delete` (gains the text-reference case), `add-ffi-handler`. A format edit refreshes the citations of every Source of the type through the vocabulary signal (500 Sources at Scale).

#### S15-18 — A new type can copy another's formats and suggestions

**Ships.** One engine write creates a type as a copy of another's three formats and suggestions at every level; S15-47's Add type dialog offers **Copy from**.
**Not this PR.** Copying Sources or metadata values.
**Check.** Bar 5's Copy from: a new type copied from Census has its graph suggestions on its page (S15-12) and its formats through the type read (S15-15; on the page once S15-17 lands).
**Context.** S15-D7; map § 6.3 "The editor"; S15-47's Add type dialog file and the Source types list model.

#### S15-19 — Seed the citation types, fields and suggestions

**Ships.** `sourcevocab`'s registry gains the 26 types (with icons from `sourcetypes/icons.go`), 63 fields (with descriptions) and suggestions at their levels in format order (map § 6.8); `birth_certificate` stops suggesting `record_date` and `issue_date`.
**Not this PR.** Formats (S15-20).
**Check.** A new project lists the 26 types; a census Source suggests its Source fields, its Artifacts the copy fields, its graphs the item fields; Install run twice changes nothing.
**Context.** Rule "The seed is the product default"; map § 6.8; skill `add-seeded-vocabulary`. `seedField` gains `UnknownText`, seeded through `Install` ("n.p." on `publication_place` and `publisher`); lands after S15-37. Updates [`seeded-vocabulary.md`](../../seeded-vocabulary.md) § 2 and [`add-seeded-vocabulary`](../../../.agents/skills/add-seeded-vocabulary/SKILL.md) (the `seedFields` shape).

#### S15-20 — Seed the citation formats

**Ships.** Each seeded type's three formats, as in map § 6.8, installed with the types; Install writes them after the fields so keys resolve to ids. Says in the PR how to run Install against an existing dogfood project.
**Not this PR.** Rendering them in the app (S15-16 on).
**Check.** A test renders every seeded format in all three forms against an invented Source of its type and compares the expected text. It deletes S15-14's seed-format corpus (`core/citationformat/testdata/seed-formats.txt`) and `TestSeedFormatsParse`, which this test supersedes.
**Context.** Rules "Follow the style; never copy the book", "The seed is the product default", "Formats name fields by id" (Install calls `metadatafields.ResolveKeysTx`); map § 6.8 "Formats". [`add-seeded-vocabulary`](../../../.agents/skills/add-seeded-vocabulary/SKILL.md) keeps `Install` out of FFI, Swift and open, so the plan names how the dogfood run happens (a test-harness or developer command against a copy of the catalog) and warns that re-running `Install` overwrites edited product labels and formats and restores deleted product rows.

#### S15-37 — Metadata values can be marked unknown or supplied

**Ships.** One migration: `is_unknown` and `is_supplied` (with their checks) on `source_metadata`, `artifact_metadata` and `evidence_graph_metadata`, and `unknown_text` on `source_metadata_fields`. `sourcemetadata.Input` and `Row` carry a `valuemark.Mark` (an unknown row has no text, so `normalizeValue` takes the mark); `metadatafields`' update write takes `unknown_text`; the proto's `ValueMark`; FFI, Copy Source and the audit carry them.
**Not this PR.** The Source date (S15-43), the page (S15-44), rendering (S15-16), any chrome.
**Errors.** Maps S15-14's `valuemark.invalid` in `L10n.Errors`, the first PR that sends it over FFI.
**Check.** Handler tests: a value saved unknown reads back unknown with no text; both facts together are refused through `valuemark.Validate`; Copy Source keeps them; the audit shows the change; a field's unknown text saves.
**Context.** Rule "A value can be marked unknown or supplied"; map § 6.10; skills `add-catalog-migration`, `add-catalog-model`, `add-audit-scope`, `add-ffi-handler`. Updates [`source-layer-data-model.md`](../../source-layer-data-model.md).

#### S15-43 — The Source date can be marked unknown or supplied

**Ships.** One migration: `date_unknown` and `date_supplied` on `sources` (a `valuemark.Mark`; unknown means no `date_value_id`); the Source read and date write; Copy Source carries them with the date when its Published date tick is on; audit.
**Not this PR.** The date dialog (S15-42).
**Check.** Handler tests: a Source marked no date reads back unknown with no date; supplied keeps its DateValue; Copy Source with the tick off carries neither.
**Context.** Rules "The Source date is one optional DateValue on `sources`", "A value can be marked unknown or supplied"; skills `add-catalog-migration`, `add-date-value`. Updates [`source-provenance-date.md`](source-provenance-date.md).

#### S15-44 — The printed page can be marked unknown or supplied

**Ships.** The locator's page selector gains `page_unknown` and `page_supplied` beside `page_label`, checked in `validatePage` through `valuemark.Validate`; `locator.Page` returns the mark, so `graphfill` and the resolver read it. No migration (the locator is JSON).
**Not this PR.** The composer (S15-45).
**Check.** Locator tests: an unknown page has no label; both facts are refused; an old locator reads as unmarked.
**Context.** Rule "A value can be marked unknown or supplied"; `core/locator/validate.go` (`selectorRaw`, `validatePage`), `core/locator/depiction.go` (`Page`), `core/database/graphfill/load.go`. Updates [`interpretation-layer-data-model.md`](../../interpretation-layer-data-model.md) § 3.2 ("An unnumbered page simply omits `page_label`" becomes "is marked unknown").

#### S15-38 — Boards carry their citation's requirements

**Ships.** `listWorkspaces` reads each type's formats once, as it reads suggestions, and annotates every entry with its requirement (needed, used, none) and whether its chain is met at another level (one more batched `listByOwners` over the Sources); needed and used fields are emitted even when not suggested or dismissed; `TypeSuggestion` carries the same for add mode; `DismissSuggestion` refuses a needed field. Every board read and write reply carries the annotation. The Source workspace read carries the Source date's requirement, and the composer's read the printed page's (the plan names that read). `.sourceWorkspace` and the graph board key invalidate on `.changedCitationFormats`. At Scale, 60 Artifacts and 60 graphs share their Source's one type: one format read per type per call.
**Not this PR.** Any drawing of the flags (S15-39 on).
**Check.** Handler tests: on the seeded census type, an Artifact with no URL has `url` needed; a dismissed needed field is still emitted; `line_number` filled on the Source is met for a graph; dismissing a needed field is refused; a format edit marks a visited Source page stale.
**Context.** Rules "Boards flag needed fields; the engine decides the rows", "Requirements need a refresh signal; renders do not", "A format's fields are needed or used"; `core/database/sourcemetadata/sourcemetadata.go` (`listWorkspaces`, `DismissSuggestion`), `api/proto/engine.proto` (`MetadataWorkspaceEntry`, `TypeSuggestion`), `CatalogQueryRegistry.swift` (`.sourceWorkspace`). Updates `docs/catalog-caches.md` and [`source-layer-data-model.md`](../../source-layer-data-model.md) § 5.4 (the merge).

### Slice 5 — Rendering

#### S15-05 — The Person page's Sources section shows each Source's date

**Ships.** The Source record (S16-12) carries the date, and each Source in the Person page's Sources section shows it as S15-D3 draws it. Lands after S16-03, S16-06 and S16-07, which edit `PersonSourcesSection.swift` and `PersonSourcesContent.swift`.
**Not this PR.** Grouped citations (S15-22).
**Check.** Bar 1's Person page half.
**Context.** S15-D3; rule "Build on Spike 16's caches"; S16-12 and S16-13 scopes in [Spike 16's map](../spike-16/deployment-plan.md); `PersonSourcesContent.swift`, `PersonSourcesSection.swift`.

#### S15-16 — Citations render through their type's formats

**Ships.** The catalog resolver for `core/citationformat`, reading SQL: built-ins from the Source row and its date and the Citation's locator and label; metadata at each named level, the Source date and the page, each with its `valuemark` (S15-37, S15-43, S15-44), through S15-07's batch read; one batch render RPC (runs, plain text, group key per Citation; no missing list, rule "A format's fields are needed or used"); one render request for previews; the built-ins table over FFI. A type with no full format renders no text. Nothing is cached.
**Parity.** Adds `api/ffi/swift_vocabulary_test.go` rows for S15-14's `Form`, `Option`, `DiagnosticCode` and built-in names, the first PR that sends them over FFI.
**Not this PR.** Any screen (S15-17, S15-21 – S15-23).
**Check.** Handler tests: the census example renders from values spread over Source, Artifact and graph; 300 and 1,200 Citations render in one call in a fixed number of queries, timed at both.
**Context.** Rules "One engine, in Go", "Citations render on demand, from SQL", "One render request for previews", "Today's line stays the fallback"; map §§ 6.3, 6.5, 6.6.

#### S15-17 — The format editor

**Ships.** The Source type page edits its three formats with Insert field (the built-ins table and the fields, grouped by level, inserting the prefixed form), a live preview against a Source of that type the researcher picks, and the engine's diagnostics shown at their position. Swift does not parse formats.
**Not this PR.** Copy from (S15-18).
**Check.** Bar 5: editing the census full format updates the preview.
**Context.** S15-D16; map § 6.3 "The editor". A new query key goes into `docs/catalog-caches.md` (S16-10) and, if it lands after S16-25, uses S16-25's value keys.

### Slice 6 — Citations in the app

#### S15-21 — The provenance sheet shows formatted citations

**Ships.** When the provenance sheet opens it holds one `CatalogQueryKey` (evicted when hidden) that asks S15-16's batch render for its Citations, and groups them by the returned key; loading and failure use S16-04's `QueryHandle` reading and `PVRetryCallout`; it shows each record's full citation with its Citations beneath, or today's line when the type has no format. Lands after S16-30, which reshapes the sheet's records. The existing Copy citation (`PVClipboardButton`) copies the full or short form as rich and plain text through one rich-payload write added to `PVClipboardCopyState`. `CitationLineDisplay` stays as the fallback and for its other callers.
**Not this PR.** The Sources section (S15-22).
**Check.** Bar 4's provenance sheet; bar 7 on the sheet; copying pastes italics into a rich-text editor.
**Context.** S15-D9 (it draws the sheet's loading and failed states for the on-open call); [`provenance-loading.md`](provenance-loading.md) (this PR starts "Load records when the sheet opens"; update its note when it lands); rules "Grouping is by the rendered full citation", "Citations render on demand, from SQL", "Today's line stays the fallback"; S16-30; `PVProvenanceSheetContent.swift`, `PVProvenanceRecordRow.swift`, `PVClipboardCopyState`, `CitationLineDisplay.swift`.

#### S15-22 — The Sources section groups a Source's Citations by citation

**Ships.** When the Sources section appears it asks S15-16's batch render for its Citations, and a Source's Citations with the same group key show as one citation with the pieces beneath. Lands after S16-03, S16-06 and S16-07.
**Not this PR.** Re-ordering Sources.
**Check.** Bar 7 in the Sources section, on a person cited 5 times on one household.
**Context.** S15-D15; rule "Grouping is by the rendered full citation"; `PersonSourcesContent.swift`.

### Slice 7 — Move

#### S15-24 — Move a bundle to another Source in the engine

**Ships.** The bundle closure, a preflight RPC (the bundle, its Subject counts, the credibility difference) and a move RPC that updates `source_id` on `artifacts`, `evidence_graphs` and `subjects` in one transaction with deferred foreign keys, recording per-row changes so audit (both Sources), `Reads`, search and Spike 16's caches follow from the effects registry; `evidencegraphs.CreateDefault` when the old Source loses its last graph. At Scale a move writes 5 Artifacts, 5 graphs and up to 100 Subjects.
**Not this PR.** Chrome (S15-25); undo; Merge Sources (refused).
**Check.** Handler tests: a single pair, a shared graph pulling in its Artifacts, a bundle of 5 Artifacts and 5 graphs, the last-graph case; refs unchanged; Artifact and graph metadata move with the bundle; both Sources' histories show the move.
**Context.** Rule "A move is the whole bundle"; [`move-artifact-between-sources.md`](move-artifact-between-sources.md); `core/database/effects/registry.go`, `effects/path.go` (`readChangeColumn`); skills `use-catalog-session`, `add-audit-scope`, `add-ffi-handler`. Updates [`interpretation-layer-data-model.md`](../../interpretation-layer-data-model.md) § 4.2 and [`source-layer-data-model.md`](../../source-layer-data-model.md) § 7 (a Subject's and an Artifact's Source can change).

#### S15-25 — Move from an Artifact or a graph

**Ships.** **Move to another Source…** on Artifact rows and graphs on the Source page opens the confirm S15-D10 draws: the target picker, the bundle, and the credibility note when the two Sources' grades differ. After the move, the app lands on the moved Artifact under its new Source.
**Not this PR.** Undo.
**Check.** Bar 8.
**Context.** S15-D10, S15-D1 (graphs), S15-D14 (where Move sits on the Artifact list); [`add-workspace-location`](../../../.agents/skills/add-workspace-location/SKILL.md).

### Slice 8 — Provenance loading

#### S15-30 — The paged fold moves to the kit

**Ships.** Preparatory, Swift: S16-07's fold rule and fold state move from `Features/Conclusions/ConclusionShowMoreRow.swift` to `macos/App/Platform/` beside `FocusClaim`, and its Show more row becomes `DesignSystem/Components/ShowMoreRow/PVShowMoreRow` with a `L10n.DesignSystem` string; the Family, Timeline and Sources sections use them with no visible change. `PVShowMoreRow` also owns the scroll that follows a keyboard Show more (a `ScrollViewReader` in the row scrolls to `revealed` in the same branch that claims focus), so Family's and Sources' `scrollTarget`/`scrollRequest` pairs and their `pvScrollsRowIntoView` go away and a pointer click no longer scrolls (S16-07 ship log MNT-3, UX-5); the Timeline's anchor-top scroll stays its own.
**Not this PR.** The provenance table's fold (S15-27).
**Check.** `scripts/check-guidance-names.py` passes; the sections' fold and focus tests pass unchanged.
**Context.** Rule "The provenance table folds a page at a time"; S16-07; [`add-ui-component`](../../../.agents/skills/add-ui-component/SKILL.md); [`design-system-layers.md`](../../design-system-layers.md).

#### S15-27 — The provenance table folds a page at a time

**Ships.** `PVProvenanceRecordTable` shows 50 citation groups and a `PVShowMoreRow` that reveals the next 50 and moves focus to the first, never splitting a group from its Citations.
**Not this PR.** Loading records on open (S15-29); making the assembly linear (S15-28 and S15-29 send the denial facts); the Why accordion (removed by S15-31).
**Check.** A value with 1,200 records opens on 50 groups; first layout measured in a Release build at 300 and 1,200 records before and after; Tab order holds through the shown rows.
**Context.** S15-D17; rule "The provenance table folds a page at a time"; [`provenance-loading.md`](provenance-loading.md) "Cap" (its Debug timings).

#### S15-31 — Event and Place rows open the provenance sheet

**Ships.** Event and Place pages use `ReconciledValueRow`'s sheet provenance, as `PersonDetailView` does, as S15-D11 and S15-D12 draw it; `ReconciledValueRow.Provenance` and its Why case, `ReconciliationReasoningView`, `ReconciliationRecordRows` and the Why strings are deleted.
**Not this PR.** Loading records on open (S15-29).
**Check.** On an Event and a Place, a value row opens the provenance sheet with the same records the Why showed; `rg` finds no Why type or string.
**Context.** Rule "The Why accordion goes"; `ReconciledValueRow.swift`, `ReconciliationReasoningView.swift`, `EventDetailContent.swift`, `PlaceDetailView.swift`, `PersonDetailView.swift`; [`add-localized-string`](../../../.agents/skills/add-localized-string/SKILL.md) (removed strings). Updates [`macos-client-patterns.md`](../../macos-client-patterns.md) (the sheet-or-Why line).

#### S15-28 — A value's records load on their own

**Ships.** The detail read drops each value's records and adds `FieldRecordCounts` per field, composed from the node's outcome rows and the records tier (no new SQL); one records read takes a row's (owner, Property) pairs and returns its records grouped by pair, each outcome with whether it denied a value and the denier's Source title, and reports its inputs as S16-24's reads do; FFI for both. Each picture's record (`PictureTile.Record`) keeps its outcome. At Scale the records read composes up to 1,200 records from the cache.
**Not this PR.** The app (S15-29).
**Check.** Handler tests: the counts equal today's record-derived counts, including a mixed field's distinct Sources; records for a `.field`, a `.spanning` and a `.derived` row; the Person read's payload measured on a heavily researched person before and after; the records read timed at 1,200 records.
**Context.** Rule "Records load when the sheet opens"; [`provenance-loading.md`](provenance-loading.md) "Load records when the sheet opens"; `core/database/conclusiondetails` (`ReconciledValue.Support`, `Against`, `Outcome.DeniedBy`); S16-11, S16-19, S16-24, S16-30. Updates the `conclusiondetails` package comment ("The Why stays a SQL read …") and [`conclusion-reconciliation.md`](../../conclusion-reconciliation.md) (the detail read returns outcomes with their evidence).

#### S15-29 — The provenance sheet loads its records when it opens

**Ships.** Person, Event and Place rows draw their counts from `FieldRecordCounts`; the sheet's key (S15-21) carries the row's records with their citations, keyed by its (owner, Property) pairs, and refreshes through the registry on the inputs the read reports (once per write that touches them); `ReconciledValueDisplay.distinctSourceCount`, `sourceCount`, the `recordCount` derivation, `deniedSomething` and the denier search go, so the assembly is linear. `.conclusionDetail`'s Source follow (S16-09) is restated for a detail that no longer carries records.
**Not this PR.** The Why accordion, removed by S15-31.
**Check.** Bar 10: the page loads without records; the sheet loads on open, recovers from a failure, and refetches after a write to a cited Source; a sheet of 1,200 records loads and renders, timed.
**Context.** S15-D18; rule "Records load when the sheet opens"; S16-04, S16-09, S16-25; `PVProvenanceSheetContent.swift`, `ReconciledValueDisplay.swift`, `ReconciledValueRowModel.swift` (`RecordsSource`). Updates [`macos-client-patterns.md`](../../macos-client-patterns.md) (the detail key no longer carries every outcome; when `provenanceContent()` is built), [`design-system-layers.md`](../../design-system-layers.md) and [`add-ui-component`](../../../.agents/skills/add-ui-component/SKILL.md) (recipe content built after an async read), and retires [`provenance-loading.md`](provenance-loading.md).

### Slice 9 — Needed fields, unknown and supplied values

#### S15-39 — Metadata boards flag needed fields

**Ships.** The shared board row draws `entry.requirement`: a needed entry with no value flagged unfilled with no dismiss, a hint naming a chain's other levels; a used entry with a quieter mark. Every board gets it at once: the Source page, the Artifact sheet in edit and add mode, the graph form.
**Not this PR.** The Artifact list's mark (S15-40); unknown and supplied (S15-41); the date and the page (S15-42, S15-45).
**Check.** Bar 4's boards: a census Source with no ED shows "Enumeration district" flagged; a census Artifact with no URL shows "URL" flagged in its sheet; a household graph with no item shows "Item" flagged; filling each clears it.
**Context.** S15-D20; rules "Boards flag needed fields; the engine decides the rows", "One metadata board"; `MetadataBoardView.swift`, `MetadataBoardModel.swift`, `MetadataDraftHost.swift`.

#### S15-40 — The Artifact list marks a missing citation field

**Ships.** An Artifact list entry whose entries include a needed one with no value carries a mark; it opens the sheet scrolled to Copy details. A filter over the entries S15-38 already sends.
**Check.** On a census Source, the Artifact with no URL is marked and the others are not.
**Context.** S15-D21; S15-35's list.

#### S15-41 — A metadata row can be marked unknown or supplied

**Ships.** The Unknown and Supplied control, built once beside the board row in `macos/App/Features/Sources/`, on every board's rows; live boards save at once, draft boards with their owner's Save. An unknown row reads as its field's unknown text and is not flagged. The control takes a `PVFieldFocus`, so a form can list it in its Tab order.
**Not this PR.** The Source date (S15-42), the page (S15-45), the unknown text itself (S15-46).
**Check.** Bar 11's metadata half: a book Source with publication place marked unknown is not flagged, and its citation reads "n.p."; a place marked supplied reads "[Topeka]".
**Context.** S15-D22; rule "A value can be marked unknown or supplied"; S15-37, S15-39.

#### S15-42 — The Source date can be unknown, supplied or flagged

**Ships.** The date dialog offers **No date** and **Supplied** (S15-41's control) beside the shared date form; the header shows them, and flags an empty date when the type needs `{source.date}`.
**Not this PR.** The shared date form itself, unchanged.
**Check.** Bar 11's date half: an undated letter dated from its postmark, marked supplied, cites "[12 March 1880]"; one marked no date cites "n.d." and is not flagged.
**Context.** S15-D23; rule "A value can be marked unknown or supplied"; S15-43, S15-38, S15-41; `add-date-value`.

#### S15-45 — The composer marks and flags the printed page

**Ships.** The printed page in the composer takes Unknown and Supplied (S15-41's control) and is flagged when the type needs `{citation.page}` and it is empty.
**Check.** A Citation with its page marked unknown cites "unpaginated" and is not flagged.
**Context.** S15-D24; S15-13, S15-38, S15-41, S15-44; `CitationLocatorDraft.swift`.

#### S15-46 — A field's unknown text is editable

**Ships.** The Metadata page's field editor edits a field's unknown text ("n.p."), through S15-37's write.
**Check.** A researcher's own field given unknown text "not stated" cites it when a value is marked unknown.
**Context.** S15-D25; `macos/App/Features/Metadata/MetadataModel.swift`.

#### S15-23 — The Source page copies its source-list entry

**Ships.** **Copy source-list entry** on the Source page: the list form rendered through the one render request and copied as rich and plain text through S15-21's rich-payload write. A type with no list format offers nothing. **Re-scoped (user, 2026-11-13):** the citation preview (S15-D1 SD-11 – SD-13) is not built; needed fields are flagged on the boards (S15-39, S15-40, S15-11).
**Not this PR.** Copying several Sources' entries ([idea](../../ideas/copy-source-list-entries.md)); notes, which are copied where Citations are shown (S15-21).
**Check.** On a census Source, Copy source-list entry pastes "Kansas. Ottawa County. 1880 U.S. census, population schedule." with its italics into a rich-text editor.
**Context.** S15-D19; rule "Boards flag needed fields; the engine decides the rows"; map § 6.10.
