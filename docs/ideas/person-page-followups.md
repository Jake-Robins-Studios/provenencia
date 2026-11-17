# Person page follow-ups

**Status:** idea only — not roadmapped. Low-priority Person page items from the [2026-11-08 audit](../deployment-plan/spike-16/person-page-audit.md), parked by the user the same day. P-18 and P-19 went to Spike 16 Batch 6 (S16-47, S16-46; 2026-11-17). Pull one in when the code it names next changes, or as a batch of an odds-and-ends spike.

## The Conclusion lists hide a refresh failure too (map review K-2)

`ConclusionListPresentation` (`ConclusionListPage.swift` 5–24), behind the Persons, Events and Places lists, is built from `QueryHandle.read` and `isFetching` like the detail page was, so a failed reload behind a list keeps the old rows and says nothing, and its error `PVCallout` (158–159) has nothing to press. Spike 16's S16-04 adds a `QueryHandle` reading with the refresh failure beside the value and moves the Conclusion detail page onto it; the lists adopt the same reading and the kit's `PVRetryCallout`. It changes chrome on three list pages, so it needs a brief.

## A record links line over a pair or entity cap is silent (S16-01)

A record links line over `MaxPairWork` or `MaxEntityMembers` keeps 0 facts and nothing says so (S16-01 reports only `MaxReadWork`). **Shape:** if wanted, a flag on the pair beside `not_counted`, drawn as part of the diagram's partial note.

## Nothing caps how many Evidence graphs one person spans (S16-01)

Nothing caps how many Evidence graphs one person spans; the Person page reads are linear in it (S16-01). The real Scale is 50. **Shape:** if a crafted project needs it, one more cap beside the records-per-graph one.
