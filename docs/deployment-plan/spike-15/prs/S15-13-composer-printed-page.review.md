# Review — S15-13 The composer records the printed page (and brief S15-D8)

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1. Round 1 had a blocker (M-1), answered by the user with a preparatory PR (S15-50) rather than a plan reshape, so round 2 runs at the refresh that unblocks the plan, once S15-50 has landed and the board is agreed. **Reviewers:** maintainability (opus), executability (sonnet)

## To user

- **M-1 (answered 2026-11-16).** The third field could not use `PVTabPair`, which pairs exactly two fields. User: tab order belongs to the form, not to an input–text-area pair. Rethink it as a preparatory PR: S15-50, "Forms list their tab order" (`PVTabOrder`, any number of fields, replacing `PVTabPair` at every caller, skill and README updated). S15-13 depends on it.

## Writer's own calls

- D-6: after a Citation delete the blank Citation keeps the printed page with the locator (the composer keeps the spot); an Artifact switch and **New citation** clear it.
- D-7: the field is hidden while the viewer is still loading, as Paste and Auto transcribe are.
- D-2: "at most one page selector" becomes a write-time rule in `validateDoc`. Only the composer writes locators, always with one page selector.
- D-10: the menu reuses the citation line's "p. %@" and "image %lld" strings through `CitationLineDisplay`; no new menu keys.
- Version: minor, 0.17.0.

## Round 1

### M-1 · blocker · D-10 drops `PVTabPair` against a skill rule, and the precedent the brief cites does not exist
`add-ui-component` checklist line 74 and `DesignSystem/README.md` rows Input and TextArea say an input and a text area in one form are wrapped in `PVTabPair`; the draft's feature-private ring was a second mechanism; `CitationComposerAuthoringBox` uses combo-commit routing, not `PVFieldFocus` neighbours.
**Answer:** To user → answered: a preparatory PR, S15-50 (map row, scope entry, slice 3, S15-50 ──▶ S15-13). The plan's D-12 passes `CitationFormFocus.order` to `PVTabOrder`; the brief's inventory row is corrected.

### M-2 · blocker · The new menu keys repeat the citation line's page words
**Answer:** Fixed — D-10: `CitationLineDisplay.printedPage(_:)` and `filePage(_:)` wrap the existing `L10n.Conclusions` keys; `parts` and the menu call them; no menu keys added; the brief's copy table says the menu uses the citation line's strings.

### M-3 · major · D-8 merges only the row text; the two Citation menus are still copies
**Answer:** Fixed — D-9: one `CitationStepMenu` owns the options, the new-citation row and the row; both `citationOptions` and `menuLocator` go; T-9 moved to `CitationComposerModelTests`.

### M-4 · major · AC-4.3 needs a one-page-selector rule that `Validate` does not have
**Answer:** Fixed — D-2: the rule moves into `validateDoc`; the counts in `citationPage` and `regionDocPages` go; T-1 and T-3 test it at write.

### M-5 · minor · `locator.Page` returns a tuple that S15-44 must widen
**Answer:** Fixed — D-4: `PageRef { ArtifactPage, Label }`; S15-44 adds a field.

### M-6 · minor · The Swift page selector still drops keys it does not model
**Answer:** Declined for this PR — no unmodeled key exists on the page selector until S15-44 adds the marks, and S15-45 models them in `CitationLocatorDraft` (Out row, Next adds).

### M-7 · minor · Two names for one fact in the new Swift
**Answer:** Fixed — D-8: data is `pageLabel` (draft and model); copy, the capability and the view say "printed page".

### M-8 · minor · `CitationLocatorDraft.hasPage` is unused
**Answer:** Fixed — D-5 deletes it; Deletes and the DoD sweep list it.

### X-1 · blocker · AC-4.3 is not enforced by anything the plan changes
**Answer:** Fixed with M-4 (D-2).

### X-2 · major · A deleted Citation's printed page leaks into the blank composer
**Answer:** Fixed — decided to keep it with the locator (D-6, AC-2.6, T-6); the composer keeps the deleted Citation's spot, and the printed page belongs to the spot.

### X-3 · major · Switching Artifacts clears the printed page, which the plan does not mention
**Answer:** Fixed — D-6, AC-2.7, T-6.

### X-4 · major · STEP-4 and STEP-6 are out of order for Tab order and focus
**Answer:** Fixed — tab order (D-12, through S15-50's `PVTabOrder`) and the `@FocusState` move into STEP-4; STEP-6 keeps the width class and `FocusKeeper` (D-11, D-13).

### X-5 · major · `plan-docs` check cannot report "no errors"
**Answer:** Fixed — this log now exists.

### X-6 · minor · The menu's new L10n keys have no home step
**Answer:** Fixed — STEP-4 adds the three field keys with comments; the menu adds none (D-10); STEP-5 removes `menuPage`.

### X-7 · minor · T-6 cannot read "store got `page_label":"24"` as written
**Answer:** Fixed — T-6 reads `store.citationsByID["cit-1"]?.locatorJSON`.

### X-8 · minor · The field's offered state before the viewer has loaded is undefined
**Answer:** Fixed — D-7: hidden while `kind` is `.unsupported`, as Paste and Auto transcribe are.

### X-9 · minor · Non-string `page_label` in stored JSON
**Answer:** Fixed — D-5 ignores it; T-5 `nonStringPageLabelIsIgnored`.

### X-10 · nit · Smaller choices
**Answer:** Fixed — Edges: a page above `MaxInt32` stays "no page selector", label included; AC-4.7 for a blank label beside a file page; T-7 moved to `ArtifactViewerModelTests`; T-4 names `TestGraphRecordsCarryCitationWords`.

### X-11 · major · Brief frame 4's data does not match CP-5 or the menu
**Answer:** Fixed — the brief's data adds CIT-5MV2N, CIT-6TN1B, CIT-8PL3C; frame 4 becomes 4a (Enumeration book 4) and 4b (Folio 23), each one Artifact's menu.

### X-12 · minor · Regular-only frames not explained
**Answer:** Fixed — the brief's § 5 says why frames 3 – 6 are Regular only.

### X-13 · minor · The board's open choices change the inventory
**Answer:** Logged — the plan's "Board-dependent" line and the brief's Handoff name them; the plan is refreshed at board agreement.

## Board check (2026-11-16)

The agreed S15-D8 board was read against the brief: every requirement CP-1 – CP-7, CP-W1, CP-W2 has its frame; the copy matches § 2.1 word for word ("Printed page", "As printed, such as 14 or iv", the help sentence, "Save citation"); the Tab order note matches D-12; the Kit used row names only kit pieces and the three extended snowflakes; no local control. The board's own decisions are folded into the plan as D-16 (placement by the space given, help as a tooltip, no column widens at Wide) and § 6's frame descriptions. Round 2 of the plan review runs at the refresh after S15-50 lands.
