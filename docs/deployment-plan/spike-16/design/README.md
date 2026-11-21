# Spike 16 — Claude Design briefs

**UI in this spike is designed in Claude Design before it is implemented.** Workflow: [`add-design-brief`](../../../../.agents/skills/add-design-brief/SKILL.md).

Briefs are written one at a time, just before the PR they gate. Design track and gating: [`../deployment-plan.md`](../deployment-plan.md#design-track). A brief covers one view.

## Scheduled

| Brief | View | Board | Gates |
| --- | --- | --- | --- |
| [S16-D9](S16-D9-omnibar-results.md) | Omnibar results on the kit popup list: its own window, the combo box's card, the loading, empty and error lines | [agreed 2026-11-21](https://claude.ai/artifact/1UzGb9TQCd7ZQrmuAN5AY8), page \"S3-01 Omnibar Results\" | S16-52 |
| [S16-D11](S16-D11-web-kit-popup-list.md) | The web kit: a PopupList component (card, row, line, searching line), the ComboBox's open list composed from it, the Omnibar Hit Row as the SearchHitRow component | [agreed 2026-11-21](https://claude.ai/artifact/7AZ8cscWF3f5Wz7gQ39cMe), PopupList, ComboBox, SearchHitRow | — (kit only; S16-D9's board instances it) |
| S16-D10 | Toast stack: several toasts stacked top-trailing in the workspace window, a refreshed card, a burst clipped at the bottom, the composer's toast moved into it | — (written just before S16-58) | S16-58 |

## Archived

| Brief | View | Board | Built by |
| --- | --- | --- | --- |
| [S16-D8](archive/S16-D8-properties-no-match.md) | Properties: a search's no-match state as the kit's empty state, with Clear search; a selected type with no Properties | [agreed 2026-11-19](https://claude.ai/artifact/XRS4WQDZbaDa7jAzVKYQdc), section "S16-D8 · No match" | S16-48 |
| [S16-D6](archive/S16-D6-event-date-row.md) | Event page: the Date row for an event dated by as-ofs: each kept as-of earliest first with its Sources, the start and end beside them | [agreed 2026-11-17](https://claude.ai/artifact/5ciAxv86fYtrUvuCHPuuJ5), turn "S16-D6 · As-of dates": `from` / `as of` / `until` in secondary ink, `Show 50 more` | S16-44 |
| [S16-D4](archive/S16-D4-event-date-line.md) | Events list: the shared event date line on a row, every dating case (occurrence, span, as-of only, as-of with a start or an end) | [agreed 2026-11-17](https://claude.ai/artifact/HP8p5mK3BFhNzFRrP5UK9w): "as of …", "from …, as of …", "as of …, until …" | S16-42 |
| [S16-D7](archive/S16-D7-timeline-lifeline-dating.md) | Person page Timeline: the lifeline draws every event's dating, with a one-day open mark | [agreed 2026-11-17](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), turn 18: a 32 pt bar for an open day | S16-42 |
| [S16-D2](archive/S16-D2-person-page-folds.md) | Person page folds (Family, Timeline, Sources): a page per Show more, focus on what it reveals, a folded record's highlight | [agreed 2026-11-09](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ) | S16-07 |
| [S16-D1](archive/S16-D1-person-page-notices.md) | Person page: notices for a failed reload (header band, a full-width section, the Sources diagram column) and for a record links diagram that is partial | [agreed 2026-11-10](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ) | S16-04 |
