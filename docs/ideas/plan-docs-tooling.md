# Plan docs tooling

**Status:** idea only — not roadmapped. Split out of the retired `structural-debt.md` on 2026-11-17 (checked against the code that day). No user-visible change unless a section says so; pull one in when a feature next changes that code. `scripts/check-plan-docs.py` and the spike-close link check ([`archive-docs`](../../.agents/skills/archive-docs/SKILL.md)).

## The spike-close link comparison is a shell block

The spike-close link comparison is a shell block in `archive-docs` § Retarget that `ship-pr` § 8 step 2 runs on every close. It needed two fixes in S14-99 (an empty base listing, then a failed `mktemp` that could extract over the repo and `rm -rf` it), and Claude Code still refuses its `rm -rf "$tmp"` line, so an agent cannot finish it as written. Move it into `scripts/check-plan-docs.py` as `--links --base REF`, which extracts both sides, compares and cleans up with `tempfile.TemporaryDirectory()`, and is tested; the skill then gives one command. (S14-99 ship log (in git with #754))

## Nothing checks anchors, and no gate checks every doc

`scripts/check-plan-docs.py --links FILE ...` checks the relative links of any Markdown file, and a spike close compares them against its base (`archive-docs` § Retarget), but nothing checks anchors, and no gate runs it over `docs/**/*.md`: the base still has broken links of its own. Fix those, then let `check-pr.sh` run `--links`, anchors included, over every `docs/**/*.md`. (S13-99 review M-5)
