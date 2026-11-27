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
**Skills to load:** [`add-ui-component`](../../../../.agents/skills/add-ui-component/SKILL.md), [`add-localized-string`](../../../../.agents/skills/add-localized-string/SKILL.md) (its "Whole phrases"), [`add-swift-test`](../../../../.agents/skills/add-swift-test/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md) (the `core/kinship` page functions paragraph)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/match-rules.mdc`, `.cursor/rules/swift-tests.mdc`
**Context:** brief [S16-D18](../design/S16-D18-family-groups-and-marriages.md); working rules "(Batch 6) Family groups siblings by their parents", "(Batch 6) Family shows a couple's marriage from its events", "(Batch 1) Crafted fan-out is capped, not engineered"; [S16-82's plan](S16-82-family-groups-and-marriages-read.md) and its **Landed** note; [`macos-client-patterns.md` § 9](../../../macos-client-patterns.md#9-window-widths-regular-and-wide). Swift checks need macOS with Xcode; STEP-9 needs `protoc` and its Go and Swift plugins (`scripts/generate-proto.sh` checks for them)
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
| AC-1.3 | F3: {Heinrich, Anna}: Margarethe, Johann, Friedrich; {Heinrich}: Wilhelm; {Anna}: Christian | Captions PARENTS, SHARED PARENT, SHARED PARENT; labels "This person, siblings and parents", "Children of Heinrich Weber", "Children of Anna Weber" |
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
| AC-2.3 | M2: a place only (Altona), a date only (12 Jun 1841), neither | Drawn "m. Altona", "m. 12 Jun 1841", "m."; spoken "…, married in Altona", "…, married 12 Jun 1841", "…, married" (user, 2026-11-27: "in", as a tile's "born in Bremen") |
| AC-2.4 | M3: Johann–Maria with 12 Jun 1841 at Hamburg and an undated one at Lübeck, in that order from the engine | Two lines over Maria's group in that order; Maria's tile 46 pt lower than with none (two lines of 21 pt and 4 pt) |
| AC-2.5 | M4: F2's family, Heinrich–Anna 3 May 1812 at Altona, Heinrich–Katharina abt 1816 at Kiel | In the three-parent group: "m. 3 May 1812 · Altona, with Heinrich Weber" between Heinrich and Anna; "m. abt 1816 · Kiel, with Heinrich Weber" under Katharina. In {Heinrich, Anna} and {Heinrich, Katharina}: the same marriages with no name. The named lines are spoken as drawn ("married abt 1816, Kiel, with Heinrich Weber"), each just after Anna's or Katharina's tile (user, 2026-11-27) |
| AC-2.6 | M5: Maria married, 31 partner units, partner 31 married | Maria's line shows; partner 31's group and its line are hidden; one page shows them |
| AC-2.7 | A marriage of an event type `L10n.LifeLine.copy` does not list, or not of origin provenencia | No line for that marriage |

**US-3.** As a contributor, the engine sends one shape for the left column and a life line's copy lives in one table of whole phrases, so a later union pattern needs one table row.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | `GetPersonFamilyResponse` | Has no `origin_siblings`; `FamilyUnitKind` has no PARENTS or SIBLINGS; units are partner and one-parent units only |
| AC-3.2 | A spouse pattern whose event type has no `L10n.LifeLine.copy` case | `TestSwiftVocabularyMatchesGo` fails, naming the event type |
| AC-3.3 | A person tile's b. and d. lines, and the Person header's | Drawn and spoken as before this PR |

## 3. Scope

| In | Covered by |
| --- | --- |
| FG-1 groups in order, each sibling once, one line per group, no crossing | STEP-4, AC-1.1, AC-1.2, AC-1.4, AC-1.5 |
| FG-2 a parent in several groups has a tile and a Tab stop in each | STEP-4, AC-1.1 |
| FG-3 captions | STEP-4, AC-1.1, AC-1.3, AC-1.4, AC-1.5, AC-1.6 |
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
| FM-W1 lines sit where they sit at Regular | STEP-5, T-10 |
| One table of life-line copy in whole phrases; b. and d. move into it | STEP-1, AC-3.3 |
| The Go parity row for `kinship.SpouseEventTypes()` | STEP-2, AC-3.2 |
| `EventSecondaryDisplay` moves to Platform; `L10n.list` joins names for this PR and its three existing callers | STEP-3 |
| Deleting the old fields and their mechanisms (§6 **Deletes**); `persondetail.Unit` with `Couples` | STEP-6 – STEP-9, AC-3.1 |
| Previews F1 – F4, F6, M1 – M4 and 11h | STEP-4, STEP-5 |
| Docs and guidance the deletions make false | STEP-10 |

| Out | Home |
| --- | --- |
| The engine's grouping and marriages | S16-82 (landed) |
| Opening the marriage from Family; a link, chip or Badge on a marriage | Not planned (brief §2.1: the Timeline opens it) |
| Siblings' or children's marriages; events other than the spouse patterns' | Not planned (brief §2.1) |
| A "+N" place count on a marriage line | Not planned (brief §2: a tile line shows one place) |
| Rewriting other splices (`lifeSpan`, `EventTitle`, the ones in `docs/ideas/international-names.md`) | [`docs/ideas/international-names.md`](../../../ideas/international-names.md) "Whole-phrase copy, app-wide" |
| A family tree reading `SiblingGroups` per generation | [`docs/ideas/kinship-view.md`](../../../ideas/kinship-view.md) |
| Sending relatives as indexes into one table (P-8) | [`docs/ideas/person-page-performance.md`](../../../ideas/person-page-performance.md), descoped (rule "Refused: memoising and re-shaping for speed") |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Family content | `macos/App/Features/Conclusions/PersonFamilyContent.swift` `PersonFamilyContent` | Builds `parentSets` from `.parents` units and `siblings` from `originSiblings`; `Fold.parentSets`; tile ids `l-p{k}-{id}`, `l-s-{id}`; no marriages |
| Family layout | `macos/App/Features/Conclusions/PersonFamilyLayout.swift` `PersonFamilyLayout`, `Group { tiles; more }` | Stacks parent sets, then siblings on rails (`railX`), a bracket at `bracketX`; `afterSet` 20; `betweenGroups` 28 for the right column |
| Diagram | `macos/App/Features/Conclusions/PersonFamilySection.swift` `PersonFamilyDiagram` | Draws segments, captions, then one container per group, tiles then more rows; no `accessibilitySortPriority` anywhere in `macos/App` |
| Fixtures | `macos/App/Features/Conclusions/PersonFamilyPreviewData.swift` `full`, `conflicting`, `siblingsOnly`, `annaOnly`, `origin(_:_:)`, `unit(_:partners:children:)` | Built from `.parents`/`.siblings` units and `originSiblings` |
| Event fixtures | `macos/App/Features/Conclusions/PersonTimelinePreviewData.swift` `event(_:type:…)`, `When`, `When.apply(to:)` | Builds the `CatalogEventSummary` inline; `When` has no qualified date |
| Life lines | `macos/App/Platform/PersonLifeDisplay.swift` `LifeLine`, `lifeLines(_:locale:missing:)`, private `lifeLine(_:facts:locale:missing:spoken:)` | Splices `L10n.Conclusions.a11yBorn`/`a11yBornInline` (and died) into `a11yLifeLine`, `a11yLifeLineKnown`, `a11yLifeLinePlaceOnly`; abbreviations `personBornAbbr`, `personDiedAbbr`; text through `L10n.Conclusions.lifeLineText`; these are their only readers |
| Date · place line | `macos/App/DesignSystem/Components/DatePlaceLine/PVDatePlaceLine.swift` | `HStack(spacing: PVSpacing.space4)` of leading, date, "·", place, `extraCount`; no trailing part |
| Event wording | `macos/App/Features/Conclusions/EventsListView.swift` `EventSecondaryDisplay` | A value formatter in a list view's file; read by `ConclusionSummaryDisplay`, `EventDetailContent`, `PersonTimelineContent`, `EventsListView` |
| List joins | `macos/App/Platform/ReconciledValueDisplay.swift` (line 184), `macos/App/Features/SourceTypes/SourceTypeCopyModel.swift` (line 98), `macos/App/Features/Catalog/Search/CatalogSearchHitPresentation.swift` (line 73) | Three hand-rolled `ListFormatter` joins |
| Person card | `macos/App/DesignSystem/Recipes/PersonCard/PVPersonCard.swift` `PVPersonCardContent`, `PVPersonCard.lines` | Draws `content.lines` with `PVDatePlaceLine(…, missing: .omitted)`, no `extraCount` |
| Seeded event terms | `macos/App/Platform/L10n.swift` `L10n.PropertyTerm.resource`; `macos/App/Platform/ConclusionVocabulary.swift` `SeededEventTypeTerm`, `CatalogOrigin.isProduct` | The switch shape the parity test reads; the origin check `PropertyTermDisplay.name` uses |
| Family copy | `L10n.swift` `L10n.Conclusions.familyCaption*`, `familyGroup*`, `familyThisPerson` | `familyCaptionOtherParent(s)` read only by the content's parent captions |
| Swift model | `macos/App/Platform/GenealogyStore.swift` `CatalogPersonFamily.originSiblings`, `CatalogOriginSibling`, `CatalogFamilyUnit.Kind.parents`, `.siblings`; `macos/App/Platform/GoStore.swift` `getPersonFamily`, `mapFamilyUnit` | Maps both old and new fields |
| Proto | `api/proto/engine.proto` `GetPersonFamilyResponse` (fields 1–6), `OriginSibling`, `FamilyUnitKind` | Field 3 and `OriginSibling` read only by `GoStore`; enum values 1 and 4 |
| Handler | `api/ffi/handlers/person_detail.go` `GetPersonFamily`, `familyUnitKindProto` | Maps `family.UnitCouples[k]` and the origin siblings (lines 177–186) |
| Family read | `core/database/persondetail/family.go` `Family.UnitCouples`, `OriginSibling`, `PersonFamily` (returns `(Family, []OriginSibling, Summaries, error)`), `originSiblings`, `indexCouples`, `dropUnread` | `UnitCouples` is parallel to `Units` |
| Kinship | `core/kinship/families.go` `UnitParents`, `UnitSiblings`, `Unit.Empty`, `FamilyUnits(person, kin, kinOf, rules)`, `parentUnits` (with `paired`), `subset`; kept: `sharedParents`, `spouseLink`, `filedSpouseLink`, `pairsParents`, `SiblingGroups`, `Couples` | `FamilyUnits` returns parent sets, partners, one-parent and siblings units; only `parentUnits` reads `rules` |
| Comments naming the old shape | `core/kinship/siblings.go` (`Siblings` doc); `core/kinship/kinship.go` package doc; `docs/deployment-plan/spike-16/person-page-audit.md` line 107; the working rules' caps list (`deployment-plan.md` line 233) | Name `parentUnits` |
| Go parity test | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo`, `swiftFuncBody`, `swiftEnumBody`, `swiftNamedKey`, subtest "every composer-worded term has composer wording" | No life-line row |
| Swift tests | `macos/ProvenenciaTests/PersonFamilyContentTests.swift`, `PersonFamilyLayoutTests.swift`; `PersonDetailTests.swift` `lifeLinesOmitMissingHalves`, `lifeLinesSayUnknownUntilLifeEventsArrive` and the `extraPlaces` expectations (lines 478–517) | Assume parent sets, rails, `originSiblings` |
| Go tests | `core/kinship/families_test.go` `TestFamilies`, `TestFamiliesMoreParentsThanMaxPivotEnd`, `TestFamiliesGrowth`, `TestFamiliesGrowthPairs`, `TestUnitEmpty`, `FuzzFamilyUnits`, helpers `unitsPastSiblingBound`, `linksPastSiblingBound`, `crowd`, `pairs`, `placements`, `shown`, `unitName`; `siblings_test.go` "50,000 parents and a sibling sharing them all"; `core/database/persondetail/family_test.go` `unitKind`, `relative`, `TestPersonFamily` (AC-1.2, AC-1.5), `TestPersonFamilyOriginSiblings`, "AC-2.8 …"; `family_drop_test.go` `TestDropUnread`; `caps_test.go`; `api/ffi/handlers/person_detail_test.go` "carries the person and the origin siblings" | Read the parent and siblings units or origin siblings |

**Precedent.** S16-82 ([#1009](https://github.com/Jake-Robins-Studios/provenencia/pull/1009)) shaped `persondetail.Group`; copy it for `persondetail.Unit`. The `LifeMarker` message's `reserved 2; reserved "beside_event_id";` (`engine.proto`) is the precedent for a removed field. The Promote menu's per-kind keys (`L10n.Promote.newOption(_:)`) are the whole-phrase precedent.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | One PR; the life-line copy table and the parity row are its first two commits | The table's only new reader is this PR's marriage line | A preparatory PR with nothing to show |
| D-2 | `L10n.LifeLine` (shape in **Codebase fit**) holds each event type's copy as whole phrases: the abbreviation, the header's stated phrase, three inline phrases (date and place, date only, place only), an optional bare phrase, and for spouse types the with-spouse phrases. No phrase takes a translated word as an argument. `copy(eventTypeKey:origin:)` returns nil unless `CatalogOrigin.isProduct(origin)`, then switches over `SeededEventTypeTerm` constants. Birth and death have no bare phrase and no with-spouse phrases; marriage has both | `add-localized-string` "Whole phrases"; the origin rule sits with the lookup, as `PropertyTermDisplay.name` does | One table of bare words spliced into shared formats — a splice per sentence |
| D-3 | `PersonLifeDisplay.lifeLine` builds every line from a `Copy`: `.stated` uses `stated` with the "unknown" fill-ins; `.omitted` picks the phrase by which halves are present, and with both missing uses `bare`, or returns nil when the copy has none. So a person's missing b. or d. is left out and a marriage with neither half is kept (FM-4) by the table's data, not a flag | One builder (user, 2026-11-27: "married in Altona") | A `keepsBare` Bool for one caller |
| D-4 | A named line (FM-2) passes the other spouse's `PVTitleSource`. Spoken, `lifeLine` picks the with-spouse phrase ("married abt 1816, Kiel, with Heinrich Weber", from `title.spokenText`); drawn, `LifeLine.trailing` is the with-spouse drawn phrase (", with Heinrich Weber", from `title.text`). Family speaks that label with no couple before it (user, 2026-11-27) | FM-2, FM-6; the tile just before the line names the other spouse | Prefixing the couple — "Heinrich Weber" spoken twice |
| D-5 | An unnamed line is spoken as the couple's names, `L10n.list([a, b], locale:)`, then the line's label, through `L10n.DesignSystem.spokenJoin`: "Heinrich Weber and Anna Weber, married 3 May 1812, Altona". A parents' couple names parents i then j (D-9); a partner's couple names the person, then the partner. With no focus tile (`family.person` nil) a partner's line is spoken by its own label | FM-6; one list join | A "%@ and %@" key |
| D-6 | The left column draws `family.siblingGroups` in the engine's order with no regrouping. Tile ids are `l-g{k}-{personID}`, k the group's index in `siblingGroups`; the right column keeps `r-{index}-{personID}`. Marriage line ids are `l-g{k}-m-{eventID}` and `r-{index}-m-{eventID}` | A parent in two groups needs an id per group; k is stable across folds | A per-parent counter |
| D-7 | One fold, `.siblings`, over every group's children other than the person, in group order. Group 0 always shows; another group shows when its first child does, with all its parents. The person sits in group 0 at their engine place when the sibling before them shows, else last of group 0's shown children (today's rule). The Show more row sits under the last shown child. `firstRevealed(by: .siblings)` is the first revealed child, or its group's first parent when that child is its group's first child. `Fold.parentSets` and `"more.parentSets"` go | FG-6; the keyboard lands on the first new stop in Tab order | Folding parent tiles |
| D-8 | Captions: group 0 is PARENTS (two or more parents), PARENT (one), SIBLINGS (none, with a sibling besides the person), or none. Another group is SHARED PARENTS, SHARED PARENT, or OTHER SIBLINGS (no parents). Labels: group 0 "This person, siblings and parents", "This person and parents", "This person and siblings" or "This person", by whether it has parents and a child other than the person in the engine's list; another group with parents "Children of %@" (names by `L10n.list`); without, "Other siblings" (the caption's key, as the one-parent unit's label reuses "Children") | FG-3, FG-4 | — |
| D-9 | A group's lines come from its `coupleIndexes`, in that order, each couple's marriages in the engine's order. For a couple whose ends sit at i < j among the group's parents (matched by entity id): `drawnAfter` = i when j = i + 1, else j; `spokenAfter` = j. Lines name the other spouse (parent i) only when the group has more than two parents. An index past `couples`, or a couple with an end not among the group's parents, draws nothing. A partner unit's lines come from its `coupleIndexes` and sit at the top of its group, read first | FM-2, FM-6 | Swift matching couples by id pair across the family |
| D-10 | Geometry: each sibling group reserves the 26 pt caption band; parents at x 20, full column width; children at x 52, width less 32 (x 20, full width, in a group with no parents); the gap after any parent (the last one included, before the children) is 12 pt plus 21 pt per line in it, each line 21 pt tall starting 6 pt below the tile; sibling groups are 20 pt apart (`siblingGroupGap`); the right column keeps its caption band and 28 pt between partner groups (`betweenGroups` renamed `partnerGroupGap`); a partner group's lines start at its top and its tile moves down 21 pt per line plus 4 pt when it has any; one line per sibling group at x 10 (`lineX`), from its first tile's centre to its last child's, horizontals to x 20 for parents and x 52 for children; a parentless group of two or more is joined with horizontals to x 20; a lone parentless child has no line. `railX`, `bracketX` and `afterSet` go | The agreed board; every tile keeps 92 pt | — |
| D-11 | Each `PersonFamilyLayout.Group` holds one ordered `items` list (tile, line, Show more) in VoiceOver order; the diagram walks it once and gives each item `accessibilitySortPriority(Double(items.count - index))` inside the group's container | A two-parent line is drawn between the tiles but read after the second (FM-6); one list holds the order once | A separate `readingOrder` beside three arrays |
| D-12 | `persondetail.Family.Units` becomes `[]Unit`, `Unit{kinship.Unit; Couples []int}`, as `Group` is; `UnitCouples` goes; `indexCouples` fills `Unit.Couples` | No parallel slice to misalign | Keeping `UnitCouples` |
| D-13 | Proto: field 3 and `OriginSibling` go, with `reserved 3; reserved "origin_siblings";`; `FAMILY_UNIT_KIND_PARENTS` and `_SIBLINGS` go, with `reserved 1, 4; reserved "FAMILY_UNIT_KIND_PARENTS", "FAMILY_UNIT_KIND_SIBLINGS";`. `kinship.UnitPartner` becomes `iota + 1`. `FamilyUnits(person, kin, kinOf)` drops `rules` and returns the partner units, then the one-parent unit when not empty | No reader is left (user, 2026-11-27); no dead parameter | Leaving them deprecated |
| D-14 | `PersonFamily` returns `(Family, conclusionsummaries.Summaries, error)` | The origin siblings are gone | — |
| D-15 | The kinship tests that bound parent sets move their bound to `SiblingGroups` (T-12, T-13) | What the page now draws is the groups | Deleting the bounds |
| D-16 | `EventSecondaryDisplay` moves unchanged to `macos/App/Platform/EventSecondaryDisplay.swift` *(new)*; `EventSecondaryLine` stays | A Platform formatter must not live in a list view's file once Platform reads it | Calling into the feature file |
| D-17 | The brief's FM-6 examples follow the user's two answers, changed in this planning commit | Brief and plan agree (user, 2026-11-27) | — |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `L10n.LifeLine`, `.Copy`, `.SpouseCopy`, `.birth`, `.death`, `.marriage`, `copy(eventTypeKey:origin:)`, `text(abbreviation:rest:)` *(new; the last moves from `L10n.Conclusions.lifeLineText`)* | L10n namespace | `L10n.PropertyTerm`, `L10n.Conclusions.personBornAbbr`, `a11yLifeLine*` | One home for a life line's copy; the old constants move in or go |
| `L10n.list(_:locale:)` *(new)* | func | the three joins in §4 | They become its callers |
| `PersonLifeDisplay.lifeLine(_:date:place:extraPlaces:missing:partner:)`, `eventLine(_:partner:locale:)` *(new)*; `LifeLine.trailing` *(new)* | func, field | private `lifeLine(_:facts:…)` | Generalised from it; the private one goes |
| `PVDatePlaceLine.trailing` *(new)* | component param | `extraCount` | The brief marks the component Extend |
| `macos/App/Platform/EventSecondaryDisplay.swift` *(new)*, moved | file | `EventsListView.swift` | D-16 |
| Family keys (§6 **Strings**) *(new)* | keys | `familyCaption*`, `familyGroup*` | Brief copy |
| `PersonFamilyContent.SiblingGroup`, `.MarriageLine`, `.ParentMarriage`, `siblingGroups`, `Group.marriages`, `allMarriageLines` *(new)* | types, fields | `PersonFamilyContent.Group` | The left group has parents, a caption and parents' lines; the right `Group` keeps its name |
| `PersonFamilyLayout.PlacedLine`, `.Placed`, `Group.items`, `lineX`, `marriageLineHeight`, `partnerMarriageGap`, `siblingGroupGap`; `betweenGroups` → `partnerGroupGap` *(new / renamed)* | types, consts | `PlacedTile`, `PlacedMore`, `afterSet` | Placed like tiles; `tiles` and `more` become computed from `items` |
| `PersonTimelinePreviewData.eventSummary(_:type:subjects:when:place:picture:)`, `When.about(Int32)` *(new, split out of `event`)*; `PersonFamilyPreviewData.group`, `couple`, `marriage` and the fixtures of §6 **macOS** *(new)* | helpers | `PersonTimelinePreviewData.event`, `PersonFamilyPreviewData.unit`, `origin` | `event` calls `eventSummary`; `origin` goes |
| `persondetail.Unit` *(new)* | type | `persondetail.Group` | Same shape (D-12) |
| Parity subtest "every spouse event type has life-line copy" *(new)*, regex `lifeLineCase` *(new)* | test | "every composer-worded term has composer wording", `wordingCase` | Same pattern over another switch |

Swift shapes:

```swift
// L10n.swift
enum LifeLine {
    struct SpouseCopy: Equatable {
        let dateAndPlace: LocalizedStringResource // "married %1$@, %2$@, with %3$@"
        let dateOnly: LocalizedStringResource     // "married %1$@, with %2$@"
        let placeOnly: LocalizedStringResource    // "married in %1$@, with %2$@"
        let bare: LocalizedStringResource         // "married, with %@"
        let drawn: LocalizedStringResource        // ", with %@"
    }
    struct Copy: Equatable {
        let abbreviation: LocalizedStringResource // "b."
        let stated: LocalizedStringResource       // "Born %1$@, %2$@"
        let dateAndPlace: LocalizedStringResource // "born %1$@, %2$@"
        let dateOnly: LocalizedStringResource     // "born %@"
        let placeOnly: LocalizedStringResource    // "born in %@"
        let bare: LocalizedStringResource?        // nil for birth and death; "married"
        let withSpouse: SpouseCopy?               // nil for birth and death
    }
    static let birth: Copy, death: Copy, marriage: Copy
    static func copy(eventTypeKey: String, origin: String) -> Copy?
    static func text(abbreviation: String, rest: String) -> String
}

// PersonLifeDisplay.swift
struct LifeLine: Equatable {
    var abbreviation: String
    var date: String?
    var place: String?
    var extraPlaces: Int = 0
    var trailing: String? = nil   // drawn after the place: ", with Heinrich Weber"
    var accessibilityLabel: String
    var text: String              // today's text, then `trailing`
}
static func lifeLine(_ copy: L10n.LifeLine.Copy, date: String?, place: String?, extraPlaces: Int = 0,
                     missing: PVDatePlaceLine.Missing, partner: PVTitleSource? = nil) -> LifeLine?
static func eventLine(_ event: CatalogEventSummary, partner: PVTitleSource? = nil,
                      locale: Locale = .autoupdatingCurrent) -> LifeLine?   // always .omitted

// PersonFamilyContent.swift
struct MarriageLine: Equatable { var id: String; var line: PersonLifeDisplay.LifeLine; var accessibilityLabel: String }
struct ParentMarriage: Equatable { var marriage: MarriageLine; var drawnAfter: Int; var spokenAfter: Int } // parent indexes
struct SiblingGroup: Equatable {
    var caption: String?
    var parents: [PersonCardLink]
    var children: [PersonCardLink]   // the shown ones; the person among them in group 0
    var marriages: [ParentMarriage]
    var label: String
}
// Group (right column) gains: var marriages: [MarriageLine] = []
// PersonFamilyContent: var siblingGroups: [SiblingGroup]  (shown groups only); var siblingsHidden: Int
//                      var allMarriageLines: [MarriageLine]

// PersonFamilyLayout.swift
struct PlacedLine: Equatable { var id: String; var frame: CGRect }   // relative to its group
enum Placed: Equatable, Identifiable { case tile(PlacedTile), line(PlacedLine), more(PlacedMore) } // id: tile id, line id, moreID
// Group: var items: [Placed]; tiles, lines and more are computed from items
```

**Builds on.** `EventSecondaryDisplay.content`, `DateRowDisplay`, `DerivedPlace`, `PVPersonCardContent`, `PagedFold`, `PVShowMoreRow`, `conclusionAnchorRestore`, `L10n.DesignSystem.spokenJoin`, `CatalogOrigin.isProduct`; S16-82's `siblingGroups`, `couples` and `coupleIndexes`.

**Deletes.**
- Go: `kinship.UnitParents`, `UnitSiblings`, `parentUnits` (with `paired`, its extra sets), `subset`, `FamilyUnits`' `rules`; `persondetail.OriginSibling`, `originSiblings`, `Family.UnitCouples`; `familyUnitKindProto`'s two cases; tests `TestPersonFamilyOriginSiblings`, `TestFamiliesMoreParentsThanMaxPivotEnd`, `TestFamiliesGrowth`, `TestFamiliesGrowthPairs`, helpers `unitsPastSiblingBound` and `shown`, the rows of T-14, the handler's origin-siblings check.
- Proto: `GetPersonFamilyResponse.origin_siblings`, `OriginSibling`, `FAMILY_UNIT_KIND_PARENTS`, `FAMILY_UNIT_KIND_SIBLINGS` (regenerated Go and Swift).
- Swift: `CatalogOriginSibling`, `CatalogPersonFamily.originSiblings`, `CatalogFamilyUnit.Kind.parents`, `.siblings`; `PersonFamilyContent.Sibling`, `parentSets`, `parentCaptions`, `parentSetsHidden`, `siblings`, `siblingsCaption`, `siblingsLabel`, `Fold.parentSets`; `PersonFamilyLayout.railX`, `bracketX`, `afterSet`; `PersonFamilyPreviewData.origin`; `PersonLifeDisplay`'s private `lifeLine(_:facts:…)`.
- Strings: `conclusions.family.caption.otherParent`, `.otherParents`; `conclusions.person.born`, `conclusions.person.died`, `conclusions.a11y.born`, `.died`, `.bornInline`, `.diedInline`, `conclusions.a11y.vital`, `.vitalKnown`, `.vitalPlaceOnly`, `conclusions.lifeLine.text` (moved to `lifeLine.text`), with their `L10n` constants.

**Next adds.** A union pattern with term `TermSpouse` reaches `Couples` (S16-82) and here needs one `L10n.LifeLine` case with its whole phrases; the parity row fails until it has one. A baptism or burial line on a tile is one more case and a builder call.

### Reach

| New path or state | Destination | Checked |
| --- | --- | --- |
| An anchor from older history (`l-p…`, `l-s…`) | `PersonFamilyContent.anchorStop` | No tile and no hidden tile has that id → nil → section top (AC-1.10) |
| A parent with two tiles | `PersonFamilyDiagram`, the `tiles` dictionary | Ids differ by group (D-6); keys stay unique |
| A bad couple index or end | `PersonFamilyContent.init` | Skipped (D-9, T-5) |
| `family.person` nil | group 0, partner lines | No focus tile; labels from the engine's children; partner lines spoken by their own label (D-5) |

### Scale

At the map's Scale (real: 20 children in four groups, one or two marriages a couple): the content builds tiles only for shown groups; a fold page adds at most 50 children. Crafted: `KinOf` caps parents and siblings at 100 each (`MaxKinPerRole`), so at most 31 groups show before the first page, each with at most 100 parent tiles: 3,100 tiles, the same order as today's 30 folded parent sets of up to 100 parents each. Marriages: at most 10 per couple (`maxMarriagesPerCouple`); couples at most 100 spouses plus 45 parent pairs (`pairsParents`). No write, cache key or read changes.

### Edges

- **Assumptions.** Each sibling is in exactly one group and the person only in group 0 (S16-82 `TestSiblingGroups`); a group's couples have both ends among its parents (S16-82 `indexCouples`); a couple's A is earlier than B in the person's parent order. A broken one draws less, never crashes (T-5).
- **Neighbors.** Two-parent group (unnamed line in the gap) vs three-parent group (named lines); adjacent vs non-adjacent pair in a three-parent group; one vs two marriages; a partner with vs without a marriage; a parentless group of one (no line) vs two (one line); group 0 with no parents and no siblings (no caption) vs with siblings (SIBLINGS). Each is a T-row.
- **Removed inputs.** A merged marriage is not sent (S16-82); a folded group hides its lines (AC-2.6); an event type without copy draws no line (AC-2.7).
- **Real data.** `L10n.LifeLine` holds birth, death, marriage; `kinship.SpouseEventTypes()` today is `[marriage]`; the parity row checks all of it.
- **Untrusted size.** Bounded by the engine's caps above; the layout is linear in drawn tiles and lines.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/kinship` | D-13; `Unit.Empty`: partner → no partner, one-parent → no child; the package, `FamilyUnits`, `pairsParents` and `Siblings` doc comments say what the functions do now ("the bound `Couples` uses to pair parents") |
| `core/database/persondetail` | `type Unit struct { kinship.Unit; Couples []int }`; `Family.Units []Unit`; `Families` wraps each `kinship.Unit`; `indexCouples` fills `Unit.Couples`; `dropUnread` filters `[]Unit`; D-14; doc comments drop the origin siblings |

### FFI

`api/proto/engine.proto` per D-13; regenerate with `./scripts/generate-proto.sh`. Handler `GetPersonFamily`: `CoupleIndexes: indexes(u.Couples)`; the origin-siblings loop goes; `familyUnitKindProto` maps partner and one-parent only.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Family diagram | Snowflake, Extend | `PersonFamilySection.swift` `PersonFamilyDiagram` | Lines as today (one-point rects, `PVColor.borderStrong`); captions as today; per group one `ForEach` over `items` (D-11); a line item is `PVDatePlaceLine(leading:date:place:accessibilityLabel:missing: .omitted, trailing:)` in its frame, no `extraCount`, not focusable |
| Family layout | Snowflake, Extend | `PersonFamilyLayout.swift` | D-10, D-11; doc comment: "each sibling group under its caption, its parents then its children, one line per group" |
| Family content | Snowflake, Extend | `PersonFamilyContent.swift` | D-5 – D-9; doc comment drops "parent sets" |
| Show more row | `PVShowMoreRow` | unchanged | D-7 |
| Life line | Platform type, Extend | `PersonLifeDisplay.swift` | D-3, D-4 |
| Date · place line | Component, Extend | `PVDatePlaceLine.swift` | When `trailing` is set, the last part drawn (the place, else the date, else the leading abbreviation) and `trailing` sit in an inner `HStack(spacing: 0)`; `trailing` has `lineLimit(1)`, `fixedSize()` and `layoutPriority(1)`; the place keeps its tail truncation; the "·" rule is unchanged. A `#Preview("Trailing part")` shows date and place, date only, abbreviation only, each with a trailing part. README row gains "an optional trailing part drawn after the place and never cut" |
| Life-line copy | — | `L10n.swift`, beside `L10n.PropertyTerm` | D-2 |
| Previews | Snowflake | `PersonFamilyPreviewData.swift`, `#Preview`s in `PersonFamilySection.swift` | One per fixture below, named "F1 Shared parent", "F2 Records that disagree", "F3 One-parent groups", "F4 Unrelated sets", "F6 No parents recorded", "M1 Marriages", "M2 Missing halves", "M3 Two marriages", "M4 Three parents", "11h After clicking Anna" |

Fixtures (`PersonFamilyPreviewData`; `group(_ parents:, _ children:, couples: [Int] = [])`, `unit(_:partners:children:couples:)`, `couple(_ a: String, _ b: String, _ marriages: CatalogEventSummary...)` by entity id, `marriage(_ id:, when: PersonTimelinePreviewData.When?, place: String?)` = `PersonTimelinePreviewData.eventSummary(id, type: SeededEventTypeTerm.marriage, when:, place:)`):

| Fixture | Groups | Units | Couples |
| --- | --- | --- | --- |
| `full` (F1) | [Heinrich, Anna]: Margarethe 1815, Johann, Friedrich 1820, Wilhelm; [Anna]: Christian 1823 | Maria: Karl, Luise, Emma; Sophie: Otto; one-parent: Paul | — |
| `conflicting` (F2) | [Heinrich, Anna, Katharina]: Johann, Friedrich; [Heinrich, Anna]: Margarethe, Wilhelm; [Heinrich, Katharina]: Christian | — | — |
| `oneParentGroups` (F3) | [Heinrich, Anna]: Margarethe, Johann, Friedrich; [Heinrich]: Wilhelm; [Anna]: Christian | — | — |
| `unrelatedSets` (F4) | [Heinrich, Anna, Georg Becker, Katharina Becker]: Johann; [Heinrich, Anna]: Margarethe, Friedrich; [Georg, Katharina]: Christian; []: Elisabeth Weber | — | — |
| `siblingsOnly` (F6) | []: Clara 1815, Johann, Karl 1820 | — | — |
| `married` (M1) | `full`'s, group 0 couples [0] | `full`'s, Maria couples [1] | heinrich+anna: `.day(1812, 5, 3)` Altona; johann+maria: `.day(1841, 6, 12)` Hamburg |
| `marriageHalves` (M2) | group 0 couples [0] | Maria [1], Sophie [2] | heinrich+anna: no date, Altona; johann+maria: `.day(1841, 6, 12)`, no place; johann+sophie: neither |
| `twoMarriages` (M3) | `full`'s | Maria [0] | johann+maria: `.day(1841, 6, 12)` Hamburg, then no date, Lübeck |
| `threeParentMarriages` (M4) | `conflicting`'s, couples [0, 1], [0], [1] | — | heinrich+anna: `.day(1812, 5, 3)` Altona; heinrich+katharina: `.about(1816)` Kiel |
| `annaOnly` (11h) | []: Anna (person, no link) | Heinrich: Margarethe, Johann, Friedrich, Wilhelm | — |

**Frames in words** (Regular pane 1102, primary column 1038; Wide the same with wider columns and a 96 pt gutter):
- **F1.** Caption PARENTS at the top left. Heinrich's tile, Anna's below. Margarethe, Johann (raised, "This person" badge), Friedrich, Wilhelm indented 32 pt beneath. One line at x 10 from Heinrich's centre to Wilhelm's, short horizontals to each tile. 20 pt lower: SHARED PARENT, Anna, Christian indented, its own line. Right column unchanged.
- **F2 – F4, F6** as their fixtures, one caption per group (D-8); F4's Elisabeth at the margin with no line; F6's three at the margin joined by one line.
- **M1.** "m. 3 May 1812 · Altona" in the widened gap between Heinrich and Anna; "m. 12 Jun 1841 · Hamburg" at the top of Maria's group, Maria's tile below it; Sophie's group as before.
- **M2.** "m. Altona", "m. 12 Jun 1841" over Maria, "m." over Sophie. **M3.** Two lines over Maria: "m. 12 Jun 1841 · Hamburg", then "m. Lübeck".
- **M4.** Group 0: "m. 3 May 1812 · Altona, with Heinrich Weber" between Heinrich and Anna, "m. abt 1816 · Kiel, with Heinrich Weber" under Katharina; group 1 "m. 3 May 1812 · Altona" between its two; group 2 "m. abt 1816 · Kiel" between its two.

States: empty as today (`isEmpty`: group 0 holds only the person, with no parents, no other group, no right group). Error and loading unchanged (section host).

### Strings

L10n keys *(new)*, all in `L10n.LifeLine` unless named:
- birth: `lifeLine.birth.abbreviation` "b.", `.stated` "Born %1$@, %2$@", `.dateAndPlace` "born %1$@, %2$@", `.dateOnly` "born %@", `.placeOnly` "born in %@"; death the same with "d.", "Died", "died".
- marriage: `lifeLine.marriage.abbreviation` "m.", `.stated` "Married %1$@, %2$@", `.dateAndPlace` "married %1$@, %2$@", `.dateOnly` "married %@", `.placeOnly` "married in %@", `.bare` "married"; `.withSpouse.dateAndPlace` "married %1$@, %2$@, with %3$@", `.withSpouse.dateOnly` "married %1$@, with %2$@", `.withSpouse.placeOnly` "married in %1$@, with %2$@", `.withSpouse.bare` "married, with %@", `.withSpouse.drawn` ", with %@" (its comment: drawn after the place, the comma attached).
- `lifeLine.text` "%1$@ %2$@" (moved).
- `L10n.Conclusions`: `conclusions.family.caption.sharedParent` "Shared parent", `.sharedParents` "Shared parents", `.otherSiblings` "Other siblings"; `conclusions.family.group.childrenOf` "Children of %@", `.thisPersonSiblingsAndParents` "This person, siblings and parents", `.thisPersonAndParents` "This person and parents".

Removed: the keys in **Deletes**. `familyThisPerson`'s comment becomes "the person's group with no parents and no siblings"; `familyCaptionSiblings`' "no parents recorded".

## 7. Steps

**STEP-1 — One table of life-line copy.**
Files: `macos/App/Platform/L10n.swift`, `macos/App/Resources/Localizable.xcstrings`, `macos/App/Platform/PersonLifeDisplay.swift`. Skill: `add-localized-string`.
Do: `L10n.LifeLine` with birth and death (marriage in STEP-3); `lifeLine(_:date:place:extraPlaces:missing:partner:)` (D-3); `lifeLines` calls it with `L10n.LifeLine.birth` and `.death`; the person-line keys of **Deletes** go.
Check: `xcodebuild test -project macos/Provenencia.xcodeproj -scheme Provenencia -destination 'platform=macOS' -only-testing:ProvenenciaTests/PersonDetailTests` passes unchanged (T-1); `python3 scripts/check-localizable-xcstrings.py` passes.

**STEP-2 — The parity row.**
Files: `api/ffi/swift_vocabulary_test.go`.
Do: T-2's subtest: read `swiftFuncBody(t, swiftL10n, "static func copy(eventTypeKey")`, collect `lifeLineCase` (`case SeededEventTypeTerm\.(\w+): return`) names, map them to keys through `swiftNamedKey` over `swiftEnumBody(t, swiftVocabulary, "SeededEventTypeTerm")`, and fail for each `string(k)` of `kinship.SpouseEventTypes()` it lacks. STEP-1 has no marriage case yet, so add the marriage `Copy` here with its keys (STEP-3 uses it).
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/ffi/ -run TestSwiftVocabularyMatchesGo` passes; with the marriage case removed it fails (run once, restore).

**STEP-3 — A marriage is a life line.**
Files: `macos/App/Platform/EventSecondaryDisplay.swift` *(new, moved)*, `EventsListView.swift`, `L10n.swift`, `Localizable.xcstrings`, `ReconciledValueDisplay.swift`, `SourceTypeCopyModel.swift`, `CatalogSearchHitPresentation.swift`, `PersonLifeDisplay.swift`, `PVDatePlaceLine.swift`, `macos/App/DesignSystem/README.md`, `macos/ProvenenciaTests/PersonLifeDisplayTests.swift` *(new)*. Skills: `add-ui-component`, `add-localized-string`, `add-swift-test`.
Do: D-16; `L10n.list(_ parts: [String], locale: Locale = .autoupdatingCurrent) -> String` (a `ListFormatter` with that locale, `?? parts.joined(separator: ", ")`) and its three callers; `LifeLine.trailing`, `eventLine`, `PVDatePlaceLine.trailing` and its preview (D-4, §6 **macOS**).
Check: `-only-testing:ProvenenciaTests/PersonLifeDisplayTests -only-testing:ProvenenciaTests/PersonDetailTests` passes (T-1, T-3); the full `xcodebuild test` passes.

**STEP-4 — Family draws the sibling groups.**
Files: `PersonFamilyContent.swift`, `PersonFamilyLayout.swift`, `PersonFamilySection.swift`, `PersonFamilyPreviewData.swift`, `PersonTimelinePreviewData.swift`, `L10n.swift`, `Localizable.xcstrings`, `PersonFamilyContentTests.swift`, `PersonFamilyLayoutTests.swift`. Skills: `add-ui-component`, `add-localized-string`, `add-swift-test`.
Do: D-6 – D-8, D-10, D-11 without lines; the fixtures F1 – F4, F6, 11h and their previews; `eventSummary` and `When.about` split out; the caption and label keys; `familyCaptionOtherParent(s)` deleted.
Check: `-only-testing:ProvenenciaTests/PersonFamilyContentTests -only-testing:ProvenenciaTests/PersonFamilyLayoutTests` passes (T-4, T-6 – T-9); each preview renders in Xcode.

**STEP-5 — Family draws each couple's marriages.**
Files: as STEP-4.
Do: D-5, D-9; lines in the layout and the diagram (D-10, D-11); fixtures M1 – M4 and their previews.
Check: the same two suites pass with T-5, T-10, T-11; each M preview renders.

**STEP-6 — The app stops reading the old fields.**
Files: `GenealogyStore.swift`, `GoStore.swift`, `macos/ProvenenciaTests/*` that construct them.
Do: delete `originSiblings`, `CatalogOriginSibling`, `Kind.parents`, `.siblings`; `mapFamilyUnit` returns nil for the generated `.parents` and `.siblings`; `CatalogPersonFamily`'s doc comment names the partner units, the one-parent unit, the sibling groups and the couples.
Check: `rg -n "originSiblings|CatalogOriginSibling|kind: \.parents|kind: \.siblings" macos --glob '!**/Generated/**'` finds nothing; the full `xcodebuild test` passes.

**STEP-7 — The Family read sends no origin siblings.**
Files: `core/database/persondetail/family.go`, `family_test.go`, `family_drop_test.go`, `caps_test.go`, `family_query_test.go`, `api/ffi/handlers/person_detail.go`, `person_detail_test.go`. Skill: `add-ffi-handler`.
Do: D-12, D-14; delete `OriginSibling`, `originSiblings`, `TestPersonFamilyOriginSiblings`; the handler drops its origin-siblings loop (the proto field stays unset until STEP-9); T-16, T-17.
Check: `rg -n "PersonFamily\(|persondetail.Families\(|kinship.FamilyUnits\(" core api --glob '*.go'` lists only the callers §4 names; `CGO_ENABLED=1 go test -tags fts5 ./core/database/persondetail/... ./api/ffi/...` passes.

**STEP-8 — Kinship makes no parent-set units.**
Files: `core/kinship/families.go`, `siblings.go`, `kinship.go`, `families_test.go`, `siblings_test.go`, `core/database/persondetail/family.go`, `family_test.go`, `api/ffi/handlers/person_detail.go`. Skill: `add-match-rule`.
Do: D-13's kinship half and **Deletes**' kinship lines; `familyUnitKindProto` loses its two cases; `persondetail`'s `unitKind` map loses two; T-12 – T-15.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/kinship/... ./core/database/persondetail/... ./api/ffi/...` passes; `CGO_ENABLED=1 go test -tags fts5 -run '^$' -fuzz FuzzFamilyUnits -fuzztime 30s ./core/kinship/` finds nothing.

**STEP-9 — The wire drops the old fields.**
Files: `api/proto/engine.proto`, `api/proto/engine/engine.pb.go`, `macos/App/Platform/Generated/engine.pb.swift`, `GoStore.swift`.
Do: D-13's proto half; `./scripts/generate-proto.sh`; `mapFamilyUnit` loses the two cases the regeneration removed.
Check: `rg -n "UnitParents|UnitSiblings|parentUnits|OriginSibling|UnitCouples|origin_siblings|originSiblings" core api macos --glob '!*.pb.go' --glob '!**/Generated/**'` finds nothing; `scripts/check-pr.sh` prints `check-pr: PASS`.

**STEP-10 — Docs.**
Files: `.agents/skills/add-match-rule/SKILL.md` (the `core/kinship` paragraph: "with more parents than `Rules.MaxPivotEnd`, `FamilyUnits` pairs none and places each sibling once" → "`Couples` pairs no parents"), `docs/deployment-plan/spike-16/deployment-plan.md` (caps list "the bound `parentUnits` already uses" → "`pairsParents`"; map row), `docs/deployment-plan/spike-16/person-page-audit.md` (line 107, the same), `docs/ideas/person-page-performance.md` (the P-8 sentence: siblings ship as the groups' children; `origin_siblings` is gone), `docs/macos-client-patterns.md` (one accessibility line: a drawn diagram orders VoiceOver with `accessibilitySortPriority` from one ordered list, as `PersonFamilyLayout.Group.items`), `docs/deployment-plan/spike-16/completed.md`, this plan, `docs/deployment-plan/spike-16/design/` (the brief and its `.review.md` → `design/archive/`; the `design/README.md` row moves).
Do: per the Definition of done.
Check: `python3 scripts/check-plan-docs.py docs/deployment-plan/spike-16/prs/S16-81-family-groups-and-marriages.md` and `scripts/check-guidance-names.py` pass; `rg -n "parentUnits|origin_siblings|OriginSibling" docs .agents .cursor --glob '!docs/deployment-plan/spike-16/prs/**' --glob '!docs/deployment-plan/archive/**'` finds nothing.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Swift | `PersonDetailTests.swift` `lifeLinesOmitMissingHalves`, `lifeLinesSayUnknownUntilLifeEventsArrive`, the `extraPlaces` expectations | Unchanged: "born 3 May 1790, Bremen", "died 1851", "Born date unknown, place unknown", `["b.", "d."]` | AC-3.3, D-2, D-3 |
| T-2 | Go | `api/ffi/swift_vocabulary_test.go` `TestSwiftVocabularyMatchesGo` "every spouse event type has life-line copy" *(new)* | Today's L10n → pass; a spouse type with no case → an error naming it | AC-3.2 |
| T-3 | Swift | `PersonLifeDisplayTests.swift` `eventLineWordsAndSpeaksAMarriage` *(new)* | en_US. 12 Jun 1841 at Hamburg → abbreviation "m.", text "m. 12 Jun 1841 · Hamburg", label "married 12 Jun 1841, Hamburg"; place only → "married in Altona"; date only → "married 12 Jun 1841"; neither → a line, text "m.", label "married"; partner Heinrich Weber with abt 1816 at Kiel → text "m. abt 1816 · Kiel, with Heinrich Weber", label "married abt 1816, Kiel, with Heinrich Weber"; type `burial`, or origin "user" → nil. `L10n.list(["A", "B"], locale: en)` → "A and B" | AC-2.3, AC-2.7, D-2, D-3, D-4 |
| T-4 | Swift | `PersonFamilyContentTests.swift` `siblingGroupsFromFamily` *(replaces `columnsFromFamily`)* | F1 → parent names `[["Heinrich Weber","Anna Weber"],["Anna Weber"]]`, children `[["Margarethe Weber","Johann Weber","Friedrich Weber","Wilhelm Weber"],["Christian Weber"]]`, Johann the focus with no location; all tile ids unique (`l-g0-anna`, `l-g1-anna`); F2, F3, F4, F6, 11h → the groups of AC-1.2 – AC-1.6; right column as today | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, D-6 |
| T-5 | Swift | `PersonFamilyContentTests.swift` `badCoupleIndexesDrawNothing` *(new)* | A group with `coupleIndexes: [7]`, and one whose couple's B is not among its parents → no marriages, no crash | D-9 |
| T-6 | Swift | `PersonFamilyContentTests.swift` `captionsAndGroupLabels` *(rewritten)* | F1 captions `["Parents","Shared parent"]`, labels `["This person, siblings and parents","Children of Anna Weber"]`; F2 `["Parents","Shared parents","Shared parents"]` and AC-1.2's labels; F3 AC-1.3's; F4 group 0 "This person and parents", last "Other siblings" / OTHER SIBLINGS; F6 `["Siblings"]`, "This person and siblings"; 11h no caption, "This person"; one parent in group 0 → "Parent"; right-column cases as today | AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, D-8 |
| T-7 | Swift | `PersonFamilyContentTests.swift` `foldsEachListAtThirty`, `expandedShowsAll`, `foldKeepsTheFocus`, `childrenAndSiblingsPage`, `anchorResolvesToTheTileOrItsFold` *(rewritten)*; `foldDropsHiddenSetIndexes` deleted | 20 + 20 → 30 shown, `siblingsHidden` 10, group 1 drawn with Anna; 30 + 5 → group 1 not drawn, `firstRevealed(by: .siblings)` = `l-g1-anna`; the person 40th of 130 in group 0 → today's expectations with `l-g0-` ids; `l-p0-anna`, `l-s-margarethe` → nil; a hidden group's parent → `more.siblings`; partner and children folds as today | AC-1.8, AC-1.9, AC-1.10, D-7 |
| T-8 | Swift | `PersonFamilyLayoutTests.swift` `regularAndWideMeasures` *(rewritten)* | F1 at 1038 Regular: column 485, right x 553, bus x 521; Heinrich (20, 26), Anna y 130, Margarethe (52, 234) width 453, Wilhelm y 546; line x 10 from y 72 to 592; group 1 caption y 658, its Anna y 684, Christian y 788, its line 730 to 834. At 1180 Regular and Wide: every tile's y the same, columns 556 and 532 | AC-1.1, D-10 |
| T-9 | Swift | `PersonFamilyLayoutTests.swift` `noLineLeavesItsGroup` *(replaces `parentSetRails`)*; `siblingsOnlyAndTheFocusAlone`, `fiftySiblingsStack`, `fiftySiblingsFolded` *(rewritten)* | F2, F3, F4: every vertical segment at x 10 lies inside its group's frame; no two groups' frames intersect; F4 Elisabeth at x 20, no segment at her centre; F6 Clara (20, 26) with a line at x 10; 11h focus (20, 26); 49 siblings in one two-parent group → 52 tiles, no overlap, height 26 + 52 × 104 − 12; folded → 31 children and one more row, no line reaches it; each group's `items` are parents, then children, then the more row | AC-1.4, AC-1.5, AC-1.6, AC-1.7, D-10, D-11 |
| T-10 | Swift | `PersonFamilyLayoutTests.swift` `marriageLinesSitBetweenTheCouple` *(new)* | M1: the line (20, 124, 485 × 21), Anna y 151, Margarethe y 255; Maria's line (553, 26, 485 × 21), Maria's tile y 51. M3: Maria y 72. M4 group 0: Heinrich–Anna's line between Heinrich and Anna, Heinrich–Katharina's below Katharina; in `items`, each line follows its j parent (Anna, then Katharina). Wide at 1180: the same y | AC-2.1, AC-2.4, AC-2.5, D-10, D-11 |
| T-11 | Swift | `PersonFamilyContentTests.swift` `marriagesOfEachCouple` *(new)* | M1 group 0 one line, label "Heinrich Weber and Anna Weber, married 3 May 1812, Altona", `drawnAfter` 0, `spokenAfter` 1; Maria's group one line, label "Johann Weber and Maria Schulz, married 12 Jun 1841, Hamburg"; Sophie none. M2 labels end "married in Altona", "married 12 Jun 1841", "married". M3 two lines in engine order. M4 group 0: labels "married 3 May 1812, Altona, with Heinrich Weber" (`drawnAfter` 0, `spokenAfter` 1) and "married abt 1816, Kiel, with Heinrich Weber" (`drawnAfter` 2, `spokenAfter` 2); groups 1, 2 unnamed. M5: 31 partners, Maria and partner 31 married → 30 groups, partner 31's line absent until one page. M1 with `person` nil → Maria's line label "married 12 Jun 1841, Hamburg" | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, D-5, D-9 |
| T-12 | Go | `core/kinship/families_test.go` `TestSiblingGroupsGrowth` *(new; replaces `TestFamiliesMoreParentsThanMaxPivotEnd`, `TestFamiliesGrowth`, `TestFamiliesGrowthPairs`)* | For `crowd(t, n, 2n)`, n ∈ {11, 22}, and `pairs(t, p, 3)`, p ∈ {11, 14}: kin = `KinOf(pat, linksPastSiblingBound(t, pat, edges), terms, rules)`, groups = `SiblingGroups(pat, kin)` → total children = `len(kin[RoleSibling]) + 1`; `len(groups)` ≤ that; total parents ≤ `len(groups) × len(kin[RoleParent])` | D-15 |
| T-13 | Go | `families_test.go` `FuzzFamilyUnits` *(changed)* | `placements(FamilyUnits(…))` ≤ `(len(kin[RoleChild]) + 1) × (len(edges) + 1) + len(kin[RoleSpouse])`; total children of `SiblingGroups(p(1), kin)` = `len(kin[RoleSibling]) + 1` | D-15 |
| T-14 | Go | `families_test.go` `TestFamilies`, `TestUnitEmpty`, helpers `unitName`, `show` *(trimmed)* | Deleted rows: "AC-1.2", "AC-1.3 with a spouse link", "AC-1.3 without it", "AC-1.5", "AC-1.6", "a parent not shown, a sibling only through them", "a birth with two fathers and a mother", "ten recorded parents with no pairing evidence", the subtest "over the bound a sibling sharing several parents sits with the first"; changed: "AC-1.10" → `["Partner{6;}"]`, "AC-1.11" → no units, "siblings unit comes last" renamed "the one-parent unit comes last" → `["Partner{2;}", "OneParent{;14}"]`; "links say why" finds Quin and Rae among `SiblingGroups`' children (Quin `shared_parent/16`, `shared_parent/17`; Rae `shared_parent/17`); `TestUnitEmpty` loses its UnitParents and UnitSiblings rows | D-13 |
| T-15 | Go | `siblings_test.go` "50,000 parents and a sibling sharing them all" *(changed)* | Also calls `SiblingGroups` and `Couples`; all within one second | D-15 |
| T-16 | Go | `core/database/persondetail/family_test.go` `TestPersonFamily` AC-1.2 (no units), AC-1.5 (Quin and Rae from `f.Groups`), "AC-2.8 …" (reads `u.Couples`); `family_drop_test.go` `TestDropUnread` *(rewritten)*: partner 2 with child 4, partner 5 with child 6, one-parent 7; read 3, 4, 5, 6 → one unit, partner 5; read 3, 4, 6 → none | D-12, D-14 |
| T-17 | Go | `api/ffi/handlers/person_detail_test.go` "carries the person and the sibling group" *(renamed)* | Group 0 children are the sibling (a link) and the person (no link); parents the father and mother; the partner unit as today | AC-3.1 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestPersonFamilyGroups`, `TestCraftedFamily`, `TestCraftedMarriages`, `TestPersonFamilyQueryCount`, `CatalogQueryRegistryTests`, `WorkspaceSessionTests` (they construct `CatalogPersonFamily`), `PersonTimelineContentTests` (the split fixture).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/` and `L10n.swift` with no hit left outside plans and archives; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — or none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated)
- [ ] Domain doc updated if a rule in docs/*.md changed: macos-client-patterns.md's accessibility line; add-match-rule's kinship paragraph (STEP-10)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

1. Build and run the app; open a project with brief §5's family: Johann Weber b. 1817 with a birth event naming Heinrich and Anna as father and mother; Margarethe 1815, Friedrich 1820 and Wilhelm with births naming both; Christian 1823 recorded as Anna's son only (a parent relationship). Open Johann's Family. See PARENTS with Heinrich and Anna, the four indented, then SHARED PARENT with Anna and Christian; no crossing lines (bar 50).
2. Add a marriage event on 12 Jun 1841 at Hamburg with Johann and Maria Schulz as subjects, and one on 3 May 1812 at Altona with Heinrich and Anna. See "m. 3 May 1812 · Altona" between Heinrich and Anna and "m. 12 Jun 1841 · Hamburg" over Maria; a partner with no marriage event shows none (bar 51).
3. Turn on VoiceOver: the groups are "This person, siblings and parents" and "Children of Anna Weber"; after Anna, "Heinrich Weber and Anna Weber, married 3 May 1812, Altona"; Tab skips the marriage lines.
4. Stretch the window past a 1600 pt pane: the same arrangement, wider columns.
5. Add Katharina as Johann's third parent and marry her to Heinrich (abt 1816, Kiel): see the three-parent group's named lines, spoken "married abt 1816, Kiel, with Heinrich Weber" after Katharina.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| `accessibilitySortPriority` does not order a contained group on macOS | Manual check 3; T-9, T-10 hold the layout's order |
| The generated Swift drops `.parents`/`.siblings` | STEP-6 maps them to nil before STEP-9 removes them |

**Stop and report if:**

- `CatalogPersonFamily.siblingGroups`, `couples` or `coupleIndexes` differ from §4 (S16-82's shape changed).
- VoiceOver reads a two-parent marriage line before the second parent with `accessibilitySortPriority` applied (D-11 cannot work).
- STEP-7's `rg` lists a caller of `PersonFamily`, `Families` or `FamilyUnits` that §4 does not name.
- A brief frame and an AC here disagree.
- `swiftFuncBody` cannot read `static func copy(eventTypeKey` (T-2).
- `PersonTimelinePreviewData.event`'s output changes when it calls `eventSummary` (a Timeline test fails).

## 12. Open questions

None.

## 13. PR

**Title:** S16-81 — Family groups siblings by their parents and shows each couple's marriage
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-16/prs/S16-81-family-groups-and-marriages.md`.
