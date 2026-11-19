# Ship log — S16-48 A Properties search with no match shows the kit's empty state

**Plan:** [`S16-48-properties-no-match.md`](S16-48-properties-no-match.md) · **Branch:** `s16-48-properties-no-match` · **PR:** #899
**State:** ready

## Round 0 — implement
Base `origin/main` @ `d3abece94`.
Branch cut from `origin/main` @ `b0477ee68` (main moved past `d3abece94` before the cut). Head `d2c29f47b`. Gate PASS (orchestrator run). PR #899 (draft).
Report deviations: STEP-2 and STEP-3 in one commit (the app does not build with one alone); version 0.24.0 → 0.24.1 (main had moved past the planning base); tests written with the model code, not run red first; brief move also fixed its own relative links; manual checks 1–6 left for the user.

## Round 1 — review
Reviewers: CON, MNT, UX (`macos/App/**`, `Localizable.xcstrings`), SEC+PRF (`macos/App/Features/Properties/PropertiesModel.swift`, a Features model that filters catalog rows). Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | minor | `.rows` has no payload; the view filters and sorts `visibleProperties` a second time | Fix now → F-1 | verified: `PropertiesModel.swift:120` reads `visibleProperties` to pick `.rows`, `PropertiesView.swift:284` reads it again; contradicts the plan's Edges ("reads `visibleProperties` once per body"); `ConclusionListPresentation.rows([Row], …)` is the precedent |
| MNT-2 | MNT | minor | `PVEmptyState`'s `icon:title:` init and its `icon:` `EmptyView` overloads copy the `glyph:` bodies instead of forwarding | Fix now → F-2 | verified: `PVEmptyState.swift:15-42` differ only in `.symbol(icon)`; same-pass cleanup of a grid this PR changes. Supersedes D-9's "no change to … any other init" (no behavior change) |
| UX-1 | UX | minor | A wrapped verbatim title is left-aligned while the message under it is centered | To user → Fix now → F-3 (user 2026-11-19) | verified: `PVEmptyState.swift:79-81` title has no `.multilineTextAlignment(.center)`, message at :87 has it; a 120-character query (PN-6) wraps. The one-line fix changes the kit body, which D-9 says not to touch |
| UX-2 | UX | minor | With a type selected, "No property matches" shows for a Property that exists but is not bound to that type | Follow-up | board-agreed copy (S16-D8); a type-scoped title is a copy decision for a later pass |

Nits (logged): `CON-1 · deployment-plan.md:317 · Landed #899 has no PR link, unlike S16-45/46` · `CON-2 · PropertiesModelTests T-6 checks the model flag only; real focus rests on manual check 1` · `MNT-3 · PropertiesView.swift:312-324 · padding+frame written twice, once per empty state` · `MNT-4 · PropertiesModel.swift:124 · third inline query trim after SourcesModel/CatalogSearchModel.trimmedQuery` · `UX-3 · no VoiceOver announcement when the no-match state appears; matches the rest of the app`
SEC+PRF: no findings. CON: no findings beyond nits.

### Fix plan 1

**F-1 — `.rows` carries its rows; the body filters once** (from MNT-1)
Files: `macos/App/Features/Properties/PropertiesModel.swift`, `macos/App/Features/Properties/PropertiesView.swift`, `macos/ProvenenciaTests/PropertiesModelTests.swift`. Skill: `add-swift-test`.
Failing test first: change T-1, T-3, T-4 and T-6's `.rows` expectations to `.rows(model.visibleProperties)` (or match the payload's IDs) so they fail to compile/run against the payload-less case.
Do: make `PropertiesTablePresentation.rows` → `case rows([CatalogProperty])`, following `ConclusionListPresentation.rows` in `macos/App/Features/Conclusions/ConclusionListPage.swift:12`. In `tablePresentation`, `let rows = visibleProperties` once; `if !rows.isEmpty { return .rows(rows) }`. In `propertyTable`, `case .rows(let rows): PVTable(rows: rows, …)`. Keep `Equatable` (add the conformance `CatalogProperty` needs only if it is missing). While in the switch, wrap the two empty-state arms' shared `.padding(PVSpacing.space6).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)` once (MNT-3) only if it stays a one-place change with the identifiers unchanged.
Check: `rg -n "visibleProperties" macos/App` prints only the definition and the one read in `tablePresentation`; tests pass; scripts/check-pr.sh PASS.

**F-2 — Every `PVEmptyState` icon init forwards to its glyph init** (from MNT-2)
Files: `macos/App/DesignSystem/Components/EmptyState/PVEmptyState.swift`.
Do: `init(icon:title:message:compact:action:)` becomes `self.init(glyph: .symbol(icon), title: title, message: message, compact: compact, action: action)`. The two `icon:` `EmptyView` overloads (about lines 108-128) forward to their `glyph:` overloads. That leaves one assigning body per title kind (`glyph:title:` and `glyph:verbatimTitle:`). No behavior change. This supersedes D-9's "no change to … any other init"; add a line saying so to the plan's Landed note.
Check: `grep -nE "self\.(glyph|title|message|compact|action) =" macos/App/DesignSystem/Components/EmptyState/PVEmptyState.swift` prints exactly two blocks (the `glyph:title:` and `glyph:verbatimTitle:` inits); `grep -n "symbol(icon)" …` shows only forwarding calls; scripts/check-pr.sh PASS.

**F-3 — A wrapped empty-state title is centered like its message** (from UX-1; user approved 2026-11-19)
Files: `macos/App/DesignSystem/Components/EmptyState/PVEmptyState.swift`.
Do: add `.multilineTextAlignment(.center)` to the title `Text` in `body`, beside its `.font` and `.foregroundStyle`. Record in the plan's Landed note that the user approved this body change over D-9's "No change to the body" (UX-1).
Check: the title modifier chain holds `.multilineTextAlignment(.center)`; scripts/check-pr.sh PASS. Manual check 4 confirms visually.

## Round 1 — fix
Head `88b020ff8`. Gate PASS (orchestrator run; `origin/main` unchanged at `b0477ee68`). F-1 done (`cc84f718f`); F-2 and F-3 done (`88b020ff8`). The optional MNT-3 fold was skipped (not a clean one-place change), so it stays a logged nit. F-1's tests were changed first but not run red: against the enum with no payload they fail to compile by construction.
Resolved by orchestrator read of `d2c29f47b..88b020ff8`: MNT-1 **Resolved** (`tablePresentation` binds `visibleProperties` once, `.rows(let rows)` feeds `PVTable`); MNT-2 **Resolved** (only the `glyph:title:` and `glyph:verbatimTitle:` inits assign; every `icon:` form forwards); UX-1 **Resolved** (title carries `.multilineTextAlignment(.center)`; plan Landed note records the user's approval over D-9).

## Round 2 — review
Not run: round 1 had no Fix-now blocker or major.

## Result
Gate PASS · CI pending · open: none · follow-ups: UX-2 · to user: UX-1 (answered: fix on this PR)
