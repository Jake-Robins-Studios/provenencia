# S15-50 — Forms list their tab order

**Status:** Draft
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
**Review:** [`S15-50-forms-list-their-tab-order.review.md`](S15-50-forms-list-their-tab-order.review.md) — not reviewed yet

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

## 1. Objective

AppKit's key loop skips the text view under a `PVTextArea` when Tab leaves a `PVInput`, so a form names its fields' Tab order itself. Today the kit offers that only as `PVTabPair`: exactly two fields, wired first ↔ second, with the focus state private to the pair. S15-13 needs three fields (Label, Printed page, Transcription) and needs the focus held above the form so it survives the composer's layout switch. The user's call (2026-11-16): Tab order belongs to the form, not to a pair of fields. This PR adds `PVTabOrder`: a form lists its fields in order, any number, and gets one focus handle per field. It moves every `PVTabPair` caller onto it and deletes `PVTabPair`.

**Why now.** S15-13 depends on it.

**What stays.** Every form's fields, layout and Tab behavior. The text area's own Tab handling (`PVTextAreaTabRouter`: Tab leaves the area, Option-Tab types a tab character) and the input's (`PVInputTabClaim`) are unchanged. Tab from the last listed field and Shift-Tab from the first are left to the key loop, as today.

## 2. User stories

**US-1.** As a researcher, Tab and Shift-Tab move between a form's text input and its text area exactly as before.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The Artifact sheet: cursor in Label, press Tab | The cursor is in Description; Shift-Tab returns to Label |
| AC-1.2 | Each other former `PVTabPair` form (Properties identity edit and create, the graph form, Add type, the composer's citation form in both layouts, the composer's new-Subject dialog, the Evidence graph card form) | Tab and Shift-Tab between its two listed fields behave as before |
| AC-1.3 | Tab in the last listed field, Shift-Tab in the first | The key loop handles the key, as today |

**US-2.** As a contributor, I list any number of fields and, when I need to, hold the focus state myself.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | `PVTabOrder.neighbours(of: .b, in: [.a, .b, .c])` | `(next: .c, previous: .a)` |
| AC-2.2 | Of `.a` in `[.a, .b, .c]`; of `.c` | `(next: .b, previous: nil)`; `(next: nil, previous: .b)` |
| AC-2.3 | Of `.a` in `[.a]`; of `.d` in `[.a, .b]` (not listed) | `(nil, nil)` both: the field leaves Tab to the key loop |
| AC-2.4 | A host passes its own `FocusState<Field?>.Binding` | The handles write that binding; a write to it by the host lands in the field |

## 3. Scope

| In | Covered by |
| --- | --- |
| `PVTabOrder` in the kit | STEP-1, AC-2.* |
| Every `PVTabPair` caller moves to it; `PVTabPair` and `PVTabPairField` deleted | STEP-2, STEP-3, AC-1.* |
| The skill's checklist line and the DesignSystem README rows | STEP-4 |

| Out | Home |
| --- | --- |
| The composer's third field (Printed page) | S15-13 |
| Wiring more fields into a form's order than today's two (the read-only key fields in Properties create and Add type, the icon grid) | not planned: those forms keep today's Tab behavior |
| Focus kept across a width change | S15-13 (it applies `FocusKeeper` with the host-held binding) |
| Any change to `PVTextAreaTabRouter` or `PVInputTabClaim` | not planned |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| The pair | `macos/App/DesignSystem/Components/Input/PVTabPair.swift` `PVTabPair`, `PVTabPairField` | A `View` with a private `@FocusState var field: PVTabPairField?`; `content(handle(.first), handle(.second))`; `PVTabPairField.next/previous` wire first ↔ second; a `#Preview` |
| The handle | `macos/App/DesignSystem/Components/Input/PVFieldFocus.swift` `PVFieldFocus.init(_:equals:next:previous:)`, `neighbours(next:previous:claim:)` | Builds a handle on any `FocusState<Value?>.Binding` with optional neighbours; unchanged by this PR |
| Text area Tab | `macos/App/DesignSystem/Components/TextArea/PVTextArea.swift` `PVTextAreaTabRouter` | Tab leaves the area to `focus.next`, else the key loop; Option-Tab inserts a tab. Unchanged |
| Input Tab | `macos/App/DesignSystem/Components/Input/PVInput.swift` `PVInputTabClaim` | Claims Tab for a handle with a neighbour. Unchanged |
| Callers (10 uses, 7 files) | `Features/Properties/PropertiesView.swift` lines 619 (`PropertiesIdentityEditor`) and 823 (create form); `Features/Sources/ArtifactSheet.swift` 103 (`fields`); `Features/Sources/SourceGraphFormDialog.swift` 95; `Features/SourceTypes/SourceTypeAddDialog.swift` 55; `Features/CitationComposer/CitationComposerEvidenceColumn.swift` 58 (`sideForm`: label first) and 75 (`panelForm`: transcription first); `Features/CitationComposer/CitationComposerView.swift` 131 (new-Subject dialog); `Features/EvidenceGraph/EvidenceGraphView.swift` 395 (the label field hidden while `model.isEditingBridge`, the description passed `nil` then) | Each wraps one input and one text area in `PVTabPair { a, b in … }` |
| Guidance | `.agents/skills/add-ui-component/SKILL.md` line 74; `macos/App/DesignSystem/README.md` rows Input (157), Field focus (158), TextArea (159) | Name `PVTabPair` as the rule |
| Tests | `macos/ProvenenciaTests/PVFieldFocusTests.swift` `tabPairOrder` | Tests `PVTabPairField.next/previous` |

**Precedent.** `PVTabPair` itself (the handle wiring to copy); a kit component that may own or borrow state: `FocusKeeper` takes the host's `FocusState<Stop?>.Binding` (`macos/App/Platform/FocusKeeper.swift`).

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `PVTabOrder<Field: Hashable, Content: View>: View` *(new)* in `macos/App/DesignSystem/Components/Input/PVTabOrder.swift`. `init(_ order: [Field], focus: FocusState<Field?>.Binding? = nil, @ViewBuilder content: @escaping (_ focus: (Field) -> PVFieldFocus) -> Content)`. With `focus` nil it owns a private `@FocusState`; with a binding it writes the host's. The body is `content` unchanged, so the parent stack lays the fields out (as `PVTabPair`) | Any number of fields; a host that must keep focus across a rebuild holds the state (S15-13) | A second, host-held variant type — one component covers both |
| D-2 | `static func neighbours(of field: Field, in order: [Field]) -> (next: Field?, previous: Field?)` *(new)* on `PVTabOrder` is the one rule: the field after and before it in `order`; nil at the ends and for a field not in `order`. The handle for a field is `PVFieldFocus(binding, equals: field, next:, previous:)` with those values | Pure and testable; the ends keep today's "leave it to the key loop" | Wrapping Tab from the last field to the first — today's forms let Tab reach their buttons |
| D-3 | A field not shown is left out of `order` by the caller; `PVTabOrder` has no `isShown` parameter | The caller knows what it draws; one list says it | A visibility closure — two sources of truth |
| D-4 | Each caller declares a `private enum` of its fields, named for them (`enum Field { case label, description }`, `case name, description` in the graph form), and passes them in today's pair order. The composer declares `enum CitationFormFocus { case label, transcription }` *(new, internal, in `CitationComposerEvidenceColumn.swift`)*; `sideForm` lists `[.label, .transcription]`, `panelForm` `[.transcription, .label]` | Names read at the call site; S15-13 adds `printedPage` to `CitationFormFocus` | A kit enum of generic slots — the pair's `first`/`second` again |
| D-5 | `EvidenceGraphView` keeps its order `[.label, .description]` and its existing `model.isEditingBridge ? nil : description` for the description's handle | No behavior change in this PR | Changing the bridge-edit focus — not asked |
| D-6 | `PVTabPair`, `PVTabPairField`, the `tabPairOrder` test and `PVTabPair`'s `#Preview` are deleted. `PVTabOrder.swift` carries a `#Preview` with three fields (two inputs and a text area) | One mechanism | Keeping `PVTabPair` as a wrapper — the user asked to retire the pair concept |
| D-7 | The rule becomes: "A form with a `PVTextArea` lists its fields in a `PVTabOrder`; every kit field takes a `PVFieldFocus`." | The concern is the form's order, not a pair | — |

**Rules this plan bends.** The `PVTabPair` rule in `.agents/skills/add-ui-component/SKILL.md` and `macos/App/DesignSystem/README.md` is replaced (user, 2026-11-16); STEP-4 updates both.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVTabOrder` *(new)* | component | `PVTabPair` | Replaces it (two fields, private state only) |
| `PVTabOrder.neighbours(of:in:)` *(new)* | func | `PVTabPairField.next/previous`, `PVFieldFocus.neighbours(next:previous:claim:)` | The first is the two-case rule it generalizes; the second turns a neighbour into a claim and is still used |
| Per-form `enum Field` *(new, 6 private)*, `CitationFormFocus` *(new)* | enum | `PVTabPairField` | Names the form's own fields |

**Builds on.** `PVFieldFocus.init(_:equals:next:previous:)`; `FocusKeeper`'s host-held binding shape.
**Deletes.** `PVTabPair.swift` (`PVTabPair`, `PVTabPairField`, its `#Preview`); `PVFieldFocusTests.tabPairOrder`; the `PVTabPair` wording in the skill and the README.
**Next adds.** S15-13 adds `printedPage` to `CitationFormFocus` and passes a host-held binding; S15-45 adds the Unknown/Supplied control to that order.

### Reach

None — no new path into existing code and no new state: each form keeps its fields and order.

### Scale

None — no write, list or loop; a form's order has 2 fields here (3 in S15-13).

### Edges

- **Assumptions.** A handle's neighbour must be a field with a view; today's callers list only drawn fields (D-3, D-5). A field listed twice is a caller error; `neighbours` uses the first index (T-1 pins it).
- **Neighbors.** One field: no neighbours (AC-2.3). The ends: nil (AC-2.2).
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
| Tab order | `PVTabOrder` *(new)* | `macos/App/DesignSystem/Components/Input/PVTabOrder.swift` | D-1, D-2 |
| Callers | — | the 7 files in § 4 | D-4, D-5 |

States and accessibility: unchanged.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — The kit lists a form's tab order.**
Files: `macos/App/DesignSystem/Components/Input/PVTabOrder.swift` *(new)*, `macos/ProvenenciaTests/PVFieldFocusTests.swift`. Skills: `add-ui-component`, `add-swift-test`.
Do: D-1, D-2, the `#Preview` of D-6; T-1, T-2.
Check: `xcodebuild test` on `PVFieldFocusTests` passes.

**STEP-2 — The Sources, Source types, Properties and Evidence graph forms use it.**
Files: `PropertiesView.swift`, `ArtifactSheet.swift`, `SourceGraphFormDialog.swift`, `SourceTypeAddDialog.swift`, `EvidenceGraphView.swift`.
Do: D-4, D-5.
Check: builds; manual check steps 1 – 2.

**STEP-3 — The composer uses it; the pair goes.**
Files: `CitationComposerEvidenceColumn.swift`, `CitationComposerView.swift`, `PVTabPair.swift` (deleted), `PVFieldFocusTests.swift`.
Do: D-4, D-6.
Check: `rg -n "PVTabPair" macos` returns nothing; `xcodebuild test` passes; manual check step 3.

**STEP-4 — Docs.**
Files: `.agents/skills/add-ui-component/SKILL.md` (line 74, D-7), `macos/App/DesignSystem/README.md` (Input and TextArea rows name `PVTabOrder`; Field focus row says `PVTabOrder` builds its neighbours), `docs/deployment-plan/spike-15/deployment-plan.md` (map row status), `completed.md`, this plan.
Do: per the Definition of done.
Check: `rg -n "PVTabPair" .agents docs/*.md macos/App/DesignSystem/README.md` returns nothing; `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-15/prs/S15-50-forms-list-their-tab-order.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence ending in a period ("Let a form list its fields' Tab order in any number."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PVFieldFocusTests` `tabOrderNeighbours` *(new)* | The cases of AC-2.1, AC-2.2, AC-2.3; a field listed twice uses its first place | AC-2.1, AC-2.2, AC-2.3, D-2 |
| T-2 | Swift | `PVFieldFocusTests` `tabOrderHandlesClaimTheirNeighbours` *(new)* | Handles built by `PVTabOrder` over a host `FocusState` in a test host view: `handle(.a).next?()` sets the binding to `.b`; `handle(.c).next` is nil | AC-2.4, D-1 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `CitationComposerModelTests`, `PVFieldFocusTests`.

If T-2 cannot build a `FocusState` outside a rendered view, it tests the handle closure that `PVTabOrder` builds through a `static func handles(binding:order:)` it exposes for the body and the test alike, and the manual check covers the live claim.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected)
- [ ] Sweep: `PVTabPair` and `PVTabPairField` `rg`'d across `.agents/`, `.cursor/rules/`, `docs/*.md`, `macos/` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches before and after; no new kit primitive beyond `PVTabOrder`
- [ ] Version bump — none, per the header
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ — none (no brief)
- [ ] Domain doc updated if a rule in docs/*.md changed: none; the skill and the DesignSystem README per STEP-4
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. AC-1.1, AC-1.3: Source page → edit an Artifact: Tab from Label to Description, Shift-Tab back; Tab from Description reaches the sheet's next control.
2. AC-1.2: the same in Add Evidence graph, Add type, Properties (edit a property's identity; Add property), and an Evidence graph card's label and description.
3. AC-1.2: the citation composer at the default window (Transcription → Label) and wide (Label → Transcription); the new-Subject dialog (Label → Description).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A generic `View` holding an optional `FocusState` binding and its own `@FocusState` reads awkwardly | D-1 fixes the shape; T-2 and the preview exercise both modes |

**Stop and report if:**

- A form's Tab order differs from before in any manual check step.
- A `PVTabPair` use appears outside the 7 files of § 4 (`rg -n "PVTabPair" macos` at the base).
- `PVTabOrder` cannot pass a host-held `FocusState<Field?>.Binding` to `PVFieldFocus` (S15-13 needs it).

## 12. Open questions

None.

## 13. PR

**Title:** S15-50 — Forms list their tab order
**Body:** objective in one sentence; what shipped against US-1, US-2; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-50-forms-list-their-tab-order.md`.
