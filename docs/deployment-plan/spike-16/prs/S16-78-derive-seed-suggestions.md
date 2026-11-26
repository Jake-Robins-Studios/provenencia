# S16-78 — Install derives each seeded type's suggested fields from its formats

**Status:** Landed in [#993](https://github.com/Jake-Robins-Studios/provenencia/pull/993) (2026-11-26)
**Landed:** As planned, then one user change after review (user, 2026-11-26: the seed is data; only `Install` and the suggestion rule are tested). D-4 and T-3's per-type and census checks are superseded: `TestSuggestedKeys` tests the rule on synthetic formats. T-4 is superseded: `TestSeedAnnotations` was deleted, with `TestSeedCitations` and its golden, `TestSeedFieldsAreRead`, `TestSeedTypes`, `TestSeededFormatsNeedOnlySuggestedFields`, `TestSeedPlaceFields`, and `TestInstall`'s 26/69 count pin. AC-1.4's census spot check went with them. See the ship log's "User change" section.
**Spike / slice:** Spike 16 · Slice 6j — A Voters list type
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the suggestion rows a new project gets are the same, so every view looks the same)
**Board:** —
**Depends on:** —
**Blocks:** S16-79
**Branch:** `s16-78-derive-seed-suggestions`
**Version bump:** none — a new project's rows are byte for byte the same; no wire or catalog change ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-seeded-vocabulary`](../../../../.agents/skills/add-seeded-vocabulary/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc`
**Context:** [`docs/seeded-vocabulary.md`](../../../seeded-vocabulary.md) § 2.3 (the suggestion rule, user 2026-11-20 and 2026-11-23); [`docs/citation-formats.md`](../../../citation-formats.md) § Needed and used; the S16-79 plan review, finding M-5 ([`S16-79-voters-list-type.review.md`](S16-79-voters-list-type.review.md)); user, 2026-11-26: "plan it first"
**Planned:** 2026-11-26 against `origin/main` @ `0886b43`; refreshed 2026-11-26 against `5b2606d` (fetch it; a local `main` may be older)
**Review:** [`S16-78-derive-seed-suggestions.review.md`](S16-78-derive-seed-suggestions.review.md) — Fits · Ready with changes, 2 rounds; no blocker open; To user: none

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

Each seeded Source type suggests exactly the fields its formats read (§ 2.3's rule), but the list is typed by hand in `seedSuggestions` and a test derives the same list to catch a difference. After this PR, `Install` derives each type's list from its formats with that rule, and the hand lists go. A new project gets the same rows in the same order.

**Why now.** S16-79 adds a type and changes eleven types' copy layer; each such change means hand-deriving lists the code already derives. The user asked for this first (2026-11-26).

**What stays.** The rule itself, the rows and sort orders a new project gets, `CopyType`, `AppendSuggestion`, researcher types (their suggestions are the researcher's, never derived).

## 2. User stories

**US-1.** As a contributor adding or changing a seeded type's formats, I write only the formats, and its suggested fields follow.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | A new project, after this PR | Every seeded type's suggestions are the lists `seedSuggestions` holds at the planning base, field for field and sort order for sort order |
| AC-1.2 | `rg -n "seedSuggestion" core docs/*.md .agents` | No hit |
| AC-1.3 | A seeded format that reads a field no `seedFields` row has | `Install` fails with `ErrInvalid` and leaves nothing (as a bad suggestion does today) |
| AC-1.4 | The census type | Suggests `creator` first and `citing` last; the spot check pins no count, so a format change does not edit it (today's literal is 18) |

## 3. Scope

| In | Covered by |
| --- | --- |
| `suggestedKeys` derives a type's list from its formats | STEP-1, AC-1.1 |
| `Install` writes the derived lists | STEP-1, AC-1.1, AC-1.3 |
| `seedSuggestions`, `seedSuggestion` and the test copy of the rule go | STEP-2, AC-1.2 |
| Tests read the derived lists | STEP-2, AC-1.4 |
| Skill and doc text | STEP-3 |

| Out | Home |
| --- | --- |
| Deriving suggestions for a researcher's type, or when a researcher edits a seeded type's formats | not planned (a researcher's list is theirs) |
| Any change to a format or to the rule | S16-79 (formats); not planned (rule) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Hand lists | `core/database/sourcevocab/registry_suggestions.go` `seedSuggestions`; `registry.go` `seedSuggestion` (type) and the header comment naming `registry_suggestions.go` | 26 lists typed by hand |
| Install | `core/database/sourcevocab/sourcevocab.go` `Install` | Loops `seedSuggestions`; an unknown type or field key is `ErrInvalid` |
| The rule, in tests | `core/database/sourcevocab/registry_test.go` `derivedSuggestions`, `mustParseForm`, `TestSeedSuggestionsFollowFormats` | Derives each list from the formats and compares it with `seedSuggestions`; spot-checks census |
| Other readers | `registry_test.go` `TestSeededFormatsNeedOnlySuggestedFields`, `TestSeedPlaceFields`; `sourcevocab_test.go` `TestInstall` ("empty catalog gets the seed", "a seed entry naming an unknown type is rejected even with no fields"), `seedSuggestionKeys` | Iterate `seedSuggestions` |
| Docs | `docs/seeded-vocabulary.md` line 83 (suggestions "live in a code registry"), § 2.3 (the comparing test, "the same 18 fields"); `.agents/skills/add-seeded-vocabulary/SKILL.md` table row, step 1's `registry_suggestions.go` bullet, step 6 | Describe hand lists |

**Precedent.** None of this shape in `sourcevocab`; `sourcetypes.RequirementsTx` (`core/database/sourcetypes/formats.go`) is the production caller of `citationformat.Requirements` to copy from.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | `suggestedKeys(f sourcetypes.Formats) []string` *(new)* in `registry_suggestions.go` holds the rule: `derivedSuggestions`' body moved onto `templates, _ := f.Parse()` (the one parse of a type's formats, as `sourcetypes.RequirementsTx` uses), reading `templates[FormFull]`, `[FormList]`, `[FormShort]` in that order; no error return | One parse path in the engine; `ToStored` refuses a bad format in `Install` before this runs, and `TestSeedTypes` fails one in tests | Its own `citationformat.Parse` loop with an error — a second parse and an unreachable error path; `sourcetypes` — the rule is the seed's |
| D-2 | `Install` calls `suggestedKeys(t.Formats)` for each type right after the type's upsert and writes the list with `ensureSuggestionTx` at positions 0 to n−1, in list order. No branch of its own for a key with no seeded field: `ToStored` has already refused such a format with `unknown_field` (→ `ErrInvalid`) | One loop instead of two; an unreachable guard is dead code | Keeping today's `fieldIDs` guard — `ToStored` runs first |
| D-3 | STEP-1 keeps `seedSuggestions` and proves the derived lists equal it in `TestInstall` before STEP-2 deletes it | Proves AC-1.1 against the hand lists rather than against the rule itself | A golden of the lists — a third copy |
| D-4 | `TestSeedSuggestionsFollowFormats` becomes `TestSuggestedKeys` *(renamed)* (cases: § 8 T-3) | The comparison it made is now the code; `TestSeedFieldsAreRead` owns "formats read only seeded fields" | — |
| D-5 | In STEP-1 the "unknown type" `TestInstall` case becomes "a seed format reading an unseeded field is rejected": it swaps `seedTypes` (restored by `t.Cleanup`) for `[]seedType{{Key: "bad_type", Label: "Bad", Description: "Bad.", IconKey: "type_document", Formats: sourcetypes.Formats{Full: "{meta.no_such_field}", Short: "{source.title}", List: "{source.title}"}}}` and keeps the `ErrInvalid` and rollback assertions; the error comes from `ToStored` | The case it covered (a suggestion naming no type) cannot be written once `Install` stops reading `seedSuggestions` | Dropping the case — loses the rollback check |
| D-6 | Tests read a seeded type's list through `suggestedKeysOf(t *testing.T, typeKey string) []string` *(renamed from `seedSuggestionKeys`)*, which returns `suggestedKeys(findSeedType(t, typeKey).Formats)` | The new name stops `rg seedSuggestion` matching a live helper | Inlining it at two call sites |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `suggestedKeys` *(new)* | func | `registry_test.go` `derivedSuggestions` | Moved from the test to the package, the test copy deleted |
| `TestSuggestedKeys` *(renamed)* | test | `TestSeedSuggestionsFollowFormats` | Renamed, its comparison gone |
| `suggestedKeysOf` *(renamed)* | test helper | `seedSuggestionKeys` | Renamed and rebased on `suggestedKeys` (D-6) |

**Builds on.** `citationformat.Requirements`, the § 2.3 rule.
**Deletes.** `seedSuggestions`, `seedSuggestion`, `derivedSuggestions` (and `registry_test.go`'s `maps` import, which only it used; `mustParseForm` stays, other tests use it), the hand-compare in `TestSeedSuggestionsFollowFormats`, the "unknown type" case (replaced, D-5), `Install`'s `fieldIDs` guard (D-2); every doc line naming them.
**Next adds.** S16-79's type and its copy-layer change need no suggestion edits and no count edit.

### Reach

None — same rows at create.

### Scale

None — 26 types parsed three times each at create.

### Edges

- **Assumptions.** `Requirements` returns requirements in first-read order per template; the test copy relied on it, and `TestSuggestedKeys`' census check plus STEP-1's equality hold it.
- **Neighbors.** A type with no format would suggest nothing; every seeded type has three (`TestSeedTypes`).
- **Removed inputs.** None.
- **Real data.** STEP-1 runs the rule over all 26 seeded types against the hand lists.
- **Untrusted size.** None — product data.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/database/sourcevocab` | `suggestedKeys` *(new, D-1)*; `Install` per D-2; `seedSuggestions`, `seedSuggestion` deleted |

Errors: none new.

### FFI

None — no wire change.

### macOS

None — no view change.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — Derive in Install**
Files: `core/database/sourcevocab/registry_suggestions.go`, `sourcevocab.go`, `registry_test.go`, `sourcevocab_test.go`. Skill: `add-seeded-vocabulary`.
Do: add `suggestedKeys` (D-1) above `seedSuggestions`; `derivedSuggestions` returns its result; `registry_test.go` drops its `maps` import (its one use moves) and `registry_suggestions.go` imports `maps`, `citationformat` and `sourcetypes`. `Install` writes the derived lists (D-2). Replace the "unknown type" case per D-5. `seedSuggestions` stays; `TestInstall`'s "empty catalog gets the seed" still compares the installed rows with `seedSuggestions` (D-3).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/...` passes.

**STEP-2 — Delete the hand lists**
Files: `registry_suggestions.go`, `registry.go`, `registry_test.go`, `sourcevocab_test.go`.
Do: delete `seedSuggestions`, `seedSuggestion` and `derivedSuggestions`; the header comment of `registry.go` says the suggestions are derived in `registry_suggestions.go`. `TestInstall`'s two loops (registry lists, then unlisted types) become one loop over `seedTypes` comparing each type's rows with `suggestedKeysOf(t, st.Key)` and requiring a non-empty list. Rename `seedSuggestionKeys` to `suggestedKeysOf` (D-6) at its definition and two call sites. `TestSuggestedKeys` per D-4, keeping today's "no empty list" check. `TestSeededFormatsNeedOnlySuggestedFields` and `TestSeedPlaceFields` iterate `seedTypes` with `suggestedKeysOf`.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcevocab/... ./core/database/sourcemetadata/... ./core/onboarding/...` passes; `rg -n "seedSuggestion|derivedSuggestions" core` prints nothing.

**STEP-3 — Docs**
Files: `docs/seeded-vocabulary.md`, `.agents/skills/add-seeded-vocabulary/SKILL.md`, `docs/deployment-plan/spike-16/completed.md`, `docs/deployment-plan/spike-16/deployment-plan.md` (map row), this plan.
Do: `seeded-vocabulary.md` line 83: "Product-seeded Source types/fields/suggestions live in a **code registry** (`core/database/sourcevocab/registry.go`, `registry_fields.go`, `registry_suggestions.go`)" → "Product-seeded Source types and fields live in a **code registry** (`core/database/sourcevocab/registry.go`, `registry_fields.go`), and `Install` derives each type's suggestions from its formats (`registry_suggestions.go` `suggestedKeys`, § 2.3)"; "and each type's suggested fields, one list per type" stays. § 2.3: "The seed lists each type's fields as one list, derived from the type's formats in first-read order:" becomes "`Install` derives each seeded type's list from its formats (`suggestedKeys`), in first-read order:", "`TestSeedSuggestionsFollowFormats` derives the lists from the formats and fails on any difference, in order, and" becomes "`TestSuggestedKeys` checks each list, and"; "all offer the same 18 fields" → "all offer the same fields". Skill: the table row's `seedSuggestions` becomes "suggestions derived from the formats"; step 1's `registry_suggestions.go` bullet becomes "`registry_suggestions.go` `suggestedKeys` — derives each type's suggested fields from its formats (§ 2.3); a type needs no list of its own"; step 6's `TestSeedSuggestionsFollowFormats` becomes `TestSuggestedKeys`. After the PR is open: this plan Landed, the map row `Landed #N`, a `completed.md` entry ("Seeded types' suggested fields are derived from their formats at install; new projects get the same rows").
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-78-derive-seed-suggestions.md` passes.

Commits: one per behavior. The subject is one full imperative sentence ending in a period ("Derive each seeded type's suggested fields from its formats at install.").

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `sourcevocab_test.go` `TestInstall` "empty catalog gets the seed" | STEP-1: rows equal `seedSuggestions`; STEP-2: rows equal `suggestedKeys` per type | AC-1.1, D-3 |
| T-2 | Go | `sourcevocab_test.go` `TestInstall` "a seed format reading an unseeded field is rejected" *(new)* | D-5's type → `ErrInvalid`, no fields or types left | AC-1.3, D-2, D-5 |
| T-3 | Go | `registry_test.go` `TestSuggestedKeys` *(renamed)* | census: `creator` first, `citing` last, no count; each type: not empty, no repeat | AC-1.4, D-4 |
| T-4 | Go | `sourcemetadata_test.go` `TestSeedAnnotations` | Unchanged and green | AC-1.1 |

Must stay green: everything `scripts/check-pr.sh` runs.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — none
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — no brief
- [ ] Version bump as the header says — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated
- [ ] Domain doc updated: docs/seeded-vocabulary.md § 2.3 and the skill, per STEP-3
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Create a new project. Open the Census Source type: it suggests the same 18 fields in the same order as before this PR, `creator` first and `citing` last.
2. AC-1.2: `rg -n "seedSuggestion" core docs/*.md .agents` prints nothing.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The derived lists differ from the hand lists | STEP-1's comparison runs before anything is deleted |

**Stop and report if:**

- STEP-1's `TestInstall` comparison fails for any type.
- `citationformat.Requirements` no longer returns requirements in first-read order.

## 12. Open questions

None.

## 13. PR

**Title:** S16-78 — Install derives each seeded type's suggested fields from its formats
**Body:** objective in one sentence; US-1 against AC-1.1 – AC-1.4; STEP-1's equality run as evidence; deviations; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-78-derive-seed-suggestions.md`.
