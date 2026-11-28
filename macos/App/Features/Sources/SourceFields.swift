import SwiftUI

/// The Source fields of the Add Source sheet (Copy takes them in S16-74), in order: Title, Type with Private
/// beside it (its help behind an info icon), Description, Published date. The sheet owns the draft, the two field errors and the save; this
/// view draws them. Identifiers are `<prefix>.title`, `.type`, `.date`,
/// `.description`, `.private` and `.privateHelp`. The sheet disables it while it saves (`PVFormDialog` does).
struct SourceFields: View {
    /// The width of the Add Source sheet.
    static let dialogWidth: CGFloat = 560

    @Binding var draft: SourcesModel.Draft
    @Binding var titleError: String?
    @Binding var typeError: String?
    let types: [CatalogSourceType]
    let accessibilityIdentifierPrefix: String

    /// The fields Tab moves between here: Description, then the date's Year. Title and Type stay
    /// outside this order.
    private enum Field: Hashable { case description, date }
    private static let order: [Field] = [.description, .date]
    @FocusState private var focus: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            SourceTitleTypeFields(
                draft: $draft,
                titleError: $titleError,
                typeError: $typeError,
                types: types,
                accessibilityIdentifierPrefix: accessibilityIdentifierPrefix
            ) {
                HStack(spacing: PVSpacing.space3) {
                    PVCheckbox(L10n.Sources.privateSwitch, isChecked: $draft.isPrivate)
                        .accessibilityIdentifier("\(accessibilityIdentifierPrefix).private")
                    PVHelpIcon(
                        icon: .info,
                        label: L10n.Sources.privateHelpLabel,
                        help: L10n.Sources.privateSwitchHelp,
                        cardEdge: .trailing
                    )
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).privateHelp")
                }
                .alignmentGuide(.pvFieldControl) { $0[VerticalAlignment.center] }
            }
            PVField(
                label: L10n.Sources.formDescription,
                hint: L10n.Sources.formDescriptionHint
            ) {
                PVInput(
                    text: $draft.description,
                    focus: PVFieldFocus($focus, equals: .description, in: Self.order)
                )
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).description")
            }
            PVField(
                label: L10n.Sources.formPublishedDate,
                hint: L10n.Sources.formPublishedDateHint,
                error: draft.validation.dateError
            ) {
                SourceDateEditor(
                    draft: $draft.date,
                    accessibilityIdentifierPrefix: "\(accessibilityIdentifierPrefix).date",
                    yearFocus: PVFieldFocus($focus, equals: .date, in: Self.order)
                )
            }
        }
    }
}

#if DEBUG
private struct SourceFieldsPreview: View {
    @State var draft: SourcesModel.Draft
    @State var titleError: String?
    @State var typeError: String?

    init(_ draft: SourcesModel.Draft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        SourceFields(
            draft: $draft,
            titleError: $titleError,
            typeError: $typeError,
            types: [
                CatalogSourceType(
                    id: "census", key: "census", origin: "provenencia", label: "Census",
                    description: "A population count."
                ),
            ],
            accessibilityIdentifierPrefix: "sources.add"
        )
        .padding(PVSpacing.space8)
        .frame(width: SourceFields.dialogWidth)
    }
}

private func previewDraft(_ edit: (inout SourcesModel.Draft) -> Void = { _ in }) -> SourcesModel.Draft {
    var draft = SourcesModel.Draft(sourceTypeID: "", title: "")
    edit(&draft)
    return draft
}

#Preview("Blank: the board's frame 1") {
    SourceFieldsPreview(previewDraft())
}

#Preview("Filled, Private: frame 2") {
    SourceFieldsPreview(previewDraft {
        $0.title = "1880 census, Ward 4, Altona"
        $0.sourceTypeID = "census"
        $0.description = "Enumeration district 12"
        $0.isPrivate = true
        $0.date.startYear = 1880
        $0.date.startMonth = 6
        $0.date.startDay = 1
    })
}

#Preview("Month 13: frame 4") {
    SourceFieldsPreview(previewDraft {
        $0.title = "1880 census"
        $0.sourceTypeID = "census"
        $0.date.startYear = 1880
        $0.date.startMonth = 13
    })
}

#Preview("Incomplete date: frame 5") {
    SourceFieldsPreview(previewDraft {
        $0.title = "1880 census"
        $0.sourceTypeID = "census"
        $0.date.phrase = "Spring 1880"
        $0.date.startTZ = "America/Chicago"
        $0.date.showAdvanced = true
    })
}
#endif
