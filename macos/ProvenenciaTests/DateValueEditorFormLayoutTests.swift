import AppKit
import SwiftUI
import Testing
@testable import Provenencia

/// The date form's Kind and qualifier row, measured with the app's real type.
@Suite
@MainActor
struct DateValueEditorFormLayoutTests {
    /// The composer's value box: 480 pt of dialog content less 2 x 14 pt of `inlineValue` padding.
    private let composerFormWidth: CGFloat = 452

    private func width(of control: some View) -> CGFloat {
        NSHostingView(rootView: control).fittingSize.width
    }

    @Test func kindAndQualifierFitTheComposerBox() {
        var maxKind: CGFloat = 0
        for kind in ["point", "range"] {
            var draft = DateValueDraft.empty()
            draft.setKind(kind)
            maxKind = max(maxKind, width(of: DateValueEditorForm(draft: .constant(draft)).kindControl))
        }
        var maxQualifier: CGFloat = 0
        for qualifier in ["", DateQualifier.about, DateQualifier.before, DateQualifier.after] {
            var draft = DateValueDraft.empty()
            draft.qualifier = qualifier
            maxQualifier = max(maxQualifier, width(of: DateValueEditorForm(draft: .constant(draft)).qualifierControl))
        }
        let row = maxKind + DateValueEditorForm.Layout.kindGap + maxQualifier
        #expect(row <= composerFormWidth, "Kind \(maxKind) + gap + qualifier \(maxQualifier) = \(row)")
    }
}
