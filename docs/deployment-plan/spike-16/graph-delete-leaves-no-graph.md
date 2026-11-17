# A graph delete names the Artifacts it leaves in no graph

**Status:** Batch 6, pulled in 2026-11-17 (user). PR: S16-45. Was the idea `docs/ideas/artifact-outside-graph-marker.md`, left over when the card marker for an Artifact in no Evidence graph went to Spike 12 (S12-38, brief S12-D7; user, 2026-10-27).

## Problem

Since S12-22 an Artifact may be in no Evidence graph. No Citation composer offers it then, so nothing can cite it until it is linked again. There are two ways an Artifact ends up there:

1. **The researcher unchecks its last graph in the Artifact sheet.** The sheet says so while they do it: "This artifact won't be in an evidence graph. Citations can't use it until it is linked." (`L10n.Sources.artifactGraphsNone`).
2. **The researcher deletes a graph.** Each Artifact linked to that graph and to no other loses its last link. The delete confirm names the graph's Citations, which go with it (`citations.graph_id`), but says nothing about these Artifacts.

Afterwards the Artifact's row on the Source page carries the "Not in an evidence graph" badge (S12-38), so the researcher finds out only after the fact. The user decided the confirm should say so beforehand, so that both ways warn alike (user, 2026-11-17).

The idea was written before the graph delete took its Citations with it. It said an Artifact with Citations protects the graph, and that `deleteimpact` had no group that informs without blocking. Neither is true today. A graph is refused only for its Subjects and when it is its Source's last graph, and `Report.Cascades` already informs without blocking: the Subject delete names the record it leaves (`identity_claims.subject_id`) and the one it deletes (`canonical_entities.last_member`).

## Shape

- **Engine.** `deleteimpact` gains one more non-blocking cascade on `KindEvidenceGraph`. It lists the Artifacts linked to the graph and to no other graph, by ref, and is capped like every listed group. It is information about a consequence, not a release: the graph's links are already released by their facet (`evidence_graph_artifacts.graph_id`), and this edge only says which of those links was an Artifact's last.
- **App.** The confirm already appends one sentence per cascade group (`PVDeleteImpactCopy.cascadeLines`). The new via gets its own sentence, in the words of the Artifact sheet's line. Nothing else in the confirm changes: same alert, same buttons, same layout.
- **No brief.** One more sentence in a confirm the kit already draws is copy, not chrome (user, 2026-11-17; Batch 6 working rule).

## Not this batch

- Naming those Artifacts by label instead of by ref: every cascade line names its rows by ref today. Changing that is a change to every line, and is not planned.
- A way to relink the Artifacts from the confirm: not planned. The Artifact sheet relinks them.
