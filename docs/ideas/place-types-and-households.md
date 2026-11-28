# Place types and households

**Status:** idea, not scheduled (2026-11-28). From a discussion of how to enter residences: one residence event per person, sharing a Place, instead of one residence event shared by a household.

## Why

A residence event shared by several people gives them all one span. People in a household rarely arrive and leave on the same days, so the shared event can't hold what later records say about one member. It also breaks at Promote: a later record that dates one member's residence differently can't join the shared Conclusion event without a date conflict.

The entry convention that fixes this needs no code: **one residence event per person**, each with its own `start_date` / `end_date` / `as_of`, and each linked by its own Location to the **same Place**. This is the shape [`evidence-graph-structure-shortcuts.md`](evidence-graph-structure-shortcuts.md) already describes for the six grandsons "of Town Y".

What it loses is the fact that people lived *together*. Separate events say only that each person lived at that place. Sharing a place isn't living together: all six grandsons link to Town Y. The app can't tell a town from a house, because a Place has only `toponym`, its period and pictures ([`conclusion-layer-data-model.md`](../conclusion-layer-data-model.md) §8: "The schema does not know a township from a comma-separated blob").

## Wanted

A seeded term Property **`place_type`** on `place`, with terms such as `country`, `state`, `province`, `region`, `county`, `township`, `city`, `town`, `village`, `parish`, `farm` and `dwelling`. Views read it as the signal: **residences that share a household-type Place and overlap in time are people who lived together**, and the timeline, Person page, event page and Place page can group them.

The property is worth having for more than households: roll-ups ("events in Upper Canada"), maps, search filters, the gazetteer ([`place-gazetteer-service.md`](place-gazetteer-service.md)) and place matching all need to know a place's size.

## Things to decide

1. **Key name.** `place_type`, matching `event_type`, `relationship_type` and `place_relationship_type`. A bare `type` reads like the Subject type (person, event, place).
2. **The household term's name.** Not `residence`, which is already an `event_type` term. The registry allows one key under two properties (`child` is both a role and a relationship type), but "a Residence at a Residence" reads badly. `dwelling` is census vocabulary ("dwelling house") and names a building, not an activity. Alternatives: `habitation`, `abode`, `household`.
3. **The rule belongs on the term, not in the code.** No `if place_type == dwelling`. Give a term a flag, like `Directed`, `Inverse` and `Neutral` on `seedTerm` (`core/database/subjectvocab/registry.go`), meaning "residences that overlap here are a household". Each existing flag is a column on `property_terms` added by its own migration (`000044`, `000046`, `000047`), so this one is one too, via [`add-catalog-migration`](../../.agents/skills/add-catalog-migration/SKILL.md). Then:
   - a researcher's own terms (an apartment, a cabin) can opt in without a code change;
   - the Properties page needs a way to set the flag on a researcher's own term.
4. **Places where people live together but aren't a household.** A boarding house, workhouse, asylum, prison, barracks, school or hospital. Co-residents there aren't a family. Leave them out of the flag. Perhaps group them under a different label ("residents of") instead, which might mean the flag is a small vocabulary (`household`, `institution`, none) rather than a boolean.
5. **Farms and homesteads.** A farm with tenant cottages holds several households. Leave `farm` and `homestead` out of the household rule by default.
6. **Dates must overlap.** Same dwelling and overlapping residence spans means living together. Same dwelling forty years apart means successive occupants. Use the as-of-as-bounds comparison from S16 ([`event-as-of.md`](../deployment-plan/spike-16/event-as-of.md)): as of x is start ≤ x ≤ end, and two as-ofs never conflict. Decide what an open-ended or undated residence does. Probably it isn't grouped, or is grouped and shown as uncertain.
7. **Which layer the grouping reads.** On a Source graph, the place type is what that record says. On the Conclusion side a Place can be `mixed` (one record says town, another dwelling). Group only when the Conclusion value carries the household flag, and not when it's mixed.
8. **Matching.** Places at different levels shouldn't merge, so a `place_type` conflict is probably a knob: `subject.Weights.place.place_type`, through [`add-match-rule`](../../.agents/skills/add-match-rule/SKILL.md) and the [`matching-model.md`](../matching-model.md) knob inventory. Decide whether neighbouring levels (town and city, village and parish) count as a conflict or are compared as unknown.
9. **Place types over time.** A village becomes a town and a township becomes a city. A single value with `mixed` handles a record that disagrees, but a real change of status is probably a `succeeded_by` place relationship, not a second type. Say which in the copy.
10. **Show it as implied, like kinship.** "Lived together" is a fact nobody entered, like the spouses and parents `core/kinship` derives from marriages and births. Model it once as a derived fact that every view reads, not as grouping in each view. A co-residence pattern would pivot on a Place. That's new: `Pattern.PivotKind` (`core/kinship/patterns.go`) returns only an event or a person today. It's also not a kinship term, so it might be a sibling reader rather than a kinship pattern. [`kinship-view.md`](kinship-view.md) already lists "census households" under other patterns, and the two should be decided together.
11. **Labels.** The derived fact supports "also at this dwelling, 1880–1885", not "lived with" stated as a conclusion. Copy goes through [`add-localized-string`](../../.agents/skills/add-localized-string/SKILL.md).
12. **Binding.** Bind `place_type` on `place`, probably locked, since the screens and the rule key into it ([`seeded-vocabulary.md`](../seeded-vocabulary.md) §3.3). Add a §3.x terms table for it.
13. **Existing catalogs.** Install seeds only at catalog create ([`add-seeded-vocabulary`](../../.agents/skills/add-seeded-vocabulary/SKILL.md)). Existing projects need a backfill of the property, its terms, the flag and the binding. Existing places stay untyped, so the grouping simply doesn't apply until the researcher types them.
14. **Entry.** The type is one more field on every place card. The pattern shortcuts in [`evidence-graph-structure-shortcuts.md`](evidence-graph-structure-shortcuts.md) (a residence cluster placed in one action) could set it.

## Alternatives considered

- **Dates on the participation connection.** One shared residence event, with each person's participation carrying its own `start_date` / `end_date`. There's precedent: `place_relationship` already has dates. Set aside because it gives two answers to "when". Timeline placement, Conclusion ordering, `subject.Weights.event.date`, the as-of bounds and lifespan would each need a rule for which date wins. Records also rarely give different spans for members of one household, since different spans usually come from different records. Revisit if real evidence keeps doing it (a household register with each member's arrival and departure), probably on a dated household event.
- **A shared household or census event beside the residences.** It works today with no code. When a record attests that people lived together, enter that as one event with them all as participants, and keep each person's residence for their own span. It sits alongside `place_type` rather than replacing it: it records what a record said, whereas `place_type` lets the app infer it.
- **Group at the exact Place with no type.** Display code only, labelled "also at this place". Honest at any size, but useless at a town.
- **Treat a Place with nothing `part_of` it as fine-grained.** Weak: a town stops counting the moment one street is entered under it.

## First slice

The `place_type` property, its terms, the flag (with its migration), the binding and the backfill, with no grouping. Grouping and the derived co-residence fact come after, once real places have been typed.
