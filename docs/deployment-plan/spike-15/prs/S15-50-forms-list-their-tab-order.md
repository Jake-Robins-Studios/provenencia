# S15-50 — Forms list their tab order

**Status:** Landed in [#862](https://github.com/Jake-Robins-Studios/provenencia/pull/862) (2026-11-16)
**Spike / slice:** Spike 15 · Slice 3 — Printed page (preparatory)
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: every form looks and tabs the same before and after)
**Board:** —
**Depends on:** —
**Blocks:** S15-13
**Branch:** `s15-50-forms-list-their-tab-order`
**Version bump:** none — a preparatory change with no change a researcher can see, no wire and no catalog change (precedent S15-36; [`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** —
**Context:** S15-13's review M-1 ([`S15-13-composer-printed-page.review.md`](S15-13-composer-printed-page.review.md)); the map's S15-50 scope entry; `macos/App/DesignSystem/README.md` (Input, Field focus, TextArea rows)
**Planned:** 2026-11-16 against `main` @ `5b64138`
**Review:** [`S15-50-forms-list-their-tab-order.review.md`](S15-50-forms-list-their-tab-order.review.md) — Fits with changes — Ready with changes, rounds 1 – 2 (reshaped in round 1, user 2026-11-16)

### Implementer — read this first

1. **This file is the whole task.** Read it top to bottom before you change code. Then read every file under **Current state** and load every skill under **Skills to load**.
2. **Check the base.** Compare `main` with the **Planned** commit. If a file under **Current state** has changed so a row is no longer true, stop and report which rows.
3. **Decisions are made.** Do not reopen a **Decision** or a **Scope** line, and do not swap in a design you like better. If one cannot work, stop: say which ID it is, what you found (path, line, output), and what you would need. Do not improvise around it.
4. **Do only In.** Out stays out, even when it is one line away. Do not refactor, rename, or tidy code the plan does not name.
5. **Work the Steps in order.** Run each step's check before you start the next. A failing check is fixed in that step.
6. **Hit a Stop condition → stop.** Report it. Do not work around it.
7. **Done is the Definition of done.** Report each box with its evidence: the command and its result, the test name, or the manual check you ran.
8. **Docs-only lines in the DoD are part of the PR.** Do not skip them.

---

## Landed

- `PropertiesCreateForm` also took `holdsField`, `holdsRadios` and `createBindRow` from `PropertiesCreateHost`.
- `ArtifactSheetForm.fields`, `SourceGraphForm.fields`, `sideForm` and `panelForm` gained `@ViewBuilder` to hold `let order`.
- Review UX-1: the Evidence graph create form's focus moved into a new private `EvidenceGraphCreateForm` (with `focus` / `Field`) inside the dialog, per D-3, instead of D-4's `createFormFocus` / `CreateFormField` on `EvidenceGraphContent`; `styleTypeLabel(_:)` moved with it.
- Review MNT-1: `init(_:equals:next:previous:)` is now `private` with no defaults, and `init(_:equals:in:)` defaults `order` to `[]`, so a form's order is the only way to give a handle Tab neighbours.
- Ship log: [`S15-50-forms-list-their-tab-order.ship.md`](S15-50-forms-list-their-tab-order.ship.md).

## 1. Objective

AppKit's key loop skips the text view under a `PVTextArea` when Tab leaves a `PVInput`, so a form names its fields' Tab order itself. Today the kit offers that only as `PVTabPair`: exactly two fields, wired first ↔ second, with the focus state private to the pair. S15-13 needs three fields (Label, Printed page, Transcription), with the focus held by the composer so it survives a layout switch. The user's call (2026-11-16): Tab order belongs to the form, not to a pair of fields, and the order lives on the focus handle every kit field already takes. After this PR a form holds its own `@FocusState`, writes its fields' order once, and builds each field's handle with `PVFieldFocus($focus, equals: .label, in: order)`. Every `PVTabPair` caller moves to it and `PVTabPair` is deleted.

**Why now.** S15-13 depends on it.

**What stays.** Every form's fields, layout and Tab behavior. The text area's own Tab handling (`PVTextAreaTabRouter`: Tab leaves the area, Option-Tab types a tab character) and the input's (`PVInputTabClaim`) are unchanged. Tab from the last listed field and Shift-Tab from the first are left to the key loop, as today.

## 2. User stories

**US-1.** As a researcher, Tab and Shift-Tab move between a form's text input and its text area exactly as before.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The Artifact sheet: cursor in Label, press Tab | The cursor is in Description; Shift-Tab returns to Label |
| AC-1.2 | Each other former `PVTabPair` form (Properties identity edit and create, the graph form, Add type, the composer's citation form in both layouts, the composer's new-Subject dialog, the Evidence graph create form) | Tab and Shift-Tab between its two listed fields behave as before |
| AC-1.3 | Tab in the last listed field, Shift-Tab in the first | The key loop handles the key, as today |
| AC-1.4 | The Evidence graph create form while editing a bridge (the label is hidden) | Tab and Shift-Tab in Description go to the key loop, as today |

**US-2.** As a contributor, I list any number of fields in a form's order.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `PVFieldFocus.neighbours(of: .b, in: [.a, .b, .c])` | `(next: .c, previous: .a)` |
| AC-2.2 | Of `.a` in `[.a, .b, .c]`; of `.c` | `(next: .b, previous: nil)`; `(next: nil, previous: .b)` |
| AC-2.3 | Of `.a` in `[.a]`; of `.d` in `[.a, .b]` (not listed); of `.a` in `[]` | `(nil, nil)`: the field leaves Tab to the key loop |
| AC-2.4 | `PVFieldFocus.claims(next: .c, previous: .a, claim:)` with a recording `claim` | Running `next` records `.c`; running `previous` records `.a`; a nil neighbour gives a nil claim |

## 3. Scope

| In | Covered by |
| --- | --- |
| `PVFieldFocus.init(_:equals:in:)` and `neighbours(of:in:)`; `neighbours(next:previous:claim:)` renamed `claims(next:previous:claim:)` | STEP-1, AC-2.* |
| Every `PVTabPair` caller holds its focus and lists its order; `PVTabPair` and `PVTabPairField` deleted | STEP-2, STEP-3, AC-1.* |
| The skill's checklist line and the DesignSystem README rows | STEP-4 |
| The map's S15-41 scope: its Unknown/Supplied control takes a `PVFieldFocus` | STEP-4 |

| Out | Home |
| --- | --- |
| The composer's third field (Printed page) and holding the citation form's focus in `CitationComposerView` | S15-13 |
| Wiring more fields into a form's order than today's (the read-only Key inputs in Properties create and Add type, Add type's icon grid) | not planned: those forms keep today's Tab behavior |
| `SourceTypePageView.form` (a `PVInput` and a `PVTextArea` with the icon grid between them, never wrapped in `PVTabPair`) | not planned: keeps today's Tab behavior, as Add type's icon grid does |
| Text-area editors with no `PVInput` (`SourcePageCredibilityView`, `SourcePageDescriptionView`, `SourcePageNotesView`) | not planned: the rule (D-6) does not reach them |
| Focus kept across a width change | S15-13 (`FocusKeeper` on the composer's host-held state) |
| Any change to `PVTextAreaTabRouter` or `PVInputTabClaim` | not planned |
| Editing `PVTabPair` mentions in earlier plans, review logs, briefs and the spike archives | not planned: history stays as written |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| The pair | `macos/App/DesignSystem/Components/Input/PVTabPair.swift` `PVTabPair`, `PVTabPairField` | A `View` with a private `@FocusState var field: PVTabPairField?`; `content(handle(.first), handle(.second))`; `PVTabPairField.next/previous` wire first ↔ second; a `#Preview` |
| The handle | `macos/App/DesignSystem/Components/Input/PVFieldFocus.swift` `PVFieldFocus.init(_:equals:next:previous:)`, `static func neighbours(next:previous:claim:)` | Builds a handle on any `FocusState<Value?>.Binding` with optional neighbours; `neighbours(next:previous:claim:)` turns neighbour values into `FocusClaim.claim` closures. Its only caller is `init(_:equals:next:previous:)` (and the test `tabPairOrder`) |
| Text area Tab | `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift` `PVTextAreaTabRouter` | Tab leaves the area to `focus.next`, else the key loop; Option-Tab inserts a tab. Unchanged |
| Input Tab | `macos/App/DesignSystem/Components/Input/PVInput.swift` `PVInputTabClaim` | Claims Tab for a handle with a neighbour. Unchanged |
| Callers (9 uses, 7 files) | `Features/Properties/PropertiesView.swift` 619 (`PropertiesIdentityEditor`: the label handle inside `PVInlineEdit`'s editor closure, the description's on the `PVTextArea` beside it) and 823 (`PropertiesCreateHost.createForm`, the content of the host's `.pvFormDialog`: Label, a read-only Key `PVInput` with no handle, Description); `Features/Sources/ArtifactSheet.swift` 103 (`ArtifactSheetForm.fields`); `Features/Sources/SourceGraphFormDialog.swift` 95 (`SourceGraphForm.fields`: Name, Description); `Features/SourceTypes/SourceTypeAddDialog.swift` 55 (`SourceTypeAddForm.body`: Label, a read-only Key with no handle, Description); `Features/CitationComposer/CitationComposerEvidenceColumn.swift` 58 (`sideForm`: Label first) and 75 (`panelForm`: Transcription first); `Features/CitationComposer/CitationComposerView.swift` 131 (the new-Subject dialog's content closure on `CitationComposerView`'s `.pvFormDialog`: Label, Description); `Features/EvidenceGraph/EvidenceGraphView.swift` 395 (`EvidenceGraphContent.createForm`: the label hidden while `model.isEditingBridge`, and the description passed `nil` then) | Each wraps one input and one text area in `PVTabPair { a, b in … }` |
| Precedent | `Features/Promote/PromoteView.swift` (`private enum Field { case query }`, `@FocusState`), `Features/Sources/SourceDateDialog.swift`, `Features/Sources/MetadataBoardView.swift` | Forms that hold `@FocusState private var focus: Field?` and pass `PVFieldFocus($focus, equals: …)` |
| Guidance | `.agents/skills/add-ui-component/SKILL.md` line 74; `macos/App/DesignSystem/README.md` rows Input (157), Field focus (158), TextArea (159) | Name `PVTabPair` as the rule |
| Tests | `macos/ProvenenciaTests/PVFieldFocusTests.swift` `tabPairOrder` | Tests `PVTabPairField.next/previous` and `neighbours(next:previous:claim:)` with a recording claim |

**Precedent.** The forms in the Precedent row: a form's own `@FocusState` and `PVFieldFocus($focus, equals:)`. Copy that shape; add `in: order`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | In `PVFieldFocus.swift`: `static func neighbours<Value: Equatable>(of value: Value, in order: [Value]) -> (next: Value?, previous: Value?)` *(new)*, the field after and before the value's first place in `order`, nil at the ends, for an empty order and for a value not in `order`; and `@MainActor init<Value: Hashable>(_ binding: FocusState<Value?>.Binding, equals value: Value, in order: [Value])` *(new)*, which calls it and then `self.init(binding, equals: value, next:, previous:)`. Both are `@MainActor` (the file's statics that build claims already are). `init(_:equals:next:previous:)` stays as the one place a handle on a binding is built; it is not called from forms (the DesignSystem README's Field focus row says forms use `in:`) | The order rule lives on the handle every kit field takes, in the file that already owns Tab neighbours (user, 2026-11-16) | A `PVTabOrder` view owning or borrowing focus — two state modes, a generic the callers cannot infer, an untestable claim path (review M-1, X-1, X-2) |
| D-2 | The existing `static func neighbours(next:previous:claim:)` is renamed `claims(next:previous:claim:)`; behavior unchanged | Two statics named `neighbours` doing two halves of one job would read as one (review M-2) | Keeping the name |
| D-3 | A form holds `@FocusState private var focus: Field?` and a nested `private enum Field: Hashable` in the view that is the form's content (inside the sheet when the form is a dialog, never on the view that presents it), and writes its order once as `let order: [Field] = …` at the top of the `@ViewBuilder` property or `body` that builds the fields; a field not drawn is left out of `order` | The form owns its order and its state, as Promote and the date dialog already do | A kit enum of generic slots — the pair's `first`/`second` again |
| D-4 | Types, states and orders: `PropertiesIdentityEditor` `Field { label, description }`, `focus`, in `body`; `PropertiesCreateForm` *(new, private struct in `PropertiesView.swift`, extracted from `PropertiesCreateHost.createForm`: `@Bindable var model: PropertiesModel`, `@Binding var draft: PropertiesModel.Draft?`; the host's dialog closure becomes `PropertiesCreateForm(model: model, draft: $draft)`)* `Field { label, description }`, `focus` (the read-only Key keeps no handle, so Tab goes Label → Description as today); `ArtifactSheetForm` `Field { label, description }`, `focus`, in `fields`; `SourceGraphForm` (in `SourceGraphFormDialog.swift`) `Field { name, description }`, `focus`, in `fields`; `SourceTypeAddForm` (in `SourceTypeAddDialog.swift`) `Field { label, description }`, `focus`, in `body` (Key as in Properties); `CitationNewSubjectFields` *(new, private struct in `CitationComposerView.swift`: `let label: Binding<String>`, `let description: Binding<String>`, `let error: String?`; it replaces the `PVTabPair` block inside the new-Subject dialog's `VStack`, called with `newSubjectLabelBinding`, `newSubjectDescriptionBinding`, `model.newSubjectDraft?.error`)* `Field { label, description }`, `focus`; `CitationComposerEvidenceColumn` `CitationFormFocus { label, transcription }` *(internal, not private: S15-13 extends it and moves its state to `CitationComposerView`)*, state `@FocusState private var formFocus: CitationFormFocus?` (not `focus`: `labelField(focus:)` and `transcriptionColumn(rows:focus:)` take a parameter of that name), `sideForm` `[.label, .transcription]`, `panelForm` `[.transcription, .label]`, each in its own property; `EvidenceGraphContent` `CreateFormField { label, description }`, state `@FocusState private var createFormFocus: CreateFormField?` (its `focus` holds `EvidenceGraphFocus`), in `createForm` | Each form's fields and today's order; the state sits in the sheet's content view, as `SourceDateForm` and `PromoteView` do; no name clash (review R2-1, R2-2, R2-3) | The state on the presenting view — whether its `.focused` reaches a separate sheet window is unproven |
| D-5 | `EvidenceGraphContent.createForm`: `order = model.isEditingBridge ? [.description] : [.label, .description]`, and the description always gets its handle; the label's `PVField` stays behind the existing `if !model.isEditingBridge` | One rule for hidden fields (D-3); a lone listed field has no neighbours, so Tab goes to the key loop as with today's `nil` handle (AC-1.4) | Keeping the `nil` special case (review M-3) |
| D-6 | The rule in the skill and the README: "When Tab must move from a field that claims Tab (`PVInput`, `PVComboBox`, `PVSelect`) to a `PVTextArea`, the form holds its `@FocusState` and lists the fields in order: `PVFieldFocus($focus, equals: field, in: order)`. Every kit field takes a `PVFieldFocus`." | Worded by the reason it exists, so text-area-only editors stay conforming (review M-4) | "A form with a `PVTextArea` lists its fields" — reaches forms it does not mean |
| D-7 | `PVTabPair.swift` (`PVTabPair`, `PVTabPairField`, its `#Preview`) is deleted. `PVFieldFocusTests.tabPairOrder` becomes T-2 | One mechanism | Keeping `PVTabPair` as a wrapper — the user asked to retire the pair |

**Rules this plan bends.** The `PVTabPair` rule in `.agents/skills/add-ui-component/SKILL.md` and `macos/App/DesignSystem/README.md` is replaced (user, 2026-11-16); STEP-4 updates both.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVFieldFocus.neighbours(of:in:)` *(new)*, `PVFieldFocus.init(_:equals:in:)` *(new)* | func, init | `PVTabPairField.next/previous`; `PVFieldFocus.init(_:equals:next:previous:)` | Generalizes the first to any order; extends the second, which it calls |
| Per-form `private enum Field` and friends *(new, 8)*; `CitationFormFocus` *(new)* | enum | `PromoteView`'s `private enum Field` | Same shape, per form |
| `PropertiesCreateForm`, `CitationNewSubjectFields` *(new, private)* | view | `SourceDateForm` (a dialog's content view holding its focus) | Moves two dialog forms out of their presenters so the state sits in the sheet |

**Builds on.** `PVFieldFocus`, the form-held `@FocusState` pattern (`PromoteView`, `SourceDateDialog`, `MetadataBoardView`).
**Deletes.** `PVTabPair.swift` (`PVTabPair`, `PVTabPairField`, its `#Preview`); the name `neighbours(next:previous:claim:)` (renamed); the `nil` handle special case in `EvidenceGraphContent.createForm`; the `PVTabPair` wording in the skill and the README.
**Next adds.** S15-13 adds `printedPage` to `CitationFormFocus` and moves its `@FocusState` to `CitationComposerView`; S15-41's Unknown/Supplied control takes a `PVFieldFocus` (map scope line, STEP-4), so S15-45 can list it in the composer's order.

### Reach

None — no new path into existing code and no new state: each form keeps its fields and order.

### Scale

None — no write, list or loop; an order has 2 fields here (3 in S15-13).

### Edges

- **Assumptions.** A listed field has a drawn view (D-3). A value listed twice is a caller error; `neighbours(of:in:)` reads its first place and no test pins it.
- **Neighbors.** One field, an empty order and an unlisted value: no neighbours (AC-2.3). The ends: nil (AC-2.2).
- **Removed inputs.** None.
- **Real data.** None — no table drives this.
- **Untrusted size.** None — the order is written in code.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Ordered handle | `PVFieldFocus` | `macos/App/DesignSystem/Components/Input/PVFieldFocus.swift` | D-1, D-2 |
| Callers | — | the 7 files in § 4 | D-3, D-4, D-5. A caller reads, for one field: `PVInput(text: …, focus: PVFieldFocus($focus, equals: .label, in: order))` |
| Dialog content views | — | `PropertiesCreateForm`, `CitationNewSubjectFields` *(new)* | D-4 |

States and accessibility: unchanged.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — A focus handle takes its place in a form's order.**
Files: `macos/App/DesignSystem/Components/Input/PVFieldFocus.swift`, `macos/ProvenenciaTests/PVFieldFocusTests.swift`. Skills: `add-ui-component`, `add-swift-test`.
Do: D-1, D-2; T-1, T-2.
Check: `xcodebuild test` on `PVFieldFocusTests` passes (macOS).

**STEP-2 — The Sources, Source types, Properties and Evidence graph forms list their order.**
Files: `PropertiesView.swift`, `ArtifactSheet.swift`, `SourceGraphFormDialog.swift`, `SourceTypeAddDialog.swift`, `EvidenceGraphView.swift`.
Do: D-3, D-4, D-5.
Check: builds; manual check steps 1, 2.

**STEP-3 — The composer lists its order; the pair goes.**
Files: `CitationComposerEvidenceColumn.swift`, `CitationComposerView.swift`, `PVTabPair.swift` (deleted).
Do: D-4, D-7. `labelField(focus:)` and `transcriptionColumn(rows:focus:)` keep their `PVFieldFocus?` parameters.
Check: `rg -n "PVTabPair" macos` returns nothing; `xcodebuild test` passes; manual check step 3.

**STEP-4 — Docs.**
Files: `.agents/skills/add-ui-component/SKILL.md` (line 74: D-6), `macos/App/DesignSystem/README.md` (Input and TextArea rows: D-6's sentence in place of the `PVTabPair` clause; Field focus row: "builds its Tab neighbours from a form's order with `init(_:equals:in:)`"), `docs/deployment-plan/spike-15/deployment-plan.md` (map row status; the **Ships.** line of the scope entry `#### S15-41 — A metadata row can be marked unknown or supplied` gains the sentence "The control takes a `PVFieldFocus`, so a form can list it in its Tab order."), `docs/deployment-plan/spike-15/completed.md`, this plan.
Do: per the Definition of done.
Check: `rg -n "PVTabPair" .agents macos docs/*.md` returns nothing; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-50-forms-list-their-tab-order.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence ending in a period ("Let a form list its fields' Tab order in any number."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PVFieldFocusTests` `neighboursFollowTheFormsOrder` *(new)* | The cases of AC-2.1, AC-2.2, AC-2.3 | AC-2.1, AC-2.2, AC-2.3, D-1 |
| T-2 | Swift | `PVFieldFocusTests` `claimsRunTheNeighbour` (today's `tabPairOrder`, renamed and rewritten without `PVTabPairField`) | `claims(next: "c", previous: "a")` with a recording claim: `next?()` records "c", `previous?()` records "a"; `claims(next: String?.none, previous: String?.none)` gives two nils | AC-2.4, D-2 |

Tab at a real form is checked by hand (§ 10): a `FocusState.Binding` cannot be made outside a rendered view.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `CitationComposerModelTests`, `PVFieldFocusTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: `PVTabPair`, `PVTabPairField` and `neighbours(next:` `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md` and `macos/` with no hit left (earlier plans and archives keep theirs); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches before and after; no new kit primitive
- [ ] Version bump — none, per the header
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ — none (no brief)
- [ ] Domain doc updated if a rule in docs/*.md changed: none; the skill and the DesignSystem README per STEP-4
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. AC-1.1, AC-1.3: Source page → edit an Artifact: Tab from Label to Description, Shift-Tab back; Tab from Description reaches the sheet's next control.
2. AC-1.2, AC-1.4: the same in Add Evidence graph, Add type (Label → Description, past the read-only Key), Properties (edit a property's identity; Add property), and an Evidence graph's create form; while editing a bridge there, Tab in Description goes to the next control.
3. AC-1.2: the citation composer at the default window (Transcription → Label) and with a pane wider than 1400pt (Label → Transcription); the new-Subject dialog (Label → Description).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A form's Tab moves differently after the change | Manual check steps 1 – 3 at each former `PVTabPair` form |

**Stop and report if:**

- A form's Tab order differs from before in any manual check step.
- Tab does not move between the two fields inside a dialog (Add property, the new-Subject dialog, Add Evidence graph, Add type, the Artifact sheet) with the state in its content view (D-3).
- A `PVTabPair` use appears outside the 7 files of § 4 (`rg -n "PVTabPair" macos` at the base).
- `neighbours(next:previous:claim:)` has a caller other than `PVFieldFocus.init(_:equals:next:previous:)` and `tabPairOrder` (`rg -n "neighbours\(next:" macos`).

## 12. Open questions

None.

## 13. PR

**Title:** S15-50 — Forms list their tab order
**Body:** objective in one sentence; what shipped against US-1, US-2; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-50-forms-list-their-tab-order.md`.
