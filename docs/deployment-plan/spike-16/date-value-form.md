# The date form

**Batch 9 design** (user, 2026-11-28). Opened as an idea file during S16-73's review and moved into the spike when the user scheduled it. The PR is [S16-83](deployment-plan.md#s16-83--the-date-form-is-smaller-and-keyboard-first) and its brief is S16-D20. The rules that bind it are the map's Batch 9 working rules.

The shared date form is `DateValueEditorForm` and `DateValueDraft`, and `SourceDateEditor` adds Reads as under it. Every host draws it: the Source date dialog, Add Source, the Copy sheet from S16-74, and the observation dates in the Citation composer. So a change here lands in all of them.

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

## A repeated letter walks a select's matches

`PVTypeSelectMatcher` (`PVFloatingMenuSelection.swift`) appends every key that comes within 0.8 s of the last. So pressing J twice quickly builds `jj`, and that matches nothing. The Month select stays on January, and only a pause between presses walks on to June. macOS's own pop-up buttons walk a repeated letter's matches. The fix is in the matcher: a buffer that is one character repeated searches for that single character, starting past the current row. Every select, menu, list and table that uses the matcher gets it. This is a kit fix that rides with this PR because the user asked for one PR (2026-11-28).

## Tab starts at Year

Most of the time a researcher tabs into the date and types it. Sometimes they go back to switch Single date to Between two bounds, or to set About, Before or After.

The loop the user chose (2026-11-28):

1. Tab into the form lands on Year.
2. Tab goes on to Month and Day, then the time fields when they show, then leaves the form.
3. Shift-Tab from Year goes to the qualifier (on a Single date), then to Kind.
4. Tab from Kind comes back to Year.

Today the system order decides. Without Full Keyboard Access, Kind, the chips and the links are not Tab stops at all. With it, Kind and the qualifier come before Year. The form needs its own loop, through the kit's field focus (`PVFieldFocus`, and `PVSegmentedControl`'s focus target).

**Still open for the plan:**

- **The end side of a range:** where its Year, Month and Day sit in the loop. Straight after the start side's Day is the natural answer.
- **The links:** whether Add time and Calendar and phrase are Tab stops, and where.

## Remove time clears the time, or keeps it

S16-73 renamed the time link from "Hide time" to "Remove time". It clears that side's hour, minute, second, millisecond and time zone (`DateValueDraft.hideTime(start:)`). Before, the link only hid the fields and left the values in the draft. A hidden time zone could then keep a date from saving, and the message pointed at a field you couldn't see.

The other way out is to keep the values, and to show the time fields whenever they hold anything, so the link only hides an empty block. Then a researcher can't lose a saved 09:30 by tidying the form. The choice applies to every host, and it is the user's to make in S16-83's plan. (From S16-73 round 3, UX-1 and UX-2.)

## The range message shows before the second bound is typed

On Between two bounds, as soon as the earliest year is typed, the form shows "Add the latest bound, or choose Single date." That is before the researcher has had a chance to type the latest bound. The line is true, but it comes early on the usual path. It could wait until the latest bound's fields lose focus, or until Create is pressed. `DateValueDraft.unsavableError` decides the text; the timing belongs to the form. The condensed layout and the new Tab loop change where focus goes, so the timing is decided in the same plan. (From S16-73's review, UX-5.)
