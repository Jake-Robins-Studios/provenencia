# S16-58 — Toasts stack in one list per window

**Status:** Planned
**Spike / slice:** Spike 16 · Slice 6e — Stacked toasts
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D10](../design/S16-D10-toast-stack.md), board agreed 2026-11-22
**Board:** [design system, agreed 2026-11-22](https://claude.ai/artifact/7AZ8cscWF3f5Wz7gQ39cMe), component `PVToastStack` (`PVToastStack.jsx`, its README and component sheet K1: one, two and five cards, entering and leaving, Reduce Motion); [main app layout, agreed 2026-11-22](https://claude.ai/artifact/1UzGb9TQCd7ZQrmuAN5AY8), page "Workspace Chrome", section "Toast stack" (Two toasts · Regular and Wide = T1a, T1b; T2 Two surfaces at once; T3 A refreshed card; T4 A burst), drawn by `PVToastStackHost` in "App Layout". Values as briefed: 360 pt cards, 8 pt apart, 24 pt in from the content pane's top and trailing edges under the toolbar, cut at the pane's bottom, the column click-through outside the cards. The board adds motion values: a card enters sliding 28 pt from the trailing edge while fading in, 200 ms ease-out; it leaves the same way, 200 ms ease-in; with Reduce Motion it fades, 200 ms linear (D-7). The callers' boards were updated to send to the stack (user, 2026-11-22); T5 (the composer) is on the composer's board
**Depends on:** S16-56 (landed [#909](https://github.com/Jake-Robins-Studios/provenencia/pull/909)), S16-D10 (board agreed 2026-11-22)
**Blocks:** S16-59
**Branch:** `s16-58-toast-stack`
**Version bump:** patch — the next patch after `VERSION` on `main` when the branch is cut (0.32.1 → 0.32.2 at the planning base): toasts stack and the composer's toast moves; no wire or catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md) (its badge-refresh line changes)
**Rules that bind:** `.cursor/rules/design-system-layers.mdc` (no `Features/` type inside `DesignSystem/Components/`)
**Context:** brief [S16-D10](../design/S16-D10-toast-stack.md); design [`stacked-toasts.md`](../stacked-toasts.md); map scope entry [S16-58](../deployment-plan.md#s16-58--toasts-stack-in-one-list-per-window); working rule "(Batch 6) One toast stack per window"; bar 32; S16-56's review QCK-1 ([`completed.md`](../completed.md)); the precedent `PVClipboardCopyState` (a kit `@Observable` with an injected sleep)
**Planned:** 2026-11-22 against `main` @ `4ca4a23`
**Review:** [`S16-58-toast-stack.review.md`](S16-58-toast-stack.review.md) — Fits with changes / Ready with changes, 1 round; board checked 2026-11-22

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

Every toast in the workspace window joins one stack in the content pane's top-trailing corner, newest on top, each card leaving on its own five-second timer or its dismiss button. A second toast no longer replaces the first, a window toast and a page's toast no longer land on top of each other, and the same message again refreshes the card on screen instead of adding a second one. The Citation composer's saved-bridge toast moves from the foot of its observations column into the stack.

**Why now.** Batch 6 takes parked ideas one at a time; this is [`stacked-toasts.md`](../stacked-toasts.md), from dogfood while choosing portraits (bar 32). It also closes S16-56's review finding QCK-1: the failed recount's toast moves out of `WorkspaceView` into a model a test drives.

**What stays.** The `PVToast` card and every toast's copy and tone. Every caller except the composer still sets its own `toast` binding (S16-59 moves them). The likeness viewer's sheet and Onboarding draw their own single toast. The sidebar badges keep their last values when a recount fails.

## 2. User stories

**US-1.** As a researcher, when I act twice in a row, I see both toasts, stacked, so that I can read the first one too.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | On a Person page, choose portrait A, then portrait B within five seconds | Two success cards, B's on top of A's, in the content pane's top-trailing corner under the toolbar (TS-2, TS-3) |
| AC-1.2 | Two cards on screen; dismiss the lower one | The upper card stays and leaves five seconds after it appeared, not five seconds after the dismiss |
| AC-1.3 | Two cards added two seconds apart | Each leaves five seconds after it was added; the lower (older) one first |
| AC-1.4 | A save toast on the Source page while the counts failure toast is on screen | Both cards in one column, never one over the other (TS-4) |

**US-2.** As a researcher, when the same message repeats, I see it once, so that a burst of one failure does not fill the window.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | The counts failure (danger, `Couldn’t refresh catalog counts` / message M) is on screen with a success card above it; the recount fails again with message M | One danger card, now on top; its five seconds restart; VoiceOver does not read it again (TS-5) |
| AC-2.2 | The same failure with a different message M2 | A second danger card (the message differs) |
| AC-2.3 | The counts failure card was dismissed; the recount fails again with M | The danger card is added again |

**US-3.** As a researcher, the composer's toast shows where every other toast shows.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | In the Citation composer, save a bridge | `Bridge saved` / its reading sentence shows in the window's stack, top-trailing; nothing draws at the foot of the observations column (TS-7) |

**US-4.** As a researcher in a sheet, the toast stays in the sheet.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | In the likeness viewer (Person page Gallery, open a likeness), choose it as the portrait | The toast shows inside the viewer's sheet, not in the window's stack behind it |

**US-5.** As a researcher with Reduce Motion on, cards fade in and out instead of sliding (TS-8).

| AC | Given / when | Then |
| --- | --- | --- |
| AC-5.1 | Reduce Motion on; a toast is added, then dismissed | The card fades in and fades out; it does not slide |

## 3. Scope

| In | Covered by |
| --- | --- |
| Kit `PVToastList` *(new)*: add (newest first, a repeat refreshes), dismiss, each entry's own expiry | STEP-2, AC-1.2, AC-1.3, AC-2.1 |
| Kit `PVToastStack` *(new)* drawing the list (TS-1, TS-2, TS-6, TS-8, TS-W1) | STEP-3, AC-1.1, AC-5.1 |
| The list is in the environment (`\.pvToastList`); a sheet clears it for its content | STEP-3, AC-4.1 |
| `vocabularyToastOverlay` forwards into the list when one is in the environment | STEP-4, AC-1.1, AC-1.4 |
| `WorkspaceView`'s two overlays go; the stack draws over the content pane; notices and history issues join it | STEP-6, AC-1.4 |
| `CatalogCounts` adds the failed recount's toast to the list (QCK-1) | STEP-5, AC-2.1–AC-2.3 |
| The composer's saved-bridge toast is added to the list; `bridgeToast` goes (TS-7) | STEP-7, AC-3.1 |
| Kit README rows and the brief's handoff | STEP-8 |

| Out | Home |
| --- | --- |
| Each other caller adding to the list directly; the forwarding, `session.noticeToast`, `\.pvToastList` and `PVSheetChrome`'s clear going | S16-59 |
| One expiry mechanism for the single cards left (`OnboardingView`, a sheet's card) | not planned (two callers, no refresh need; the kit README names the split, STEP-8) |
| Onboarding's toast (`OnboardingView`) | not planned (no workspace window; working rule) |
| A toast raised inside a sheet joining the window's stack | not planned (working rule: a sheet keeps its own toast) |
| A cap, a pile or a "+N more" line | not planned (refused, user 2026-11-17) |
| A toast action button (the web kit's `action` slot) | not planned |
| Moving `presentHistoryIssueIfNeeded` out of `WorkspaceView` | not planned (it reads `WorkspaceNavigation`, which the view owns; only its target changes here) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Toast card | `macos/App/DesignSystem/Components/Toast/PVToast.swift` `PVToast` | One card, max 360 pt. Auto-dismisses after `autoDismissAfter` (default `defaultAutoDismissDelay` = 5) through a `.task(id:)` keyed on tone, title and message; `autoDismissAfter: nil` keeps it up. Announces through `pvAnnounce` on appear and on text change |
| Announce | `macos/App/DesignSystem/Components/Announce/PVAnnounce.swift` `PVAnnounceModifier` | Speaks on `onAppear` and on a change of text; the same text while mounted is not spoken again |
| Page toast overlay | `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift` `vocabularyToastOverlay(_:identifier:)`, `VocabularyToastOverlay` | Draws one `PVToast` top-trailing with `.padding(PVSpacing.space8)`, `.id(toast)`, slide-from-trailing plus opacity, `.animation(reduceMotion ? nil : PVMotion.easeStandard, value: toast)`; dismiss sets the binding nil |
| Toast value | `macos/App/Features/CatalogVocabulary/VocabularyPane.swift` `VocabularyToast` | `title: String`, `body: String` (empty means title only), `tone: PVToastTone`; `Equatable, Hashable` |
| Callers of the overlay | `PropertiesView.swift:74`, `SourcePageView.swift:131`, `SourcesListView.swift:81`, `SourceTypePageView.swift:43`, `MetadataView.swift:76`, `EvidenceGraphView.swift:161`, `ConclusionDetailPage.swift:198`, `ConclusionPictureViewer.swift:156` (in a sheet), `WorkspaceView.swift:71-78` | Each draws its own card in its own top-trailing corner |
| Window toasts | `macos/App/Features/Workspace/WorkspaceView.swift` `WorkspaceView` | `@State countsToast` and `session.noticeToast` each have a `.vocabularyToastOverlay` on the whole window (sidebar and toolbar included). `presentCountsErrorIfNeeded` (on `.onChange(of: catalogCounts.lastRefreshError)`) and `presentHistoryIssueIfNeeded` set `countsToast`; a history issue replaces a counts toast |
| Notice | `macos/App/Features/Workspace/Session/WorkspaceSession.swift` `WorkspaceSession.noticeToast` | Set by `SourceTypePageModel.swift:454`, `WorkspaceNavigation.swift:359`, `PromoteModel.swift:378` |
| Counts | `macos/App/Features/Catalog/CatalogCounts.swift` `CatalogCounts.refreshAll`, `lastRefreshError`, `clearRefreshError` | A failure sets `lastRefreshError`; the view toasts it and clears it. No test can drive the toast (QCK-1) |
| Content pane | `macos/App/Features/Workspace/WorkspaceContent.swift` `WorkspaceContent` | `WorkspaceToolbar` above `WorkspaceDestinationHost` in a `VStack` |
| Composer toast | `macos/App/Features/CitationComposer/CitationComposerModel.swift` `bridgeToast: (title: String, message: String)?`; set in `CitationComposerModel+Authoring.swift` (`bridgeSavedTitle`, `bridgeSavedBody` / `duplicateSavedBody`); drawn by `CitationComposerSubjectGroups.swift` `CitationComposerObservationsColumn` `.overlay(alignment: .bottom)` with `PVToast(tone: .success, …)` | At the foot of the observations column, outside the window's corner |
| Likeness viewer | `macos/App/Features/Conclusions/ConclusionLeadModel.swift` `toastInViewer`, `viewerOpened`, `viewerClosed`; `ConclusionGallerySection.swift:60` `.pvSheet(item:)` | The viewer (a sheet) draws the lead's toast; the page passes `.constant(nil)` while it is open |
| Sheet chrome | `macos/App/DesignSystem/Components/Panel/PVSheet.swift` `PVSheetChrome` | Sets `\.pvSheetClose` and `\.pvSheetInnerEditOpen` on its content |
| Injected sleep | `macos/App/DesignSystem/Components/ClipboardButton/PVClipboardButton.swift` `PVClipboardCopyState` | Kit `@MainActor @Observable` with `sleep: @MainActor (Duration) async -> Void`, one `Task` per timer, `guard !Task.isCancelled` after the sleep |
| Tests | `macos/ProvenenciaTests/CatalogCountsTests.swift` (`refreshAllFailureSetsLastRefreshErrorAndLeavesBadgesUnset`, `refreshAllSuccessClearsLastRefreshError`, `writeRecountFailureSetsErrorEachTime`, `refreshAllOnEmptyProjectYieldsZero`); `PVClipboardButtonTests.swift` (its private `Timer`); `SourceTypePageModelTests.swift` asserts `session.noticeToast` | `CatalogCounts(projectDir:store:)` is also built in `SourcePageModelTests.swift:1653`, `CatalogSessionStoreTests.swift:64`, `WorkspaceSidebarSectionsTests.swift:11`, `SourceCopyModelTests.swift:278` |

**Precedent.** `PVClipboardCopyState` (`86e81a0`) is the shape for `PVToastList`: a kit `@Observable` class that owns its timers with an injected sleep, so a test proves the timing without a window or a real wait; copy its `Task` and cancellation pattern. `PVSheetChrome`'s `.environment(\.pvSheetClose, …)` with its `PVSheetCloseKey` is the shape for `\.pvToastList`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The window's list is a kit type, `PVToastList` *(new)*, `@MainActor @Observable final class` in `DesignSystem/Components/Toast/PVToastList.swift`, holding `private(set) var entries: [PVToastEntry]` (newest first). `PVToastEntry` *(new)*: `Identifiable, Equatable` with `id: UUID`, `tone: PVToastTone`, `title: String?`, `message: String?` | It is content-agnostic (tone and two strings), the kit stack draws it, and the kit's sheet chrome clears it (D-5); a `Features/` type cannot be named there | A model in `Features/Workspace/` — the kit could not name it; a `[VocabularyToast]` — a feature type |
| D-2 | `WorkspaceSession` owns the window's list: `let toasts: PVToastList` *(new)*, an `init` parameter `toasts: PVToastList = PVToastList()` | The session is the one object every workspace model already holds, so S16-59 moves callers to `session.toasts.add` with no new plumbing; `WorkspaceView` builds `CatalogCounts` from the same session in its `init` | `@State` on `WorkspaceView` — S16-59's models could not reach it; a second environment object — two ways to reach one list |
| D-3 | Expiry is in the model: `add` starts a `Task` per entry that awaits `sleep(PVToastList.lifetime)` *(new, `.seconds(PVToast.defaultAutoDismissDelay)`)* and then removes that entry unless cancelled; `dismiss` cancels only that entry's task. `init(sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) })`. The stack's cards pass `autoDismissAfter: nil` | A test drives the timers with no window (map Check); a refresh must restart a timer whose content did not change, which `PVToast`'s content-keyed `.task(id:)` cannot | View-owned timers (`PVToast`'s `.task`) — untestable without a window, and blind to a refresh |
| D-4 | `add(tone:title:message:)` first turns an empty title or message into `nil` (the one place this rule lives); then an entry equal on tone, title and message moves to index 0, keeps its `id`, and its timer restarts (old task cancelled, new task started); otherwise a new entry is inserted at index 0. No cap | Working rule; the kept `id` keeps the card's view identity, so `pvAnnounce` does not speak again | A new id on refresh — VoiceOver would read it again |
| D-5 | The list reaches views through a kit `EnvironmentKey`: `EnvironmentValues.pvToastList: PVToastList?` *(new)*, default `nil`, declared in `PVToastList.swift`. `WorkspaceView` sets it to `session.toasts`; `PVSheetChrome` sets it to `nil` for its content. Its one reader is D-6's forwarding (the stack reads the session, D-8), so it is transitional: S16-59 deletes it | A sheet covers the window, so every toast inside any `.pvSheet` draws in the sheet (AC-4.1) — fixed once in the sheet chrome, not at the viewer's call site; a custom key can be cleared, as `\.pvSheetClose` is set | `.environment(object)` by type — no clean way to clear it in a sheet; a `forwards: false` flag at `ConclusionPictureViewer` — the next sheet with a toast would forward behind itself |
| D-6 | `VocabularyToastOverlay` reads `\.pvToastList`. With a list: `.onChange(of: toast, initial: true)` adds a non-nil toast through `PVToastList.add(_ toast: VocabularyToast)` *(new, a one-line forward to `add(tone:title:message:)`, a feature extension beside `VocabularyToast` in `VocabularyPane.swift`)* and sets the binding to nil; it draws no card, and its `identifier` is used only on the card path. Without a list: today's card, unchanged | Every page's toasts stack with no caller change (map); `initial: true` forwards a toast set before the overlay mounted | Forwarding through `onAppear` plus `onChange` — two paths for one rule |
| D-7 | `PVToastStack(list:)` *(new)*, `DesignSystem/Components/Toast/PVToastStack.swift`: a `VStack(alignment: .trailing, spacing: PVSpacing.space4)` of `ForEach(list.entries)` `PVToast(tone:title:message:onDismiss: { list.dismiss(entry.id) }, autoDismissAfter: nil)`, padded `PVSpacing.space8`, in a frame filling its container aligned `.topTrailing`, `.clipped()`. Transition (the board's values): `.asymmetric(insertion: .offset(x: PVToastStack.slideDistance).combined(with: .opacity).animation(PVMotion.easeOut), removal: .offset(x: PVToastStack.slideDistance).combined(with: .opacity).animation(PVMotion.easeIn))` with `static let slideDistance: CGFloat = 28` *(new)*; under `accessibilityReduceMotion`, `.opacity.animation(.linear(duration: PVMotion.durationNormal))`. The cards around one that enters or leaves move with `.animation(PVMotion.easeStandard, value: list.entries.map(\.id))`, or with no animation under Reduce Motion. `.accessibilityIdentifier("workspace.toasts")` on the column. With no entries it draws nothing (no container). The column and its frame have no background or `contentShape`, so a click outside a card reaches the page | TS-1, TS-2, TS-6, TS-8 and the board's motion (28 pt, 200 ms ease-out in, ease-in out, a linear fade under Reduce Motion; `PVMotion.durationNormal` is 0.2 s and `easeOut` / `easeIn` are its curves); the rule says Reduce Motion fades (today's overlay drops the animation instead) | A `ScrollView` for a burst — TS-6 cuts it at the pane's edge; no animation under Reduce Motion — the rule says it fades |
| D-8 | `WorkspaceContent` draws `PVToastStack(list: session.toasts)` as `.overlay` on `WorkspaceDestinationHost`, reading `@Environment(WorkspaceSession.self)` (as `WorkspaceDestinationHost` does) | TS-2: under the toolbar, over the content pane, never over Back, Forward, the breadcrumbs or the sidebar | On `WorkspaceView` — it would cover the sidebar and toolbar, as the window's toasts do today; reading `\.pvToastList` — the key goes in S16-59, the session stays |
| D-9 | `WorkspaceView`: `countsToast`, its overlay, `presentCountsErrorIfNeeded` and the `.onChange(of: catalogCounts.lastRefreshError)` go. `presentHistoryIssueIfNeeded` calls `session.toasts.add(tone: .danger, …)` with today's copy. `session.noticeToast` keeps its `.vocabularyToastOverlay` binding, placed before `.environment(\.pvToastList, session.toasts)` in the modifier chain so it forwards | One list, no window-level card; the notice keeps working until S16-59 | Forwarding `noticeToast` by hand in the view — a second forwarding path beside D-6 |
| D-10 | `CatalogCounts.init(projectDir:store:toasts:)` takes the list (required); a failed `refreshAll` adds `tone: .danger`, title `L10n.string(L10n.Workspace.countsRefreshFailedTitle)`, message `L10n.Errors.message(for: error)`. `lastRefreshError` and `clearRefreshError()` go | QCK-1: a test drives the toast through the model; with D-4 a repeat of the same failure refreshes, and one after a dismiss adds again (AC-2.1, AC-2.3) | Keeping `lastRefreshError` beside the toast — a second record of one failure with no reader |
| D-11 | `CitationComposerModel+Authoring.swift`'s bridge save calls `session.toasts.add(tone: .success, title: L10n.string(L10n.CitationComposer.bridgeSavedTitle), message: message)` (the model already holds `session`); `CitationComposerModel.bridgeToast` and `CitationComposerObservationsColumn`'s `.overlay(alignment: .bottom)` go. The S16-59 map row drops `bridgeToast` | The toast moves place in this PR anyway; adding directly touches the code once instead of retyping it here and deleting it in S16-59 (review M-3) | Retyping `bridgeToast` to `VocabularyToast?` behind a forwarding overlay — two edits of one line across two PRs |
| D-12 | The test sleep moves to a shared helper `ManualSleep` *(new)*, `macos/ProvenenciaTests/ManualSleep.swift`, the body of `PVClipboardButtonTests`'s private `Timer` (`sleep`, `settle`, `fire(_:)`, `sleeps`); `PVClipboardButtonTests` uses it | Two suites need it; reuse beats a copy | A second private copy in `PVToastListTests` |

**Rules this plan bends.**

| Rule | Bent by | Answer | Step |
| --- | --- | --- | --- |
| [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md) and `docs/design-system-layers.md`: a kit piece needs two real call sites | D-1, D-7: `PVToastList` and `PVToastStack` in `DesignSystem/Components/` with one caller (the workspace window) | The user, 2026-11-17: working rule "(Batch 6) One toast stack per window" names a kit `PVToastStack` | STEP-8: the README's Toast row says it is a one-caller kit piece by that rule |

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `PVToastList`, `PVToastEntry` *(new)* | type | `PVClipboardCopyState` (searched `@Observable` under `DesignSystem/`, "toast" across `macos/App`) | A different job (one flag); it is the pattern copied, not the type |
| `EnvironmentValues.pvToastList` *(new)* | key | `\.pvSheetClose` (`PVSheetCloseKey`) | Different value; same shape |
| `PVToastStack` *(new)* | component | `VocabularyToastOverlay` (feature, one card) | It draws one optional toast from a binding; the stack draws a list, and the overlay becomes its forwarder |
| `PVToastList.add(_: VocabularyToast)` *(new)* | func | `VocabularyToastOverlay`'s card mapping (`toast.body.isEmpty ? nil : toast.body`) | A one-line forward; the empty-to-nil rule moves into the kit `add` (D-4), so every caller matches repeats the same way |
| `WorkspaceSession.toasts` *(new)* | property | `WorkspaceSession.noticeToast` | The notice is one optional value; it stays until S16-59 |
| `VocabularyToastTests.swift` *(new)* | test file | `PVToastListTests` | T-7 tests a feature extension; the kit suite tests only the kit |
| `ManualSleep` *(new)* | test helper | `PVClipboardButtonTests.Timer` (private) | Moved, not copied |

**Builds on.** `PVToast` (each card), `PVToast.defaultAutoDismissDelay`, `pvAnnounce`, `PVMotion.easeStandard`, the `PVSheetChrome` environment pattern, the `PVClipboardCopyState` timer pattern.
**Deletes.** `CitationComposerModel.bridgeToast`; `WorkspaceView.countsToast`, `presentCountsErrorIfNeeded`, the `.onChange(of: catalogCounts.lastRefreshError)`, the `countsToast` overlay; `CatalogCounts.lastRefreshError`, `clearRefreshError()` and their doc comments; the composer's `.overlay(alignment: .bottom)` `PVToast`; `PVClipboardButtonTests.Timer` (moved). `vocabularyToastOverlay`'s card path stays (sheets use it).
**Next adds.** S16-59: each model calls `session.toasts.add(tone:title:message:)` (or `add(_: VocabularyToast)` where it already builds one); the forwarding in `VocabularyToastOverlay`, `noticeToast`, `\.pvToastList` and `PVSheetChrome`'s clear go with it. `VocabularyToast` and the overlay's card path stay only for the sheet (`ConclusionLeadModel`, `ConclusionPictureViewer`): a model that can raise a toast while its sheet is up decides where it draws, as `ConclusionLeadModel.toastInViewer` does. A new sheet uses `.pvSheet`, so its content clears the key until then.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A page's toast set before its overlay mounts (a model loads with a toast) | `VocabularyToastOverlay` | `onChange(initial: true)` forwards it on mount |
| A page left while its card is on screen | `PVToastStack` | The card lives in the session's list and leaves on its timer; today it vanished with the page. Intended: the toast outlives the page that raised it |
| The workspace closed (sign out, project switch) with cards up | `PVToastList` | Each task holds `[weak self]`; the session and its list go with `WorkspaceView` |
| Many cards (a burst) | `PVToastStack` | Cut at the pane's edge (TS-6); clicks outside a card reach the page (no `contentShape` on the column) |

### Scale

None — no catalog read or write. The list holds what the researcher's actions raise in five seconds; each entry owns one sleeping task; no cap by rule.

### Edges

- **Assumptions.** `PVAnnounce` speaks on appear: a refreshed entry keeps its `id`, so its card keeps its identity and is not spoken again (T-3). A cancelled task must not remove its entry after the sleep returns: `guard !Task.isCancelled` (T-3, T-4).
- **Neighbors.** Same tone and title, different message → two cards (T-5). Same title and message, different tone → two cards (T-5). A title-only toast equals another title-only toast with that title, whether its message is `nil` or `""` (T-6).
- **Coalesced sets.** A model that sets an equal `VocabularyToast` twice within one update is forwarded once; the result is the same single card a repeat gives.
- **Removed inputs.** A dismissed entry's timer firing later removes nothing else (T-4). `dismiss` of an unknown id does nothing (T-4).
- **The lead's toast.** A page card forwarded before the likeness viewer opens stays in the window's stack until its timer; `viewerOpened()` clears only the binding. The viewer draws its own toasts in the sheet (D-5), so no toast shows twice; the S13-15 D-10 rule (one surface per toast) holds.
- **Real data / Untrusted size.** None — no data from the catalog.

### Schema

None — no catalog change.

### Go core

None — Swift only.

### FFI

None —.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Toast | `PVToast` | `DesignSystem/Components/Toast/PVToast.swift` | Unchanged; the stack passes `autoDismissAfter: nil` |
| Toast stack | `PVToastStack` *(new)* | `DesignSystem/Components/Toast/PVToastStack.swift` | D-7; brief TS-1, TS-2, TS-6, TS-8, TS-W1 |
| Toast list | `PVToastList` *(new)* | `DesignSystem/Components/Toast/PVToastList.swift` | D-1 – D-5 |
| The window's toasts | `WorkspaceView`, `WorkspaceContent` | `Features/Workspace/` | D-8, D-9 |
| A page's toast | `vocabularyToastOverlay` | `Features/CatalogVocabulary/VocabularyChrome.swift` | D-6 |
| Composer toast | `session.toasts` | `Features/CitationComposer/CitationComposerModel+Authoring.swift` | D-11; the column's overlay goes |
| Sheet | `PVSheetChrome` | `DesignSystem/Components/Panel/PVSheet.swift` | Clears `\.pvToastList` (D-5) |

Signatures:

```swift
@MainActor @Observable
final class PVToastList {
    static let lifetime: Duration = .seconds(PVToast.defaultAutoDismissDelay)
    private(set) var entries: [PVToastEntry] = []
    init(sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) })
    func add(tone: PVToastTone, title: String?, message: String?)
    func dismiss(_ id: PVToastEntry.ID)
}
struct PVToastStack: View { let list: PVToastList }
extension EnvironmentValues { var pvToastList: PVToastList? }
```

States: none (no cards: no view at all); one; many (cut at the pane's bottom). Accessibility: each card announces once (`PVToast`), its dismiss button is labelled (`L10n.DesignSystem.toastDismiss`); `PVToastTone` keeps its fileprivate color and icon.

### Strings

None — no new copy; every card shows copy the app already has. No action changes what it covers.

## 7. Steps

**STEP-1 — Shared manual sleep**
Files: `macos/ProvenenciaTests/ManualSleep.swift` *(new)*, `macos/ProvenenciaTests/PVClipboardButtonTests.swift`. Skill: `add-swift-test`.
Do: move `Timer` to `ManualSleep` (D-12); the clipboard tests use it.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVClipboardButtonTests` passes.

**STEP-2 — The list**
Files: `macos/App/DesignSystem/Components/Toast/PVToastList.swift` *(new)*, `macos/ProvenenciaTests/PVToastListTests.swift` *(new)*. Skill: `add-ui-component`, `add-swift-test`.
Do: `PVToastEntry`, `PVToastList` (D-1, D-3, D-4) and the `\.pvToastList` key (D-5). Tests T-1 – T-6.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVToastListTests` passes.

**STEP-3 — The stack, and sheets keep their own toast**
Files: `PVToastStack.swift` *(new)*, `macos/App/DesignSystem/Components/Panel/PVSheet.swift` (`PVSheetChrome`). Skill: `add-ui-component`.
Do: D-7, with a `#Preview` of three entries on a list built with `PVToastList(sleep: { _ in await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in } })`, a sleep that never returns, so the cards stay; `PVSheetChrome` adds `.environment(\.pvToastList, nil)` beside `\.pvSheetClose` (D-5).
Check: the project builds; the preview shows three stacked cards top-trailing.

**STEP-4 — Pages forward into the list**
Files: `macos/App/Features/CatalogVocabulary/VocabularyChrome.swift`, `VocabularyPane.swift`.
Do: D-6; `PVToastList.add(_: VocabularyToast)` beside `VocabularyToast`. T-7.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PVToastListTests` passes.

**STEP-5 — The session holds the list, and a failed recount adds its toast**
Files: `macos/App/Features/Workspace/Session/WorkspaceSession.swift`, `macos/App/Features/Catalog/CatalogCounts.swift`, `macos/App/Features/Workspace/WorkspaceView.swift` (`init` and the counts path only), `.agents/skills/use-catalog-session/SKILL.md`, `macos/ProvenenciaTests/CatalogCountsTests.swift`, and the `CatalogCounts(projectDir:store:)` call sites in `SourcePageModelTests.swift`, `CatalogSessionStoreTests.swift`, `WorkspaceSidebarSectionsTests.swift`, `SourceCopyModelTests.swift`. Skill: `add-swift-test`.
Do: D-2 (with the doc comment on `WorkspaceSession` naming `toasts`) and D-10. `WorkspaceView.init` builds `CatalogCounts(projectDir:store:toasts: session.toasts)`; `presentCountsErrorIfNeeded` and its `.onChange` go. The skill's line becomes: "Badge refresh (`CatalogCounts.refreshAll`) must not swallow errors silently: a failure adds a danger toast to the window's list (`CatalogCounts(projectDir:store:toasts:)`)." `CatalogCountsTests.makeCounts(store:toasts:)` takes `toasts: PVToastList = PVToastList(sleep: ManualSleep().sleep)`, so no entry expires during a test; T-8 builds its own list, passes it, and dismisses with `toasts.dismiss(toasts.entries[0].id)`. The other files pass `toasts: PVToastList()`. T-8, T-9. One commit.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/CatalogCountsTests` passes; the app builds.

**STEP-6 — The window draws one stack**
Files: `WorkspaceView.swift`, `WorkspaceContent.swift`.
Do: D-8, D-9 (the `countsToast` state and overlay go; history issues add to `session.toasts`; the notice overlay forwards).
Check: the app builds; manual checks 1 and 2.

**STEP-7 — The composer's toast joins the stack**
Files: `macos/App/Features/CitationComposer/CitationComposerModel.swift`, `CitationComposerModel+Authoring.swift`, `CitationComposerSubjectGroups.swift`.
Do: D-11.
Check: the app builds; `rg -n bridgeToast macos` finds nothing; manual check 4.

**STEP-8 — Kit README**
Files: `macos/App/DesignSystem/README.md`.
Do: the Toast row names `PVToastStack.swift` and `PVToastList.swift`: one list per workspace window, newest first, a repeat refreshes, a sheet clears `\.pvToastList` and draws its own card. Cards in a stack expire through `PVToastList`; a single `PVToast` keeps `autoDismissAfter`; a single card that needs a refresh moves to a list, not to a third timer. The stack is a one-caller kit piece by the working rule "(Batch 6) One toast stack per window".
Check: `python3 scripts/check-guidance-names.py` passes.

**STEP-9 — Docs**
Files: `completed.md`, `deployment-plan.md` (map row), this plan (status), `design/S16-D10-toast-stack.md` → `design/archive/`, `design/README.md`.
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py` on the changed docs reports no errors.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PVToastListTests.swift` `addPutsNewestFirst` *(new)* | add A, add B → `entries` titles `[B, A]`; two sleeps started | AC-1.1, D-4 |
| T-2 | Swift | `PVToastListTests` `eachEntryLeavesOnItsOwnTimer` *(new)* | add A, add B; fire A's sleep → `[B]`; fire B's → `[]` | AC-1.3, D-3 |
| T-3 | Swift | `PVToastListTests` `repeatMovesToTopKeepsIdAndRestartsTimer` *(new)* | add A, add B, add A again → `[A, B]`, A's `id` unchanged, three sleeps; fire A's first sleep → still `[A, B]`; fire A's third → `[B]` | AC-2.1, D-4 |
| T-4 | Swift | `PVToastListTests` `dismissKeepsTheOtherTimer` *(new)* | add A, add B; `dismiss(B.id)` → `[A]`, no new sleep; fire B's sleep → `[A]`; fire A's → `[]`; `dismiss` of an unknown id → no change | AC-1.2, D-3 |
| T-5 | Swift | `PVToastListTests` `differentToneOrMessageAddsACard` *(new)* | (success, "Saved", "x") then (danger, "Saved", "x") → 2 entries; then (success, "Saved", "y") → 3 | AC-2.2, D-4 |
| T-6 | Swift | `PVToastListTests` `titleOnlyRepeatRefreshes` *(new)* | (info, "Filed", nil) then (info, "Filed", "") → 1 entry, `message == nil` | D-4 |
| T-7 | Swift | `VocabularyToastTests.swift` `addingAVocabularyToastForwardsItsFields` *(new)* | `add(VocabularyToast(title: "Filed", body: "", tone: .info))` → one entry, title "Filed", `message == nil`, tone `.info` | D-6 |
| T-8 | Swift | `CatalogCountsTests` `writeRecountFailureAddsToastEachTime` *(replaces `writeRecountFailureSetsErrorEachTime`)* | good count; a write's recount fails → one danger entry, title `countsRefreshFailedTitle`, message `L10n.Errors.unknown`, `counts.sources == 1`; fails again → still one entry; dismiss it; fails again → one entry | AC-2.1, AC-2.3, D-10 |
| T-9 | Swift | `CatalogCountsTests` `refreshAllFailureAddsToastAndLeavesBadgesUnset` *(renamed from `refreshAllFailureSetsLastRefreshErrorAndLeavesBadgesUnset`)*, `refreshAllSuccessAddsNoToast` *(renamed from `refreshAllSuccessClearsLastRefreshError`)*, `refreshAllOnEmptyProjectYieldsZero` *(edited)* | assertions on `lastRefreshError` become assertions on the list's entries | D-10 |

The stack, the forwarding into it, the sheet's clearing and the composer's save are views or have no test harness today (no test saves a bridge); the manual check covers AC-1.1, AC-1.4, AC-3.1, AC-4.1 and AC-5.1.

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `CatalogCountsTests`, `PVClipboardButtonTests`, `PVToastTests` (the single card's timer, unchanged), `SourceTypePageModelTests` (asserts `session.noticeToast`, which stays).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`lastRefreshError`, `clearRefreshError`, `presentCountsErrorIfNeeded`, `countsToast`, `bridgeToast`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: none expected; stacked-toasts.md already says it
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

On a project with a Person who has two likenesses from two Sources:

1. Person page, Gallery: choose likeness A as the portrait, then B within five seconds. Two `Portrait updated` cards, B's on top, top-trailing under the toolbar; neither covers Back, Forward or the omnibar. Dismiss the lower; the upper leaves about five seconds after it appeared (AC-1.1, AC-1.2, AC-1.3).
2. Open a Source page and save its title; within five seconds go to Source types and leave a type page that raises a notice (or Promote a record, whose notice is a window notice): both cards in one column (AC-1.4).
3. AC-2.1 – AC-2.3 have no switch in the app that fails a recount on demand; T-8 covers them, and the PR says so.
4. Citation composer: save a bridge. `Bridge saved` shows in the stack top-trailing; nothing at the foot of the observations column (AC-3.1).
5. Person page, Gallery, open a likeness in the viewer and choose it: the toast shows inside the viewer, not behind it (AC-4.1).
6. System Settings → Accessibility → Display → Reduce motion on: repeat step 1; cards fade, no slide (AC-5.1).
7. Fourteen toasts in a row (choose portraits back and forth quickly): the column is cut at the pane's bottom; a click on the page beside the column works (TS-6).
8. Repeat step 1 in a Wide window (pane ≥ 1600 pt): the stack is 360 pt wide in the same corner (TS-W1).

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| A toast raised inside a sheet forwards to the window's stack behind the sheet | D-5 clears `\.pvToastList` in `PVSheetChrome`; manual check 5 |
| The overlay on `WorkspaceView` that forwards `noticeToast` sits outside `.environment(\.pvToastList, …)` and draws its own card | D-9 names the order; manual check 2 shows a notice in the stack |
| The column's empty area swallows clicks on the page | D-7 draws no background; manual check 7. If it fails, stop and report |

**Stop and report if:**

- The composer's board draws its `Bridge saved` toast anywhere but the window's stack (TS-7, D-11).
- `PVToast`'s announce speaks again when a refreshed card moves to the top (T-3 holds the id, but VoiceOver in manual check says otherwise): D-4 needs a different identity rule.
- A caller other than those in §4 draws a `PVToast` inside the workspace (`rg -n "PVToast\(" macos/App/Features` finds one beyond `VocabularyChrome.swift`, `OnboardingView.swift` and, until STEP-7, `CitationComposerSubjectGroups.swift`).
- A test outside §8 asserts `CatalogCounts.lastRefreshError`.
- Manual check 7 finds a click beside the column does not reach the page.

## 12. Open questions

None.

## 13. PR

**Title:** S16-58 — Toasts stack in one list per window
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-58-toast-stack.md`.
