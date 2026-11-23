# Spike 15 — Claude Design briefs

**UI in this spike is designed in Claude Design before it is implemented.** Workflow: [`add-design-brief`](../../../../.agents/skills/add-design-brief/SKILL.md).

Briefs are written one at a time, just before the PR they gate. Design track and gating: [`../deployment-plan.md`](../deployment-plan.md#design-track). One brief, one PR: a brief gates exactly one PR and draws only what it ships (S15-D1 and S15-D14 predate the rule and stay as written).

## Scheduled

| Brief | View | Board | Gates |
| --- | --- | --- | --- |
| S15-D4 | Adding an Artifact: the copy fields | Descoped 2026-11-12: folded into S15-D14 | — |
| S15-D11 | Event page: value rows open the provenance sheet; the Why accordion removed | — | S15-31 |
| S15-D12 | Place page: value rows open the provenance sheet; the Why accordion removed | — | S15-31 |
| S15-D15 | Person page Sources section: Citations grouped under one citation | Descoped 2026-11-21 with S15-22 | — |
| S15-D17 | Provenance sheet: the record table's fold | — | S15-27 |
| S15-D18 | Provenance sheet: records loading on open, and their failure | — | S15-29 |
| S15-D19 | Source page: Copy source-list entry | — | S15-23 |
| S15-D20 | Metadata board row: a needed and a used entry on every board, no dismiss; the composer's Citation board included | — | S15-39 |
| S15-D21 | Source page Artifacts: the list entry's mark for a missing citation field | — | S15-40 |
| S15-D22 | Metadata board row: the Unknown and Supplied control, reused by S15-42; the composer's Citation board has it as a row | — | S15-41 |
| S15-D23 | Source date dialog and header: No date, Supplied, the empty-date flag | — | S15-42 |
| S15-D24 | Citation composer: Unknown, Supplied and the needed flag on the printed page | Descoped 2026-11-22 with S15-45: the page is a Citation board row (S15-D20, S15-D22) | — |
| S15-D25 | Metadata page: a field's unknown text | — | S15-46 |
| S15-D29 | Citation composer: the final shape, the Citation's metadata board beside the locator inputs and no Printed page input | — | S15-56 |
| S15-D30 | Source type page: a fourth suggestion list (Citation), Copy type's fourth tick, the format editor's completion with the Citation's fields | Descoped 2026-11-22: suggestions lose their level (S15-63) | — |
| S15-D33 | Metadata board row: an inherited value, where it comes from, override and fall back (Artifact sheet, graph form) | — | S15-64 |
| S15-D34 | Artifact sheet, graph form, composer: the citation preview | Descoped 2026-11-22 with S15-65 | — |
| S15-D35 | Metadata board row: the list-below hint and Move to Source | — | S15-66 |
| S15-D36 | Citation formats list and format page (new sidebar place); the type page's link to its format | — | S15-68 |
| S15-D37 | Source type page: the default-format picker and preview in place of the format link; Copy type's formats tick | — | S15-69 |
| S15-D38 | Citation formats: Add format dialog, Copy format, Delete and its in-use refusal | — | S15-70 |
| S15-D39 | Source page: the format picker | — | S15-71 |
| S15-D31 | Citation composer: the Printed page input goes | Descoped 2026-11-22: merged into S15-D29 | — |

## Archived

| Brief | View | Board | Built by |
| --- | --- | --- | --- |
| [S15-D32](archive/S15-D32-one-suggestion-list.md) | Source type page and Copy type sheet: one Suggested fields list in place of three; one suggestions tick | [agreed 2026-11-23](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG): the Suggested fields and Copy type frames; count on the section header, no list header | S15-63 (#955) |
| [S15-D10](archive/S15-D10-move-confirm.md) | Move to another Source: a Move button on Artifact rows and graph cards (the row's right-click menu goes), the confirm (the bundle, the target, the credibility and left-behind notes), landing on the target page | [agreed 2026-11-22](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK): page *Move*; no right-click menus, Move is a folder-input IconButton; the why line only when more than one Artifact moves | S15-25 (#940) |
| [S15-D14](archive/S15-D14-source-page-artifacts.md) | Source page Artifacts: the list with each Artifact's copy details read-only and a thumbnail of at most 80pt; the Artifact sheet in edit and add mode (replaces S15-D1 SD-9, SD-10 and S15-D4) | [agreed 2026-11-13](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK): rows, 64pt thumbnail, kit discard confirm, header-only Add field on the Source's section | S15-34 (#819), S15-35 (#824), S15-10 (#829), S15-25 (#940) |
| [S15-D1](archive/S15-D1-source-page.md) | Source page: the date, the Private switch, Page columns, an Artifact's metadata board, Move on Artifacts and graphs. Its citation preview (SD-11 – SD-13) is not built (user, 2026-11-13) | [validated 2026-11-10](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK) | S15-03 (#766), S15-09 (#802), S15-25 (#940) |
| [S15-D9](archive/S15-D9-provenance-sheet-citations.md) | Provenance sheet: formatted citations, same-citation rows without rules between them, Copy full and Copy short, the on-open loading and failed states | [agreed 2026-11-21](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ): page *Vitals*, turn 20; labelled Full and Short buttons stacked in a 72pt track; Read as 104, Outcome 128, Record 72, reserved column removed (the likeness viewer's row too) | S15-21 (#930) |
| [S15-D16](archive/S15-D16-source-type-citation-formats.md) | Source type page: the three formats under Details, Insert field, the live preview against a Source, warnings under each format; one Save for Details and formats | [agreed 2026-11-20](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG): frames "S15-D16 · D16-1a – D16-15"; each preview above its format, one Preview with picker; completion at the caret; its suggested-first ranking not taken (typed query only) | S15-17 (#924) |
| [S15-D3](archive/S15-D3-person-sources-date.md) | Person page Sources section: each Source's published date in the Date column, now captioned Published | [agreed 2026-11-20](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ): page *Sources*, turn 19; undated reads italic secondary in the section and the Sources list | S15-05 (#919) |
| [S15-D13](archive/S15-D13-copy-source-dialog.md) | Copy Source dialog: a Published date tick | [agreed 2026-11-10](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK#artboard-32c863db011e) | S15-32 (#778) |
| [S15-D2](archive/S15-D2-sources-list.md) | Sources list: the date on rows and as a sort | [agreed 2026-11-10](https://claude.ai/artifact/JDm51QdorUvY79EFoci4cm) | S15-04 (#774) |
| [S15-D5](archive/S15-D5-evidence-graph-form.md) | Evidence graph form: its metadata board (two columns at 880pt, the app's first); the graph rows show saved values read-only | [agreed 2026-11-14](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK): rows "Evidence graphs" (g-values …) and "Evidence graph form" (gf-meta-*) | S15-11 (#834) |
| [S15-D26](archive/S15-D26-add-source-type-dialog.md) | Add type dialog: label, icon, description in two columns, the icon grid inline | [agreed 2026-11-14](https://claude.ai/artifact/R94Wfp97eC9cBLaSNBQEga) | S15-47 (#843) |
| [S15-D27](archive/S15-D27-source-type-page.md) | Source type page: the page from scratch (header, details, delete, locked types, the Source suggestions), with slots named for S15-12 and S15-17; the list without its side pane; leaving with unsaved details asks; no toast after Add or Delete (user, 2026-11-15) | [agreed 2026-11-15](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG): sheet icon picker, new page header, Details beside Suggested fields at every width | S15-48 (#848) |
| [S15-D28](archive/S15-D28-source-types-list.md) | Source types list: a sortable Used by column; at Wide the Sources list's band and a Description column | [agreed 2026-11-15](https://claude.ai/artifact/R94Wfp97eC9cBLaSNBQEga): section 01 of the S2-03 Source Types Board; Description cut with a full-text tooltip | S15-49 (#852) |
| [S15-D6](archive/S15-D6-source-type-suggestion-levels.md) | Source type page: suggestions at three levels, stacked in the Suggested fields column; Return adds a picked field. Rewritten 2026-11-15 as an enhancement of S15-D27's page board | [agreed 2026-11-16](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG): frames "S15-D6 · …" on the Source type page board; micro-caps list headers, no section count, pool hint once | S15-12 (#856) |
| [S15-D8](archive/S15-D8-citation-composer-printed-page.md) | Citation composer: the printed page next to Label (image and PDF); the split on Regular and Wide | [agreed 2026-11-16](https://claude.ai/artifact/3GSFQZjqdQjL8v2rpgMiDc): section "S15-D8 · The printed page…"; Printed page beside Label when the column fits (Label ≥ 180pt + 140pt), else under it; help as a tooltip; no column widens at Wide | S15-13 (#863) |
| [S15-D7](archive/S15-D7-copy-source-type.md) | Source type page: Copy in the header and the Copy type sheet (moved from the Add type dialog, user 2026-11-17) | [agreed 2026-11-17](https://claude.ai/artifact/42ZuWus4ynyz7xUDwcF6zG): frames "S15-D7 · D7-1a – D7-10" (7 split into 7 and 7b) | S15-18 (#877) |
