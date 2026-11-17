# S16-45 — A graph delete names the Artifacts it leaves in no graph

**Status:** Planned
**Spike / slice:** Spike 16 · Slice 6a — A graph delete warns about its Artifacts
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: one more sentence in the graph delete confirm the kit already draws; Batch 6 working rule)
**Board:** —
**Depends on:** —
**Blocks:** —
**Branch:** `s16-45-graph-delete-names-no-graph-artifacts`
**Version bump:** patch — the next patch after `VERSION` on `main` when the branch is cut (0.19.0 → 0.19.1 at the planning base): a sentence a researcher sees in an existing confirm, on a cascade group the wire already carries; no wire or catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-catalog-delete`](../../../../.agents/skills/add-catalog-delete/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [design](../graph-delete-leaves-no-graph.md), [`catalog-deletes.md` rule 10](../../../catalog-deletes.md), working rules: "(Batch 6) A sentence added to a confirm the kit already draws is copy, not chrome"
**Planned:** 2026-11-17 against `main` @ `09f7398`
**Review:** [`S16-45-graph-delete-names-no-graph-artifacts.review.md`](S16-45-graph-delete-names-no-graph-artifacts.review.md) — Fits with changes / Ready with changes, 1 round

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

Deleting an Evidence graph leaves each Artifact that was linked only to that graph in no graph, where no Citation composer offers it. Today the delete confirm names the graph's Citations but not these Artifacts; the researcher finds out afterwards from the row badge "Not in an evidence graph" (S12-38). After this PR the confirm names them beforehand, in the words of the Artifact sheet's line when the researcher unchecks an Artifact's last graph.

**Why now.** Idea `artifact-outside-graph-marker.md`, pulled into Batch 6 (user, 2026-11-17): both ways of leaving an Artifact in no graph should warn alike.

**What stays.** The delete still goes ahead; the sentence never blocks. The confirm's title, its first sentence, its buttons and its Citations sentence are unchanged. The Subject, Artifact and Source deletes are unchanged.

## 2. User stories

**US-1.** As a researcher, when I delete an Evidence graph, I see which Artifacts will be in no evidence graph afterwards, so that I can relink them or cancel.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Source with graphs Default and Jones; Artifact `ART-A` linked only to Jones, `ART-B` linked to both. Delete Jones | The confirm's message ends with the sentence "ART-A won’t be in an evidence graph. Citations can’t use it until it is linked." `ART-B` is not named |
| AC-1.2 | Jones holds `ART-A` and `ART-C`, both only in Jones | "ART-A and ART-C won’t be in an evidence graph. Citations can’t use them until they are linked." |
| AC-1.3 | Jones holds 25 Artifacts that are in no other graph | The engine reports Total 25 with the first 20 refs listed; the sentence names 20 refs and ends ", and 5 more", then the plural ending of AC-1.2 |
| AC-1.4 | Every Artifact of Jones is also in Default, or Jones has no Artifact | No such group in the report; the confirm reads as today |
| AC-1.5 | Jones also has 2 Citations | The Citations sentence comes first, then the Artifacts sentence |
| AC-1.6 | Jones is deleted after AC-1.1's confirm | `ART-A` has no link left and its row shows the "Not in an evidence graph" badge; `ART-B` is still linked to Default |

## 3. Scope

| In | Covered by |
| --- | --- |
| A non-blocking cascade edge on `KindEvidenceGraph` listing the Artifacts linked only to that graph, via `evidence_graph_artifacts.last_graph` | STEP-1, AC-1.1–AC-1.5 |
| The via shared with Swift (`DeleteImpactCascadeVia.leavesNoGraph`, the `swift_vocabulary_test` row) | STEP-2, STEP-3 |
| The confirm sentence for that via (`L10n.DeleteImpact.leavesNoGraph`), singular and plural | STEP-3, AC-1.1–AC-1.3 |
| `catalog-deletes.md` rule 10, the `deleteimpact` README and `add-catalog-delete` name the cascade | STEP-4 |

| Out | Home |
| --- | --- |
| Naming the Artifacts by label instead of ref (every cascade line names refs) | not planned ([design § Not this batch](../graph-delete-leaves-no-graph.md#not-this-batch)) |
| A relink action in the confirm | not planned ([design § Not this batch](../graph-delete-leaves-no-graph.md#not-this-batch)) |
| Showing cascade groups on the blocked notice (a graph with Subjects) | not planned: the notice lists what blocks, and the delete cannot happen |
| Artifact delete, Source delete, the unlink sheet | not planned: none leaves another Artifact in no graph; the sheet already warns |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Cascade vias | `core/database/deleteimpact/handle_gone.go` const block `ViaLeavesHandle`, `ViaDeletesCitations`, `ViaLastMember` | The vias shared with Swift. No via for Artifacts left in no graph |
| Cascade edges | `handle_gone.go` `buildCascadeEdges` | Returns `[]inboundEdge{lastMemberEdge, leavesHandle}`, both `Parent: KindSubject`, `Bucket: BucketFacet`, with `Count` and `List`. Not facet releases: they inform about a consequence |
| Report cascades | `facets.go` `cascadesFor` | Named facets first (for a graph: `citations.graph_id`), then every `cascadeEdgeList` edge whose `Parent` is the kind. `impact.go` `Impact` fills `Report.Cascades` through `collectGroups` for allowed and refused reports |
| Graph links release | `facets.go` `buildFacetReleases`, `rowFacet(KindEvidenceGraph, "evidence_graph_artifacts", "graph_id", …)` | Releases every link of the graph, unnamed. Its `Count`/`List` must equal what it releases, so it cannot be named for a subset |
| SQL helpers | `probes.go` `countSQLFn`, `listSQLFn` | Take one query with the parent id (and the limit for the list); the list dedupes ids |
| Listed projection | `projectors.go` `projectArtifact` | Gives an Artifact's label and its Source page location; used for `KindArtifact` already |
| Schema | `core/database/migrations/000055.sql` `evidence_graph_artifacts` | PK `(graph_id, artifact_id)`, index `evidence_graph_artifacts_artifact_id_idx` on `artifact_id` |
| Graph gates | `register.go` `isLastGraph`, `fkEdge(KindEvidenceGraph, "subjects.graph_id", …)` | A Source's last graph is refused (`last_graph`); a graph with Subjects is refused |
| FFI | `api/ffi/handlers/delete_impact.go` | `out.Cascades = groupsToProto(r.Cascades)`: every group goes to the wire, no change needed |
| Swift vocab | `macos/App/Platform/ConclusionVocabulary.swift` `DeleteImpactCascadeVia` | Cases `leavesHandle`, `deletesCitations`, `deletesHandles`, `unrecognized`; `init(rawValue:)` and `wire` |
| Confirm copy | `macos/App/DesignSystem/Recipes/DeleteImpact/PVDeleteImpact.swift` `PVDeleteImpactCopy.cascadeLines` | One sentence per cascade group in report order. An unknown via falls to `L10n.DeleteImpact.alsoAffects` ("This also changes artifacts ART-A.") — what the new group would read today without this PR |
| Copy | `macos/App/Platform/L10n.swift` `L10n.DeleteImpact.deletesHandles(count:handleRefs:)` | Precedent: refs, then a `%#@records@` substitution with one/other variations in `macos/App/Resources/Localizable.xcstrings` |
| Sheet copy | `L10n.Sources.artifactGraphsNone` | "This artifact won’t be in an evidence graph. Citations can’t use it until it is linked." |
| Graph delete entry | `macos/App/Features/Sources/SourcePageModel.swift` `askDeleteGraph` | `presentImpact(kind: "evidence_graph", …)` → the shared confirm. No change |
| Row badge | `macos/App/Features/Sources/SourcePageArtifactRow.swift` `L10n.Sources.artifactNotInGraph` | The after-the-fact badge. No change |
| Tests | `core/database/deleteimpact/impact_test.go` `TestImpactEvidenceGraph` "a graph's Citations go with it" | Asserts `len(got.Cascades) == 1`. Its `art` is created with zero-value `Graphs` (every graph), so it is in Default too and stays out of the new group |
| Tests | `core/database/evidencegraphs/evidencegraphs_test.go` "a graph takes its Citations with it" | Asserts `len(report.Cascades) == 1`; `a` is linked to Default and Jones, so it stays out too |
| Tests | `api/ffi/swift_vocabulary_test.go` row "cascade vias" | `want: sorted(ViaLeavesHandle, ViaDeletesCitations, ViaLastMember)` |
| Tests | `macos/ProvenenciaTests/PVDeleteImpactTests.swift` `graphDeleteConfirmNamesTheCitationsItTakes`, `cascadeLinesNameDeletedHandles` | The shape the new Swift tests copy |

**Precedent.** The `citations.graph_id` cascade (graph delete names its Citations) and `canonical_entities.last_member` (an edge in `buildCascadeEdges` that is not a facet release). Copy the edge shape of `lastMemberEdge` and the copy shape of `deletesHandles`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The cascade registry gets one home: `core/database/deleteimpact/cascades.go` *(new)* takes, moved unchanged from `handle_gone.go`, the shared via const block, `cascadeEdgeList` and `buildCascadeEdges`; the new edge is an `inboundEdge` literal inside `buildCascadeEdges`, appended after `leavesHandle`. The handle helpers (`lastMemberRows`, `subjectHandleCascade*`, `handleGoesWithout`, `releaseHandleIfGone`, `LastMemberGroup`) stay in `handle_gone.go` | An informing edge, like `lastMemberEdge`; one file names every cascade (map review M-2) | Naming the `evidence_graph_artifacts.graph_id` facet — its List must equal everything it releases (all links); a new Report field — `Cascades` already means "goes with it, never blocks" |
| D-2 | Via `ViaLeavesNoGraph = "evidence_graph_artifacts.last_graph"` *(new)*, in the shared const block of `handle_gone.go` | Table-dot-meaning, as `canonical_entities.last_member`; distinct from the facet's `evidence_graph_artifacts.graph_id` | Reusing the facet's via string — two groups would share a via |
| D-3 | Query: links of the graph whose Artifact has no link to another graph, the predicate written once as a const fragment (`soleLinkFrom` *(new)*: `FROM evidence_graph_artifacts l WHERE l.graph_id = ? AND NOT EXISTS (…)` as below) that both strings build on, as `fkEdge` builds its two queries from one shape. Count `SELECT COUNT(*) FROM evidence_graph_artifacts l WHERE l.graph_id = ? AND NOT EXISTS (SELECT 1 FROM evidence_graph_artifacts o WHERE o.artifact_id = l.artifact_id AND o.graph_id != l.graph_id)`; List the same joined to `artifacts a` selecting `a.id, a.ref`, `ORDER BY a.ref COLLATE NOCASE LIMIT ?`, through `countSQLFn` / `listSQLFn` | Same order as the Citations list; the `NOT EXISTS` uses the `artifact_id` index | Reading links in Go and filtering — more rows read for the same answer |
| D-4 | `Child: KindArtifact`, `Bucket: BucketFacet`, `Parent: KindEvidenceGraph` | `projectArtifact` already projects an Artifact; `BucketFacet` matches the other cascade edges | A new kind |
| D-5 | Swift case `DeleteImpactCascadeVia.leavesNoGraph` *(new)*; `cascadeLines` maps it to `L10n.DeleteImpact.leavesNoGraph(count:refs:)` *(new)* | Each known via has its own sentence | Leaving it on `.unrecognized` — "This also changes artifacts ART-A." does not say what happens |
| D-6 | Copy, key `deleteImpact.confirm.leavesNoGraph`, value `%2$@ %#@graphs@`, substitution `graphs` (argNum 1, `lld`): one "won’t be in an evidence graph. Citations can’t use it until it is linked.", other "won’t be in an evidence graph. Citations can’t use them until they are linked." | The Artifact sheet's words (`artifactGraphsNone`: "won’t be in an evidence graph. Citations can’t use it until it is linked."), so both warnings read alike (user, 2026-11-17); the count is not printed, as in `deletesHandles` | Printing the count ("The graph’s 2 artifacts won’t be in any evidence graph") — reads as if the Artifacts were deleted |
| D-7 | Refs, not labels, in the sentence | Every cascade line names refs; the joined list and ", and N more" come from `cascadeLines` unchanged | Labels — a change to every line (Out) |
| D-9 | `func CascadeVias() []string` *(new)* in `cascades.go` returns the `Via` of every `Named` facet release (`facetReleases()`) and every `cascadeEdgeList` entry; the "cascade vias" row of `swift_vocabulary_test.go` reads `want: sorted(deleteimpact.CascadeVias()...)` | The registry is the only list: a new cascade fails the parity test until Swift has its case (review M-1), as `graphalign.ConnectionOutcomes()` does for its row | Adding the const to the hand-kept `want` — a forgotten line passes the test and Swift falls to `alsoAffects` |
| D-8 | Tests: Go table test in `deleteimpact`; a delete-then-check subtest in `evidencegraphs`; Swift tests in `PVDeleteImpactTests` | Each layer where the behavior lives | A UI test — the confirm's message is a string `cascadeLines` returns |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `ViaLeavesNoGraph` *(new)* | const | `ViaLastMember` | Extends the same const block, now in `cascades.go` |
| `cascades.go` *(new)* | file | `handle_gone.go` (holds the vias and `buildCascadeEdges` today) | Moves the registry out of a file about handles; no new code but the edge, `soleLinkFrom` and `CascadeVias` |
| `soleLinkFrom` *(new)* | const | `fkEdge` in `probes.go` | One predicate for count and list |
| `CascadeVias()` *(new)* | func | `ResourceInboundVias()` | The cascade counterpart, read by the parity test |
| `DeleteImpactCascadeVia.leavesNoGraph` *(new)* | enum case | `.deletesCitations` | Extends the enum |
| `L10n.DeleteImpact.leavesNoGraph(count:refs:)` *(new)*, key `deleteImpact.confirm.leavesNoGraph` | key | `deletesHandles(count:handleRefs:)` | Extends `L10n.DeleteImpact` |
| `TestImpactEvidenceGraphLeavesNoGraph` *(new)* | test | `TestImpactEvidenceGraph` | A table test of its own (go-tests rule); the existing test is a sequence of subtests on one fixture |

**Builds on.** `cascadeEdgeList` / `cascadesFor`, `countSQLFn` / `listSQLFn`, `projectArtifact`, `cascadeLines`, `swift_vocabulary_test`.
**Deletes.** None — nothing becomes dead.
**Next adds.** A later informing cascade on any kind is one more edge in `buildCascadeEdges` and one Swift case; the parity test asks for the case.

### Reach

None — no new path into existing code: the confirm already renders any cascade group; the new state (a graph whose Artifacts are in no other graph) is reachable today and only gains a sentence.

### Scale

At the map's Scale (one Source holds tens of Artifacts and a handful of graphs) the count and list read the graph's links once each; the list sorts the qualifying refs and returns at most 20 (`listedCap`). A crafted graph with 100,000 links costs one indexed `NOT EXISTS` per link, in the read transaction `Snapshot` already opens, the same order as the Citations count beside it. No write, cache or key changes.

### Edges

- **Assumptions.** `cascadeLines` assumes each group's `listed` is non-empty when shown and `total ≥ listed.count`; `collectGroups` skips a zero count and caps the list (T-1 "no sole links", "25 sole links").
- **Neighbors.** An Artifact in this graph and another → not listed; in this graph only → listed; in no graph at all → not a link of this graph, so not listed (T-1).
- **Removed inputs.** A refused report (graph with Subjects) also carries the group; the notice does not show cascades, so nothing changes there (T-1 "refused graph"). The last graph is refused before cascades are read.
- **Real data.** None — no table or seed drives the rule.
- **Untrusted size.** Links per graph from a crafted catalog: bounded by the `LIMIT` on the list; the count is one aggregate (see Scale).

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/deleteimpact` | `cascades.go` *(new)* per D-1: the moved const block plus `const ViaLeavesNoGraph = "evidence_graph_artifacts.last_graph"` *(new)*; the moved `cascadeEdgeList` and `buildCascadeEdges`, which returns `{lastMemberEdge, leavesHandle, <graph edge literal per D-3, D-4>}`; `soleLinkFrom` *(new)*; `func CascadeVias() []string` *(new)* per D-9 |

Errors: none new.

### FFI

None — `GetDeleteImpact` already sends every cascade group.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Via case | `DeleteImpactCascadeVia.leavesNoGraph` | `macos/App/Platform/ConclusionVocabulary.swift` | `init(rawValue:)` and `wire` both map `"evidence_graph_artifacts.last_graph"` |
| Confirm sentence | `PVDeleteImpactCopy.cascadeLines` | `macos/App/DesignSystem/Recipes/DeleteImpact/PVDeleteImpact.swift` | `case .leavesNoGraph: return L10n.DeleteImpact.leavesNoGraph(count: group.total, refs: joined)` |

States: no such group → no sentence (as today). Accessibility: the confirm's message is read as it is today; nothing new.

### Strings

L10n keys *(new)*: `L10n.DeleteImpact.leavesNoGraph(count:refs:)` = `deleteImpact.confirm.leavesNoGraph`, per D-6, comment "Allowed graph delete confirm, appended after the Citations line; arguments are how many Artifacts and the artifact ref(s), such as ART-7KD45". Removed: none.

## 7. Steps

**STEP-1 — Engine cascade**
Files: `core/database/deleteimpact/handle_gone.go`, `core/database/deleteimpact/cascades.go` *(new)*, `core/database/deleteimpact/impact_test.go`. Skill: `add-catalog-delete`.
Do: first move the const block, `cascadeEdgeList` and `buildCascadeEdges` to `cascades.go` unchanged and run the check (no behavior change); then add the const (D-2), `soleLinkFrom` and the edge (D-1, D-3, D-4) and `CascadeVias` (D-9). Write T-1.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/deleteimpact/...` passes, including `TestImpactEvidenceGraph` unchanged.

**STEP-2 — Delete agrees with the report**
Files: `core/database/evidencegraphs/evidencegraphs_test.go`.
Do: write T-2.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/evidencegraphs/...` passes.

**STEP-3 — Swift case and copy**
Files: `api/ffi/swift_vocabulary_test.go`, `macos/App/Platform/ConclusionVocabulary.swift`, `macos/App/DesignSystem/Recipes/DeleteImpact/PVDeleteImpact.swift`, `macos/App/Platform/L10n.swift` (beside `deletesHandles`), `macos/App/Resources/Localizable.xcstrings` (the key beside `deleteImpact.confirm.deletesHandles`), `macos/ProvenenciaTests/PVDeleteImpactTests.swift`. Skills: `add-localized-string`, `add-swift-test`.
Do: set the "cascade vias" row to `want: sorted(deleteimpact.CascadeVias()...)` (T-3, D-9); D-5, D-6; write T-4 – T-7 in the `PVDeleteImpactTests` suite, after `graphDeleteConfirmReadsSingularForOneCitation`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/...` passes; `python3 -m json.tool macos/App/Resources/Localizable.xcstrings > /dev/null` succeeds; on macOS, `xcodebuild test` (the command `scripts/check-pr.sh` runs as `xcode-test`) passes, no Swift warning. Off macOS, `check-pr.sh` reports `xcode-test (needs macOS)`: report T-4 – T-7 and the Swift build as not run, and hand the PR to a macOS run; do not mark them passed.

**STEP-4 — Docs**
Files: `docs/catalog-deletes.md` rule 10 (after "the confirm names them (`Report.Cascades`, via `citations.graph_id`)": add that the confirm also names, via `evidence_graph_artifacts.last_graph`, the Artifacts linked to that graph and to no other, which it leaves in no graph); `core/database/deleteimpact/README.md` (after the `canonical_entities.last_member` sentence: "Graph delete Impact lists the Artifacts it leaves in no graph under `evidence_graph_artifacts.last_graph`."); `.agents/skills/add-catalog-delete/SKILL.md` (after the `Named: true` bullet: "An informing cascade that is not a release (a consequence such as `canonical_entities.last_member` or `evidence_graph_artifacts.last_graph`) is an edge in `buildCascadeEdges` in `core/database/deleteimpact/cascades.go` *(new)*, with its via in that file's const block and a `DeleteImpactCascadeVia` case; `TestSwiftVocabularyMatchesGo` reads `CascadeVias()` and fails until the case exists."); `docs/deployment-plan/spike-16/completed.md` (a paragraph under Batch 6: "S16-45 (#N): the graph delete confirm names the Artifacts it leaves in no evidence graph, through a new `deleteimpact` cascade, `evidence_graph_artifacts.last_graph`."), `docs/deployment-plan/spike-16/deployment-plan.md` (map row Status `Landed #N`), this plan (Status and a Landed note). Version: `VERSION` and `core/version.go` `Version` to the next patch, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj` (4 at the planning base) to the same value, in this step's commit.
Do: per the Definition of done.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Name the Artifacts a graph delete leaves in no graph."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/database/deleteimpact/impact_test.go` `TestImpactEvidenceGraphLeavesNoGraph` *(new)*, table-driven | Fixture per case: a new catalog and Source (as `TestImpactEvidenceGraph` builds them); Artifacts made with `artifactstest.Create` and zero-value `Graphs` start in Default; an Artifact meant for Jones only goes there with `evidencegraphstest.Split(t, c, userID, src.ID, "Jones", ids...)`, one in both with `evidencegraphstest.Create(t, c, userID, src.ID, "Jones", ids...)`; Citations with `observationstest.Cite`, a Subject with `subjectstest.On(t, c, userID, jones.ID, "person", "Alice")`. Cases: "sole link" (A in Jones only, B in both) → one group via `ViaLeavesNoGraph`, `Kind == KindArtifact`, `Total 1`, listed `[A.Ref]` with `Location.ArtifactID` set; "two sole links" → `Total 2`, refs sorted; "no sole links" (every Artifact also in Default) → no group with that via; "empty graph" → no group; "unlinked Artifact" (C in no graph, Jones holds only B, which is in Default too) → no group; "25 sole links" → `Total 25`, 20 listed; "with Citations" (2 Citations in Jones) → `Cascades[0].Via == ViaDeletesCitations`, `Cascades[1].Via == ViaLeavesNoGraph`; "refused graph" (a Subject in Jones) → `Allowed` false, the group still in `Cascades` | AC-1.1–AC-1.5 ("no sole links", "empty graph": AC-1.4), D-1–D-4 |
| T-2 | Go | `core/database/evidencegraphs/evidencegraphs_test.go` subtest "a graph delete leaves its sole Artifacts in no graph" *(new)* With the file's `fixture`: `a := f.newArtifact(t, s, "Page A")` (no link), `b := f.newArtifact(t, s, "Page B")`, `f.link(t, def.ID, b)`, then `f.createGraph(t, evidencegraphs.CreateInput{SourceID: s.ID, Name: "Jones", ArtifactIDs: [][]byte{a, b}})`, so A is in Jones only and B in both; `graphImpact` lists A only; `f.deleteGraph(jones)`; `evidencegraphstest.ArtifactGraphs(A)` empty, `ArtifactGraphs(B)` = `[Default]` | AC-1.6 |
| T-3 | Go | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` "cascade vias" (updated) | `CascadeVias()` = Swift `DeleteImpactCascadeVia` wires: the four vias, with `evidence_graph_artifacts.last_graph` | D-2, D-5, D-9 |
| T-4 | Swift | `PVDeleteImpactTests.swift` `graphDeleteConfirmNamesTheArtifactItLeavesInNoGraph` *(new)* | group via `evidence_graph_artifacts.last_graph`, kind `artifact`, total 1, listed `ART-A` → `["ART-A won’t be in an evidence graph. Citations can’t use it until it is linked."]` | AC-1.1, D-6 |
| T-5 | Swift | `graphDeleteConfirmNamesArtifactsInThePlural` *(new)* | total 2, `ART-A`, `ART-C` → `["ART-A and ART-C won’t be in an evidence graph. Citations can’t use them until they are linked."]` | AC-1.2 |
| T-6 | Swift | `graphDeleteConfirmCountsArtifactsBeyondTheListedCap` *(new)* | total 25, 20 listed → one line with prefix "ART-1, " and containing ", and 5 more" and suffix "Citations can’t use them until they are linked." | AC-1.3 |
| T-7 | Swift | `graphDeleteConfirmNamesCitationsThenArtifacts` *(new)* | cascades `[citations.graph_id (2), evidence_graph_artifacts.last_graph (1)]` → two lines, Citations first | AC-1.5 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestImpactEvidenceGraph`, the evidencegraphs "a graph takes its Citations with it" subtest (both assert one cascade; §4 says why they stay at one), `PVDeleteImpactTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory — no brief (Batch 6 rule); no new kit primitive
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — patch
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated — not gated
- [ ] Domain doc updated: docs/catalog-deletes.md rule 10; deleteimpact README; add-catalog-delete
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project. On a Source, make sure it has two graphs, Default and Jones (add Jones from the Source page).
2. Add Artifact A and in its sheet check only Jones. Add Artifact B with both graphs checked.
3. Click the trash button on Jones. The confirm reads the usual sentence, then "ART-… (A's ref) won’t be in an evidence graph. Citations can’t use it until it is linked." B's ref is not named.
4. Delete. A's row shows "Not in an evidence graph"; B's does not.
5. Add a graph Smith, link B to it, delete Smith: the confirm has no Artifacts sentence (AC-1.4).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| An existing test asserting one graph cascade gains a second group | §4 shows both fixtures link their Artifact to Default too; T-1 pins the order |
| The plural substitution renders the count or the wrong form | T-4, T-5 and T-7 compare whole strings; T-6 checks prefix, the `summaryMore` overflow and suffix, as `graphDeleteConfirmCountsCitationsBeyondTheListedCap` does |

**Stop and report if:**

- Moving the const block, `cascadeEdgeList` or `buildCascadeEdges` to `cascades.go` changes any test result (it must be a pure move).
- `buildCascadeEdges` or `cascadesFor` no longer exist as §4 says, or `Report.Cascades` is no longer filled for a graph.
- `TestImpactEvidenceGraph` or the evidencegraphs Citations subtest fails with two cascades (their Artifact is in Jones only at your base).
- The `swift_vocabulary_test` "cascade vias" row cannot read a new case without changing its regex.
- You are off macOS at the end of STEP-3: report the Swift checks as not run (STEP-3), do not claim them.
- `listSQLFn` cannot take the D-3 list query (it needs other arguments than the graph id and the limit).

## 12. Open questions

None.

## 13. PR

**Title:** S16-45 — A graph delete names the Artifacts it leaves in no graph
**Body:** objective in one sentence; what shipped against US-1; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-45-graph-delete-names-no-graph-artifacts.md`.
