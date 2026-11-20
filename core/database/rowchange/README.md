# rowchange

One row-level mutation: entity type, id, action (`create`, `update`, `delete`), and each field's old and new value.

`audit.Record` stores a `Change` on `audit_changes`. [`effects`](../effects) reads the same value when it walks a path. [`deleteimpact`](../deleteimpact) builds these changes when it releases facet rows. The type lives here so those packages do not import each other.

`Created`, `Updated` and `Deleted` build a row's change from its entity type, its id and its column map. `Created` is a create: every key is present, old is nil, new is the value. `Deleted` is a delete: old is the value, new is nil. `Updated` diffs two row maps and records a field only when it changed (a key missing from one side reads nil, `fixed` keys are skipped); it returns nil when nothing changed. A column left off the diff is unchanged. Each copies the id it is given.

This package does not know table names, foreign keys, or what a change affects. The map of the schema packages is in [`catalogmodel`](../catalogmodel/README.md).
