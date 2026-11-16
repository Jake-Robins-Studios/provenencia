# Ship log — S15-50 Forms list their tab order

**Plan:** [`S15-50-forms-list-their-tab-order.md`](S15-50-forms-list-their-tab-order.md) · **Branch:** `s15-50-forms-list-their-tab-order` · **PR:** #862
**State:** ready

## Round 0 — implement
Head `23687c72f` (branched from local `main` @ `7ed654520`; `git fetch` failed, no network). Gate PASS (orchestrator run). Report deviations: `PropertiesCreateForm` also took `holdsField`, `holdsRadios`, `createBindRow` from `PropertiesCreateHost` (`createForm` calls them); `ArtifactSheetForm.fields`, `SourceGraphForm.fields`, `sideForm`, `panelForm` gained `@ViewBuilder` to hold `let order`. Not done for lack of network: push, draft PR, landed commit. Noted: `check-plan-docs.py` will flag the deleted `PVTabPair.swift` in § 4 once the plan is edited.

## Round 1 — review
Reviewers: CON, MNT, UX. Skipped: SEC+PRF — no security path, no `core/**`, no Feature model; the diff is view focus wiring over enums written in code, no data the app did not write.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | major | Evidence graph create dialog holds its focus state on the presenting view | Fix now → F-1 | verified: `@FocusState createFormFocus` on `EvidenceGraphContent` (`EvidenceGraphView.swift:110`); `createForm` is the content of `.pvFormDialog` (line ~194). D-4 names `EvidenceGraphContent` for this state, but D-3 ("inside the sheet when the form is a dialog, never on the view that presents it") and D-4's own Why and Rejected columns rule it out; the plan contradicts itself and the fix follows D-3, as R2-1 did for Add property and new-Subject |
| MNT-1 | MNT | major | `init(_:equals:next:previous:)` stays open to forms | Fix now → F-2 | verified: internal init with defaulted `next:`/`previous:` (`PVFieldFocus.swift:32`); only `init(_:equals:in:)` passes neighbours. Enforces D-1 ("not called from forms") without removing the init |
| MNT-2 | MNT | minor | Local `neighbours` holds claims; `around` holds neighbours | Fix now → F-2 | verified: lines 39, 62 |
| CON-1 | CON | minor | DoD landing record not done (map row, completed.md, plan Landed note) | Fix now → finish | needs the PR number; blocked on network. The Landed note records the deviations and F-1's departure from D-4's letter |

Nits (logged): `MNT-3 · PVFieldFocus.swift:87 · neighbours(of:in:) need not be @MainActor` · `MNT-4 / UX-2 / CON-2 · ArtifactSheet.swift:129, SourceGraphFormDialog.swift:122 · wrap the long PVTextArea call` (three lenses; rides along in F-3) · `MNT-5 · ArtifactSheet.swift:65-68 · move @FocusState/Field up beside model` · `MNT-6 · README.md:157,159 · D-6 sentence written twice; TextArea row could point to Input`

### Fix plan 1

**F-1 — The Evidence graph create form holds its focus inside the sheet** (from UX-1)
Files: `macos/App/Features/EvidenceGraph/EvidenceGraphView.swift`. Skill: `add-ui-component`.
Failing test first: none (a `FocusState.Binding` cannot be built outside a rendered view; plan § 8).
Do: extract `createForm` into a new `private struct EvidenceGraphCreateForm: View` (`@Bindable var model: EvidenceGraphModel`, plus anything else `createForm` reads), holding `@FocusState private var focus: Field?` and `private enum Field: Hashable { case label, description }`, with D-5's order (`model.isEditingBridge ? [.description] : [.label, .description]`). Shape it like `PropertiesCreateForm`. The `.pvFormDialog` closure becomes `EvidenceGraphCreateForm(model: model)`. Remove `createFormFocus`, `CreateFormField` and `createForm` from `EvidenceGraphContent`.
Check: builds; `rg -n "createFormFocus|CreateFormField" macos` returns nothing; scripts/check-pr.sh PASS.

**F-2 — A form's order is the only way to give a handle Tab neighbours** (from MNT-1, MNT-2)
Files: `macos/App/DesignSystem/Components/Input/PVFieldFocus.swift`, `macos/App/DesignSystem/README.md` (Field focus row).
Failing test first: none (access control; the compiler is the check).
Do: make `init(_:equals:next:previous:)` `private` (it stays the one place a handle on a binding is built, D-1). Give `init(_:equals:in:)` a default `in order: [Value] = []` so every existing `PVFieldFocus($focus, equals: x)` caller compiles unchanged through it. In the private init rename the local `neighbours` to `claims`; in the `in:` init rename `around` to `neighbours`. README Field focus row: drop "may carry a Tab `next` / `previous` neighbour" wording; say the neighbours come only from a form's order (`in:`).
Check: `rg -n "PVFieldFocus\(\\$[^)]*(next|previous):" macos` returns nothing; scripts/check-pr.sh PASS (Xcode tests, no warning).

**F-3 — Wrap the two long `PVTextArea` calls** (nit MNT-4 / UX-2 / CON-2, riding along)
Files: `macos/App/Features/Sources/ArtifactSheet.swift`, `macos/App/Features/Sources/SourceGraphFormDialog.swift`.
Do: split each description `PVTextArea(text:lineLimit:focus:)` call's arguments across lines, as the `PVInput` above it does.
Check: scripts/check-pr.sh PASS.

## Round 1 — fix
Head `3ca7ff994`. Gate PASS (orchestrator run). F-1 `89425eadb`, F-2 `ae9749d51`, F-3 `3ca7ff994`. Branch pushed (network back). Deviations: `styleTypeLabel(_:)` moved into `EvidenceGraphCreateForm` (its only caller); a doc line on the `in:` init. MNT-2 resolved in F-2 (read: `claims` / `neighbours` locals).

## Round 2 — review
Reviewers: UX (UX-1), MNT (MNT-1). Scope `23687c72f...3ca7ff994`. CON not sent back (minor only).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | — | Round-1 major | Resolved | `EvidenceGraphCreateForm` holds `focus`/`Field` inside the sheet; `rg createFormFocus\|CreateFormField` empty |
| MNT-1 | MNT | — | Round-1 major | Resolved | value-neighbour init `private`, no defaults; only caller is `init(_:equals:in:)`; README row updated |

No new findings. MNT noted (no finding): the closure memberwise init still takes raw `next`/`previous` closures; callers are tests and `PersonRecordLinksColumn.swift:93` (no neighbours).

## Finish
`origin/main` @ `7ed654520`, unchanged since the branch was cut; no merge needed.
Draft PR #862; landing record `74cc14a95` (plan Landed, map row, completed.md). `check-plan-docs.py` did not flag the deleted `PVTabPair.swift`.

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: — (F-1 followed D-3 over D-4's letter for the Evidence graph form; recorded in the plan's Landed note)
