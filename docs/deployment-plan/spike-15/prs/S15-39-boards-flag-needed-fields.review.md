# Review — S15-39 Metadata boards flag needed fields

Plan: [`S15-39-boards-flag-needed-fields.md`](S15-39-boards-flag-needed-fields.md) · Brief: [S15-D20](../design/S15-D20-boards-flag-needed-fields.md)

## Planning answers (user, 2026-11-28)

- A needed field met elsewhere (inherited from the Source, or answered by a later option of its chain) draws the used mark with no dismiss.
- The flag shows on every board the engine emits it on, below the Source too.
- The agreed board reaches the implementer as Claude Design links.

## Round 1 — executability (verdict: Ready with changes)

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| X-1 | blocker | Swift checks cannot run in a Linux container | Declined: `scripts/check-pr.sh` runs `xcode-test` on macOS only and fails it elsewhere ("needs macOS"); the implementer runs on a Mac, as for every Swift plan in this spike |
| X-2 | major | Needed + inherited + not met undefined | Fixed: D-3 reads an inherited value as met; Edges says why the engine sets `metElsewhere` then; T-2 row |
| X-3 | major | Mark case, hint argument and Platform importing a Feature type | Fixed: D-3 case label, D-5 `metadataNeededAlternatives(_ names: String)`, D-6 signatures, D-7 takes `CitationNeed?`; T-2, T-5 |
| X-4 | major | Unknown-level options, empty names, repeated names | Fixed: D-2 drops unknown-level options; D-6 `optionNames` skips empty and repeated names, the hint is drawn only when non-empty; T-5 row |
| X-5 | minor | Row layout left to the board | Fixed in part: § 6 macOS Label row (VStack, `mark:` default nil, inherited label stays hidden, Badge at rest and in edit); spacing waits for the board |
| X-6 | minor | Parity file edit only partly given | Fixed: D-8 names the exact clause and the decoded field |
| X-7 | nit | Fixture flags for T-3 | Fixed: T-3 builds with `suggested: true` |
