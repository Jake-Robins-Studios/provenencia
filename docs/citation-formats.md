# Citation formats

A Source type's citation formats are text in a small syntax of our own. The engine that reads them is `core/citationformat`: pure Go, no database. It parses a format into a tree with positioned diagnostics, renders it through a resolver into italic and plain runs, derives which fields a type's formats need or use, and rewrites a format's field references between keys and ids. Values print exactly as typed; the engine never reorders, inverts or abbreviates metadata.

## Forms

A type has up to three formats, one per form:

| Form | Writes |
| --- | --- |
| `full` | The first note on a source |
| `short` | A later note |
| `list` | The entry in a source list |

The list form describes the Source as a whole, so it reads Source values only: a placeholder at any other level is a diagnostic there.

## Syntax

| Syntax | Meaning |
| --- | --- |
| `{source.meta.key}`, `{artifact.meta.key}`, `{graph.meta.key}` | The metadata value with that key on that level, as typed |
| `{source.title}` and the other built-ins | A value that is not metadata (below) |
| `{a\|b\|c}` | The first option that has a value, like SQL `COALESCE`; the only way a format falls back from one level to another |
| `[ ... ]` | An optional group: removed with its text and punctuation if any placeholder of its own is empty. Groups nest, and a nested group decides for itself only when its parent prints |
| `*...*` | Italic; closes with the next `*` in the same group |
| `\\` `\{` `\}` `\[` `\]` `\*` | A literal character; no other escape exists |

Everything else is literal text, `|` included. Every metadata placeholder names its level; there is no unprefixed `{meta.key}`. A field is named by its key (letters, digits, `_` and `-`) as the researcher types it, or by `#` and its canonical lowercase id as a format is stored. A placeholder may end in `:option` (see Dates). A format holds at most 4,096 bytes and 8 open groups and italic spans at once, and a rendered citation at most 65,536 bytes: a value that crosses that is cut there and nothing after it prints.

## Built-in placeholders

| Placeholder | Value | Options | Unknown text |
| --- | --- | --- | --- |
| `source.title` | The Source title (always set) | none | none |
| `source.type` | The Source type label (always set) | none | none |
| `source.date` | The Source date, a DateValue | `year`, `full` | `n.d.` |
| `artifact.label` | The Artifact label (always set) | none | none |
| `graph.name` | The Evidence graph name (always set) | none | none |
| `citation.page` | The Citation's printed page | none | `unpaginated` |
| `citation.image` | The Citation's page in the file | none | none |
| `citation.label` | The Citation label | none | none |

The Citation level has only built-ins. Metadata sits under `meta.`, so a built-in and a metadata key never collide.

## Needed and used

A placeholder outside every group is needed: empty, it leaves a hole and prints nothing. A placeholder inside a group is used: empty, its group drops out. A chain is one requirement, met when any option has a value; a chain holding an always-set built-in is used, never needed. `Requirements` returns one requirement per distinct sequence of targets, needed if any format needs it. `Missing` returns the needed requirements no target answers, testing each as the full form with no option.

## Unknown and supplied

A value can carry a mark (`core/valuemark`): unknown (the record does not give it; no text) or supplied (not on the record; taken from elsewhere), never both. An unknown value answers its requirement and prints its unknown text: a built-in's from the table above, a metadata field's from its definition, nothing when it has none (its group then drops). A supplied value prints in square brackets. In a chain an unknown answer stops the chain.

## Dates

A DateValue prints in citation terms through `datevalue.CitationDisplay`: day-month-year, `ca.` `bef.` `aft.` for a qualifier, `1878–1882` for a range. `{source.date}` and `{source.date:full}` write the month in full, or abbreviated in the short form; `{source.date:year}` writes the year alone and keeps the qualifier. The words are English citation text and are not localized.

## Diagnostics

`Parse` returns every diagnostic with its byte span, sorted by position, and no template. After `unknown_form`, `too_long`, `too_deep` and `unclosed_placeholder` scanning stops and nothing after is reported.

| Code | When | Span |
| --- | --- | --- |
| `unknown_form` | The form is not one of the three | Zero width at 0 |
| `too_long` | More than 4,096 bytes | The whole text |
| `too_deep` | More than 8 open groups and italic spans | The opening `[` or `*` |
| `unclosed_placeholder` | A `{` with no `}` before the next `{` or the end | That `{` |
| `stray_close_brace` | A `}` outside a placeholder | That `}` |
| `unclosed_group` | A `[` still open at the end | That `[` |
| `stray_close_bracket` | A `]` with no open group | That `]` |
| `unclosed_italic` | A `*` still open when its group closes or the text ends | That `*` |
| `bad_escape` | A `\` before any other character, or last | The `\` and the character after it, or the `\` alone when last |
| `group_without_placeholder` | A group with no placeholder of its own | `[` through `]` |
| `empty_option` | An empty option, as in `{}` | Zero width at its place |
| `bad_character` | An option holding a space, `\`, `{`, `[`, `]` or `*` | The first space, `\`, `{`, `[`, `]` or `*` in the option |
| `unprefixed_meta` | An option whose first part is `meta` | The option |
| `unknown_level` | A first part that is not a level | The option |
| `meta_not_at_level` | `meta` at the Citation level | The option |
| `bad_field` | No field after `meta.`, or one that is neither a key nor an id | The field |
| `unknown_builtin` | A name not in the built-in table at that level | The option |
| `unknown_option` | An option on metadata or one the built-in does not take | The text after the first `:` |
| `not_in_list_form` | A level other than the Source in the list form | The option |

Each option yields at most one diagnostic, the first that applies in this order from `empty_option` down.
