# The date form

**Batch 9 design** (user, 2026-11-28); shipped in S16-83 ([#1027](https://github.com/Jake-Robins-Studios/provenencia/pull/1027)). Opened as an idea file during S16-73's review and moved into the spike when the user scheduled it. The PR is [S16-83](deployment-plan.md#s16-83--the-date-form-is-smaller-and-keyboard-first) and its brief is S16-D20. The rules that bind it are the map's Batch 9 working rules.

The shared date form is `DateValueEditorForm` and `DateValueDraft`, and `SourceDateEditor` is the Source date block around it (S16-83 dropped its Reads as card: working rule "The date form shows no Reads as"; the block stays for S15-42's marks control). Every host draws it: the Source date dialog, Add Source, the Copy sheet from S16-74, and the observation dates in the Citation composer. So a change here lands in all of them.

## It takes less space

Today the form stacks these, top to bottom:

- **Kind:** a caption, the segmented Single date / Between two bounds, and for a range an italic gloss.
- **Qualifier:** a caption, then four chips.
- A divider.
- **Each side:** a micro-caps heading with an italic hint ("Leave a part empty when the record does not say"), then Year, Month and Day, each with its own label above. Under them sit the Add time link and, when it is shown, the time block.
- A divider.
- **Calendar and phrase…**, and the two fields it opens.
- **Reads as**, in Add Source and the Source date dialog.

Inline in Add Source this is most of the sheet. In the Source date dialog it is the whole dialog.

S16-D20 draws a condensed form, in its own dialog and inline. Some of the room it could take back:

- Kind and the qualifier share one row.
- The per-section captions go, where the control's own text already says what it is.
- The dividers go.
- The side hint moves to a field hint or a tooltip.
- Add time and Calendar and phrase share one line of links.

Nothing a researcher can set today goes. The board decides the layout, and the plan follows it.

**The board** (agreed 2026-11-28; S16-D20's **Board** line): Kind and the qualifier on one row with no captions, and the range gloss as a caption line under it; no heading on a Single date, and a range's sides labelled in a left column; one row of time fields under each side's Year, Month and Day; no dividers; the hint and Calendar and phrase… on one line under the sides. The dialog is 520 pt.

## A repeated letter walks a select's matches

`PVTypeSelectMatcher` (`PVFloatingMenuSelection.swift`) appends every key that comes within 0.8 s of the last. So pressing J twice quickly builds `jj`, and that matches nothing. The Month select stays on January, and only a pause between presses walks on to June. macOS's own pop-up buttons walk a repeated letter's matches. The fix is in the matcher: a buffer that is one character repeated searches for that single character, starting past the current row. Its three callers get it: `PVSelectSession`, `PVContextMenuKeyboard` and `PVTable`. (The combo box filters typed text instead, and `PVList` has no type-select.) This is a kit fix that rides with this PR because the user asked for one PR (2026-11-28).

## Tab starts at Year

Most of the time a researcher tabs into the date and types it. Sometimes they go back to switch Single date to Between two bounds, or to set About, Before or After.

The loop the user chose (2026-11-28):

1. Tab into the form lands on Year.
2. Tab goes on to Month and Day, then the time fields, then leaves the form.
3. Shift-Tab from Year goes to the qualifier (on a Single date), then to Kind.
4. Tab from Kind comes back to Year.

Today the system order decides. Without Full Keyboard Access, Kind, the chips and the links are not Tab stops at all. With it, Kind and the qualifier come before Year. The form needs its own loop, through the kit's field focus (`PVFieldFocus`, and `PVSegmentedControl`'s focus target).

**How the loop is built** (map review K9-1 – K9-4): one `@FocusState` over every field of the form; a new `PVFieldFocus` operation that replaces a handle's Tab neighbours, so a host's handle becomes the Year entry; the qualifier as a `PVSegmentedControl` like Kind; `PVSegmentedControl` claiming Tab when its handle has neighbours; the field before the form claiming Tab into Year.

**Decided by the board** (2026-11-28): a range runs the earliest side (Year to Time zone), then the latest side in the same order; Calendar and phrase… is one stop after the last Time zone, and when it is open the Calendar select and the Phrase input follow it; then out.

**Still open for the plan:** whether Shift-Tab from Kind goes to the host's previous field.

## The time fields always show

Decided (user, 2026-11-28), to make the form simpler: every side's time fields (Hour, Min, Sec, Ms and Time zone) are always on the form, and the latest side gets the same fields as the earliest. So there is no Add time or Remove time link, and no time value is ever hidden. An empty time field means no time, as an empty day means no day.

This replaces what S16-73 shipped. S16-73 made Remove time clear the time so that a hidden time zone could not keep a date from saving. With nothing hidden, that problem is gone. `DateValueDraft.hideTime(start:)`, the `showStartTime` and `showEndTime` flags, the toggle and its two strings go.

Earlier the same day the user had kept Remove time clearing the time. Showing the time fields all the time replaces that call.

## The latest bound is typed

Today, on Between two bounds, typing the earliest year shows "Add the latest bound, or choose Single date." before the researcher has had a chance to type the latest one (S16-73's review, UX-5).

The user first decided (2026-11-28) that the latest bound would fill itself in from the earliest as it is typed. After the S16-D20 board they dropped it (user, 2026-11-28): with any part of either side allowed to be empty, which fields follow and when they stop is too complex, and a followed month quietly narrows the window. The researcher types the latest bound, switching to Between leaves it empty, and the line shows as S16-73 shipped it. Nothing in `DateValueDraft` tracks typed fields.
