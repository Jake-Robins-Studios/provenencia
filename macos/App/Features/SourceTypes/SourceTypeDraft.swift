import Foundation

/// The values of a Source type being written: the Add dialog's and the type page's Details form's
/// in-progress label, description and icon.
struct SourceTypeDraft: Equatable {
    var label: String
    var description: String
    var iconKey: String = PVMarkKey.defaultTypeMark.rawValue

    var trimmedLabel: String { label.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The key the engine mints from the label.
    var key: String { FieldSlug.kebab(trimmedLabel) }

    /// Why the label cannot be saved, or nil. One rule for the Add dialog and the type page.
    var labelError: String? {
        if trimmedLabel.isEmpty { return L10n.string(L10n.SourceTypes.errorLabelRequired) }
        if key.isEmpty { return L10n.string(L10n.SourceTypes.errorUnslugifiable) }
        return nil
    }
}

/// The Label's error as the researcher types and as a write answers: the one rule for the Add
/// type dialog, the type page's Details form and the Copy type sheet. `error` is shown under
/// Label; `announces` is true only for the engine's refusal of a duplicate key, which the field
/// speaks (an error that follows typing is not announced).
struct SourceTypeLabelCheck: Equatable {
    private(set) var error: String?
    private(set) var announces = false

    /// Sets the label and shows or clears its error as the researcher types, as
    /// `SourceTitleTypeFields` does. Does nothing when the label is unchanged.
    mutating func edit(_ new: String, in draft: inout SourceTypeDraft) {
        guard new != draft.label else { return }
        draft.label = new
        error = draft.labelError
        announces = false
    }

    /// Shows the draft's label error, or clears it, and answers whether the label can be saved.
    mutating func validate(_ draft: SourceTypeDraft) -> Bool {
        error = draft.labelError
        announces = false
        return error == nil
    }

    /// Takes the engine's duplicate-key refusal as the Label's error and answers true; any other
    /// error is not the label's and answers false.
    mutating func refuse(_ failure: Error) -> Bool {
        guard (failure as? CoreInvokeError)?.engineCode == .sourceTypeDuplicateKey else { return false }
        error = L10n.Errors.message(for: failure)
        announces = true
        return true
    }

    mutating func clear() {
        error = nil
        announces = false
    }
}
