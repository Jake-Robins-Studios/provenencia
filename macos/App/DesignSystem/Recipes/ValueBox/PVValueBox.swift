import SwiftUI

/// A structured value's form set inside a form: a sunken card, full width, with the inline
/// value's padding. The Citation composer's date, name and term values and Add Source's Published date
/// draw it, so a form embedded in another form looks the same in every host.
struct PVValueBox<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        PVCard(
            tone: .sunken,
            insets: EdgeInsets(
                top: PVSpacing.space5,
                leading: 14,
                bottom: PVSpacing.space5,
                trailing: 14
            )
        ) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
