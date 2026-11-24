# Ideas parking lot

Scratch space for product ideas that are **not** on the current deployment plan and should not be treated as commitments.

Use this folder when something useful pops up mid-work and would otherwise get lost. Capture enough context that a future reader understands the problem and the rough shape of a solution. Do **not** turn entries into spike tasks, schemas, or UI specs until they are deliberately pulled into a roadmap spike.

## Rules of thumb

- **Not authoritative.** Domain and stack decisions stay in the sibling docs under [`docs/`](../). Spikes live under [`deployment-plan/`](../deployment-plan/).
- **Not scheduled.** Adding a file here does not put it on the current spike (or any spike).
- **Prefer one file per domain cluster.** Keep related leftovers in one file with sections; link out to model docs when the idea depends on an existing layer.
- **Rough is fine.** Bullets, open questions, and “maybe later” notes are enough.
- **Promote out.** When an idea is pulled into a deployment-plan spike, move the file into that spike folder (or cut the section that shipped).
- **Delete when done.** A shipped or abandoned idea does not stay here. Git and the spike / PR that shipped it are the record. Open leftovers move into another current idea, a spike note, a domain doc, or a skill — never an `ideas/archive/` folder.
- **Dogfood first.** Fresh UI friction from using the app on real data starts as one file under [`docs/dogfood/ux/`](../dogfood/ux/). Move it here when it is parked longer-term; delete the dogfood file when this (or a spike) is the copy.

## Current ideas

### Evidence graph and canvas

- [`evidence-graph-followups.md`](evidence-graph-followups.md) — card image memory, upward shadows, P3 color drift, keyboard multi-select, reloading sign
- [`evidence-graph-structure-shortcuts.md`](evidence-graph-structure-shortcuts.md) — place or paste a common cluster; field hints from transcription
- [`graph-canvas-second-host.md`](graph-canvas-second-host.md) — what a family-tree canvas host still needs from GraphCanvas

### Citation composer and media

- [`citation-composer-followups.md`](citation-composer-followups.md) — bridge-mode subject filter; cropped citation preview; a citation preview beside each metadata board (from S15-65)
- [`depictions-and-likenesses.md`](depictions-and-likenesses.md) — Spike 10 / 14 leftovers (page-change confirm, PDF Artifact thumbnails, audit items)
- [`audio-video-sources.md`](audio-video-sources.md)
- [`text-quote-locators.md`](text-quote-locators.md)

### Promote, matching, names

- [`promote-ranking.md`](promote-ranking.md) — rebuild Promote's ranking on Evidence graph scoring; coverage-aware similarity; alike-pair memo (name index on commit and the narrower canon walk went to Spike 16 Batch 2)
- [`provisional-identity-claims.md`](provisional-identity-claims.md) — Promote Accepted / Provisional status; possible values from provisional members on conclusion pages
- [`matching-test-suite.md`](matching-test-suite.md) — scenario goldens, invariants, simulated world, scoreboard, labeler; remember researcher decisions
- [`international-names.md`](international-names.md) — other name patterns, transliteration, calendars, impossible dates, Daitch–Mokotoff
- [`kinship-view.md`](kinship-view.md) — family trees reading every kinship shape as one fact, and patterns beyond spouse, parent and grandparent
- [`organizations.md`](organizations.md) — Organization as a Subject type; descoped from S11-48
- [`place-gazetteer-service.md`](place-gazetteer-service.md)

### Conclusion pages and provenance

- [`person-page-performance.md`](person-page-performance.md) — record links memo and a household-sized budget, Timeline participants sent once, lazy Timeline cards, siblings sent once
- [`person-page-followups.md`](person-page-followups.md) — the Conclusion lists' silent refresh failure, partial record-links lines, a cap on graphs per person
- [`wide-layout.md`](wide-layout.md) — pages still waiting for a Wide frame (the Persons, Events and Places lists, Properties, Metadata, Event and Place pages) and the Person Sources rows at narrow widths

### Properties, vocabulary, Sources

- [`source-page-followups.md`](source-page-followups.md) — missing-Source errors outside the page context, delete after a delete elsewhere, the fake's blank Source for a missing id
- [`source-type-packages.md`](source-type-packages.md) — citation styles as installable packages of types, fields and formats; raised in Spike 15, which seeds the *Evidence Explained*-style set as the product default
- [`event-as-of-followups.md`](event-as-of-followups.md) — Spike 16 Batch 5 leftovers: as-of on a Place, hide as-of on instantaneous event types
- [`properties-and-terms.md`](properties-and-terms.md) — binding order, event-type-scoped properties, Occupation seed, term management (direction / inverses), failed bind after create
- [`source-to-source-relationships.md`](source-to-source-relationships.md)
- [`registry-source-import.md`](registry-source-import.md) — paste a record URL from Ancestry, FamilySearch and similar; access unproven
- [`share-packages.md`](share-packages.md) — also holds the crafted-project hardening parked when Spike 12 closed

### Kit, tooling and refactors

- [`performance-possibilities.md`](performance-possibilities.md) — small speed-ups reviews found in untouched code: the formats preview picker's options rebuilt on every redraw
- [`kit-layering.md`](kit-layering.md) — the kit's delete impact taking a Features type, hand-built hover focus rings, page-column metrics and diagram options with one caller
- [`value-formatting.md`](value-formatting.md) — two date formatters, editor flags in the date draft, integer text, event formatting in Features
- [`catalog-query-layer.md`](catalog-query-layer.md) — Swift mutations still sent beside a write's effects (Source create and retype, field relabel and delete); the rest went to Spike 16 slice 6g
- [`graph-cache-followups.md`](graph-cache-followups.md) — kinship pivots on `deps`, value columns repeated across readers, two toponym readers, filed-link reads
- [`search-index-followups.md`](search-index-followups.md) — search kinds owning their columns; a term rename leaving handle documents stale
- [`swift-test-fixtures.md`](swift-test-fixtures.md) — Artifact file fixtures, per-key registry tests and fake reads, the fake's saved observations
- [`plan-docs-tooling.md`](plan-docs-tooling.md) — the spike-close link comparison as a script; anchors and a gate over every doc
- [`history-menu-labels.md`](history-menu-labels.md) — the Back/Forward history menu's rows: a long name loses its section, graph rows do not name their Source
- [`value-row-owner-check.md`](value-row-owner-check.md) — a date or name row shared by two owners in a crafted catalog; `PutTx` edits it in place for both

### App shell and collaboration

- [`multiple-windows-and-sync.md`](multiple-windows-and-sync.md) — what a return to several workspace windows needs, and what sync between two researchers' copies adds on top

Closed spikes (decisions, not PR order): [`docs/deployment-plan/archive/`](../deployment-plan/archive/).

Pulled into [Spike 15](../deployment-plan/spike-15/): nested Sources / derivation / templates ([`source-structure-later.md`](../deployment-plan/spike-15/source-structure-later.md)); Source privacy toggle; credibility field UX; rethink of Source metadata and type suggestions.
