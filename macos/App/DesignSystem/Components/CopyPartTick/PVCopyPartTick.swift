import SwiftUI

/// One part a Copy form can bring over from the original: a checkbox with the
/// part's name and a hint saying what would be copied. A part the original
/// lacks reads unchecked and disabled, with `absentHint` in place of the hint,
/// whatever the stored choice is, so a hidden tick is never sent. Copy Source
/// and Copy Source type use it for every part.
struct PVCopyPartTick: View {
    let label: LocalizedStringResource
    let hint: String
    /// Replaces `hint` when the original has no such part ("None on this Source").
    let absentHint: String
    @Binding var isChecked: Bool
    let isAvailable: Bool
    /// True while the form saves; an unavailable part is disabled either way.
    let isDisabled: Bool

    var body: some View {
        PVCheckbox(
            verbatim: L10n.string(label),
            description: isAvailable ? hint : absentHint,
            isChecked: Binding(
                get: { isAvailable && isChecked },
                set: { isChecked = $0 }
            ),
            isDisabled: !isAvailable || isDisabled
        )
    }
}
