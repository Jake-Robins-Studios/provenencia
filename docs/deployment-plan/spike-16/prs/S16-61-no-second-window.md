# S16-61 — Nothing in the app waits on a second window

**Status:** Landed in [#886](https://github.com/Jake-Robins-Studios/provenencia/pull/886) (2026-11-18)
**Spike / slice:** Spike 16 · Slice 7a — One window
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the states this PR removes have no way in once S16-60 landed, and the one kept notice changes copy only)
**Board:** —
**Depends on:** S16-60 (landed [#884](https://github.com/Jake-Robins-Studios/provenencia/pull/884))
**Blocks:** — (lands before S16-59, Spike 15's S15-25, S15-39 and S15-41; order, not a dependency)
**Branch:** `s16-61-no-second-window`
**Version bump:** patch — it changes shipped app code and copy ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md)
**Rules that bind:** `.cursor/rules/macos-l10n.mdc`, `.cursor/rules/swift-tests.mdc`, `.cursor/rules/macos-client.mdc`
**Context:** working rules "(Batch 7) One workspace window, and closing it quits", "(Batch 7) Nothing is built for a second window"; [S15-34 plan](../../spike-15/prs/S15-34-artifact-edit-sheet.md) D-13, AC-3.5, AC-5.5; [S15-10 plan](../../spike-15/prs/S15-10-artifact-sheet-add-mode.md) AC-3.4, AC-4.4, T-11
**Planned:** 2026-11-18 against `main` @ `a8b782880`
**Landed:** D-5 copy changed in review (UX-1, user 2026-11-18): "%@ is now suggested by this type."
**Review:** [`S16-61-no-second-window.review.md`](S16-61-no-second-window.review.md) — Fits with changes, Ready

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

S16-60 locked the app to one workspace window. This PR removes the code and the tests that exist only for a change another window makes while a sheet is open, rewords the one notice a single window still reaches, and fixes the comments and the UX review lens that name another window. Plans and reviews then stop spending time on a second window.

**Why now.** Batch 7 lands before Batch 6 (user, 2026-11-18), so no Batch 6 plan or review reads these paths as a pattern to follow.

**What stays.** Everything one window still reaches: Back or Forward to a deleted or merged entity, a cached page shown while it refreshes (stale-while-revalidate) and the write made on it before the refresh lands, a page left and returned to after a write elsewhere in the window, relaunch restoring history, and engine refusals. A survey of `macos/App` and `macos/ProvenenciaTests` on 2026-11-18 found that `WorkspaceSession`'s follows and stale marks, `CatalogRowPresence`, `leavesForSectionRoot`, `SourcePageContext.fail`'s `gone`, `ConclusionDetailPresentation.gone`, `SourceTypePageModel.isGone`, `EvidenceGraphModel.graphIsGone`, `PromoteModel`'s `promote.stale` branch, `DeleteImpactFlow.refreshAfterInUse`, `MetadataModel` and `PropertiesModel` selection sync, and the link-lock re-reads after a refused save all serve one window. They stay, with their tests.

## 2. User stories

**US-1.** As a contributor, when I read the Source page and its sheets, I find no code path that only a second window can reach, so I do not extend one by copying it.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | The STEP-5 and STEP-6 `rg` checks | No hit |
| AC-1.2 | The STEP-1 and STEP-2 `rg` checks | No hit |
| AC-1.3 | The test suite | `artifactGoneClosesTheSheet`, `anAddSheetCloseRule`, `sheetSaveSkipsAGraphDeletedDuringEdit`, `aGraphMadeWhileAddingIsLinked`, `sheetSaveKeepsAGraphMadeDuringEdit`, `deletedSourceDuringACoverRefreshLeaves` and `artifactDeletedElsewhereIsDropped` are gone; every other test passes |

**US-2.** As a researcher, when I change a Source's type while the metadata Add field row has a field picked that the new type suggests, the row clears its pick and tells me the field is now on the board, so I pick another.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Add row open with Film number picked and "F-7" typed; change the type to one whose suggestions include Film number | The row's field is cleared, "F-7" stays, and the row reads "Film number is now on the board. Pick another field." (VoiceOver announces it) |
| AC-2.2 | The same, then pick Roll | The notice goes |

**US-3.** As a researcher, the Artifact sheet (edit and add) works as before: it opens, saves its label, description, graph links and copy details, keeps its draft after its own create when the file fails, and keeps a graph that a Citation holds checked and locked.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Edit an Artifact, change its graph checks, Save | `updateArtifact` sends the checked graphs in list order (`sheetCitationsLockHoldsUntilTheLinkIsSaved`) |
| AC-3.2 | Add an Artifact on a Source with one graph | `createArtifact` sends that graph (`addArtifactOnOneGraphShowsTheGroup`) |
| AC-3.3 | Add an Artifact whose file ingest fails | The sheet stays open with its draft, as today (the add-sheet ingest tests, `SourcePageModelTests` 522–628) |

## 3. Scope

| In | Covered by |
| --- | --- |
| Remove the Artifact sheet's close when its Artifact leaves the page | STEP-1, AC-1.2 |
| Remove the Artifact sheet's handling of a graph deleted or made since it opened | STEP-2, AC-1.2, AC-3.1, AC-3.2 |
| Delete the seven second-window tests | STEP-1, STEP-2, STEP-3, AC-1.3 |
| Reword the Add row's taken notice and test it through a type change | STEP-4, AC-2.1, AC-2.2 |
| Reword comments and string comments that name another window or a deletion elsewhere | STEP-5, AC-1.1 |
| Rewrite the UX lens's round-trip check and its Known trap | STEP-6, AC-1.1 |
| Version bump, docs | STEP-7, STEP-8 |

| Out | Home |
| --- | --- |
| Not-found handling, leave-on-deleted, `WorkspaceSession` follows and stale marks, list merges, Promote's stale branch, delete-impact refresh, selection sync on Metadata and Properties | Not planned: one window reaches each (§1 What stays) |
| The link-lock re-reads after a refused save (`ArtifactSheetModel.save`, `SourceGraphFormModel.save`) | Not planned: an engine refusal reaches them in one window; only their comments change (STEP-5) |
| `SourceGraphFormDraft`'s exclusion-based state and `SourceCopyModel.artifactIDsToCopy`'s exclusion-based list | Not planned: exclusions are how a checklist stores its state, not a second-window guard; only their comments change (STEP-5) |
| Landed plans, ship logs, archived briefs and `completed.md` paragraphs that mention another window | Not planned: they are history |
| Multiple windows and sync | [`docs/ideas/multiple-windows-and-sync.md`](../../../ideas/multiple-windows-and-sync.md) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Sheet close on drop | `macos/App/Features/Sources/SourceArtifactsSection.swift` `workspaceChanged()` (86–96) | Closes the open Artifact sheet and sets a toast when its `artifactID` is no longer in `items`. The sheet is modal and has no delete, and a save from it keeps its Artifact, so only another window reaches it |
| Its call | `macos/App/Features/Sources/SourcePageModel.swift` `apply(_:)` (152–176) | Lines 170–174 compare `shown?.artifacts` with `workspace.artifacts` and call `artifacts.workspaceChanged()`. `shown` is also read for `metadata.resetIfChanged` (164–166), which stays |
| Toast strings | `macos/App/Platform/L10n.swift` `L10n.Sources.toastArtifactGoneTitle`, `toastArtifactGoneBody(label:)` (6935–6947); `Localizable.xcstrings` `sources.page.toastArtifactGoneTitle`, `sources.page.toastArtifactGoneBody` | "Artifact no longer here" / "“%@” was deleted or moved in another window." |
| Graphs deleted since open | `macos/App/Features/Sources/ArtifactSheetModel.swift` `liveGraphIDs` (170–174), read by `checkedGraphIDs` (183–189) | Filters the captured `graphIDs` to those still in the session's graph list. The sheet is modal, so no graph is deleted while it is open |
| Graphs made since open | `ArtifactSheetModel.swift` `savedGraphIDs` (207–215), read by the edit save (298) and the create (380) | Appends graphs of this Source that are not in `graphIDs` and link the Artifact (in add mode, every such graph). Only another window makes a graph while the sheet is open |
| Graph list | `ArtifactSheetModel.swift` `graphs` (190–194) | `compactMap` over `graphIDs` through `session.evidenceGraph(id:)`; the lookup stays, its comment names a deletion since open |
| Lock re-read comment | `ArtifactSheetModel.swift` `save()` (329–330) | "a Citation may have taken the Artifact since the sheet opened"; the re-read after a refusal stays |
| Graph form comments | `macos/App/Features/Sources/SourceGraphFormModel.swift` `SourceGraphFormDraft` (4–7), `save()` (231–233) | "an Artifact added while the form is open starts checked"; "the engine's locks may have moved since the form opened" |
| Copy comment | `macos/App/Features/Sources/SourceCopyModel.swift` `artifactIDsToCopy` (96–97) | "A deleted Artifact drops out and a new one starts checked" |
| Taken notice | `macos/App/Features/Sources/MetadataBoardModel.swift` `MetadataBoardAddRow.takenFieldLabel` (10–12), `resetDrafts()` (73–84); `MetadataBoardView.swift` (189–193); `L10n.Sources.metadataAddRowFieldTaken(field:)` (6747–6753) | Set when a reload puts the picked field on the board. One window reaches it: `SourceIdentitySection.save` (208–237) calls `context.applySource(…, typeChanged:)`, the workspace refetches, and `SourcePageModel.apply` calls `metadata.resetIfChanged`. Copy: "%@ was added in another window. Pick another field." |
| Comments naming another window | `SourcePageContext.swift` `gone` (33), `fail(_:)` (48), `SourcePageModel.swift` `gone` (79), `Platform/ConclusionVocabulary.swift` (314), `Platform/FakeStore.swift` `sourceNotFound` (697), `core/database/sources/sources.go` `ErrNotFound` (29–30); string comments in `L10n.swift` (6085, 8182, 9914, 11329) and the matching `Localizable.xcstrings` comments | Describe `sources.not_found` and the gone notices as a second window's doing |
| UX lens | `.agents/skills/review-pr/lenses/ux.md` (52–55, 150–152) | "ask what happens when another window deletes or merges it meanwhile"; Known trap "After another window deleted an item the page held" |
| Tests | `macos/ProvenenciaTests/SourcePageModelTests.swift` `artifactGoneClosesTheSheet` (2456), `anAddSheetCloseRule` (1921), `sheetSaveSkipsAGraphDeletedDuringEdit` (2388), `aGraphMadeWhileAddingIsLinked` (1699), `sheetSaveKeepsAGraphMadeDuringEdit` (2292), `deletedSourceDuringACoverRefreshLeaves` (2788); `SourceCopyModelTests.swift` `artifactDeletedElsewhereIsDropped` (256) | Each changes the store or the session behind an open sheet or dialog, or deletes the Source between the page's own write and the refresh that follows it, as only a second window would |
| Sheet label | `ArtifactSheetModel.swift` `openedLabel` (34, set at 94, 100, 389) | Read only by `workspaceChanged()`'s toast |
| Tests that stay | `MetadataBoardModelTests.swift` `addRowTakenFieldSaysSo` (158), `pickingAFieldClearsTheNotice`; `SourcePageModelTests.swift` `saveTypeUpdatesCommittedType` (124), `privateSwitchSavesRevertsAndKeepsEdits` (2665, the shape T-1 copies), `addArtifactOnOneGraphShowsTheGroup` (1640), `sheetCitationsLockHoldsUntilTheLinkIsSaved` (2203), `sheetMarksAnArtifactInNoGraph`, `sheetSaveReloadFailureOffersReadAgain`, the add-sheet ingest tests (522–628) | Unchanged, except `addRowTakenFieldSaysSo` if it asserts copy (it does not today) |

**Precedent.** `b92235b0e` ("Remove the unused stale policy from the catalog query registry.") removed the unused `CatalogQueryStalePolicy` with its tests. Copy that shape: delete the code, its strings and its tests together, and `rg` the names after.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `SourceArtifactsSection.workspaceChanged()` and its call in `SourcePageModel.apply` go; `shown` stays for `metadata.resetIfChanged` | Batch 7 map review K7-1 found no one-window path: the sheet is modal and has no delete, a save keeps its Artifact, a failed ingest keeps the made one, and S15-25's move closes the sheet itself | Keeping it as a safety net — an untestable path is code the rule says goes |
| D-2 | `liveGraphIDs` goes: `checkedGraphIDs` reads `graphIDs ?? []` | No graph is deleted while the modal sheet is open | Keeping the filter — it guards nothing in one window |
| D-3 | `savedGraphIDs` goes: the edit save and the create send `checkedGraphIDs` | No graph is made while the sheet is open; S15-10 AC-3.4 ("a graph made while the sheet is open starts linked") and its test go with it (user, 2026-11-18: remove what only a second window reaches; the map's S16-61 entry is updated) | Keeping AC-3.4 — the map's first cut kept it as harmless, which the user overrode |
| D-4 | `graphs` keeps its `compactMap` lookup; its comment says it reads the captured ids from the session | The lookup is how it gets the graph values | Force-unwrapping — a crash for no gain |
| D-5 | The taken notice stays. Copy: "%@ is now on the board. Pick another field." (`sources.page.metadataAddRowFieldTaken`, same key) | A type change reaches it in one window (K7-1); a key keeps its name when only its English changes (`add-localized-string`) | A new key — churn for the same meaning |
| D-6 | The type-change path is tested in `SourcePageModelTests` *(new test)*, through `identity.saveType()` with the store's source metadata seeded with the new type's suggested Film number entry | That is the path that reaches it; the board-level test already covers `resetDrafts` | A board-only test — it would not show the page reaches it |
| D-7 | The link-lock re-reads after a refused save stay; their comments say the engine's refusal names the graph that keeps the Artifact | A refused save reaches them in one window (locks loaded before the save may be read again) | Removing them — they serve a refusal |
| D-8 | `artifactDeletedElsewhereIsDropped` goes; `artifactIDsToCopy` stays | The Copy Source dialog is modal; the exclusion list is how the checklist stores its state, and other tests cover the list | Keeping the test — it simulates a second window |
| D-10 | `deletedSourceDuringACoverRefreshLeaves` goes; the page's not-found handling on that refresh stays | The refresh runs right after the page's own successful Artifact delete, so only another window deletes the Source in between; the handling is the shared `fail` path, which `writeToADeletedSourceLeaves` and the other gone tests keep covering | Keeping the test — it simulates a second window |
| D-11 | No guard is added to `SourceArtifactsSection.openSheet` for a delete whose impact read is still in flight | The delete confirm (`pvDeleteImpact` → `pvConfirm` / `pvSheet`) is presented by the page beneath the modal Artifact sheet, so it cannot be confirmed until the sheet closes; the race is a request, not a delete under the sheet. Manual check step 3 confirms it | A guard — code for a case that cannot delete anything |
| D-9 | The UX lens text (STEP-6) is fixed here, word for word | The lens is what reviewers read; vague wording would let a reviewer ask about a second window again | Leaving it to the implementer |

**Rules this plan bends.** None. D-3 changes the map's scope entry for S16-61 (S15-10 AC-3.4 no longer stays); the map is updated in the same commit as this plan.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `SourcePageModelTests.typeChangeClearsTheAddRowsTakenField` *(new)* | test | `saveTypeUpdatesCommittedType`, `MetadataBoardModelTests.addRowTakenFieldSaysSo` | It reuses both: the first's setup and type save, the second's assertion |

**Builds on.** `saveTypeUpdatesCommittedType`'s fixtures (`makeStore`, `photoType()`, `makeModel`), `FakeStore.metadataByOwner`.
**Deletes.** `SourceArtifactsSection.workspaceChanged()`; `SourcePageModel.apply`'s artifacts comparison and its comment; `ArtifactSheetModel.liveGraphIDs`, `ArtifactSheetModel.savedGraphIDs`; `L10n.Sources.toastArtifactGoneTitle`, `L10n.Sources.toastArtifactGoneBody(label:)` and their two catalog keys; tests `artifactGoneClosesTheSheet`, `anAddSheetCloseRule`, `sheetSaveSkipsAGraphDeletedDuringEdit`, `aGraphMadeWhileAddingIsLinked`, `sheetSaveKeepsAGraphMadeDuringEdit`, `deletedSourceDuringACoverRefreshLeaves`, `artifactDeletedElsewhereIsDropped`; `ArtifactSheetModel.openedLabel`. The helper `openAddSheetAfterClosing` stays (the test above `anAddSheetCloseRule` calls it).
**Next adds.** None named. A return to several windows rebuilds the removed paths from commit announcements ([idea](../../../ideas/multiple-windows-and-sync.md) point 7).

### Reach

None — no new path into existing code. Removing `workspaceChanged` removes a way out of the sheet that nothing in one window takes.

### Scale

None — no write, list or loop changes.

### Edges

- **Assumptions.** The Artifact sheet is modal and has no delete; the graph form and the Copy Source dialog are modal. Held by S16-60's single window; stop condition below if a sheet can be shown over another sheet.
- **Neighbors.** A save from the sheet patches the page and its Artifact stays (AC-3.1); a create whose file fails keeps the sheet (AC-3.3, the ingest tests at 522–628).
- **Removed inputs.** A graph that appears or goes behind an open sheet: no longer handled; only another window made one.
- **Real data.** None — no table-driven rule.
- **Untrusted size.** None — no list read from data the app did not write.

### Schema

None — no catalog change.

### Go core

None — only the `ErrNotFound` comment in `core/database/sources/sources.go` changes.

### FFI

None —

### macOS

None — no new view or component. `MetadataBoardView`'s notice keeps its caption style and `.pvAnnounce`.

### Strings

- Changed: `sources.page.metadataAddRowFieldTaken` → "%@ is now on the board. Pick another field."; comment "Notice under the inline Add field row when a change of the Source's type put its picked field on the board; argument is the field label".
- Removed: `sources.page.toastArtifactGoneTitle`, `sources.page.toastArtifactGoneBody`.
- Comments only (copy unchanged): `sources.page.deletedNotice` → "Notice after leaving a Source page whose Source was deleted (Back to it, or a write on its cached page); argument is the Source title"; `sourceTypes.page.goneNotice` → "Notice after leaving a Source type page whose type was deleted; argument is the type label"; `conclusions.person.gone` → "Toast and notice when a Person page's person was deleted or merged"; `error.sources.not_found` → "FFI error sources.not_found: the Source was deleted".

## 7. Steps

**STEP-1 — The Artifact sheet no longer closes when its Artifact leaves the page**
Files: `SourceArtifactsSection.swift`, `SourcePageModel.swift`, `ArtifactSheetModel.swift`, `L10n.swift`, `Localizable.xcstrings`, `SourcePageModelTests.swift`. Skill: `add-localized-string`.
Do: delete `workspaceChanged()`; delete lines 170–174 of `SourcePageModel.apply` (the comment and the `if`); delete `toastArtifactGoneTitle`, `toastArtifactGoneBody(label:)` and their two catalog entries; delete `ArtifactSheetModel.openedLabel` and its three assignments; delete `artifactGoneClosesTheSheet` and `anAddSheetCloseRule` (D-1). Delete `deletedSourceDuringACoverRefreshLeaves` (D-10).
Check: `rg -n "workspaceChanged|toastArtifactGone|openedLabel" macos` finds nothing; `python3 scripts/check-localizable-xcstrings.py` passes.

**STEP-2 — The sheet's graph list is the one it opened with**
Files: `ArtifactSheetModel.swift`, `SourcePageModelTests.swift`.
Do: delete `liveGraphIDs`; `checkedGraphIDs` passes `ids: graphIDs ?? []` (D-2). Delete `savedGraphIDs`; lines 298 and 380 send `checkedGraphIDs` (D-3). The `graphs` comment reads "The graphs the sheet offers, read from the session in the order they were captured." (D-4). Delete `sheetSaveSkipsAGraphDeletedDuringEdit`, `aGraphMadeWhileAddingIsLinked`, `sheetSaveKeepsAGraphMadeDuringEdit`.
Check: `rg -n "liveGraphIDs|savedGraphIDs" macos` finds nothing; `scripts/check-pr.sh` passes its Xcode tests, including the remaining sheet tests (AC-3.1 – AC-3.3).

**STEP-3 — The Copy Source test for a deleted Artifact goes**
Files: `SourceCopyModelTests.swift`, `SourceCopyModel.swift`.
Do: delete `artifactDeletedElsewhereIsDropped` (D-8). `artifactIDsToCopy`'s comment reads "The original's Artifacts in workspace order, minus the unchecked ones."
Check: `SourceCopyModelTests` passes (via `scripts/check-pr.sh`).

**STEP-4 — The taken notice reads for one window, tested through a type change**
Files: `L10n.swift`, `Localizable.xcstrings`, `MetadataBoardModel.swift`, `SourcePageModelTests.swift`. Skills: `add-localized-string`, `add-swift-test`.
Do: write `typeChangeClearsTheAddRowsTakenField` *(new)* first. Types as in `saveTypeUpdatesCommittedType` (`photoType()` and `t2` Census, set on `store.sourceTypesByProject[projectDir]`). Session as in `privateSwitchSavesRevertsAndKeepsEdits`, plus the location apply from `resourceDeleteDoesNotReloadTheDeletedSource` (1251): `let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)`, `session.apply(location: WorkspaceLocation.sourcePage(sourceId: sourceID))` so the workspace key is visible and reloads, `let model = makeModel(store: store, session: session)`, `await model.warmFromSession()`. Then `model.metadata.openAddRow()`, `pickAddRowField("film")`, `setAddRowValue("F-7")`; seed `store.metadataByOwner[MetadataOwner(level: .source, id: sourceID)] = [catalogMetadataEntry(catalogMetadataField("film", label: "Film number"), suggested: true)]` (the helpers `SourceGraphFormModelTests` uses at 362); `model.identity.beginEditType()`, `typeDraftID = "t2"`, `await model.identity.saveType()`, `await session.settleWrites()`; then `model.sync(from: try #require(session.queryHandle(.sourceWorkspace(project: session.projectKey, sourceId: sourceID))))`, as the view's status `onChange` does. Expect on `model.metadata.addRow`: `addRow?.fieldID == ""`, `addRow?.value == "F-7"`, `addRow?.takenFieldLabel == "Film number"`, and `L10n.Sources.metadataAddRowFieldTaken(field: "Film number") == "Film number is now on the board. Pick another field."` (D-6). Run it: the copy assertion fails. Then change the string and its comment (§6 Strings, D-5), and `MetadataBoardAddRow.takenFieldLabel`'s doc comment to "The label of the field the row had picked when a reload put it on the board (a change of the Source's type suggested it); the row says so until a field is picked again."
Check: the new test passes; `addRowTakenFieldSaysSo` and `pickingAFieldClearsTheNotice` pass.

**STEP-5 — Comments name what one window meets**
Files: `SourcePageContext.swift` (33–34: "The notice to show when a write found this Source deleted; the page leaves for the Sources list while it is set."; 48: the second sentence starts "A Source deleted while this page was cached sets `gone`", the rest of the comment unchanged), `SourcePageModel.swift` (79: "The notice a write set when it found this Source deleted; the page leaves while it is set."), `ArtifactSheetModel.swift` (329–330: "Read the locks again: the engine's refusal says which graph keeps the Artifact."; line 331, the re-read, stays), `SourceGraphFormModel.swift` (4–7: drop the clause "so an Artifact added while the form is open starts checked" and keep the rest; 231–233: "Any refusal of an edit: read the engine's locks again and keep the refusal in view."), `Platform/ConclusionVocabulary.swift` (314: "`sources.not_found` a deleted Source"), `SourcePageContext.swift` (60–61: "False when the Source was deleted and the page is leaving, so the caller returns without writing state."), `SourceDateFormModel.swift` (50–51: "One write. True when the date was saved, or when the Source turned out to be deleted (the page is leaving); false keeps the dialog open with its draft and error."), `Platform/FakeStore.swift` (678–679: "(the engine's not-found for a deleted Source)"; 697: "The engine's answer for a deleted Source."), `core/database/sources/sources.go` (29–30, reflowed: "a read or write of a deleted Source"), the four L10n string comments in §6 Strings with their catalog comments, and two test comments: `SourcePageModelTests.swift` 2584 ("// MARK: Source date, Private and a deleted Source (S15-03)") and `SourceTypePageModelTests.swift` 155 ("/// UX-3: a deleted type leaves with a notice that names it.").
Check: `rg -n "another window|second window|deleted elsewhere|added while the form|deleted since the sheet|made since the sheet|taken the Artifact" macos core` finds nothing (`ArtifactSheetModel`'s "checked or unchecked since the sheet opened" is the dirty check and stays); `gofmt -l core/database/sources` prints nothing.

**STEP-6 — The UX lens asks what one window meets**
Files: `.agents/skills/review-pr/lenses/ux.md`.
Do: lines 52–55 become: "**An id held across a round trip.** For each id the view keeps between requests (a selection, a draft, a decided row), ask what happens when the id is gone by the time it is used: Back or Forward to a deleted or merged item, a write on a cached page that answers not-found. The page names the item, recovers, and keeps the user's other work; it does not loop on an error." Lines 150–152 become: "**A deleted item that blocks the page.** After Back to an item that had been deleted, every request failed with an error naming nothing, and only Cancel, losing every decision, got out." (D-9)
Check: `rg -n "another window" .agents/skills` finds nothing.

**STEP-7 — Version**
Files: `VERSION`, `core/version.go`, `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: bump PATCH from the current `main` value in all three (`MARKETING_VERSION` in every configuration).
Check: the three agree.

**STEP-8 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `deployment-plan.md` (map row), this plan (status, Landed note).
Do: per the Definition of done.
Check: links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `SourcePageModelTests.swift` `typeChangeClearsTheAddRowsTakenField` *(new)* | Add row on Film number with "F-7", type changed to one suggesting Film number → field cleared, value kept, `takenFieldLabel == "Film number"`, notice "Film number is now on the board. Pick another field." | AC-2.1, D-5, D-6 |
| T-2 | Swift | `MetadataBoardModelTests.swift` `pickingAFieldClearsTheNotice` (kept) | Pick Roll → notice cleared | AC-2.2 |
| T-3 | Swift | `SourcePageModelTests.swift` `sheetCitationsLockHoldsUntilTheLinkIsSaved`, `sheetSaveReloadFailureOffersReadAgain` (kept) | Edit sends the checked graphs; a refused save re-reads locks, as today | AC-3.1, D-2, D-7 |
| T-4 | Swift | `SourcePageModelTests.swift` `addArtifactOnOneGraphShowsTheGroup` and the add-sheet ingest tests (522–628, kept) | Create sends the checked graph; a failed ingest keeps the sheet | AC-3.2, AC-3.3, D-3 |
| T-5 | Script | `rg` checks in STEP-1, STEP-2, STEP-5, STEP-6 | No hit | AC-1.1, AC-1.2 |
| T-6 | Swift | The suite | The seven deleted tests are gone; everything else passes | AC-1.3 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourcePageModelTests` (sheet saves that asserted `savedGraphIDs`' extra graphs), `MetadataBoardModelTests`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: none
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Open a project with a Source that has Artifacts and two Evidence graphs. Open an Artifact's sheet, uncheck one graph, Save: the Artifact's row shows the remaining graph. Add an Artifact with both graphs checked: it is in both.
2. On a Photograph Source, open the Metadata Add field row, pick a field the Census type suggests, type a value, then change the Source's type to Census: the row clears its pick, keeps the value, and reads "‹Field› is now suggested by this type."
3. Choose Delete on an Artifact row and, before the confirm appears, open another Artifact's sheet (or open the sheet, then use the row's Delete if it is reachable). No delete confirm shows over the sheet; after closing the sheet, the confirm shows or not, and confirming deletes only the row chosen (D-11).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A sheet can be shown over the Artifact sheet (a delete impact, a second sheet) and delete an Artifact or graph | Stop condition below |
| A remaining test asserted `savedGraphIDs`' extra graphs | STEP-2's check names the suite; such a test is a second-window test and is reported, not edited to pass |

**Stop and report if:**

- Manual check step 3 shows a delete confirm over the open Artifact sheet, or anything inside `ArtifactSheet.swift` can delete or create an Artifact or a graph (D-11).
- T-1, set up as STEP-4 says, still sees no `takenFieldLabel` after `model.sync(from:)`.
- A test other than the seven named fails after STEP-1 or STEP-2.
- `SourcePageModel.apply`'s `shown` turns out to have no reader once lines 170–174 go (then report; do not remove it, `metadata.resetIfChanged` should still read it).

## 12. Open questions

None.

## 13. PR

**Title:** S16-61 — Nothing in the app waits on a second window
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-61-no-second-window.md`.
