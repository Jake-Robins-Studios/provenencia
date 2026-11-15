import Foundation
@testable import Provenencia

/// An Artifact row for tests. `ref` defaults to `ART-` plus the `id`, and `label`
/// to the `id`; a file-bearing Artifact passes `fileID` and `file` together.
func catalogArtifact(
    _ id: String,
    ref: String? = nil,
    sourceID: String = "s1",
    label: String? = nil,
    description: String = "",
    fileID: String = "",
    file: CatalogFileRef? = nil
) -> CatalogArtifact {
    CatalogArtifact(
        id: id, ref: ref ?? "ART-\(id)", sourceID: sourceID, fileID: fileID,
        label: label ?? id, description: description, file: file
    )
}

/// A file-bearing image Artifact for tests: ref `ART-<ID>` uppercased, file id
/// `file-<id>` unless `fileID` says otherwise, at `objects/<id>.jpg` unless
/// `relPath` does.
func catalogFileArtifact(
    _ id: String,
    ref: String? = nil,
    sourceID: String = "s1",
    label: String? = nil,
    fileID: String? = nil,
    relPath: String? = nil,
    mediaType: String = "image/jpeg"
) -> CatalogArtifact {
    let fileID = fileID ?? "file-\(id)"
    return catalogArtifact(
        id, ref: ref ?? "ART-\(id.uppercased())", sourceID: sourceID, label: label, fileID: fileID,
        file: CatalogFileRef(
            id: fileID, relPath: relPath ?? "objects/\(id).jpg", originalFilename: "\(id).jpg",
            mediaType: mediaType, byteSize: 4_200_000
        )
    )
}

/// A metadata field for tests; `key` defaults to the lowercased `label`.
func catalogMetadataField(
    _ id: String, label: String, key: String? = nil, dataType: String = "text", usedBy: Int = 0
) -> CatalogMetadataField {
    CatalogMetadataField(
        id: id, key: key ?? label.lowercased(), origin: "user", label: label, dataType: dataType,
        description: "", usedBy: usedBy
    )
}

/// A Source type for tests; `key` defaults to the kebab-cased `label`.
func catalogSourceType(
    _ id: String, label: String, key: String? = nil, origin: String, description: String = "", usedBy: Int = 0
) -> CatalogSourceType {
    CatalogSourceType(
        id: id, key: key ?? FieldSlug.kebab(label), origin: origin, label: label, description: description,
        usedBy: usedBy
    )
}

/// A product-seeded Source type for tests (key `book`).
func seededSourceType(id: String = "t1", label: String = "Book", usedBy: Int = 0) -> CatalogSourceType {
    catalogSourceType(
        id, label: label, key: "book", origin: "provenencia", description: "A published monograph.", usedBy: usedBy
    )
}

/// A researcher-made Source type for tests.
func userSourceType(id: String = "t2", label: String = "Family scrapbook", usedBy: Int = 0) -> CatalogSourceType {
    catalogSourceType(id, label: label, origin: "user", description: "Nan's albums.", usedBy: usedBy)
}

/// A plugin's Source type for tests (read only).
func pluginSourceType(id: String = "t3", label: String = "Grave memorial", usedBy: Int = 5) -> CatalogSourceType {
    catalogSourceType(
        id, label: label, key: "grave-memorial", origin: "plugin:findagrave", description: "From the plugin.",
        usedBy: usedBy
    )
}

/// The engine's refusal of a metadata value (`sourcemetadata.invalid`) for tests; the refused
/// value's field id is `params[0]`.
func catalogMetadataRefusal(params: [String] = []) -> CoreInvokeError {
    .coded(status: 1, code: "sourcemetadata.invalid", kind: .user, params: params)
}

/// A metadata row for tests; it holds a value exactly when `value` is not empty.
func catalogMetadataEntry(
    _ field: CatalogMetadataField, _ value: String = "", suggested: Bool = false, order: Int32 = 0
) -> CatalogMetadataEntry {
    CatalogMetadataEntry(
        field: field, valueText: value, hasValue: !value.isEmpty, suggested: suggested, sortOrder: order
    )
}
