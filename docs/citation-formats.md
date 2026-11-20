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

## Storage

A type stores its three formats in `source_types.citation_full`, `citation_short` and `citation_list`. A column is NULL when the form has no format; an empty or all-whitespace text is never stored. A format is stored as sent, byte for byte, except that each field a placeholder names is written by id (`{graph.meta.#<id>}`, the id in canonical lowercase), so a field's key can never mean two fields once saved and a field a format names cannot be deleted. The wire writes fields by key, as the researcher types them.

`GetCitationFormats` and `UpdateCitationFormats` carry the three forms by key. A write replaces all three, parses each, resolves each key to a field and refuses the whole write with every diagnostic when any form fails: `Parse`'s, then `unknown_field` and `ambiguous_field` at each occurrence of the key (resolution runs only on forms that parsed). Nothing saves and no revision is recorded. A write that stores the texts already stored records nothing.

A key held by more than one field (a product field and a researcher's field may share a key) is `ambiguous_field` unless the write names the field in `field_choices`, one `{key, field_id}` per key; a choice must name a field whose key is exactly that key, or the write is invalid. The read returns a choice for each shown key that more than one field holds, so sending the reply back unchanged stores the same text. A `#<id>` typed in a format resolves to that field, or is `unknown_field`.

The read shows every by-id field by its key, except an id with no field and an id whose key a different id already took in the same type's formats (scanned full, short, list): those stay as their `#<id>` token. A stored text that does not parse comes back as stored with its diagnostics, so a type's page still opens.

Deleting a field is refused while any format names its id; the delete notice lists the types.

## Rendering

`RenderCitations`, `RenderCitationPreview` and `ListCitationBuiltins` (package `core/database/citationrender`) turn the formats into text. Nothing they produce is cached: a screen asks when it shows its citations, so a format or field edit needs no refresh signal.

**What each built-in reads.** `source.title` is the Source's title; `source.type` the type's label; `source.date` the Source's date with its mark; `artifact.label` the Citation's Artifact label; `graph.name` its graph's name; `citation.page` the printed page label with its mark (`locator.Page`); `citation.image` the file page when the locator holds one (a Citation with none leaves it unset); `citation.label` the Citation's label. A metadata field named by id reads the stored value at its level, with its mark and the field's unknown text; a field named by key answers nothing. The boards and the render answer through one resolver (`sourcemetadata.CitationValues`), so they cannot disagree about what has a value.

**The Citation's Source is its graph's.** A Citation never leaves its graph, so its Source is the Source of that graph; its Artifact's own values are still read at the Artifact level.

**The batch.** `RenderCitations` takes at most 2,000 Citation ids and returns, for each Citation found, the full and the short citation as styled runs and plain text, and a group key. The order is the input order, a repeated id once; an id with no Citation is left out without an error. A Citation whose type has no full (short) format, or whose format does not parse, or whose graph, Source or type row is missing, comes back with an empty full (short); the app shows its own line. A call renders at most 8 MiB of text in all; more is `citations.invalid`. The reply also names the Evidence graphs and Sources the read used (`inputs`), so a screen can refresh when they change. A call reads a fixed number of queries per 500 ids.

**The group key.** Citations whose full citations render the same, run for run (italics count), share a key; one that differs in a field the format reads does not, and one that differs only in a field it does not read does. A Citation with no full citation gets a key of its own, so none groups with another. The key is opaque.

**The preview.** `RenderCitationPreview` renders one form against one target: a Citation (any form; the list form reads only its Source) or a Source (the list form only). With no `format` it renders the target's type's stored format. With one, the text is unsaved and written with field keys, checked the way a save checks it (`field_choices` say which field a shared key means): any diagnostic comes back alone, with nothing rendered. A blank format renders nothing. A Citation or Source that is not in the catalog is `citations.not_found` or `sources.not_found`. The reply lists what a needed chain lacks, as the options of that chain that can be shown, in chain order.

## Diagnostics

`Parse` returns every diagnostic with its byte span, sorted by position, and no template. After `unknown_form`, `too_long` and `too_deep` scanning stops and nothing after is reported. After `unclosed_placeholder` scanning stops when no `{` or `}` follows; before a later `{` it resumes there.

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
| `unknown_field` | Reported by a type's format write, not `Parse`: no field has the key, or the id | The field |
| `ambiguous_field` | Reported by a type's format write, not `Parse`: more than one field holds the key and no choice was made | The field |

Each option yields at most one diagnostic, the first that applies in this order from `empty_option` down.
