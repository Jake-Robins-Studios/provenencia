# S15-39 — Metadata boards flag needed fields

**Status:** Blocked — on board S15-D20
**Spike / slice:** Spike 15 · Slice 9 — Needed fields, unknown and supplied values
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S15-D20](../design/S15-D20-boards-flag-needed-fields.md), board not agreed yet
**Board:** Claude Design links once agreed (user, 2026-11-28): [Source Detail](https://claude.ai/artifact/443NPNYmGErAmxgV1fBsFK) (Source page, Artifact sheet, graph form) and [Citation Composer](https://claude.ai/artifact/3GSFQZjqdQjL8v2rpgMiDc) (Citation metadata sheet), frames D20-1a – D20-10; the brief's **Board** line will name them
**Depends on:** S15-38 (landed #910), S15-34 (landed [#819](https://github.com/Jake-Robins-Studios/provenencia/pull/819)), S15-11 (landed [#834](https://github.com/Jake-Robins-Studios/provenencia/pull/834)), S15-56 (landed #982), S16-61 (landed [#886](https://github.com/Jake-Robins-Studios/provenencia/pull/886)), S15-D20
**Blocks:** S15-40, S15-41, S15-66
**Branch:** `s15-39-boards-flag-needed-fields`
**Version bump:** minor, 0.53.0 (today's `VERSION`) → **0.54.0** (or the next minor after `main`'s `VERSION` when you rebase): every board shows what the citation needs ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-client.mdc` (the draft-board scenario file is the record of the rules `MetadataDraftHost` mirrors), `.cursor/rules/swift-tests.mdc`
**Context:** working rules "A format's fields are needed or used", "Boards flag needed fields; the engine decides the rows", "One metadata board", "A board shows what its owner inherits"; [`evidence-explained-citation-map.md` § 6.10](../evidence-explained-citation-map.md); S15-38's plan [`S15-38-board-requirements.md`](S15-38-board-requirements.md) (D-8, D-12, D-17)
**Planned:** 2026-11-28 against `main` @ `573612a`
**Review:** [`S15-39-boards-flag-needed-fields.review.md`](S15-39-boards-flag-needed-fields.review.md) — round 1 in progress

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

Every board entry already carries what its Source type's citation formats ask of it (S15-38: needed, used or none; met elsewhere; the chain's other options), and no board draws it. After this PR the shared board row draws it: an empty needed field that nothing answers is flagged and offers no dismiss, with a hint naming the chain's other fields; an empty used field, or a needed one met elsewhere, carries a quieter mark; a row with a value carries none. Every board gets it at once, because every board is `MetadataBoardView`: the Source page, the Artifact sheet (edit and add), the graph form (edit and add) and the composer's Citation metadata sheet. `MetadataDraftHost` learns the one rule it mirrors (a needed field cannot be dismissed), so the draft-board scenario file loses its `needed` divergence.

**Why now.** S15-38 sends the annotation on every read and write reply and S15-56 made the Citation's printed page a board row, so one Swift change flags every board, the page included. Until it lands the ✕ on an empty needed suggestion fails with "This metadata change can't be saved." (accepted by the user until S15-39, 2026-11-19; S15-38 ship log CON-1).

**What stays.** Which entries a board holds and their order (the engine's), the "Suggested by this type" heading, every write and RPC, the drafts the sheets send, saved rows, the inherited row's value, caption and override, the Add field row. No Go, proto or schema change.

## 2. User stories

**US-1.** As a researcher, an empty field the citation needs is flagged on whichever board I am looking at, so I fill it before I cite.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A census Source with no Jurisdiction; open the Source page | The Jurisdiction row shows the Needed flag and no ✕ (NF-1) |
| AC-1.2 | A Book Source with no Author | Author is flagged; Author for sorting is flagged with "Or fill in Author" (NF-1, NF-2) |
| AC-1.3 | AC-1.2, then save Author "Ashby, Ruth" | Author is a saved row with no mark; Author for sorting shows Used and no ✕ (NF-3, NF-5) |
| AC-1.4 | AC-1.1, then save "Calder County" in Jurisdiction | A saved row, no mark; trash it (confirm) → flagged again (NF-5) |
| AC-1.5 | A census Source with no Jurisdiction; open an Artifact's sheet, Add an Artifact, open a graph's form | Jurisdiction flagged on each (NF-6) |
| AC-1.6 | A Court report Citation with no Page; open its Citation metadata sheet | Page flagged with "Or fill in Pages"; type "112" in Pages and press its row's Save → Page shows Used, before the sheet's Save (NF-2, NF-5, D-4) |

**US-2.** As a researcher, a field the citation only uses is marked quietly and can still be dismissed, so the flags I see are the ones that matter.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | A census Artifact with no URL; open its sheet | URL shows Used, not flagged, with its ✕ (NF-3) |
| AC-2.2 | AC-2.1; dismiss URL; Save | The row goes, the sheet saves, no error |
| AC-2.3 | The census Source holds Jurisdiction "Calder County"; open an Artifact's sheet | Jurisdiction is the inherited row ("Calder County", "From Source") with Used and no ✕ (NF-4) |
| AC-2.4 | AC-2.3; override Jurisdiction "Ottawa County", row Save | A saved row, no mark; its trash → the inherited row with Used again (NF-4) |
| AC-2.5 | Any row with a value | No mark, whatever its field's need (NF-5) |

**US-3.** As a VoiceOver user, a flagged row says so.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Focus AC-1.1's Jurisdiction input | Reads "Jurisdiction, needed for citation" (NF-7) |
| AC-3.2 | Focus AC-1.2's Author for sorting input | Reads "Author for sorting, needed for citation", hint "Or fill in Author" (NF-7) |
| AC-3.3 | Focus AC-2.3's inherited value | Reads "Jurisdiction, used in citation, Inherited from Source: Calder County" (NF-7) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `entry.requirement` mapped into Swift on every board read and write reply | STEP-1, T-1 |
| The mark rule: needed (flag), used (quiet), none; met elsewhere; a chain's alternative valued on the board | STEP-2, T-2, AC-1.3, AC-1.6 |
| NF-1, NF-2, NF-3: flag, chain hint, used mark on the suggestion row | STEP-5, AC-1.1, AC-1.2, AC-2.1 |
| NF-4: the mark on the inherited row; no ✕ on a needed one | STEP-5, AC-2.3, AC-2.4 |
| No ✕ on any needed row; `MetadataDraftHost` refuses dismissing a needed field | STEP-3, STEP-5, T-3 |
| NF-5: filling clears the mark; clearing brings it back | STEP-2, STEP-5, T-2, AC-1.4 |
| NF-6: every board (Source page, Artifact sheet edit and add, graph form edit and add, Citation metadata sheet) | STEP-5, manual check |
| NF-7: spoken names and the hint | STEP-4, STEP-5, T-5, AC-3.1 – AC-3.3 |
| NF-W1: nothing moves at Wide | Manual check 8 |
| The draft-board scenario file's `needed` divergence and the parity test's skip go | STEP-3, T-4 |
| Copy | STEP-4 |

| Out | Home |
| --- | --- |
| The Artifacts list's mark for a missing needed field | S15-40 |
| The Unknown and Supplied control; an unknown row answering a needed field on screen | S15-41 |
| The Source date's flag (`dateRequirement` in Swift) | S15-42 |
| The ⓘ and its board hint helper | S15-73 |
| The list-below hint and Move to Source | S15-66 |
| The Copy Source sheet's board | S16-75 (it reaches this row through S16-77's requirements) |
| A needed-rows heading or re-sorting | not planned (brief § 2.2) |
| A draft that clears a stored alternative re-flagging its head before Save | not planned (Edges) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Wire | `api/proto/engine.proto` `MetadataWorkspaceEntry.requirement`, `CitationRequirement`, `CitationRequirementOption`, `CitationNeed` | Sent on every entry since S15-38; nothing to change |
| Swift entry | `macos/App/Platform/GenealogyStore.swift` `CatalogMetadataEntry` | No requirement field (S15-38 D-12) |
| Swift option | `GenealogyStore.swift` `CatalogCitationOption` | One option of a chain; used by the format editor's missing line only |
| Mapping | `macos/App/Platform/GoStore.swift` `mapMetadataEntry`; `renderCitationPreview` maps `CitationRequirementOption` inline in a `compactMap` closure | Every board read (`getSourceWorkspace`, `getMetadataBoard`, `getDraftMetadataBoard`) and write reply goes through `mapMetadataEntry`; it drops `requirement`. The option mapping cannot be reused |
| Board model | `macos/App/Features/MetadataBoard/MetadataBoardModel.swift` `MetadataBoardModel.suggested`, `dismissSuggestion(fieldID:)` | No notion of need |
| Board view | `macos/App/Features/MetadataBoard/MetadataBoardView.swift` `MetadataBoardSuggestionRow`, `MetadataBoardInheritedRow`, `MetadataBoardSuggestionDismiss`, `MetadataBoardLabel`, `MetadataBoardCaption` | Both empty-row kinds always draw the ✕; a needed field's ✕ fails on the Source page (`sourcemetadata.DismissSuggestion` refuses it) and is silently dismissed in a sheet |
| Draft host | `macos/App/Features/MetadataBoard/MetadataDraftHost.swift` `dismissSuggestion(fieldID:)` | Dismisses any empty suggestion or head, needed included |
| Hosts | `SourcePageMetadataHost` (live); `MetadataDraftHost` in `ArtifactSheetModel`, `SourceGraphFormModel`, `CitationMetadataSheetModel` | All draw through `MetadataBoardView` (directly or `DraftMetadataBoardField`); add mode already reads `getDraftMetadataBoard` (S15-64) |
| Missing line copy | `macos/App/Platform/L10n.swift` `L10n.CitationFormats.missing(_:)` with an inner `name(_:)` | Names an option (field label or `builtinName`); the inner function is not reusable |
| Scenario file | `core/database/sourcemetadata/testdata/draft_board_scenarios.json` | `"needed": ["document_number"]`; scenario "dismissing an empty needed suggestion is refused" carries `"known_divergence": "needed"`; `_note` names the divergence |
| Tests | `macos/ProvenenciaTests/MetadataDraftHostParityTests.swift` `compared(_:divergence:)` `case "needed"`, `scenariosMatchTheEngine` (`divergence != "needed"` guard); `MetadataBoardModelTests.swift`; `MetadataDraftHostTests.swift` `dismissOnlyEmptySuggestions`; `CatalogFixtures.swift` `catalogMetadataEntry(...)` | The parity test skips the needed scenario's board and draft; the fixture has no requirement parameter |
| Go | `core/database/sourcemetadata/sourcemetadata_test.go` `TestDraftBoardScenarios` | Ignores `known_divergence` except `order`; unchanged by this PR |

**Precedent.** S15-64 ([#959](https://github.com/Jake-Robins-Studios/provenencia/pull/959)) added `CatalogMetadataEntry.inherited`: one field on the entry, one mapper beside `mapMetadataEntry` (`mapInheritedMetadataValue`), the fixture gained a defaulted parameter, and `MetadataBoardView` gained a row state drawn from it. Copy that shape. Do not copy its Go and effects work: there is none here.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `CatalogMetadataEntry.requirement: CatalogCitationRequirement?` (nil = the formats do not read the field), with the types in Codebase fit. `CatalogMetadataEntry.isNeeded` is `requirement?.need == .needed`. A wire need of `.unspecified` or an unknown case maps to nil | One annotation per entry, as the wire has it; nil mirrors the wire's absence | Three loose fields on the entry — a fourth copy of the wire's shape |
| D-2 | `GoStore.mapCitationRequirement(_:)` *(new)* and `GoStore.mapCitationOption(_:)` *(new, extracted from `renderCitationPreview`'s closure, which then calls it)*; `mapMetadataEntry` sets `requirement` when `e.hasRequirement`. `mapCitationOption` returns nil for a level this build does not know, as the closure does; `mapCitationRequirement` drops such an option with `compactMap` | Every board read and write reply already passes `mapMetadataEntry`, so one line reaches every board; one option mapper for the preview and the board | A second inline option mapping |
| D-3 | The mark rule lives once, in `MetadataBoardModel.requirementMark(for:)` *(new)*, returning `MetadataRequirementMark?` *(new)*: an entry with a value → nil; no requirement → nil; `.used` → `.used`; `.needed` with `metElsewhere` or an `inherited` value → `.used` (user, 2026-11-28); `.needed` with an alternative that is a field with no level (read nearest-first) and whose entry on this board has a value → `.used`; otherwise `.needed(alternatives:)` with the requirement's alternatives. The case is `needed(alternatives: [CatalogCitationOption])`; tests write `.needed(alternatives: [])` | The engine decides need, chain and above-level answers; the alternative check only keeps a draft board current between Save and the next read, where the engine's `metElsewhere` cannot follow the draft (a live board's reply already includes it) | Re-reading the draft board on each row Save (`getDraftMetadataBoard` takes no draft values); a level-`source` alternative counted on the board (it answers only on the Source's own board, which is live) |
| D-4 | A needed entry offers no ✕ on either empty-row kind, met elsewhere or not. `MetadataDraftHost.dismissSuggestion` returns its entries unchanged for a needed entry, as `sourcemetadata.DismissSuggestion` refuses it (S15-38 D-8) | One rule on both sides; the scenario file pins it | Throwing from the draft host — nothing can reach it once the ✕ is gone, and the scenario's expected draft is null either way |
| D-5 | The row's mark is a `PVBadge` in `MetadataBoardLabel`, under the field name: `.needed` → `L10n.Sources.metadataNeededBadge`, `tone: .warning`; `.used` → `L10n.Sources.metadataUsedBadge`, `tone: .neutral, subtle: true`. The chain hint is a `MetadataBoardCaption` under the suggestion row's input, one line, `L10n.Sources.metadataNeededAlternatives(_ names: String)` over `L10n.CitationFormats.optionNames(_:)` | The brief's inventory (NF-1 – NF-3); the caption view the inherited row already uses | A Callout for the hint (brief non-goal); a new kit mark |
| D-6 | The hint names each alternative by `L10n.CitationFormats.optionName(_:)` *(extracted from `missing`'s inner `name`)*, with no level, joined by `L10n.CitationFormats.missingJoin` (", or "). `optionName(_ option: CatalogCitationOption) -> String` is the field's label, else `builtinName`, else ""; `optionNames(_ chain: [CatalogCitationOption]) -> String` skips an empty name and a name already listed. `missing(_:)` calls `optionName`. The hint is drawn only when `optionNames` is not empty | A field option on a needed head is either read nearest-first (filled here, it answers) or a list-form Source field (shown only on the Source's own board), so a level adds nothing on the board; one naming function for the editor and the board | The editor's "on the Source" form — redundant on the Source page |
| D-7 | Spoken name: `L10n.Sources.metadataRequirementName(field: String, need: CitationNeed?)` *(new)* gives "Jurisdiction, needed for citation" / "URL, used in citation", or the field label alone for nil; the row passes `.needed` for `.needed(alternatives:)` and `.used` for `.used` (`CitationNeed` is a Platform type, so `L10n` imports no Feature type). It replaces `entry.field.label` as the suggestion row input's `accessibilityLabel` and as the `field` argument of `metadataInheritedAccessibility` on the inherited row. The chain hint is the suggestion row input's `accessibilityHint`. The Badge is `accessibilityHidden` | NF-7; the existing inherited label already starts with the field | A second inherited-row string |
| D-8 | The parity file drops `known_divergence: "needed"` from its scenario, and from the `_note` exactly the clause `'needed' (a needed field cannot be dismissed, … S15-39 removes this divergence)` with its joining comma, keeping the rest; `"needed"` stays. `MetadataDraftHostParityTests.File` gains `needed: [String]`, and each start row whose key is in it gets `requirement: CatalogCitationRequirement(need: .needed, metElsewhere: false, alternatives: [])`; `compared`'s `case "needed"` and the `divergence != "needed"` guard go. Go's `TestDraftBoardScenarios` is unchanged | `.cursor/rules/macos-client.mdc`: the file is the record of the rules the draft host mirrors; S15-38 D-17 handed the divergence to this PR | A Swift-only test of the refusal — the engine and the host would drift with both green |
| D-9 | Rows keep the engine's order under today's heading; the Source page's empty state is unchanged | Rule "the engine decides the rows"; brief § 2.2 | Sorting needed rows first in Swift |

**Rules this plan bends.** None. The user's two answers of 2026-11-28 (a needed field met elsewhere draws the used mark with no ✕; the flag shows on every board the engine emits it on) were written into the rule "Boards flag needed fields; the engine decides the rows" and the S15-39 scope entry at planning; the implementer edits neither.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `CatalogCitationRequirement { need: CitationNeed; metElsewhere: Bool; alternatives: [CatalogCitationOption] }` *(new)*, beside `CatalogCitationOption` in `GenealogyStore.swift` | type | `CatalogCitationPreview.missing: [[CatalogCitationOption]]` | A missing chain has no need or met flag; reuses `CatalogCitationOption` for the options |
| `enum CitationNeed: Sendable, Equatable { case needed, used }` *(new)*, beside it | type | `Provenencia_Engine_V1_CitationNeed` (wire) | App types do not expose generated enums (`CitationBuiltin`, `Level` precedent) |
| `CatalogMetadataEntry.requirement`, `isNeeded` *(new)* | field, computed | `CatalogMetadataEntry.inherited` | Extends the entry |
| `GoStore.mapCitationRequirement(_:)`, `GoStore.mapCitationOption(_:)` *(new)* | func | `mapInheritedMetadataValue`; the closure in `renderCitationPreview` | Extracts the closure |
| `enum MetadataRequirementMark: Equatable { case needed(alternatives: [CatalogCitationOption]); case used }` *(new)*, in `MetadataBoardModel.swift` | type | — (searched `Mark`, `Flag`, `requirement` in `Features/MetadataBoard/`) | — |
| `MetadataBoardModel.requirementMark(for:)` *(new)* | func | `MetadataBoardModel.savedEntry(fieldID:)` | The board's one place for the rule (D-3) |
| `L10n.Sources.metadataNeededBadge`, `metadataUsedBadge`, `metadataNeededAlternatives(_:)`, `metadataRequirementName(field:need:)` *(new)* | key | `L10n.Sources.metadataInheritedFrom`, `metadataInheritedAccessibility` | New copy beside the board's |
| `L10n.CitationFormats.optionName(_:)`, `optionNames(_:)` *(new, extracted)* | func | `L10n.CitationFormats.missing(_:)`'s inner `name` | Extracted so the editor and the board name options alike |
| `catalogMetadataEntry(..., requirement:)` parameter *(new)* in `CatalogFixtures.swift` | test helper | the same function's `inherited:` | Extends it |

**Builds on.** `MetadataBoardView` as the one board (rule "One metadata board"); `mapMetadataEntry` as the one entry mapper; the draft-board scenario file (`.cursor/rules/macos-client.mdc`); `PVBadge`; `MetadataBoardCaption`; S15-64's row shape.
**Deletes.** The parity test's `case "needed"` and its `divergence != "needed"` guard; the scenario's `known_divergence: "needed"` and the `_note` sentence naming it; the inline option closure in `renderCitationPreview`; `missing(_:)`'s inner `name` function.
**Next adds.** S15-40 filters the Artifact's entries with `requirementMark(for:)`'s `.needed` (or the same rule over a list's entries). S15-41's unknown value is a value, so it clears the mark with no change here. S15-66 adds its hint as one more caption under the same row. S15-73 joins the chain hint with the description through its board hint helper. S16-75's Copy board gets the marks through `getDraftMetadataBoard`.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A needed row with no ✕ | `MetadataBoardSuggestionRow`, `MetadataBoardInheritedRow` | The row is still removed by a reload that drops it (`resetDrafts`); the Source page's refused dismiss can no longer be reached |
| A needed field the Source lacks, on every sheet of that Source | `ArtifactSheet`, `SourceGraphFormDialog`, `CitationMetadataSheet` | Flagged there too (user, 2026-11-28); filling it in a sheet saves with the sheet |
| An entry with a requirement added through Add field | `MetadataDraftHost.set` | Cannot happen: a needed or used head is always on the board, and `fieldComboOptions` excludes board fields. A field appended by `set` has `requirement` nil |
| An entry whose wire need this build does not know | `mapCitationRequirement` | nil: no mark |

### Scale

At a board of 30 entries, each needed head with up to 3 alternatives, `requirementMark(for:)` scans the board once per alternative: under 100 comparisons per row, under 3,000 per board draw. It builds the set of valued field ids once per call. No write, read, cache key or invalidation changes.

### Edges

- **Assumptions.** `requirement` is per entry and the engine dedupes alternatives (`AppendOptions`), so the hint lists each once (T-2). `metElsewhere` is set only on a needed head (wire comment), so `.used` with `metElsewhere` cannot occur; the rule ignores it there. An inherited value means the nearest level above holds the head, so the engine sets `metElsewhere` on a needed head whenever `inherited` is set; the rule reads either (T-2).
- **Neighbors.** Needed, empty, not met → flag (T-2). Needed, empty, met by the Source (inherited) → used (T-2, AC-2.3). Needed, empty, met by a later option → used (T-2, AC-1.3). Needed, with a value → nil (T-2). Used, empty → used, ✕ kept (T-2, AC-2.1). Used, dismissed → gone, as today (AC-2.2). None → nil, as today. A needed head dismissed in an earlier layout → the engine emits it; drawn flagged with no ✕ (the read's rule, S15-38).
- **Removed inputs.** Clearing a valued needed field on a live board → the reply re-annotates it (AC-1.4). Clearing an alternative in a draft → the head's mark follows the alternative's value on the board (T-2). Clearing, in a draft, an alternative the owner had stored before the sheet opened → the head stays Used until Save and reopening, because the read's `metElsewhere` already counted it. In the seed only Court report's Page and Pages form such a chain off the Source page (seed sweep below); accepted, Out.
- **Real data.** The 29 seeded types' formats (a temporary `citationformat.Requirements` dump at the planning base): 22 types need one to three fields (census, the certificates, Record book, Case file and Statute Jurisdiction; Book Author and Author for sorting ← Author; Journal article and Broadcast also Published in; Court report Published in and Page ← Pages; Interview, Correspondence and Newspaper item also the Source date, S15-42); 7 need none (Passenger list, Border crossing, Family Bible, Photograph, Private papers, GEDCOM file, Map). Chains with alternatives: Author for sorting ← Author (list form, Source board only) and Page ← Pages (every board). Every type uses 4 – 20 fields, so the used mark sits on most empty suggestions (brief NF-3).
- **Untrusted size.** None — the entries come from the engine's board read, bounded by the board's rows.

### Schema

None — no catalog change.

### Go core

None — the engine already sends the annotation (S15-38). Only the scenario JSON's divergence line changes (D-8); `TestDraftBoardScenarios` runs unchanged.

### FFI

None — no proto change; `engine.pb.swift` already holds `requirement`.

### macOS

From the brief's inventory. The board is not agreed: when it is, the planner copies its decisions here and in D-5, and the plan moves to Planned.

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Needed flag | `PVBadge(L10n.Sources.metadataNeededBadge, tone: .warning)` | `MetadataBoardLabel` gains `mark: MetadataRequirementMark?` | Under the field name; `accessibilityHidden(true)`; identifier `<prefix>.<fieldID>.needed` |
| Used mark | `PVBadge(L10n.Sources.metadataUsedBadge, tone: .neutral, subtle: true)` | the same | Identifier `<prefix>.<fieldID>.used` |
| Chain hint | `MetadataBoardCaption(…, lineLimit: 1)` | `MetadataBoardSuggestionRow`, under its `PVInput`, above its error | Drawn for `.needed` with alternatives only; identifier `<prefix>.<fieldID>.alternatives` |
| No ✕ | — | `MetadataBoardSuggestionRow` and `MetadataBoardInheritedRow` draw `MetadataBoardSuggestionDismiss` only when `!entry.isNeeded` | The inherited row's `restingTrailing` is `EmptyView` then |
| Label | `MetadataBoardLabel(…, mark: MetadataRequirementMark? = nil)` | `MetadataBoardView.swift` | A `VStack(alignment: .leading)` of the name then the Badge; nil (saved rows) draws today's label. The inherited row's label stays `accessibilityHidden`; the Badge shows at rest and in edit. Spacing and the input's alignment come from the agreed board |
| Mark source | `MetadataBoardModel.requirementMark(for:)` | `MetadataBoardView`'s `ForEach(board.suggested)` passes it to both rows | Saved rows draw none |

States: an empty board as today; a board with every row marked draws them all; a saved row never shows a mark. Accessibility per D-7.

### Strings

L10n keys *(new)*, in `L10n.Sources` beside `metadataInheritedFrom`, each in `Localizable.xcstrings`:

| Key | English |
| --- | --- |
| `sources.page.metadataNeededBadge` | "Needed" |
| `sources.page.metadataUsedBadge` | "Used" |
| `sources.page.metadataNeededAlternatives` | "Or fill in %@" (argument: the names, joined with ", or ") |
| `sources.page.metadataRequirementNeeded` | "%@, needed for citation" |
| `sources.page.metadataRequirementUsed` | "%@, used in citation" |

`metadataRequirementName(field:need:)` picks the last two. Changed: none. The board may refine the words; the plan copies the board's.

## 7. Steps

**STEP-1 — Carry the requirement into Swift**
Files: `macos/App/Platform/GenealogyStore.swift`, `macos/App/Platform/GoStore.swift`, `macos/ProvenenciaTests/CatalogFixtures.swift`, `macos/ProvenenciaTests/MetadataRequirementMappingTests.swift` *(new)*. Skill: `add-swift-test`.
Do: D-1, D-2. Make `mapMetadataEntry` and the two new mappers `static` (not `private`) so T-1 calls them, as `SourceMappingTests` calls its mappers. Add `requirement: CatalogCitationRequirement? = nil` to `catalogMetadataEntry`.
Check: T-1 passes; `xcodebuild test` builds with no warning.

**STEP-2 — The mark rule**
Files: `macos/App/Features/MetadataBoard/MetadataBoardModel.swift`, `macos/ProvenenciaTests/MetadataBoardModelTests.swift`.
Do: D-3.
Check: T-2 passes.

**STEP-3 — A needed field cannot be dismissed in a draft**
Files: `macos/App/Features/MetadataBoard/MetadataDraftHost.swift`, `core/database/sourcemetadata/testdata/draft_board_scenarios.json`, `macos/ProvenenciaTests/MetadataDraftHostParityTests.swift`, `macos/ProvenenciaTests/MetadataDraftHostTests.swift`.
Do: D-4, D-8.
Check: T-3, T-4 pass; `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcemetadata -run TestDraftBoardScenarios` passes.

**STEP-4 — Copy**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/ProvenenciaTests/L10nResolutionTests.swift`. Skill: `add-localized-string`.
Do: § 6 Strings; D-6 (`optionName`, `optionNames`, `missing` calling them).
Check: T-5 passes; `python3 scripts/check-localizable-xcstrings.py` passes; the format editor's missing line reads as before (its tests stay green).

**STEP-5 — Draw the marks on every board**
Files: `macos/App/Features/MetadataBoard/MetadataBoardView.swift`. Skill: `add-ui-component`.
Do: § 6 macOS; D-5, D-7, D-9.
Check: the app builds; manual check 1 – 6 on the board's frames.

**STEP-6 — Docs**
Files: `docs/deployment-plan/spike-15/completed.md`, `deployment-plan.md` (map row status), this plan (status), `design/S15-D20-boards-flag-needed-fields.md` → `design/archive/`, `design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py` on the changed docs passes; links resolve.

**STEP-7 — Version**
Files: `VERSION`, `core/version.go`, `MARKETING_VERSION` in `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: the next minor.
Check: `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Flag an empty field the citation needs on every metadata board."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `MetadataRequirementMappingTests.swift` `mapsTheRequirement` *(new)* | Wire entry with need NEEDED, `met_elsewhere` true, alternatives [field `author` level "source", builtin "date" level "source"] → `requirement` {.needed, true, [option field author level .source, option builtin .sourceDate level .source]}; need USED → {.used, false, []}; no requirement → nil; need UNSPECIFIED → nil; `renderCitationPreview`'s missing chain mapping gives the same options (call `mapCitationOption` on the same wire option) | D-1, D-2 |
| T-2 | Swift | `MetadataBoardModelTests.swift` `requirementMarkFollowsTheRule` *(new)*, table over a `MetadataDraftHost` | needed, empty → `.needed(alternatives: [])`; needed, empty, alternatives [Pages] → `.needed(alternatives: [Pages])`; then set Pages through `board.save` → `.used`; clear Pages → `.needed(alternatives: [Pages])`; needed with `metElsewhere` → `.used`; needed, inherited, `metElsewhere` false → `.used`; needed with a value → nil; used, empty → `.used`; used with a value → nil; no requirement → nil; an alternative with level `.source` valued on the board → `.needed` (not counted) | D-3, AC-1.3, AC-1.6, AC-2.1, AC-2.3, AC-2.5 |
| T-3 | Swift | `MetadataDraftHostTests.swift` `dismissingANeededFieldChangesNothing` *(new)* | Entries built with `catalogMetadataEntry(…, suggested: true, requirement:)`, so `isEmptyRow` holds. Needed empty suggestion: `board.dismissSuggestion` → entries unchanged, `draft` nil, `isChanged` false; needed with `metElsewhere` and inherited → the same; used empty suggestion → removed and listed dismissed (as `dismissOnlyEmptySuggestions`) | D-4, AC-2.2 |
| T-4 | Swift | `MetadataDraftHostParityTests.swift` `scenariosMatchTheEngine` (changed) | Every scenario, "dismissing an empty needed suggestion is refused" included, compares board and draft with no needed skip | D-8 |
| T-5 | Swift | `L10nResolutionTests.swift` `boardRequirementCopy` *(new)* | `metadataRequirementName(field: "Jurisdiction", need: .needed)` → "Jurisdiction, needed for citation"; `.used` → "URL, used in citation"; nil → "URL"; `metadataNeededAlternatives(L10n.CitationFormats.optionNames([Folio, Pages]))` → "Or fill in Folio, or Pages"; `optionNames` over [Pages, Pages, an option with neither field nor built-in] → "Pages"; `L10n.CitationFormats.missing` over a two-option chain reads as before | D-6, D-7, AC-3.1, AC-3.2 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `MetadataDraftHostParityTests`, `MetadataDraftHostTests` `dismissOnlyEmptySuggestions` and `anEmptyHeadTheReadReturnedClearsToEmptyAndDismisses` (their fixtures have no requirement, so they keep their behavior), the format editor's tests over `L10n.CitationFormats.missing`, `TestDraftBoardScenarios`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it); "hides it until S15-39" and "S15-39 removes this divergence" gone from the parity test and the scenario file
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory and the agreed board; no new kit primitive
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

Use a new project (the seed's census, Book and Court report types). Make: Source "1880 census, Calder County" (Census) with Creator and Provider and no Jurisdiction, one Artifact, one graph and one Citation; Source "History of Calder County" (Book) with no Author; Source "Kansas Reports, vol. 12" (Court report) with Published in "Kansas Reports" and one Citation.

1. The census Source page: Jurisdiction flagged, no ✕; the other empty suggestions Used, each with ✕ (AC-1.1).
2. Save "Calder County" in Jurisdiction: a saved row, no mark. Trash it, confirm: flagged again. Save it again (AC-1.4).
3. The Book Source page: Author flagged; Author for sorting flagged with "Or fill in Author". Save Author "Ashby, Ruth": Author for sorting Used, no ✕ (AC-1.2, AC-1.3).
4. The census Artifact's sheet: Jurisdiction inherited with Used and no ✕; URL Used with ✕. Dismiss URL, Save: no error. Override Jurisdiction "Ottawa County", then trash it: Used again; Cancel (AC-2.1 – AC-2.4).
5. Clear the census Source's Jurisdiction; open the Artifact sheet, Add an Artifact, the graph form and the Citation's metadata sheet: Jurisdiction flagged on each (AC-1.5).
6. The Kansas Reports Citation's metadata sheet: Page flagged with "Or fill in Pages"; type "112" in Pages, row Save: Page shows Used (AC-1.6).
7. VoiceOver on step 1's Jurisdiction input, step 3's Author for sorting input (before Author), and step 4's inherited Jurisdiction value (AC-3.1 – AC-3.3).
8. Repeat steps 1 and 4 with the window at 2560pt: nothing moves; a typed value survives the resize (NF-W1).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The used mark is loud: it sits on most empty rows | The brief asks the board to keep it as quiet as a caption (NF-3); the plan copies the board's tone |
| A long field name and the Badge overflow the 132pt label column | Frame D20-10; the label wraps and the Badge sits under it |
| Extracting `optionName` changes the format editor's missing line | T-5's `missing` case and the editor's tests |

**Stop and report if:**

- The agreed board draws the mark as something other than a kit Badge in the label column, puts the hint outside the row, adds a heading or a new row type, or needs a new kit primitive (then the planner refreshes D-5 and § 6 macOS).
- S15-73 has landed (its map row reads Landed): the chain hint joins its board hint helper (map scope "Context"), which this plan does not name.
- S15-41, S15-51 or S15-66 has landed and changed `MetadataBoardSuggestionRow`, `MetadataBoardInheritedRow` or `MetadataBoardLabel` so a § 4 row is untrue.
- `mapMetadataEntry` is not the only place a `MetadataWorkspaceEntry` becomes a `CatalogMetadataEntry`.
- A board entry reaches Swift with `met_elsewhere` true on a used requirement, or with duplicated alternatives.
- T-4 fails on a scenario other than the needed one.

## 12. Open questions

None.

## 13. PR

**Title:** S15-39 — Metadata boards flag needed fields
**Body:** objective in one sentence; what shipped against US-1 – US-3; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-39-boards-flag-needed-fields.md`.
