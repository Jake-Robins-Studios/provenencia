# Citation composer follow-ups

**Status:** idea / bugs, not scheduled. Dogfood 2026-10-15. Field hints from transcription are under [`evidence-graph-structure-shortcuts.md`](evidence-graph-structure-shortcuts.md). Depiction page-change confirm is under [`depictions-and-likenesses.md`](depictions-and-likenesses.md).

## Bridge mode subject selectors — primary subjects only

While creating a bridge observation, the two subject selectors list existing bridge subjects (relationships, participations, locations, place links) alongside primary subjects. A bridge is between two primary subjects, so picking a bridge there can only end in a refusal.

**Wanted:** In bridge mode the subject selectors offer primary subjects only; bridge subjects are excluded (or shown disabled with a reason).

**Shape:**

- `CitationComposerVocabulary.make` builds one `graphSubjects` list from `snapshot.subjects` **and** `snapshot.bridges`, then one `subjectComboOptions` menu for every observation row — that design leaks bridges into bridge mode.
- `CitationComposerModel.subjectOptions` returns that single list; there is no mode-specific variant.
- Bridge end pickers and the property-mode subject picker both pass `model.subjectOptions`. A fix is a filtered list for the bridge pickers: `graphSubjects` whose `typeKey` is not an `EvidenceBridgeKind` raw value. Whether "New \<type\>…" rows belong in bridge mode is a separate product call.
- `resolvePair` already refuses a bridge on either end (`refusedPairTitle` / `refusedPairBody`); keep that as a backstop after filtering the menu.
- Tests: a "bridge mode options exclude bridges" case beside the existing citation composer vocabulary / authoring tests.

## Citation preview in the new observation modal is cropped

The citation preview under the citation picker is cropped after roughly eight lines. The rest of the transcription is cut off and there is no way to see it from the modal.

**Wanted:** A bounded scroll region (or expand / "show more") so the full citation is readable while the observation is filled in. Letting the preview grow unbounded would push the whole dialog taller.

**Shape:**

- `CitationComposerAuthoringBox.citationReading` renders `model.transcription` as `Text` with `.lineLimit(8)` and `.fixedSize(horizontal: false, vertical: true)` inside a sunken bordered box — the eight-line cap is the crop.
- The block sits under the citation `PVSelect` in a `.pvFormDialog(width: 520, …)`.
- `PVFormDialogContent` wraps the form in a `PVPanel` with no internal scroll; check panel behavior when the form outgrows the window before choosing expand vs scroll.

## Saved lines rebuild on every keystroke

`CitationComposerSubjectGroups`' body reads the computed `subjectGroups` twice and also reads `model.authoring`, so every keystroke in a new-observation dialog rebuilds the saved lines and calls `ObservationValueDisplay.string` per row twice; a date row builds `DateFormatter`s on each call. Move the list into a child view that reads only `model.subjectGroups`, and bind the value once per body. No worse than before S14-37; untimed. Touch it when a composer list change next opens that file. (S14-37 review PRF-1)

## Observation rows keep a draft state only one throwaway row uses

`ObservationRows.rows` holds only rows from `ObservationRow.loaded(from:)`, so `ObservationRowState.draft`, the optional `baseline` and their branches in `canSave`, `deriveState` and `revert` serve only the throwaway row `savePropertyDraft` builds to call `asDraft`. Make `asDraft` a function of `ObservationRowValues`, then drop the state and make `baseline` non-optional. (S14-37 review MNT-2)

## A citation preview beside each metadata board

Parked from Spike 15 (S15-65, descoped 2026-11-22: "skip the previews for now"). The Artifact sheet, the graph form and the composer would show the full citation their owner's values give, re-rendered as the draft changes, so a researcher sees how an inherited or overridden value prints.

**Shape:** one render request (`RenderCitationPreview`) whose `sourcemetadata.CitationValues` takes the unsaved draft's rows at the owner's level; no second resolver. One render per pause in typing. The Source page's own preview was refused 2026-11-13; reopening this idea should ask about it again. Brief S15-D34 was never written.
