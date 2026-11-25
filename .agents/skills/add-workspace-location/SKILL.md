---
name: add-workspace-location
description: >-
  Wires a new Provenencia macOS workspace place into first-class navigation
  history (WorkspaceLocation, WorkspaceNavigation.go(to:), Back/Forward,
  persist/restore). Use when adding or changing a sidebar destination,
  Source-style deep page, master–detail selection, workspace section,
  breadcrumb/omnibar target, or any view that should restore via history —
  WorkspaceNavigation, WorkspaceSection, NavigationHistoryStore,
  selectedSection bypass, closeSource without go(to:), or navigation-history.md.
---

# Add a workspace location (navigation history)

Every **committed place** the researcher can return to must be a
[`WorkspaceLocation`](../../../macos/App/Features/Workspace/WorkspaceLocation.swift)
pushed through
[`WorkspaceNavigation.go(to:)`](../../../macos/App/Features/Workspace/WorkspaceNavigation.swift).
`WorkspaceNavigation` is owned by `WorkspaceView` and injected with
`.environment(navigation)`. Do **not** use SwiftUI `NavigationStack` /
`NavigationPath`. Do **not** leave parallel “where we are” state that bypasses
the stack. Sidebar collapse stays on `WorkspaceModel` (chrome only).

Authoritative behavior: [`docs/deployment-plan/archive/spike-3/navigation-history.md`](../../../docs/deployment-plan/archive/spike-3/navigation-history.md).

## When this applies

| Change | History work required? |
| --- | --- |
| New sidebar section / destination host | **Yes** — section + list root |
| List → detail page (Source-style) | **Yes** — deep id on the location |
| Master–detail row select (fields pattern) | **Yes** — selection is a place |
| Omnibar / breadcrumb / cross-link → a place | **Yes** — call `go(to:)` |
| Search query, scroll, focus, dirty drafts | **No** — UI ephemera, omit, except a record page's section anchor (the row it opened another place from; Step 5) and a list's anchor row in `listScrollAnchor`: its top row on the Source types list (through `ListScrollAnchorModifier`), its selected row on the Conclusion lists and the Sources list (through `ListSelectionAnchorModifier`; the Sources list passes `reveal`, which opens the closed Source that holds a graph row through `SourcesOutline.setOpen`, closing the one open before it; `WorkspaceNavigation.listAnchor` is the selection) |
| Modal/sheet that is not a restoreable place | **No** — unless product says Back should return into it |

## Checklist

```
- [ ] WorkspaceLocation carries any new deep id (and == ignores ref/title fluff)
- [ ] New sidebar section added to WorkspaceSection if needed
- [ ] Every commit path calls navigation.go(to:) (sidebar, open, close/list-back, row select, links)
- [ ] No raw selectedSection = / openSource / closeSource / select as the sole place change
- [ ] Destination applies currentLocation on appear + onChange (after query handle ready)
- [ ] Missing deep id → navigation.fallbackToSectionRoot() after list/workspace ready
- [ ] Destination uses @Environment(WorkspaceNavigation.self); not a private parallel nav store
- [ ] WorkspaceNavigationTests cover push + restore (+ prune if new deep id)
```

## Steps

### 1. Extend `WorkspaceLocation` (if new deep kind)

Add an optional stable id field (e.g. `artifactId`, `nodeId`). Keep denormalized
`ref` / `title` for jump-menu chrome only.

Update `==` to include the new id (still **ignore** `ref` / `title`).

A graph, citationComposer or promote location carries `graphId` beside `sourceId` and is built with `WorkspaceLocation.evidenceGraph(…)`, `.citationComposer(…)` or `.promote(…)`; one without `graphId` becomes the Source page in `init`.

JSON under Application Support is v1 `Codable` — new optional keys are fine;
do not bump casually. See `NavigationHistoryStore` / `NavigationHistoryDocument`.

### 2. Sidebar section (if new destination)

Add `WorkspaceSection` case (raw value kebab-case), L10n label/icon
([`add-localized-string`](../add-localized-string/SKILL.md)), sidebar item, and
`WorkspaceContent` host.

Sidebar select **always** pushes a **section list root**:

```swift
navigation.go(to: .sectionRoot(.yourSection))
```

Never assign `navigation.selectedSection` directly.

### 3. Record navigation → `go(to:)`

| User action | Call |
| --- | --- |
| Open deep page / activate list row | `go(to: WorkspaceLocation(section:…, yourId:…, ref:…, title:…))` |
| Back to list / clear selection | `go(to: .sectionRoot(.yourSection))` |
| Master–detail select | Binding `set` → `go(to:)` with deep id (model `select` runs from **apply**) |

Feature models may still implement `open` / `select` / `close` for **applying**
UI state. Those must not be the only path that changes place when the user
commits navigation.

### 4. Apply location → UI

In the destination view (pattern: `SourcesListView`, `MetadataView`):

1. Take `@Environment(WorkspaceNavigation.self) private var navigation`.
2. On `onAppear` + `onChange(of: navigation.currentLocation)` (+ `onChange` on query
   handle status/value when list loads async):
   - Guard `location.section == .yourSection`.
   - Deep id present + found → apply selection/open (a master–detail model's `syncSelection(from:)`; a page mounts per id and reads its row's presence).
   - Deep id present + missing after handle ready → `navigation.fallbackToSectionRoot()`.
   - Deep id nil → clear to list root (no second `go(to:)`).
   - A page whose read reports its entity gone applies `.leavesForSectionRoot(when:notice:)`, with `notice:` for the toast that says why (a Conclusion page, the Evidence graph, the Source page).
   - A write that deletes the shown entity applies its effects with `session.apply(_:_:leavingPage:)`, which leaves the page before the reload, so nothing reads the deleted id. The rule is for a page that the deleted entity is the whole of (the Person page, the Source page); a master–detail page (Metadata, Properties) stays on its list, which a plain `apply` refreshes.

Catalog reads come from `WorkspaceSession` query handles (Spike 4) — see
[`add-workspace-place`](../add-workspace-place/SKILL.md). Do **not** add `.task {
load(from:) }` as the primary hydration path.

### 5. Page sections (a sub-place of a record page)

A record page can offer sections (the Person page: Vitals, Family, Timeline, Gallery, Sources). A page section is a sub-place stored on `WorkspaceLocation.pageSection` (the first the kind offers is stored as nil; the raw values of `ConclusionPageSection` are frozen because they are written to history files), changed with `withPageSection(_:)` through `navigation.go(to:)`, so Back returns to the previous section. Two properties, two jobs:

- `openPageSection` is the section the page shows: the stored one, else the first the kind offers. The place registry, the page and the fill all read it; never write `pageSection ?? …` or `offered[0]`.
- The stored `pageSection` is history identity and the crumb, where the first section adds none (`WorkspaceLocationLabels`).

A section also remembers the row it opened another place from, so Back puts the scroll and the keyboard there. `WorkspaceLocation.sectionAnchor` (a `ConclusionSectionAnchor`: a frozen `Part`, an id, and the row that holds it when the stop is inside a row) is not identity, decodes as nil from older files and unknown parts, and is cleared by `withPageSection(_:)`. It is written as the row opens: a section's rows call `navigation.go(to:from:)`, which stamps the entry being left (`stampSectionAnchor`) and pushes, so Back, the sidebar or the omnibar never write one. A section with a content type resolves through that content's `anchorTarget(for:)`, from ids its build keeps (the stop that takes the keyboard and the id to scroll to; the fold's Show more when a fold hides the row; nil when the row is gone); a section without one (the gallery, related places, record links) resolves through a lookup over what it draws. One `conclusionAnchorRestore` call per section scrolls and focuses once per mount, and waits for a settled read (`conclusionReadSettled`) so it never resolves against a value being replaced. Folds are never revealed by a restore. An opener passes the anchor as built, `ConclusionSectionAnchor(part:id:)` straight into `go(to:from:)`; a nil anchor (an id that cannot be kept) still navigates and stamps nothing. A new Conclusion section adds a `Part`, an `anchorTarget(for:)` and that call.

A kind that adopts sections adds its cases to `ConclusionPageSection.offered(by:)` and `reads(project:entityId:)`, gives its place spec the same open-section line as `.personDetail`, and supplies its own fill. See [`add-workspace-place`](../add-workspace-place/SKILL.md) for the read list.

### 6. Tests

Extend [`WorkspaceNavigationTests`](../../../macos/ProvenenciaTests/WorkspaceNavigationTests.swift)
([`add-swift-test`](../add-swift-test/SKILL.md)):

- Push the new location; Back/Forward restore the deep id.
- Missing-entity prune → section root (if applicable).

Inject a temp navigation file URL via `attachProject(uuid:fileURL:)`.

## Do not

- Bypass history with hierarchical “up” controls that only clear local state
- Push on every search keystroke or focus change
- Key history by project path (use `project.uuid` + `InstallPaths.navigationFile`)
- Put history JSON inside `.provenencia` or UserDefaults
- Fuse navigation back into `WorkspaceModel` (chrome-only: sidebar collapse)
- Disable ⌘[ / ⌘] menu items based on `canGoBack` / `canGoForward` in
  `ProvenenciaApp.commands` — Scene commands often freeze the first `.disabled`
  state; `goBack` / `goForward` already no-op at the ends

## Related

- Persist/API: `NavigationHistoryStore`, `WorkspaceNavigation.attachProject`
- Keyboard: `NavigationCoordinator` + `ProvenenciaApp` (`⌘[` / `⌘]`)
- Unsaved work: `WorkspaceLeaveGuard` on `WorkspaceNavigation.leaveGuard` — `go(to:)` / back / forward / index ask the guard; `fallbackToSectionRoot()` and `attachProject` do not. A page installs its guard with `.workspaceLeaveGuard(model)` (the citation composer, Promote and the Source type page do).
- Catalog session for destination loads: [`use-catalog-session`](../use-catalog-session/SKILL.md)
- Place registry + query cache: [`add-workspace-place`](../add-workspace-place/SKILL.md)
