# Working labels on Conclusion handles

**Status:** idea, not scheduled (2026-11-28). From [`place-types-and-households.md`](place-types-and-households.md) (a household like "the Smith homestead" has no recorded name) and dogfood: a census names a subject's father or mother and says something about them, but not their name. Those people end up unnamed at the bottom of the Persons list.

## The problem

Some Persons and Places have no recorded name. The researcher still needs to call them something, to find them again for a merge and to recognise them on a list: "Mother of James", "the Smith homestead". That name isn't evidence, so it can't be a Property value: a value is an Observation, and an Observation needs a Citation. A made-up name stored that way would look like a record said it.

## What exists

The model already has the slot, **`canonical_entities.label`** on a Conclusion handle, "an optional researcher working identifier" that "is not a genealogical name and must not substitute for NameValue Observations" ([`conclusion-layer-data-model.md`](../conclusion-layer-data-model.md) §6). It's already read:
  - **Titles.** Every kind's title is the recorded name, else the label in italic, else the ref: `PersonTitleDisplay`, `PlaceTitleDisplay` and `EventTitleDisplay` (`macos/App/Platform/`) all return a `PVTitleSource`, and the Go side matches (`placeTitle` in `core/database/conclusionsummaries/order.go`).
  - **Sort.** A nameless Person sorts by it (`personSortKey`), so a labelled "Mother of James" sorts under M instead of falling to the bottom.
  - **Search.** The omnibar indexes it (`core/database/searchindex/handles.go`).

When a record does name the person or place, that name is a cited `name` or `toponym`, and it wins the title. The label stays as the researcher's identifier.

**Not the Source-graph subject's label.** `subjects.label`, set in the graph's create dialog, is a separate thing: a handle for working with a card on one Evidence graph. It never reaches the Conclusion layer, and nothing here connects the two (decided, user, 2026-11-28).

## What's missing

Nothing writes the handle's label. `canonicalentities` has no update, Promote mints handles with an empty label (`core/database/promote/promote.go`, `core/database/identityclaims/bridgefile.go`), and no RPC or screen sets it. A handle with no recorded name is titled by its ref.

## Wanted

1. **Edit the label on the Conclusion page, for Persons and Places alike.** An audited update in `canonicalentities` ([`add-catalog-query`](../../.agents/skills/add-catalog-query/SKILL.md), [`add-audit-scope`](../../.agents/skills/add-audit-scope/SKILL.md)), one FFI handler ([`add-ffi-handler`](../../.agents/skills/add-ffi-handler/SKILL.md)), and an editable label on the page. It's one write for every kind, not one per kind. The graph cache and the search index already read the column, so the write's effects must reach both ([`catalog-caches.md`](../catalog-caches.md)). Events compose their titles from type and participants and rarely need one, but nothing stops it.
2. **Prompt for a label on the Promote page.** When a row would leave its handle titled by its ref, show an inline check on that row:
   - a Person: "This person has no name. Add a working label?"
   - a Place: "This place has no toponym. Add a working label?"

   It applies when the row's target is **New**, or an existing record that has neither a name nor a label and that this subject doesn't name either. The field starts empty; a researcher who doesn't want a label leaves it empty and the row promotes as today. The label rides in the Promote batch and is written with **Done**, in the same revision as the Identity Claims, so Cancel or a stale-catalog refusal writes no label either.

## One rule, not one per kind

The prompt's condition is "this handle's title would fall back to its ref", which is the existing title rule (name, else label, else ref). It isn't a check for `name` on persons and `toponym` on places. Read it from the same source the titles use, so a kind whose title property changes, or a new kind, gets the prompt without a new branch. The copy names the missing thing per kind ("no name", "no toponym"), so the kind's title property needs a label to show. The locked `name` on `person` and `toponym` on `place` bindings ([`seeded-vocabulary.md`](../seeded-vocabulary.md) §3.3) are already the properties the titles read.

## Decided (user, 2026-11-28)

1. **Merge chooses the label.** When handle merge is built, its UI has a control for which label survives.
2. **Subject labels stay separate,** as above. With no subject label copied up, there's no duplicate warning.
3. **No dismiss.** The Promote check stays on the row; an empty field is the way to decline.
4. **The design brief comes with planning.** The Conclusion page editor and the Promote row's check add chrome, so the plan starts with a Claude Design brief ([`add-design-brief`](../../.agents/skills/add-design-brief/SKILL.md)).

## Open questions

1. **Wording.** The page needs to show that the label is the researcher's name, not a recorded one. The italic title already does this on lists. Copy goes through [`add-localized-string`](../../.agents/skills/add-localized-string/SKILL.md).

## First slice

The audited label write and its FFI handler, with the Conclusion page editor for Persons and Places. The Promote check comes after, since it changes the Promote batch.
