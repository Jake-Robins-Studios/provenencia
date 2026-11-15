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
