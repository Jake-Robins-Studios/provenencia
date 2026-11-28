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

## Round 1 — maintainability (verdict: Fits with changes)

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M-1 | blocker | D-3's alternative check copies the engine's met-elsewhere rule lossily (one head can head several chains; the wire flattens alternatives) | To user → the engine re-annotates drafts (user, 2026-11-28). New preparatory PR S15-74 in the map; D-3 now reads only `requirement` and `hasValue`; D-10 re-reads a draft board's requirements after each change; T-6, T-7 |
| M-2 | blocker | The rule on `MetadataBoardModel` makes S15-40 and S15-42 copy it | Fixed: D-3 is `CatalogCitationRequirement.mark(hasValue:)` in Platform, `CatalogMetadataEntry.citationMark` calls it; T-2 is a pure table |
| M-3 | minor | `CitationNeed` belongs in `CitationFormatVocabulary.swift` | Fixed: Codebase fit, STEP-1 |
| M-4 | minor | The mark's associated alternatives duplicate `requirement.alternatives` | Fixed: `CitationMark` is `.needed` / `.used`; the hint reads `entry.requirement?.alternatives` |
| M-5 | minor | The dismiss check sits in three places | Fixed: D-4 `CatalogMetadataEntry.isDismissible`; the rows take an optional `onDismiss` |
| M-6 | minor | `missingJoin`'s comments go false | Fixed: D-6 widens both comments |
| M-7 | minor | Decisions repeat the Design tables | Fixed: D-1, D-2, D-5, D-8 trimmed to the choice and point at Codebase fit, § 6 macOS and Deletes |
| M-8 | nit | Next adds leaves out S15-42 | Fixed: Next adds and the Out row name it |

**Brief.** NF-5's sheet clause stands: S15-74 makes it the engine's answer. The brief's **Depends on** names S15-74.

## Verdict

Round 1 answered; no open blocker. Round 2 runs when S15-74 lands and the plan is refreshed against its store method (D-10's Current state), with the agreed board.
