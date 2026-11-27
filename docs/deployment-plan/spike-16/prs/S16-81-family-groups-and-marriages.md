# S16-81 — Family groups siblings by their parents and shows each couple's marriage

**Status:** Draft
**Spike / slice:** Spike 16 · Slice 6l — Family parents
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** [S16-D18](../design/S16-D18-family-groups-and-marriages.md), board agreed 2026-11-27
**Board:** [Claude Design — Person Detail](https://claude.ai/artifact/N9V52ewQjxeNvh3Az3YkXQ#page-Person-Detail---Family), turn "S16-D18 · Sibling groups and marriages". The implementer may not be able to open it: §6 **macOS** describes every frame in words, and the brief's §4 and §5 are the agreed text
**Depends on:** S16-82 (landed [#1009](https://github.com/Jake-Robins-Studios/provenencia/pull/1009)), S16-D18
**Blocks:** —
**Branch:** `s16-81-family-groups-and-marriages`
**Version bump:** minor, 0.48.3 → 0.49.0 at the base — Family shows sibling groups and marriages, a feature; the wire loses fields only this binary read ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md) (the `core/kinship` page functions paragraph)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/match-rules.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** brief [S16-D18](../design/S16-D18-family-groups-and-marriages.md); working rules "(Batch 6) Family groups siblings by their parents", "(Batch 6) Family shows a couple's marriage from its events", "(Batch 1) Crafted fan-out is capped, not engineered"; [S16-82's plan](S16-82-family-groups-and-marriages-read.md) and its **Landed** note; [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide)
**Planned:** 2026-11-27 against `main` @ `819a568`
**Review:** — (not reviewed yet)

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

The Person page's Family section draws the person's siblings, the person among them, in groups by the parents each shares with the person: each group its parents' tiles, then its children indented beneath, joined by one line that stays inside the group, so no two lines cross and a parent in two groups is drawn in each. Each couple the page shows (a group's parents, and the person with each partner) carries a line for each marriage both are subjects of, "m. 12 Jun 1841 · Hamburg", worded as a tile's b. and d. lines. It comes from the dogfood note of 2026-11-26 (a mother drawn twice, stacked above every sibling, with crossing lines) and the user's request for marriage dates on Family; the engine half (S16-82) already sends the groups and couples.

**Why now.** S16-82 landed; S16-D18's board is agreed; until this PR the engine sends the old parent-set fields beside the new ones, and only today's drawing reads the old ones.

**What stays.** The tiles and their 92 pt height, the two columns, the right column's partners and children, the bus, the Show more rows and their 30-tile fold, the section header and empty state, the Wide arrangement (S13-D3), and the read's inputs.

## 2. User stories

The family in every example is brief §5's: Johann Weber (b. 1817), parents Heinrich and Anna, siblings Margarethe (1815), Friedrich (1820), Christian (1823) and Wilhelm (undated); partners Maria Schulz (children Karl, Luise, Emma), Sophie Brandt (Otto), and Paul with no other parent.

**US-1.** As a researcher, when a sibling shares only some of my person's parents, I see each sibling once in a group under the parents they share, so I read each family unit on its own.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Groups {Heinrich, Anna}: Margarethe, Johann, Friedrich, Wilhelm; {Anna}: Christian (F1) | Left column: caption PARENTS, Heinrich, Anna, then the four indented; caption SHARED PARENT, Anna, then Christian indented. Anna has two tiles with different ids. One line per group at x 10; no line reaches another group |
| AC-1.2 | F2: {Heinrich, Anna, Katharina}: Johann, Friedrich; {Heinrich, Anna}: Margarethe, Wilhelm; {Heinrich, Katharina}: Christian | Captions PARENTS, SHARED PARENTS, SHARED PARENTS; container labels "This person, siblings and parents", "Children of Heinrich Weber and Anna Weber", "Children of Heinrich Weber and Katharina Weber" |
| AC-1.3 | F3: {Heinrich, Anna}: Margarethe, Johann, Friedrich; {Heinrich}: Wilhelm; {Anna}: Christian | Captions PARENTS, SHARED PARENT, SHARED PARENT; labels "…", "Children of Heinrich Weber", "Children of Anna Weber" |
| AC-1.4 | F4: {Heinrich, Anna, Georg Becker, Katharina Becker}: Johann; {Heinrich, Anna}: Margarethe, Friedrich; {Georg, Katharina}: Christian; {}: Elisabeth | Person's group captioned PARENTS, labelled "This person and parents"; the last group captioned OTHER SIBLINGS, labelled "Other siblings", Elisabeth at x 20 with no line and no bracket |
| AC-1.5 | F6: one group with no parents: Clara, Johann, Karl | Caption SIBLINGS, label "This person and siblings", the three at x 20 joined by one line |
| AC-1.6 | 11h: Anna's page, one group holding Anna alone, a partner Heinrich | No left caption, label "This person"; Anna's tile at (20, 26) |
| AC-1.7 | Tab through F1 | Heinrich, Anna, Margarethe, Friedrich, Wilhelm, Anna, Christian, then the right column (Johann's own tile takes no stop) |
| AC-1.8 | 40 siblings: 20 in Johann's group, 20 in a {Anna} group (F5b) | The first 30 others shown (20, then 10 of Anna's group with Anna's tile), "Show 10 more" under the 30th, inside Anna's group; one page later all 40 show and the row is gone |
| AC-1.9 | 30 siblings in Johann's group and 5 in a {Anna} group | Anna's group is not drawn (its first child is the 31st); one page reveals it, and the keyboard lands on its Anna tile |
| AC-1.10 | A history entry whose Family anchor is an old id (`l-p0-anna`, `l-s-margarethe`) | `anchorStop` is nil, so Back lands at the section's top |

**US-2.** As a researcher, when a couple on Family has a marriage recorded, I see its date and place between the two people, so I know when and where they married without opening the Timeline.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | M1: Heinrich–Anna married 3 May 1812 at Altona; Johann–Maria 12 Jun 1841 at Hamburg; Johann–Sophie partners with no marriage | "m. 3 May 1812 · Altona" in the gap between Heinrich's and Anna's tiles, which widens 21 pt; "m. 12 Jun 1841 · Hamburg" at the top of Maria's group, Maria's tile 25 pt lower; nothing over Sophie |
| AC-2.2 | VoiceOver on M1 | After Anna's tile: "Heinrich Weber and Anna Weber, married 3 May 1812, Altona"; at the top of Maria's group, before Maria's tile: "Johann Weber and Maria Schulz, married 12 Jun 1841, Hamburg". Neither line takes a Tab stop |
| AC-2.3 | M2: a place only (Altona), a date only (12 Jun 1841), neither | Drawn "m. Altona", "m. 12 Jun 1841", "m."; spoken "…, married in Altona", "…, married 12 Jun 1841", "…, married" (user, 2026-11-27: one builder for b., d. and m.) |
| AC-2.4 | M3: Johann–Maria with 12 Jun 1841 at Hamburg and an undated one at Lübeck, in that order from the engine | Two lines over Maria's group in that order; Maria's tile 46 pt lower than with none (two lines of 21 pt and 4 pt) |
| AC-2.5 | M4: F2's family, Heinrich–Anna 3 May 1812 at Altona, Heinrich–Katharina abt 1816 at Kiel | In the three-parent group: "m. 3 May 1812 · Altona, with Heinrich Weber" between Heinrich and Anna; "m. abt 1816 · Kiel, with Heinrich Weber" under Katharina. In {Heinrich, Anna} and {Heinrich, Katharina}: the same marriages with no name. The named lines are spoken as drawn, "married abt 1816, Kiel, with Heinrich Weber", each just after Katharina's or Anna's tile (user, 2026-11-27) |
| AC-2.6 | M5: Maria married, 31 partner units | Maria's line shows; partner 31's group and its line are hidden; one page shows them |
| AC-2.7 | A marriage of an event type with no life-line words (any type `L10n.LifeLineWords.words` does not list, or one not of origin provenencia) | No line for that marriage |

**US-3.** As a contributor, the engine sends one shape for the left column and the Swift words of a life line live in one table, so a later union pattern needs one table row.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `GetPersonFamilyResponse` | Has no `origin_siblings`; `FamilyUnitKind` has no PARENTS or SIBLINGS; units are partner and one-parent units only |
| AC-3.2 | A spouse pattern whose event type has no `L10n.LifeLineWords` case | `TestSwiftVocabularyMatchesGo` fails, naming the event type |
| AC-3.3 | A person tile's b. and d. lines, and the Person header's | Drawn and spoken as before this PR |

## 3. Scope

| In | Covered by |
| --- | --- |
| FG-1 groups in order, each sibling once, one line per group, no crossing | STEP-4, AC-1.1, AC-1.2, AC-1.4, AC-1.5 |
| FG-2 a parent in several groups has a tile and a Tab stop in each | STEP-4, AC-1.1 |
| FG-3 captions | STEP-4, AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6 |
| FG-4 group container labels | STEP-4, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6 |
| FG-5 Tab order | STEP-4, AC-1.7 |
| FG-6 one siblings fold across the groups | STEP-4, AC-1.8, AC-1.9 |
| FG-7 the per-set rails, the bracket and the childless "Other parent" block go | STEP-4, AC-1.4 |
| FG-W1 nothing moves between widths | STEP-4, T-8 |
| FM-1, FM-4 marriage lines worded from the event type, kept with both halves missing | STEP-1, STEP-3, STEP-5, AC-2.1, AC-2.3 |
| FM-2 a group's parents' lines, and the named lines of a group with more than two parents | STEP-5, AC-2.1, AC-2.5 |
| FM-3 a partner's lines | STEP-5, AC-2.1, AC-2.4 |
| FM-5 several marriages, in the engine's order | STEP-5, AC-2.4 |
| FM-6 spoken, no Tab stop, in reading order | STEP-5, AC-2.2, AC-2.5 |
| FM-7 lines hide with their tiles | STEP-5, AC-2.6 |
| FM-W1 lines sit where they sit at Regular | STEP-5, T-8 |
| One life-line words table; b. and d. move into it | STEP-1, AC-3.3 |
| The Go parity row for `kinship.SpouseEventTypes()` | STEP-2, AC-3.2 |
| Deleting the old fields and their mechanisms (§6 **Deletes**); `persondetail.Unit` with `Couples` in place of `Family.UnitCouples` | STEP-6, STEP-7, AC-3.1 |
| Previews F1 – F4, F6, M1 – M4 and 11h | STEP-4, STEP-5 |
| Docs and guidance the deletions make false | STEP-8 |

| Out | Home |
| --- | --- |
| The engine's grouping and marriages | S16-82 (landed) |
| Opening the marriage from Family; a link, chip or Badge on a marriage | Not planned (brief §2.1: the Timeline opens it) |
| Siblings' or children's marriages; events other than the spouse patterns' | Not planned (brief §2.1) |
| A "+N" place count on a marriage line | Not planned (brief §2: a tile line shows one place) |
| A family tree reading `SiblingGroups` per generation | [`docs/ideas/kinship-view.md`](../../../ideas/kinship-view.md) |
| Sending relatives as indexes into one table (P-8) | [`docs/ideas/person-page-performance.md`](../../../ideas/person-page-performance.md), descoped (rule "Refused: memoising and re-shaping for speed") |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Family content | `macos/App/Features/Conclusions/PersonFamilyContent.swift` `PersonFamilyContent` | Builds `parentSets` from `.parents` units and `siblings` from `originSiblings`; `Fold.parentSets`; tile ids `l-p{k}-{id}`, `l-s-{id}`; no marriages |
| Family layout | `PersonFamilyLayout.swift` `PersonFamilyLayout` | Stacks parent sets, then siblings on rails (`railX`), a bracket at `bracketX` for siblings in no set; `afterSet` 20 |
| Diagram | `PersonFamilySection.swift` `PersonFamilyDiagram` | Draws segments, captions, then one container per group in view order; no `accessibilitySortPriority` anywhere in `macos/App` |
| Fixtures | `PersonFamilyPreviewData.swift` `full`, `conflicting`, `siblingsOnly`, `annaOnly`, `origin(_:_:)`, `unit(_:partners:children:)` | Built from `.parents`/`.siblings` units and `originSiblings` |
| Life lines | `macos/App/Platform/PersonLifeDisplay.swift` `LifeLine`, `lifeLines(_:locale:missing:)`, private `lifeLine(_:facts:locale:missing:spoken:)` | Builds b. and d. from `CatalogLifeFacts`; words from `L10n.Conclusions.personBornAbbr`, `personDiedAbbr`, `a11yBorn`, `a11yDied`, `a11yBornInline`, `a11yDiedInline`; returns nil for a missing line in `.omitted` |
| Date · place line | `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift` | `leading`, `date`, `place`, `extraCount`; no trailing part |
| Event wording | `macos/App/Features/Conclusions/EventsListView.swift` `EventSecondaryDisplay.content(_:locale:)` | Date via `DateRowDisplay.line(dating:)`, place via `DerivedPlace.name`, `extraPlaces` |
| Person card | `macos/App/DesignSystem/Recipes/PersonCard/PVPersonCard.swift` `PVPersonCardContent`, `PVPersonCard.lines` | Draws `content.lines` with `PVDatePlaceLine(…, missing: .omitted)`, no `extraCount` |
| Seeded event terms | `macos/App/Platform/L10n.swift` `L10n.PropertyTerm`; `ConclusionVocabulary.swift` `SeededEventTypeTerm` | `marriage` is a constant; `PropertyTerm.resource` is the switch shape the parity test reads |
| Family copy | `L10n.swift` `L10n.Conclusions.familyCaption*`, `familyGroup*`, `familyThisPerson` | `familyCaptionOtherParent(s)` read only by the content's parent captions |
| Swift model | `macos/App/Platform/GenealogyStore.swift` `CatalogPersonFamily.originSiblings`, `CatalogOriginSibling`, `CatalogFamilyUnit.Kind.parents`, `.siblings`; `GoStore.swift` `getPersonFamily`, `mapFamilyUnit` | Maps both old and new fields |
| Proto | `api/proto/engine.proto` `GetPersonFamilyResponse` (fields 1–6), `OriginSibling`, `FamilyUnitKind` | Field 3 and `OriginSibling` read only by `GoStore`; enum values 1 and 4 |
| Handler | `api/ffi/handlers/person_detail.go` `GetPersonFamily`, `familyUnitKindProto` | Maps `family.UnitCouples[k]` and the origin siblings |
| Family read | `core/database/persondetail/family.go` `Family.UnitCouples`, `OriginSibling`, `PersonFamily` (returns `(Family, []OriginSibling, Summaries, error)`), `originSiblings`, `indexCouples`, `dropUnread` | `UnitCouples` is parallel to `Units` |
| Kinship | `core/kinship/families.go` `UnitParents`, `UnitSiblings`, `Unit.Empty`, `FamilyUnits`, `parentUnits` (with `paired`), `subset`; kept: `sharedParents`, `spouseLink`, `filedSpouseLink`, `pairsParents`, `SiblingGroups`, `Couples` | `FamilyUnits` returns parent sets, partners, one-parent and siblings units |
| Comments naming the old shape | `core/kinship/siblings.go` (`Siblings` doc, "the bound parentUnits uses"); `core/kinship/kinship.go` package doc | Name `parentUnits` |
| Go parity test | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo`, `swiftFuncBody`, `swiftEnumBody`, `swiftNamedKey`, subtest "every composer-worded term has composer wording" | No life-line row |
| Swift tests | `macos/ProvenenciaTests/PersonFamilyContentTests.swift`, `PersonFamilyLayoutTests.swift`; `PersonDetailTests.swift` life-line tests (lines 470–640) | Assume parent sets, rails, `originSiblings` |
| Go tests | `core/kinship/families_test.go` `TestFamilies`, `TestFamiliesMoreParentsThanMaxPivotEnd`, `TestFamiliesGrowth`, `TestFamiliesGrowthPairs`, `TestUnitEmpty`, `FuzzFamilyUnits`, `crowd`, `pairs`, `placements`, `shown`, `unitName`; `siblings_test.go` "50,000 parents and a sibling sharing them all"; `core/database/persondetail/family_test.go` `unitKind`, `relative`, `TestPersonFamily` (AC-1.2, AC-1.5), `TestPersonFamilyOriginSiblings`, "AC-2.8 …"; `family_drop_test.go` `TestDropUnread`; `caps_test.go`; `api/ffi/handlers/person_detail_test.go` "carries the person and the origin siblings" | Read the parent and siblings units or origin siblings |

**Precedent.** S16-82 ([#1009](https://github.com/Jake-Robins-Studios/provenencia/pull/1009)) shaped `persondetail.Group{kinship.SiblingGroup; Couples []int}`: copy it for `persondetail.Unit`. The `LifeMarker` message's `reserved 2; reserved "beside_event_id";` (`engine.proto`) is the precedent for a removed field. "every composer-worded term has composer wording" in `TestSwiftVocabularyMatchesGo` is the precedent for a test that reads a Swift switch body. `ReconciledValueDisplay` joins names with `ListFormatter`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | One PR; the life-line words table and the Go parity row are its first two commits | The table's only new reader is this PR's marriage line; a separate PR would ship a table with no new row | A preparatory PR — a PR with nothing to show |
| D-2 | `L10n.LifeLineWords` *(new)* holds, per event type, an abbreviation, a display word (the header's `.stated` lines) and an inline word (a tile's): birth "b." / "Born" / "born", death "d." / "Died" / "died", marriage "m." / "Married" / "married". `words(eventTypeKey:)` is a `switch` over `SeededEventTypeTerm` constants (`case SeededEventTypeTerm.marriage: return marriage`), so the parity test reads it as it reads `PropertyTerm.resource`. Keys `lifeLine.<termKey>.abbreviation`, `.word`, `.inline`; the six old keys go | One home for a life line's words (brief inventory) | Keeping `personBornAbbr` and the `a11y*` words beside a marriage table — two homes |
| D-3 | `PersonLifeDisplay` builds every line through one builder that takes the words and an already-worded date and place. A person's b. and d. lines call it with their facts; a marriage line is built from its `CatalogEventSummary` through `EventSecondaryDisplay.content`, only when `eventTypeOrigin` is `CatalogOrigin.provenencia` and `LifeLineWords.words` has its key (else no line). An event line is kept with both halves missing (spoken: the inline word alone); a person's missing b. or d. is still left out in `.omitted` | One builder speaks b., d. and m. one way (user, 2026-11-27: "married in Altona") | A marriage formatter in Family |
| D-4 | A named line (FM-2) carries the other spouse's tile title on `LifeLine.partner` *(new)*. Drawn, `PVDatePlaceLine.trailing` *(new)* gets `L10n.Conclusions.lifeLineWithSpouse(name)` = ", with %@", drawn with no space before it, after the last part drawn (the place, else the date, else the abbreviation), never cut; the place is cut first. Spoken, the line's label is `spokenJoin(label, L10n.Conclusions.a11yLifeLineWithSpouse(name))` = "with %@", and Family speaks that label alone, with no couple before it (user, 2026-11-27) | The brief's FM-2 and FM-6 example; the tile before the line names the other spouse | Prefixing the couple — "Heinrich Weber" spoken twice |
| D-5 | An unnamed marriage line is spoken as the couple's names joined by `ListFormatter` (the content's locale), then the line's label, through `L10n.DesignSystem.spokenJoin`: "Heinrich Weber and Anna Weber, married 3 May 1812, Altona". Names are the tiles' `title.spokenText`; the person's own from the focus tile | FM-6; brief inventory: no hand-made "and" format | A "%@ and %@" key |
| D-6 | The left column draws `family.siblingGroups` in the engine's order with no regrouping. Tile ids are `l-g{k}-{personID}`, k the group's index in `siblingGroups`; the right column keeps `r-{index}-{personID}` | A parent in two groups needs an id per group; k is the engine's, stable across folds | A per-parent counter — ids that shift when a fold opens |
| D-7 | One fold, `.siblings`, over every group's children other than the person, in group order. Group 0 always shows; another group shows when its first child does, with all its parents. The person sits in group 0 at their engine place when the sibling before them shows, else last of group 0's shown children (today's rule). The Show more row sits under the last shown child. `firstRevealed(by: .siblings)` is the first revealed child, or its group's first parent when that child is its group's first child. `Fold.parentSets` and `"more.parentSets"` go | FG-6; the keyboard lands on the first new stop in Tab order | Folding parent tiles — the agreed board folds siblings only |
| D-8 | Captions: group 0 is PARENTS (two or more parents), PARENT (one), SIBLINGS (none, with a sibling besides the person), or none. Another group is SHARED PARENTS, SHARED PARENT, or OTHER SIBLINGS (no parents). Labels: group 0 "This person, siblings and parents", "This person and parents", "This person and siblings" or "This person", by whether it has parents and a child other than the person in the engine's list; another group with parents "Children of %@" (names by `ListFormatter`); without, "Other siblings" (the caption's string, as the one-parent unit's label reuses "Children") | FG-3, FG-4 | — |
| D-9 | A group's marriage lines come from `coupleIndexes`, in that order, each couple's marriages in the engine's order. For a couple whose parents sit at i < j in the group's parents (by entity id): drawn in the gap after parent i when j = i + 1, else in the gap after parent j; spoken just after parent j. Lines name the other spouse (parent i) only when the group has more than two parents. A couple with an end not among the group's parents draws nothing. A partner unit's lines come from its `coupleIndexes` and sit at the top of its group, spoken first | FM-2, FM-6 | Swift matching couples by id pair across the family — the engine already names them by index |
| D-10 | Geometry: each sibling group reserves the 26 pt caption band; parents at x 20, full column width; children at x 52 (x 20 in a group with no parents); a gap after a parent is 12 pt plus 21 pt per line in it, each line 21 pt tall from 6 pt below the tile; a partner group's lines start at its top and its tile moves down 21 pt per line plus 4 pt when it has any; groups are 20 pt apart; the one line per group is at x 10 (parents' and children's horizontals to x 20 and x 52; a parentless group of two or more joined to x 20). `railX`, `bracketX` and `afterSet` go | The agreed board (Board line of the brief); every tile keeps 92 pt | — |
| D-11 | Reading order is the layout's: each `PersonFamilyLayout.Group` lists its tiles, lines and Show more ids in VoiceOver order, and the diagram gives each `accessibilitySortPriority` from that order inside the group's container | A two-parent line is drawn between the tiles but spoken after the second (FM-6); view order alone cannot say it | Drawing the views in reading order — the line would be read before Anna |
| D-12 | `persondetail.Family.Units` becomes `[]Unit`, `Unit{kinship.Unit; Couples []int}` *(new)*, as `Group` is; `UnitCouples` goes; `indexCouples` fills `Unit.Couples` | No parallel slice to misalign | Keeping `UnitCouples` |
| D-13 | Proto: field 3 and `OriginSibling` go, with `reserved 3; reserved "origin_siblings";`; `FAMILY_UNIT_KIND_PARENTS` and `_SIBLINGS` go, with `reserved 1, 4; reserved "FAMILY_UNIT_KIND_PARENTS", "FAMILY_UNIT_KIND_SIBLINGS";`. `kinship.UnitPartner` becomes `iota + 1`. `FamilyUnits` returns the partner units, then the one-parent unit when not empty | No reader is left (user, 2026-11-27); `LifeMarker` precedent | Leaving them deprecated |
| D-14 | `PersonFamily` returns `(Family, conclusionsummaries.Summaries, error)` | The origin siblings are gone | — |
| D-15 | Kinship tests: the parent-set cases go; the bounds they held move to `SiblingGroups` (T-12, T-13); the Siblings shape checks of "links say why" read the relative from `SiblingGroups`' children | The bounds still matter for what the page now draws | Deleting the growth tests outright |
| D-16 | The brief's FM-6 place-only example becomes "married in Altona", and its named-line example stands alone, in this planning commit | Brief and plan agree (user, 2026-11-27) | — |

**Rules this plan bends.** None. D-16 edits the brief's example to the user's answer; the working rules already say S16-81 deletes the old fields.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `L10n.LifeLineWords`, `.Words`, `.birth`, `.death`, `.marriage`, `words(eventTypeKey:)` *(new)* | L10n namespace | `L10n.PropertyTerm` (the type's name "Marriage"), `L10n.Conclusions.personBornAbbr` | A life line's three words per type; the term name is the type's label, not its abbreviation. The old constants move in |
| `PersonLifeDisplay.lifeLine(_:date:place:extraPlaces:missing:keepsBare:partner:)`, `eventLine(_:partner:locale:)` *(new)* | func | private `lifeLine(_:facts:…)` | Generalised from it; the private one goes |
| `LifeLine.partner: String?` *(new)* | field | `LifeLine.extraPlaces` | One optional part (brief inventory) |
| `PVDatePlaceLine.trailing: String?` *(new)* | component param | `extraCount` | The brief marks the component Extend |
| `L10n.Conclusions.lifeLineWithSpouse(_:)`, `a11yLifeLineWithSpouse(_:)` *(new)* | keys | `lifeLineText(abbreviation:rest:)`, `a11yLifeLine*` | Drawn and spoken differ, as `personBornAbbr` and `a11yBorn` did |
| `L10n.Conclusions.familyCaptionSharedParent`, `familyCaptionSharedParents`, `familyCaptionOtherSiblings`, `familyGroupChildrenOf(_:)`, `familyGroupThisPersonSiblingsAndParents`, `familyGroupThisPersonAndParents` *(new)* | keys | `familyCaption*`, `familyGroup*` | Brief copy |
| `PersonFamilyContent.SiblingGroup`, `.MarriageLine`, `.ParentMarriage`, `siblingGroups`, `Group.marriages`, `allMarriageLines` *(new)* | types, fields | `PersonFamilyContent.Group` (right column) | The left group has parents, a caption and parents' lines; the right `Group` keeps its name and gains `marriages` |
| `PersonFamilyLayout.PlacedLine`, `Group.lines`, `Group.readingOrder`, `lineX`, `marriageLineHeight`, `partnerMarriageGap`, `siblingGroupGap` *(new)* | types, consts | `PlacedTile`, `PlacedMore`, `afterSet` | Placed like tiles; `siblingGroupGap` replaces `afterSet` |
| `PersonFamilyPreviewData.group(…)`, `couple(…)`, `marriage(…)`, fixtures `oneParentGroups`, `unrelatedSets`, `married`, `marriageHalves`, `twoMarriages`, `threeParentMarriages` *(new)* | helpers | `unit(_:partners:children:)`, `origin(_:_:)`; `PersonTimelinePreviewData.event` | `event` builds a `CatalogPersonEvent` with a span and cannot set a qualifier; `origin` goes |
| `persondetail.Unit` *(new)* | type | `persondetail.Group` | Same shape (D-12) |
| Parity subtest "every spouse event type has life-line words" *(new)*, regex `lifeLineCase` *(new)* | test | "every composer-worded term has composer wording", `wordingCase` | Same pattern over another switch |

**Builds on.** `EventSecondaryDisplay.content`, `DateRowDisplay`, `DerivedPlace`, `PVPersonCardContent`, `PagedFold`, `PVShowMoreRow`, `conclusionAnchorRestore`, `L10n.DesignSystem.spokenJoin`, `ListFormatter`; S16-82's `siblingGroups`, `couples` and `coupleIndexes`.

**Deletes.**
- Go: `kinship.UnitParents`, `UnitSiblings`, `parentUnits` (with `paired`, its extra sets), `subset`; `persondetail.OriginSibling`, `originSiblings`, `Family.UnitCouples`; `familyUnitKindProto`'s two cases; tests `TestPersonFamilyOriginSiblings`, `TestFamiliesMoreParentsThanMaxPivotEnd`, `TestFamiliesGrowth`, `TestFamiliesGrowthPairs` (replaced by T-12, T-13), the handler's origin-siblings check, the parent-set rows of `TestFamilies` and `TestUnitEmpty`.
- Proto: `GetPersonFamilyResponse.origin_siblings`, `OriginSibling`, `FAMILY_UNIT_KIND_PARENTS`, `FAMILY_UNIT_KIND_SIBLINGS` (regenerated Go and Swift).
- Swift: `CatalogOriginSibling`, `CatalogPersonFamily.originSiblings`, `CatalogFamilyUnit.Kind.parents`, `.siblings`; `PersonFamilyContent.Sibling`, `parentSets`, `parentCaptions`, `parentSetsHidden`, `siblings`, `siblingsCaption`, `siblingsLabel`, `Fold.parentSets`; `PersonFamilyLayout.railX`, `bracketX`, `afterSet`; `PersonFamilyPreviewData.origin`; `PersonLifeDisplay`'s private `lifeLine(_:facts:…)`.
- Strings: `conclusions.family.caption.otherParent`, `.otherParents`; `conclusions.person.born`, `conclusions.person.died`, `conclusions.a11y.born`, `.died`, `.bornInline`, `.diedInline`, with their `L10n` constants.

**Next adds.** A union pattern with term `TermSpouse` reaches `Couples` (S16-82) and here needs one `LifeLineWords` case; the parity row fails until it has one. A baptism or burial line on a tile is one more case and a builder call.

### Reach

| New path or state | Destination | Checked |
| --- | --- | --- |
| An anchor from older history (`l-p…`, `l-s…`) | `PersonFamilyContent.anchorStop` | No tile and no hidden tile has that id → nil → section top (AC-1.10) |
| A parent with two tiles | `PersonFamilyDiagram` `ForEach(group.tiles, id: \.id)`, the `tiles` dictionary | Ids differ by group (D-6); the dictionary keys stay unique |
| A couple index past `couples`, or a couple end not in the group | `PersonFamilyContent.init` | Skipped, no crash (T-5) |
| `family.person` nil | group 0 | No focus tile; labels from the engine's children (as today) |

### Scale

At the map's Scale (real: 20 children in four groups, one or two marriages a couple): the content builds tiles only for shown groups; a fold page adds at most 50 children. Crafted: `KinOf` caps parents and siblings at 100 each (`MaxKinPerRole`), so at most 31 groups show before the first page, each with at most 100 parent tiles: 3,100 tiles, the same order as today's 30 folded parent sets of up to 100 extras each. Marriages: at most 10 per couple from the engine (`maxMarriagesPerCouple`); couples at most 100 spouses plus 45 parent pairs (`pairsParents`). No write, cache key or read changes.

### Edges

- **Assumptions.** The content assumes each sibling is in exactly one group and the person only in group 0 (S16-82's `SiblingGroups`, T-1 there); that a group's couples have both ends among its parents (S16-82's `indexCouples`); that couples' A is earlier than B in the person's parent order. A broken one draws less, never crashes (T-5).
- **Neighbors.** Two-parent group (unnamed line in the gap) vs three-parent group (named lines); adjacent pair vs non-adjacent pair in a three-parent group; a couple with one vs two marriages; a partner with vs without a marriage; a parentless group of one (no line) vs two (one line); group 0 with no parents and no siblings (no caption) vs with siblings (SIBLINGS). Each is a T-row.
- **Removed inputs.** A marriage merged away is not sent (S16-82); a folded group hides its lines (FM-7, AC-2.6); an event type without words draws no line (AC-2.7).
- **Real data.** `LifeLineWords` holds birth, death, marriage; `kinship.SpouseEventTypes()` today is `[marriage]`; the parity row checks all of it.
- **Untrusted size.** Bounded by the engine's caps above; the layout is linear in drawn tiles and lines.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/kinship` | Delete per **Deletes**. `FamilyUnits(person, kin, kinOf, rules)` keeps its signature; it returns `partnerUnits`' units, then the one-parent unit when not empty (`rules` stays for its callers; mark it `_ Rules` only if `go vet` asks). `Unit.Empty`: partner → no partner, one-parent → no child. Doc comments say what the functions do now |
| `core/database/persondetail` | `type Unit struct { kinship.Unit; Couples []int }` *(new)*; `Family.Units []Unit`; `Families` wraps each `kinship.Unit`; `indexCouples` fills `Unit.Couples`; `dropUnread` filters `[]Unit`; `PersonFamily` per D-14; `family.go` doc comments drop the origin siblings |

### FFI

`api/proto/engine.proto` per D-13; regenerate with `./scripts/generate-proto.sh`. Handler `GetPersonFamily`: `CoupleIndexes: indexes(u.Couples)`; the origin-siblings loop goes; `familyUnitKindProto` maps partner and one-parent only.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Family diagram | Snowflake, Extend | `PersonFamilySection.swift` `PersonFamilyDiagram` | Lines as today (one-point rects, `PVColor.borderStrong`); captions as today; marriage lines as `PVDatePlaceLine(leading:date:place:accessibilityLabel:missing: .omitted, trailing:)` in their placed frames, no `extraCount`, not focusable; `accessibilitySortPriority` per D-11 |
| Family layout | Snowflake, Extend | `PersonFamilyLayout.swift` | D-10; doc comment rewritten ("each sibling group under its caption, its parents then its children, one line per group") |
| Family content | Snowflake, Extend | `PersonFamilyContent.swift` | D-6 – D-9; doc comment drops "parent sets" |
| Caption | Snowflake, Ship | the diagram's captions | D-8 |
| Show more row | `PVShowMoreRow` | unchanged | D-7 |
| Life line | Platform type, Extend | `PersonLifeDisplay.swift` | D-3, D-4 |
| Event wording | Feature helper, Ship | `EventSecondaryDisplay.content` | — |
| Date · place line | Component, Extend | `PVDatePlaceLine.swift` | D-4; README row gains "an optional trailing part drawn after the place and never cut" |
| Life-line words | — | `L10n.swift`, beside `L10n.PropertyTerm` | D-2 |
| Previews | Snowflake | `PersonFamilyPreviewData.swift`, `#Preview`s in `PersonFamilySection.swift` | "F1 Shared parent" (`full`), "F2 Records that disagree" (`conflicting`), "F3 One-parent groups", "F4 Unrelated sets", "F6 No parents recorded" (`siblingsOnly`), "M1 Marriages", "M2 Missing halves", "M3 Two marriages", "M4 Three parents", "11h After clicking Anna" |

**Frames in words** (Regular pane 1102 wide, primary column 1038; Wide identical but wider columns, 96 pt gutter; nothing moves between widths):
- **F1.** Caption PARENTS at the top left. Heinrich's tile, Anna's below it. Margarethe, Johann (raised, "This person" badge), Friedrich, Wilhelm indented 32 pt beneath. One vertical line at x 10 from Heinrich's centre to Wilhelm's, short horizontals to each tile. 20 pt lower: caption SHARED PARENT, Anna's tile, Christian indented, its own line. Right column unchanged (Maria with Karl, Luise, Emma; Sophie with Otto; Paul).
- **F2.** Group 1 caption PARENTS: Heinrich, Anna, Katharina; Johann, Friedrich. Group 2 SHARED PARENTS: Heinrich, Anna; Margarethe, Wilhelm. Group 3 SHARED PARENTS: Heinrich, Katharina; Christian.
- **F3.** PARENTS: Heinrich, Anna; Margarethe, Johann, Friedrich. SHARED PARENT: Heinrich; Wilhelm. SHARED PARENT: Anna; Christian.
- **F4.** PARENTS: Heinrich, Anna, Georg Becker, Katharina Becker; Johann. SHARED PARENTS: Heinrich, Anna; Margarethe, Friedrich. SHARED PARENTS: Georg, Katharina; Christian. OTHER SIBLINGS: Elisabeth at the margin, no line.
- **F6.** SIBLINGS: Clara, Johann, Karl at the margin, one line joining the three.
- **M1.** F1 with "m. 3 May 1812 · Altona" in the widened gap between Heinrich and Anna; "m. 12 Jun 1841 · Hamburg" at the top of Maria's group, Maria's tile below it; Sophie's group as before.
- **M2.** Heinrich–Anna "m. Altona"; Johann–Maria "m. 12 Jun 1841"; Johann–Sophie "m.".
- **M3.** Two lines over Maria: "m. 12 Jun 1841 · Hamburg", then "m. Lübeck".
- **M4.** F2's family: in group 1, "m. 3 May 1812 · Altona, with Heinrich Weber" between Heinrich and Anna, "m. abt 1816 · Kiel, with Heinrich Weber" under Katharina; group 2 "m. 3 May 1812 · Altona" between its two; group 3 "m. abt 1816 · Kiel" between its two.

States: empty as today (`isEmpty`: group 0 holds only the person with no parents, no other group, no right group). Error and loading unchanged (section host). Accessibility per FG-4, FG-5, FM-6.

### Strings

L10n keys *(new)*:
- `lifeLine.birth.abbreviation` "b.", `lifeLine.birth.word` "Born", `lifeLine.birth.inline` "born"; the same three for `death` ("d.", "Died", "died") and `marriage` ("m.", "Married", "married").
- `conclusions.lifeLine.withSpouse` ", with %@" (drawn; the comma attaches to the part before it); `conclusions.a11y.withSpouse` "with %@".
- `conclusions.family.caption.sharedParent` "Shared parent", `.sharedParents` "Shared parents", `.otherSiblings` "Other siblings".
- `conclusions.family.group.childrenOf` "Children of %@", `.thisPersonSiblingsAndParents` "This person, siblings and parents", `.thisPersonAndParents` "This person and parents".

Removed: the keys in **Deletes**. `familyThisPerson`'s comment changes to "the person's group with no parents and no siblings"; `familyCaptionSiblings`' to "no parents recorded".

## 7. Steps

**STEP-1 — One table of life-line words.**
Files: `macos/App/Platform/L10n.swift`, `Localizable.xcstrings`, `PersonLifeDisplay.swift`, `macos/ProvenenciaTests/PersonDetailTests.swift`. Skill: `add-localized-string`.
Do: add `L10n.LifeLineWords` (D-2); route `lifeLines` through the general builder (D-3) with `LifeLineWords.birth` and `.death`; delete the six old constants and keys.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PersonDetailTests` passes with its life-line expectations unchanged (T-1).

**STEP-2 — The parity row.**
Files: `api/ffi/swift_vocabulary_test.go`.
Do: a subtest of `TestSwiftVocabularyMatchesGo` reads the body of `static func words(eventTypeKey` from `swiftL10n`, collects the `SeededEventTypeTerm` names it switches on (`lifeLineCase` *(new)*: `case SeededEventTypeTerm\.(\w+): return`), maps them to keys through `swiftNamedKey` over the `SeededEventTypeTerm` body, and fails for each `kinship.SpouseEventTypes()` key it lacks (T-2).
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/ -run TestSwiftVocabularyMatchesGo` passes; removing the marriage case fails it (run once, revert).

**STEP-3 — A marriage is a life line.**
Files: `PersonLifeDisplay.swift`, `PVDatePlaceLine.swift`, `macos/App/DesignSystem/README.md`, `L10n.swift`, `Localizable.xcstrings`, `macos/ProvenenciaTests/PersonLifeDisplayTests.swift` *(new)*. Skills: `add-ui-component`, `add-localized-string`, `add-swift-test`.
Do: `eventLine(_:partner:locale:)`, `LifeLine.partner`, `PVDatePlaceLine.trailing`, the two with-spouse keys (D-3, D-4).
Check: `-only-testing:ProvenenciaTests/PersonLifeDisplayTests` passes (T-3).

**STEP-4 — Family draws the sibling groups.**
Files: `PersonFamilyContent.swift`, `PersonFamilyLayout.swift`, `PersonFamilySection.swift`, `PersonFamilyPreviewData.swift`, `L10n.swift`, `Localizable.xcstrings`, `PersonFamilyContentTests.swift`, `PersonFamilyLayoutTests.swift`. Skills: `add-ui-component`, `add-localized-string`, `add-swift-test`.
Do: the content reads `siblingGroups` and right-column units only (D-6, D-7, D-8); the layout places groups (D-10, D-11, no lines yet); fixtures `full` (F1: adds `group([anna], [christian])`), `conflicting` (F2), `oneParentGroups` (F3), `unrelatedSets` (F4), `siblingsOnly` (F6: person Johann with Clara 1815 and Karl 1820), `annaOnly` (11h) built with `group(parents:children:couples:)` and no `originSiblings`; previews; caption and label keys; `familyCaptionOtherParent(s)` deleted. Content and layout tests rewritten (T-4, T-6, T-7, T-8, T-9).
Check: `-only-testing:ProvenenciaTests/PersonFamilyContentTests -only-testing:ProvenenciaTests/PersonFamilyLayoutTests` passes; each F preview renders in Xcode.

**STEP-5 — Family draws each couple's marriages.**
Files: as STEP-4.
Do: `MarriageLine`, `ParentMarriage`, `Group.marriages`, `allMarriageLines` (D-5, D-9); `PlacedLine`, gaps and partner offsets (D-10); the diagram draws them (D-11); fixtures `married`, `marriageHalves`, `twoMarriages`, `threeParentMarriages` with `couple(…)` and `marriage(id:dating:place:)` (a `CatalogEventSummary` of type `SeededEventTypeTerm.marriage`, origin `CatalogOrigin.provenencia`); previews M1 – M4.
Check: the same two suites pass with T-5, T-10, T-11; each M preview renders.

**STEP-6 — The app stops reading the old fields.**
Files: `GenealogyStore.swift`, `GoStore.swift`, `FakeStore.swift` if it names them, `macos/ProvenenciaTests/*` that construct them.
Do: delete `originSiblings`, `CatalogOriginSibling`, `Kind.parents`, `.siblings`, and `mapFamilyUnit`'s two cases; rewrite `CatalogPersonFamily`'s doc comment (partner units, one-parent unit, the sibling groups, the couples).
Check: `rg -n "originSiblings|CatalogOriginSibling|\.parents\b.*CatalogFamilyUnit|kind: \.siblings" macos` finds nothing; the full `xcodebuild test` passes.

**STEP-7 — The engine stops sending them.**
Files: `api/proto/engine.proto`, generated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/person_detail.go` and its test, `core/database/persondetail/family.go` and its tests, `core/kinship/families.go`, `siblings.go`, `kinship.go` and their tests. Skills: `add-ffi-handler`, `add-match-rule`.
Do: D-12 – D-15 and **Deletes**' Go and proto lines. `GoStore.mapFamilyUnit` loses the two generated cases with the regeneration.
Check: `./scripts/generate-proto.sh`; `CGO_ENABLED=1 go test -tags fts5 ./core/kinship/... ./core/database/persondetail/... ./api/ffi/...` passes; `go test -tags fts5 -run xxx -fuzz FuzzFamilyUnits -fuzztime 30s ./core/kinship/` finds nothing; `rg -n "UnitParents|UnitSiblings|parentUnits|OriginSibling|UnitCouples|origin_siblings" core api --glob '!*.pb.go'` finds nothing.

**STEP-8 — Docs.**
Files: `.agents/skills/add-match-rule/SKILL.md` (the `core/kinship` paragraph: "with more parents than `Rules.MaxPivotEnd`, `FamilyUnits` pairs none and places each sibling once" becomes "`Couples` pairs no parents"), `docs/deployment-plan/spike-16/deployment-plan.md` (caps list line "the bound `parentUnits` already uses" → "`pairsParents`"; map row; scope entry unchanged), `docs/ideas/person-page-performance.md` (the P-8 sentence: siblings ship as the groups' children; `origin_siblings` is gone), `completed.md`, this plan, `design/` (brief → `design/archive/`, `design/README.md` row moves).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-81-family-groups-and-marriages.md` passes; `scripts/check-guidance-names.py` passes; links resolve.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PersonDetailTests.swift` existing life-line tests (lines 470–640) | Unchanged expectations: "born 3 May 1790, Bremen", "Born date unknown, place unknown", `["b.", "d."]` | AC-3.3, D-2 |
| T-2 | Go | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` "every spouse event type has life-line words" *(new)* | Today's L10n → pass; a spouse type with no case → error naming it | AC-3.2 |
| T-3 | Swift | `PersonLifeDisplayTests.swift` `eventLineWordsAndSpeaksAMarriage` *(new)* | en_US. Marriage 12 Jun 1841 at Hamburg → abbreviation "m.", text "m. 12 Jun 1841 · Hamburg", label "married 12 Jun 1841, Hamburg"; place only → label "married in Altona"; date only → "married 12 Jun 1841"; neither → a line, text "m.", label "married"; partner "Heinrich Weber" with abt 1816 at Kiel → text "m. abt 1816 · Kiel, with Heinrich Weber", label "married abt 1816, Kiel, with Heinrich Weber"; type `burial`, or origin not provenencia → nil | AC-2.3, AC-2.7, D-3, D-4 |
| T-4 | Swift | `PersonFamilyContentTests.swift` `siblingGroupsFromFamily` *(replaces `columnsFromFamily`)* | F1 → two groups, parent names `[["Heinrich Weber","Anna Weber"],["Anna Weber"]]`, children `[["Margarethe Weber","Johann Weber","Friedrich Weber","Wilhelm Weber"],["Christian Weber"]]`, Johann the focus with no location; all tile ids unique (Anna `l-g0-anna`, `l-g1-anna`); F2, F3, F4, F6, 11h → the groups of AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6; right column as today | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, D-6 |
| T-5 | Swift | `PersonFamilyContentTests.swift` `badCoupleIndexesDrawNothing` *(new)* | A group with `coupleIndexes: [7]` and a couple whose B is not among the group's parents → no marriages, no crash | Reach, D-9 |
| T-6 | Swift | `PersonFamilyContentTests.swift` `captionsAndGroupLabels` *(rewritten)* | F1 captions `["Parents","Shared parent"]`, labels `["This person, siblings and parents","Children of Anna Weber"]`; F2 `["Parents","Shared parents","Shared parents"]`, labels per AC-1.2; F4 group 0 "This person and parents", last "Other siblings"; F6 `["Siblings"]` "This person and siblings"; 11h no caption, "This person"; one parent in group 0 → "Parent"; right-column cases as today | AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, D-8 |
| T-7 | Swift | `PersonFamilyContentTests.swift` `foldsEachListAtThirty`, `expandedShowsAll`, `foldKeepsTheFocus`, `childrenAndSiblingsPage`, `anchorResolvesToTheTileOrItsFold` *(rewritten)*; `foldDropsHiddenSetIndexes` deleted | 20 + 20 siblings (F5b) → 30 shown, `siblingsHidden` 10, Anna's group drawn with Anna; 30 + 5 → group 1 not drawn, `firstRevealed(by: .siblings)` = `l-g1-anna`; the person 40th of 130 in group 0 → today's expectations with `l-g0-` ids; `l-p0-anna`, `l-s-margarethe` → nil; a hidden group's parent → `more.siblings`; partner and children folds as today | AC-1.8, AC-1.9, AC-1.10, D-7 |
| T-8 | Swift | `PersonFamilyLayoutTests.swift` `regularAndWideMeasures` *(rewritten)* | F1 at 1038 Regular: column 485, right x 553, bus x 521; Heinrich (20, 26), Anna y 130, Margarethe (52, 234) width 453, Wilhelm y 546; line x 10 from y 72 to 592; group 1 caption y 658, its Anna y 684, Christian y 788, its line 730 to 834. At 1180 Regular and Wide: the same y for every tile, columns 556 and 532 | AC-1.1, FG-W1, FM-W1, D-10 |
| T-9 | Swift | `PersonFamilyLayoutTests.swift` `noLineLeavesItsGroup` *(replaces `parentSetRails`)*, `siblingsOnlyAndTheFocusAlone`, `fiftySiblingsStack`, `fiftySiblingsFolded` *(rewritten)* | F2, F3, F4: every vertical segment at x 10 lies inside its group's frame and no two groups' frames intersect; F4 Elisabeth at x 20, no segment at her centre; F6 Clara at (20, 26) with a line at x 10; 11h focus at (20, 26); 49 siblings in one two-parent group → 52 tiles, no overlap, height 26 + 52 × 104 − 12; folded → 31 children and one more row, no line reaches it; each group's `readingOrder` lists parents then children then the more row | AC-1.4, AC-1.5, AC-1.6, AC-1.7, D-10, D-11 |
| T-10 | Swift | `PersonFamilyLayoutTests.swift` `marriageLinesSitBetweenTheCouple` *(new)* | M1: Anna y 151, the line (20, 124, 485 × 21), Margarethe y 255; Maria's line (553, 26, 485 × 21), Maria's tile y 51; Sophie's tile as without marriages plus Maria's 25. M3: Maria y 72 (26 + 42 + 4). M4 group 0: Heinrich–Anna line between Heinrich and Anna, Heinrich–Katharina line below Katharina; `readingOrder` places each line after its j parent (Anna, then Katharina). Wide: same y | AC-2.1, AC-2.4, AC-2.5, FM-W1, D-10, D-11 |
| T-11 | Swift | `PersonFamilyContentTests.swift` `marriagesOfEachCouple` *(new)* | M1 group 0 one line, label "Heinrich Weber and Anna Weber, married 3 May 1812, Altona", `drawnAfter` 0, `spokenAfter` 1; Maria's group one line, label "Johann Weber and Maria Schulz, married 12 Jun 1841, Hamburg"; Sophie none. M2 labels end "married in Altona", "married 12 Jun 1841", "married". M3 two lines in engine order. M4 group 0: lines with `partner` "Heinrich Weber", labels "married 3 May 1812, Altona, with Heinrich Weber" (`drawnAfter` 0, `spokenAfter` 1) and "married abt 1816, Kiel, with Heinrich Weber" (`drawnAfter` 2, `spokenAfter` 2); groups 1, 2 unnamed. M5: 31 partners, Maria married, partner 31 married → 30 groups shown, partner 31's line absent until one page | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, D-5, D-9 |
| T-12 | Go | `core/kinship/families_test.go` `TestSiblingGroupsGrowth` *(new, replaces the three growth tests)* | `crowd(n, 2n)` and `pairs(p, 3)` past the sibling bound, n ∈ {11, 22}, p ∈ {11, 14} → every sibling and the person once across the groups' children; groups ≤ siblings + 1; parents placed ≤ groups × parents; associations shown ≤ 2 × input | D-15, Scale |
| T-13 | Go | `families_test.go` `FuzzFamilyUnits` *(changed)* | Units bound `(children + 1) × (edges + 1) + spouses`; `SiblingGroups`' children count = siblings + 1 | D-15 |
| T-14 | Go | `families_test.go` `TestFamilies`, `TestUnitEmpty` *(trimmed)*; "links say why" reads Quin and Rae from `SiblingGroups` | Partner and one-parent rows unchanged; AC-1.10 → `["Partner{6;}"]`; "siblings unit comes last" → `["Partner{2;}", "OneParent{;14}"]`; rows whose only units were parent sets or siblings deleted; Quin's shapes `shared_parent/16`, `shared_parent/17`, Rae's `shared_parent/17` | D-13, D-15 |
| T-15 | Go | `siblings_test.go` "50,000 parents and a sibling sharing them all" *(changed)* | Also calls `SiblingGroups` and `Couples`; all within one second | D-15 |
| T-16 | Go | `core/database/persondetail/family_test.go` `TestPersonFamily` AC-1.2 (no units), AC-1.5 (Quin and Rae from `f.Groups`), "AC-2.8 …" (reads `u.Couples`); `family_drop_test.go` `TestDropUnread` *(rewritten)*: partner 2 with child 4, partner 5 with child 6, one-parent 7; read 3, 4, 5, 6 → one unit, partner 5; read 3, 4, 6 → none | D-12, D-14 |
| T-17 | Go | `api/ffi/handlers/person_detail_test.go` "carries the person and the sibling group" *(renamed)* | Group 0 children are the person (no link) and the sibling (a link); parents father and mother; the partner unit as today | AC-3.1 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestPersonFamilyGroups`, `TestCraftedFamily`, `TestCraftedMarriages`, `TestPersonFamilyQueryCount`, `CatalogQueryRegistryTests`, `WorkspaceSessionTests` (they construct `CatalogPersonFamily`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: none changes; add-match-rule's kinship paragraph and the working rules' caps line (STEP-8)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Build and run the app; open a project with brief §5's family: Johann Weber b. 1817 with birth events naming Heinrich and Anna as father and mother, Margarethe 1815, Friedrich 1820 and Wilhelm with births naming both, and Christian 1823 recorded as Anna's son only (a parent relationship). Open Johann's Family. See PARENTS with Heinrich and Anna, the four indented, then SHARED PARENT with Anna and Christian; no crossing lines (bar 50).
2. Add a marriage event on 12 Jun 1841 at Hamburg with Johann and Maria Schulz as subjects, and one on 3 May 1812 at Altona with Heinrich and Anna. See "m. 3 May 1812 · Altona" between Heinrich and Anna and "m. 12 Jun 1841 · Hamburg" over Maria; a partner with no marriage event shows none (bar 51).
3. Turn on VoiceOver: the groups are "This person, siblings and parents" and "Children of Anna Weber"; after Anna, "Heinrich Weber and Anna Weber, married 3 May 1812, Altona"; Tab skips the marriage lines.
4. Stretch the window past a 1600 pt pane: the same arrangement, wider columns.
5. Add Katharina as Johann's third parent and marry her to Heinrich (abt 1816, Kiel): see the three-parent group's named lines.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `accessibilitySortPriority` does not order a contained group on macOS | Manual check 3; T-9/T-10 hold the layout's order |
| Generated Swift drops `.parents`/`.siblings` before STEP-6 removes their uses | STEP-6 runs before STEP-7 |
| Tests that construct `CatalogPersonFamily(units:…, originSiblings:)` | STEP-6's `rg` and full test run |

**Stop and report if:**

- `family.siblingGroups` or `couples` in the app's model differ from §4 (S16-82's shape changed).
- VoiceOver reads a two-parent marriage line before the second parent with `accessibilitySortPriority` applied (D-11 cannot work).
- Any Go caller of `persondetail.PersonFamily`, `Families` or `kinship.FamilyUnits` exists beyond those §4 names (`rg` before STEP-7).
- A brief frame and an AC here disagree.
- `TestSwiftVocabularyMatchesGo` cannot read `words(eventTypeKey` with the existing helpers.

## 12. Open questions

None.

## 13. PR

**Title:** S16-81 — Family groups siblings by their parents and shows each couple's marriage
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-81-family-groups-and-marriages.md`.
