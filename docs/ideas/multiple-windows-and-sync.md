# Multiple windows, and sync between researchers

Parked (user, 2026-11-18). Spike 16 Batch 7 locked the app to one workspace window (S16-60) and removed what was built for a second one (S16-61), because planning for two windows kept slowing early work. Both ideas here are long-term.

## Multiple windows with live data

Every window lives in one process and calls one Go core, so the catalog's exclusive lock (`PRAGMA locking_mode=EXCLUSIVE`, one connection, `catalogsession`'s one queue) does not stand in the way. What a return to `WindowGroup` needs:

1. **Several projects at once, or one project per app.** `catalogsession.getOrOpen` closes every other session before opening a project, so two windows on two projects would close and reopen each other's catalog on every call.
2. **A shared session closes with its last window.** `WorkspaceView.onDisappear` closes the catalog session; with two windows on one project it needs a count of the windows using it.
3. **Every window learns of every commit.** Each window has its own `WorkspaceSession` cache. Go should announce each commit's effects (`Catalog.Listen`, `CommitListener`) and every window, the writer included, applies them from that announcement, not from the writer's reply.
4. **Menu commands follow the key window.** `SignOutCoordinator`, `NavigationCoordinator` and `OmnibarFocusCoordinator` are app-wide; they become `@FocusedValue` / `.focusedSceneValue`.
5. **Per-window restore.** Navigation history is saved per project; two windows on one project need per-window state (`@SceneStorage`).
6. **Sign-out is app-wide.** Signing out in one window signs out all.
7. **What S16-61 removed comes back, built on point 3.** The Artifact sheet closing with a toast when its Artifact leaves the page (`SourceArtifactsSection.workspaceChanged`, S15-34 AC-3.5), and the sheet's handling of a graph deleted or made while it is open (`liveGraphIDs`, `savedGraphIDs`, S15-10 AC-3.4). Git has the old versions.

The one-window-per-project variant (opening an open project focuses its window) avoids 2, 3 and 5.

## Two researchers on one project, through a sync server

Two local copies, kept in step through a server (not data held in the cloud). It shares the receiving end with multiple windows: a change the app did not make arrives, is committed, and every window refreshes from the commit. Point 3 above is that path, so build it from the commit. What sync adds on top:

- **A change feed.** `audit_changes` already records row-level create, update and delete per transaction (`changes_json`); every write, seeding and open-time repairs included, would have to go through it.
- **Ordering and conflicts.** Concurrent edits to one field; a delete on one side while the other links to the deleted row. `deleteimpact`'s refusals are local and can be broken by a merge of two valid histories.
- **Identity and uniqueness.** UUIDv7 ids are safe; short refs (`SRC-…`) and `UNIQUE` columns can collide across machines and need a merge rule.
- **Derived caches** rebuilt from remote commits (search index, graph cache, match index).
- **Files.** `objects/` syncs apart from SQLite; a row can arrive before its file.
- **Catalog format.** Two copies on different `user_version` must refuse or translate.
- **The server, accounts and permissions.**
