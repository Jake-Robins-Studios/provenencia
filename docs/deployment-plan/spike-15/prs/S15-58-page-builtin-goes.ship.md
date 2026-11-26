# Ship log — S15-58 The page built-in goes

**Plan:** [`S15-58-page-builtin-goes.md`](S15-58-page-builtin-goes.md) · **Branch:** `s15-58-page-builtin-goes` · **PR:** #987
**State:** ready

## Round 0 — implement
Head `d6d1fc323`. Gate PASS (orchestrator run). Report deviations: bump is 0.44.1 → 0.45.0 (`main` moved); `docs/citation-formats.md` changed in the first commit because `TestDocMatchesEngine` needs it; regenerated `engine.pb.swift` drops swift-protobuf `_storage` indirection (generator output); §10 manual check not run (left to the user). Note: `bin/reseed-source-vocab` vet error is an untracked local folder, not on `main`; not this PR.

## Round 1 — review
Base `6aed8ffeb`, head `d6d1fc323`. Reviewers: CON, MNT, UX, SEC+PRF (route-reviewers: all RUN).


| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | minor | Unknown/supplied tests dropped their locator page marks, against D-3 | Fix now → F-1 | verified: diff of `render_test.go` and `citation_render_test.go` replaces `page_unknown` / `page_label`+`page_supplied` locators with `pageLocator("1")`; D-3 says locator JSON stays as written |
| MNT-1 | MNT | minor | Two doc comments still name the printed page on a Source board | Fix now → F-2 | verified: `sourcemetadata.go:817-819`, `engine.proto:427-428` |
| UX-1 | UX | minor | `{citation.page}` mistake does not point to `{meta.page}` | Follow-up | D-1 rejects a retired-placeholder code; a generic "did you mean a field" hint on `unknown_builtin` is new work for every unknown name, not this PR's code |
| — | SEC+PRF | — | No findings | — | — |

Nits (logged): `MNT-2 / CON-2 · core/database/citationrender/render_test.go:596 · TestGroupKey ranges over map[*[]byte]string; a slice of pairs reads better` · `UX-2 · plan §10 · manual check not run; user runs it before merge`

### Fix plan 1

**F-1 — Restore the locator page marks in the unknown/supplied tests** (from CON-1)
Files: `core/database/citationrender/render_test.go` (`TestRenderUnknownAndSupplied`), `api/ffi/handlers/citation_render_test.go` (`TestRenderCitations` "AC-1.6 unknown and supplied values").
Failing test first: none (test-only, per D-3).
Do: put back the original locators, `{"version":1,"selectors":[{"type":"page","page_unknown":true}]}` for A and `{"version":1,"selectors":[{"type":"page","page_label":"23","page_supplied":true}]}` for B, keeping the Citation `page` values the PR added. Expected text stays "n.p.; n.d.; p. unpaginated." / "[Ashby Press]; [ca. 1880]; p. [23].".
Check: both tests pass; `git diff 6aed8ffeb -- <both files> | grep page_unknown` shows no removed line for these locators; scripts/check-pr.sh PASS.

**F-2 — Drop the printed page from two comments** (from MNT-1)
Files: `core/database/sourcemetadata/sourcemetadata.go` (`ListWorkspaces`), `api/proto/engine.proto` (`CitationRequirement`), regenerated `engine.pb.go` / `engine.pb.swift`.
Do: "…what its type asks of the Source date." in `ListWorkspaces`; "…on a board, or of the Source date." on `CitationRequirement`; rerun `./scripts/generate-proto.sh`.
Check: `rg -n -i 'printed page' core/database/sourcemetadata/sourcemetadata.go api/proto/engine.proto` prints only the reserved-field comment (~engine.proto:507); scripts/check-pr.sh PASS.

## Round 1 — fix
Head `e8c29d064`. Gate PASS (orchestrator run). F-1 done: both tests carry the original `page_unknown` and `page_label`+`page_supplied` locators again beside the Citation `page` values — CON-1 **Resolved** (read by orchestrator). F-2 done: both comments name the Source date alone, proto regenerated — MNT-1 **Resolved** (read by orchestrator).
Nits (logged): `F-2 · core/database/sourcemetadata/sourcemetadata.go:819 · the reflowed comment's last line runs past the file's usual wrap`

## Round 2 — review
Not run: round 1 had no Fix-now blocker or major.

## Result
Gate PASS · `origin/main` unmoved since the branch was cut · CI <pending> · open: none · follow-ups: UX-1 · to user: —

## Cost
Plan: 4,556 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | default | 177k |
| 1 | CON | opus | 84k |
| 1 | MNT | opus | 81k |
| 1 | UX | opus | 46k |
| 1 | SEC+PRF | opus | 70k |
| 1 | implementer (fix) | default | 74k |
| | **Total** | | **532k** |
