# Date value form

**Status:** idea only, not on a map. Opened 2026-11-28 from S16-73's review. These are changes to the shared date form (`DateValueEditorForm` and `DateValueDraft`). Every host gets them: Add Source, the Source date dialog and the observation dates in the Citation composer.

## Remove time clears the time, or keeps it

S16-73 renamed the time link from "Hide time" to "Remove time". Pressing it clears that side's hour, minute, second, millisecond and time zone (`DateValueDraft.hideTime(start:)`). Before, the link only hid the fields, and the values stayed in the draft. A hidden time zone could then keep a date from saving, and the message pointed at a field you couldn't see. The other way to fix that is to keep the values and show the time fields whenever they hold anything, so the link only hides an empty block. That way a researcher can't lose a saved 09:30 by tidying the form, and the form needs no "Remove" wording. Pick one for every host. (S16-73 round 3, UX-1 and UX-2)

## The range message shows before the second bound is typed

On Between two bounds, typing the earliest year straight away shows "Add the latest bound, or choose Single date." It shows before the researcher has had a chance to type the latest bound. The line is true, but it shows too early on the usual path. For example, it could wait until the latest bound's fields lose focus, or until Create is pressed. `DateValueDraft.unsavableError` decides the text; the timing belongs to the form. (S16-73 review, UX-5)
