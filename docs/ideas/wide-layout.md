# Wide layout: pages waiting for a Wide frame

**Status:** idea, 2026-10-29; checked against the code 2026-11-17. A queue, not a spike. Each line becomes a brief ([`add-design-brief`](../../.agents/skills/add-design-brief/SKILL.md) "Wide layout (binding)") and a PR when its page is next touched, or as a batch in an even spike.

Every page has a Regular / Wide width class (1600pt of pane, S14-24) and the Page columns kit component (`PVPageColumns`); a page moves onto it in its own redesign (user, 2026-10-29). The rules and patterns are in [`macos-client-patterns.md` § 9](../macos-client-patterns.md#9-window-widths-regular-and-wide).

Done and gone from this list: the Source page (Page columns with the pinned header, S15-03), the Person page (S13-10, S13-28), the Sources list (fills the pane with Type and Published columns at Wide, S16-66), the Source types list and page (S15-48, S15-49), the Citation composer (S15-13), Promote (S13-23), and two-column form sheets, now the kit's `PVFormColumns` (the Artifact sheet, the Evidence graph form, the Add Source type dialog).

## Pages still drawn at their Regular layout at Wide

| Page | Wide pattern to start from | Notes |
| --- | --- | --- |
| Persons, Events and Places lists | Answered: they fill the pane | S16-67 (user, 2026-11-23): each list fills the pane at every width, with 56pt gutters at Wide; `ConclusionListPage` reads the width class for its gutter only. The detail beside the list is not planned |
| Properties, Metadata | List with a side pane | Each keeps its fixed side pane at every width; its brief decides whether the list or the pane takes the width (S14-24 D-6). Source types left this shape for a list and its own page (S15-48, S15-49); Metadata keeps it (user, 2026-11-14) |
| Event and Place pages | Page columns with a secondary column | On Page columns through `ConclusionDetailPage`, so centered at Wide, with no Wide arrangement of their own yet; it comes with their redesigns |

## Narrow panes

The window can be as narrow as 700pt (a pane of about 436pt). Pages are drawn at Regular and Wide; below the Regular frame some do not fit:

- **Person page, Sources rows.** The rows' fixed Type, Date and Ref columns plus the narrowest Citation column (`PersonSourcesColumns.minWidth`, about 640pt) do not fit a 436pt pane. `ConclusionPinnedSideColumn` already moves the diagram under the rows when the pane is narrow, but the rows themselves have no narrow arrangement. Found on the S13-D10 board (frame 15r, 2026-11-07); it waits for the next change to the Sources section (user, 2026-11-07). The rows switch at their own width with `PVWidthBreakpoints` (S16-39), as the Sources list does.
