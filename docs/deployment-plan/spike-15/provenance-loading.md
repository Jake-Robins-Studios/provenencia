# Provenance loading and drawing

**Status:** Shipped as S15-27, S15-28 and S15-29; deleted with the spike folder at close ([`archive-docs`](../../../.agents/skills/archive-docs/SKILL.md)). Was a Spike 15 design input (pulled in from `docs/ideas/provenance.md` on 2026-11-09, user). Two performance follow-ups from Spike 13, now PRs in [`deployment-plan.md`](deployment-plan.md): the cap is **S15-27** (brief S15-D17), for the provenance sheet only: the Why accordion on the Event and Place pages is deprecated (user, 2026-11-09), so the notes below about the Why no longer apply; loading records when the sheet opens is **S15-28** (engine) and **S15-29** (app), growing the on-open call S15-21 adds for citations. The measurements each section asks for are the first step of those PRs' plans.

## Cap the records a provenance table draws

**Spike 15** (S15-21) shows each record's formatted citation, so the rows it draws are longer. Measure the cap with formatted rows.

The user accepted this risk on 2026-11-03 (S13-36 review SEC-1).

Shipped in S15-27 ([S15-D17](design/archive/S15-D17-provenance-table-fold.md)) as a fold of 50 records with the kit's Show more row. First layout, Debug build, best of 3: 300 records 1558 ms before, 266 ms after; 1,200 records 6691 ms before, 266 ms after.

Related: the S13-36 ship log (in git with #702), SEC-1 and F-11.

## Load records when the sheet opens

Raised as S13-06 review PRF-1 and deferred by the user on 2026-10-30; looked at again after S13-11 (#650) and parked on 2026-10-31.

`GetConclusionDetail` is the one read behind a detail page. For the Person page, it returns every Property's values, and every record behind each value with its outcome, Source, Artifact, Citation and page. It does the same for the fields the life rows read off the person's events and event–place links (`conclusiondetails.PersonDerivedRows`).

- **Cost (S13-06 PRF-1).** Four extra batched SQL rounds per Person page load, the same however many events or Places the person has. The rows returned grow with every record of each owner, across all of its Properties (`sqlOutcomes` has no Property filter). S13-11 added two text columns and one locator decode per record.
- **Not measured.** The Spike 13 map's **Scale** gives no records-per-person or records-per-Place figure.
- **Cache.** Swift keeps a detail for the session until a write clears it. The cost falls on the first open and on each open after an edit.
- **Who uses it.** Most visits never open a provenance sheet. The researcher may be on the way to Family, Timeline or Gallery, and the records are read anyway.

**Since Spike 16 Batch 2** (S16-11, S16-30) the records compose from memory (the node's outcome rows, Subject records, Source records) instead of SQL, so this idea is only about the size of the page read's payload; measure that before pulling it in.

**Spike 15 takes the first step** (2026-11-09), and S15-28 and S15-29 finish it. Formatted citations are fetched when the provenance sheet opens, not with the page: S15-21 asks one batch render call for the sheet's Citations, which reads SQL in a few batched queries and caches nothing ([`deployment-plan.md`](deployment-plan.md) rule "Citations render on demand, from SQL"; S15-16 measures it at 300 Citations). So the sheet already gains a load-on-open call, its loading and failed states (S15-D9), and the "a write lands while the sheet is open" question for citation text. The records themselves still arrive with the page read until S15-28 and S15-29 move them onto the same on-open call; S15-21's call is the one that grows, not a second one. That first step landed in S15-21: the call is the `provenanceSheet` query key (`CatalogProvenanceSheetRead`, released when the sheet closes), and S15-29 adds the records to its value.

**Shape:** Load a row's records only when its provenance sheet opens.

- The page read keeps a summary per field (Source count, "1 record disagrees", counts on other values, whether any records exist). Go returns those as counts from one grouped query that skips Citation / Artifact / Source joins, locator decode, and date and name lookups.
- The gallery keeps its lead records (`leadOutcomes`).
- A new read loads one row's records, keyed by owner and Property, so it also covers life rows and event–place links. The Event and Place pages' Why accordion could call it when it expands.

**What it would take** (about the size of S13-11): the Go counts query and new RPC; proto; row models from counts; loading / failed states in the sheet (S13-D2 draws neither); refetch when a write lands while the sheet is open; `FakeStore`; rewriting Swift tests that build records by hand.

**Before pulling it in:** Measure the current read on a heavily researched person at the map's **Scale**. Do it only if that number shows the page load is too slow. Settle the life-row owners first: S13-11 moved birth and death place rows to their event–place links.

Related: the S13-06 ship log (in git with #640), PRF-1 and PRF-2; the S13-11 ship log (in git with #650).
