# Ship log — S16-39 One container measures its own width and tells its content which layout fits

**Plan:** [`S16-39-own-width-breakpoints.md`](S16-39-own-width-breakpoints.md) · **Branch:** `s16-39-own-width-breakpoints` · **PR:** —
**State:** ready

## Round 0 — implement
Stopped on the base check (Implementer item 2). `main` is at `eb7ee08e9`; the plan was written against `5b64138`. §4 "Composer" is no longer true: S15-13 (`4b0165303`, `20318fded`) removed `threeUp = geo.size.width >= 1400`; `composeSplit` now reads `CitationComposerColumnLayout(widthClass)` from `\.pvWidthClass`, and its `GeometryReader` only supplies the panel's height (`evidence(layout:order:height:)`). Verified by the orchestrator: `rg -n "1400|threeUp" macos/App/Features/CitationComposer` prints nothing. D-8, STEP-5, AC-1.4, T-4 and §10 step 4 describe code that is gone.
Local state: STEP-1 committed (`8a1f07ef5`, T-1–T-4, T-8 pass); STEPs 2–4 edited, uncommitted, not built; STEP-5–8 not started; nothing pushed. Taken to the user.
Resumed 2026-11-16: user chose to drop the composer. Plan refreshed in `f6e60fc0b` (D-8 now "out", STEP-5 a no-op check, AC-1.4 and manual step 4 removed; map row and scope entry match; review log has a Refresh entry). Implementer resumes from STEP-2 on the existing branch, keeping `8a1f07ef5` and the uncommitted STEP-2–4 edits.
Head `c340f9e32` (local; `git push` fails here with "Could not resolve hostname github.com", so GitHub has `07340573f`, which differs only by the STEP-8 docs commit). Gate PASS (orchestrator, against `eb7ee08e9`). Report: STEPs 1–8 done, no stop. Deviations: the `add-ui-component` comment line opens the GOOD half of the new anti-pattern block (no earlier width example to attach it to); § 10 manual check not run (no UI session).

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. UX: the diff touches `macos/App/**` (no copy; dispatched on the path rule). SEC+PRF: list, table and per-resize redraw code under `macos/App/Features/**` and the kit (performance); no security path touched.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1, CON-2 | MNT, CON | minor | The `add-ui-component` GOOD example uses a bare `880` twice and a `?:` between two view types | Fix now → F-1 | verified: `SKILL.md:138-140`; a ternary between different `View` types does not compile in a `@ViewBuilder`; `isAtLeast` asserts membership, so two literals drift into a debug crash |
| MNT-2 | MNT | minor | `pvMeasuresWidthClass()`'s doc says the view must fill, which the container now enforces | Fix now → F-2 | verified: `PVWidthClass.swift:44-45`; stale comment in a file this PR changes |
| MNT-3, CON-3, UX (outside lens) | MNT, CON, UX | minor | § 9 rule 3 names `PVTableColumn.minTableWidth` twice | Fix now → F-3 | verified: `docs/macos-client-patterns.md:278` |
| CON-1 | CON | minor | Landed note says "No differences from the plan" though § 10 was not run | Fix now → F-4 | verified: plan line 4; ship log round 0 |
| UX | UX | — | No findings | — | — |
| SEC/PRF | SEC+PRF | — | No findings | — | — |

Nits (logged): `CON-4, MNT-6 · macos/App/DesignSystem/Components/Table/PVTable.swift:22 · rewrap the contract bullet` · `CON-5 · PVWidthBreakpoints.swift:137-138 · private let vs D-2's let; record in the Landed note` · `MNT-4 · SourcesModelTests.swift:683-717 · nine copies of SourcesListColumns(met: PVBreakpointsMet(…)); a local columns(at:_:) helper` · `MNT-5 · macos/App/DesignSystem/README.md:195 · WidthClass row omits the Timeline and the pane measure`

### Fix plan 1
All minors; the nits ride along because they sit in the same files.

**F-1 — The skill's GOOD example names its breakpoint and branches with if/else** (from MNT-1, CON-2)
Files: `.agents/skills/add-ui-component/SKILL.md`.
Do: in the GOOD half, declare `static let compactBelow: CGFloat = 880` and write `PVWidthBreakpoints([Self.compactBelow]) { met in if met.isAtLeast(Self.compactBelow) { fullRow } else { compactRow } }`, keeping the plan's comment line first. In the BAD half, change the commented body to `if width < 880 { compactRow } else { fullRow }`.
Check: `rg -n "isAtLeast\(880\)|\? fullRow|\? compactRow" .agents` prints nothing; `python3 scripts/check-guidance-names.py` passes.

**F-2 — `pvMeasuresWidthClass()`'s doc states what the container does** (from MNT-2)
Files: `macos/App/DesignSystem/Components/WidthClass/PVWidthClass.swift`.
Do: replace the first two doc lines with "Measures the width this view is given (through `PVWidthBreakpoints`, which fills it) and gives that width class to the view's content." Keep the remaining lines.
Check: `rg -n "must fill the space" macos/App` prints nothing.

**F-3 — § 9 rule 3 names the column property once** (from MNT-3, CON-3)
Files: `docs/macos-client-patterns.md`.
Do: drop the first `` (`PVTableColumn.minTableWidth`) `` on line 278; keep "(`PVTableColumn.minTableWidth`, read through `PVWidthBreakpoints`)".
Check: `rg -c "PVTableColumn.minTableWidth" docs/macos-client-patterns.md` counts one fewer than before, and line 278 holds it once.

**F-4 — The Landed note lists every difference** (from CON-1, CON-5)
Files: `docs/deployment-plan/spike-16/prs/S16-39-own-width-breakpoints.md` (line 4).
Do: replace "No differences from the plan." with the differences: the § 10 manual check was not run by the implementer (no UI session; the user runs steps 1–3 and 6 before merge, and step 2 checks the Sources list draws no compact frame before full rows); `PVBreakpointsMet`'s two fields are `private let`, not `let` (D-2); the `add-ui-component` comment line opens the GOOD half of the new anti-pattern block, there being no earlier width example to attach it to.
Check: `python3 scripts/check-plan-docs.py` on the plan reports no errors.

**Ride-along nits** (CON-4/MNT-6, MNT-4, MNT-5): rewrap `PVTable.swift`'s contract bullet to the surrounding width; add a private `columns(at:_:)` helper in `SourcesModelTests` and move the nine builds onto it (same widths and expectations); append "the Timeline's people stacking, and the pane's width class (`pvMeasuresWidthClass`)" to the README WidthClass row's list of users.
Check: `scripts/check-pr.sh` PASS.

## Round 1 — fix
Head `a63fd8400` (pushed). Gate PASS (orchestrator, against `eb7ee08e9`). F-1–F-4 and the ride-along nits done. Orchestrator read the fix commits: F-1 named constant and `if`/`else` in both halves — **Resolved**; F-2 doc reworded — **Resolved**; F-3 rule 3 names the property once — **Resolved**; F-4 Landed note lists the unrun manual check, `private let`, and the comment placement — **Resolved**.

## Round 2 — review
Not run: no reviewer had a Fix-now blocker or major in round 1.

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: — (the § 10 manual check is the user's)
