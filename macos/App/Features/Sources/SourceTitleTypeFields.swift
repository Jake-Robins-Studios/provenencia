import SwiftUI

/// The Title and Source type fields shared by Add Source and Copy Source. It
/// owns the one display rule: nothing shows on open; after the first edit by
/// the researcher to either field, both errors follow `draft.validation`. The
/// app's own changes to the draft (a sole type filled in, the Copy prefill)
/// change no error.
struct SourceTitleTypeFields<TypeTrailing: View>: View {
    @Binding var draft: SourcesModel.Draft
    @Binding var titleError: String?
    @Binding var typeError: String?
    let types: [CatalogSourceType]
    let accessibilityIdentifierPrefix: String
    /// A view at the right of the Type row, at its natural width; Type takes the rest.
    private let typeTrailing: TypeTrailing

    init(
        draft: Binding<SourcesModel.Draft>,
        titleError: Binding<String?>,
        typeError: Binding<String?>,
        types: [CatalogSourceType],
        accessibilityIdentifierPrefix: String,
        @ViewBuilder typeTrailing: () -> TypeTrailing
    ) {
        self._draft = draft
        self._titleError = titleError
        self._typeError = typeError
        self.types = types
        self.accessibilityIdentifierPrefix = accessibilityIdentifierPrefix
        self.typeTrailing = typeTrailing()
    }

    var body: some View {
        let options = SourceTypeComboRow.options(for: types)
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            PVField(
                label: L10n.Sources.formTitle,
                error: titleError,
                marker: .required
            ) {
                PVInput(
                    text: Binding(
                        get: { draft.title },
                        set: { new in
                            guard new != draft.title else { return }
                            draft.title = new
                            showErrors()
                        }
                    ),
                    isInvalid: titleError != nil,
                    activateOnAppear: true
                )
                .accessibilityIdentifier("\(accessibilityIdentifierPrefix).title")
            }
            HStack(alignment: .pvFieldControl, spacing: PVSpacing.space7) {
                PVField(
                    label: L10n.Sources.formType,
                    error: typeError,
                    marker: .required
                ) {
                    PVComboBox(
                        selection: Binding(
                            get: { draft.sourceTypeID },
                            set: { new in
                                guard new != draft.sourceTypeID else { return }
                                draft.sourceTypeID = new
                                showErrors()
                            }
                        ),
                        options: options,
                        placeholder: L10n.Sources.typePlaceholder,
                        emptyLabel: options.isEmpty
                            ? L10n.Sources.typePoolEmpty
                            : L10n.Sources.typeNoMatch,
                        isInvalid: typeError != nil,
                        label: L10n.Sources.formType,
                        accessibilityIdentifierPrefix: "\(accessibilityIdentifierPrefix).type"
                    ) { option, query in
                        SourceTypeComboRow(
                            type: types.first { $0.id == option.value },
                            option: option,
                            query: query
                        )
                    }
                }
                    .frame(maxWidth: .infinity)
                typeTrailing
            }
        }
    }

    private func showErrors() {
        titleError = draft.validation.titleError
        typeError = draft.validation.typeError
    }
}

extension SourceTitleTypeFields where TypeTrailing == EmptyView {
    init(
        draft: Binding<SourcesModel.Draft>,
        titleError: Binding<String?>,
        typeError: Binding<String?>,
        types: [CatalogSourceType],
        accessibilityIdentifierPrefix: String
    ) {
        self.init(
            draft: draft,
            titleError: titleError,
            typeError: typeError,
            types: types,
            accessibilityIdentifierPrefix: accessibilityIdentifierPrefix
        ) { EmptyView() }
    }
}
