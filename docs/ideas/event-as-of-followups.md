# Event as-of follow-ups

Left over from Spike 16 Batch 5 ([event as-of dates](../deployment-plan/spike-16/event-as-of.md)), 2026-11-16. Not scheduled.

- **Backfill into an existing catalog.** `as_of` is seeded at create time only, as every seeded Property is ([`add-seeded-vocabulary`](../../.agents/skills/add-seeded-vocabulary/SKILL.md)). The user will ask for a one-off command that adds `as_of` and its event binding to the dogfood project once Batch 5 lands (user, 2026-11-16). It is not a migration and not open-time heal.
- **As-of on a Place.** "Town Y existed as of 1850" would sample a Place's period the way an event's as-of samples its span. A Place's period is separate code (`PlaceSummary`, the place entries, a chain at a date), so it waits for a real record that needs it.
- **Hide as-of on instantaneous event types.** A birth or a burial has no span, so an as-of on one is odd. It is a case of [Lock event properties to specific event types](properties-and-terms.md#lock-event-properties-to-specific-event-types) and waits for that.
- **An as-of outside the researcher's own start or end.** `start_date` 1995 with `as_of` 1990 contradicts itself. Batch 5 draws the known span and says nothing; a notice on the Event page could flag it.
