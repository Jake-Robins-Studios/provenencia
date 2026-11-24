# catalogmodel

The declared list of catalog tables and foreign keys. SQLite remains the schema (`core/database/migrations`, `schemahash.go`). This package is the classified copy other registries read: table name, primary key, kind, bucket, and each foreign key's target, `ON DELETE` action, and whether a cascade is audited.

It imports nothing else in `core/database`, and `core/vocabkey` for the metadata level type. `MetadataTables` declares each metadata level's owner, values and layout tables once, and `SourcePath` walks a level up to its Source; `sourcemetadata`, `deleteimpact` and `effects` build their stores, probes, facet releases and Source scopes from it, so a new metadata level is one entry. An entry's `Ups` are its direct parents, nearest first in `vocabkey.NearestFirst()`; exactly one is `ToSource`, the path the type read and the audit scope follow; `TestMetadataTables` checks the order. `TestPragmaHonesty` checks `Tables` and `FKs` against `sqlite_schema` and `PRAGMA foreign_key_list`.

## How the schema packages sit

These are siblings under `core/database`. Each one is its own package so the imports stay one way.

| Package | Role | Imports |
| --- | --- | --- |
| `catalogmodel` | Declared tables and foreign keys | nothing else in `core/database`; `core/vocabkey` for the metadata level type |
| [`rowchange`](../rowchange) | One row's old and new fields | nothing in `core/database` |
| [`deleteimpact`](../deleteimpact) | Whether a delete is allowed, and what it must release | `catalogmodel`, `rowchange` |
| [`effects`](../effects) | What a written change touches | `catalogmodel`, `rowchange` |
| `audit` | Stores the revision and its source scopes | `rowchange`, `effects` |
| [`writes`](../../writes) | The transaction around a write that has moved onto it | `database`, `audit`, `effects` |

`deleteimpact` and `effects` do not import each other. `effects` does not import `audit`. [`writes.Run`](../../writes) resolves the changes with `effects.Resolve`, records them (`audit.Record` stores the scopes that `Set` names, declared once in `effects.Scopes`), recomputes handles, and reprojects search. Which writes call it is in that package's [README](../../writes/README.md). Official deletes call `deleteimpact`.

A wrapping directory would group the folders in the tree and leave this direction unchanged. Nesting one of these packages inside another would cycle.
