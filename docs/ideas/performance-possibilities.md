# Performance possibilities

**Status:** idea only — not roadmapped. Small speed-ups that reviews found in code their PR did not touch. Nothing here is slow enough to notice today; **measure before pulling any of these in.** Person page work has its own file: [`person-page-performance.md`](person-page-performance.md).

## The formats preview picker rebuilds its options on every redraw

The "Preview with" picker in a Source type's formats editor (`SourceTypeFormatsSection.swift`, the `PVComboBox` in the preview field) builds its options inline in `body`: `sources.map { PVComboBoxOption(value: $0.id, label: $0.title, subtext: $0.ref) }`. Every redraw of the section — typing in a format, picking a Source, a preview reply landing — maps every Source of that type again.

The list is only the Sources of one type (`SourceTypeFormatsModel.previewSources`, from the cached `.sourcesOfType` derived value), so it is usually short; the cost shows only when one type holds thousands of Sources.

Fix shape: the one S15-25 used for the Move dialog's target picker (PRF-1). Build the options once per list change through `session.derived`, with `.sourcesOfType(typeID:)` as its input, and have `body` read the cached array. (S15-25 review PRF-1, 2026-11-22)
