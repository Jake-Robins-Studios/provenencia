# S16-82 — The Family read sends sibling groups and each couple's marriages

**Status:** Landed in [#1009](https://github.com/Jake-Robins-Studios/provenencia/pull/1009) (2026-11-27)
**Landed:** As planned, except: T-9 is a new test, `TestDropUnreadGroupsAndCouples`, beside `TestDropUnread` rather than an extension of its literal; `spouseLink` calls a small `filedSpouseLink` (one spouse link a person files to another), since `core/kinship` may hold no literal number (`TestLayerPackages`).
**Spike / slice:** Spike 16 · Slice 6l — Family parents
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: the engine sends new fields that nothing draws until S16-81)
**Board:** —
**Depends on:** —
**Blocks:** S16-81
**Branch:** `s16-82-family-groups-and-marriages-read`
**Version bump:** none — no change a researcher can see; the wire change ships inside the one app binary ([`docs/versioning.md`](../../../versioning.md))
**Skills to load:** [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`add-match-rule`](../../../../.agents/skills/add-match-rule/SKILL.md) (the `core/kinship` page functions section)
**Rules that bind:** `.cursor/rules/go-tests.mdc`, `.cursor/rules/match-rules.mdc`
**Context:** brief [S16-D18](../design/S16-D18-family-groups-and-marriages.md) (agreed 2026-11-27: the frames this read must serve), working rules "(Batch 6) Family groups siblings by their parents", "(Batch 6) Family shows a couple's marriage from its events", "(Batch 1) Crafted fan-out is capped, not engineered"
**Planned:** 2026-11-27 against `main` @ `c103545`
**Review:** [`S16-82-family-groups-and-marriages-read.review.md`](S16-82-family-groups-and-marriages-read.review.md) — Fits with changes, Ready; 2 rounds, every finding answered

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

The Family read sends the person's siblings grouped by the parents they share with the person, and the marriages of every couple the page shows, so S16-81 can draw the agreed S16-D18 board without working out kinship in Swift. Each sibling, the person among them, is in exactly one group: siblings recorded with exactly the same of the person's parents are one group. Each couple (the person and a partner, or two of the person's parents) carries the marriage events both are subjects of, earliest first.

**Why now.** S16-81's board is agreed (2026-11-27) and its drawing reads both; the engine half has nothing to draw, so it lands first and on its own (user, 2026-11-26).

**What stays.** Every field the response sends today (`units`, `person`, `origin_siblings`, `inputs`) and the app's Family section, which still draws from them. S16-81 switches the drawing and deletes what it leaves unread.

## 2. User stories

**US-1.** As the engine, when the Family read runs for a person, I send the person's siblings in groups by shared parentage, in the page's order, so the page draws them as they are.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | Johann's parents Heinrich and Anna (married, so one pair); Margarethe, Friedrich and Wilhelm children of both; Christian Anna's child only (brief frame F1) | Two groups: {Heinrich, Anna} with Margarethe, Johann, Friedrich, Wilhelm (birth order, Wilhelm undated last); {Anna} with Christian |
| AC-1.2 | Johann's parents recorded as Heinrich, Anna and Katharina; Friedrich a child of all three; Margarethe and Wilhelm of Heinrich and Anna; Christian of Heinrich and Katharina (F2) | {Heinrich, Anna, Katharina} with Johann, Friedrich; {Heinrich, Anna} with Margarethe, Wilhelm; {Heinrich, Katharina} with Christian |
| AC-1.3 | Johann's parents Heinrich and Anna; Wilhelm Heinrich's only; Christian Anna's only (F3) | {Heinrich, Anna} …; {Heinrich} with Wilhelm; {Anna} with Christian (more parents first, then the person's parent order) |
| AC-1.4 | Johann's parents recorded as Heinrich, Anna, Georg Becker and Katharina Becker (Heinrich–Anna married, Georg–Katharina married); Margarethe and Friedrich children of Heinrich and Anna; Christian of Georg and Katharina; Elisabeth recorded as Johann's sister with no shared parent (F4) | Four groups in order: {Heinrich, Anna, Georg, Katharina} with Johann; {Heinrich, Anna} with Margarethe, Friedrich; {Georg, Katharina} with Christian; {} with Elisabeth |
| AC-1.5 | Johann has no parents; Clara and Karl recorded as his siblings (F6) | One group, no parents: Clara, Johann, Karl in birth order |
| AC-1.6 | Johann has no parents and no siblings | One group: Johann alone |

**US-2.** As the engine, I send each couple the page shows with its marriages, so the page draws "m. 12 Jun 1841 · Hamburg" without looking for events.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Johann and Maria are subjects of a marriage dated 12 Jun 1841 | A couple {Johann, Maria} with that marriage's event summary |
| AC-2.2 | Heinrich and Anna, Johann's parents, are subjects of a marriage | A couple {Heinrich, Anna} with its summary |
| AC-2.3 | Johann and Sophie are partners through a child only, or linked as spouses with no marriage event | No couple for them |
| AC-2.4 | Johann and Maria have two marriages, 1841 and one undated | One couple, the 1841 marriage first, the undated one second |
| AC-2.8 | Brief frame F2's family, Heinrich–Anna and Heinrich–Katharina married; Johann has partners Maria (married) and Sophie (not) | The group {Heinrich, Anna, Katharina} names both couples; {Heinrich, Anna} names the first, {Heinrich, Katharina} the second; Maria's partner unit names the Johann–Maria couple; Sophie's names none |
| AC-2.5 | A couple has 200 marriage events (crafted) | The couple carries 10: the first 10 pivots in shape order (D-6), sent in list order (D-7); the read stays within the timing budget |
| AC-2.6 | One of a couple's marriage events is merged away before the read | It is not sent; a couple left with none is not sent |
| AC-2.7 | A warm second read; then the marriage's date is edited and committed | The warm read issues no graph query and records the same inputs; after the edit, the read's inputs name the event and the couple's marriage carries the new date |

## 3. Scope

| In | Covered by |
| --- | --- |
| `kinship.SiblingGroups` and `kinship.Couples`, page-only, beside `FamilyUnits` | STEP-1, STEP-2, AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-2.1, AC-2.2, AC-2.3, AC-2.4 |
| `kinship.SpouseEventTypes()` and `Pattern.ImpliesSpouse()`, derived from `eventPatterns` | STEP-1, AC-2.1 |
| `persondetail.Family` carries the groups and couples; `PersonFamily` reads the marriages, caps, orders, drops unread and indexes each group's and partner's couples | STEP-3, STEP-4, STEP-5, AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-2.5, AC-2.6, AC-2.7 |
| Proto `SiblingGroup` (with `couple_indexes`), `FamilyCouple`, `FamilyUnit.couple_indexes`, `GetPersonFamilyResponse.sibling_groups` and `.couples`; handler mapping | STEP-6, STEP-7, AC-2.8 |
| Swift: `CatalogSiblingGroup`, `CatalogFamilyCouple`, `CatalogFamilyUnit.coupleIndexes`, `CatalogPersonFamily.siblingGroups` and `.couples`; `GoStore` maps them; nothing draws them | STEP-8 |
| Docs and guidance the PR changes: the working rules' caps list, `matching-model.md`, the `kinship` package doc, `add-match-rule`, `docs/ideas/kinship-view.md` | STEP-9 |

| Out | Home |
| --- | --- |
| Drawing the groups and the marriage lines | S16-81 |
| Deleting `origin_siblings`, `parent_sets`, the `OriginSibling` proto, `persondetail.OriginSibling` and `originSiblings` (and `PersonFamily`'s `[]OriginSibling` return), `parentUnits` with `paired`, `subset` and its extra sets, `UnitParents`, `UnitSiblings` and their `familyUnitKindProto` cases, `CatalogOriginSibling`, `TestPersonFamilyOriginSiblings` | S16-81, which removes their last reader, today's drawing; the map's S16-81 row and scope entry list them (user, 2026-11-27) |
| The life-line words table and its parity test row | S16-81 |
| A co-parent known only through a child carrying a marriage | Not planned: no spouse link, so no pivot (working rule: a spouse link with no marriage event shows nothing) |
| Siblings' or children's marriages; any event but the spouse-implying patterns' | Not planned (brief §2.1) |
| A sibling's own parents who are not the person's | Not planned (brief, "A sibling's parents") |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Family read | `core/database/persondetail/family.go` `Families`, `PersonFamily`, `Family` | Builds `kinship.FamilyUnits` per person; `aroundKin` (the kin of the person's parents and children) is computed and dropped after `FamilyUnits` |
| Origin siblings | `family.go` `originSiblings`, `OriginSibling` | Lists siblings once with `ParentSets` indexes into the parents units, ordered for the stacked layout; no shared-parent set is sent |
| Unread drop | `family.go` `dropUnread` | Drops unread relatives from units and empty units |
| Parent sets | `core/kinship/families.go` `parentUnits` | Works out each sibling's `shared` parents (indexes into the person's parents, from `PatternSharedParent` shapes) inline in its loop |
| Patterns | `core/kinship/patterns.go` `eventPatterns`, `Patterns` | `marriage_spouses` on `vocabkey.EventMarriage` with term `TermSpouse`; no accessor names the spouse-implying patterns |
| Link shapes | `core/kinship/kinship.go` `Shape`, `Recording`; `links.go` `Link` | A spouse link carries one `Shape{PatternMarriageSpouses, Pivot: marriage event id}` per marriage |
| Event summaries | `core/database/conclusionsummaries/compose.go` `EventsByIDs`, `PersonsByIDs`, `NewSummaries`, `ByIDs` | `EventsByIDs` returns rows in list order (dated first, earliest first, then ref) |
| Event inputs precedent | `core/database/persondetail/timeline.go` `PersonEvents` | `in.Nodes(ids)`, then `in.Cached(id).Canonical(eventType)` records each event node and keeps canonical events |
| Handler | `api/ffi/handlers/person_detail.go` `GetPersonFamily`, `familyMemberProto`; `conclusion_summaries.go` `eventSummaryProto` | Maps units, person, origin siblings, inputs |
| Proto | `api/proto/engine.proto` `GetPersonFamilyResponse` (fields 1–4), `FamilyUnit`, `FamilyMember`, `OriginSibling`, `EventSummary` | No groups, no marriages |
| Swift | `macos/App/Platform/GenealogyStore.swift` `CatalogPersonFamily`, `CatalogOriginSibling`; `GoStore.swift` `getPersonFamily` (≈ line 1570), `mapFamilyMember`, `mapEventSummary` | Maps today's fields |
| Tests | `core/kinship/families_test.go` `TestFamilies`; `core/database/persondetail/family_test.go` `TestPersonFamily`, `TestPersonFamilyOriginSiblings`, `TestPersonFamilyRecordsInputs`; `family_query_test.go` `TestPersonFamilyQueryCount`; `family_drop_test.go` `TestDropUnread`; `caps_test.go` `TestCraftedFamily`; `api/ffi/handlers/person_detail_test.go` `TestGetPersonFamily` | Cover units and origin siblings |
| Test world | `core/database/graphcache/graphcachetest/graphcachetest.go` `Canon.Marriage`, `Birth`, `Parent`, `Relationship`, `Date`, `Merge` | Builds every family the ACs need |

**Precedent.** S13-04's origin siblings (`originSiblings`, `OriginSibling.parent_sets`, `CatalogOriginSibling`) added a page-only grouping to this same read, response and Swift mapping: copy its shape (kinship computes, `persondetail` orders by birth and drops unread, the handler maps, `GoStore` maps). `PersonEvents` is the precedent for reading event nodes and summaries with inputs recorded.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | The grouping is a `core/kinship` page function beside `FamilyUnits`; `persondetail` orders and drops; Swift regroups nothing | Kinship owns family shape (working rule); one tested place | Grouping in Swift from `parent_sets` — a kinship rule in the client |
| D-2 | A sibling's signature is its shared parents: the indexes, in the person's parent order, of the person's parents its link carries a `PatternSharedParent` shape through. `parentUnits` and `SiblingGroups` read it through one helper, `sharedParents` | The one definition of "shares a parent" stays in one place | A second inline copy |
| D-3 | The person's signature is every one of the person's parents, so the person's group is the group of that signature; it is always first, even with no parents (then it holds every sibling with no shared parent too). Other groups follow by signature length, longest first, then by the signature's indexes compared in order; the empty signature, when it is not the person's, is last | Matches the agreed board's order (F1–F6) with no special case for "no parents" | A separate flag for the person's group |
| D-4 | A group's parents are `Relative`s from the person's own parent links (so each carries the person's link); its children are `Relative`s from the person's sibling links in link order, and in the person's group the person is appended last as `Relative{ID: person}` with a nil link, as `originSiblings` adds it (`persondetail` sorts by birth) | Same members the units send today | — |
| D-5 | A couple is the person with each spouse in `kin[RoleSpouse]` (deduplicated by the spouse's id, first link wins), then each two of the person's parents (`i < j`, in parent order) that `spouseLink` finds joined, only when `pairsParents` allows for the person's parent count. A pair is skipped when either end is the person. A partner couple's marriages come from the person's own `kin[RoleSpouse]` link; a parent pair's from the link `spouseLink` returns (A's link to B if A files one, else B's), since the person and a partner are never keys of `kinOf`. Marriages are the distinct pivots, in shape order, of the shapes whose pattern `ImpliesSpouse`. Only couples with at least one pivot are returned. For a partner, A is the person; for parents, A is the earlier in parent order | The spouse-implying patterns are the rule (working rule); the shapes already name the events | Reading marriage events by walking each person's events — a second way to find them |
| D-6 | At most `maxMarriagesPerCouple = 10` pivots per couple are read: the first 10 in shape order, before any node or summary is loaded; a package constant in `persondetail` with `// decided: user, 2026-11-08` (rule "Crafted fan-out is capped, not engineered"); the rule's caps list gains it (STEP-9) | The cap sits beside the read it bounds; `persondetail` is not a matching package; real data has one to three | A `kinship.Rules` knob — the cap is the page read's, not kinship's |
| D-7 | `PersonFamily` replaces its `ByIDs` call: it gets the event type id from `c.Graph().Vocabulary()` `TypeIDsByKey()[vocabkey.Event]`, loads the capped pivots with `in.Nodes`, keeps those `in.Cached(id).Canonical(eventType)` accepts, reads them with `EventsByIDs` (list order) and the wanted persons with `PersonsByIDs`, and builds the summaries with `NewSummaries(persons, events, nil)`. Each couple's `Marriages` are its kept events in `EventsByIDs`' order. Its signature stays `(Family, []OriginSibling, Summaries, error)` | Records inputs as `PersonEvents` does; list order is the one date order | `ByIDs` — its map loses the order |
| D-8 | `dropUnread` also drops unread group members, unread couples and unread marriages. The first group is never dropped, even with the person unread; another group left with no child is dropped, and two groups left with the same parents stay apart (their signatures differ). A couple whose either person, or every marriage, is unread is dropped. Couple indexes (D-11) are computed after the drop | One drop rule for every part the read sends | — |
| D-9 | The response sends both alongside today's fields (`sibling_groups = 5`, `couples = 6`); a couple names its two people by entity id string (`database.UUIDString`) and carries `EventSummary`s through `eventSummaryProto` | Additive: the app keeps drawing from today's fields until S16-81 | Couples nested in groups and partner units — two places for one fact |
| D-10 | `kinship.SpouseEventTypes()` lists the event types of the patterns whose term is `TermSpouse`, in `eventPatterns` order; `Pattern.ImpliesSpouse()` is true for those patterns' codes. Both read `eventPatterns`; nothing else lists marriage | One registry; S16-81's parity test reads `SpouseEventTypes` | A hard-coded `PatternMarriageSpouses` check |
| D-11 | Each group and each partner unit names its couples by index into `couples`, so Swift matches nothing: a group's couples are those whose two people are both its parents, in `couples` order; a partner unit's is the couple of the person and its partner. One unexported `indexCouples(*Family)` *(new)* fills `Group.Couples` and `Family.UnitCouples` (parallel to `Units`); `Families` calls it last, and `PersonFamily` calls it again after the drop, so `Families` and `PersonFamily` return the same shape | The engine sends the decision (lens trap "a client decision keyed to engine values") | Swift searching couples by id pair; indexes only in `PersonFamily`, which breaks `TestPersonFamily` AC-1.14's equality of the two |
| D-12 | `persondetail.Family.Couples` holds a page type, `FamilyCouple{A, B []byte; Marriages [][]byte}`, built from `kinship.Couple`; `kinship.Couple.Pivots` keeps meaning the uncapped pivots in shape order | One name per meaning across layers | Reusing `kinship.Couple` with `Pivots` rewritten |
| D-13 | Which two parents are spouses is one rule: `spouseLink` and `pairsParents` are extracted from `parentUnits` (its `files` closure and `pairing` bound) and called by both `parentUnits` and `Couples` | `Couples` must not re-derive pairing beside `parentUnits` | A second spouse check in `Couples` |

**Rules this plan bends.** (1) The map's S16-81 row says "no Go or proto change beyond one parity test row", and the working rule "(Batch 6) Family groups siblings by their parents" and S16-82's scope say this PR replaces `origin_siblings`. This plan keeps S16-82 additive and gives the Go, proto and Swift-mapping deletions to S16-81, so S16-81 gains a Go and proto removal. → The old fields' only reader is today's drawing, which S16-81 rewrites; replacing them here would mean adapting a drawing that S16-81 then throws away. → User's answer: S16-81 deletes them (2026-11-27). → Done in planning: the map rows, both scope entries and the working rule say so. (2) The working rule named `persondetail` as where the engine groups; D-1 puts the grouping in `core/kinship` beside `FamilyUnits`, with `persondetail` ordering. → The user decided the engine groups (2026-11-27); the package was the writer's wording in the rule. → Done in planning: the rule names `core/kinship`; the user can veto (report, 2026-11-27).

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `kinship.SiblingGroup`, `SiblingGroups(person []byte, kin Kin) []SiblingGroup` *(new)* | type, func | `kinship.FamilyUnits`, `Unit` | Units group by parent *sets* (pairs and extras); groups are by exact shared parentage. A `Unit` kind would mix two orders in one list |
| `kinship.Couple`, `Couples(person []byte, kin Kin, kinOf map[string]Kin, rules Rules) []Couple` *(new)* | type, func | `partnerUnits` | Partner units hold children, not pivots, and know nothing of the parents' pair |
| `kinship.spouseLink`, `kinship.pairsParents` *(new, unexported)* | func | `parentUnits`' `files` closure and `pairing` | Extracted, not copied (D-13) |
| `persondetail.FamilyCouple`, `persondetail.Group`, `Family.UnitCouples`, `indexCouples` *(new)* | types, field, func | `persondetail.OriginSibling` | Page types: the read marriages and couple indexes (D-11, D-12) |
| `kinship.sharedParents` *(new, unexported)* | func | the inline loop in `parentUnits` | Extracted, not copied: `parentUnits` calls it |
| `kinship.SpouseEventTypes`, `Pattern.ImpliesSpouse` *(new)* | func, method | `Patterns`, `Pattern.PivotKind` | Same table, a new question |
| `persondetail.maxMarriagesPerCouple` *(new)* | const | `maxRecordLinkLines` (`recordlinks.go`) | The page read's own cap |
| `engine.SiblingGroup`, `engine.FamilyCouple`, `FamilyUnit.couple_indexes`, response fields 5–6 *(new)* | proto | `OriginSibling`, `FamilyUnit` | New shapes; the old ones go in S16-81 |
| `CatalogSiblingGroup`, `CatalogFamilyCouple` *(new)*; `CatalogPersonFamily.siblingGroups`, `.couples`, `CatalogFamilyUnit.coupleIndexes` *(new)* | Swift types | `CatalogOriginSibling` | As above |

**Builds on.** `canonlinks.Reader.Relationships` with `Siblings: true`, `kinship.KinOf`, `shownKin`, `conclusionsummaries.EventsByIDs`, `graphcache.PageInputs`, `familyMemberProto`, `eventSummaryProto`, `GoStore.mapFamilyMember`, `mapEventSummary`.
**Deletes.** None in this PR: the old fields keep their one reader, today's drawing, until S16-81 replaces it. S16-81 deletes them; the Out row lists every one, as do S16-81's map row and scope entry.
**Next adds.** S16-81 draws `siblingGroups` and `couples` and deletes the old fields. A union pattern added to `eventPatterns` with term `TermSpouse` reaches `Couples` and `SpouseEventTypes` with no other change. A family tree (`docs/ideas/kinship-view.md`) reads `SiblingGroups` per generation.

### Reach

| New path or state | Destination | Checked |
| --- | --- | --- |
| A person with no parents now yields a group (AC-1.5, AC-1.6) | `SiblingGroups`, `dropUnread` | The first group is kept even with no parents and only the person |
| An event summary on the Family response | `eventSummaryProto`; `GoStore.mapEventSummary` | Same mapping as the Timeline's events; a missing picture path maps to "" |
| A merged or removed marriage event | `PersonFamily` | Not canonical or no summary → not sent (AC-2.6) |

### Scale

At the map's Scale (real: 20 children in four parent sets, one or two marriages per couple; crafted: each axis 20 times past its cap): groups are linear in siblings × parents (≤ `MaxKinPerRole` each, both already capped in `KinOf`); couples are at most the person's spouses plus pairs of parents (pairs only form among ≤ `MaxPivotEnd` parents, since `Siblings` and pairing stop past it — `Couples` checks pairs only when `pairsParents` allows); marriages are read at most `maxMarriagesPerCouple` per couple, so at most (100 + 45) × 10 event nodes, all in one `Nodes` call and one `EventsByIDs` call. The read adds two batched loads, no per-couple query. `TestCraftedFamily` gains a 200-marriage couple within `capBudget`.

### Edges

- **Assumptions.** `SiblingGroups` assumes each sibling link is distinct per sibling (`KinOf` keeps one link per pair of ends, from `LinkSet`); the person is never in `kin[RoleSibling]`. `Couples` assumes a spouse link's shapes may repeat a pivot (dedup) and may hold other patterns (filtered by `ImpliesSpouse`). T-1 and T-2 hold each.
- **Neighbors.** A sibling sharing every parent → the person's group (AC-1.1). A sibling sharing every parent but one → its own group (AC-1.1's Christian). Parents linked as spouses with no marriage event → no couple (AC-2.3). Two parents paired only by a shared birth pivot, with no spouse link → no couple, since no spouse link carries a marriage (T-3).
- **Removed inputs.** A merged sibling or parent is dropped by `dropUnread` (D-8, T-4); a merged marriage event is dropped (AC-2.6). A dropped parent leaves its group's signature as computed (the group is still the siblings who share it), and the group shows its remaining parents: T-4 pins it.
- **Real data.** None — no table or seed drives the rule beyond `eventPatterns`' two rows; `SpouseEventTypes()` returns `[marriage]` (T-1).
- **Untrusted size.** Parents and siblings are capped by `KinOf` (100 each); groups ≤ siblings + 1; pairs of parents checked only at ≤ `MaxPivotEnd` (10) parents; pivots per couple capped by D-6 before `Nodes`.

### Schema

None — no catalog change.

### Go core

| Package | Change |
| --- | --- |
| `core/kinship` (`families.go`) | `type SiblingGroup struct { Parents, Children []Relative }` *(new)*; `func SiblingGroups(person []byte, kin Kin) []SiblingGroup` *(new)*; `type Couple struct { A, B []byte; Pivots [][]byte }` *(new)*; `func Couples(person []byte, kin Kin, kinOf map[string]Kin, rules Rules) []Couple` *(new)*, order per D-5: partners, then parent pairs; `func sharedParents(l Link, parentIDs [][]byte) []int`, `func spouseLink(kinOf map[string]Kin, a, b []byte) (Link, bool)`, `func pairsParents(n int, rules Rules) bool` *(new, unexported)*, all three called by `parentUnits` |
| `core/kinship` (`patterns.go`) | `func SpouseEventTypes() []vocabkey.EventType` *(new)*; `func (p Pattern) ImpliesSpouse() bool` *(new)* |
| `core/database/persondetail` (`family.go`) | `type Group struct { kinship.SiblingGroup; Couples []int }` and `type FamilyCouple struct { A, B []byte; Marriages [][]byte }` *(new)*; `Family` gains `Groups []Group`, `Couples []FamilyCouple` and `UnitCouples [][]int` (parallel to `Units`) *(new fields)*; `Families` fills `Groups` and `Couples` (each couple's `Marriages` its `Pivots`, uncapped) from `shown` and `aroundKin`, then calls `indexCouples`; `PersonFamily` caps and reads the marriages (D-6, D-7), sorts each group's children with `byBirth`, drops per D-8, then calls `indexCouples` again (D-11); `const maxMarriagesPerCouple = 10` *(new)* |

Errors: none new.

### FFI

`api/proto/engine.proto`:

```proto
// SiblingGroup is the person's siblings who share exactly the same of the
// person's parents, the person among them. The first group is the person's.
message SiblingGroup {
  repeated FamilyMember parents = 1;   // the person's parents the group shares, in the person's parent order
  repeated FamilyMember children = 2;  // birth order, undated last; the person's member has no link
  repeated int32 couple_indexes = 3;   // indexes into the response's couples: the couples among this group's parents
}

// FamilyCouple is two people the page shows together and the marriage events
// both are subjects of, earliest first.
message FamilyCouple {
  string a_entity_id = 1;
  string b_entity_id = 2;
  repeated EventSummary marriages = 3;
}

// in FamilyUnit (a PARTNER unit names its couple with the person, if married)
  repeated int32 couple_indexes = 4;

// in GetPersonFamilyResponse
  repeated SiblingGroup sibling_groups = 5;
  repeated FamilyCouple couples = 6;
```

Handler `api/ffi/handlers/person_detail.go` `GetPersonFamily` maps both. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Sibling group | `CatalogSiblingGroup { parents: [CatalogFamilyMember]; children: [CatalogFamilyMember]; coupleIndexes: [Int] }` *(new)* | `macos/App/Platform/GenealogyStore.swift` | Beside `CatalogOriginSibling` |
| Partner unit's couple | `CatalogFamilyUnit.coupleIndexes: [Int] = []` *(new)* | same | |
| Couple | `CatalogFamilyCouple { aEntityId: String; bEntityId: String; marriages: [CatalogEventSummary] }` *(new)* | same | |
| Family | `CatalogPersonFamily.siblingGroups: [CatalogSiblingGroup] = []`, `.couples: [CatalogFamilyCouple] = []` *(new)* | same | Defaults keep `FakeStore` and previews compiling |
| Mapping | `GoStore.getPersonFamily`, `mapFamilyUnit` | `macos/App/Platform/GoStore.swift` | Group members through `mapFamilyMember`, marriages through `mapEventSummary` (private static, in the same type), indexes as `Int`. `FakeStore` needs nothing: the defaults compile |

Nothing draws them. States: none.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — Spouse patterns and the shared rules in kinship**
Files: `core/kinship/patterns.go`, `core/kinship/families.go`, `core/kinship/families_test.go`. Skill: `add-match-rule`.
Do: add `SpouseEventTypes` and `ImpliesSpouse` (D-10); extract `sharedParents`, `spouseLink` and `pairsParents` from `parentUnits` and call them there (D-2, D-13).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/kinship/...` passes; `TestFamilies` unchanged and green; T-1 passes.

**STEP-2 — SiblingGroups and Couples**
Files: `core/kinship/families.go`, `core/kinship/families_test.go`.
Do: add the types and functions per D-3, D-4, D-5, with doc comments stating each order.
Check: T-2, T-3 pass.

**STEP-3 — Families carries groups and couples**
Files: `core/database/persondetail/family.go`.
Do: the new types and fields; `Families` fills `Groups` and `Couples` from `shown[id]`, `aroundKin` and `rules`, then calls `indexCouples` (D-11).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/persondetail/...` green, `TestPersonFamily` AC-1.14 unchanged.

**STEP-4 — PersonFamily reads the marriages**
Files: `core/database/persondetail/family.go`, `family_test.go`, `family_query_test.go`, `caps_test.go`.
Do: D-6, D-7; add each group member to the persons wanted and to `in.AddHandles`, as the units' members are.
Check: T-5, T-6, T-7 pass; `TestPersonFamilyRecordsInputs` green.

**STEP-5 — Order, drop and index**
Files: `core/database/persondetail/family.go`, `family_test.go`, `family_drop_test.go`.
Do: sort each group's children with `byBirth`; D-8; call `indexCouples` after the drop (D-11).
Check: T-4 and the extended `TestDropUnread` pass.

**STEP-6 — Proto**
Files: `api/proto/engine.proto`; generated `api/proto/engine/engine.pb.go`, `macos/App/Platform/Generated/engine.pb.swift`. Skill: `add-ffi-handler`.
Do: the messages and fields in §6 FFI; run `./scripts/generate-proto.sh`. Never edit the generated files by hand; with no `protoc` toolchain, stop and report (§11).
Check: `go build ./...` passes.

**STEP-7 — Handler**
Files: `api/ffi/handlers/person_detail.go`, `person_detail_test.go`.
Do: map `Family.Groups` with `familyMemberProto` and their `Couples` as `couple_indexes`, `Family.UnitCouples` onto each `FamilyUnit`, and `Family.Couples` with `eventSummaryProto` (D-9, D-11); a member or event with no summary at this point is an error, as `familyMemberProto` and `personEventProto` treat one.
Check: T-8 passes; `CGO_ENABLED=1 go test -tags fts5 ./api/...` green.

**STEP-8 — Swift mapping**
Files: `macos/App/Platform/GenealogyStore.swift`, `macos/App/Platform/GoStore.swift`.
Do: the types and mapping in §6 macOS.
Check: `scripts/check-pr.sh` builds the app and its tests with no Swift warning. With no `xcodebuild` (not macOS), report the Xcode steps as not run (§11).

**STEP-9 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`; `deployment-plan.md`: the S16-82 map row status, and the rule "(Batch 1) Crafted fan-out is capped, not engineered" (a caps bullet for `maxMarriagesPerCouple`, 10, in `persondetail.PersonFamily`); `docs/matching-model.md` (the `kinship.MaxPivotEnd` row names `Couples` among its page readers: no parent pairs past the bound); `core/kinship/kinship.go` package doc (names `SiblingGroups` and `Couples` beside `KinOf` and `FamilyUnits`); `.agents/skills/add-match-rule/SKILL.md` (the kinship page-functions sentence names `SiblingGroups` and `Couples`); `docs/ideas/kinship-view.md` (the grouping is in `core/kinship`); this plan (status).
Do: per the Definition of done.
Check: links resolve; `scripts/check-pr.sh` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/kinship/families_test.go` `TestSpousePatterns` *(new)* | `SpouseEventTypes()` → `[marriage]`; `PatternMarriageSpouses.ImpliesSpouse()` true, `PatternBirthParents` and `PatternSharedParent` false | D-10 |
| T-2 | Go | `families_test.go` `TestSiblingGroups` *(new, table)* | Links built with the file's `linksFor`, sibling shapes as `Shape{PatternSharedParent, parent}`: the families of AC-1.1 – AC-1.6 → the groups (parents in parent order, children in link order) in the order listed there; 11 parents and one recorded sibling → the person's group with 11 parents, the sibling in the last group | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, D-2, D-3 |
| T-3 | Go | `families_test.go` `TestCouples` *(new, table)* | Hand-built `Link`s with `Shape{PatternMarriageSpouses, pivot}`: a spouse with two marriage shapes and a repeated pivot → one couple, two pivots in shape order; the same spouse twice in `kin[RoleSpouse]` → one couple; a spouse link with no marriage shape → none; two parents joined by a married spouse link filed by the second parent only → a couple with A the earlier parent; two parents paired only by a shared birth pivot → none; the person married to Sam, with `kinOf` holding no entry for the person or Sam → the couple is still found from `kin[RoleSpouse]`; the person married to parent S, and S married to parent P2 → two couples, {person, S} first; 11 parents → no parent pairs | AC-2.1, AC-2.2, AC-2.3, AC-2.4, D-5, D-13 |
| T-4 | Go | `core/database/persondetail/family_test.go` `TestPersonFamilyGroups` *(new)* | The canon families of AC-1.1 – AC-1.5 (Canon `Birth`, `Parent`, `Relationship`, `Marriage`, `Date`); a helper `groupsOf` *(new)* prints each group as `"Heinrich+Anna: Margarethe, Johann, Friedrich, Wilhelm"` (parents in order joined with `+`, children in order, not sorted) → exactly the lines listed there; a merged sibling → absent, and its group dropped if left empty; a merged parent (Canon `Merge` into a stranger) → the group keeps its children and its other parents | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, D-3, D-8 |
| T-5 | Go | `family_test.go` `TestPersonFamilyCouples` *(new)* | Johann–Maria married 1841 and undated → one couple, 1841 first; Heinrich–Anna married → couple; Johann–Sophie through a child only → none; one marriage merged away → not sent; AC-2.8's family → the groups' and partner units' couple indexes listed there; a date edit on Johann–Maria's marriage (Canon `Date`, `Commit`), read again → the couple's marriage carries the new date and the inputs' handles name the event | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.6, AC-2.7, AC-2.8, D-7, D-11 |
| T-6 | Go | `family_query_test.go` `TestPersonFamilyQueryCount` (extend) | Its fixture already holds two marriages: assert the first read's `Couples` is not empty; the warm read's equality and 0 queries then cover the new fields | AC-2.7 |
| T-7 | Go | `caps_test.go` `TestCraftedFamily` (extend) | A couple with 200 dated marriages → 10 sent: the set is the first 10 pivots in shape order, sent in date order; within `capBudget` | AC-2.5, D-6 |
| T-8 | Go | `api/ffi/handlers/person_detail_test.go` `TestGetPersonFamily` (extend) | The test's `pat`–`sam` marriage `m1` → a `FamilyCouple` with `m1`'s summary, and `pat`–`sam`'s partner unit's `couple_indexes` names it; `sibling_groups[0]` holds `pat` | AC-2.1, AC-2.8, D-9 |
| T-9 | Go | `family_drop_test.go` `TestDropUnread` (extend) | The literal gains `Groups` and `Couples`: an unread sibling and an unread parent leave the group's other members; the first group stays with the person unread; a couple with one unread person is dropped | D-8 |

Must stay green: everything `scripts/check-pr.sh` runs, `TestPersonFamily` AC-1.14 (`Families` equals `PersonFamily`) unchanged. Most likely to break: `TestFamilies` (the extractions), `TestPersonFamilyQueryCount`, `TestDropUnread`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none in this PR)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (both done in planning)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated; S16-81 archives S16-D18
- [ ] Docs and guidance per STEP-9: the caps list in the rule "Crafted fan-out is capped, not engineered", matching-model.md's MaxPivotEnd row, the kinship package doc, add-match-rule, docs/ideas/kinship-view.md
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None — nothing on screen changes. The handler test (T-8) is the check; the reviewer reads its output.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| The STEP-1 extractions change `parentUnits`' placement | `TestFamilies` and `TestPersonFamilyOriginSiblings` must pass unchanged |
| Event summaries add queries to a warm read | T-6; the event nodes and summaries are cached like the Timeline's |
| A marriage's place or date edit not refreshing Family | T-8 asserts the event id is among the inputs, as the Timeline records its events |

**Stop and report if:**

- `PersonEvents` no longer records event nodes through `in.Nodes` and `in.Cached` (D-7's precedent changed).
- `EventsByIDs` no longer returns list order.
- A spouse link between two married people carries no `PatternMarriageSpouses` shape in `canonlinks.Reader.Relationships`' output (D-5 rests on it).
- `TestFamilies` or `TestPersonFamilyOriginSiblings` cannot pass after the STEP-1 extractions without changing their expectations.
- `protoc`, `protoc-gen-go` or `protoc-gen-swift` is missing: report STEP-6 as not run and stop; never hand-edit `engine.pb.go` or `engine.pb.swift`. With no `xcodebuild`, finish the Go steps and report STEP-8's Xcode check as not run.
- The warm read in T-6 issues a query that only a change outside §6 would remove.

## 12. Open questions

None.

## 13. PR

**Title:** S16-82 — The Family read sends sibling groups and each couple's marriages
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; `Plan: docs/deployment-plan/spike-16/prs/S16-82-family-groups-and-marriages-read.md`.
