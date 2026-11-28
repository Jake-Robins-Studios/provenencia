# Place types and households

**Status:** idea, not scheduled (2026-11-28; decisions 2026-11-28). From a discussion of how to enter residences: one residence event per person, sharing a Place, instead of one residence event shared by a household.

## Why

A residence event shared by several people gives them all one span. People in a household rarely arrive and leave on the same days, so the shared event can't hold what later records say about one member. It also breaks at Promote: a later record that dates one member's residence differently can't join the shared Conclusion event without a date conflict.

The entry convention that fixes this needs no code: **one residence event per person**, each with its own `start_date` / `end_date` / `as_of`, and each linked by its own Location to the **same Place**. This is the shape [`evidence-graph-structure-shortcuts.md`](evidence-graph-structure-shortcuts.md) already describes for the six grandsons "of Town Y".

What it loses is the fact that people lived *together*. Separate events say only that each person lived at that place. Sharing a place isn't living together: all six grandsons link to Town Y. The app can't tell a town from a house, because a Place has only `toponym`, its period and pictures ([`conclusion-layer-data-model.md`](../conclusion-layer-data-model.md) §8: "The schema does not know a township from a comma-separated blob").

## Wanted

A seeded term Property **`place_type`** on `place`, with terms such as `country`, `state`, `province`, `region`, `county`, `township`, `city`, `town`, `village`, `parish` and `dwelling`. Views read it as the signal: **residences that share a household-type Place and overlap in time are people who lived together**, and the timeline, Person page, event page and Place page can group them.

The property is worth having for more than households: roll-ups ("events in Upper Canada"), maps, search filters, the gazetteer ([`place-gazetteer-service.md`](place-gazetteer-service.md)) and place matching all need to know a place's size.

## Decided (user, 2026-11-28)

1. **Key name: `place_type`**, matching `event_type`, `relationship_type` and `place_relationship_type`. A bare `type` reads like the Subject type (person, event, place).
2. **The household term is `dwelling`.** Not `residence`, which is already an `event_type` term. `dwelling` is census vocabulary ("dwelling house") and names a building, not an activity.
3. **The rule is registry data, not code.** No `if place_type == dwelling`. A term carries a flag, like `Directed`, `Inverse` and `Neutral` on `seedTerm` (`core/database/subjectvocab/registry.go`), meaning "residences that overlap here are a household". Each existing flag is a column on `property_terms` added by its own migration (`000044`, `000046`, `000047`), so this one is too, via [`add-catalog-migration`](../../.agents/skills/add-catalog-migration/SKILL.md). A researcher's own term (an apartment, a cabin) can then opt in without a code change. The Properties page needs a way to set the flag on one.
4. **Institutions are descoped.** Boarding houses, workhouses, asylums, prisons, barracks, schools and hospitals get no seeded term and no household rule for now. They're places where people live together without being a household, so a later slice might give them their own label ("residents of"). That would make the flag a small vocabulary (`household`, `institution`, none) rather than a boolean.
5. **A farm is a dwelling.** Enter a farm as a `dwelling`; there is no separate `farm` or `homestead` term.
6. **Dates must overlap.** Any view that says people lived together requires overlapping residence spans at the dwelling. Same dwelling forty years apart means successive occupants. Use the as-of-as-bounds comparison from S16 ([`event-as-of.md`](../deployment-plan/spike-16/event-as-of.md)): as of x is start ≤ x ≤ end, and two as-ofs never conflict.
7. **The grouping reads the Conclusion value.** Group when a Place's reconciled `place_type` (`single`, `merged`, or `concluded` by the researcher; [`conclusion-reconciliation.md`](../conclusion-reconciliation.md)) carries the household flag. When it's `mixed` and the researcher hasn't concluded it, don't group. This is the "later Property (nature, grain, …)" that `conclusion-reconciliation.md` §place chains anticipated.
8. **Matching gets a knob.** A `place_type` conflict scores against a merge: `subject.Weights.place.place_type`, through [`add-match-rule`](../../.agents/skills/add-match-rule/SKILL.md) and the [`matching-model.md`](../matching-model.md) knob inventory.
9. **A change of type is a new Place.** When a township becomes a city, enter a new Place and link the two with `succeeded_by`. A Place has one type for its whole period, so a `mixed` type means records disagree, never that the place changed.
10. **No backfill.** Install seeds `place_type` only into catalogs created after it ships ([`add-seeded-vocabulary`](../../.agents/skills/add-seeded-vocabulary/SKILL.md)). The dogfood catalog gets it from a one-off script written with the implementation, not a shipped backfill.
11. **"Lived together" is one derived fact, held in the graph cache.** It's computed once and every view reads it: the timeline, the Person, event and Place pages. No view groups residences itself. It is a fact nobody entered, like the spouses and parents `core/kinship` derives from marriages and births and shows as implied. It's a registered entry in the graph cache ([`catalog-caches.md`](../catalog-caches.md)), beside `canonlinks.kinship`: keyed by the dwelling's place handle, updated by the commit's roots (a residence, Location or Place changes) and `DerivedFrom` the vocabulary (the household flag lives on a term). The PR adds its row to `catalog-caches.md` and its fill to `BenchmarkCacheSizes`, as `TestCacheDocListsEveryEntry` requires. It hinges on a Place, which `Pattern.PivotKind` (`core/kinship/patterns.go`) doesn't support today (it returns only an event or a person), and it isn't a family relationship, so it's probably a sibling reader rather than a kinship pattern. [`kinship-view.md`](kinship-view.md) lists "census households" under other patterns; decide the two together.
12. **Wording says what the evidence says.** "Also at this dwelling, 1880–1885: Mary", not "Lived with Mary". Copy goes through [`add-localized-string`](../../.agents/skills/add-localized-string/SKILL.md).
13. **`place_type` is a locked binding on `place`,** so the Properties page can't unbind it while the household rule reads it, as `event_type` is locked on `event` ([`seeded-vocabulary.md`](../seeded-vocabulary.md) §3.3). Add a §3.x terms table.
14. **The type is optional.** A Place with no `place_type` stays valid everywhere, as today. It just never takes part in household grouping. Residences group only once their place is typed `dwelling` (or another term with the household flag). The pattern shortcuts in [`evidence-graph-structure-shortcuts.md`](evidence-graph-structure-shortcuts.md) (a residence cluster placed in one action) could set `dwelling` for the researcher.

## Still open

1. **Open-ended and undated residences.** Whether a residence with no dates, or only one end, joins a group, or is shown as uncertain.
2. **Neighbouring types in matching.** Whether town and city, or village and parish, count as a conflict or compare as unknown. An untyped place compares as unknown against any type.
3. **The full seeded term list.** Which of `country`, `state`, `province`, `region`, `county`, `township`, `city`, `town`, `village`, `parish` and `dwelling` ship.

## Alternatives considered

- **Dates on the participation connection.** One shared residence event, with each person's participation carrying its own `start_date` / `end_date`. There's precedent: `place_relationship` already has dates. Set aside because it gives two answers to "when". Timeline placement, Conclusion ordering, `subject.Weights.event.date`, the as-of bounds and lifespan would each need a rule for which date wins. Records also rarely give different spans for members of one household, since different spans usually come from different records. Revisit if real evidence keeps doing it (a household register with each member's arrival and departure), probably on a dated household event.
- **A shared household or census event beside the residences.** It works today with no code. When a record attests that people lived together, enter that as one event with them all as participants, and keep each person's residence for their own span. It sits alongside `place_type` rather than replacing it: it records what a record said, whereas `place_type` lets the app infer it.
- **Group at the exact Place with no type.** Display code only, labelled "also at this place". Honest at any size, but useless at a town.
- **Treat a Place with nothing `part_of` it as fine-grained.** Weak: a town stops counting the moment one street is entered under it.

## First slice

The `place_type` property, its terms, the household flag (with its migration), the binding and the matching knob, with no grouping. Grouping and the derived co-residence fact come after, once real places have been typed.
