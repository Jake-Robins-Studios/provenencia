# S16-59 — Workspace callers add to the toast stack

**Status:** Planned
**Spike / slice:** Spike 16 · Slice 6e — Stacked toasts
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: every toast keeps its copy, tone and host stack; only how a model reaches the list changes)
**Board:** —
**Depends on:** S16-58 (landed [#941](https://github.com/Jake-Robins-Studios/provenencia/pull/941))
**Blocks:** —
**Branch:** `s16-59-toast-callers`
**Version bump:** none — a preparatory refactor with no change a researcher can see, no wire change and no catalog format change, as S16-64 ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md) (the kit README's Toast row)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc` (no `Features/` type inside `DesignSystem/Components/`)
**Context:** map scope entry [S16-59](../deployment-plan.md#s16-59--workspace-callers-add-to-the-toast-stack); working rule "(Batch 6) One toast stack per window"; [`stacked-toasts.md`](../stacked-toasts.md) "Callers add, they do not set"; S16-58's plan [Landed note](S16-58-toast-stack.md#landed) and [ship log](S16-58-toast-stack.ship.md) (CON-6, MNT-2, MNT-7, UX-3); bar 32
**Planned:** 2026-11-22 against `main` @ `46a2614`
**Review:** [`S16-59-toast-callers.review.md`](S16-59-toast-callers.review.md) — Fits with changes / Ready with changes, 1 round

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

Every workspace model adds its toast to its host's `PVToastList` directly, instead of setting a `toast` property that a view modifier forwards into the list. The forwarding modifier (`vocabularyToastOverlay`), the per-model `toast` properties, `WorkspaceSession.noticeToast` and the `VocabularyToast` value all go, so a toast has one path: a model calls `add`. The researcher sees the same toasts in the same stacks as after S16-58.

**Why now.** S16-58 made every page's toast stack by forwarding its old binding into the window's list, and left the forwarding for this PR (its §3 Out row, Next adds). Its review left three items here: the overlay's `identifier` parameter is no longer read and nine callers pass dead ids (CON-6, UX-3; the ship log says ten), and `WorkspaceSession.toasts`' comment says every toast joins the window's list, which a sheet's toast does not (MNT-7).

**What stays.** `PVToastList`, `PVToastStack` and `PVToast` are unchanged. The window draws `session.toasts` (`WorkspaceContent`); each `.pvSheet` owns its list and draws its stack (`PVSheetChrome`); Onboarding owns its list. Every toast keeps its copy and tone. `CatalogCounts` and the navigation-history issue keep their `replacing:` ids. The likeness viewer's toasts show in the viewer's sheet; a portrait chosen on the page shows in the window's stack.

## 2. User stories

**US-1.** As a contributor, when a workspace model raises a toast, it adds to the list it will show in, so that one path exists and a test asserts on the list.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A Metadata field is added (`MetadataModel`, the add path) | `session.toasts`' one entry is tone `.success`, title `L10n.string(L10n.Metadata.toastAddedTitle)`; the model has no `toast` property |
| AC-1.2 | A Source type's Details save with formats unchanged (`SourceTypePageModel.save`) | One entry, title `toastUpdatedTitle`, message `toastUpdatedBody(label:key:)` |
| AC-1.3 | An Evidence graph is added from the Source page (`SourceGraphFormModel.save`) | One entry: title "Evidence graph added", message "`<ref>` is ready to open." |
| AC-1.4 | A Source move finishes (`SourceMoveModel.move`) | One `.success` entry in `session.toasts`, title `moveDoneTitle(target:)`, message `doneBody(artifacts:graphs:)` |
| AC-1.5 | A page leaves for its section root with a notice (`LeavesForSectionRoot.leave(notice: "Gone", …)`) | One `.info` entry, title "Gone", no message; with `notice: nil` the list stays empty |
| AC-1.6 | A save that fails (`SourceTypePageModelTests.aStoreFailureOnSaveIsNotALabelError`) | The list stays empty |

**US-2.** As a researcher, a portrait choice shows its toast where I am looking, as today.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Person page, Gallery section, no viewer open; choose a portrait (`ConclusionLeadModel.choose`) | One success entry, "Portrait updated" / "Using the likeness from Census as the portrait.", in `session.toasts` |
| AC-2.2 | The likeness viewer open (`viewerOpened(toasts: sheetList)`); choose a portrait | The entry is in `sheetList`; `session.toasts` stays empty |
| AC-2.3 | The viewer closed (`viewerClosed()`) after AC-2.2; choose again | The entry is in `session.toasts`; `sheetList` keeps only its earlier entry |
| AC-2.4 | The write fails (`setPreferredLikenessError`) | One `.danger` entry titled `L10n.Errors.message(for:)`, no message, in the list AC-2.1 or AC-2.2 names |

**US-3.** As a researcher, nothing on screen changes.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | Bar 32: choose two portraits in a row on a Person page | Two cards stacked top-trailing, newest on top, each leaving five seconds after it appeared |
| AC-3.2 | In the likeness viewer, choose a likeness | The card shows inside the viewer's sheet, not in the window behind it |
| AC-3.3 | Save a Source title, then Promote a graph within five seconds | Both cards in the window's one column |

## 3. Scope

| In | Covered by |
| --- | --- |
| Properties, Sources list, Source type page, Metadata and Evidence graph models add to `session.toasts`; their `toast` properties go | STEP-2, STEP-3, AC-1.1, AC-1.2 |
| The Source page's sections (`SourcePageModel`, `SourceArtifactsSection`, `ArtifactSheetModel`, `SourceGraphFormModel`) add to `context.session.toasts`; `SourcePageContext.toast` and `SourcePageModel.toast` go | STEP-4, AC-1.3 |
| `WorkspaceSession.noticeToast`'s four setters add to `session.toasts`; the property and `WorkspaceView`'s notice overlay go | STEP-5, AC-1.4, AC-1.5 |
| `ConclusionLeadModel` adds to the viewer's sheet list while the viewer is open, else to `session.toasts`; `toast` and `toastInViewer` go | STEP-6, AC-2.1 – AC-2.4 |
| `vocabularyToastOverlay`, `VocabularyToastOverlay`, `VocabularyToast` and `PVToastList.add(_: VocabularyToast)` go, with the nine overlay ids (CON-6, UX-3) | STEP-7 |
| `WorkspaceView` stops setting the key; `\.pvToastList` becomes `\.pvSheetToasts` beside the other sheet keys; `WorkspaceSession.toasts`' comment says what is true (MNT-7) | STEP-5, STEP-7 |
| The models' toast tests assert on the list | STEP-2 – STEP-6 |
| Kit README Toast row | STEP-8 |

| Out | Home |
| --- | --- |
| A toast from a sheet joining the window's list | not planned (working rule: a sheet owns its list) |
| `ArtifactSheetModel`'s created toast, `SourceMoveModel`'s done toast and the Source graph form's toast moving into a sheet's list | not planned (they land in the window's list today, after their sheet closes; no visible change is this PR's bar) |
| A `replacing:` id held by any caller other than `CatalogCounts` and `WorkspaceView`'s history issue | not planned (working rule: only a repeating event holds an id) |
| Moving `presentHistoryIssueIfNeeded` out of `WorkspaceView` | not planned (S16-58 §3 Out) |
| `PVToastStack.swift`'s stray spacing before `)` (S16-58 ship log nit) | not planned (a kit file this PR does not otherwise touch) |
| Onboarding's toast host | not planned (already a `PVToastList` since S16-58) |

## 4. Current state

Verified at `46a2614`. Paths under `macos/App/` unless they start with `macos/ProvenenciaTests/`.

| Area | Where | Today |
| --- | --- | --- |
| The forwarder | `Features/CatalogVocabulary/VocabularyChrome.swift:49-75` `View.vocabularyToastOverlay(_:identifier:)`, `VocabularyToastOverlay` | `onChange(of: toast, initial: true)` adds a non-nil toast to `\.pvToastList` and sets the binding nil; `assertionFailure` without a list. `identifier` is stored and never read |
| The value | `Features/CatalogVocabulary/VocabularyPane.swift:29-43` `VocabularyToast` (`title`, `body`, `tone`; `Equatable, Hashable`), `extension PVToastList { func add(_ toast: VocabularyToast) }` | A parameter bag for `add(tone:title:message:)` and the type of every model's `toast` |
| Overlay callers | `Features/Properties/PropertiesView.swift:74`, `Features/Sources/SourcePageView.swift:131`, `Features/Sources/SourcesListView.swift:81`, `Features/SourceTypes/SourceTypePageView.swift:43`, `Features/Metadata/MetadataView.swift:76`, `Features/EvidenceGraph/EvidenceGraphView.swift:161`, `Features/Conclusions/ConclusionDetailPage.swift:198`, `Features/Conclusions/ConclusionPictureViewer.swift:156`, `Features/Workspace/WorkspaceView.swift:71-78` | Each binds a model's `toast` (or `session.noticeToast`) and passes an id nothing reads |
| Properties | `Features/Properties/PropertiesModel.swift` `toast` (:52); sets at :410, :486, :548; holds `private let session` | No test asserts its toast |
| Sources list | `Features/Sources/SourcesModel.swift` `toast` (:95); set at :446; `private let session` | `SourcesModelTests.swift:375` `model.toast != nil` |
| Source type page | `Features/SourceTypes/SourceTypePageModel.swift` `toast` (:21); `toast = savedToast(…)` at :218; `savedToast(_:detailsChanged:formatsSaved:) -> VocabularyToast` at :224-245; sets at :348, :371; `session.noticeToast` at :454 (`keepEditing`); `private let session` | `SourceTypePageModelTests.swift` :109, :123, :149, :370, :400, :425, :543, :545 (`body.contains("3")`), :559, :655, :737-760 (`noticeToast`), :809, :822, :833, :850; `SourceTypesModelTests.swift:338` `page.toast == nil` |
| Metadata | `Features/Metadata/MetadataModel.swift` `toast` (:41); sets at :266, :300, :323; `private let session` | `MetadataModelTests.swift` :98, :155, :202, :441 |
| Evidence graph | `Features/EvidenceGraph/EvidenceGraphModel.swift` `toast` (:90); sets at :264, :365, :690, :1450; `let session` | `EvidenceGraphModelTests.swift` :361-362, :455, :670, :719, :1659 |
| Source page | `Features/Sources/SourcePageContext.swift:32` `var toast`; `context.toast =` in `SourcePageModel.swift` :247, :264, `SourceArtifactsSection.swift` :143, :154, :192, `ArtifactSheetModel.swift:397`, `SourceGraphFormModel.swift:205`; `SourcePageModel.swift:97-100` forwards `toast` to `context.toast`; `SourcePageContext.session` is `let` (internal); `SourcePageModel.context` is `private` | `SourcePageModelTests.swift` :802, :1568-1569, :1871, :1974; `SourceGraphFormModelTests.swift` :99-100, :242. `SourcePageModelTests.makeModel(store:session:)` (:54) takes an optional session; `SourceGraphFormModelTests.makeModel` returns `(model, store, session)` |
| Notice | `Features/Workspace/Session/WorkspaceSession.swift:29-30` `noticeToast: VocabularyToast?`; doc comment :12-13 "Every toast the workspace raises joins this one list"; set by `SourceTypePageModel.swift:454`, `Workspace/WorkspaceNavigation.swift:359` (`LeavesForSectionRoot.leave`; doc comments :341, :355-356, :436 say "the session's notice toast"), `Promote/PromoteModel.swift:378`, `Sources/SourceMoveModel.swift:217` | `SourceMoveModelTests.swift` :403-405, :433; `WorkspaceNavigationTests.swift:101`; `SourceTypePageModelTests.swift:737-760` |
| Window | `Features/Workspace/WorkspaceView.swift:70-79` | The notice overlay, then `.environment(\.pvToastList, session.toasts)`, whose only reader is the forwarder. `presentHistoryIssueIfNeeded` (:136, :143) already adds with `replacing: historyIssueToastID` |
| Lead | `Features/Conclusions/ConclusionLeadModel.swift` `toast` (:15), `toastInViewer` (:18), `viewerOpened()` (:29-33), `viewerClosed()` (:38-42), sets in `write` (:74, :78); `ConclusionDetailPage.swift:143-144` comment, :197-198 overlay; `ConclusionPictureViewer.swift:156-160` overlay, `onAppear { lead.viewerOpened() }`, `onDisappear { lead.viewerClosed() }`. The viewer is presented by `ConclusionGallerySection.swift:60` `.pvSheet(item:)` | `PersonDetailTests.swift` :280-283 `leadModel(_:)` (drops its session), :300-311 `leavingTheSectionKeepsAPageToast`, :319, :359, :372, :377, :389 |
| Sheet list | `DesignSystem/Components/Panel/PVSheet.swift:24-32` `PVSheetChrome` | `@State toasts = PVToastList()`, `.environment(\.pvToastList, toasts)`, draws `PVToastStack(list: toasts, identifier: "sheet.toasts")` |
| Key | `DesignSystem/Components/Toast/PVToastList.swift:80-89` `EnvironmentValues.pvToastList`; comment "the window, or a sheet over it" | Set by `WorkspaceView` and `PVSheetChrome`; read only by `VocabularyToastOverlay` |
| Kit README | `DesignSystem/README.md:168` Toast row | "Every toast host (the workspace window, each sheet, Onboarding) owns one `PVToastList`, sets it as `\.pvToastList` …"; Onboarding does not set it today |
| Sheet guidance | `.agents/skills/add-ui-component/SKILL.md:97` | Teaches `\.pvSheetClose`; says nothing of a sheet's toast list |
| Feature docs | `docs/deployment-plan/spike-16/stacked-toasts.md:10-24`; `docs/macos-client-patterns.md:105` | Name `noticeToast`, `vocabularyToastOverlay`, `toastInViewer` and "the page owns … its toast" as current |
| List assertions | `CatalogCountsTests.swift:85-88, 121-124`, `CitationComposerModelTests.swift:916-919`, `PVToastListTests.swift:10` `titles(_:)` | Three shapes for reading a list in tests |
| Tests | `macos/ProvenenciaTests/VocabularyToastTests.swift` `addingAVocabularyToastForwardsItsFields` | Tests the forward extension this PR deletes |

**Precedent.** `5b1b74a` ("Show the composer's saved-bridge toast in the window's stack.", S16-58 D-11) is this PR's shape for one caller: `CitationComposerModel+Authoring.swift:672` calls `session.toasts.add(tone: .success, title: …, message: …)` through the `session` the model holds, and `CitationComposerModelTests.savingABridgeAddsItsToastToTheWindowList` asserts on `fresh.session.toasts.entries` with the session's default list. Copy both. S16-64 is the precedent for a version-free preparatory PR.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | Every call site writes `<list>.add(tone:title:message:)` with today's tone and copy, each argument the same expression it passes to `VocabularyToast` today (so the `String` conversion it does today, `L10n.string(…)` or a `String`-returning `L10n` function, stays). Where today's `body` is `""`, it passes `message: nil` | One path into the list (map scope); `add` already turns `""` into `nil` (S16-58 D-4), so `nil` says it at the call | Keeping `VocabularyToast` and calling `add(_: VocabularyToast)` — a feature parameter bag over the kit's own three parameters, and a second way to add |
| D-2 | `VocabularyToast`, `PVToastList.add(_: VocabularyToast)`, `vocabularyToastOverlay(_:identifier:)` and `VocabularyToastOverlay` are deleted, with `VocabularyToastTests.swift` | Each loses its last caller in this PR | Keeping the overlay for the viewer — the viewer adds through its model (D-6) |
| D-3 | Workspace page models add to `session.toasts` through the `session` they already hold: `PropertiesModel`, `SourcesModel`, `SourceTypePageModel`, `MetadataModel`, `EvidenceGraphModel`, `PromoteModel`, `SourceMoveModel`. The Source page's sections add to `context.session.toasts`. `LeavesForSectionRoot.leave` adds to its `session` parameter's list | Each already holds the session (§4); no new parameter | A list injected into each model — a second way to reach one list |
| D-4 | `SourceTypePageModel.savedToast(_:detailsChanged:formatsSaved:)` becomes `private func addSavedToast(_ updated: CatalogSourceType, detailsChanged: Bool, formatsSaved: Bool)`: the same `switch`, each case calling `session.toasts.add(tone: .success, …)` with today's copy; `save()` calls it where it set `toast` | Every toast site in the model then calls `add` (D-1), and the three cases stay out of `save()` (review M-4) | A function returning a `(title:message:)` tuple — a value shape for one caller; inlining the switch in `save()` — 20 lines in the save path |
| D-5 | `WorkspaceSession.noticeToast` goes. Its four setters (§4) add to `session.toasts` directly, before the navigation they precede, as today's set does | The notice existed so a toast outlived the page that raised it; the window's list already does (S16-58 Reach) | Keeping `noticeToast` as a name for "toast after leaving" — it would be a second path to the same list |
| D-6 | `ConclusionLeadModel` holds `private var viewerToasts: PVToastList?` *(new)* in place of `toast` and `toastInViewer`. `viewerOpened(toasts: PVToastList?)` sets it; `viewerClosed()` sets it to `nil`. `write` adds to `viewerToasts ?? session.toasts`. `ConclusionPictureViewer` reads `@Environment(\.pvSheetToasts) private var sheetToasts` and calls `lead.viewerOpened(toasts: sheetToasts)` in its existing `onAppear`. `ConclusionDetailPage`'s overlay and its "one Toast has one host" comment go; the `lead` property's comment drops "so the page's toast is its own" | The scope entry: a model whose toast can show while its sheet is up decides where it draws (S16-58 Next adds). The sheet's list is `@State` in the kit's `PVSheetChrome`, so the environment is the one way the viewer reaches it | Making `PVSheetChrome`'s list public through a binding — the kit owns it; a `Bool` plus a separate list parameter on `choose` — the caller would pass the list on every call |
| D-7 | The environment key is renamed `\.pvSheetToasts` and moves from `PVToastList.swift` to `PVSheet.swift`, beside `\.pvSheetClose` and `\.pvSheetInnerEditOpen`: a `private struct PVSheetToastsKey: EnvironmentKey` (default `nil`) and `EnvironmentValues.pvSheetToasts: PVToastList?`, commented "The toast list of the sheet a view is in, set by `PVSheetChrome`; `nil` outside a sheet, where a workspace model adds to `WorkspaceSession.toasts`." `PVSheetChrome` is its one setter and `ConclusionPictureViewer` its one reader. `WorkspaceView`'s `.environment(\.pvToastList, session.toasts)` goes. `add-ui-component`'s sheet sentence gains: "A sheet's content that must raise a toast reads `@Environment(\.pvSheetToasts)` and hands it to its model (`ConclusionLeadModel.viewerOpened(toasts:)`); a workspace model adds to `WorkspaceSession.toasts`." | After D-2 nothing outside a sheet reads the key; its name then says when it is set, and the sheet's keys live in one file (review M-1). The skill line is where the next sheet's author learns D-6's pattern | Keeping `\.pvToastList` with a new comment — a generic name a workspace view would read as the window's list and get `nil`; deleting the key — the viewer could not reach its sheet's list |
| D-8 | `WorkspaceSession.toasts`' comment reads: "The window's toasts, newest first. Every toast the workspace raises outside a sheet joins this one list (`CatalogCounts` adds its recount failure here); `WorkspaceContent` draws it. A sheet draws its own (`PVSheetChrome`)." | S16-58 ship log MNT-7 | — |
| D-9 | Tests compare a list's cards whole, through a test fixture `macos/ProvenenciaTests/ToastFixtures.swift` *(new)*: `struct ToastCard: Equatable { let tone: PVToastTone; let title: String?; let message: String? }` with an unlabeled `init(_ tone:_ title:_ message: String? = nil)`, and `extension PVToastList { var cards: [ToastCard] }` (newest first). A positive check is `#expect(session.toasts.cards == [ToastCard(.success, title, message)])`, which also checks the count (AC-1.2, AC-1.4 say one entry); a `toast == nil` check is `#expect(session.toasts.cards.isEmpty)`; `toast != nil` is `!cards.isEmpty`; `body.contains(x)` is `cards.first?.message?.contains(x) == true`. A test that adds twice compares the whole list after each add. Tests use the session's default list, as `CitationComposerModelTests.savingABridgeAddsItsToastToTheWindowList` does. A helper that builds a session and drops it returns it: `PersonDetailTests.leadModel(_:)` returns `(ConclusionLeadModel, WorkspaceSession)`. A test with no session in scope (`SourcePageModelTests` at :802, :1871, :1974 call `makeModel(store:)`) builds `WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)` first and passes it as `session:`. `CatalogCountsTests`' and `CitationComposerModelTests`' tone/title/message checks and `PVToastListTests`' private `titles(_:)` move onto `cards` (review M-3) | One way to assert a toast, and a double add fails a test | Hand-written `entries.first` field checks — three shapes exist already, and `.first` cannot see a second card; a `ManualSleep` list per session — no assertion here waits |
| D-10 | `PersonDetailTests.leavingTheSectionKeepsAPageToast` is replaced by `aToastGoesToTheViewerWhileItIsOpen` *(new)*, T-5 | The old test checks `toast` and `toastInViewer` clearing, which no longer exist; the new rule is where an add lands | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `ConclusionLeadModel.viewerToasts` *(new, private)* | property | `ConclusionLeadModel.toastInViewer` (replaced) | It replaces the flag: the list itself says where an add goes |
| `ConclusionLeadModel.viewerOpened(toasts:)` | func (signature change) | `viewerOpened()` | Same function, one parameter |
| `SourceTypePageModel.addSavedToast` | func (replaces `savedToast`) | `savedToast` | Same switch; adds instead of returning |
| `\.pvSheetToasts`, `PVSheetToastsKey` | key (rename and move of `\.pvToastList`) | `\.pvSheetClose` (`PVSheetCloseKey`) | Its siblings' file and naming |
| `ToastFixtures.swift`: `ToastCard`, `PVToastList.cards` *(new)* | test helper | `PVToastListTests.titles(_:)` (private), `CatalogCountsTests`' field checks | One shared shape replaces them (D-9) |
| `PersonDetailTests.aToastGoesToTheViewerWhileItIsOpen` *(new)* | test | `leavingTheSectionKeepsAPageToast` (deleted) | It tests the new rule (D-10) |

Searched: `rg -n "toast" macos/App --glob '*.swift'` for every setter and reader; `rg -n "pvToastList"` for every key use; `rg -n "entries\[0\]|entries.first|titles\(" macos/ProvenenciaTests` for list assertions.

**Builds on.** `PVToastList.add(tone:title:message:replacing:)` (S16-58), `WorkspaceSession.toasts`, `PVSheetChrome`'s own list, the composer's direct add (`5b1b74a`).
**Deletes.** `vocabularyToastOverlay(_:identifier:)`, `VocabularyToastOverlay`, `VocabularyToast`, `PVToastList.add(_: VocabularyToast)`, `VocabularyToastTests.swift`; the `toast` property of `PropertiesModel`, `SourcesModel`, `SourceTypePageModel`, `MetadataModel`, `EvidenceGraphModel`, `SourcePageContext`, `SourcePageModel` (its forward) and `ConclusionLeadModel`; `ConclusionLeadModel.toastInViewer`; `WorkspaceSession.noticeToast`; the nine `.vocabularyToastOverlay` call sites and their ids (`properties.toast`, `sources.page.toast`, `sources.toast`, `sourceTypes.page.toast`, `metadata.toast`, `evidenceGraph.toast`, `\(pageIdentifier).toast`, `\(identifier).toast`, `workspace.notice.toast`); `WorkspaceView`'s `.environment(\.pvToastList, …)` and its "Before the environment below" comment; `PersonDetailTests.leavingTheSectionKeepsAPageToast`.
**Next adds.** A new workspace toast is one `session.toasts.add` in its model and one assertion on the list in its test. A new sheet whose model raises a toast takes its list as `ConclusionLeadModel` does (D-6).

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A page model's async save that finishes after its page was left | `session.toasts` | Today the toast sat in the model's `toast` until the page's overlay mounted again (`initial: true`), or was lost with the model. Now it is added at once and shows in the window's stack. This is the only timing change; manual check 4 |
| The viewer opened outside a sheet (no `\.pvSheetToasts`) | `ConclusionLeadModel.write` | `viewerToasts` is `nil`, so the add goes to `session.toasts`. The viewer is only presented by `.pvSheet` today (`ConclusionGallerySection.swift:60`) |
| A portrait save in flight while the viewer closes | `ConclusionLeadModel.write` | `viewerClosed()` clears `viewerToasts` first, so the add goes to the window's list, as today's `toastInViewer == false` path forwarded it (T-5) |

### Scale

None — no catalog read or write changes; each add is one array insert and one sleeping task, as since S16-58.

### Edges

- **Assumptions.** A model adds on the main actor: every model named here is `@MainActor`, as `PVToastList` is. A sheet's list lives as long as the sheet's `PVSheetChrome`: `viewerClosed()` runs in the viewer's `onDisappear`, so the model holds the list no longer than the viewer is up (T-5).
- **Neighbors.** A title-only toast (`body: ""` today) → `message == nil` (T-3, T-4). Two equal adds → two cards, as since S16-58; no caller passes `replacing:`.
- **Removed inputs.** None — no input is decided or excluded.
- **Real data / Untrusted size.** None — no data from the catalog.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None — no RPC change.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Window toasts | `PVToastStack` over `session.toasts` | `Features/Workspace/WorkspaceContent.swift` | Unchanged |
| Sheet toasts | `PVSheetChrome`'s list and stack | `DesignSystem/Components/Panel/PVSheet.swift` | Unchanged; `ConclusionPictureViewer` reads its list (D-6) |

```swift
// ConclusionLeadModel
private var viewerToasts: PVToastList?
func viewerOpened(toasts: PVToastList?)
func viewerClosed()

// SourceTypePageModel
private func addSavedToast(_ updated: CatalogSourceType, detailsChanged: Bool, formatsSaved: Bool)

// PVSheet.swift
extension EnvironmentValues { var pvSheetToasts: PVToastList? }
```

States: no change. Accessibility: no change; each card announces as since S16-58.

### Strings

None — no copy is added, removed or reworded; every call keeps its `L10n` key.

## 7. Steps

**STEP-1 — Check the base, and one way to assert a toast**
Files: `macos/ProvenenciaTests/ToastFixtures.swift` *(new)*, `CatalogCountsTests.swift`, `CitationComposerModelTests.swift`, `PVToastListTests.swift`. Skill: `add-swift-test`.
Do: confirm each §4 row with `rg -n "vocabularyToastOverlay|noticeToast|VocabularyToast|toastInViewer|pvToastList" macos`. Add the fixture (D-9) and move the three existing suites' tone/title/message checks and `titles(_:)` onto `cards`; id checks (`entries[0].id`) stay on `entries`.
Check: the hits match §4's rows (lines may shift by a few; a new hit is a Stop condition); `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/CatalogCountsTests -only-testing:ProvenenciaTests/CitationComposerModelTests -only-testing:ProvenenciaTests/PVToastListTests` passes.

**STEP-2 — Properties, Sources list and Metadata add to the window's list**
Files: `macos/App/Features/Properties/PropertiesModel.swift`, `PropertiesView.swift`, `macos/App/Features/Sources/SourcesModel.swift`, `SourcesListView.swift`, `macos/App/Features/Metadata/MetadataModel.swift`, `MetadataView.swift`, `macos/ProvenenciaTests/SourcesModelTests.swift`, `MetadataModelTests.swift`. Skill: `add-swift-test`.
Do: D-1, D-3; delete each model's `toast` and its view's `.vocabularyToastOverlay`. Tests per D-9 (T-1).
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/SourcesModelTests -only-testing:ProvenenciaTests/MetadataModelTests -only-testing:ProvenenciaTests/PropertiesModelTests` passes.

**STEP-3 — The Source type page and the Evidence graph add to the window's list**
Files: `macos/App/Features/SourceTypes/SourceTypePageModel.swift`, `SourceTypePageView.swift`, `macos/App/Features/EvidenceGraph/EvidenceGraphModel.swift`, `EvidenceGraphView.swift`, `macos/ProvenenciaTests/SourceTypePageModelTests.swift`, `SourceTypesModelTests.swift`, `EvidenceGraphModelTests.swift`. Skill: `add-swift-test`.
Do: D-1, D-3, D-4; leave `keepEditing`'s `session.noticeToast` for STEP-5. Tests per D-9 (T-2).
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/SourceTypePageModelTests -only-testing:ProvenenciaTests/SourceTypesModelTests -only-testing:ProvenenciaTests/EvidenceGraphModelTests` passes.

**STEP-4 — The Source page's sections add to the window's list**
Files: `macos/App/Features/Sources/SourcePageContext.swift`, `SourcePageModel.swift`, `SourceArtifactsSection.swift`, `ArtifactSheetModel.swift`, `SourceGraphFormModel.swift`, `SourcePageView.swift`, `macos/ProvenenciaTests/SourcePageModelTests.swift`, `SourceGraphFormModelTests.swift`. Skill: `add-swift-test`.
Do: D-1, D-3: `context.toast = VocabularyToast(…)` becomes `context.session.toasts.add(…)`; `SourcePageContext.toast`, `SourcePageModel.toast` and the view's overlay go. Tests per D-9 (T-3).
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/SourcePageModelTests -only-testing:ProvenenciaTests/SourceGraphFormModelTests` passes.

**STEP-5 — The session's notice goes**
Files: `macos/App/Features/Workspace/Session/WorkspaceSession.swift`, `WorkspaceView.swift`, `WorkspaceNavigation.swift`, `macos/App/Features/SourceTypes/SourceTypePageModel.swift`, `macos/App/Features/Promote/PromoteModel.swift`, `macos/App/Features/Sources/SourceMoveModel.swift`, `macos/ProvenenciaTests/SourceMoveModelTests.swift`, `WorkspaceNavigationTests.swift`, `SourceTypePageModelTests.swift`. Skill: `add-swift-test`.
Do: D-5 (the notice overlay and its "Before the environment below" comment go; the window's `.environment(\.pvToastList, …)` stays until STEP-7, since the Conclusion page's overlay still forwards through it), D-8. `WorkspaceNavigation.swift`'s comments at :341, :355-356 and :436 say "adds `notice` to the window's toasts" in place of "the session's notice toast". In `SourceTypePageModelTests`' copy-notice test, the `session.noticeToast = nil` reset between steps becomes a count: record `session.toasts.entries.count` before each step and compare after. Tests per D-9 (T-4).
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/SourceMoveModelTests -only-testing:ProvenenciaTests/WorkspaceNavigationTests -only-testing:ProvenenciaTests/SourceTypePageModelTests -only-testing:ProvenenciaTests/PromoteModelTests` passes; `rg -n noticeToast macos` prints nothing.

**STEP-6 — The lead adds where the viewer is**
Files: `macos/App/Features/Conclusions/ConclusionLeadModel.swift`, `ConclusionPictureViewer.swift`, `ConclusionDetailPage.swift`, `macos/ProvenenciaTests/PersonDetailTests.swift`. Skill: `add-swift-test`.
Do: D-6, D-10; the model's type comment keeps its first paragraph and its `viewerOpened` / `viewerClosed` comments say where an add goes. Tests T-5, T-6.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PersonDetailTests` passes.

**STEP-7 — The forwarder and the value go; the key becomes the sheet's**
Files: `macos/App/Features/Workspace/WorkspaceView.swift`, `macos/App/DesignSystem/Components/Panel/PVSheet.swift`, `macos/App/Features/Conclusions/ConclusionPictureViewer.swift`, `.agents/skills/add-ui-component/SKILL.md`, `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift`, `VocabularyPane.swift`, `macos/ProvenenciaTests/VocabularyToastTests.swift` (deleted), `macos/App/DesignSystem/Components/Toast/PVToastList.swift` (the key leaves it). The project uses synchronized folders, so deleting the file removes it from the target.
Do: D-2; D-7 (the window's `.environment(\.pvToastList, session.toasts)` goes; the key is renamed and moved; the viewer reads `\.pvSheetToasts`; the skill line).
Check: `rg -n "vocabularyToastOverlay|VocabularyToast|toastInViewer|noticeToast" macos` prints nothing; `rg -n "pvToastList" macos .agents` prints nothing; `rg -n "pvSheetToasts" macos/App` prints only `PVSheet.swift` and `ConclusionPictureViewer.swift`; the app builds.

**STEP-8 — Kit README and guidance**
Files: `macos/App/DesignSystem/README.md`. Skill: `add-ui-component`.
Do: the Toast row's sentence on hosts reads: "Every toast host (the workspace window, each sheet, Onboarding) owns one `PVToastList` and draws one `PVToastStack`, so cards expire in one place. A workspace model adds to `WorkspaceSession.toasts`; a sheet sets its list as `\.pvSheetToasts` for content that must add to it (the likeness viewer)." The rest of the row stays.
Check: `python3 scripts/check-guidance-names.py` passes.

**STEP-9 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `deployment-plan.md` (map row), this plan (status, Landed note), `docs/deployment-plan/spike-16/stacked-toasts.md`, `docs/macos-client-patterns.md`.
Do: per the Definition of done. `stacked-toasts.md`'s Shape bullet "One stack per window" and its "Callers add, they do not set" bullet say what shipped: a workspace model adds to `WorkspaceSession.toasts`; a sheet owns its list, reached as `\.pvSheetToasts`, and the likeness viewer hands it to `ConclusionLeadModel`; Onboarding owns its list; no `noticeToast`, `toastInViewer` or `vocabularyToastOverlay` is named as current. `macos-client-patterns.md:105` "the page owns the lead model (`ConclusionLeadModel`, which chooses a gallery lead) and its toast" becomes "the page owns the lead model (`ConclusionLeadModel`, which chooses a gallery lead); its toast goes to the viewer's sheet list while the viewer is open, else to the window's" (review M-2).
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-59-toast-callers.md` reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed, ending in a period, like the rest of `git log` ("Add each page's toast to the window's list directly."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-0 | Swift | `ToastFixtures.swift` *(new)*; `CatalogCountsTests`, `CitationComposerModelTests`, `PVToastListTests` *(edited)* | the existing cases, read through `cards` → same results | D-9 |
| T-1 | Swift | `MetadataModelTests` (the four tests asserting `model.toast` at :98, :155, :202, :441); `SourcesModelTests` (:375) *(edited)* | add / update / delete a field → `session.toasts.cards == [ToastCard(.success, <same L10n.Metadata title>, <body>)]`; Sources list add → `cards` not empty | AC-1.1, D-3, D-9 |
| T-2 | Swift | `SourceTypePageModelTests` (every `model.toast` assertion in §4) and `SourceTypesModelTests` (:338) *(edited)*; `EvidenceGraphModelTests` (:361-362, :455, :670, :719, :1659) *(edited)* | Details save → title `toastUpdatedTitle`, message `toastUpdatedBody(label:key:)`; formats only → `Formats.toastSavedBody`; both → `Formats.toastBothBody`; a refused save → list empty; graph position failure → first entry `.danger`, title `positionPersistFailedTitle` | AC-1.2, AC-1.6, D-4 |
| T-3 | Swift | `SourceGraphFormModelTests` (:99-100, :242), `SourcePageModelTests` (:802, :1568-1569, :1871, :1974) *(edited)* | graph added → title "Evidence graph added", message "`<ref>` is ready to open."; graph edit → list empty; graph deleted → "Evidence graph deleted" / "GPH-G-JONES was erased from this source." | AC-1.3, D-9 |
| T-4 | Swift | `SourceMoveModelTests` (:403-405, :433), `WorkspaceNavigationTests.leavingAGonePageShowsTheNoticeAndRewritesTheEntry`, `SourceTypePageModelTests`' copy-notice test (:737-760) *(edited)* | move done → `.success`, `moveDoneTitle(target: "Deed")`, `doneBody(artifacts: 2, graphs: 2)`; move failed → list empty; `leave(notice: "Gone")` → one `.info` entry, title "Gone", `message == nil`; `notice: nil` → empty; Keep editing after a held copy → one entry whose title contains "State census"; Discard → no entry added | AC-1.4, AC-1.5, D-5 |
| T-5 | Swift | `PersonDetailTests.aToastGoesToTheViewerWhileItIsOpen` *(new)* | `let sheet = PVToastList()`; `viewerOpened(toasts: sheet)`; `choose(censusTile())` → `sheet.cards.count == 1`, `session.toasts.cards.isEmpty`; `viewerClosed()`; `useEarliest` → `session.toasts.cards.count == 1`, `sheet.cards.count == 1` | AC-2.2, AC-2.3, D-6 |
| T-6 | Swift | `PersonDetailTests` `choosingAPortraitWritesAndToasts`, `useEarliestClearsAndToasts`, `theLeadCopyIsReadAtCallTime`, `portraitFailureToastsTheError` *(edited)* | each `model.toast == VocabularyToast(…)` → `session.toasts.cards == [ToastCard(…)]` with the same tone, title and message (`nil` where the body was `""`) | AC-2.1, AC-2.4, D-9 |

`PropertiesModelTests` and `PromoteModelTests` have no toast assertion today; this PR adds none (no AC rests on them; the Promote card is manual check 3). The views' removal of the overlay has no unit test; the manual check covers AC-3.1 – AC-3.3.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `SourceTypePageModelTests` (most assertions), `PersonDetailTests`, `CitationComposerModelTests` (shares `session.toasts`), `CatalogCountsTests` (unchanged, but builds sessions).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none expected: no copy changes)
- [ ] Sweep: `vocabularyToastOverlay`, `VocabularyToastOverlay`, `VocabularyToast`, `noticeToast`, `toastInViewer`, `savedToast(`, `pvToastList` and the nine overlay ids `rg`'d across `macos`, `.agents/`, `.cursor/rules/`, `docs/` (recursive, except `prs/`, `archive/`, `completed.md` and `*.review.md`) and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no brief; no kit primitive added)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated: stacked-toasts.md and macos-client-patterns.md:105 (STEP-9)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

On a project with a Person who has two likenesses from two Sources (Census and Register):

1. Person page, Gallery: choose likeness A as the portrait, then B within five seconds. Two `Portrait updated` cards, B's on top, top-trailing under the toolbar; each leaves about five seconds after it appeared (AC-3.1).
2. Open a likeness in the viewer and choose it: the card shows inside the viewer's sheet, not in the window behind it. Close the viewer and choose the other likeness on the page: the card shows in the window's stack (AC-3.2, AC-2.1 – AC-2.3).
3. Open a Source page and save its title; within five seconds open an Evidence graph's Promote and finish it: both cards in the window's one column (AC-3.3).
4. Source types: open a type, edit its description without saving, choose Copy type, then Keep editing in the leave question: the info card naming the copy shows in the window's stack (D-5, T-4).
5. Add a Property, add a Metadata field, add a Source from the Sources list, and move a node in an Evidence graph: the first three each raise their success card in the window's stack; the graph raises none unless its position save fails (D-3).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A toast raised by a page model after its page was left now shows at once (§6 Reach) | Intended by the working rule (one list per window); the card has the copy it had, so nothing reads wrong out of its page |
| The viewer's `onAppear` runs before `PVSheetChrome` sets the key, so `sheetToasts` is `nil` and the viewer's toasts go behind the sheet | `PVSheetChrome` sets the key on its content's environment, which the viewer's `onAppear` reads; T-5 covers the model; manual check 2 the view. If manual check 2 shows the card behind the sheet, stop |
| A test reads an entry after it expired | No assertion here waits on the clock; the default list holds an entry five seconds (D-9). A flaky expiry is a Stop condition, not a reason to add a sleep |

**Stop and report if:**

- `rg -n "vocabularyToastOverlay|noticeToast|VocabularyToast|toastInViewer|pvToastList" macos` at your checkout finds a caller §4 does not list.
- A model in D-3 does not hold a `WorkspaceSession` (a new `init` without one).
- A `toast == nil` assertion sits after an earlier add in the same test, so `cards.isEmpty` would be false for a reason the old test did not check.
- Manual check 2 shows a viewer toast behind the sheet.
- `ConclusionPictureViewer` is presented anywhere other than through `.pvSheet`, apart from its `#Preview` (there `viewerToasts` is `nil` and the add goes to `session.toasts`).

## 12. Open questions

None.

## 13. PR

**Title:** S16-59 — Workspace callers add to the toast stack
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-59-toast-callers.md`.
