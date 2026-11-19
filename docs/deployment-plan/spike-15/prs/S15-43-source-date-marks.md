# S15-43 — The Source date can be marked unknown or supplied

**Status:** Draft
**Spike / slice:** Spike 15 · Slice 4 — Formats as data
**Map row:** [`../deployment-plan.md`](../deployment-plan.md#pr-map)
**Brief:** — (no chrome change: Go, one migration and the wire. No view sets or shows the date's mark yet; S15-42 adds the date dialog's No date and Supplied and the header's display, gated by S15-D23)
**Board:** —
**Depends on:** S15-02 (landed [#762](https://github.com/Jake-Robins-Studios/provenencia/pull/762)), S15-14 (landed [#868](https://github.com/Jake-Robins-Studios/provenencia/pull/868)); builds on S15-37 (landed [#879](https://github.com/Jake-Robins-Studios/provenencia/pull/879)) and S15-32 (landed [#778](https://github.com/Jake-Robins-Studios/provenencia/pull/778))
**Blocks:** S15-16, S15-42
**Branch:** `s15-43-source-date-marks`
**Version bump:** minor, 0.24.0 → **0.25.0** (if `main`'s `VERSION` is no longer 0.24.0 when you rebase, the next minor after it): a format step that old apps refuse by `user_version`, and new wire fields ([`docs/versioning.md`](../../../versioning.md)); `VERSION`, `core/version.go`, and every `MARKETING_VERSION` line in `macos/Provenencia.xcodeproj/project.pbxproj`
**Skills to load:** [`add-catalog-migration`](../../../../.agents/skills/add-catalog-migration/SKILL.md), [`add-catalog-model`](../../../../.agents/skills/add-catalog-model/SKILL.md), [`add-catalog-query`](../../../../.agents/skills/add-catalog-query/SKILL.md), [`add-date-value`](../../../../.agents/skills/add-date-value/SKILL.md), [`add-audit-scope`](../../../../.agents/skills/add-audit-scope/SKILL.md), [`add-ffi-handler`](../../../../.agents/skills/add-ffi-handler/SKILL.md), [`use-catalog-session`](../../../../.agents/skills/use-catalog-session/SKILL.md)
**Rules that bind:** `.cursor/rules/go-tests.mdc` (table tests)
**Context:** working rules "The Source date is one optional DateValue on `sources`", "A value can be marked unknown or supplied" ([`../deployment-plan.md`](../deployment-plan.md#working-rules)); [`../evidence-explained-citation-map.md`](../evidence-explained-citation-map.md) § 6.10 "Unknown and supplied"; [`../source-provenance-date.md`](../source-provenance-date.md); [`docs/source-layer-data-model.md`](../../../source-layer-data-model.md) § 5 (`sources`); [`docs/structured-date-model.md`](../../../structured-date-model.md) § 3.2 (`phrase`); the precedent plan [`S15-37-metadata-value-marks.md`](S15-37-metadata-value-marks.md)
**Planned:** 2026-11-19 against `main` @ `d3abece` (compare with `origin/main` after `git fetch origin main`; a local `main` may be stale)
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

A Source's own date (S15-02) can carry the two facts of [`core/valuemark`](../../../../core/valuemark/valuemark.go): **unknown** (the record gives no date; the Source holds no DateValue, and a citation prints "n.d.") and **supplied** (the date is not on the record; the researcher took it from elsewhere, and a citation prints it in square brackets). The engine stores, validates, reads, copies and audits the pair; the wire carries it. This is the date half of the storage behind bar 11, as S15-37 was for metadata values.

**Why now.** S15-14 landed `valuemark` and S15-37 put its proto message `ValueMark` and the handler converters (`api/ffi/handlers/value_mark.go`) in place for this PR to reuse. The renderer (S15-16) reads the date's mark to print "n.d." or "[1880]", and the date dialog (S15-42) writes it. Both need these columns and this wire first.

**Also (structural debt; S15-32 review SEC-1, map scope entry).** `datevalue.Validate` gains one high total cap on `Phrase`. Today a crafted catalog's huge phrase is copied again by Copy Source's date tick, which this PR extends to carry the mark.

**What stays.** No view draws or sets the date's mark. Swift sends no mark, so every date save the app makes today writes a date with no mark (D-6). An unknown Source is undated for the Sources list's sort (absent `date_sort_key`, last). Metadata dates stay text. Nothing renders "n.d." yet (S15-16).

## 2. User stories

**US-1.** As the engine, when a Source's date is set with a mark, I store the mark beside the date and refuse a mark `valuemark.Validate` refuses, so that the renderer and the date dialog can trust the stored pair.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-1.1 | An undated Source; `SetSourceDate` with no `date` and `mark {unknown: true}` | The reply's Source has no `date`, no `date_sort_key`, and `date_mark.unknown` true; the row's `date_value_id` is NULL and `date_unknown` is 1; no `date_values` row exists |
| AC-1.2 | A Source dated 1880 (point, year); `SetSourceDate` with no `date` and `mark {unknown: true}` | The date row is released (deleted, with its delete change); the Source reads unknown with no date |
| AC-1.3 | An unknown Source; `SetSourceDate` with `date` "ABT 1880" and `mark {supplied: true}` | A new date row; the Source reads the date with `date_mark.supplied` true and `date_unknown` 0 |
| AC-1.4 | `SetSourceDate` with `date` 1880 and `mark {unknown: true}`; with no date and `mark {supplied: true}`; with no date and `mark {unknown: true, supplied: true}` | Each is refused `valuemark.invalid` (no params); nothing is written; the stored date and mark are unchanged |
| AC-1.5 | A supplied Source dated 1880; `SetSourceDate` with `date` 1880 and no mark | The date row is unchanged (same id); `date_supplied` becomes 0: a write without a mark is a date with no mark (D-6) |
| AC-1.6 | `SetSourceDate` repeats the stored date and mark (dated supplied; and undated unknown) | No change is recorded (`effects.revision` 0) |
| AC-1.7 | An unknown Source; `SetSourceDate` with no date and no mark | The Source is undated with no mark (`date_unknown` 0) |
| AC-1.8 | `GetSourceWorkspace` and `ListSources` on a supplied and an unknown Source | Each `Source` carries the same `date_mark` as the write reply; an unmarked Source carries no `date_mark` |

**US-2.** As the engine, when a Source is copied with its Published date tick on, the mark travels with the date.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-2.1 | Copy Source with `copy_date` true of an unknown Source | The copy is unknown with no date and no `date_values` row |
| AC-2.2 | Copy Source with `copy_date` true of a Source supplied "ABT 1880" | The copy has its own date row equal to the original's and is supplied |
| AC-2.3 | Copy Source with `copy_date` false of an unknown Source, and of a supplied dated Source | The copy is undated with no mark |

**US-3.** As the researcher reading the history, every change to the date's mark is in the audit, on the Source.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-3.1 | AC-1.1's write | One `source` update change with `date_unknown` {false → true} and no other key |
| AC-3.2 | AC-1.2's write | The `source` update change holds `date_value_id` {id → nil} and `date_unknown` {false → true}; then the `date_value` delete change |
| AC-3.3 | AC-1.5's write | One `source` update change with `date_supplied` {true → false}; no `date_value` change |
| AC-3.4 | Deleting an unknown Source, and a supplied Source | The `source` delete change holds `date_unknown` {true → nil}, or `date_supplied` {true → nil}; an unmarked Source's delete change holds neither key |

**US-4.** As the engine, a date phrase has one high bound, so a crafted catalog cannot make a date write copy an unbounded text.

| AC | Given / when | Then |
| --- | --- | --- |
| AC-4.1 | `datevalue.Validate` on a phrase-only point whose phrase is `MaxPhraseBytes` bytes | Valid |
| AC-4.2 | The same with `MaxPhraseBytes + 1` bytes, on a point with a year, and on a range | `datevalue.ErrInvalid` |
| AC-4.3 | Copy Source with `copy_date` true of a Source whose stored date row has a phrase of `MaxPhraseBytes + 1` bytes (written by raw SQL) | Refused `datevalues.invalid`; nothing is written |

## 3. Scope

| In | Covered by |
| --- | --- |
| Migration `000068.sql`: `date_unknown`, `date_supplied` on `sources` with their checks | STEP-1, AC-1.1, T-7 |
| `sources.Source.DateMark`; every read fills it; a date row that is gone reads with no supplied mark | STEP-2, AC-1.8, T-2, T-8 |
| `sources.SetDate` takes the mark: validate, store in one statement with the date id, one update change | STEP-2, AC-1.1 – AC-1.7, AC-3.1 – AC-3.3 |
| `sources.Delete`'s change carries a set mark | STEP-2, AC-3.4 |
| Copy Source carries the mark with the date tick | STEP-3, AC-2.1 – AC-2.3 |
| `datevalue.MaxPhraseBytes` and its check in `Validate` | STEP-4, AC-4.1 – AC-4.3 |
| Proto: `SetSourceDateRequest.mark`, `Source.date_mark`; the handler | STEP-5, AC-1.1 – AC-1.8 |
| Docs: `source-layer-data-model.md`, `source-provenance-date.md`, `structured-date-model.md`, `add-date-value`, map row, `completed.md`, version | STEP-6 |

| Out | Home |
| --- | --- |
| The date dialog's No date and Supplied, the header's display, the needed flag; Swift sending and reading `date_mark` | S15-42 |
| Rendering "n.d." and "[1880]" | S15-16 |
| The Source date's requirement on the Source workspace read | S15-38 |
| The printed page's mark | S15-44 |
| A move carrying the Source date's mark | not planned (a move changes an Artifact's `source_id`; the Source's own date does not move) |
| An unknown Source sorting apart from undated ones in the Sources list | not planned (rule "The Source date is one optional DateValue": undated last; unknown has no date) |
| A cap on other `date_values` text columns (`start_tz`, `end_tz`, `calendar`) | not planned (the S15-32 finding names the phrase only) |
| An `EngineErrorCode` case for `valuemark.invalid` | S15-41 (its row places the message; S15-42 reuses it) |

## 4. Current state

| Area | Where | Today |
| --- | --- | --- |
| Mark type | `core/valuemark/valuemark.go` `Mark`, `Validate(m Mark, hasValue bool) error`, `ErrInvalid` (code `valuemark.invalid`) | Used by `sourcemetadata` (S15-37); not by the Source date |
| Mark converters | `api/ffi/handlers/value_mark.go` `valueMarkProto`, `parseValueMark` | Written for this PR to reuse (S15-37 D-11); called from `metadata.go` only |
| Mark copy in the app | `macos/App/Platform/L10n.swift` `L10n.Errors.valueMarkInvalid` | Exists (S15-37); no Swift change is needed for the error |
| Table | `core/database/migrations/000063.sql` | `sources.date_value_id BLOB REFERENCES date_values(id)` (unique when set), `is_public`. Latest step is `000067.sql` |
| Source type | `core/database/sources/sources.go` `Source` | `DateValueID []byte`, `Date *datevalue.Value`; no mark |
| SQL | same file, `sqlSetDateValue` (`UPDATE sources SET date_value_id = ? WHERE id = ?`), `sqlGet`, `sqlGetByRef`, `sqlList` | Read `date_value_id, is_public`; no mark columns |
| Scans | same file, `scanSource`, `scanSourceList` | Two scans with the same column list; `scanSourceList` adds `HasArtifact` |
| Date fill | same file, `getOne` (one Source), `List` (batched `datevalues.LookupManyTx`) | A `date_value_id` whose row is gone reads as undated (`Date` nil, `DateValueID` kept) |
| Date write | same file, `SetDate(tx, userID, sourceID []byte, date *datevalue.Value) (Source, []rowchange.Change, error)` | `date != nil`: `datevalues.PutTx` (insert or edit in place), then `sqlSetDateValue` and `dateValueChange` when the id changed. `date == nil` with a stored id: `sqlSetDateValue` NULL, `dateValueChange`, `deleteimpact.ReleaseReplaced` of the row. No change → returns `prev` |
| Audit change | same file, `dateValueChange(sourceID, from, to []byte)` | One `source` update change with `date_value_id` only |
| Delete | same file, `Delete`'s change map | Holds `date_value_id` when set; `is_public` always (`boolInt`) |
| Sort key | same file, `DateSortKey` | Absent when `Date` is nil: an unknown Source sorts with the undated ones, which this PR keeps |
| Copy Source | `core/database/sourcecopy/sourcecopy.go` `Draft.Date`, `ReadDraft`, `CreateFromDraft`, `apply` | `ReadDraft` copies `src.Date` without its id; `CreateFromDraft` calls `sources.SetDate` only when `d.Date != nil`; `apply` drops `d.Date` when `!in.Date` |
| Date validation | `core/datevalue/datevalue.go` `Validate` | Checks a phrase only for presence on a phrase-only point; no length bound. Called by `datevalues.PutTx`, `InsertTx`, `UpdateTx` (`core/database/datevalues/datevalues.go`) after `normalize` trims |
| Wire | `api/proto/engine.proto` `SetSourceDateRequest` (next free tag 5), `Source` (next free tag 17), `ValueMark` (S15-37) | No date mark |
| Handler | `api/ffi/handlers/sources.go` `SetSourceDate`, `sourceProto` | Passes `valuecodec.OptionalDateFromProto(req.GetDate())`; `sourceProto` sets `Date` and `DateSortKey`. Every Source reply (`ListSources`, `GetSourceWorkspace`, `CreateSource`, `CopySource`, `UpdateSource`, `SetSourceDate`, `SetSourcePublic`, cover writes) builds through `sourceProto` (directly or via `enrichSourceProto` in `thumbnails.go`) |
| Swift | `macos/App/Platform/GoStore.swift` `setSourceDate`, `FakeStore.swift` `setSourceDate` | Sends no mark; untouched apart from the regenerated `engine.pb.swift` |
| Tests | `core/database/sources/sources_test.go` `TestSourceDate`, `TestSourceDelete`, helper `runSetDate`; `core/database/sourcecopy/sourcecopy_test.go` `TestCopy` (date cases), helper `setDate`; `core/database/audit/scopes_test.go` (calls `sources.SetDate`); `core/datevalue/validate_test.go` `TestValidate`; `api/ffi/handlers/sources_test.go` `TestSetSourceDate`, `TestCopySource`, `TestListSources` | No mark anywhere. Four test call sites of `SetDate` gain the mark argument |

**Precedent.** S15-37 ([#879](https://github.com/Jake-Robins-Studios/provenencia/pull/879)) is the same shape for metadata values: copy its migration (`000067.sql`, `ADD COLUMN` with a check naming the value column), its "no mark on the wire means no mark" rule (D-7 there), its audit shape for the pair (Go `bool`), and its reuse of `valueMarkProto` / `parseValueMark`. S15-02 ([#762](https://github.com/Jake-Robins-Studios/provenencia/pull/762)) wrote `SetDate`; S15-32 ([#778](https://github.com/Jake-Robins-Studios/provenencia/pull/778)) added the Copy Source date tick. Do not copy S15-37's facet release work: the Source row's delete change is built by hand in `sources.Delete`.

## 5. Decisions

| ID | Decision | Why | Rejected |
| --- | --- | --- | --- |
| D-1 | One migration `core/database/migrations/000068.sql` *(new)*, `ALTER TABLE … ADD COLUMN` only: `date_unknown INTEGER NOT NULL DEFAULT 0 CHECK (date_unknown IN (0, 1) AND (date_unknown = 0 OR date_value_id IS NULL))`, then `date_supplied INTEGER NOT NULL DEFAULT 0 CHECK (date_supplied IN (0, 1) AND NOT (date_unknown = 1 AND date_supplied = 1) AND (date_supplied = 0 OR date_value_id IS NOT NULL))` | Map § 6.10 names the columns; the checks are `valuemark.Validate`'s rules on the table, as `000067.sql` does for values (proven on the repo's SQLite there: a column check may name another column, and existing rows pass with the defaults) | A rebuild — not needed for added columns; only the both-flags check — leaves an unknown Source with a date storable by a crafted write |
| D-2 | `sources.Source` gains `DateMark valuemark.Mark`. `sqlGet`, `sqlGetByRef` and `sqlList` select `date_unknown, date_supplied` right after `is_public`; `scanSource` and `scanSourceList` read them | One type for every holder (rule "A value can be marked unknown or supplied"); every read fills it as every read fills `Date` | Two bools on `Source` — the rule names one type |
| D-3 | Every read settles the mark against the date: when `Date` is nil (undated, or its row is gone), `DateMark.Supplied` is false. One helper `settleDateMark(s *Source)` *(new)* in `sources.go`, called by `getOne` after its lookup and by `List` after its batched fill | A dangling `date_value_id` passes D-1's check with `date_supplied` 1, but reads as undated (S15-02's rule); a read must never carry a pair `valuemark.Validate` refuses, so Copy Source (which re-writes through `SetDate`) and the renderer never see "supplied, no date" | Leaving it raw — Copy Source of such a Source would fail `valuemark.invalid`; cleaning the row on read — reads do not write |
| D-4 | `sources.SetDate(tx *database.Tx, userID, sourceID []byte, date *datevalue.Value, mark valuemark.Mark) (Source, []rowchange.Change, error)`. Order: `loadForWrite`; `valuemark.Validate(mark, date != nil)` (refused as the bare `valuemark.ErrInvalid`, no params, before anything is written); then as today for the date row (`datevalues.PutTx` or release); then one statement `sqlSetDate` *(new)* = `UPDATE sources SET date_value_id = ?, date_unknown = ?, date_supplied = ? WHERE id = ?`, run when the id or the mark differs from `prev`. `sqlSetDateValue` is deleted. On the clear path the statement runs before `ReleaseReplaced`, as today | One statement keeps D-1's checks true at every step (setting a date on an unknown Source must clear `date_unknown` in the same `UPDATE`). One write path for date and mark, so the next `SetDate` caller cannot forget the mark. The id-based `date != nil` is "has a value" for a date: `OptionalDateFromProto` already maps a blank kind to nil | A separate `SetDateMark` write — two writes for one control in S15-42 and a window where the checks fail; params on the error — the date has one control, nothing to place |
| D-5 | `dateValueChange` is replaced by `dateChange(sourceID []byte, prevID, nextID []byte, prevMark, nextMark valuemark.Mark) *rowchange.Change` *(new)*: one `source` update change holding `date_value_id` {`UUIDJSON` old → new} when the ids differ, `date_unknown` {old → new} and `date_supplied` {old → new} as Go `bool` each only when it differs; nil when nothing differs. Change order stays: `date_value` create or update, then `source`; on clear, `source`, then `date_value` delete | The audit records the mark "as part of the value" (map § 6.10) on the row that holds it; Go `bool` is the pair's audit shape S15-37 set (`is_unknown`/`is_supplied`), so a history reader sees one shape for the mark everywhere. Only the keys that differ, as `SetCover` does | `boolInt` like `is_public` — a second audit shape for the same pair; always both keys — `sources` update changes carry only what changed |
| D-6 | No mark on the wire means no mark: `SetSourceDateRequest.mark` absent is `valuemark.Mark{}`, and a write without a mark over a marked Source clears the mark | S15-37 D-7's rule, one meaning per write. Today's app sends no mark and cannot create one, so nothing it saves today loses a mark; S15-42 sends the mark with every date write | "Absent keeps the stored mark" — a second meaning for the same field on the wire |
| D-7 | `sources.Delete`'s change map gains `date_unknown` {true → nil} when `existing.DateMark.Unknown`, and `date_supplied` {true → nil} when `existing.DateMark.Supplied`, Go `bool`; nothing when false | `Delete` already records only the set optional columns (`description`, `date_value_id`); the mark follows it | Always both keys — differs from the rest of this hand-built map |
| D-8 | Copy Source: `sourcecopy.Draft` gains `DateMark valuemark.Mark`; `ReadDraft` sets it from `src.DateMark` (already settled by D-3); `apply` zeroes it when `!in.Date`; `CreateFromDraft` calls `sources.SetDate(tx, userID, src.ID, d.Date, d.DateMark)` when `d.Date != nil || d.DateMark != (valuemark.Mark{})` | Map scope: "Copy Source carries them with the date when its Published date tick is on". The tick is the one choice for the date, and the mark is part of the date | A separate tick for the mark — the Copy form has one Published date tick (S15-D13) |
| D-9 | `core/datevalue`: `const MaxPhraseBytes = 4096` *(new)*, exported, documented as one high cap far above any real phrase; `Validate` returns `ErrInvalid` when `len(v.Phrase) > MaxPhraseBytes`, first, for every kind | Map scope "one high total cap on `Phrase`"; the repo's rule for costs only a crafted catalog reaches is one high cap, not a design (S15-14 `MaxRenderedBytes`, S15-15 `MaxFormatBytes` = 4096). `Validate` is the one gate every date write passes (`PutTx`, `InsertTx`, `UpdateTx`), so Copy Source's re-insert is refused as AC-4.3 says. Reads do not validate, so a stored long phrase still reads | A cap in `sources.SetDate` only — Observations' dates would stay unbounded; a smaller cap such as `namevalue.MaxPartBytes` (1024) — a long dual-dating phrase could get close, and a cap is not a product limit |
| D-10 | Proto: `SetSourceDateRequest`: `ValueMark mark = 5;` (comment: absent is no mark; unknown needs no date, supplied needs one). `Source`: `ValueMark date_mark = 17;` (absent for no mark). `sourceProto` sets `DateMark: valueMarkProto(s.DateMark)`; `SetSourceDate` passes `parseValueMark(req.GetMark())` | S15-37 D-8 and D-11 made one message and one converter pair for this; every Source reply goes through `sourceProto` | A new message — the rule names one |
| D-11 | No Swift change beyond the regenerated `macos/App/Platform/Generated/engine.pb.swift`. `GoStore.setSourceDate` and `FakeStore.setSourceDate` keep their signatures | No view sets or shows the mark here (Out → S15-42); the error copy exists (S15-37) | Threading the mark through the stores now — S15-42's work, gated by S15-D23 |

**Rules this plan bends.** None.

## 6. Design

### Codebase fit

| New *(this PR adds)* | Kind | Closest existing | Why not reuse or extend it |
| --- | --- | --- | --- |
| `000068.sql` *(new)* | migration | `000067.sql` | Same pattern (additive `ALTER TABLE` with checks) |
| `Source.DateMark` *(new field)* | field | `valuemark.Mark`, `sourcemetadata.Row.Mark` | Reuses the type |
| `settleDateMark` *(new)* | func | the date fill in `getOne` and `List` | Both fills call it; one rule (D-3) |
| `SetDate`'s `mark` parameter | param | `SetDate` | Extends the one date write |
| `sqlSetDate` *(new)* | SQL | `sqlSetDateValue` | Replaces it (D-4) |
| `dateChange` *(new)* | func | `dateValueChange` | Replaces it (D-5); searched `rg -n "dateValueChange" core`: only `sources.go` |
| `Draft.DateMark` *(new field)* | field | `Draft.Date` | Rides the same tick |
| `datevalue.MaxPhraseBytes` *(new)* | const | `citationformat.MaxFormatBytes`, `namevalue.MaxPartBytes` | Same "one high cap" pattern in the package that owns the value |
| `SetSourceDateRequest.mark`, `Source.date_mark` | proto fields | `ValueMark` (S15-37) | Reuses the message |
| Test cases T-1 – T-8 | test | the named existing tests | New cases go in the existing functions where they cover the same write; one new function `TestSourceDateMarks` holds the mark table |

**Builds on.** `core/valuemark` (S15-14); S15-37's `ValueMark` and `api/ffi/handlers/value_mark.go`; S15-02's `SetDate` and its release through `deleteimpact.ReleaseReplaced`; S15-32's Copy Source date tick; `writes.Run` recording returned changes (no new effect: the entity type `source` is unchanged).
**Deletes.** `sqlSetDateValue` and `dateValueChange` (D-4, D-5). `core/database/sources/sources.go`'s two scans keep their shape; no other code becomes dead.
**Next adds.** S15-16's resolver reads `Source.DateMark` with `Source.Date` (unknown → "n.d.", supplied → brackets). S15-42 sends `SetSourceDateRequest.mark` from the date dialog and reads `Source.date_mark` in the header, reusing S15-41's control. S15-38's Source date requirement counts an unknown date as an answer. S15-44 puts the same pair in the locator.

### Reach

| New path or state | Destination | Checked: resets on the new id · handles a missing referent · shows the state |
| --- | --- | --- |
| A Source with `date_unknown` 1 and no date | `DateSortKey` (absent, sorts last as undated); the Sources list and Source page (show no date, as undated, until S15-42); `sourcecopy.ReadDraft` (D-8) | Swift does not read `date_mark` yet (D-11) |
| A Source with `date_supplied` 1 | Same readers; the date shows as today | Swift does not read `date_mark` yet |
| A supplied Source whose date row is gone (crafted or FK-off) | Every read (D-3) | Reads undated, no mark; T-8 |

### Scale

At the map's Scale (a census Source with 60 graphs and 60 Artifacts; the Sources list): no query is added. Each Source read selects two more integer columns; `SetDate` runs at most the same statements as today (one `UPDATE` replaces one). No cache key, signal or invalidation changes: the write keeps entity type `source` and its Source scope.

### Edges

- **Assumptions.** `SetDate` assumes "unchanged" means the same date row and id (D-4 adds the mark). `List` and `getOne` assume a dangling id reads undated (D-3 extends it to the mark). `DateSortKey` assumes no date means undated (an unknown Source has no date, so it sorts last). Tests T-2, T-8.
- **Neighbors.** Unmarked undated → unknown: one source change, no date row (AC-1.1). Dated → unknown: release (AC-1.2). Unknown → dated supplied (AC-1.3). Supplied → same date, no mark (AC-1.5). A blank-kind date with `unknown` is unknown (the blank kind is nil, T-6). Unknown → no date, no mark (AC-1.7).
- **Removed inputs.** Clearing the date to unknown releases the date row with its delete change (AC-3.2). Deleting the Source records its mark (AC-3.4). The date tick off drops the mark from a copy (AC-2.3).
- **Real data.** None — no table, seed or configuration drives a rule here.
- **Untrusted size.** A date row read from a crafted catalog: its `phrase` is bounded by D-9 before Copy Source writes it again (AC-4.3). The mark is two integers bounded by D-1's checks; the schema hash refuses a catalog whose `sources` table differs.

### Schema

Migration `core/database/migrations/000068.sql` *(new)*:

```sql
-- S15-43: the Source date can be marked unknown or supplied (core/valuemark;
-- map § 6.10). Unknown means no date_value_id.
ALTER TABLE sources ADD COLUMN date_unknown INTEGER NOT NULL DEFAULT 0
	CHECK (date_unknown IN (0, 1) AND (date_unknown = 0 OR date_value_id IS NULL));
ALTER TABLE sources ADD COLUMN date_supplied INTEGER NOT NULL DEFAULT 0
	CHECK (date_supplied IN (0, 1) AND NOT (date_unknown = 1 AND date_supplied = 1)
		AND (date_supplied = 0 OR date_value_id IS NOT NULL));
```

`catalogmodel`: no change (no new table or foreign key; `TestPragmaHonesty` stays green). Delete class: unchanged (`sources.date_value_id` stays `BucketOwnedOutbound`). Audit: the `source` entity's changes carry the new columns (D-5, D-7).

### Go core

| Package | Change |
| --- | --- |
| `core/datevalue` | `MaxPhraseBytes` *(new)*; `Validate` checks it first (D-9); the package doc names the cap |
| `core/database/sources` | `Source.DateMark` (D-2); the three SELECTs and two scans; `settleDateMark` (D-3) from `getOne` and `List`; `SetDate`'s `mark` (D-4); `sqlSetDate` replaces `sqlSetDateValue`; `dateChange` replaces `dateValueChange` (D-5); `Delete`'s map (D-7). `SetDate`'s doc comment states the mark rule |
| `core/database/sourcecopy` | `Draft.DateMark`, `ReadDraft`, `apply`, `CreateFromDraft` (D-8); the package doc says the date's mark travels with the date |

Errors: `valuemark.invalid` (no params) → a mark `Validate` refuses, from `SetDate` (and Copy Source never, since reads settle the mark). `datevalues.invalid` → a phrase over the cap, as any invalid date today.

### FFI

`api/proto/engine.proto`: D-10's two fields. Handler `api/ffi/handlers/sources.go`: `SetSourceDate` passes `parseValueMark(req.GetMark())` to `sources.SetDate`; `sourceProto` sets `DateMark`. No new RPC, no `ffi.Call` case. Regenerate with `./scripts/generate-proto.sh`.

### macOS

None — no view changes (D-11). `macos/App/Platform/Generated/engine.pb.swift` is regenerated.

### Strings

None — no new copy; `L10n.Errors.valueMarkInvalid` exists (S15-37).

## 7. Steps

**STEP-1 — The migration**
Files: `core/database/migrations/000068.sql` *(new)*. Skills: `add-catalog-migration`, `add-catalog-model`.
Do: write D-1's DDL. No `-- migrate:` line.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/...` passes (schema hash, `TestPragmaHonesty`, every existing store test).

**STEP-2 — The Source date carries its mark**
Files: `core/database/sources/sources.go`, `sources_test.go`, `core/database/sourcecopy/sourcecopy.go` (the one `SetDate` call passes `valuemark.Mark{}` in this step), `core/database/sourcecopy/sourcecopy_test.go` (helper `setDate` passes `valuemark.Mark{}`), `core/database/audit/scopes_test.go`, `api/ffi/handlers/sources.go` (passes `valuemark.Mark{}` in this step). Skills: `add-catalog-query`, `add-date-value`, `add-audit-scope`.
Do: D-2 – D-5, D-7. `runSetDate` in `sources_test.go` gains a `mark valuemark.Mark` parameter; existing callers pass the zero mark; nothing else in existing tests changes. Add T-2, T-3, T-7, T-8.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/... ./api/...` passes.

**STEP-3 — Copy Source keeps the date's mark**
Files: `core/database/sourcecopy/sourcecopy.go`, `sourcecopy_test.go`.
Do: D-8. Add T-4.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/database/sourcecopy/...` passes.

**STEP-4 — A date phrase has one high cap**
Files: `core/datevalue/datevalue.go`, `core/datevalue/validate_test.go`, `core/database/sourcecopy/sourcecopy_test.go`. Skill: `add-date-value`.
Do: D-9. Add T-1 and T-5.
Check: `CGO_ENABLED=1 go test -tags fts5 ./core/...` passes.

**STEP-5 — The wire**
Files: `api/proto/engine.proto`, regenerated `api/proto/engine/engine.pb.go` and `macos/App/Platform/Generated/engine.pb.swift`, `api/ffi/handlers/sources.go`, `api/ffi/handlers/sources_test.go`. Skills: `add-ffi-handler`, `use-catalog-session`.
Do: D-10. Run `./scripts/generate-proto.sh` (needs `protoc`, `protoc-gen-go` and `protoc-gen-swift`). Never hand-edit `engine.pb.go` or `engine.pb.swift`. Add T-6.
Check: `CGO_ENABLED=1 go test -tags fts5 ./api/...` passes; `git diff --stat` shows both generated files changed; the Xcode build in `scripts/check-pr.sh` passes with no Swift warning.

**STEP-6 — Docs and version**
Files: `docs/source-layer-data-model.md` (§ 5 `sources` DDL gains the two columns; the `date_value_id` paragraph says the date can be marked unknown (no date row) or supplied, with D-1's rules, and that Copy Source carries the mark with the date tick), `docs/deployment-plan/spike-15/source-provenance-date.md` (one line under "What this idea still owns": the date can be marked unknown or supplied, S15-43), `docs/structured-date-model.md` § 3.2 (the phrase cap), `.agents/skills/add-date-value/SKILL.md` (the phrase rule line names `MaxPhraseBytes`), `docs/deployment-plan/spike-15/deployment-plan.md` (map row status), `docs/deployment-plan/spike-15/completed.md`, this plan (status, Landed note), `VERSION`, `core/version.go`, `MARKETING_VERSION` lines in `macos/Provenencia.xcodeproj/project.pbxproj`.
Do: per the Definition of done.
Check: links resolve; `scripts/check-pr.sh` prints `check-pr: PASS`.

Commits: one per behavior. The subject is one full imperative sentence that says what changed for the researcher, ending in a period, like the rest of `git log` ("Store whether a Source's date is unknown or supplied."). No WIP commits.

## 8. Tests

| ID | Layer | File · test | Case: input → expected | Covers |
| --- | --- | --- | --- | --- |
| T-1 | Go | `core/datevalue/validate_test.go` `TestValidate` (new rows) | phrase-only point, phrase `strings.Repeat("a", MaxPhraseBytes)` → valid; `MaxPhraseBytes+1` → `ErrInvalid`; point year 1880 with an over-cap phrase → `ErrInvalid`; range 1880–1890 with an over-cap phrase → `ErrInvalid` | AC-4.1, AC-4.2, D-9 |
| T-2 | Go | `core/database/sources/sources_test.go` `TestSourceDateMarks` *(new)*, a table of steps on one Source through `runSetDate` capturing changes | undated → (nil, unknown) → `DateMark{Unknown}`, `Date` nil, no `date_values` row, one `source` change `date_unknown` {false → true} only; same again → no changes; unknown → (ABT 1880, supplied) → date row created, `date_value` create then `source` change with `date_value_id`, `date_unknown` {true → false}, `date_supplied` {false → true}; same again → no changes; → (ABT 1880, no mark) → same date id, one `source` change `date_supplied` {true → false}; → (nil, unknown) → `source` change `date_value_id` {id → nil} and `date_unknown` {false → true}, then `date_value` delete; → (nil, no mark) → `date_unknown` {true → false}; refused: (1880, unknown), (nil, supplied), (nil, unknown+supplied) → `errors.Is(err, valuemark.ErrInvalid)`, stored date and mark unchanged; `Get` and `List` read each stored mark | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.7, AC-3.1, AC-3.2, AC-3.3, D-4, D-5 |
| T-3 | Go | same file, `TestSourceDelete` (new cases) | delete an unknown Source → `source` delete change holds `date_unknown` {true → nil}, no `date_supplied`; delete a supplied dated Source → `date_supplied` {true → nil} and `date_value_id`; an unmarked Source → neither key | AC-3.4, D-7 |
| T-4 | Go | `core/database/sourcecopy/sourcecopy_test.go` `TestCopy` (new cases beside the date cases) | tick on, original unknown → copy `DateMark{Unknown}`, no date, no new `date_values` row; tick on, original supplied ABT 1880 → copy supplied with its own row equal to the original's; tick off, each → copy undated, zero mark | AC-2.1, AC-2.2, AC-2.3, D-8 |
| T-5 | Go | same file, `TestCopy` (new case) | original's date row phrase set by raw `UPDATE date_values SET phrase = ?` to `MaxPhraseBytes+1` bytes; copy with the tick on → `errors.Is(err, datevalue.ErrInvalid)`, source count unchanged | AC-4.3, D-9 |
| T-6 | Go | `api/ffi/handlers/sources_test.go` `TestSetSourceDate` (new subtest "marks") | `SetSourceDate` no date, `Mark{Unknown}` → `Source.date_mark.unknown`, no `date`, no `date_sort_key`; `Date{Kind: " "}` with `Mark{Unknown}` → unknown; `pointDate(1880,0,0)` with `Mark{Supplied}` → `date_mark.supplied`, `date_sort_key` set; `GetSourceWorkspace` and `ListSources` → same `date_mark`; repeat → `effects.revision` 0; date with `Mark{Unknown}` → error code `valuemark.invalid`; no mark over supplied → `date_mark` nil | AC-1.1, AC-1.3, AC-1.4, AC-1.5, AC-1.6, AC-1.8, D-6, D-10 |
| T-7 | Go | `core/database/sources/sources_test.go` `TestSourceDateMarks` (case "the table refuses a bad pair") | raw `UPDATE sources SET date_unknown = 1` on a dated Source; `SET date_supplied = 1` on an undated Source; `SET date_unknown = 1, date_supplied = 1` on an undated Source → each a constraint error | D-1 |
| T-8 | Go | same file, `TestSourceDateMarks` (case "a supplied date whose row is gone reads undated") | supplied dated Source, its `date_values` row deleted with foreign keys off (as `TestSourceDate` "dangling date row reads undated") → `Get` and `List` read `Date` nil and a zero `DateMark`; `runSetDate(…, YMD(1900), Mark{Supplied})` then succeeds | D-3 |

Must stay green: everything `scripts/check-pr.sh` runs. Most likely to break: `sources_test.go` and `sourcecopy_test.go` cases that compare the `source` change's `Fields` after a date write; `core/database/audit/scopes_test.go` (calls `SetDate`).

## 9. Definition of done

```
- [ ] Every AC in §2 is true: test name or manual check line for each
- [ ] Every T-# in §8 exists and passes
- [ ] scripts/check-pr.sh prints check-pr: PASS (gofmt, go vet, go test, Xcode tests with no Swift warning, catalog and plan-doc checks)
- [ ] No Out line was implemented; no code outside §4 / §6 was refactored
- [ ] New user-facing copy is in L10n + Localizable.xcstrings; no stale strings left — n/a, no new copy
- [ ] Sweep: each renamed or deleted name `rg`'d by its old, qualified name across `.agents/`, `.cursor/rules/`, `docs/*.md` and `L10n.swift` with no hit left (`sqlSetDateValue`, `dateValueChange`); `scripts/check-guidance-names.py` passes (check-pr runs it)
- [ ] Every row of **Rules this plan bends** has the user's answer, and its rule is updated — n/a, none
- [ ] UI matches the brief inventory; no new kit primitive unless the brief marks it New — n/a, no chrome
- [ ] Version bump as the header says (VERSION, core/version.go, MARKETING_VERSION together)
- [ ] This plan: Status → Landed in #N (date); a Landed note lists every difference from the plan
- [ ] deployment-plan.md: map row status; completed.md: one short paragraph of what shipped
- [ ] Brief moved to design/archive/ and design/README.md updated (if gated) — n/a, not gated
- [ ] Domain docs updated: docs/source-layer-data-model.md § 5, docs/structured-date-model.md § 3.2, source-provenance-date.md, add-date-value skill (STEP-6)
- [ ] PR description: what shipped, AC evidence, deviations, manual check
```

## 10. Manual check

No view shows the date's mark, so the reviewer checks that nothing the app does today changed:

1. Open a project made before this build. It opens (the format step runs); the Source page shows each Source's date as before, and the Sources list sorts by date with undated Sources last.
2. On a Source page, set a date, change it, and clear it. Each saves as before.
3. Copy a dated Source with the Published date tick on, then with it off. The copy is dated, then undated.

## 11. Risks and stop conditions

| Risk | Mitigation |
| --- | --- |
| An app date edit clears a mark | No app write can create a mark before S15-42, which sends it with every date write (D-6) |
| A real phrase hits the cap | 4096 bytes is far above any dating phrase; the cap is a crafted-catalog bound (D-9) |
| The clear-to-unknown order trips D-1's check | One `UPDATE` sets the id and the mark together (D-4); T-2 walks every transition |

**Stop and report if:**

- `protoc`, `protoc-gen-go` or `protoc-gen-swift` is missing, or `xcodebuild` cannot run (not on macOS): stop after STEP-4 and report; STEP-5 runs on a Mac. Never hand-write generated code.
- `000068.sql` is taken on `main` (another PR added a step): use the next number only if nothing else in that step touches `sources`; otherwise report.
- `ADD COLUMN` with D-1's checks fails on the repo's SQLite build (`go test` shows a migrate error naming the CHECK).
- `rg -n "SetDate\(" core api` lists a non-test caller other than `sourcecopy.go` and `api/ffi/handlers/sources.go`.
- A `writes.Run` effect or audit scope test fails because a `source` change now carries a column it does not expect (`core/database/effects`, `core/database/audit`): report the test; do not add an effect entry.
- An existing test fails on the phrase cap with a phrase it wrote on purpose (not a crafted one): report the test and its phrase length.
- Swift code fails to build against the regenerated `engine.pb.swift`.

## 12. Open questions

None.

## 13. PR

**Title:** S15-43 — The Source date can be marked unknown or supplied
**Body:** objective in one sentence; what shipped against each US; AC evidence; deviations from the plan; manual check; `Plan: docs/deployment-plan/spike-15/prs/S15-43-source-date-marks.md`.
