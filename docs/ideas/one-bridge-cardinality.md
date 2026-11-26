# One bridge cardinality for matching and reconciliation

**Status:** idea only — not roadmapped.

## Problem

"How many of these can one entity have through this bridge" is declared once today, for matching: `core/matchregistry/segment.go` `defaultSegment` lists `One` keys (a person has one birth and one death), and Promote scores a differing neighbor through a `One` link as a conflict. Reconciliation needs the same fact: an event has one place, so its location links vote (S16-80). S16-80 passes "single" inside the place vote with a decided comment instead of declaring it, because adding location to `One` today would be wrong for matching in two ways:

- A `One` key holds from both ends, and a place has many events.
- Matching does not know containment: an event record placed in Canada and one placed in Swift Current would score as a conflict (−3, as strong as a differing name or date), although one place contains the other.

## Idea

1. A `One` key can name the end it holds from (`End` set), so location holds from the event's end only.
2. Since S16-80, value compare relates two subject values by entity and by the `Within` list each carries (the places that contain it at a date, from `conclusionsummaries` `placeGraph.within`). Matching fills `Within` for a place neighbour the same way, so two places where one contains the other at the event's date line up instead of conflicting.
3. With both, location's event end joins `One`, and the place vote reads the registry instead of its constant. Any later single bridge end is one registry row that matching and reconciliation both honour.

## Open questions

- How matching reads a place's `Within` at the event's date: the layers stay pure, so the walk that builds segments supplies it.
- Whether a person's birth and death, already `One` for matching, should also vote across a person's several birth events (today the earliest dated leads).
