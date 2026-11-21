---
name: add-catalog-query
description: >-
  Adds Provenencia catalog table access as a nested domain package under core/database.
  Use when adding or changing SQLite queries, Upsert/Lookup/List for a catalog table,
  core/database/users or a new core/database/<table>/ folder, or when the user asks
  for database query functions without putting another file in core/database/.
---

# Add a catalog query package

Table SQL and functions live in **`core/database/<domain>/`**, not in the `database` package root. Root stays the exclusive catalog client (`Catalog`, `Create`/`Open`/`Close`, format errors, migrations).

New **schema** is a separate step: follow `.agents/skills/add-catalog-migration/SKILL.md` first if the table does not exist yet, and register the table and its FKs in the same PR (`.agents/skills/add-catalog-model/SKILL.md`).

## Layout

Copy `core/database/users/`.

```
core/database/<domain>/
  <domain>.go       # SQL consts, functions, domain sentinels
  <domain>_test.go  # table-driven tests
```

Package name is the folder name (`users`, `datevalues`, later `sources`, …). Call sites use `users.Upsert(c, …)`, not `Catalog` methods.

Researcher FFI/onboarding obtain `c` from **`catalogsession.Do`** / **`withProjectCatalog`** (see `.agents/skills/use-catalog-session/SKILL.md`). Package tests may still `database.Create` / `Open` + `defer Close()`.

Shared genealogical dates: follow `.agents/skills/add-date-value/SKILL.md` (`core/datevalue` for the type, `core/database/datevalues` for queries), not a new ad-hoc date package.

Product-seeded vocabulary (`origin=provenencia` registries + `Ensure`): follow `.agents/skills/add-seeded-vocabulary/SKILL.md`.

Official **resource / vocab `Delete`**: follow `.agents/skills/add-catalog-delete/SKILL.md`. Do not add `sqlInUse` next to `DELETE`.

## Functions

- Take `*database.Catalog`. Get the handle with `c.DB()`; return that error (`database.ErrClosed`).
- Keep SQL as unexported consts next to the functions. Do not add `core/database/queries/`.
- Domain validation sentinels stay in this package (`users.ErrInvalid`), except for a value type that a matching layer or the reconciler carries: that lives in a pure `core/<singular>` package (`core/datevalue`, `core/namevalue`, `core/depictionvalue`) that owns its type, `Validate` and `ErrInvalid`, and the table package keeps only the queries. Do **not** add them to `core/database/errors.go` (that file is lock/format/folder/closed only).
- A by-id `IN` read goes through `core/database/sqlbatch` (`sqlbatch.Query`). A hand-built `SQLInPlaceholders` list is allowed only over a set something else already bounds: one `sqlbatch.Each` chunk, one page of search hits, or a fixed vocabulary of keys or levels. The function's comment names that bound. SQLite binds at most 32,766 values per statement.
- A table read with a column list writes it once: `columns(alias)` on `database.Columns` (`"id"`, `"description|COALESCE(%s, '')"`), `scanX(row, extra ...any)` reading that list, and `GetManyTx` (`database.UniqueBlobIDs`, `sqlbatch.Query`, a map keyed by `string(id)`, missing ids absent).
- Bind an optional value with `database.NullBlob`, `NullString`, `NullInt`, `NullInt64` or `NullBool`; `NullTrimmed` when the text is trimmed first.
- `database` must **not** import table packages (import cycle). Use-cases (`onboarding`, later FFI) import both.
- `Delete` for a resource or vocab row calls `deleteimpact.Impact` in the same tx, then deletes the parent, then owned-outbound release. Facet/field deletes (notes, metadata clear) stay ordinary writes.
- A research write builds each change with `rowchange.Created`, `Updated` or `Deleted` over the package's column map and returns it; `writes.Run` (a write with a value) or `writes.RunChanges` (a write with none) records it in the same transaction. A new audited `EntityType` needs a non-`None` effect, and delete changes carry the parent FK — follow `.agents/skills/add-audit-scope/SKILL.md`. "Last activity" reads (`Updated`) come from the display cache, `Graph.Activity`, which loads `audit_transaction_scopes` once and follows commits.

## Reads inside a write

The catalog has one connection, so a read through `c.DB()` inside `writes.Run` waits on the transaction that is already open. A read a write needs takes the `*sql.Tx` through an exported `…Tx` twin (`artifacts.ListBySourceTx`, `sourcemetadata.ReadDraftTx`). Write the SQL and scan once in an unexported function over `database.Querier`; the Catalog read and its Tx twin both call it.

A package never declares its own querier or scanner interface, named or inline: a read takes `database.Querier`, a write `database.Execer`, a row scan `database.Scanner`, even when it calls one method. `sqlbatch`, `graphcache`, `effects` and `dbtest`, which cannot import `core/database`, take the `dbsql` types those alias. `dbsql`'s guard test refuses a copy. A query that selects one id column calls `database.QueryIDs` (`dbsql.QueryIDs` from a leaf package), not a local copy.

A read made of more than one query straight on `c.DB()` opens one read transaction (`db.Begin`, deferred `Rollback`), as `deleteimpact.Snapshot` does, so its queries see one state. A registry entry's loader runs on the session graph under `catalogsession.Do`'s lock and opens no transaction, as `sources.loadRecords` and `evidencegraphs.list` do. Either way the unexported body takes `database.Querier` and the package's writes call it with their `tx.Tx`; add an exported `…Tx` twin only with its first caller outside the package.

A write across several tables lives in a composing package (`core/database/connect`, `core/database/sourcecopy`, `core/database/sourcemove`). It takes the `*database.Tx`, calls each owner package's write, returns the changes, and never calls `writes.Run`; the handler does. A write that changes both sides of a composite foreign key calls `tx.DeferForeignKeys()` before its first update and never issues a PRAGMA itself.

## Tests

Table-driven, in the same folder. `database.Create` a temp `*.provenencia`, `defer Close()`, cover happy path, validation, and closed catalog.

Run `CGO_ENABLED=1 go test ./core/database/...` (and the use-case package you called from).

## Do not

- Add `<table>.go` / `<table>_test.go` under `core/database/` itself
- Attach table methods to `Catalog`
- Add a new value struct under `core/database/<table>` when a matching layer or the reconciler carries it (put it in a pure `core/<singular>` package)
- Put identity, FFI, or ingest in the query package
- Reach into `Catalog`’s unexported `db` field from another package
