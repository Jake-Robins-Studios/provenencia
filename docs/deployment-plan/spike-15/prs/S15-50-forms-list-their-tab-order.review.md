# Review — S15-50 Forms list their tab order

**Verdict:** round 1: Fits with changes — Not ready; reshaped (M-1, user 2026-11-16); round 2 below
**Rounds:** 2. **Reviewers:** maintainability (opus), executability (sonnet)

## To user

- **M-1 (answered 2026-11-16).** Put the order rule on the focus handle (`PVFieldFocus(_:equals:in:)`, the form holding its `@FocusState`) instead of a `PVTabOrder` view that may own or borrow focus. User: adopt it. The map's S15-50 row and scope, S15-13 (D-12, Codebase fit, macOS, Stop conditions) and S15-D8's inventory row were renamed in the same commit.

## Writer's own calls

- D-4: each form's enum is nested in the view that draws it; the composer's is `CitationFormFocus` (internal, so S15-13 can extend it); the Evidence graph's state is `createFormFocus` beside its existing `focus`.
- D-5: the Evidence graph's hidden label leaves the order, replacing the `nil` handle (review M-3).
- The forms with a read-only Key input or an icon grid keep today's two-field order (Out).
- No version bump (S15-36 precedent).

## Round 1

### M-1 · major · Put the order rule on the focus handle, not in a view that may own the focus state
**Answer:** To user → adopted. D-1 rewritten: `PVFieldFocus.neighbours(of:in:)` and `init(_:equals:in:)`; no `PVTabOrder` type.

### M-2 · major · A second static named `neighbours`, on a second type, for one job
**Answer:** Fixed — D-2 renames the existing claim builder `claims(next:previous:claim:)`; the order rule sits beside it in `PVFieldFocus.swift`.

### M-3 · major · D-5 keeps a second way to say "this field is not shown"
**Answer:** Fixed — D-5: `order = isEditingBridge ? [.description] : [.label, .description]`; the description always gets its handle; AC-1.4.

### M-4 · minor · D-7 widens the rule beyond what it means and misses a form
**Answer:** Fixed — D-6 words the rule by its reason; Out rows for `SourceTypePageView.form` and the text-area-only editors.

### M-5 · minor · "Next adds" claims a slot that the map does not give
**Answer:** Fixed — STEP-4 adds to the map's S15-41 scope that its control takes a `PVFieldFocus`.

### M-6 · minor · The claim path loses its test; T-2 leaves an API shape open
**Answer:** Fixed with M-1 — T-2 is today's `tabPairOrder`, rewritten for `claims` with a recording claim; no test-only seam.

### M-7 · nit · T-1 pins duplicate behavior
**Answer:** Fixed — not tested; Edges says it is a caller error.

### M-8 · nit · Folder
**Answer:** Moot with M-1 (no new file).

### X-1 · blocker · `PVTabOrder`'s generic `Field` cannot be inferred at the callers
**Answer:** Fixed with M-1 — each field's handle is `PVFieldFocus($focus, equals: .label, in: order)`, typed by the form's `@FocusState`.

### X-2 · blocker · The host-held mode has no caller and no runnable test
**Answer:** Fixed with M-1 — one mode: the form always holds the state; T-1 and T-2 are pure; live Tab is the manual check.

### X-3 · major · Where the binding is resolved
**Answer:** Moot with M-1.

### X-4 · major · D-3 and D-5 contradict
**Answer:** Fixed — see M-3.

### X-5 · major · Enum count and placement undecided
**Answer:** Fixed — D-3, D-4 name each type and enum (8 enums, nested).

### X-6 · major · Fields in each order for the three-control forms
**Answer:** Fixed — D-4: the read-only Key keeps no handle; Tab goes Label → Description, as today.

### X-7 · major · `PropertiesIdentityEditor`'s handles inside `PVInlineEdit`
**Answer:** Fixed — § 4 names it; its handles are built inline from its own `@FocusState`; manual check step 2.

### X-8 · minor · Paths and doc checks
**Answer:** Fixed — STEP-4 gives `docs/deployment-plan/spike-15/completed.md`; the sweep leaves earlier plans and archives alone (Out, DoD); README wording given in STEP-4; this log exists.

### X-9 · minor · The preview needs its own enum
**Answer:** Moot — `PVTabPair`'s preview is deleted; no new view.

### X-10 · minor · Checks not runnable on Linux
**Answer:** Logged — Swift checks run on macOS (`scripts/check-pr.sh`); Tab at a form is a manual check by design (§ 8 note).

### X-11 · nit · Temptations
**Answer:** Fixed — STEP-3 says `labelField` and `transcriptionColumn` keep their parameters.

## Round 2
