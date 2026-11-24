# S15-55 — Boards read every level above

**Status:** Planned
**Spike / slice:** Spike 15 · Slice 11 — Metadata at any level
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: no view draws a Citation board until S15-56, and an Artifact's or graph's board reads the same values as today)
**Board:** —
**Depends on:** S15-54 (landed [#965](https://github.com/Jake-Robins-Studios/provenencia/pull/965)), S15-64 (landed [#959](https://github.com/Jake-Robins-Studios/provenencia/pull/959))
**Blocks:** S15-56
**Branch:** `s15-55-boards-read-every-level-above`
**Version bump:** minor, 0.39.0 (today's `VERSION`) → **0.40.0** (or the next minor after `main`'s `VERSION` when you rebase): a wire field changes on `GetDraftMetadataBoardRequest` and a Citation's board now reads its graph and Artifact ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests), `.cursor/rules/ffi-handlers.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** map scope entry S15-55 ([`../deployment-plan.md`](../deployment-plan.md)); working rules "A format reads a field from the nearest level that holds it", "A board shows what its owner inherits", "Boards flag needed fields; the engine decides the rows"; S15-54 **Next adds** and **Landed** ([plan](S15-54-citations-hold-metadata.md)); S15-61 **Next adds** ([plan](S15-61-metadata-levels-list.md)); S15-64 ([plan](S15-64-inherited-values.md)); [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) § 5.2
**Planned:** 2026-11-24 against `main` @ `302ac6e`
**Review:** [`S15-55-boards-read-every-level-above.review.md`](S15-55-boards-read-every-level-above.review.md) — Fits with changes / Ready with changes, two rounds; every finding Fixed but M-6 (Declined with evidence); nothing open

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

A Citation's board reads every level above it: its Evidence graph, its Artifact and its Source, nearest first. So a needed field held on the Citation's graph is "met above" on the Citation's board, and the value the Citation inherits is its graph's, else its Artifact's, else its Source's, as its citation prints it. The draft board of a new owner names its would-be parents (a new Citation's graph and Artifact; a new Artifact's or graph's Source) instead of a bare Source id, so the composer (S15-56) can show a new Citation's board. Every ancestor's values come in the board read's one batched `readByOwners` call, and the saved and draft boards are built by one builder.

**Why now.** S15-54 made the Citation hold values, but its board still treats the Source as its only ancestor (S15-54 D-10). S15-56 draws the composer's Citation board, draft and saved, and needs both reads first.

**What stays.** An Artifact's and a graph's board read exactly what they read today (their only ancestor is the Source). Which entries a board holds, their order, dismissals, requirements per field, every write RPC and every view. Renders (`citationrender`) read the same owners and rows as today.

## 2. User stories

**US-1.** As the engine, when I read a Citation's board, I read its graph's, Artifact's and Source's values with it, so that its requirements are met at the Citation or above and it inherits the nearest value.

Fixture for AC-1.x: a type whose full format is `{meta.line_number}.` (line_number needed, `newLedger`), a Source S of it, an Artifact A, a graph G linked to A, a Citation C on A and G.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | G holds line "7"; A, S, C hold none; read C's board | line_number: needed, `MetElsewhere` true; `Inherited` "7" from `graph` G |
| AC-1.2 | Only A holds line "9" | needed, met; `Inherited` "9" from `artifact` A |
| AC-1.3 | Only S holds line "14" | needed, met; `Inherited` "14" from `source` S |
| AC-1.4 | G "7", A "9", S "14" | `Inherited` "7" from `graph` (graph before Artifact, the rule's tie-break) |
| AC-1.5 | G marked unknown (`Input{Mark: valuemark.Mark{Unknown: true}}`), A "9" | `Inherited` is G's unknown row; met (an unknown value answers and stops the walk) |
| AC-1.6 | No level holds line | needed, `MetElsewhere` false; `Inherited` nil |
| AC-1.7 | C holds "3", G holds "7" | C's own value "3"; `Inherited` "7" from `graph`; `MetElsewhere` true |
| AC-1.8 | G holds "7"; read A's board and G's board | A's board: line_number `Inherited` nil, not met (G is not A's ancestor); G's board: own value "7", `Inherited` nil |
| AC-1.9 | G holds "7"; `ListWorkspaces(c, [G, C, S])` in one call | Each board `reflect.DeepEqual` to `boardOf` that owner alone; G's board has exactly one entry with `Value != nil` |

**US-2.** As the engine, when a board lists 60 Citations of one Artifact, I read their ancestors' values in the same reads as for one Citation, so that the composer's Artifact reads in one batch.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `ListWorkspaces` over 1 Citation, then over 60 Citations of one Artifact and graph (warm catalog) | The same number of SELECTs both times; the 60-Citation read inside 100 ms |

**US-3.** As the app, when I ask for the draft board of a new owner, I name its would-be parents, so that a new Citation's board reads its graph and Artifact as a saved one does.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Draft at `citation`, parents [G, A] (or [A, G]); G holds line "7" | line_number needed, met; `Inherited` "7" from `graph`; every entry empty |
| AC-3.2 | Draft at `artifact` (or `graph`), parents [S]; S holds Provider "Ancestry" | As today: Provider `Inherited` "Ancestry" from `source` |
| AC-3.3 | Draft at `citation` with parents: [G] alone; [G, A, S]; [G, G]; [G of S, A2 of another Source]; [G, an Artifact id that names no Artifact]; [G, a 15-byte id]; none | Each `sourcemetadata.ErrInvalid` |
| AC-3.4 | Draft at `source` with any parents, or at `page` or `""` | `sourcemetadata.ErrInvalid` |
| AC-3.5 | `GetDraftMetadataBoard` with a parent whose id is `not-an-id`, or a version 4 id | `request.invalid_id` (`errInvalidID`), as today for `source_id` |
| AC-3.6 | `GetDraftMetadataBoard` with a nil entry in `parents` | `sourcemetadata.invalid` (`parseOwner` on nil) |

**US-4.** As a researcher (through handler tests; no view yet), when my Citation's graph holds the line, the Citation's board does not flag it, and when no level holds it, it does: the slice Check.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `newMetadataOwners`' type with full format `{meta.line_number}.`; `SetMetadata` line "7" on the graph; `GetMetadataBoard` on the Citation | line_number `requirement` needed with `met_elsewhere` true; `inherited` display "7", owner level `graph` |
| AC-4.2 | Then `ClearMetadata` on the graph, nothing on Artifact or Source | `met_elsewhere` false; no `inherited` |
| AC-4.3 | `GetDraftMetadataBoard` level `citation`, parents [graph, Artifact] with the graph holding "7" | As AC-4.1 |

## 3. Scope

| In | Covered by |
| --- | --- |
| One derivation of an owner's ancestors (`OwnersAbove`) from its level's `Ups` and its Source; the type read carries the up ids | STEP-2, AC-1.1, AC-1.8, T-9 |
| One constructor of a resolver's rows (`ValuesOf`) for boards and renders; the render's owners through `OwnersAbove` | STEP-2, STEP-3, T-10 |
| One board builder for saved and draft boards, reading every board's ancestors in its one `readByOwners` call | STEP-3, AC-1.1 – AC-1.9, AC-2.1 |
| `ListDraftWorkspace` takes the level and its parents; any level with ups, the Citation included | STEP-4, AC-3.1 – AC-3.4 |
| `GetDraftMetadataBoardRequest.parents` replaces `source_id`; the handler follows | STEP-5, AC-3.5, AC-3.6, AC-4.3 |
| Swift's `getDraftMetadataBoard` takes parents; `FakeStore` and its tests follow | STEP-6, T-11 |
| A guard that every ancestor of a level is one up away or the Source | STEP-1, T-1 |
| `source-layer-data-model.md` § 5.2; version bump; map and `completed.md` | STEP-7 |

| Out | Home |
| --- | --- |
| The composer's Citation board, its call with a new Citation's graph and Artifact, and the citations-by-Artifact read that batches Citation boards | S15-56 |
| `inherited_values` read paths for Artifact and graph value writes (a Citation board refreshing when its graph's value changes) | S15-56 (S15-64 **Next adds**) |
| A Citation board's own `Date` or `Page` annotation | not planned: `Board.Date` and `Board.Page` stay the Source board's; the page built-in goes in S15-58 |
| Checking that a draft Citation's graph is linked to its Artifact | not planned (D-7): the Citation create refuses an unlinked pair |
| Showing values below an owner | not planned (rule "A board shows what its owner inherits") |

## 4. Current state

Verified at `302ac6e`.

| Area | Where | Today |
| --- | --- | --- |
| Level list | `core/database/catalogmodel/metadata.go` `MetadataUp`, `MetadataLevelTables.Ups`, `SourceUp`, `MetadataTables`, `SourcePath` | The Citation's `Ups` are graph then Artifact (`ToSource`); Artifact and graph have one up, the Source. No function lists a level's ancestors |
| List tests | `core/database/catalogmodel/metadata_test.go` `TestMetadataTables` (FKs per up, `upsOrderErr`), `TestSourcePath` | Nothing checks that every ancestor is one up away or the Source |
| Store | `core/database/sourcemetadata/owner.go` `store` (`typeIn`, `typeSuffix`), `sourcePathIn`, `newStore`, `buildStores` | `typeIn` reads the owner's id, its Source's type id and its Source id; not the owner's up columns |
| Type read | `core/database/sourcemetadata/annotation.go` `typesIn` (callback `fn(id, typeID, sourceID []byte)`), `needOfTx` (its own `typesIn` callback) | Callers get the Source only |
| Resolver | `core/database/sourcemetadata/annotation.go` `CitationValues` (its comment: "A board and a render both build it"), `Nearest`, `Without`, `annotate` | Built by three literals: `listWorkspaces`, `ListDraftWorkspace`, `citationrender.fillValues` (plus `Without`'s copy) |
| Board read | `core/database/sourcemetadata/sourcemetadata.go` `listWorkspaces` | Adds each owner's Source to the values read and builds `Rows` from `{o.Level, LevelSource}` alone (S15-54 D-10): a Citation board neither inherits from nor is met by its graph or Artifact |
| Draft read | `core/database/sourcemetadata/sourcemetadata.go` `ListDraftWorkspace(c, sourceID, level)` | Hand check `level != LevelArtifact && level != LevelGraph` → `ErrInvalid`; its own copy of the board steps (`sources.Lookup`, `readByOwners`, `readTypeNeedsAndSuggestions`, `MapByIDsTx`, `buildEntries`) over the Source alone |
| Store tests | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSourcePathIn` (exact SQL strings), `newLevelOwner`, `newLedger` (its `l.graph` is a bare graph, linked to no Artifact), `boardOf`, `entryOf`, `sourceOwner`, `TestListWorkspacesInherited`, `TestListDraftWorkspaceInherited` (calls `ListDraftWorkspace(c, src.ID, level)`), `TestDraftBoardScenarios`, `TestListWorkspacesAnnotationsScale`, `BenchmarkListWorkspacesScale` | |
| Render | `core/database/citationrender/load.go` `subject.owners`, `fillValues` | `owners` hand-lists Source, Artifact, graph and Citation from the ids its Citation read already holds (`citations.Cited` `ArtifactID`, `GraphID`, `ID`); `fillValues` builds its own `CitationValues` literal |
| Wire | `api/proto/engine.proto` `GetDraftMetadataBoardRequest` (`project_dir = 1`, `source_id = 2`, `level = 3`) and its comment (lines 888 – 890, "level is \"artifact\" or \"graph\""); `MetadataOwner` | |
| Handler | `api/ffi/handlers/metadata.go` `GetDraftMetadataBoard` (`parseID(req.GetSourceId())`; doc comment lines 262 – 265), `parseOwner` | |
| Handler tests | `api/ffi/handlers/metadata_test.go` `TestGetDraftMetadataBoard` (refusals table: `"citation level"` expects `ErrInvalid`), `TestMetadataBoardInherited` (two draft calls with `SourceId`), `newMetadataOwners`, `lineLedgerSource`; `api/ffi/handlers/harness_test.go` `setFormats` | |
| Swift store | `macos/App/Platform/GenealogyStore.swift` `getDraftMetadataBoard(projectDir:sourceID:level:)` (doc comment line 1674), `MetadataOwner`; `macos/App/Platform/GoStore.swift` `getDraftMetadataBoard`; `macos/App/Platform/FakeStore.swift` `draftMetadataBoardEntries` (keyed `"<sourceID>/<level>"`), `draftMetadataBoardCalls` (`(sourceID:, level:)`), `getDraftMetadataBoard` | |
| Swift caller and tests | `macos/App/Features/Sources/SourcePageContext.swift` `readDraftBoardForAdd(level:)`; `macos/ProvenenciaTests/SourcePageModelTests.swift` (line 1974 `.map(\.sourceID)`), `SourceGraphFormModelTests.swift` (line 379), `OnboardingModelTests.swift` (stub, line 367) | |
| Domain doc | `docs/source-layer-data-model.md` § 5.2 (line 258, the inherited-value paragraph; line 321, "`ListDraftWorkspace` … built against its Source"; the **Citation** bullet's "met at the owner's ancestors") | Name no Citation ancestors |

**Precedent.** S15-64 ([#959](https://github.com/Jake-Robins-Studios/provenencia/pull/959), merge `11c91bb`) added `Inherited` through `above := r.Without(o.Level)` and `Nearest`: this PR only puts more levels into `r`. S15-61 ([#943](https://github.com/Jake-Robins-Studios/provenencia/pull/943)) built `sourcePathIn` from the list: extend its select list the same way. S15-63 D-4 ([#955](https://github.com/Jake-Robins-Studios/provenencia/pull/955)) replaced a wire field by reserving its number and name: copy that for `source_id`. S15-63 D-17 added the Swift draft-board call and its `FakeStore` members: change them in place.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | An owner's ancestors are, in its level's `Ups` order, the owners its row names in the up columns, then its Source unless an up already is it; a Source has none. One pure function says this, `OwnersAbove` (Codebase fit); the board reads and the render both call it. No `catalogmodel.Ancestors`: `TestMetadataTables` checks that every level reachable through `Ups` is a direct up or the Source (T-1), so the up columns and the Source find every ancestor | One derivation of "a Citation's owners at every level" (S15-54 Next adds), with no read added: the type read already joins the owner row, and the render already holds the ids | `catalogmodel.Ancestors`: a closure no read uses; a level-by-level walk: a query per hop; keeping the render's hand list beside it with a parity test |
| D-2 | `sourcePathIn` appends `t0.<Up.Column>` for each of `path[0].Ups`, in order, after its three columns. `store` gains `ups []vocabkey.Level`. `typesIn` scans one `[]byte` per up and calls `fn(ownerAbove)`; `readAbove` collects them by `Owner.key` and is `ErrInvalid` when any owner given has no row, for every caller; `needOfTx` calls `readAbove` for its one owner | The up ids cost no query. An Artifact's and graph's `source_id` repeats the Source id, which `OwnersAbove` dedupes | A second query for the up ids; leaving out `source_id` for levels whose only up is the Source: a special case for one repeated column |
| D-3 | One board builder, `buildBoards(tx, boards []ownerAbove) ([]Board, error)`, does every read and builds every board, saved or draft, in the order given; each board reads `owner.Level`, `typeID`, `sourceID` and `ancestors()`. `listWorkspaces` is `readAbove` over its owners, then `buildBoards`, keyed back by `Owner.key` (its `map[string]Board` result and `ListWorkspaces` stay). `ListDraftWorkspace` is the parent checks (D-6), then `buildBoards` on one `ownerAbove`: `owner = Owner{Level: level}` (nil ID), `upIDs` = the parents keyed by level, `typeID` and `sourceID` the parents'. A nil owner ID adds no own values, layout or extras. Inside `buildBoards` nothing changes from today's `listWorkspaces` but the values read (D-5) and `ValuesOf` (D-4) | A later board rule (S15-39, S15-41, S15-66, S15-56) lands once and reaches both boards | Two copies of the board steps, as today |
| D-4 | `ValuesOf(rows OwnerRows, owners []Owner, fields map[string]metadatafields.Field) CitationValues` builds `Rows[o.Level] = rows.Of(o)` for each owner given, `Fields`, and an empty `Builtins` map; each caller adds its built-ins. `buildBoards` passes the own owner (when there is one) and the ancestors, then sets `SourceDate`; `fillValues` passes `s.owners()`, then sets its seven built-ins as today. `Without` keeps its literal: it copies a resolver, it does not build one | The comment on `CitationValues` says a board and a render build it alike; one constructor makes that true | A private `boardValues` beside the render's copy |
| D-5 | The values read adds each board's ancestors to its one `readByOwners` call, each owner once (`seenOwner`, as Sources are today). Source dates come from the boards' Source ids (`sources.GetManyTx`) | Rule "Boards flag needed fields": one batched read of the owner's ancestors | — |
| D-6 | `ListDraftWorkspace(c, level, parents []Owner)`. Shape checks, before any query, each `ErrInvalid`: a level with no store or whose store has no `ups` (replaces the hand check); `len(parents) != len(ups)`; a parent failing `storeFor`; a parent level not in `ups` or named twice. Then `readAbove(parents)`: a parent with no row, or parents with different Source ids, is `ErrInvalid`. The draft's `ownerAbove` is built as D-3 says, so its ancestors are `OwnersAbove` like every board's | The draft owner has no row, so its parents are what its row would name; one Source makes one type and one date | Order-sensitive parents (callers would mirror `Ups`' order); taking the Source alongside: it is derived |
| D-7 | The draft read does not check that a Citation's graph is linked to its Artifact | The board's rows do not depend on the link; `citations.InsertWithObservationsTx` refuses an unlinked pair at create | `evidencegraphs.IsLinkedTx` in the level-generic read |
| D-8 | Proto: `GetDraftMetadataBoardRequest` reserves 2 and `"source_id"` and adds `repeated MetadataOwner parents = 4`; the comments in § 6 FFI. The handler parses each with `parseOwner` | S15-63 D-4 precedent; one owner message on the wire | Keeping `source_id` beside `parents`: a field that half-lies |
| D-9 | Swift: `getDraftMetadataBoard(projectDir:parents:level:)` replaces `sourceID:` on `GenealogyStore`, `GoStore` and `FakeStore`. `SourcePageContext.readDraftBoardForAdd` passes `[MetadataOwner(level: .source, id: sourceID)]`. `FakeStore.draftMetadataBoardEntries` is keyed `parents.map(\.id).sorted().joined(separator: ",") + "/" + level.rawValue` (sorted, as the engine takes any order; one Source parent keys `"<sourceID>/<level>"` as today). `OnboardingModelTests`' stub becomes `getDraftMetadataBoard(projectDir _: String, parents _: [MetadataOwner], level _: Level)`, and `draftMetadataBoardCalls` records `(parents: [MetadataOwner], level: Level)` | The Swift call says what the wire says; S15-56 then only passes `[graph, Artifact]`. The map row's "Go" is widened by this one mechanical call (writer's call, logged) | Keeping `sourceID:` until S15-56: the half-lie D-8 removes, and S15-56 would redo five files |
| D-10 | `subject.owners()` in `citationrender` is the Citation, then `sourcemetadata.OwnersAbove(LevelCitation, {graph: GraphID, artifact: ArtifactID}, the Source's id)`; a Source-only subject is its Source. The owners' order changes; `ListByOwnersTx` does not depend on it | D-1's one derivation, with no read added: the ids come from the render's Citation read | Rendering through `readAbove`: a SELECT per 500 Citations |
| D-11 | `Board.Date` and `Board.Page` stay set on the Source board only | Map: "requirements at the Citation level" are its entries' annotations (`needsAt` already takes any level); the page built-in goes in S15-58 | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `OwnersAbove(level vocabkey.Level, upIDs map[vocabkey.Level][]byte, sourceID []byte) []Owner` *(new)*, `owner.go` | func | `citationrender` `subject.owners` (hand list) | Replaces the hand list (D-10). Walks `stores[level].ups` in order, adding an owner for each non-nil id; then the Source when `sourceID` is non-nil, `level` is not the Source, and no up is that Source. A level with no store gives nil |
| `ValuesOf(rows OwnerRows, owners []Owner, fields map[string]metadatafields.Field) CitationValues` *(new)*, `annotation.go` | func | The `CitationValues{…}` literals in `listWorkspaces`, `ListDraftWorkspace`, `fillValues` | Replaces all three (D-4) |
| `ownerAbove` *(new)* `{owner Owner; typeID, sourceID []byte; upIDs map[vocabkey.Level][]byte}` with `ancestors() []Owner` (= `OwnersAbove(owner.Level, upIDs, sourceID)`), `annotation.go` beside `typesIn` | type | `typesIn`'s three callback arguments | Extends them with the up ids |
| `readAbove(tx *sql.Tx, owners []Owner) (map[string]ownerAbove, error)` *(new)*, `sourcemetadata.go` | func | `listWorkspaces`' `eachLevel` + `typesIn` loop; `needOfTx`'s own `typesIn` call | Moves the loop out for both board reads and `needOfTx` |
| `buildBoards(tx *sql.Tx, boards []ownerAbove) ([]Board, error)` *(new)*, `sourcemetadata.go` | func | `listWorkspaces`' body after its type read; `ListDraftWorkspace`'s body | One builder for both (D-3) |
| `store.ups []vocabkey.Level` *(new)* | field | `catalogmodel.MetadataLevelTables.Ups` | The store keeps the levels its SQL reads, as it keeps `ownerColumn` |
| `GetDraftMetadataBoardRequest.parents` *(new)* | proto field | `MetadataOwner` | Reused message |
| `newCitationOwners(t, c, userID, src) (artifact, graph, citation Owner)` *(new)*, `sourcemetadata_test.go` | test helper | `newLevelOwner`'s citation case (new Artifact, the Source's sole graph via `evidencegraphstest.SoleGraph`) | `newLedger`'s Source has two graphs (`l.graph`), so `SoleGraph` fails there. It makes a new Artifact (`artifactstest.Create`), a new graph linked to it (`evidencegraphstest.Create(t, c, userID, src.ID, "Household", a.ID)`) and a Citation on both (`citationstest.Create`). `citations` has no UNIQUE on the pair, so T-5 calls `citationstest.Create` again with it |
| `ancestorsErr(list)` *(new)*, `catalogmodel/metadata_test.go` | test helper | `upsOrderErr` | Same shape, a different check |

Searched: `typesIn(`, `sourcePathIn`, `CitationValues{`, `owners()`, `ListDraftWorkspace`, `GetDraftMetadataBoard`, `getDraftMetadataBoard`, `draftMetadataBoard`, `.Ups` across `core/`, `api/`, `macos/`, `.agents/`, `docs/*.md`.

**Builds on.** S15-61's level list (`Ups` from S15-54); S15-62's one walker `Nearest`; S15-64's `above := r.Without(o.Level)`.
**Deletes.** `ListDraftWorkspace`'s hand level check and its copy of the board steps; `listWorkspaces`' board steps (into `buildBoards`) and its `typesIn` loop (into `readAbove`); the three `CitationValues` literals (into `ValuesOf`); `subject.owners`' hand list; `needOfTx`'s own `typesIn` callback; `GetDraftMetadataBoardRequest.source_id` (reserved) and the handler's `parseID(req.GetSourceId())`; Swift's `sourceID:` argument and `FakeStore`'s `sourceID` call field; `TestGetDraftMetadataBoard`'s `"citation level"` refusal (now accepted).
**Next adds.** S15-56 calls `ListWorkspaces` over an Artifact's Citations (one read, AC-2.1) and `getDraftMetadataBoard(parents: [graph, Artifact], level: .citation)`, and adds the Artifact and graph `inherited_values` paths. S15-39, S15-41 and S15-66 change `buildBoards` once for both boards.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A Citation board with graph and Artifact rows in `Rows` | `annotate`, `buildEntries`' `place` (`above.Nearest`) | Both read `Rows` by level only; a level with no rows is an empty map (`OwnerRows.Of`). AC-1.6 |
| `GetMetadataBoard`, every metadata write reply and `CreateCitationWithObservations` / `UpdateCitation` replies on a Citation | `ownerBoardProto` → `ListWorkspace` | Same path as AC-1.x; `inheritedProto` already sends any owner level |
| A draft at the Citation level | `ListDraftWorkspace` → `buildBoards` with a nil owner ID | A parent that names no row is `ErrInvalid`. AC-3.3 |
| A board call naming an owner and its ancestor | `buildBoards` values read | The ancestor is read once. AC-1.9 |
| A render through `ValuesOf` and `OwnersAbove` | `citationrender.fillValues` | A Citation whose Source row is missing (`s.source == nil`) passes a nil Source id: no Source owner, as today. `TestRender…` stays green |

### Scale

At the map's Scale (a board of up to 30 suggested fields read with its owner's ancestors in one batched read; a composer's Artifact of up to 60 Citations; a Source of 60 Artifacts and 60 graphs; a render of 300 Citations):

- **Citation boards.** `readAbove` adds no query: the up ids ride the type read (one SELECT per level per 500 owners). The values read covers at most four levels: one SELECT each per 500 owners. 60 Citations of one Artifact cost the same SELECTs as one (AC-2.1, T-5), under the 100 ms budget S15-64 set for a board read.
- **Artifact and graph boards.** The type read selects one more column (`source_id`); the values read is unchanged. `TestListWorkspacesAnnotationsScale` and `BenchmarkListWorkspacesScale` (121 boards) stay green; the PR reports the benchmark's ns/op before and after.
- **Draft read.** At most two type reads (one per parent level), one values read per ancestor level (at most three).
- **Render.** No read changes: `TestRenderScale` keeps 10 and 14 SELECTs.

### Edges

- **Assumptions.** `Nearest` walks `NearestFirst()` over `Rows` keyed by level, so each level holds one owner's rows per board: a Citation has one graph and one Artifact (`citations.graph_id`, `artifact_id` NOT NULL). `Without(o.Level)` removes only the owner's level. `GroupByOwner` duplicates rows if an owner is read twice; the values read keeps each owner once (AC-1.9). The type comes from the `ToSource` path (the Artifact's Source); a Citation's graph has the same Source by `evidencegraphs.Link`, which this read does not re-check.
- **Neighbors.** An Artifact or graph board reads the Source only, never a sibling level (AC-1.8). The tie-break graph before Artifact (AC-1.4). An unknown at the graph stops the walk (AC-1.5). The owner's own value is not "elsewhere" (AC-1.7). A draft board equals a saved board of an owner with no rows under the same parents (T-6 compares them). The list form's fields resolve at the Source alone (`fieldAt`, unchanged).
- **Removed inputs.** Deleting the graph deletes the Citation (`citations.graph_id` CASCADE); an Artifact or Source holding Citations cannot be deleted (S15-54 D-13), so no Citation board names a missing ancestor. A cleared graph value falls back to the Artifact's, then the Source's (AC-4.2, AC-1.2, AC-1.3).
- **Real data.** None — `needsAt` and the seed are unchanged; `TestSeedAnnotations` and `TestDraftBoardScenarios` stay green.
- **Untrusted size.** `parents` comes off the wire: refused when its length differs from the level's `ups` (at most 2) before any query (D-6).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcemetadata` `owner.go` | `store.ups`; `newStore` fills it from `path[0].Ups`; `sourcePathIn` appends the up columns (D-2): Citation `SELECT t0.id, t2.source_type_id, t2.id, t0.graph_id, t0.artifact_id FROM citations t0 JOIN artifacts t1 ON t1.id = t0.artifact_id JOIN sources t2 ON t2.id = t1.source_id WHERE t0.id IN (`; Artifact `SELECT t0.id, t1.source_type_id, t1.id, t0.source_id FROM artifacts t0 JOIN sources t1 ON t1.id = t0.source_id WHERE t0.id IN (`; graph the same on `evidence_graphs`; the Source's unchanged. `OwnersAbove` (D-1) |
| `core/database/sourcemetadata` `annotation.go` | `ownerAbove`, `typesIn`'s new callback, `needOfTx` through `readAbove`, `ValuesOf` (D-2, D-4) |
| `core/database/sourcemetadata` `sourcemetadata.go` | `readAbove`, `buildBoards` (D-3, D-5); `listWorkspaces` and `ListDraftWorkspace(c *database.Catalog, level vocabkey.Level, parents []Owner) ([]WorkspaceEntry, error)` on them (D-6); doc comments name a new Citation's graph and Artifact |
| `core/database/citationrender` `load.go` | `subject.owners` (D-10); `fillValues` through `ValuesOf` (D-4) |

Errors: `sourcemetadata.invalid` → every refusal in D-6.

### FFI

`api/proto/engine.proto` (D-8):

```proto
// GetDraftMetadataBoard is the board a new owner starts with: its Source type's
// suggestions, empty, then the fields its citation formats head at level, each
// with its requirement and the value it inherits from its parents and above.
message GetDraftMetadataBoardRequest {
  string project_dir = 1;
  reserved 2;
  reserved "source_id";
  string level = 3; // "artifact", "graph" or "citation"
  // The owners directly above the new one, one per level above it: a new
  // Artifact's or graph's Source; a new Citation's graph and Artifact. Any order.
  repeated MetadataOwner parents = 4;
}
```

Handler `api/ffi/handlers/metadata.go` `GetDraftMetadataBoard`: parse each parent with `parseOwner`, then `sourcemetadata.ListDraftWorkspace(c, vocabkey.Level(req.GetLevel()), parents)`; its doc comment follows the proto's. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Draft board call | — | `GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift` `getDraftMetadataBoard(projectDir:parents:level:)` | D-9. `GoStore` maps each `MetadataOwner` to `Provenencia_Engine_V1_MetadataOwner` (`level.rawValue`, `id`), as `setMetadata` fills `req.owner`. The protocol doc comment: "The board a new owner at `level` starts with under `parents` (a new Artifact's or graph's Source; a new Citation's graph and Artifact): its type's suggestions, empty, then the fields the type's citation formats head there. The engine's read (`GetDraftMetadataBoard`), so no caller builds the rows itself." |
| Add forms' read | — | `SourcePageContext.readDraftBoardForAdd(level:)` | Passes the page's Source as the one parent; nothing else changes |

No view, state or string changes.

### Strings

None — no user-facing copy changes, and no action changes what it covers.

## 7. Steps

**STEP-1 — Ancestors are one up away**
Files: `core/database/catalogmodel/metadata_test.go`.
Do: D-1's guard: `ancestorsErr(list)` returns an error naming the level when a level reachable through `Ups` (transitively) is neither a direct up nor the end of its `SourcePath`. `TestMetadataTables` asserts the shipped list passes and a list with an extra level `"deep"` whose one up is the Citation (`{Level: LevelCitation, Column: "citation_id", ToSource: true}`) fails naming `deep`. T-1.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/catalogmodel/` passes.

**STEP-2 — One derivation of ancestors and of a resolver's rows**
Files: `core/database/sourcemetadata/owner.go`, `annotation.go`, `sourcemetadata.go`, `sourcemetadata_test.go`, `core/database/citationrender/load.go`. Skill: `add-catalog-query`.
Do: D-2, `OwnersAbove`, `ownerAbove`, `readAbove`, `ValuesOf`; `listWorkspaces` reads its owners through `readAbove` and builds its resolver through `ValuesOf` with the same two owners as today; `needOfTx` through `readAbove`; D-10 and `fillValues` through `ValuesOf`. `TestSourcePathIn`'s strings take the up columns (T-2). T-9, T-10.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/ ./core/database/citationrender/` passes with no other test changed; `TestRenderScale` keeps 10 and 14 SELECTs; `CGO_ENABLED=1 go test -tags fts5 -run '^$' -bench BenchmarkListWorkspacesScale -count 5 ./core/database/sourcemetadata/` median ns/op recorded as the "before".

**STEP-3 — One board builder reads every ancestor**
Files: `core/database/sourcemetadata/sourcemetadata.go`, `sourcemetadata_test.go`.
Do: D-3 for `listWorkspaces` (`ListDraftWorkspace` keeps its body until STEP-4), D-5. Add `newCitationOwners`, T-3, T-5.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/` passes; the same benchmark with `-count 5`: its median is the "after".

**STEP-4 — The draft board takes parents**
Files: `core/database/sourcemetadata/sourcemetadata.go`, `sourcemetadata_test.go`.
Do: D-6 on `buildBoards`. `TestListDraftWorkspaceInherited` passes `[]Owner{sourceOwner(src.ID)}`. T-6. The handler does not build until STEP-5, so STEP-4 to STEP-6 are one commit; run only this package here.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata/` passes.

**STEP-5 — The wire names the parents**
Files: `api/proto/engine.proto`, `api/proto/engine/engine.pb.go`, `macos/App/Platform/Generated/engine.pb.swift` (regenerated), `api/ffi/handlers/metadata.go`, `api/ffi/handlers/metadata_test.go`. Skill: `add-ffi-handler`.
Do: D-8. `./scripts/generate-proto.sh` (needs `protoc`, `protoc-gen-go`, `protoc-gen-swift`; never hand-edit the generated files). If it exits for a missing tool, or this is not macOS (STEP-6), stop after STEP-4 and report: hand over the branch with STEP-1 to STEP-4 committed as one commit that builds `./core/...` only. T-7, T-8.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/... ./core/...` passes.

**STEP-6 — Swift passes the parents**
Files: `macos/App/Platform/GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift`, `macos/App/Features/Sources/SourcePageContext.swift`, `macos/ProvenenciaTests/SourcePageModelTests.swift`, `SourceGraphFormModelTests.swift`, `OnboardingModelTests.swift`. Skill: `add-swift-test`.
Do: D-9. T-11.
Check: the Xcode tests in `scripts/check-pr.sh` pass with no Swift warning.

**STEP-7 — Docs and version**
Files: `docs/source-layer-data-model.md` § 5.2, `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`, `docs/deployment-plan/spike-15/deployment-plan.md` (map row), `docs/deployment-plan/spike-15/completed.md`, this plan.
Do: § 5.2: line 258 says a Citation's board inherits from its graph, else its Artifact, else its Source, and an Artifact's or graph's from its Source; line 321 says `ListDraftWorkspace` builds the draft board of a new Artifact, graph or Citation from its would-be parents, through the same builder; the **Citation** bullet's "met at the owner's ancestors" names them the same way. Version 0.40.0. The DoD's docs lines (the map's scope entry was rewritten with this plan; only the row status changes).
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-55-boards-read-every-level-above.md` reports no errors; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period ("Read a Citation's graph and Artifact on its metadata board."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/catalogmodel/metadata_test.go` `TestMetadataTables` | Shipped list → `ancestorsErr` nil; a `"deep"` level below the Citation → an error naming the owner level `deep` and the far level (`graph`) | D-1 |
| T-2 | Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestSourcePathIn` | Each level's SQL as in § 6 Go core | D-2 |
| T-3 | Go | `sourcemetadata_test.go` `TestListWorkspacesAncestors` *(new)*, table over `newLedger` + `newCitationOwners` | The rows of AC-1.1 – AC-1.9 → their Then columns (`Annotation.Need`, `MetElsewhere`, `Inherited.ValueText`, `Inherited.Owner.Level`, `Value`) | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-1.8, AC-1.9 |
| T-4 | Go | `sourcemetadata_test.go` `TestListWorkspacesInherited`, `TestListWorkspacesAnnotations`, `TestListWorkspacesAnnotationsScale`, `TestSeedAnnotations`, `TestDraftBoardScenarios` | Unchanged → green | D-3, D-5, D-11 |
| T-5 | Go | `sourcemetadata_test.go` `TestListWorkspacesCitationsScale` *(new)* | On a census Source, `newCitationOwners` then 59 more Citations on the same Artifact and graph; `databasetest.CountSelects` over a warm `ListWorkspaces` of the first Citation, then of all 60 → equal counts; `databasetest.WithinBudget` 100 ms on `databasetest.Warm` of the 60 | AC-2.1 |
| T-6 | Go | `sourcemetadata_test.go` `TestListDraftWorkspaceParents` *(new)* | AC-3.1 (both parent orders; and, entry by entry in order, its `Field.ID`, `Suggested`, `Annotation`, `Inherited` and `StaysWithoutValue` equal those of C's saved board from `boardOf`, C holding nothing), AC-3.2 (artifact and graph), each AC-3.3 and AC-3.4 refusal as its own row → `ErrInvalid` | AC-3.1, AC-3.2, AC-3.3, AC-3.4, D-3, D-6 |
| T-7 | Go | `api/ffi/handlers/metadata_test.go` `TestGetDraftMetadataBoard`, `TestMetadataBoardInherited` | Every request sends `Parents: []*engine.MetadataOwner{{Level: "source", Id: …}}`; the refusals table's row type becomes `{parents []*engine.MetadataOwner; level string; want error}` (a nil parent is a `nil` element; "the graph alone" is a one-element list); its rows: `"citation level"` row removed; add "citation with the graph alone" → `ErrInvalid`, "a nil parent" → `ErrInvalid`, "malformed parent id" and "a version 4 parent id" → `errInvalidID`; keep "no such Source", "source level", "unknown level", "an empty level" | AC-3.5, AC-3.6, D-8 |
| T-8 | Go | `api/ffi/handlers/metadata_test.go` `TestMetadataBoardAncestors` *(new)* | A fresh `newMetadataOwners` (its own project, so no other test sees the formats); the type id read with `GetSourceWorkspace` as `newMetadataOwners` does; `setFormats` `{Full: "{meta.line_number}."}`; line_number's id from `fieldIDsByKey`; AC-4.1, AC-4.2, AC-4.3 on `m.citation`, `m.graph`, `m.artifact` | AC-4.1, AC-4.2, AC-4.3 |
| T-9 | Go | `sourcemetadata/owner_test.go` `TestOwnersAbove` *(new)*, table | Citation with graph and Artifact ids and Source S → [graph, Artifact, S]; Citation with a nil graph id → [Artifact, S]; Artifact with up `{source: S}` and Source S → [S] once; Source S → none; level `"page"` → nil | D-1 |
| T-10 | Go | `core/database/citationrender/render_test.go` `TestRenderNearestLevel`, `scale_test.go` `TestRenderScale` | Unchanged → green (owners and values through `OwnersAbove` and `ValuesOf`) | D-4, D-10 |
| T-11 | Swift | `macos/ProvenenciaTests/SourcePageModelTests.swift` (line 1974), `SourceGraphFormModelTests.swift` (line 379) | `draftMetadataBoardCalls.map(\.parents) == [[MetadataOwner(level: .source, id: sourceID)]]`; every other expectation unchanged | D-9 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestSourcePathIn`, `TestGetDraftMetadataBoard`, `TestMetadataBoardInherited`, `TestDraftBoardScenarios`, `TestRenderScale`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: `rg -n 'GetSourceId\(\)' api/ffi/handlers/metadata.go` has no hit in GetDraftMetadataBoard; `rg -n 'sourceID: sourceID, level' macos` and `rg -n 'draftMetadataBoardCalls.map\(\\.sourceID\)' macos` have no hit; `rg -in 'artifact.{0,12}or.{0,14}graph' api/proto/engine.proto api/ffi/handlers/metadata.go core/database/sourcemetadata/sourcemetadata.go docs/source-layer-data-model.md macos/App/Platform/GenealogyStore.swift` leaves no line describing the draft read as Artifact or graph only (to change: `engine.proto` 888 and 890, `metadata.go` 262 and 265, `sourcemetadata.go` 850, `source-layer-data-model.md` 321, `GenealogyStore.swift` 1674; hits that stay: `engine.proto` 628 and `GenealogyStore.swift` 139 (moves), `source-layer-data-model.md` 258, and the new "a new Artifact's or graph's Source" wording); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] BenchmarkListWorkspacesScale ns/op before and after is in the PR description
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Domain doc updated: docs/source-layer-data-model.md § 5.2 (STEP-7)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

No view draws a Citation board before S15-56, so the check is the handler tests and one look in the app that nothing moved:

1. Run `CGO_ENABLED=1 go test -tags fts5 -run 'TestMetadataBoardAncestors|TestGetDraftMetadataBoard' -v ./api/ffi/handlers/`: each AC-4 case passes.
2. In the app, on a census Source with Provider "Ancestry" on the Source, open **Add artifact** and an existing Artifact's sheet: Provider shows "From Source" as before this PR; **Add evidence graph**'s form shows the same.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A duplicated owner in the values read doubles a board's rows | Each owner once (D-5); AC-1.9 |
| The extra up column slows the Artifact and graph boards | One column on a joined row; the benchmark is reported (STEP-3) |
| Moving the draft read onto `buildBoards` changes a draft board | T-6 compares a draft with a saved empty board; `TestListDraftWorkspaceInherited` and `TestGetDraftMetadataBoard` keep their expectations |

**Stop and report if:**

- After STEP-4, `rg -n 'CitationValues\{' core api --glob '!*_test.go'` finds a literal outside `ValuesOf` and `CitationValues.Without` (`annotation.go`).
- A level reachable through `Ups` is neither a direct up nor the Source at your base (T-1 fails on the shipped list): D-1 does not hold.
- `TestRenderScale`'s SELECT counts change: this PR must not change the render's reads.
- `BenchmarkListWorkspacesScale`'s median grows by more than 10% from STEP-2's to STEP-3's, or T-5 misses its budget.
- `TestDraftBoardScenarios`, `TestListWorkspacesAnnotations` or `TestSeedAnnotations` changes its expected output: no Artifact or graph board should change.
- A Swift caller other than `SourcePageContext.readDraftBoardForAdd` calls `getDraftMetadataBoard`.

## 12. Open questions

None.

## 13. PR

**Title:** S15-55 — Boards read every level above
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-55-boards-read-every-level-above.md`.
