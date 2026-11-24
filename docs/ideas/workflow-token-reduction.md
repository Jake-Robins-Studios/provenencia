# Workflow token reduction

**Status:** idea only — not roadmapped. From a review of the plan-spike → plan-pr → ship-pr workflow on 2026-11-24. The first batch shipped with [#966](https://github.com/Jake-Robins-Studios/provenencia/pull/966): plan-pr "Write it once" and the plan word-count line, `scripts/route-reviewers.py`, `scripts/check-patterns.py` in the gate, and the **Cost** table in ship and review logs. The rest is below. Pull an item in once a few ship logs' **Cost** tables show where the tokens go.

## Where the tokens go

A spike-16 plan averages about 7,300 words (Decisions 23%, Design 15%, Steps 9%, Current state 9%). About a dozen fresh agents read the whole plan per PR: two to four plan reviewers, the implementer, up to four review-round reviewers, verifiers, the fix-round implementer and round-2 reviewers. Each reviewer also loads `review-pr/SKILL.md` (1.5k words) and a rubric (1.6k–3.3k). Plan length multiplies, so a word cut from a plan saves about twelve.

Considered and declined: a hard cap on plan length. It would cut binding detail when a PR needs it; "Write it once" targets repetition instead.

## Make skills and plans smaller

- **Per-lens plan slices.** Give each reader the sections it uses: implementer — Steps, Tests, DoD, Decisions; conformance — ACs, Tests, DoD; maintainability — Codebase fit, Decisions, Deletes; security and performance — Edges, Scale, Reach. `check-plan-docs.py` already parses sections; a `--slice <lens>` flag could print one. Risk: a reviewer misses a contradiction between a section it saw and one it did not. Try it on one lens first and compare findings.
- **History out of always-loaded skills.** Rationale and dates ("Conformance ran on Sonnet from 2026-10-18…", the S12-13 and S12-08 stories in `review-plan`, the long Known traps prose) move to a `docs/workflow-decisions.md` that agents do not load. The skill keeps the rule.
- **Split `maintainability.md` (3.3k words).** It is loaded by plan review and PR review. Core questions stay; per-area appendices (Swift UI, catalog, matching) load only when the routing script matches their paths.
- **One copy of each check.** The `review-plan` plan-checks table restates the plan-pr self-review gate and parts of the maintainability rubric. Keep one and link it.

## Split the work differently

- **A middle tier between quick-pr and ship-pr.** No schema, FFI or new chrome and a small diff: one combined conformance and maintainability reviewer, one round, no executability review of the plan. Most cost is per reviewer, so fewer reviewers saves more than shorter reviews.
- **Diff first for reviewers.** The dispatch prompt says to start from the diff and file list and pull context with Grep and Read, not reread whole files.
- **Plan-review round 2 only for blockers.** It runs today after any "Fixed reshape"; the writer could confirm a small fix against the code and keep a fresh round 2 for blockers.
- **Cheaper models for clerical steps.** Ship-log bookkeeping and the PR body do not need the orchestrator's model. Conformance stays on Opus (moved back 2026-11-06 after four misses on Sonnet).

## Move more into scripts

- **More of the plan-pr self-review gate into `check-plan-docs.py`.** Still done by the model: every backticked symbol exists at the planning base (`rg` each), every In line is covered by a Step, the version-bump line is filled, Reach, Scale and Edges hold content or "None — why".
- **Generate the ship log and PR body.** A script that scaffolds the ship log (header, round tables, nits copied from reviewer output) and assembles the PR body from the ship log and the plan's user stories and Manual check. These are long outputs the orchestrator writes token by token.
- **Only the failing check to the implementer.** `check-pr.sh` already prints the last 40 lines of a failed check; the orchestrator could pass that block alone, not the whole run.
- **More trap shapes in `check-patterns.py`.** Candidates that need a sharper pattern before they can gate without false positives: an added `try?` on a load path (UX), a `CatalogQueryKey` without `whenHidden` (performance), `Int64(` or `+` on a catalog number in Swift (security), `NSWorkspace.shared.open` on a URL not built by `urlshape.OpenHref` (security).
