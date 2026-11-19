# S15-38 — Boards carry their citation's requirements

**Status:** Landed in [#910](https://github.com/Jake-Robins-Studios/provenencia/pull/910) (2026-11-19)
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go and the wire only. The board draws neither an unsuggested empty entry nor the annotation yet (`MetadataBoardModel.saved` / `suggested`); S15-39 draws them, gated by S15-D20; S15-42 and S15-45 draw the date's and the page's)
**Board:** —
**Depends on:** S15-14 (landed [#868](https://github.com/Jake-Robins-Studios/provenencia/pull/868)), S15-15 (landed [#871](https://github.com/Jake-Robins-Studios/provenencia/pull/871)), S15-37 (landed [#879](https://github.com/Jake-Robins-Studios/provenencia/pull/879)); reads the seed of S15-19 (landed #897) and the Source date mark of S15-43 (landed #900)
**Blocks:** S15-39, S15-42, S15-45
**Branch:** `s15-38-board-requirements`
**Version bump:** minor, 0.26.0 → **0.27.0** (if `main`'s `VERSION` is no longer 0.26.0 when you rebase, the next minor after it): a backward-compatible feature, new wire fields and one new RPC old clients ignore, and boards that now carry the fields a citation reads ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/macos-client.mdc` (the draft-board scenario file records every board rule `MetadataDraftHost` mirrors; D-17)
**Context:** working rules "A format's fields are needed or used", "Boards flag needed fields; the engine decides the rows", "Requirements need a refresh signal; renders do not", "A value can be marked unknown or supplied", "Every placeholder names its level; fallback is written" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) §§ 6.3, 6.10; [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) § 5.4; the landed plans [`S15-14-citation-format-engine.md`](S15-14-citation-format-engine.md) (D-13: `Requirements`, `Missing`), [`S15-15-type-stores-citation-formats.md`](S15-15-type-stores-citation-formats.md) (D-9: `StoredFormatsTx`), [`S15-11-graph-metadata.md`](S15-11-graph-metadata.md) (D-1: one board read per page)
**Planned:** 2026-11-19 against `main` @ `5bf7cbd` (compare with `origin/main` after `git fetch origin main`; a local `main` may be stale)
**Review:** [`S15-38-board-requirements.review.md`](S15-38-board-requirements.review.md) — Fits with changes / Ready with changes, 2 rounds; every finding Fixed except the query counter (Declined, home S15-16); nothing open

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

Every metadata board the engine returns says, for each field, whether its Source type's citation formats need it, use it, or do not read it, and whether a needed field is already answered by another option of its chain (the Source's value standing in for an empty graph value). A field that heads a chain comes onto the board even when the type does not suggest it, a needed field comes back even when it was dismissed, and dismissing a needed field is refused. The Source workspace read also says what the type asks of the Source date and the printed page. This is the engine half of dogfood bar 4's "each metadata board flags the fields its type's citation needs and are empty"; no view draws it yet.

**Why now.** S15-14 derives requirements from a template, S15-15 stores formats by field id, S15-19 seeds formats for 26 types and S15-37 lets a value be marked unknown, which counts as an answer. S15-39 (boards), S15-42 (the Source date) and S15-45 (the composer's page) only draw what this PR sends.

**What stays.** Values, layout rows, the write paths and their audit. A board for a type with no formats comes back exactly as today. `ListTypeSuggestions` and `TypeSuggestion` do not change (D-10). No Swift source changes: only the generated proto (D-12).

## 2. User stories

**US-1.** As a researcher, when I open a Source, each entry on its boards (Source, Artifacts, graphs) carries what the type's citation formats ask of that field, so the boards can flag what is missing.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Seeded census Source, no values; the Source workspace read | The Source board's `jurisdiction` entry is needed, `met_elsewhere` false, no alternatives; `creator` (inside a group) is used; the Artifact board's `url` entry is used |
| AC-1.2 | A custom type whose full format is `{graph.meta.line_number|source.meta.line_number}.`; a graph with no `line_number`; its Source holds "14" | The graph entry is needed, `met_elsewhere` true, alternatives = [source · Line] |
| AC-1.3 | The same type; neither holds `line_number` | The graph entry is needed, `met_elsewhere` false, alternatives = [source · Line] |
| AC-1.4 | The same type; the Source's `line_number` is marked unknown (no text) | The graph entry is needed, `met_elsewhere` true (an unknown value answers) |
| AC-1.5 | A type with no formats (the Ledger type of `TestListWorkspaces`) | Every entry's annotation is none; entries and order are as today |
| AC-1.6 | Seeded book Source with `author` = "Ada Robins", no `author_sort` | `author_sort` is emitted (unsuggested, first option of `{source.meta.author_sort|source.meta.author}`), needed, `met_elsewhere` true |

**US-2.** As a researcher, a field the citation reads is on the board where I fill it, and a needed one cannot be waved away.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Seeded birth certificate Source (its list form needs `{source.meta.jurisdiction}`, not suggested) | The Source board holds a `jurisdiction` entry: `suggested` false, no value, needed, after the suggestions |
| AC-2.2 | Seeded census Source | The Source board holds no `item`, `line_number`, `folio`, `dwelling_number`, `family_number` or `schedule_number` entry: each is only a later option there (user, 2026-11-19) |
| AC-2.3 | A needed field with a stored `dismissed = 1` layout row and no value | The entry is emitted, in its layout position |
| AC-2.4 | A used, unsuggested field (church register `coverage`) dismissed | Not emitted, as a dismissed suggestion today (user, 2026-11-19) |
| AC-2.5 | `DismissSuggestion` on a needed field with no value | `sourcemetadata.invalid` with the field's id as params[0]; no layout row written |
| AC-2.6 | `DismissSuggestion` on a used field | Writes the layout row as today |
| AC-2.7 | Set, Clear, Reorder, Dismiss, the Artifact writes and the graph writes | Each reply's board entries carry the same annotations as the read |

**US-3.** As a researcher adding an Artifact or a graph, the draft board knows the fields the citation reads before anything is saved.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `GetDraftMetadataBoard` for a seeded census Source at `artifact` | The census artifact suggestions in order, each empty, each annotated (`url` used) |
| AC-3.2 | The AC-1.2 type at `graph`, the Source holding `line_number` | `line_number` needed, `met_elsewhere` true |
| AC-3.3 | A well-formed Source id with no Source; a level `source` or `citation` | `sourcemetadata.invalid`. A malformed id is `request.invalid_id` (`parseID`), as for `GetMetadataBoard` |

**US-4.** As a researcher, the Source page and the composer know what the type asks of the Source date and the printed page.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | Seeded census Source, no date | `GetSourceWorkspaceResponse.date_requirement`: needed, `met_elsewhere` false |
| AC-4.2 | Seeded court report Source (`{citation.page|source.meta.page_range}` outside any group), no `page_range` | `page_requirement`: needed, `met_elsewhere` false, alternatives = [source · Pages] |
| AC-4.3 | Seeded census Source (`[, p. {citation.page}]`) | `page_requirement`: used |
| AC-4.4 | A type with no formats | Both absent |

## 3. Scope

| In | Covered by |
| --- | --- |
| One parse of a type's stored formats, shared with the format editor's read | STEP-1, D-13 |
| The value a stored metadata value and a Source date give a citation, exported for S15-16 | STEP-2, D-4 |
| The annotation of each head (field or built-in): need, met elsewhere, alternatives | STEP-3, AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.6 |
| The board merge: annotations on every board read and write reply; heads emitted when unsuggested; needed ones when dismissed; the date's and page's on a Source board | STEP-4, AC-1.5, AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.7 |
| `DismissSuggestion` refuses a needed field | STEP-5, AC-2.5, AC-2.6 |
| The wire, and the date and page on the Source workspace read | STEP-6, AC-4.1, AC-4.2, AC-4.3, AC-4.4 |
| The draft board read for add mode (`GetDraftMetadataBoard`) | STEP-7, AC-3.1, AC-3.2, AC-3.3 |
| `docs/source-layer-data-model.md` § 5.4: the merge and the Dismiss bullet | STEP-8 |

| Out | Home |
| --- | --- |
| Drawing needed, used and unsuggested empty entries; the hint text; hiding the dismiss X on a needed row; add mode switching to `GetDraftMetadataBoard` | S15-39 |
| The Source date's flag in the header | S15-42 |
| The composer's printed-page flag | S15-45 |
| `CatalogMutation.changedCitationFormats(typeId)`, its `.sourceWorkspace` invalidation and the `docs/catalog-caches.md` row | S15-17 (D-11) |
| The catalog resolver for rendering (Citation-level built-ins, the Citation's own Artifact and graph) | S15-16, built on `sourcemetadata.CitationValue` and `sources.CitationDate` (D-4) |
| The Artifact list mark for a missing field | S15-40 |
| Swift copy for a built-in name in the hint (`CitationBuiltin` parity rows) | S15-16 (its scope already adds built-in names over FFI) |
| A census seed in which the Artifact's URL is needed | Not planned (user, 2026-11-19: the seed stays; the Check names a Source field) |
| A Swift `CoreMethod` constant and store method for `GetDraftMetadataBoard` | S15-39, its first caller |
| A shared query counter for "fixed number of queries" tests | S15-16, whose Check needs one (review X-2, M-9) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Board read | `core/database/sourcemetadata/sourcemetadata.go` `listWorkspaces` | Per owner: type id through `store.typeIn`, suggestions per (type, level) cached in `suggested map[typeLevel][]sourcevocab.Suggestion`, values (`readByOwners`), layout (`listLayoutByOwners`), extra fields (`loadFields`). Emits suggestions (dropping dismissed empty ones), then extras, then applies layout order. Knows nothing of formats |
| Exported reads | same file `ListWorkspace` (→ `[]WorkspaceEntry`), `ListWorkspaces` (→ `[][]WorkspaceEntry`) | One read transaction, then `listWorkspaces`. Callers: `api/ffi/handlers/metadata.go` `ownerBoardsProto` (line 66) and `ownerBoardProto` (line 272) |
| Entry | same file `WorkspaceEntry` | `Field`, `Value`, `Suggested`, `SortOrder`; doc comment "a suggested or extra field" |
| Dismiss | same file `DismissSuggestion` | `storeFor`, `requireOwner`, `loadFields`, then `getPairTx`: a value → no-op; then the layout row: already dismissed → no-op; else `layoutDismiss`. Doc comment says the X is offered on empty suggestion rows only |
| Owner type SQL | `core/database/sourcemetadata/owner.go` `stores`, `newStore` (`typeIn`) | `SELECT id, source_type_id …` / `SELECT a.id, s.source_type_id …` / `SELECT g.id, s.source_type_id …`: no Source id |
| Requirements | `core/citationformat/requirements.go` `Requirements`, `Missing`, `Need` (`NeedNeeded`, `NeedUsed`) | One requirement per distinct target chain, needed when any template needs it; a chain holding an `AlwaysSet` built-in is used. `Missing` skips chains that are not needed, tests each target at the full form with no option, and an unknown mark answers |
| Value | `core/citationformat/render.go` `Value{Text, Date, Mark, UnknownText}`, `Resolver` | The shape every resolver fills |
| Built-ins | `core/citationformat/builtins.go` `LookupBuiltin`, `Builtin.AlwaysSet` | `source.title`, `source.type`, `artifact.label`, `graph.name` always set; `source.date` (Date, "n.d."), `citation.page` ("unpaginated"), `citation.image`, `citation.label` |
| Stored formats | `core/database/sourcetypes/formats.go` `StoredFormatsTx`, `viewTx`, `Formats`, `formColumns` | `StoredFormatsTx` reads the three columns by type id, fields by id (`#<uuid>`). `viewTx` loops `citationformat.Forms()`, skips `""`, calls `Parse`, collects per-form diagnostics, keeps the templates that parsed |
| Writing formats | same file `UpdateFormats` → `ToStored` | Resolves every key; a typed `#id` must name a field, so a dangling id cannot be written through it |
| Source row | `core/database/sources/sources.go` `GetTx`, `Source.Date`, `Source.DateMark`, `Source.SourceTypeID` | Date and mark settled (`settleDate`); `ErrNotFound` when missing. `sources` does not depend on `sourcemetadata`; it reaches `citationformat` (a leaf: `apperr`, `datevalue`, `valuemark`, `vocabkey`) only through `deleteimpact`, so a direct import makes no cycle |
| Fields by id | `core/database/metadatafields` `ListByIDsTx` | A missing id is absent (`loadFields` turns that into `ErrInvalid`) |
| Wire | `api/proto/engine.proto` `MetadataWorkspaceEntry` (1–10, 3/7/8 reserved), `GetSourceWorkspaceResponse` (up to 10), `Method` (last `METHOD_COPY_SOURCE_TYPE = 122`) | No requirement fields |
| Handlers | `api/ffi/handlers/metadata.go` `ownerBoardsProto` (only caller: `sources.go` `GetSourceWorkspace`), `ownerBoardProto`, `metadataEntryProto`, `GetMetadataBoard`, `DismissMetadataSuggestion`; `api/ffi/handlers/artifacts.go` (lines 70, 142) and `api/ffi/handlers/evidence_graphs.go` (lines 98, 150) call `ownerBoardProto` | Every board on the wire goes through `metadataEntryProto` |
| Dispatch | `api/ffi/dispatch.go` constants and `switch` (`MethodCopySourceType` → `handlers.CopySourceType`) | One case per method |
| Draft-board parity | `core/database/sourcemetadata/testdata/draft_board_scenarios.json`, `TestDraftBoardScenarios` (world from `testWorld`: format-less), `macos/ProvenenciaTests/MetadataDraftHostParityTests.swift` `compared` (divergences `order`, `suggested`; unknown values compare in full) | 13 scenarios; none dismisses an empty `document_number` |
| Swift board | `macos/App/Features/Sources/MetadataBoardModel.swift` `saved` (`hasValue`), `suggested` (`!hasValue && suggested`), `moveSaved` (writes `savedRows + suggested` to `host.entries`) | An unsuggested empty entry is in neither list: not drawn, and dropped from the client copy by a reorder until the next read. Unchanged here (D-12) |
| Add mode | `macos/App/Features/Sources/SourcePageContext.swift` `unsavedMetadataRows(level:)` → `store.listTypeSuggestions` → `MetadataDraftHost.unsavedRows(from:)` | Unchanged here |
| Composer | `macos/App/Features/CitationComposer/CitationComposerModel.swift` `workspaceKey` | Holds the Source's `.sourceWorkspace` key, so the page's requirement rides that read (D-9) |
| Cache | `macos/App/Features/Workspace/Session/CatalogQueryRegistry.swift` `.sourceWorkspace` | No separate graph board key: graph boards ride `.sourceWorkspace` since S15-11 |
| Tests | `core/database/sourcemetadata/sourcemetadata_test.go` `TestListWorkspaces`, `testWorld` (upserts a birth certificate with no formats via `seedBirthCertificate`), `runFieldCreate`, `newSource`, `newLevelOwner`; `api/ffi/handlers/metadata_test.go` `TestGetMetadataBoard`, `TestMetadataOwners`; `api/ffi/handlers/sources_test.go` `TestGetSourceWorkspace`; `api/ffi/handlers/harness_test.go` `sourceFixture` (an onboarding project with the full seed; returns the birth certificate type id) | Handler tests on the seeded birth certificate see its formats from this PR on (STEP-6) |
| Seed | `core/database/sourcevocab/registry.go` `seedTypes`, `registry_suggestions.go` `seedSuggestions`; `core/database/sourcevocab/sourcevocabtest` `Install` | 26 types with formats. Measured at the planning base (Edges, Real data) |

**Precedent.** S15-37 ([#879](https://github.com/Jake-Robins-Studios/provenencia/pull/879)) added a fact to every board entry (`Row.Mark` → `MetadataWorkspaceEntry.mark`) through `listWorkspaces` and `metadataEntryProto` only, so every read and write reply carried it with no per-handler change: copy that path. S15-11 ([#834](https://github.com/Jake-Robins-Studios/provenencia/pull/834), D-1) is why one `ListWorkspaces` call serves a whole page. S15-15's D-9 is why `StoredFormatsTx` is called once with every type id.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Go types in `core/database/sourcemetadata/annotation.go` *(new)*: `type Annotation struct { Need citationformat.Need; MetElsewhere bool; Alternatives []Alternative }` (zero = none, `Need == ""`); `type Alternative struct { Level vocabkey.Level; Field *metadatafields.Field; Builtin string }` (exactly one of `Field`, `Builtin`). `WorkspaceEntry` gains `Annotation Annotation`. `type Board struct { Entries []WorkspaceEntry; Date, Page Annotation }` *(new)*: `Date` and `Page` set on a Source owner's board only | One word per concept: `citationformat.Requirement` is a chain; this is one head's role on one board (review M-5). The need is the engine's own `citationformat.Need` | A `none` constant in `citationformat` — `Requirements` never yields one |
| D-2 | **Heads.** Per (type, level), a pure step `needsAt(chains []citationformat.Requirement, level vocabkey.Level) levelNeeds` *(new)*: for each chain, its first option is its **head** and takes the chain's need; every later option that is a field at `level` is `used`. A field's need is the strongest over its chains (needed > used). `levelNeeds` holds each field's need, the emission order of heads (first appearance in the chains) and the chains each field heads. `levelNeeds` also holds `builtinHeads map[citationformat.Target][]citationformat.Requirement`: the needed or used chains headed by `{Level: source, Builtin: "date"}` and `{Level: citation, Builtin: "page"}`, filled only when `needsAt` runs for `source`. `annotate` takes the head as a `citationformat.Target` and finds its chains in `heads` (fields, keyed by field id) or `builtinHeads`. Cached per (type, level) beside `suggested` | Rule "A format's fields are needed or used": a chain empty everywhere is flagged on its first option. Per-(type, level) work done once, as suggestions are (review M-7) | Every option takes the chain's need — the Source's `line_number` would be needed on every census Source |
| D-3 | **Met elsewhere**, per owner, only on a needed head: true when every needed chain it heads is answered by a later option, tested with `citationformat.Missing([]Requirement{{Targets: chain.Targets[1:], Need: NeedNeeded}}, resolver)` returning empty. A one-option chain has an empty tail and is not met | One answer function in the engine; `Missing` skips non-needed chains, so the tail is built needed (review X-6) | Testing answers in `sourcemetadata` — a second copy of `printed` |
| D-4 | **Values for a citation, once.** `func CitationValue(r Row, f metadatafields.Field) citationformat.Value` *(new, exported, `sourcemetadata`)*: `Text` = `ValueText`, `Mark` = the read mark, `UnknownText` = `f.UnknownText`. `func CitationDate(s Source) citationformat.Value` *(new, exported, `sources`)*: `Date` = `s.Date`, `Mark` = `s.DateMark`. The board's resolver `ownerValues` *(new, unexported)* answers a field target at the owner's level from the owner's rows, at `source` from the Source's rows (both through `CitationValue`), `source.date` through `CitationDate`, and every other target with the zero `Value` (another Artifact or graph, `citation.*`, and the always-set built-ins, which never reach `Missing`: their chains are used). A target named by key (not id) answers zero: stored formats name fields by id. S15-16's map scope names these two functions as its starting point (edited at planning) | One mapping from a stored value to a citation value, shared with S15-16's render, so the board and the render agree on "answers" (review M-1, M-4) | An unexported resolver S15-16 would fork; title and type branches no test can reach |
| D-5 | **Alternatives** on a needed head: the later options of the needed chains it heads, in chain order, without repeats: a field as `Field` (its row), a built-in as its bare name. A field id with no field row is left out | Rule "with a hint naming the others"; a graph board can name a Source field it does not hold | Sending only ids — the graph form has no Source field list |
| D-6 | **Emission.** A field that heads a needed or used chain at the owner's level and is neither suggested nor valued is emitted as `Suggested: false`, no value, after the suggestions and before the extras, in `levelNeeds` emission order; then layout order applies as today. A later option that is not suggested and holds no value is not emitted (user, 2026-11-19). A valued extra gets its annotation like any entry. Each field comes out once (one `seen` set over suggestions, heads and extras) | User answer; `Suggested` keeps meaning "the type suggests it" | Emitting every option — six empty rows on every census Source board |
| D-7 | **Dismissed.** A needed entry is emitted whatever its layout row says. A used or unread entry follows its dismissal as a suggestion does today (user, 2026-11-19) | Needed fields cannot be waved away; used ones are optional | Ignoring dismissal for used fields — the X would do nothing |
| D-8 | **`DismissSuggestion` refuses a needed field.** Order: `storeFor`, `requireOwner`, `loadFields`, `getPairTx` (a value → no-op, as today), then `needOfTx(tx *sql.Tx, st *store, owner Owner, fieldID []byte) (citationformat.Need, error)` *(new)*: the owner's type through `st.typeIn` with one id, `sourcetypes.RequirementsTx` for that type, `needsAt` for the owner's level. Needed → `ErrInvalid.WithParams(database.UUIDString(fieldID))`, before any layout read. No resolver: a needed field is refused even when met elsewhere. `Apply` is unchanged: a draft's dismissed row for a needed field is written and ignored by the read (D-7) | Same need function as the read (review X-3, M-7). `sourcemetadata.invalid` is already mapped in `L10n.Errors`, and S15-39 never offers the X | A new error code and message — no screen reaches it |
| D-9 | **Date and page on the Source's own board.** The `source`-level `levelNeeds` keeps the chains headed by `source.date` and `citation.page`; for a Source owner, `listWorkspaces` annotates them like a field head (D-3, D-5) into `Board.Date` and `Board.Page`. `GetSourceWorkspace` sends them from the boards it already reads. The composer reads the page's from the `.sourceWorkspace` key it holds | One pass and one read for the page (review M-2); rule: "The Source date's requirement rides the Source workspace read; the printed page's, the composer's read" | A separate `SourceRequirements` read — a second transaction, parse and Source read, and a second copy of D-2, D-3 and D-5 |
| D-10 | **Add mode** gets its own read: `GetDraftMetadataBoard` *(new, method 123)* `{project_dir, source_id, level}` → `{repeated MetadataWorkspaceEntry entries}`; Go `ListDraftWorkspace(c *database.Catalog, sourceID []byte, level vocabkey.Level) ([]WorkspaceEntry, error)` *(new)*: `artifact` or `graph` only, else `ErrInvalid`; in one read transaction, `sources.GetTx` (its `ErrNotFound` returned as `ErrInvalid`) gives the type and date, `readByOwners` on the Source owner its rows, `RequirementsTx` and `needsAt` its heads; the type's suggestions at that level, empty, then D-6's heads, annotated through `ownerValues` with no own rows | A draft board needs unsuggested heads and the Source's values; `ListTypeSuggestions` is the type page's edit list. A draft at `source` has no meaning: the Source exists | Annotating `TypeSuggestion` — no rows for unsuggested fields, no Source to answer from |
| D-11 | **No Swift cache signal here.** `CatalogMutation.changedCitationFormats(typeId)` does not exist until S15-17 (S15-15 D-11, user 2026-11-17: a mutation nothing applies is dead). S15-17 adds the case, applies it, adds it to `.sourceWorkspace`'s invalidation and the `docs/catalog-caches.md` row. Map edited at planning | The same reasoning the user gave on 2026-11-17; graph boards have no key of their own since S15-11 | An invalidation for a case that does not exist yet |
| D-12 | No Swift app source change. `./scripts/generate-proto.sh` regenerates `macos/App/Platform/Generated/engine.pb.swift`; `GoStore` ignores the new fields; the board does not draw an unsuggested empty entry (§4 Swift board). One Swift test change (D-17) | S15-39 is the first reader and draws them | Mapping the fields into `CatalogMetadataEntry` now — unread |
| D-17 | **Draft-board parity.** `.cursor/rules/macos-client.mdc` makes `core/database/sourcemetadata/testdata/draft_board_scenarios.json` the record of the board rules `MetadataDraftHost` mirrors. The file gains `"needed": ["document_number"]`; `TestDraftBoardScenarios`' world writes the scenario type's list format `{source.meta.document_number}.` with `sourcetypes.UpdateFormats` (no existing scenario dismisses an empty `document_number`, so none changes). One scenario *(new)*: "dismissing an empty needed suggestion is refused": action `dismiss document_number` with `"refused": true`, board unchanged, draft null, `"known_divergence": "needed"`. Go expects `sourcemetadata.invalid` on a refused action. `MetadataDraftHostParityTests.compared` gains `case "needed"`, which skips the board and draft comparison (the draft host hides it until S15-39). The `_note` names the new divergence. S15-39's map scope removes it (edited at planning) | The parity file is how the client's copy of the board rules is pinned (review M-10) | Leaving the file format-less — the engine and the draft host would drift with the test green |
| D-13 | **One parse step, in the format's package.** `func (f Formats) Parse() (map[citationformat.Form]*citationformat.Template, []citationformat.FormDiagnostic)` *(new, `sourcetypes`)*: every form not blank after `strings.TrimSpace`, in `citationformat.Forms()` order, the templates that parsed and every form's diagnostics in form order. `viewTx` calls it for its templates and diagnostics and keeps its `Forms()` loop only to copy each form's text into `view.Formats` (`with`). `ToStored` calls `in.Parse()` instead of its own parse loop and keeps its id and key collection over the returned templates (stored text is never whitespace-only, so `viewTx` behaves the same; review M-11). `func RequirementsTx(tx *sql.Tx, typeIDs [][]byte) (map[string][]citationformat.Requirement, error)` *(new)*: `StoredFormatsTx` once, `Parse`, `citationformat.Requirements(full, short, list)` (a form that does not parse adds nothing; a type with no row is absent) | `sourcetypes` owns the columns; one parse for the editor, this PR and S15-16 (review M-3); one format read per board call | Parsing in `sourcemetadata` — a third copy of the loop with S15-16 next |
| D-14 | **Source facts.** Each `store.typeIn` returns a third column, the Source id (`id` for a Source, `a.source_id`, `g.source_id`). The distinct Sources join the owners in the one `readByOwners` call, deduplicated by `Owner.key` against owners already on the call. The added Source owners are used only as `ownerValues`' Source rows: they stay out of the `extraIDs` loop, the layout read and the output; boards are built only for the requested owners. Each distinct Source is read once with `sources.GetTx` for its date and mark | One more batched values read, as the rule says; a page has one Source | A by-ids Source read in `sources` — no caller reads more than one Source per board call |
| D-15 | **Fields loaded.** One `metadatafields.ListByIDsTx` for the extras' ids plus every field id that is a head at an owner's level or an alternative; ids with no row are dropped silently from heads and alternatives (extras keep today's `ErrInvalid`). `ownerValues` answers a valued field whether or not its row loaded (`UnknownText` is then empty; an unknown mark answers regardless), so a dangling later option still answers `Missing` | One fields read per call | `loadFields` for all — a dangling format id would fail the whole page |
| D-16 | Wire: enum `CitationNeed { CITATION_NEED_UNSPECIFIED = 0; CITATION_NEED_NEEDED = 1; CITATION_NEED_USED = 2; }`; `message CitationRequirement { CitationNeed need = 1; bool met_elsewhere = 2; repeated CitationRequirementOption alternatives = 3; }`; `message CitationRequirementOption { string level = 1; MetadataField field = 2; string builtin = 3; }` (`field` through the existing `metadataFieldProto`, the one wire shape for a field; review M-12). `MetadataWorkspaceEntry.requirement = 11`; `GetSourceWorkspaceResponse.date_requirement = 11`, `page_requirement = 12`; each absent when the need is none. `requirementProto(a sourcemetadata.Annotation) *engine.CitationRequirement` *(new)* | A proto enum needs no Swift parity row; absent keeps replies for types with no formats byte-identical | A string need — one more parity row |

**Rules this plan bends.** None. The map was edited at planning (2026-11-19): bar 4 and the S15-38 and S15-39 Checks name a Source field, and rule "Boards flag needed fields" gains the later-option and dismissed-used answers (user, 2026-11-19); the cache signal's home moves to S15-17 (D-11), the add-mode read replaces "`TypeSuggestion` carries the same annotation" (D-10), and S15-16's scope starts from D-4's functions. The implementer edits nothing there.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `core/database/sourcemetadata/annotation.go` *(new)* | file | `sourcemetadata.go` (1,087 lines) | Same package; keeps the merge's new half in its own file |
| `Annotation`, `Alternative`, `Board` *(new)* | type | `citationformat.Requirement`, `WorkspaceEntry` | A chain is not a head's role; `Board` carries the Source's built-in heads beside its entries |
| `needsAt`, `levelNeeds` *(new)* | func, type | `citationformat.Requirements` | Calls its output; maps chains onto one level's heads |
| `ownerValues` *(new)* | type | `citationformat.Resolver` | Implements it from `CitationValue` and `CitationDate` |
| `CitationValue` *(new)* | func | `ReadDraftsTx`'s `Row` → `Input` mapping | Maps to the engine's `Value`; S15-16 calls it |
| `sources.CitationDate` *(new)* | func | `sources.settleDate` | Converts the settled date; one line, exported for S15-16 |
| `needOfTx` *(new)* | func | `requireOwner` | Reads the owner's type and needs for one field |
| `buildEntries` *(new, extracted)* | func | the per-owner loop at the end of `listWorkspaces` | Moved, so the draft board shares it |
| `ListDraftWorkspace` *(new)* | func | `ListWorkspaces` | Same assembly with no owner row |
| `Formats.Parse`, `RequirementsTx` *(new)* | func | `viewTx`'s loop | Extracted; `viewTx` calls it |
| `GetDraftMetadataBoard` *(new)* | FFI | `GetMetadataBoard` | That takes an owner that exists (D-10) |
| `CitationNeed`, `CitationRequirement`, `CitationRequirementOption` *(new)* | proto | `ValueMark` | One shared message per fact, as `ValueMark` |
| `requirementProto` *(new)* | helper | `valueMarkProto` | Same pattern |
| `seededWorld` *(new)* | test helper | `testWorld` | `testWorld` upserts a format-less birth certificate that `sourcevocabtest.Install` would collide with (review X-5) |
| `seededSourceOfType` *(new)* | test helper | `sourceFixture` | Returns a Source of any seeded type key in the handler tests |

**Builds on.** S15-37's path (`listWorkspaces` → `metadataEntryProto`); `sqlbatch` via `StoredFormatsTx`; `citationformat.Missing` for every answer.
**Deletes.** The parse loops in `viewTx` and `ToStored` (replaced by `Formats.Parse`). `ListWorkspaces`' `[][]WorkspaceEntry` return becomes `[]Board`; `ownerBoardsProto` becomes `boardsProto(owners []sourcemetadata.Owner, boards []sourcemetadata.Board) []*engine.MetadataBoard` *(renamed)*, and `GetSourceWorkspace` calls `ListWorkspaces` itself. `TypeSuggestion` stays for the type page; `MetadataDraftHost.unsavedRows(from:)` is retired by S15-39.
**Next adds.** S15-16 builds its resolver on `CitationValue`, `CitationDate` and `RequirementsTx`'s sibling `Formats.Parse`. S15-39 reads `entry.requirement` and calls `GetDraftMetadataBoard`. S15-40 filters the Artifact boards. S15-42 reads `date_requirement`; S15-45 `page_requirement`; another built-in head is one more field on `Board`. S15-17 adds the invalidation (D-11).

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| An unsuggested empty entry (D-6) | `MetadataBoardModel.saved` / `suggested` | In neither list: not drawn, and a reorder (`moveSaved`) drops it from `host.entries` until the next read. No write sends it: `Reorder` takes the saved ids only. S15-39 draws it |
| A dismissed needed field coming back (D-7) | the board | Not drawn until S15-39 (same lists) |
| `DismissMetadataSuggestion` on a needed field | `L10n.Errors` `sourcemetadata.invalid` | Mapped today. A needed field the type also suggests is drawn as a suggestion row with a dismiss X (`MetadataBoardModel.suggested`, `MetadataBoardView.swift` `MetadataBoardSuggestionRow`); after this PR that X shows "This metadata change can't be saved." (24 seeded needed suggestions, such as census `jurisdiction`) until S15-39 hides it |
| A format naming a field id with no field row | `needsAt`, alternatives | Dropped (D-15); T-6 |

### Scale

At the map's Scale (a census Source with 60 Artifacts and 60 graphs, one type): the page read adds one `StoredFormatsTx` query, 3 parses and one `Requirements` (D-13), one `sources.GetTx`, and no extra values query (the Source is already an owner on that call). `needsAt` runs once per (type, level), 3 times; per owner, `Missing` runs once per needed head (census: none at Artifact or graph level). No write changes what it invalidates. T-9 builds that page and checks every board is annotated. It does not count queries; the shared counter is S15-16's (§3 Out).

### Edges

- **Assumptions.** `listWorkspaces` assumes each owner's entries hold a field once: heads join one `seen` set with suggestions and extras (T-3). `loadFields` fails on a missing id: head and alternative fields use `ListByIDsTx` and drop missing ids (D-15, T-6). `Requirements` keys chains by target sequence, so one field in two chains is two chains and D-2 takes the strongest (T-2, census `item` in full and short). `Missing` skips non-needed chains, so the tail is built needed (D-3, T-2).
- **Neighbors.** A chain headed by a field with an always-set built-in after it (`{source.meta.short_title|source.title}`) → used, never asks the resolver (T-1). A chain headed by a built-in (`{citation.page|source.meta.page_range}`) → the page head needed on the Source board, `page_range` used (T-1, T-7). A needed head with its own value → needed, `met_elsewhere` from later options only (T-2). A needed head marked unknown → has a value row, so the board does not flag it (S15-39) and `met_elsewhere` is unchanged (T-2). A built-in as a later option of a field head (`{graph.meta.x|source.date}`) → answered by the Source's date (T-2).
- **Removed inputs.** A dismissed needed field shows again; its layout row is kept, so it hides again when the format stops needing it (T-4, T-5). Formats cleared → entries back to today's shape on the next read (T-5). A dangling id → dropped, nothing else lost (T-6).
- **Real data.** Run at the planning base over the 26 seeded types (full, short, list): 30 needed Source fields; **no Artifact or graph field is needed** (every one sits in a group); built-in heads needed: `source.date` in census, interview, oral testimony, correspondence and newspaper item, `citation.page` in court report. Unsuggested heads emitted (D-6), all at the Source level, 32 rows: `short_title` used (16 types), `coverage` used (6), `jurisdiction` needed (the three certificates), `author_sort` needed (book, journal article, broadcast), `collection` used (passenger list, case file), `creator` and `repository` used (passenger list). Later options left off, 31 rows: `item` (18 types), `entry_number` (5), `folio` (2), `line_number` (2), `column`, `dwelling_number`, `family_number`, `schedule_number` (1 each). T-8 pins these counts.
- **Untrusted size.** Each stored form is at most `citationformat.MaxFormatBytes` (4096) before parsing (`Parse` refuses longer), so a type has at most about 1,400 placeholders over three forms, and options per chain are bounded by the same text. Work per owner is needed heads × options; no recursion. Alternatives are deduplicated per head.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcetypes/formats.go` | `Formats.Parse`, `RequirementsTx` (D-13); `viewTx` and `ToStored` call `Parse` |
| `core/database/sources/sources.go` | `CitationDate` (D-4) |
| `core/database/sourcemetadata/owner.go` | `typeIn` strings select the Source id third (D-14) |
| `core/database/sourcemetadata/annotation.go` *(new)* | `Annotation`, `Alternative`, `Board`, `CitationValue`, `ownerValues`, `levelNeeds`, `needsAt`, `annotate(ln levelNeeds, head citationformat.Target, r citationformat.Resolver, fields map[string]metadatafields.Field) Annotation`, `needOfTx` |
| `core/database/sourcemetadata/sourcemetadata.go` | `WorkspaceEntry.Annotation`; `ListWorkspaces` → `[]Board`; `ListWorkspace` returns `Board.Entries`; `listWorkspaces` as D-6, D-7, D-9, D-14, D-15 through `buildEntries`; `ListDraftWorkspace` (D-10); `DismissSuggestion` (D-8) |

```go
// ListWorkspaces is ListWorkspace over many owners in one read transaction:
// the board at index i is owners[i]'s; a Source owner's board also carries
// what its type asks of the Source date and the printed page.
func ListWorkspaces(c *database.Catalog, owners []Owner) ([]Board, error)

// ListDraftWorkspace is the board a new Artifact or graph starts with on the
// Source: the type's suggestions at level, empty, then the fields its formats
// head there, each annotated against the Source. Any other level, or a missing
// Source, is ErrInvalid.
func ListDraftWorkspace(c *database.Catalog, sourceID []byte, level vocabkey.Level) ([]WorkspaceEntry, error)
```

Errors: `sourcemetadata.invalid` → a needed field dismissed; a draft board at a level other than `artifact` or `graph`, or for a missing Source.

### FFI

`api/proto/engine.proto`: D-16; `METHOD_GET_DRAFT_METADATA_BOARD = 123`; `GetDraftMetadataBoardRequest { string project_dir = 1; string source_id = 2; string level = 3; }`, `GetDraftMetadataBoardResponse { repeated MetadataWorkspaceEntry entries = 1; }`. Handlers in `api/ffi/handlers/metadata.go`: `GetDraftMetadataBoard` (`withProjectCatalog`, as `GetMetadataBoard`), `requirementProto`, `boardsProto`; `metadataEntryProto` sets `Requirement`. `api/ffi/handlers/sources.go` `GetSourceWorkspace` calls `sourcemetadata.ListWorkspaces` and `boardsProto`, and sets `DateRequirement` and `PageRequirement` from `boards[0]`. `api/ffi/dispatch.go`: `MethodGetDraftMetadataBoard` and its case. Regenerate with `./scripts/generate-proto.sh`.

### macOS

None — generated proto only (D-12).

### Strings

None — no copy. The refusal reuses `sourcemetadata.invalid`.

## 7. Steps

**STEP-1 — One parse of stored formats**
Files: `core/database/sourcetypes/formats.go`, `core/database/sourcetypes/formats_test.go`.
Do: D-13, `viewTx` and `ToStored` both onto `Parse`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcetypes/ ./core/database/sourcevocab/` passes with the `GetFormats`, `UpdateFormats` and `ToStored` tests unchanged; T-10 passes.

**STEP-2 — Citation values**
Files: `core/database/sourcemetadata/annotation.go` *(new)*, `core/database/sources/sources.go`, `core/database/sourcemetadata/annotation_test.go` *(new)*.
Do: D-4's `CitationValue`, `CitationDate`, `ownerValues`.
Check: `go build ./...` passes (no import cycle); T-2's resolver rows pass.

**STEP-3 — Heads and annotations**
Files: `core/database/sourcemetadata/annotation.go` *(new)*, `core/database/sourcemetadata/annotation_test.go` *(new)*. Skill: `add-catalog-query`.
Do: D-1, D-2, D-3, D-5: `needsAt`, `annotate`. Field targets carry `uuid.UUID` ids; compare `id[:]` with field id bytes.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/ -run 'TestNeedsAt|TestAnnotate'` passes (T-1, T-2).

**STEP-4 — The board merge**
Files: `core/database/sourcemetadata/owner.go`, `core/database/sourcemetadata/sourcemetadata.go`, `core/database/sourcemetadata/sourcemetadata_test.go`, `api/ffi/handlers/metadata.go` (`ownerBoardsProto` → `boardsProto`, `ownerBoardProto` reads `ListWorkspace`), `api/ffi/handlers/sources.go`.
Do: D-6, D-7, D-9 (into `Board`), D-14, D-15: `buildEntries` extracted from the end of `listWorkspaces`. Rewrite the doc comments of `ListWorkspace`, `ListWorkspaces` and `WorkspaceEntry` ("a suggested, headed or extra field").
`TestListWorkspacesExported` (`sourcemetadata_test.go`) reads `got[i].Entries` where it indexed `got[i]`: the one edit to an existing core test this step allows.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/ ./api/ffi/...` passes; `TestListWorkspaces` unchanged (AC-1.5); T-3, T-4 (emission rows), T-5, T-6, T-7, T-8, T-9 pass.

**STEP-5 — Dismiss refusal**
Files: `core/database/sourcemetadata/annotation.go` *(new)* (`needOfTx`), `core/database/sourcemetadata/sourcemetadata.go` `DismissSuggestion`, its test, `core/database/sourcemetadata/testdata/draft_board_scenarios.json`, `core/database/sourcemetadata/sourcemetadata_test.go` `TestDraftBoardScenarios`, `macos/ProvenenciaTests/MetadataDraftHostParityTests.swift`. Skill: `add-swift-test`.
Do: D-8, D-17. Rewrite `DismissSuggestion`'s doc comment: a needed field is refused; a used or suggested empty field is dismissed; a valued field is a no-op.
Check: T-4's dismiss rows and T-14 pass; every existing scenario still passes in Go.

**STEP-6 — Wire**
Files: `api/proto/engine.proto`, `api/ffi/handlers/metadata.go`, `api/ffi/handlers/sources.go`, `api/ffi/handlers/metadata_test.go`, `api/ffi/handlers/sources_test.go`, `api/ffi/handlers/harness_test.go` (`seededSourceOfType`), generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`. Skill: `add-ffi-handler`.
Do: D-16 messages and fields; `requirementProto`; `metadataEntryProto`; `GetSourceWorkspace`'s two fields. Run `./scripts/generate-proto.sh`. Handler tests on the seeded birth certificate that compare a whole Source board gain the `jurisdiction` entry and the annotations: update those expectations only, and name each changed test in the PR body.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/...` passes; T-11, T-13 pass.

**STEP-7 — Draft board RPC**
Files: `core/database/sourcemetadata/sourcemetadata.go` `ListDraftWorkspace`, `api/proto/engine.proto`, `api/ffi/handlers/metadata.go` `GetDraftMetadataBoard`, `api/ffi/dispatch.go`, `api/ffi/handlers/metadata_test.go`. Skills: `add-ffi-handler`, `use-catalog-session`.
Do: D-10.
Check: T-12 passes; a second `./scripts/generate-proto.sh` run leaves no diff.

**STEP-8 — Docs and version**
Files: `docs/source-layer-data-model.md` § 5.4, `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`, this plan, `../deployment-plan.md` (map row status), `../completed.md`.
Do: § 5.4: rewrite the **Dismiss** bullet (a needed field always shows and refuses dismissal; any other empty field hides when dismissed) and add a **Citation** bullet: the merge reads the type's three formats; each entry carries needed, used or none and met elsewhere; a chain is flagged on its first option, its later options are used and show only where suggested or valued; an unsuggested head shows; a Source's board also carries the date's and the page's. Version bump. Then the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`.

Toolchain: `./scripts/generate-proto.sh` needs `protoc`, `protoc-gen-go` and `protoc-gen-swift`, and `scripts/check-pr.sh`'s Xcode stages need macOS with Xcode. Where they are missing, run every Go check, and report each skipped command by name in the DoD evidence; the PR's CI runs them.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

Fixtures. Core tests that need the seed use `seededWorld(t)` *(new)* in `sourcemetadata_test.go`: `database.Create` in a temp dir, `users.Upsert` as `testWorld` does, then `sourcevocabtest.Install(c)`; it never calls `seedBirthCertificate`. A seeded type is `sourcetypes.Lookup(c, key, vocabkey.OriginProvenencia)`. The custom line-number type: `sourcetypes.Create` (label "Line ledger"), the seeded `line_number` field (`metadatafields` lookup by key in `seededWorld`), `sourcevocab.AppendSuggestion` at `graph`, and `sourcetypes.UpdateFormats` inside `writes.Run` with `Formats{Full: "{graph.meta.line_number|source.meta.line_number}."}`; owners through `newSource` and `newLevelOwner`. A dangling id is written past `ToStored` with one raw `UPDATE source_types SET citation_full = ? WHERE id = ?` on `c.DB()`, text `{source.meta.#<uuid.New()>}.`. Handler tests use `seededSourceOfType(t, projectDir, userID, key)` *(new)*: the type id from `ListSourceTypes` by key and origin `provenencia`, then `CreateSource`.

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/sourcemetadata/annotation_test.go` `TestNeedsAt` *(new)* | Parsed hand-written formats → needs: `{source.meta.a}` → a needed; `[{source.meta.a}]` → used; `{graph.meta.a|source.meta.a}.` at graph → a needed, at source → a used and not a head; `{source.meta.a|source.title}` → used; `{citation.page|source.meta.p}` at source → page head needed, p used | D-2, AC-4.2 |
| T-2 | Go | same, `TestAnnotate` *(new)* | `{graph.meta.a|source.meta.a}.`: Source a "14" → met, alt [source a]; Source a unknown → met; nothing → not met; graph a valued, Source empty → needed, not met; `{graph.meta.x|source.date}.` with a dated Source → met; one-option chain → not met; `CitationValue` carries mark and unknown text; `CitationDate` carries date and mark | AC-1.2, AC-1.3, AC-1.4, D-3, D-4 |
| T-3 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestListWorkspacesAnnotations` *(new)* | `seededWorld`: census Source → `jurisdiction` needed, `creator` used, Artifact `url` used; birth certificate Source → `jurisdiction` unsuggested needed after the suggestions; census Source → none of the six later options; book with `author` → `author_sort` needed, met; a valued extra a format reads → annotated, once | AC-1.1, AC-1.6, AC-2.1, AC-2.2 |
| T-4 | Go | same, `TestDismissNeeded` *(new)* | Dismiss `jurisdiction` → `sourcemetadata.invalid`, params[0] its id, no layout row; a dismissed row for it written by `Apply` → still emitted at its layout position; dismiss church register `coverage` → hidden; dismiss a used suggested field → layout row written | AC-2.3, AC-2.4, AC-2.5, AC-2.6, D-8 |
| T-5 | Go | same, `TestAnnotationsFollowFormats` *(new)* | Line-number type, then formats cleared with `UpdateFormats` → entries back to suggestions only, annotations none; the AC-2.3 dismissed row hides again | AC-1.5, D-7 |
| T-6 | Go | same, `TestAnnotationsDanglingField` *(new)* | Dangling id in `citation_full` → no entry, no alternative, no error | D-15 |
| T-7 | Go | same, `TestSourceBoardBuiltins` *(new)* | Census Source board → `Date` needed, `Page` used; court report → `Page` needed with alt [source page_range]; Artifact board → both zero; Ledger → both zero | AC-4.1, AC-4.2, AC-4.3, AC-4.4, D-9 |
| T-8 | Go | same, `TestSeedAnnotations` *(new)* | `seededWorld`, one empty Source of each of the 26 seeded types with one Artifact and one graph. Counts, each a sum over types: entries with `Need == needed` on Source boards = 30; on Artifact and graph boards = 0; Source-board entries with `Suggested == false`, no value and a need = 32, as the per-field list in Edges; Source boards with `Date.Need == needed` = 5 (census, interview, oral testimony, correspondence, newspaper item); `Page.Need == needed` = 1 (court report). Omitted later options: none of Edges' 31 (type, field) pairs is an entry. A test table holds the per-type sets | D-2, D-6, AC-2.2 |
| T-9 | Go | same, `TestListWorkspacesAnnotationsScale` *(new)* | Census Source with 60 Artifacts and 60 graphs, one `ListWorkspaces` call → 121 boards, each Artifact `url` used, each graph `item` used, Source `jurisdiction` needed | D-13, D-14 |
| T-10 | Go | `core/database/sourcetypes/formats_test.go` `TestRequirementsTx` *(new)* | Two types (census, Ledger) in one call → census chains, Ledger absent; a stored form that does not parse → its chains missing, the others kept | D-13 |
| T-11 | Go | `api/ffi/handlers/metadata_test.go` `TestMetadataBoardRequirements` *(new)* | Seeded census Source: `GetMetadataBoard` → `jurisdiction` needed; `SetMetadata` jurisdiction → reply entry needed with value; `ReorderMetadata`, `ClearMetadata` replies annotated; `DismissMetadataSuggestion` on `jurisdiction` → `sourcemetadata.invalid` | AC-1.1, AC-2.5, AC-2.7 |
| T-12 | Go | same, `TestGetDraftMetadataBoard` *(new)* | Census at `artifact` → suggestions in order, `url` used; line-number type at `graph` with Source `line_number` → needed, met; well-formed id with no Source, level `source`, level `citation` → `sourcemetadata.invalid`; malformed id → `request.invalid_id` | AC-3.1, AC-3.2, AC-3.3 |
| T-14 | Go, Swift | `TestDraftBoardScenarios`, `MetadataDraftHostParityTests.scenariosMatchTheEngine` (new scenario) | "dismissing an empty needed suggestion is refused" → Go: `sourcemetadata.invalid`, board unchanged; Swift: skipped under `needed` | D-17, AC-2.5 |
| T-13 | Go | `api/ffi/handlers/sources_test.go` `TestGetSourceWorkspace` (new rows) | Census → `date_requirement` needed, `page_requirement` used; birth certificate → `date_requirement` used (its date sits in a group); a Source of a type made with `CreateSourceType` (no formats) → both absent | AC-4.1, AC-4.3, AC-4.4 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: whole-board expectations in `api/ffi/handlers/metadata_test.go`, `sources_test.go`, `source_write_effects_test.go`, and the Artifact and graph handler tests on the seeded birth certificate (STEP-6).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: `ownerBoardsProto` and `ListWorkspaces`' old return `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no stale hit; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (not gated: none)
- [ ] Domain doc updated: docs/source-layer-data-model.md § 5.4 (Dismiss bullet, Citation bullet)
- [ ] PR description: what shipped, AC evidence, deviations, the whole-board tests whose expectations changed, manual check
```

## 10. Manual check

No view changes, so the check is that the app still works on the new replies.

1. Build and run the app on a new project (the seed installs). Add a Source of type Birth certificate and one of type Census. Each page opens with no error and its Metadata section looks as before (the unsuggested Jurisdiction entry is not drawn yet, §4 Swift board).
2. On the census Source, add a value to a suggested field, reorder two saved rows and dismiss an empty suggestion the type does not need: each saves as before. Dismissing a needed one (e.g. census `jurisdiction`) shows the save error (known, S15-39).
3. Open the citation composer on the census Source's graph: it opens as before.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Whole-board handler tests break on the seeded birth certificate | STEP-6 updates only those expectations and lists them in the PR body |
| A reorder drops an undrawn unsuggested entry from the client copy until the next read | No write sends it; S15-39 draws and keeps it |
| One more Source read per page | One row by primary key (D-14) |
| The dismiss X on an empty suggestion the type also needs fails with the save error | Accepted by the user (2026-11-19); S15-39 hides the X |

**Stop and report if:**

- `listWorkspaces`, `DismissSuggestion`, `store.typeIn` or `viewTx` no longer match §4.
- `citationformat.Requirements` or `Missing` changed signature, or `Missing` no longer counts an unknown mark as an answer.
- `go build ./...` reports an import cycle after STEP-2.
- T-8's counts differ from Edges (the seed changed): report the new counts before changing the test.
- A handler test outside STEP-6's list needs a change other than the added entry and annotations.
- Method number 123 is taken on `main`.

## 12. Open questions

None.

## 13. PR

**Title:** S15-38 — Boards carry their citation's requirements
**Body:** objective in one sentence; what shipped against US-1 – US-4; AC evidence; deviations from the plan; the whole-board tests whose expectations changed; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-38-board-requirements.md`.

## Landed

- The version bump is 0.26.2 → 0.27.0: `main` was at 0.26.2 when the PR was cut (the header said 0.26.0 → 0.27.0).
- `listWorkspaces` returns `map[string]Board`, so besides `TestListWorkspacesExported` the same one-line `.Entries` read changed in `TestListWorkspaces` and in the `workspaces read every owner` subtest of `TestListByOwnersTx`; neither asserts anything new.
- The seeded birth certificate's formats head artifact and graph fields (`format`, `provider`, `url`, `accessed_date`, `item`, `entry_number`) that the handler fixtures detach from the type's suggestions, so those boards gain empty used entries. `withoutFormatRows` (`metadata_test.go`) drops the entries only the formats put on a board, in `TestMetadataOwners`, `TestGetMetadataBoard`, `TestMetadataBoardsKeepTheirLevel`, `TestUpdateArtifactMetadata` (`artifacts_test.go`), `TestCreateEvidenceGraph` (`evidence_graphs_test.go`) and the artifact and graph board cases of `TestGetSourceWorkspace`. The Source board tests needed no change. The measured seed has no unsuggested head below the Source level (T-8 reads only the Source boards).
- `sourcemetadata_test.go` splits `testWorld` into `emptyWorld` (a user, no vocabulary) and `testWorld`; `seededWorld` is `emptyWorld` plus the seed.
- Commits: the shared parse; the board annotations with the dismiss refusal; the draft board read; the version bump (which also carries the § 5.4 text).
- The in-app manual check (§ 10) was not run in the implementing session.
- The dismiss X on an empty needed suggestion shows the save error until S15-39 hides it (accepted by the user, 2026-11-19; § 6 Reach row and § 11 Risks).
