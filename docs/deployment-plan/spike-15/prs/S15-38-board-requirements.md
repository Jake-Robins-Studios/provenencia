# S15-38 — Boards carry their citation's requirements

**Status:** Draft
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go and the wire only. No view reads the annotation yet; S15-39 draws it on every board, gated by S15-D20; S15-42 and S15-45 draw the date's and the page's)
**Board:** —
**Depends on:** S15-14 (landed [#868](https://github.com/Jake-Robins-Studios/provenencia/pull/868)), S15-15 (landed [#871](https://github.com/Jake-Robins-Studios/provenencia/pull/871)), S15-37 (landed [#879](https://github.com/Jake-Robins-Studios/provenencia/pull/879)); reads the seed of S15-19 (landed #897) and the Source date mark of S15-43 (landed #900)
**Blocks:** S15-39, S15-42, S15-45
**Branch:** `s15-38-board-requirements`
**Version bump:** minor, 0.26.0 → **0.27.0** (if `main`'s `VERSION` is no longer 0.26.0 when you rebase, the next minor after it): a backward-compatible feature, new wire fields and one new RPC old clients ignore, and boards that now list the fields a citation reads ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** working rules "A format's fields are needed or used", "Boards flag needed fields; the engine decides the rows", "Requirements need a refresh signal; renders do not", "A value can be marked unknown or supplied", "Every placeholder names its level; fallback is written" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) §§ 6.3, 6.10; [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) § 5.4; the landed plans [`S15-14-citation-format-engine.md`](S15-14-citation-format-engine.md) (D-13: `Requirements`, `Missing`), [`S15-15-type-stores-citation-formats.md`](S15-15-type-stores-citation-formats.md) (D-9: `StoredFormatsTx`), [`S15-11-graph-metadata.md`](S15-11-graph-metadata.md) (D-1: one board read per page)
**Planned:** 2026-11-19 against `main` @ `5bf7cbd` (compare with `origin/main` after `git fetch origin main`; a local `main` may be stale)
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

Every metadata board the engine returns says, for each field, whether its Source type's citation formats need it, use it, or do not read it, and whether a needed field is already answered by another option of its chain (the Source's value standing in for an empty graph value). A field a format needs or uses comes onto the board even when the type does not suggest it, a needed field comes back even when it was dismissed, and dismissing a needed field is refused. The Source workspace read also says whether the type needs the Source date and the printed page. This is the engine half of dogfood bar 4's "each metadata board flags the fields its type's citation needs and are empty"; the boards draw nothing new yet.

**Why now.** S15-14 derives requirements from a template, S15-15 stores formats by field id, S15-19 seeds formats for 26 types and S15-37 lets a value be marked unknown, which counts as an answer. S15-39 (boards), S15-42 (the Source date) and S15-45 (the composer's page) only draw what this PR sends.

**What stays.** Values, layout rows, the write paths and their audit. A board for a type with no formats comes back exactly as today. `ListTypeSuggestions` and `TypeSuggestion` do not change (D-10). No Swift source changes: only the generated proto (D-12).

## 2. User stories

**US-1.** As a researcher, when I open a Source, each entry on its boards (Source, Artifacts, graphs) carries what the type's citation formats ask of that field, so the boards can flag what is missing.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Seeded census Source, no values; the Source workspace read | The Source board's `jurisdiction` entry is needed, `met_elsewhere` false, no alternatives; `creator` (inside a group) is used; the Artifact board's `url` entry is used |
| AC-1.2 | Seeded census graph with no `line_number`; its Source holds `line_number` = "14" | The graph board's `line_number` entry is used (it sits in a group), so `met_elsewhere` is false. With a type whose full format is `{graph.meta.line_number|source.meta.line_number}.` (outside any group): needed, `met_elsewhere` true, alternatives = [Source · Line number] |
| AC-1.3 | The same custom type; neither the graph nor the Source holds `line_number` | The graph entry is needed, `met_elsewhere` false, alternatives = [Source · Line number] |
| AC-1.4 | The same custom type; the Source's `line_number` is marked unknown (no text) | The graph entry is needed, `met_elsewhere` true (an unknown value answers) |
| AC-1.5 | A type with no formats (the Ledger type of `TestListWorkspaces`) | Every entry's requirement is none; entries and order are as today |
| AC-1.6 | Seeded book Source with `author` = "Ada Robins", no `author_sort` | `author_sort` is emitted (unsuggested, first option of `{source.meta.author_sort|source.meta.author}`), needed, `met_elsewhere` true |

**US-2.** As a researcher, a field the citation reads is on the board where I fill it, and a needed one cannot be waved away.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Seeded birth certificate Source (its formats need `{source.meta.jurisdiction}`, not suggested) | The Source board holds a `jurisdiction` entry: `suggested` false, no value, needed, after the suggestions |
| AC-2.2 | Seeded census Source | The Source board holds no `item`, `line_number`, `folio`, `dwelling_number`, `family_number` or `schedule_number` entry: each is only a fallback (a later option) there (user, 2026-11-19) |
| AC-2.3 | A needed field with a stored `dismissed = 1` layout row and no value | The entry is emitted, in its layout position |
| AC-2.4 | A used, unsuggested field (church register `coverage`) dismissed | Not emitted, as a dismissed suggestion today (user, 2026-11-19) |
| AC-2.5 | `DismissSuggestion` on a needed field with no value | `sourcemetadata.invalid` with the field's id as params[0]; no layout row written |
| AC-2.6 | `DismissSuggestion` on a used field | Writes the layout row as today |
| AC-2.7 | Set, Clear, Reorder, Dismiss, the Artifact writes and the graph writes | Each reply's board entries carry the same annotations as the read |

**US-3.** As a researcher adding an Artifact or a graph, the draft board shows the fields the citation reads before anything is saved.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `GetDraftMetadataBoard` for a seeded census Source at `artifact` | The census artifact suggestions in order, each empty, each annotated (`url` used) |
| AC-3.2 | The custom `line_number` type at `graph`, the Source holding `line_number` | `line_number` is needed with `met_elsewhere` true |
| AC-3.3 | A Source id with no Source; a level `citation` | `sourcemetadata.invalid` |

**US-4.** As a researcher, the Source page and the composer know whether the type needs the Source date and the printed page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Seeded census Source, no date | `GetSourceWorkspaceResponse.date_requirement`: needed, `met_elsewhere` false |
| AC-4.2 | Seeded court report Source (`{citation.page}` outside any group) | `page_requirement`: needed |
| AC-4.3 | Seeded census Source (`[, p. {citation.page}]`) | `page_requirement`: used |
| AC-4.4 | A type with no formats | Both absent |

## 3. Scope

| In | Covered by |
| --- | --- |
| The requirement of each board entry (need, met elsewhere, alternatives), on every board read and write reply | STEP-1, STEP-2, STEP-4, AC-1.*, AC-2.7 |
| Needed and used fields that head a chain are emitted when unsuggested; needed ones also when dismissed | STEP-2, AC-2.1 – AC-2.4 |
| `DismissSuggestion` refuses a needed field | STEP-3, AC-2.5, AC-2.6 |
| The draft board read for add mode (`GetDraftMetadataBoard`) | STEP-5, AC-3.* |
| The Source date's and the printed page's requirement on the Source workspace read | STEP-6, AC-4.* |
| `docs/source-layer-data-model.md` § 5.4: the merge | STEP-7 |

| Out | Home |
| --- | --- |
| Drawing needed and used entries; the hint text; hiding the dismiss X on a needed row; add mode switching to `GetDraftMetadataBoard` | S15-39 |
| The Source date's flag in the header | S15-42 |
| The composer's printed-page flag | S15-45 |
| `CatalogMutation.changedCitationFormats(typeId)`, its `.sourceWorkspace` invalidation and the `docs/catalog-caches.md` row | S15-17 (D-11) |
| The Artifact list mark for a missing field | S15-40 |
| Swift copy for a built-in name in the hint (`CitationBuiltin` parity rows) | S15-16 (its scope already adds built-in names over FFI) |
| A census seed in which the Artifact's URL is needed | Not planned (user, 2026-11-19: the seed stays; the Check names a Source field) |
| A Swift `CoreMethod` constant and store method for `GetDraftMetadataBoard` | S15-39, its first caller |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Board read | `core/database/sourcemetadata/sourcemetadata.go` `listWorkspaces` | Per owner: type id through `store.typeIn`, suggestions per (type, level) with `sourcevocab.ListSuggestionsTx`, values (`readByOwners`), layout (`listLayoutByOwners`), extra fields (`loadFields`). Emits suggestions (dropping dismissed empty ones), then extras, then applies layout order. Knows nothing of formats |
| Exported reads | same file `ListWorkspace`, `ListWorkspaces` | One read transaction, then `listWorkspaces` |
| Entry | same file `WorkspaceEntry` | `Field`, `Value`, `Suggested`, `SortOrder`; no requirement |
| Dismiss | same file `DismissSuggestion` | No-op when a value exists or already dismissed; otherwise writes `layoutDismiss`. Accepts any field |
| Owner type SQL | `core/database/sourcemetadata/owner.go` `stores`, `newStore` (`typeIn`) | `SELECT id, source_type_id …` / `SELECT a.id, s.source_type_id …` / `SELECT g.id, s.source_type_id …`: the owner's id and its Source's type, not the Source's id |
| Requirements | `core/citationformat/requirements.go` `Requirements`, `Missing`, `Need` (`NeedNeeded`, `NeedUsed`) | One requirement per distinct target chain, needed when any template needs it; `Missing` tests each target at the full form with no option, an unknown mark answering |
| Built-ins | `core/citationformat/builtins.go` `LookupBuiltin`, `Builtin.AlwaysSet` | `source.title`, `source.type`, `artifact.label`, `graph.name` always set; `source.date` (Date), `citation.page`, `citation.image`, `citation.label` |
| Stored formats | `core/database/sourcetypes/formats.go` `StoredFormatsTx` | Batched read of the three columns by type id, fields by id (`#<uuid>`); NULL → `""` |
| Source row | `core/database/sources/sources.go` `GetTx` | A Source with `Title`, `SourceTypeID`, `Date` and `DateMark` settled; `ErrNotFound` when missing. `sources` does not import `sourcemetadata` (`go list -deps`) |
| Fields by id | `core/database/metadatafields` `ListByIDsTx` | Fields by id; a missing id is simply absent (`loadFields` turns that into `ErrInvalid`) |
| Wire | `api/proto/engine.proto` `MetadataWorkspaceEntry` (fields 1–10, 3/7/8 reserved), `GetSourceWorkspaceResponse` (up to 10), `Method` (last `METHOD_COPY_SOURCE_TYPE = 122`) | No requirement fields |
| Handlers | `api/ffi/handlers/metadata.go` `ownerBoardsProto`, `ownerBoardProto`, `metadataEntryProto`, `GetMetadataBoard`, `DismissMetadataSuggestion`; `api/ffi/handlers/sources.go` `GetSourceWorkspace`; `api/ffi/handlers/artifacts.go` (lines 70, 142) and `api/ffi/handlers/evidence_graphs.go` (lines 98, 150) call `ownerBoardProto` | Every board on the wire goes through `metadataEntryProto` |
| Dispatch | `api/ffi/dispatch.go` method constants and `switch` (`MethodCopySourceType` → `handlers.CopySourceType`) | One case per method |
| Add mode | `macos/App/Features/Sources/SourcePageContext.swift` `unsavedMetadataRows(level:)` → `store.listTypeSuggestions` → `MetadataDraftHost.unsavedRows(from:)` | Draft boards start from the type's suggestions only. Unchanged here |
| Composer | `macos/App/Features/CitationComposer/CitationComposerModel.swift` `workspaceKey` | The composer already holds the Source's `.sourceWorkspace` key, so the page's requirement rides that read (D-9) |
| Cache | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.sourceWorkspace` | Invalidates on workspace, type, field and suggestion mutations. There is no separate graph board key: graph boards ride `.sourceWorkspace` since S15-11 |
| Tests | `core/database/sourcemetadata/sourcemetadata_test.go` `TestListWorkspaces`, `TestDraftBoardScenarios`, `testWorld` (upserts a birth certificate type with no formats); `api/ffi/handlers/metadata_test.go` `TestGetMetadataBoard`, `TestMetadataOwners`; `api/ffi/handlers/sources_test.go` `TestGetSourceWorkspace`; `api/ffi/handlers/harness_test.go` `sourceFixture` (onboarding project: the full seed, formats included) | Handler tests on the seeded birth certificate see its formats from this PR on (STEP-4) |
| Seed | `core/database/sourcevocab/registry.go` `seedTypes`, `registry_suggestions.go` `seedSuggestions`; `core/database/sourcevocab/sourcevocabtest` `Install` | 26 types with formats. Measured at the planning base (Edges, Real data) |

**Precedent.** S15-37 ([#879](https://github.com/Jake-Robins-Studios/provenencia/pull/879)) added a fact to every board entry (`Row.Mark` → `MetadataWorkspaceEntry.mark`) through `listWorkspaces` and `metadataEntryProto` only, so every read and write reply carried it with no per-handler change: copy that path. S15-11 ([#834](https://github.com/Jake-Robins-Studios/provenencia/pull/834), D-1) is why one `ListWorkspaces` call serves a whole page. S15-15's D-9 is why `StoredFormatsTx` is called once with every type id.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Go type in `core/database/sourcemetadata/requirements.go` *(new)*: `type Requirement struct { Need citationformat.Need; MetElsewhere bool; Alternatives []Alternative }` (zero value = none: `Need == ""`); `type Alternative struct { Level vocabkey.Level; Field *metadatafields.Field; Builtin string }` (exactly one of `Field`, `Builtin`). `WorkspaceEntry` gains `Requirement Requirement` | The board's package owns the merge (rule "Boards flag needed fields; the engine decides the rows"); the need is the engine's own `citationformat.Need`, not a third copy | A `none` constant in `citationformat` — `Requirements` never yields one; a separate annotation package — the merge lives in `listWorkspaces` |
| D-2 | **A field's role in a chain.** For an owner at level L, over every requirement of its type: an option that is a metadata field at L takes the chain's need when it is the **first** option, and `used` when it is a later one. The entry's need is the strongest over all its chains (needed > used > none). Built-in options never make entries | Rule "A format's fields are needed or used": a chain empty everywhere is flagged on its first option | Every option takes the chain's need — the Source's `line_number` would be flagged needed on a census Source that files one graph per household |
| D-3 | **Met elsewhere** is set only on a needed entry: true when every needed chain whose first option is this field is answered by one of its other options, tested with `citationformat.Missing` on the chain without its first target, through the owner's resolver (D-4) | One answer function in the engine (rule "A format's fields are needed or used"); an unknown mark answers (AC-1.4) | Testing the answered rule in `sourcemetadata` — a second copy of `printed` |
| D-4 | **The owner's resolver** (`boardResolver` *(new)*, unexported) answers: a metadata target at the owner's level from the owner's values; at `source` from its Source's values; `source.title` and `source.type` with the Source's title (always set); `source.date` with the Source's `Date` and `DateMark` (`sources.GetTx`); every other target (another Artifact or graph, `citation.*`) with the zero `Value`. For a Source owner, its own values are the Source's | The Source is the one record above an Artifact or a graph; a graph has many Artifacts, so an Artifact option has no single answer there (rule: "one more batched read of the Source's values") | Reading every Artifact of a graph — a Citation picks one, a board cannot |
| D-5 | **Alternatives** on a needed entry: the other options of the needed chains it heads, in chain order, without repeats; a field option as `Field` (its row, for its label), a built-in as its bare name. A field id with no field row is left out | Rule "with a hint naming the others"; the engine names fields so a graph board can name a Source field it does not hold | Sending only ids — the graph form has no Source field list |
| D-6 | **Emission.** A field that heads a needed or used chain at the owner's level and is neither suggested nor valued is emitted as `Suggested: false`, no value, after the suggestions and before the extras, in the order the requirements first name it; then layout order applies as today. A later option that is not suggested and holds no value is not emitted (user, 2026-11-19). A valued extra gets its annotation like any entry | User answer; `Suggested` keeps meaning "the type suggests it" | Emitting every option — six empty rows on every census Source board |
| D-7 | **Dismissed.** A needed entry is emitted whatever its layout row says. A used or unread entry follows its dismissal as a suggestion does today; a dismissed, unsuggested used field is not emitted (user, 2026-11-19) | Needed fields cannot be waved away; used ones are optional | Ignoring dismissal for used fields — the X would do nothing |
| D-8 | **`DismissSuggestion` refuses a needed field** with no value: `ErrInvalid.WithParams(<field wire id>)` (`sourcemetadata.invalid`), checked after `requireOwner` and `loadFields`, before any layout read. The need comes from the same function the read uses (`requirementsFor` *(new)*, one owner). A field with a value keeps today's no-op. `Apply` is unchanged: a draft's dismissed layout row for a needed field is written and ignored by the read (D-7) | Reuses the board's code: Swift never offers it (S15-39), so no new code or copy; one need function for read and refusal | A new error code and message — no screen can reach it |
| D-9 | **Date and page.** `sourcemetadata.SourceRequirements(c *database.Catalog, sourceID []byte) (date, page Requirement, err error)` *(new)*: the requirement of the chains headed by `source.date` and by `citation.page`, with met elsewhere and alternatives through the Source's resolver. `GetSourceWorkspaceResponse` carries them; the composer reads the page's from the `.sourceWorkspace` key it already holds | Rule: "The Source date's requirement rides the Source workspace read; the printed page's, the composer's read". The composer's Source read *is* this read | A field on `GetCitationResponse` — the composer opens on a new Citation with no Citation read |
| D-10 | **Add mode** gets its own read: `GetDraftMetadataBoard` *(new, method 123)* `{project_dir, source_id, level}` → `{repeated MetadataWorkspaceEntry entries}`, Go `sourcemetadata.ListDraftWorkspace(c, sourceID, level)` *(new)*: the type's suggestions at that level in order, empty, plus D-6's emitted fields, annotated through the Source's resolver. `ListTypeSuggestions` and `TypeSuggestion` stay as they are | A draft board needs unsuggested needed fields and the Source's values for met elsewhere; `ListTypeSuggestions` is the type page's edit list and must not grow rows. Replaces the map's "`TypeSuggestion` carries the same annotation"; map edited at planning | Annotating `TypeSuggestion` — no rows for unsuggested fields, no Source to answer from |
| D-11 | **No Swift cache signal here.** `CatalogMutation.changedCitationFormats(typeId)` does not exist until S15-17 (S15-15 D-11, user 2026-11-17: a mutation nothing applies is dead). S15-17 adds the case, applies it, adds it to `.sourceWorkspace`'s `invalidateOn` (`.allCached(.sourceWorkspace)`) and the `docs/catalog-caches.md` row. Map edited at planning | The same reasoning the user gave on 2026-11-17; graph boards have no key of their own since S15-11 | An invalidation for a case that does not exist yet |
| D-12 | No Swift source change. `./scripts/generate-proto.sh` regenerates `macos/App/Platform/Generated/engine.pb.swift`; `GoStore` ignores the new fields | S15-39 is the first reader | Mapping the fields into `CatalogMetadataEntry` now — unread |
| D-13 | **One format read per call.** `listWorkspaces` collects the distinct type ids and calls `sourcetypes.StoredFormatsTx` once; each type's three forms are parsed once (`citationformat.Parse`, ids as stored) and `citationformat.Requirements(full, short, list)` taken once per type. A form that does not parse adds nothing. `SourceRequirements` is a second small read on the page call (one type) | Rule "Requirements need a refresh signal" scope: "one format read per type per call" | Parsing per owner — 121 parses on a census page |
| D-14 | **Source facts.** Each `store.typeIn` returns a third column, the Source id (`id` for a Source, `a.source_id`, `g.source_id`). The Source owners join the owners in the one `readByOwners` call. Each distinct Source is read once with `sources.GetTx` for its title and date | One more batched values read, as the rule says; a page has one Source | A by-ids Source read in `sources` — no caller reads more than one Source per board call (Scale) |
| D-15 | Wire: enum `CitationNeed { CITATION_NEED_UNSPECIFIED = 0; CITATION_NEED_NEEDED = 1; CITATION_NEED_USED = 2; }`; `message CitationRequirement { CitationNeed need = 1; bool met_elsewhere = 2; repeated CitationRequirementOption alternatives = 3; }`; `message CitationRequirementOption { string level = 1; string field_id = 2; string label = 3; string builtin = 4; }`. `MetadataWorkspaceEntry.requirement = 11` and `GetSourceWorkspaceResponse.date_requirement = 11`, `page_requirement = 12`, each absent when the need is none | A proto enum needs no Swift parity row; absent = none keeps old replies byte-identical for types with no formats | A string need — one more parity row |

**Rules this plan bends.** None. The map was edited at planning (2026-11-19): bar 4 and the S15-38 and S15-39 Checks name a Source field, and rule "Boards flag needed fields" gains the later-option and dismissed-used answers (user, 2026-11-19); the cache signal's home moves to S15-17 (D-11) and the add-mode read replaces "`TypeSuggestion` carries the same annotation" (D-10). The implementer edits nothing there.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/sourcemetadata/requirements.go` *(new)* | file | `sourcemetadata.go` | Keeps the 1,087-line file from growing by the requirement merge; same package |
| `Requirement`, `Alternative` *(new)* | type | `citationformat.Requirement` | That is a chain of targets; this is one field's role on one board. It wraps `citationformat.Need` |
| `boardResolver` *(new)* | type | `citationformat.Resolver` (interface) | Implements it; no catalog resolver exists before S15-16 |
| `requirementsFor` *(new)* | func | `citationformat.Requirements` | Calls it once per type, then maps chains onto one level's fields (D-2, D-3) |
| `ListDraftWorkspace` *(new)* | func | `ListWorkspaces` | Same assembly (`buildEntries`) with no values or layout; a draft has no owner row |
| `buildEntries` *(new)* | func | the per-owner loop at the end of `listWorkspaces` | Extracted, not copied, so the draft and the owner board share it |
| `SourceRequirements` *(new)* | func | — | Built-ins have no entry; searched `Requirements(` callers: only tests and `sourcevocab` registry tests |
| `GetDraftMetadataBoard` *(new)* | FFI | `GetMetadataBoard` | That takes an owner that exists; a draft has none (D-10) |
| `CitationNeed`, `CitationRequirement`, `CitationRequirementOption` *(new)* | proto | `ValueMark` (one shared message per fact) | One message for every holder, as `ValueMark` |
| `requirementProto` *(new)* | helper | `valueMarkProto` | Same pattern |

**Builds on.** S15-37's path (`listWorkspaces` → `metadataEntryProto`); `sqlbatch` via `StoredFormatsTx`; `citationformat.Missing` for every answered test.
**Deletes.** None — nothing becomes dead. `TypeSuggestion` stays for the type page; `MetadataDraftHost.unsavedRows(from:)` is retired by S15-39 when add mode moves to `GetDraftMetadataBoard`.
**Next adds.** S15-39 reads `entry.requirement` and calls `GetDraftMetadataBoard`. S15-40 filters the Artifact boards for a needed, unvalued, unmet entry. S15-42 reads `date_requirement`; S15-45 reads `page_requirement`. S15-16's catalog resolver can start from `boardResolver`'s Source half. S15-17 adds the invalidation (D-11).

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A board entry with no value that is not suggested (D-6) | Swift `CatalogMetadataEntry` mapping, the board views | Today no entry arrives unsuggested and empty (a cleared extra leaves the board). `GoStore` maps it like any entry, and the board draws it as an empty row until S15-39 draws the flag. The manual check (§10) opens a birth certificate Source to confirm the page shows it without error |
| A dismissed needed field coming back (D-7) | the board's dismiss X | Pressing it now returns `sourcemetadata.invalid`, which `L10n.Errors` already maps; S15-39 hides the X |
| A format naming a field id with no field row | `requirementsFor` | Skipped (D-5); test T-6 |

### Scale

At the map's Scale (a census Source with 60 Artifacts and 60 graphs, one type): the page read adds one `StoredFormatsTx` query, 3 parses, one `Requirements`, one Source read and the Source's values inside the existing `readByOwners` (the Source is already an owner on that call). Per owner the work is requirements × options (census: 25 chains, ≤ 3 options). `SourceRequirements` adds one more format read for one type. No write changes what it invalidates. T-9 builds the 121-owner census page and counts queries: no growth with owners beyond today's per-level batches.

### Edges

- **Assumptions.** `listWorkspaces` assumes each owner's entries hold each field once: an unsuggested required field is added only when it is not already a suggestion or a valued extra (one `seen` set over the three sources) — T-3. It assumes `loadFields` fails on a missing id: requirement fields use `metadatafields.ListByIDsTx` directly and skip absent ids — T-6. `Requirements` keys chains by target sequence: the same field in two chains is two requirements and D-2 takes the strongest — T-2 (`item` in census full and short).
- **Neighbors.** A chain whose first option is a built-in (`{source.meta.short_title|source.title}` → used because `title` is always set; `{citation.page|source.meta.page_range}` → `page_range` used on the Source, the page needed on the workspace read) — T-2, T-7. A needed field with a value: need needed, `met_elsewhere` from the other options only — T-2. A needed field marked unknown: has a value row, so not missing — T-2.
- **Removed inputs.** A dismissed needed field is shown again (D-7); its layout row is kept, so it hides again if the format stops needing it — T-4. A type whose formats are cleared: entries return to today's shape on the next read (no cache in Go; Swift's refresh is S15-17) — T-5.
- **Real data.** Run at the planning base over the 26 seeded types (full, short, list): 30 needed Source fields; **no Artifact or graph field is needed in any type** (every one sits in a group); built-ins needed: `source.date` in census, interview, oral testimony, correspondence and newspaper item, `citation.page` in court report. Unsuggested first options emitted (D-6), all at the Source level, 32 rows over the types: `short_title` used (16 types), `coverage` used (6), `jurisdiction` needed (the three certificates), `author_sort` needed (book, journal article, broadcast), `collection` used (passenger list, case file), `creator` and `repository` used (passenger list). Fallback options left off, 31 rows: `item` (18 types), `entry_number` (5), `folio` (2), `line_number` (2), `column`, `dwelling_number`, `family_number`, `schedule_number` (1 each). T-8 runs the seed and pins these counts.
- **Untrusted size.** Formats come from the catalog. Each text is at most `citationformat.MaxFormatBytes` (4096) before parsing, so a type has at most about 1,400 placeholders over three forms; options per chain are bounded by the same text. Work per owner is chains × options; no recursion. Alternatives are deduplicated per entry.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcemetadata/owner.go` | `typeIn` strings select a third column, the Source id; `listWorkspaces` scans it |
| `core/database/sourcemetadata/requirements.go` *(new)* | `Requirement`, `Alternative` (D-1); `type typeRequirements struct { chains []citationformat.Requirement }` read by `loadTypeRequirements(tx, typeIDs [][]byte) (map[string][]citationformat.Requirement, error)` (D-13); `boardResolver` (D-4); `requirementsFor(chains, level, resolver, fields map[string]metadatafields.Field) (map[string]Requirement, []fieldOrder)` — the per-field annotation of D-2, D-3, D-5 and the D-6 emission order; `SourceRequirements` (D-9) |
| `core/database/sourcemetadata/sourcemetadata.go` | `WorkspaceEntry.Requirement`; `listWorkspaces` gathers Source ids, reads Source values with the owners, reads formats once, annotates through `buildEntries` *(extracted)*; `ListDraftWorkspace` (D-10); `DismissSuggestion` refusal (D-8) |

```go
// ListDraftWorkspace is the board a new owner at level starts with on the
// Source: the type's suggestions there, empty, and the fields its citation
// formats need or use at that level (D-6), each with its Requirement. A missing
// Source, or a level with no store, is ErrInvalid.
func ListDraftWorkspace(c *database.Catalog, sourceID []byte, level vocabkey.Level) ([]WorkspaceEntry, error)

// SourceRequirements is what the Source's type asks of the Source date and of
// a Citation's printed page. A missing Source is ErrInvalid.
func SourceRequirements(c *database.Catalog, sourceID []byte) (date, page Requirement, err error)
```

Errors: `sourcemetadata.invalid` → a needed field dismissed; a draft board for a missing Source or a non-metadata level.

### FFI

`api/proto/engine.proto`: D-15's enum and two messages; `MetadataWorkspaceEntry.requirement = 11`; `GetSourceWorkspaceResponse.date_requirement = 11`, `page_requirement = 12`; `METHOD_GET_DRAFT_METADATA_BOARD = 123`; `GetDraftMetadataBoardRequest { string project_dir = 1; string source_id = 2; string level = 3; }`, `GetDraftMetadataBoardResponse { repeated MetadataWorkspaceEntry entries = 1; }`. Handler `GetDraftMetadataBoard` in `api/ffi/handlers/metadata.go` (`withProjectCatalog`, as `GetMetadataBoard`); `requirementProto(r sourcemetadata.Requirement) *engine.CitationRequirement` (nil when none) used by `metadataEntryProto` and `GetSourceWorkspace`. `api/ffi/dispatch.go`: `MethodGetDraftMetadataBoard` and its case. Regenerate with `./scripts/generate-proto.sh`.

### macOS

None — generated proto only (D-12).

### Strings

None — no copy. The refusal reuses `sourcemetadata.invalid`.

## 7. Steps

**STEP-1 — Requirements per type and per field**
Files: `core/database/sourcemetadata/requirements.go` *(new)*, `core/database/sourcemetadata/requirements_test.go` *(new)*. Skill: `add-catalog-query`.
Do: D-1, D-2, D-3, D-4, D-5, D-13: `loadTypeRequirements`, `boardResolver`, `requirementsFor`. Field targets carry `uuid.UUID` ids; compare as `id[:]` with the field id bytes.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/ -run 'TestRequirementsFor'` passes (T-1, T-2).

**STEP-2 — The board merge**
Files: `core/database/sourcemetadata/owner.go`, `core/database/sourcemetadata/sourcemetadata.go`, `core/database/sourcemetadata/sourcemetadata_test.go`.
Do: D-6, D-7, D-14: Source id in `typeIn`; Source owners in the `readByOwners` call; one `sources.GetTx` per distinct Source; `buildEntries` extracted from the end of `listWorkspaces`, now taking the annotation map and D-6's emission list; requirement fields loaded with `metadatafields.ListByIDsTx` alongside the extras. Update the doc comments on `ListWorkspace` and `WorkspaceEntry`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/` passes, `TestListWorkspaces` unchanged (Ledger type has no formats, AC-1.5), T-3 – T-6 added.

**STEP-3 — Dismiss refusal**
Files: `core/database/sourcemetadata/sourcemetadata.go` `DismissSuggestion`, its test.
Do: D-8.
Check: T-4's dismiss rows pass.

**STEP-4 — Wire and every board reply**
Files: `api/proto/engine.proto`, `api/ffi/handlers/metadata.go`, `api/ffi/handlers/metadata_test.go`, generated `api/proto/engine/*.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`. Skill: `add-ffi-handler`.
Do: D-15 messages and the entry field; `requirementProto`; `metadataEntryProto` sets `Requirement`. Run `./scripts/generate-proto.sh`. Handler tests on the seeded birth certificate that compare a whole Source board gain the `jurisdiction` entry and the annotations: update those expectations only, and name each changed test in the PR body.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/...` passes; T-10 (Set, Dismiss, Reorder, Clear replies) passes.

**STEP-5 — Draft board RPC**
Files: `core/database/sourcemetadata/sourcemetadata.go` `ListDraftWorkspace`, `api/proto/engine.proto`, `api/ffi/handlers/metadata.go` `GetDraftMetadataBoard` *(new)*, `api/ffi/dispatch.go`, tests. Skills: `add-ffi-handler`, `use-catalog-session`.
Do: D-10.
Check: T-11 passes; `./scripts/generate-proto.sh` leaves no diff after a second run.

**STEP-6 — Date and page on the Source workspace**
Files: `core/database/sourcemetadata/requirements.go` *(new)* `SourceRequirements`, `api/proto/engine.proto`, `api/ffi/handlers/sources.go` `GetSourceWorkspace`, `api/ffi/handlers/sources_test.go`.
Do: D-9.
Check: T-7, T-12 pass.

**STEP-7 — Seed run, scale, docs**
Files: `core/database/sourcemetadata/requirements_test.go` *(new)* (T-8, T-9), `docs/source-layer-data-model.md` § 5.4, `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`, this plan, `deployment-plan.md` (map row status), `completed.md`.
Do: § 5.4 gains a paragraph: the merge reads the type's three formats; each entry carries needed, used or none and met elsewhere; a chain heads on its first option; needed fields always show and refuse dismissal; unsuggested first options show; later options show only where suggested or valued. Version bump. Then the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcemetadata/requirements_test.go` `TestRequirementsFor` *(new)* | Table over hand-written formats: `{source.meta.a}` → a needed; `[{source.meta.a}]` → used; `{graph.meta.a|source.meta.a}.` at graph → a needed with alt [source a], at source → a used; `{source.meta.a|source.title}` → used; `{citation.page|source.meta.p}` at source → p used | D-2, D-5 |
| T-2 | Go | same, `TestRequirementsForMet` *(new)* | Resolver cases: Source holds a → graph a met; Source a marked unknown → met; nothing → not met; graph a valued and Source empty → needed, not met elsewhere; `item` in two chains (full needed, short used) → needed | AC-1.2, AC-1.3, AC-1.4, AC-1.6, D-3 |
| T-3 | Go | `sourcemetadata_test.go` `TestListWorkspacesRequirements` *(new)* | `sourcevocabtest.Install`: birth certificate Source → `jurisdiction` emitted unsuggested needed after suggestions; census Source → no `item`/`line_number`/`folio`/`dwelling_number`/`family_number`/`schedule_number`; a valued extra that a format reads is annotated, once | AC-2.1, AC-2.2, AC-1.1 |
| T-4 | Go | same, `TestRequirementsDismiss` *(new)* | Dismiss on `jurisdiction` → `sourcemetadata.invalid` params[0] its id, no layout row; a stored dismissed row for it (written by `Apply`) → still emitted at its layout position; dismiss church register `coverage` → hidden | AC-2.3, AC-2.4, AC-2.5, AC-2.6, D-8 |
| T-5 | Go | same, `TestRequirementsFollowFormats` *(new)* | Custom type with `{graph.meta.line_number|source.meta.line_number}.`; then formats cleared (`sourcetypes.UpdateFormats` with empty) → entries back to suggestions only, requirements none | AC-1.2, AC-1.5 |
| T-6 | Go | same, `TestRequirementsMissingField` *(new)* | A stored format naming `#<uuid>` with no field row → no entry, no alternative, no error | D-5, AC-1.5 |
| T-7 | Go | `requirements_test.go` `TestSourceRequirements` *(new)* | Census → date needed, page used; court report → page needed; Ledger → both none; missing Source → `sourcemetadata.invalid` | AC-4.1, AC-4.2, AC-4.3, AC-4.4 |
| T-8 | Go | same, `TestSeedRequirements` *(new)* | Every seeded type through `requirementsFor` with empty values: 30 needed Source fields, 0 needed Artifact or graph fields, 32 emitted unsuggested rows and 31 fallbacks left off as listed in Edges, `source.date` needed in 5 types, `citation.page` needed in 1 | D-2, D-6, AC-2.2 |
| T-9 | Go | same, `TestListWorkspacesRequirementsScale` *(new)* | Census Source with 60 Artifacts and 60 graphs, one `ListWorkspaces` call: one `StoredFormatsTx` read (count through a query-counting `database.Querier` wrapper or the statement count), annotations on all 121 boards | Scale, D-13 |
| T-10 | Go | `api/ffi/handlers/metadata_test.go` `TestMetadataBoardRequirements` *(new)* | Seeded census project (`sourceFixture` then the census type): Source workspace read → `jurisdiction` needed, Artifact `url` used; `SetMetadata` jurisdiction → reply entry needed with value; `DismissMetadataSuggestion` jurisdiction → `sourcemetadata.invalid` | AC-1.1, AC-2.5, AC-2.7 |
| T-11 | Go | same, `TestGetDraftMetadataBoard` *(new)* | Census artifact level → suggestions in order, `url` used; custom type graph level with Source `line_number` → needed, met (AC-3.2); bad Source id, level `citation` → `sourcemetadata.invalid` | AC-3.1, AC-3.2, AC-3.3 |
| T-12 | Go | `api/ffi/handlers/sources_test.go` `TestGetSourceWorkspace` (new rows) | Census → `date_requirement` needed, `page_requirement` used; a type with no formats → both nil | AC-4.1, AC-4.3, AC-4.4 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: whole-board expectations in `api/ffi/handlers/metadata_test.go`, `sources_test.go`, `source_write_effects_test.go`, and the artifact and graph handler tests on the seeded birth certificate (STEP-4).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (not gated: none)
- [ ] Domain doc updated: docs/source-layer-data-model.md § 5.4 (the merge)
- [ ] PR description: what shipped, AC evidence, deviations, the whole-board tests whose expectations changed, manual check
```

## 10. Manual check

1. Build and run the app on a new project (the seed installs). Add a Source of type Birth certificate. Its page opens with no error; the Metadata section shows a Jurisdiction row with no value after the suggested rows (drawn as an ordinary empty row until S15-39).
2. Press the dismiss X on that Jurisdiction row. The page shows the existing metadata error message, and the row stays.
3. Add a Census Source; its Metadata section shows no Item, Line number or Folio row.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Whole-board handler tests break on the seeded birth certificate | STEP-4 updates only those expectations and lists them in the PR body |
| An empty unsuggested row confuses a researcher before S15-39 | Only types whose formats need an unsuggested field show one (Edges counts); S15-39 is next in slice 9 |
| A second Source read per page | One row by primary key (D-14) |

**Stop and report if:**

- `listWorkspaces`, `DismissSuggestion` or `store.typeIn` no longer match §4.
- `citationformat.Requirements` or `Missing` changed signature, or `Missing` no longer counts an unknown mark as an answer.
- Importing `core/database/sources` from `sourcemetadata` makes an import cycle (`go build ./...` fails with one).
- T-8's counts differ from Edges (the seed changed): report the new counts before changing the test.
- A handler test outside STEP-4's list needs a change other than the added entry and annotations.
- Method number 123 is taken on `main`.

## 12. Open questions

None.

## 13. PR

**Title:** S15-38 — Boards carry their citation's requirements
**Body:** objective in one sentence; what shipped against US-1 – US-4; AC evidence; deviations from the plan; the whole-board tests whose expectations changed; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-38-board-requirements.md`.
