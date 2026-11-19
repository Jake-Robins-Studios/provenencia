# Ship log — S16-46 Back returns to the row you opened in a section

**Plan:** [`S16-46-section-anchor.md`](S16-46-section-anchor.md) · **Branch:** `s16-46-section-anchor` · **PR:** #890
**State:** ready

## Round 0 — implement
Head `4b586b588`. Base `f984cb0f6`. Report deviations: `PersonRecordLinksColumn` takes `anchorFocus`/`anchorScrollID` and applies the `.recordLinks` restore itself (D-11 put it outside; the diagram host's closure must return exactly that type); `ConclusionDetailRowsSection.anchorTarget(rows:anchor:)` is `static`; `PlaceRelationshipRow` falls back to plain `go(to:)` when no anchor can be built; commits grouped by behavior (two section commits). Manual check not run (no GUI).
Gate (orchestrator, head `4b586b588`): PASS.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none. UX: diff touches `macos/App/**`. SEC+PRF: `WorkspaceNavigation` and `NavigationHistoryStore` are `macos/App/Features/**` models, and `sectionAnchor` decodes from the navigation history file on disk.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | blocker | Restore resolves against the stale value a section draws while it reloads on Back; a deleted row is scrolled to and focused (AC-1.3) | Fix now → F-1 | verifier Confirmed: delete → `applyHiddenPolicy` `.markStale` keeps Anna's Family value; Back → `beginLoading(keepingValue:)`; host draws stale `.content`; `restore()` resolves the gone tile and sets `didRestore`; `QueryHandle.isSettled` is the missing gate |
| UX-1 | UX | major | Back to a field row's open arrow focuses a `PVIconButton`, which draws no focus ring | To user → Fix now → F-5 (user, 2026-11-19: fix in the kit) | verifier Confirmed: `PVIconButtonBody` never reads `isFocused` nor calls `pvFocusRing` (`PVIconButton.swift:73-128`); README:544 rule. Fix is a kit change visible on every focused icon button, against the plan's "nothing looks different" |
| MNT-1 (+UX-3) | MNT | major | Eight openers each guard the failable anchor init and pick their own failure policy (seven drop the click, `PlaceRelationshipRow` navigates) | To user → Fix now → F-6 (user, 2026-11-19: "a convenience feature… just fall back to loading the page normally. I don't want to over-engineer this.") | confirmed by reading the eight sites; the fix changes D-8's `open` shape `(WorkspaceLocation, ConclusionSectionAnchor) -> Void` |
| MNT-2 | MNT | major | Timeline fold Show more ids copied as literals beside `Slot.id` | Fix now → F-2 | confirmed: `"more.dated"`/`"more.undated"` at `PersonTimelineContent.swift:127` and `:188-189` |
| CON-2 + UX-2 | CON, UX | minor | Record-links restore uses `isReady: true` though nodes exist only once `width > 0` | To user → Fix now → F-7 (user, 2026-11-19: use `width > 0`, superseding D-11's `true`) | confirmed: `if width > 0 { CircularLinkDiagram … }` (`PersonRecordLinksColumn.swift:56`) vs `isReady: true` (`:79`); D-11 states `isReady: true` |
| MNT-3 | MNT | minor | `PersonRecordLinksColumn` takes the same focus binding twice (`focus` closure and `anchorFocus`) | Fix now → F-3 | confirmed `PersonSourcesSection.swift:230-232`; implementer's own deviation from D-11 |
| MNT-4 | MNT | minor | Skill and patterns doc say each section's content answers `anchorTarget(for:)`; three sites resolve inline | Fix now → F-4 | confirmed: gallery, relationship row, record-links column resolve in inline closures |
| SEC/PRF | SEC+PRF | — | none | — | Clean |

Nits (logged): `MNT-5 · PersonSourcesSection.swift:236 · stray blank line` (= `CON-3`) · `MNT-6 · ConclusionGallerySection.swift:56-58 · restore predicate repeats focusKeeper isShown` · `UX-4 · PlaceRelationshipRow.swift:42 · PVFocusRingButtonStyle drops .plain's pressed dimming; note in manual check` · `CON-4 · PersonFamilySection.swift:122 · .id indentation`

### Fix plan 1
Supersedes, with the user's answers (2026-11-19): D-8's non-optional anchor in `open` (F-6); D-11's `isReady: true` (F-7); the plan's "nothing looks different" for focused icon buttons (F-5). Note each in the plan's Landed note.

**F-1 — Restore waits for a settled read** (from CON-1)
Files: `macos/App/Features/Conclusions/ConclusionAnchorRestore.swift`, `ConclusionPageSectionHost.swift`, `ConclusionDetailPage.swift` (`ConclusionDetailLoaded`).
Do: add one environment value (e.g. `conclusionReadSettled: Bool`, default `true`), defined beside the restore modifier. `ConclusionPageSectionHost.loaded(_:)` sets it from `handle.isSettled` (`QueryHandle.swift:93`) on the content it draws; `ConclusionDetailLoaded` sets it from its handle's `isSettled` on the default sections (field rows, gallery, relationship rows). Where both apply, the inner one wins, which is the section's own read. The modifier reads it and treats the site as ready only when `isReady && settled`; observe the combined value in its `onChange` so a refetch that settles later runs the restore then. No call site changes. A stale value is never resolved against, so a row deleted elsewhere resolves to nil on the fresh read and the page stays at its top (AC-1.3).
Test: if the modifier's readiness can be pulled out as a pure function, a Swift test that "ready but not settled" does not restore; otherwise the manual check below.
Check: scripts/check-pr.sh PASS. Add to the PR's manual check: Anna → Family → open a child → Unpromote that child → Back: Family at its top, no tile focused.

**F-2 — One source for the Timeline's Show more ids** (from MNT-2)
Files: `macos/App/Features/Conclusions/PersonTimelineContent.swift`.
Do: add `static func moreID(_ fold: Fold) -> String`, as `PersonFamilyContent.moreID(_:)` does; use it in `Slot.id`'s `.more` case and in `anchorTarget(for:)`. Point T-7's expected fold ids at `moreID`.
Check: `rg -n '"more\.(dated|undated)"' macos/App` prints only the `moreID` body; T-7 passes.

**F-3 — One focus binding for the record-links column** (from MNT-3)
Files: `PersonRecordLinksColumn.swift`, `PersonSourcesSection.swift`.
Do: keep one `focus: FocusState<PersonSourcesFocus?>.Binding` parameter; build `PVFieldFocus(focus, equals: .node(graphID:))` inside the column for `CircularLinkDiagram`; drop the closure parameter.
Check: builds; scripts/check-pr.sh PASS.

**F-4 — Guidance names both resolve shapes** (from MNT-4)
Files: `.agents/skills/add-workspace-location/SKILL.md`, `docs/macos-client-patterns.md`.
Do: say a section resolves through its content's `anchorTarget(for:)` when it has a content type, else through a lookup over what it draws (gallery, related places, record links). Mention that the restore waits for a settled read (F-1) and that a failed anchor build still navigates (F-6).
Check: scripts/check-pr.sh PASS (guidance-names, plan-docs).

**F-5 — Icon buttons draw their focus ring** (from UX-1; user)
Files: `macos/App/DesignSystem/Components/IconButton/PVIconButton.swift`. Skill: `add-ui-component`.
Do: in `PVIconButtonBody`, read `@Environment(\.isFocused)` and apply `.pvFocusRing(isFocused, cornerRadius: PVRadius.sm)` to the drawn shape without branching, as `PVButton.swift:307` and `PVInkLink.swift:60` do. Update the kit README's focus line if it lists the controls that draw a ring.
Check: builds; manual check step 4 (Vitals → Birth arrow → Back) shows the ring on the arrow.

**F-6 — A failed anchor still opens the place** (from MNT-1, UX-3; user)
Files: `WorkspaceNavigation.swift` (`go(to:from:)`), `PersonFamilySection.swift`, `PersonTimelineSection.swift`, `PersonSourcesSection.swift`, `ReconciledValueRow.swift`, `ConclusionGallerySection.swift`, `PlaceRelationshipRow.swift`, and the `open` closures they pass down.
Do: keep it plain. `go(to:from:)` takes `ConclusionSectionAnchor?`: stamp only when non-nil, always navigate. `open` becomes `(WorkspaceLocation, ConclusionSectionAnchor?) -> Void`. Each site passes `ConclusionSectionAnchor(part:…, id:…)` straight in, with no `if let`/`guard` on the anchor; `PlaceRelationshipRow.open()` loses its fallback branch. Add no new type or helper.
Check: `rg -n "let anchor = ConclusionSectionAnchor" macos/App` prints nothing; T-1 passes (add a case: `go(to:from: nil)` navigates and stamps nothing); scripts/check-pr.sh PASS.

**F-7 — Record-links restore waits for the diagram** (from CON-2, UX-2; user)
Files: `PersonRecordLinksColumn.swift`.
Do: `isReady: width > 0`, as `PersonFamilyDiagram` does.
Check: builds.

Riding along (nits): remove the stray blank line at `PersonSourcesSection.swift:234-236` (MNT-5/CON-3); align the `.id(...)` indentation at `PersonFamilySection.swift:122` (CON-4).

## Round 1 — fix
Head `fc1d6a0fc`. Gate (orchestrator) PASS. F-1 – F-7 done. F-1 has no automated test (readiness is not a pure function; no new helper per the user); manual check added. F-6: the one remaining `let anchor = ConclusionSectionAnchor` hit is the type's own `init(from:)`. CON-4 needed no change (indent already matched). F-3/F-4/F-6/F-7 share commit `18e11ac64`.

## Round 2 — review
Reviewers: CON (CON-1 blocker), MNT (MNT-1, MNT-2 major), UX (UX-1 major). Not sent: SEC+PRF (no findings). Scope: `4b586b588...fc1d6a0fc`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | blocker | Stale-value restore | Resolved | `guard isReady, settled, !didRestore`; `conclusionReadSettled` from `handle.isSettled` at `ConclusionPageSectionHost.swift:193` and `ConclusionDetailPage.swift:362` |
| MNT-1 | MNT | major | Eight anchor guards | Resolved | `go(to:from:)` takes `ConclusionSectionAnchor?` (`WorkspaceNavigation.swift:117-122`); no opener guards the anchor |
| MNT-2 | MNT | major | Timeline Show more literals | Resolved | `PersonTimelineContent.moreID(_:)` is the only source |
| UX-1 | UX | major | Icon button focus ring | Resolved | `PVIconButton.swift:112`, `:124`; README IconButton row |
| MNT-3, MNT-4, CON-2/UX-2 | — | minor | One binding; guidance; `width > 0` | Resolved | checked by the round-2 MNT, CON and UX reviewers |

No new blockers. Nits (logged): `MNT-7 · PersonTimelineContentTests.swift:91,148,175,185,186 · older tests still spell "more.dated"` · `MNT-8 · PersonTimelineContent.swift:174,196 · participantsMoreID beside moreID(.participants)` · `MNT-9/UX-5 · ConclusionAnchorRestore.swift:14-16 · long doc-comment line`

## Finish
Merged `origin/main` @ `2faf6f728` (docs only); gate PASS.

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: UX-1, MNT-1, CON-2/UX-2 (answered 2026-11-19)
