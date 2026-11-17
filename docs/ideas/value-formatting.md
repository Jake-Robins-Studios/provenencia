# Value formatting

**Status:** idea only — not roadmapped. Split out of the retired `structural-debt.md` on 2026-11-17 (checked against the code that day). No user-visible change unless a section says so; pull one in when a feature next changes that code. Date and number text is built in more than one place, and some value formatting sits in `Features/` instead of `Platform/`.

## Two date formatters

`DateRowDisplay` and `DateValueDisplay` are two date formatters; unify them behind one style and precision. (A-37, S13-34)

## The date draft carries editor flags

`DateValueDraft` carries three editor flags (`showStartTime`, `showEndTime`, `showAdvanced`) set from the input and toggled inside the draft, so the draft is not pure formatting input; split them into the editor's own state. (A-36, S13-34)

## Integer text differs between two displays

Integer text differs between `ReconciledValueDisplay` (grouping never, locale) and `ObservationValueDisplay`; unify them behind one formatter. (S14-36 review M-5)

## Event and summary formatting live in Features

`EventSecondaryDisplay` and `ConclusionSummaryDisplay` are value formatting left in `Features/Conclusions` after S13-36 moved the event and place titles to `Platform/`, and the Timeline reads `EventsList.spokenLine` and `.location`; move them together. Spike 16's S16-42 (planned) reshapes `DateRowDisplay` and `EventSecondaryDisplay.content` first. (P-26, Person page audit)
