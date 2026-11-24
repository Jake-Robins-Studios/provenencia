# Review — S16-68 The query-cache types have files of their own

**Verdict:** Maintainability: Fits with changes. Executability: Ready with changes. No blocker open.
**Rounds:** 1. **Reviewers:** maintainability, executability ([`review-plan`](../../../../.agents/skills/review-plan/SKILL.md)).

## To user

- ~~**M-1, M-2: `requireRowIDs` cannot stay `fileprivate`, and the rule says no edit.**~~ **Answered (user, 2026-11-24): a member on the enum.** `requireRowIDs()` moves onto `CatalogQueryFollows`, and its five callers call it on their slot (D-2). STEP-3 rewords the rule.

## Writer's own calls

- AC-1.3 uses `--color-moved=plain` and greps for lines git did not colour as moved, so the check reads as text. I tried it on a scratch copy of the move at the planning base: it printed exactly the headers, the imports and D-2's lines.
- The rule wording and the `completed.md` entry are written after the PR opens, so they carry its number.

## Round 1

### M-1 · blocker · D-2 changes a user rule, but "Rules this plan bends" said None
**Answer:** To user → answered (above). "Rules this plan bends" records the answer and STEP-3 updates the rule.

### M-2 · major · `requireRowIDs` would be the app's only internal free function for a domain rule
**Answer:** Fixed with the user's answer. D-2 makes it a member. The optional `requireCatalogWide()` stays Out: one caller, and S16-70's plan decides whether `.deleted` is catalog-wide.

### M-3 · minor · Codebase fit searched file names only, and "Builds on" called the naming one-type-per-file
**Answer:** Fixed. D-1's Rejected column and the search line name `CatalogQueryDescriptor.entityPage(kind:load:)` and `CatalogPageInputs`. "Builds on" now reads "files named for the concept they hold".

### M-4 · nit · Next adds left out the removals S16-70 makes
**Answer:** Fixed.

### X-1 · major · AC-1.3 and STEP-1's check could not be run as written
**Answer:** Fixed. The check runs after the STEP-1 commit, against the merge base, with an exact command whose text output says what to expect. Tried on a scratch copy.

### X-2 · major · AC-1.3's exceptions left out blank lines
**Answer:** Fixed. Blank lines and lone braces are allowed explicitly.

### X-3 · major · STEP-3 left the doc edits to the implementer
**Answer:** Fixed. It gives the rule's added clause, the scope entry's sentence, the map status text, the `completed.md` position and model, and the Landed line. All of it is written once the PR number is known.

### X-4 · minor · Status and the map link
**Answer:** Fixed. The plan is Planned and the map row links it.

### X-5 · minor · How to cut the ranges
**Answer:** Fixed. Each range is taken from `git show main:<path>` before any edit.

### X-6 · minor · `main` against the Planned commit
**Answer:** Fixed. AC-1.3 diffs against `git merge-base main HEAD`.

### X-7 · nit · Trailing newline
**Answer:** No change needed. Covered by X-2's allowance.
