# Citation formats apart from Source types

**Status:** idea. Descoped from Spike 15 as slice 12 (S15-67 – S15-72, briefs S15-D36 – S15-D39) on 2026-11-26. Not scheduled.

## The idea

A Source type says what a record is; a citation format says how it is cited. Today each type carries its own three forms (`source_types.citation_full`, `citation_short`, `citation_list`). Splitting them apart would make formats their own vocabulary:

- **A `citation_formats` table** (label, description, `origin`, the three forms), with `source_types.citation_format_id` as the type's default.
- **A format has its own page** in the sidebar, holding the format editor and preview, with Used by (types and Sources). Add, Copy and Delete; delete refused while a type or Source names it.
- **A Source can choose a format**, `sources.citation_format_id`, NULL following its type.
- **The seed shares formats** where the citation is the same: one Certificate format for the three civil certificates (printing `{source.type}` where the word goes), and the broadcast sharing Journal article.

## What it would allow

- An Obituary type citing with the Newspaper item format, without copying format text.
- One edit changing all three certificates.
- One Source citing differently from the rest of its type.

