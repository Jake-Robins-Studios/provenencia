# S16-82 — The Family read sends sibling groups and each couple's marriages

**Status:** Draft
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
| AC-1.4 | Elisabeth recorded as Johann's sister with no shared parent; Johann has parents (F4) | Elisabeth is in a last group with no parents |
| AC-1.5 | Johann has no parents; Clara and Karl recorded as his siblings (F6) | One group, no parents: Clara, Johann, Karl in birth order |
| AC-1.6 | Johann has no parents and no siblings | One group: Johann alone |

**US-2.** As the engine, I send each couple the page shows with its marriages, so the page draws "m. 12 Jun 1841 · Hamburg" without looking for events.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Johann and Maria are subjects of a marriage dated 12 Jun 1841 | A couple {Johann, Maria} with that marriage's event summary |
| AC-2.2 | Heinrich and Anna, Johann's parents, are subjects of a marriage | A couple {Heinrich, Anna} with its summary |
| AC-2.3 | Johann and Sophie are partners through a child only, or linked as spouses with no marriage event | No couple for them |
| AC-2.4 | Johann and Maria have two marriages, 1841 and one undated | One couple, the 1841 marriage first, the undated one second |
| AC-2.5 | A couple has 200 marriage events (crafted) | The couple carries the first 10 (D-6); the read stays within the timing budget |
| AC-2.6 | One of a couple's marriage events is merged away before the read | It is not sent; a couple left with none is not sent |
| AC-2.7 | A warm second read | Issues no graph query and records the same inputs; a change to a marriage's date makes the read's inputs name that event |

## 3. Scope

| In | Covered by |
| --- | --- |
| `kinship.SiblingGroups` and `kinship.Couples`, page-only, beside `FamilyUnits` | STEP-1, STEP-2, AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-2.1, AC-2.2, AC-2.3, AC-2.4 |
| `kinship.SpouseEventTypes()` and `Pattern.ImpliesSpouse()`, derived from `eventPatterns` | STEP-1, AC-2.1 |
| `persondetail.Family` carries the groups and couples; `PersonFamily` reads the marriages, caps, orders and drops unread | STEP-3, STEP-4, AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-2.5, AC-2.6, AC-2.7 |
| Proto `SiblingGroup`, `FamilyCouple`, `GetPersonFamilyResponse.sibling_groups` and `.couples`; handler mapping | STEP-5, STEP-6 |
| Swift: `CatalogSiblingGroup`, `CatalogFamilyCouple`, `CatalogPersonFamily.siblingGroups` and `.couples`; `GoStore` maps them; nothing draws them | STEP-7 |

| Out | Home |
| --- | --- |
| Drawing the groups and the marriage lines | S16-81 |
| Deleting `origin_siblings`, `parent_sets`, `OriginSibling`, `originSiblings`, the `PARENTS` and `SIBLINGS` units and `parentUnits`' set building | S16-81 (it removes their last reader) |
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
| D-4 | A group's parents are `Relative`s from the person's own parent links (so each carries the person's link); its children are `Relative`s from the person's sibling links, and the person is `Relative{ID: person}` with a nil link, as `originSiblings` adds it | Same members the units send today | — |
| D-5 | A couple is the person with each spouse in `kin[RoleSpouse]`, and each two of the person's parents joined by a spouse link in either parent's `kinOf[…][RoleSpouse]`. Its marriages are the distinct pivots of the link's shapes whose pattern `ImpliesSpouse`, in shape order. Only couples with at least one pivot are returned. For a partner, A is the person; for parents, A is the earlier in the person's parent order | The spouse-implying patterns are the rule (working rule); the shapes already name the events | Reading marriage events by walking each person's events — a second way to find them |
| D-6 | At most `maxMarriagesPerCouple = 10` pivots per couple are read, the first in shape order, before any node or summary is loaded; a package constant in `persondetail` with `// decided: user, 2026-11-08` (rule "Crafted fan-out is capped, not engineered") | The cap sits beside the read it bounds; `persondetail` is not a matching package; real data has one to three | A `kinship.Rules` knob — the cap is the page read's, not kinship's |
| D-7 | `PersonFamily` loads the capped pivots with `in.Nodes`, keeps those `in.Cached(id).Canonical(eventType)` accepts, reads them with `EventsByIDs` (list order) and persons with `PersonsByIDs`, and builds the summaries with `NewSummaries(persons, events, nil)`. Each couple keeps its read events in `EventsByIDs`' order | Records inputs as `PersonEvents` does; list order is the one date order | `ByIDs` — its map loses the order |
| D-8 | `dropUnread` also drops unread group members, unread couples and unread marriages; the first group is never dropped; another group left with no child is dropped; a couple whose either person or every marriage is unread is dropped | One drop rule for every part the read sends | — |
| D-9 | The response sends both alongside today's fields (`sibling_groups = 5`, `couples = 6`); a couple names its two people by entity id string (`database.UUIDString`) and carries `EventSummary`s through `eventSummaryProto` | Additive: the app keeps drawing from today's fields until S16-81 | Couples nested in groups and partner units — two places for one fact |
| D-10 | `kinship.SpouseEventTypes()` lists the event types of the patterns whose term is `TermSpouse`, in `eventPatterns` order; `Pattern.ImpliesSpouse()` is true for those patterns' codes. Both read `eventPatterns`; nothing else lists marriage | One registry; S16-81's parity test reads `SpouseEventTypes` | A hard-coded `PatternMarriageSpouses` check |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `kinship.SiblingGroup`, `SiblingGroups(person []byte, kin Kin) []SiblingGroup` *(new)* | type, func | `kinship.FamilyUnits`, `Unit` | Units group by parent *sets* (pairs and extras); groups are by exact shared parentage. A `Unit` kind would mix two orders in one list |
| `kinship.Couple`, `Couples(person []byte, kin Kin, kinOf map[string]Kin, rules Rules) []Couple` *(new)* | type, func | `partnerUnits` | Partner units hold children, not pivots, and know nothing of the parents' pair |
| `kinship.sharedParents` *(new, unexported)* | func | the inline loop in `parentUnits` | Extracted, not copied: `parentUnits` calls it |
| `kinship.SpouseEventTypes`, `Pattern.ImpliesSpouse` *(new)* | func, method | `Patterns`, `Pattern.PivotKind` | Same table, a new question |
| `persondetail.maxMarriagesPerCouple` *(new)* | const | `maxRecordLinkLines` (`recordlinks.go`) | The page read's own cap |
| `engine.SiblingGroup`, `engine.FamilyCouple`, response fields 5–6 *(new)* | proto | `OriginSibling`, `FamilyUnit` | New shapes; the old ones go in S16-81 |
| `CatalogSiblingGroup`, `CatalogFamilyCouple` *(new)*; `CatalogPersonFamily.siblingGroups`, `.couples` *(new)* | Swift types | `CatalogOriginSibling` | As above |

**Builds on.** `canonlinks.Reader.Relationships` with `Siblings: true`, `kinship.KinOf`, `shownKin`, `conclusionsummaries.EventsByIDs`, `graphcache.PageInputs`, `familyMemberProto`, `eventSummaryProto`, `GoStore.mapFamilyMember`, `mapEventSummary`.
**Deletes.** None in this PR — `origin_siblings` and the parent-set units keep their one reader, the app's current drawing, until S16-81 replaces it; S16-81's scope entry lists them.
**Next adds.** S16-81 draws `siblingGroups` and `couples` and deletes the old fields. A union pattern added to `eventPatterns` with term `TermSpouse` reaches `Couples` and `SpouseEventTypes` with no other change. A family tree (`docs/ideas/kinship-view.md`) reads `SiblingGroups` per generation.

### Reach

| New path or state | Destination | Checked |
| --- | --- | --- |
| A person with no parents now yields a group (AC-1.5, AC-1.6) | `SiblingGroups`, `dropUnread` | The first group is kept even with no parents and only the person |
| An event summary on the Family response | `eventSummaryProto`; `GoStore.mapEventSummary` | Same mapping as the Timeline's events; a missing picture path maps to "" |
| A merged or removed marriage event | `PersonFamily` | Not canonical or no summary → not sent (AC-2.6) |

### Scale

At the map's Scale (real: 20 children in four parent sets, one or two marriages per couple; crafted: each axis 20 times past its cap): groups are linear in siblings × parents (≤ `MaxKinPerRole` each, both already capped in `KinOf`); couples are at most the person's spouses plus pairs of parents (pairs only form among ≤ `MaxPivotEnd` parents, since `Siblings` and pairing stop past it — `Couples` checks pairs only when the person has at most `MaxPivotEnd` parents); marriages are read at most `maxMarriagesPerCouple` per couple, so at most (100 + 45) × 10 event nodes, all in one `Nodes` call and one `EventsByIDs` call. The read adds two batched loads, no per-couple query. `TestCraftedFamily` gains a 200-marriage couple within `capBudget`.

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
| `core/kinship` (`families.go`) | `type SiblingGroup struct { Parents, Children []Relative }` *(new)*; `func SiblingGroups(person []byte, kin Kin) []SiblingGroup` *(new)*; `type Couple struct { A, B []byte; Pivots [][]byte }` *(new)*; `func Couples(person []byte, kin Kin, kinOf map[string]Kin, rules Rules) []Couple` *(new; reads `rules.MaxPivotEnd`)*; `func sharedParents(l Link, parentIDs [][]byte) []int` *(new)*, called by `parentUnits` |
| `core/kinship` (`patterns.go`) | `func SpouseEventTypes() []vocabkey.EventType` *(new)*; `func (p Pattern) ImpliesSpouse() bool` *(new)* |
| `core/database/persondetail` (`family.go`) | `Family` gains `Groups []kinship.SiblingGroup` and `Couples []kinship.Couple` *(new fields; `Couples[i].Pivots` holds the read marriages in list order after `PersonFamily`)*; `Families` fills both from `shown` and `aroundKin`; `PersonFamily` reads the marriages (D-6, D-7) and sorts each group's children with `byBirth`; `dropUnread` per D-8; `const maxMarriagesPerCouple = 10` *(new)* |

Errors: none new.

### FFI

`api/proto/engine.proto`:

```proto
// SiblingGroup is the person's siblings who share exactly the same of the
// person's parents, the person among them. The first group is the person's.
message SiblingGroup {
  repeated FamilyMember parents = 1;   // the person's parents the group shares, in the person's parent order
  repeated FamilyMember children = 2;  // birth order, undated last; the person's member has no link
}

// FamilyCouple is two people the page shows together and the marriage events
// both are subjects of, earliest first.
message FamilyCouple {
  string a_entity_id = 1;
  string b_entity_id = 2;
  repeated EventSummary marriages = 3;
}

// in GetPersonFamilyResponse
  repeated SiblingGroup sibling_groups = 5;
  repeated FamilyCouple couples = 6;
```

Handler `api/ffi/handlers/person_detail.go` `GetPersonFamily` maps both. Regenerate with `./scripts/generate-proto.sh`.

### macOS

| Building block | Component | Home | Notes |
| --- | --- | --- | --- |
| Sibling group | `CatalogSiblingGroup { parents: [CatalogFamilyMember]; children: [CatalogFamilyMember] }` *(new)* | `macos/App/Platform/GenealogyStore.swift` | Beside `CatalogOriginSibling` |
| Couple | `CatalogFamilyCouple { aEntityId: String; bEntityId: String; marriages: [CatalogEventSummary] }` *(new)* | same | |
| Family | `CatalogPersonFamily.siblingGroups: [CatalogSiblingGroup] = []`, `.couples: [CatalogFamilyCouple] = []` *(new)* | same | Defaults keep `FakeStore` and previews compiling |
| Mapping | `GoStore.getPersonFamily` | `macos/App/Platform/GoStore.swift` | `mapFamilyMember`, `mapEventSummary` |

Nothing draws them. States: none.

### Strings

None — no copy.

## 7. Steps

**STEP-1 — Spouse patterns and shared parents in kinship**
Files: `core/kinship/patterns.go`, `core/kinship/families.go`, `core/kinship/families_test.go`. Skill: `add-match-rule`.
Do: add `SpouseEventTypes` and `ImpliesSpouse` (D-10); extract `sharedParents` from `parentUnits` and call it there (D-2).
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/kinship/...` passes; `TestFamilies` unchanged and green; T-1 passes.

**STEP-2 — SiblingGroups and Couples**
Files: `core/kinship/families.go`, `core/kinship/families_test.go`.
Do: add the types and functions per D-3, D-4, D-5, with their doc comments stating the order.
Check: T-2, T-3 pass.

**STEP-3 — Families carries groups and couples**
Files: `core/database/persondetail/family.go`.
Do: `Families` sets `Family.Groups` from `shown[id]` and `Family.Couples` from `shown[id]`, `aroundKin` and `rules`.
Check: `go test -tags fts5 ./core/database/persondetail/...` green.

**STEP-4 — PersonFamily reads the marriages, orders and drops**
Files: `core/database/persondetail/family.go`, `family_test.go`, `family_drop_test.go`, `family_query_test.go`, `caps_test.go`.
Do: D-6, D-7, D-8; add each group member to the persons wanted and to `in.AddHandles` as the units' members are; sort each group's children with `byBirth`.
Check: T-4 – T-7 pass; `TestPersonFamilyRecordsInputs`, `TestPersonFamilyQueryCount`, `TestCraftedFamily` green.

**STEP-5 — Proto**
Files: `api/proto/engine.proto`; generated `api/proto/engine/engine.pb.go`, `macos/App/Platform/Generated/engine.pb.swift`. Skill: `add-ffi-handler`.
Do: the messages and fields in §6 FFI; run `./scripts/generate-proto.sh`.
Check: `go build ./...` passes.

**STEP-6 — Handler**
Files: `api/ffi/handlers/person_detail.go`, `person_detail_test.go`.
Do: map `Family.Groups` with `familyMemberProto` and `Family.Couples` with `eventSummaryProto` (D-9); a member or event with no summary at this point is an error, as `familyMemberProto` and `personEventProto` treat one.
Check: T-8 passes; `go test -tags fts5 ./api/...` green.

**STEP-7 — Swift mapping**
Files: `macos/App/Platform/GenealogyStore.swift`, `macos/App/Platform/GoStore.swift`.
Do: the types and mapping in §6 macOS.
Check: `scripts/check-pr.sh` builds the app and its tests with no Swift warning.

**STEP-8 — Docs**
Files: `docs/deployment-plan/spike-16/completed.md`, `deployment-plan.md` (map row), this plan (status), `.agents/skills/add-match-rule/SKILL.md` (the kinship page-functions sentence names `SiblingGroups` and `Couples`).
Do: per the Definition of done.
Check: links resolve; `scripts/check-pr.sh` passes.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Restore list scroll after the sort is applied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/kinship/families_test.go` `TestSpousePatterns` *(new)* | `SpouseEventTypes()` → `[marriage]`; `PatternMarriageSpouses.ImpliesSpouse()` true, `PatternBirthParents` and `PatternSharedParent` false | D-10 |
| T-2 | Go | `families_test.go` `TestSiblingGroups` *(new, table)* | The links of AC-1.1 – AC-1.6 → the groups, parents and children (link order) and group order listed there; a parent past `MaxPivotEnd` (11 parents, a recorded sibling) → the person's group with 11 parents, the sibling in the last group | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, D-2, D-3 |
| T-3 | Go | `families_test.go` `TestCouples` *(new, table)* | Person and a spouse with two marriage shapes and one repeated pivot → one couple, two pivots in shape order; a spouse link with no marriage shape → none; two parents joined by a spouse link with a marriage → couple, A the earlier parent; 11 parents → no parent pairs | AC-2.1, AC-2.2, AC-2.3, AC-2.4, D-5 |
| T-4 | Go | `core/database/persondetail/family_test.go` `TestPersonFamilyGroups` *(new)* | The canon families of brief frames F1, F2, F3, F4, F6 (Canon `Birth`, `Parent`, `Relationship`, `Marriage`, `Date`) → groups as names in order, children in birth order; a merged sibling (Canon `Merge`) → absent, and a group left empty is dropped | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, D-3, D-8 |
| T-5 | Go | `family_test.go` `TestPersonFamilyCouples` *(new)* | Johann–Maria married 1841 and undated → one couple, 1841 first; Heinrich–Anna married → couple; Johann–Sophie through a child only → none; one marriage merged away → not sent | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.6, D-7 |
| T-6 | Go | `family_query_test.go` `TestPersonFamilyQueryCount` (extend) | The family with a marriage, warm second read → 0 queries, same inputs, same Family | AC-2.7 |
| T-7 | Go | `caps_test.go` `TestCraftedFamily` (extend) | A couple with 200 marriages → 10 sent, the first 10 in shape order; within `capBudget` | AC-2.5, D-6 |
| T-8 | Go | `api/ffi/handlers/person_detail_test.go` `TestGetPersonFamily` (extend) | The test's `pat`–`sam` marriage `m1` → a `FamilyCouple` with `m1`'s summary; `sibling_groups[0]` holds `pat`; `TestPersonFamilyRecordsInputs` with a marriage → the event's id among the inputs' handles | AC-2.1, AC-2.7, D-9 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `TestFamilies` (the `sharedParents` extraction), `TestPersonFamilyQueryCount`, `TestDropUnread`.

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left (none in this PR)
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left; `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated (none)
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New (no UI)
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together) — none
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — not gated; S16-81 archives S16-D18
- [ ] Domain doc updated if a rule in docs/*.md changed: none; add-match-rule's kinship page-functions sentence names SiblingGroups and Couples
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

None — nothing on screen changes. The handler test (T-8) is the check; the reviewer reads its output.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| Extracting `sharedParents` changes `parentUnits`' placement | `TestFamilies` and `TestPersonFamilyOriginSiblings` must pass unchanged |
| Event summaries add queries to a warm read | T-6; the event nodes and summaries are cached like the Timeline's |
| A marriage's place or date edit not refreshing Family | T-8 asserts the event id is among the inputs, as the Timeline records its events |

**Stop and report if:**

- `PersonEvents` no longer records event nodes through `in.Nodes` and `in.Cached` (D-7's precedent changed).
- `EventsByIDs` no longer returns list order.
- A spouse link between two married people carries no `PatternMarriageSpouses` shape in `canonlinks.Reader.Relationships`' output (D-5 rests on it).
- `TestFamilies` or `TestPersonFamilyOriginSiblings` cannot pass after extracting `sharedParents` without changing their expectations.
- The warm read in T-6 issues a query that only a change outside §6 would remove.

## 12. Open questions

None.

## 13. PR

**Title:** S16-82 — The Family read sends sibling groups and each couple's marriages
**Body:** objective in one sentence; what shipped against US-1 and US-2; AC evidence; deviations from the plan; `Plan: docs/deployment-plan/spike-16/prs/S16-82-family-groups-and-marriages-read.md`.
