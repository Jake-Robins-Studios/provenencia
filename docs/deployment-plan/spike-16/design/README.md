# Spike 16 — Claude Design briefs

**UI in this spike is designed in Claude Design before it is implemented.** Workflow: [`add-design-brief`](../../../../.agents/skills/add-design-brief/SKILL.md).

Briefs are written one at a time, just before the PR they gate. Design track and gating: [`../deployment-plan.md`](../deployment-plan.md#design-track). A brief covers one view.

## Scheduled

| Brief | View | Board | Gates |
| --- | --- | --- | --- |
| [S16-D11](S16-D11-web-kit-popup-list.md) | The web kit: a PopupList component (card, row, line, searching line), the ComboBox's open list composed from it, the Omnibar Hit Row as the SearchHitRow component | [agreed 2026-11-21](https://claude.ai/artifact/7AZ8cscWF3f5Wz7gQ39cMe), PopupList, ComboBox, SearchHitRow | — (kit only; S16-D9's board instances it) |
| [S16-D15](S16-D15-add-source-fields.md) | Add Source sheet: the shared Source fields (Title, Type, Published date, Description, Private) | — (brief written 2026-11-28, board not drawn) | **S16-73** |
| S16-D16 | Copy Source sheet: the shared Source fields filled from the original, above the credibility tick and the Artifact checklist | — | **S16-74** |
| S16-D17 | Copy Source sheet: the original's metadata as an editable board, and a type change | — | **S16-75** |

## Archived

| Brief | View | Board | Built by |
| --- | --- | --- | --- |
| [S16-D18](archive/S16-D18-family-groups-and-marriages.md) | Person page Family: the siblings grouped by their parents, each group its parents then its children, and each couple's marriage date and place | [agreed 2026-11-27](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), page "Person Detail - Family", turn "S16-D18 · Sibling groups and marriages": Shared parent(s); "m." between a group's parents and over a partner's group; tiles keep 92 pt | S16-81 |
| [S16-D14](archive/S16-D14-sources-table.md) | The Sources list as a native table: named, sortable columns, one Source open at a time, one status badge a Source | [agreed 2026-11-24](https://claude.ai/artifact/JDm51QdorUvY79EFoci4cm), page "S2-04 Sources list": TB-7 (a), TB-W1 (a), one badge width, fixed column widths | S16-71 |
| [S16-D12](archive/S16-D12-sources-list-outline.md) | The Sources list as a native outline: Source rows with Evidence graph rows under them | [agreed 2026-11-24](https://claude.ai/artifact/JDm51QdorUvY79EFoci4cm), page "S2-04 Sources list": one-line 34 pt graph rows, a rule under each Source's group, SO-W1 (b) | S16-66 |
| [S16-D13](archive/S16-D13-conclusion-lists-native.md) | The Persons, Events and Places lists on the native list: a header band across the pane, the list filling it, click selects and double-click opens, loading, empty and failure states | [agreed 2026-11-23](https://claude.ai/artifact/MQtjRymfDNraEx9roK69q4), page "Persons List": plain selection, `borderSubtle` separators, no hover, no ring, no chevron, CL-W1 (a) | S16-67 |
| [S16-D10](archive/S16-D10-toast-stack.md) | Toast stack: several toasts stacked top-trailing in the workspace window's content pane, a refreshed card, a burst clipped at the bottom, the composer's toast moved into it; a ToastStack kit component | [agreed 2026-11-22](https://claude.ai/artifact/7AZ8cscWF3f5Wz7gQ39cMe), component PVToastStack; [app layout](https://claude.ai/artifact/1UzGb9TQCd7ZQrmuAN5AY8), "Workspace Chrome" section "Toast stack" | S16-58 |
| [S16-D9](archive/S16-D9-omnibar-results.md) | Omnibar results on the kit popup list: its own window, the combo box's card, the loading, empty and error lines | [agreed 2026-11-21](https://claude.ai/artifact/1UzGb9TQCd7ZQrmuAN5AY8), page \"S3-01 Omnibar Results\" | S16-52 |
| [S16-D8](archive/S16-D8-properties-no-match.md) | Properties: a search's no-match state as the kit's empty state, with Clear search; a selected type with no Properties | [agreed 2026-11-19](https://claude.ai/artifact/XRS4WQDZbaDa7jAzVKYQdc), section "S16-D8 · No match" | S16-48 |
| [S16-D6](archive/S16-D6-event-date-row.md) | Event page: the Date row for an event dated by as-ofs: each kept as-of earliest first with its Sources, the start and end beside them | [agreed 2026-11-17](https://claude.ai/artifact/5ciAxv86fYtrUvuCHPuuJ5), turn "S16-D6 · As-of dates": `from` / `as of` / `until` in secondary ink, `Show 50 more` | S16-44 |
| [S16-D4](archive/S16-D4-event-date-line.md) | Events list: the shared event date line on a row, every dating case (occurrence, span, as-of only, as-of with a start or an end) | [agreed 2026-11-17](https://claude.ai/artifact/HP8p5mK3BFhNzFRrP5UK9w): "as of …", "from …, as of …", "as of …, until …" | S16-42 |
| [S16-D7](archive/S16-D7-timeline-lifeline-dating.md) | Person page Timeline: the lifeline draws every event's dating, with a one-day open mark | [agreed 2026-11-17](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ), turn 18: a 32 pt bar for an open day | S16-42 |
| [S16-D2](archive/S16-D2-person-page-folds.md) | Person page folds (Family, Timeline, Sources): a page per Show more, focus on what it reveals, a folded record's highlight | [agreed 2026-11-09](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ) | S16-07 |
| [S16-D1](archive/S16-D1-person-page-notices.md) | Person page: notices for a failed reload (header band, a full-width section, the Sources diagram column) and for a record links diagram that is partial | [agreed 2026-11-10](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ) | S16-04 |
