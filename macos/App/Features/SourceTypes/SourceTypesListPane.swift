import SwiftUI

/// The Source types list's table (S15-D28 TL-1 – TL-W2): the shared
/// `VocabularyListPane` around this destination's columns — label with origin
/// pill, Description once the table is 1200pt wide, mono key, suggested-field count, usage — sortable
/// by all but Description.
struct SourceTypesListPane: View {
    @Bindable var model: SourceTypesModel
    @Environment(WorkspaceNavigation.self) private var navigation
    /// The row the table highlights; arrow keys move it without leaving the list.
    @State private var highlighted: String?

    /// Column widths live only here; `PVTable` shares them between the
    /// header and every row, so they are never restated.
    private static let keyColumnWidth: CGFloat = 160
    private static let fieldsColumnWidth: CGFloat = 132
    static let usedByColumnWidth: CGFloat = 120
    /// A column that does not sort takes a pane constant, not a `SortColumn` raw value.
    static let descriptionColumnID = "description"
    /// Description shows from this table width (user, 2026-11-15), at any width class.
    static let descriptionMinTableWidth: CGFloat = 1200
    /// User, 2026-11-15: labels are short, so Description takes twice Label's share (about 220 /
    /// 440pt at a 1200pt table).
    static let descriptionFlex: CGFloat = 2

    var body: some View {
        VocabularyListPane(
            totalCount: model.types.count,
            rows: model.visibleTypes,
            isLoading: model.isLoading,
            columns: Self.columns(),
            selection: $highlighted,
            sort: PVTableSort(
                columnID: model.sortColumn.rawValue,
                direction: model.sortAscending ? .ascending : .descending
            ),
            onSortChange: { model.sortBy($0) },
            strings: VocabularyListStrings(
                tableLabel: L10n.Workspace.sourceTypesTitle,
                emptyGlyph: WorkspaceSection.sourceTypes.glyph,
                emptyTitle: L10n.SourceTypes.emptyProjectTitle,
                emptyBody: L10n.SourceTypes.emptyProjectBody,
                resultLine: { L10n.SourceTypes.resultLine(shown: $0, total: $1) }
            ),
            onActivate: { id in
                navigation.go(to: .sourceTypePage(typeId: id, title: model.types.label(forTypeID: id)))
            },
            identifierPrefix: "sourceTypes"
        )
    }

    /// The columns: Description, between Label and Key, shows once the table is 1200pt wide
    /// (`PVTableColumn.minTableWidth`). Static so the order is testable without a view.
    static func columns() -> [PVTableColumn<CatalogSourceType>] {
        let label = PVTableColumn<CatalogSourceType>(
            id: SourceTypesModel.SortColumn.label.rawValue,
            title: L10n.SourceTypes.columnLabel,
            sortable: true
        ) { type in
            HStack(spacing: PVSpacing.space2) {
                PVMark(
                    PVMarkKey(catalogKey: type.iconKey),
                    size: .inline,
                    decorative: true
                )
                Text(type.label)
                    .font(PVFont.body(size: PVTypeScale.bodySmall))
                    .foregroundStyle(PVColor.textPrimary)
                    .lineLimit(1)
                OriginPill(origin: type.origin)
            }
        }
        let description = PVTableColumn<CatalogSourceType>(
            id: descriptionColumnID,
            title: L10n.SourceTypes.columnDescription,
            minTableWidth: descriptionMinTableWidth,
            flex: descriptionFlex,
            sortable: false
        ) { type in
            Text(type.description)
                .font(PVFont.body(size: PVTypeScale.bodySmall))
                .foregroundStyle(PVColor.textMuted)
                .lineLimit(1)
                .truncationMode(.tail)
                .help(type.description)
        }
        let key = PVTableColumn<CatalogSourceType>(
            id: SourceTypesModel.SortColumn.key.rawValue,
            title: L10n.SourceTypes.columnKey,
            width: keyColumnWidth,
            sortable: true
        ) { type in
            Text(type.key)
                .font(PVFont.mono(size: PVTypeScale.micro))
                .foregroundStyle(PVColor.textMuted)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        let fields = PVTableColumn<CatalogSourceType>(
            id: SourceTypesModel.SortColumn.fields.rawValue,
            title: L10n.SourceTypes.columnFields,
            width: fieldsColumnWidth,
            sortable: true
        ) { type in
            countCell(type.suggestedFieldCount, spoken: L10n.SourceTypes.suggestedFieldsSpoken(count: type.suggestedFieldCount))
        }
        let usedBy = PVTableColumn<CatalogSourceType>(
            id: SourceTypesModel.SortColumn.usedBy.rawValue,
            title: L10n.SourceTypes.columnUsedBy,
            width: usedByColumnWidth,
            sortable: true
        ) { type in
            countCell(type.usedBy, spoken: L10n.SourceTypes.usage(count: type.usedBy))
        }
        return [label, description, key, fields, usedBy]
    }

    /// One count look for both count columns; 0 reads as the dash.
    private static func countCell(_ count: Int, spoken: String) -> some View {
        Text(count > 0 ? "\(count)" : L10n.string(L10n.SourceTypes.countNone))
            .font(PVFont.mono(size: PVTypeScale.micro))
            .foregroundStyle(count > 0 ? PVColor.textSecondary : PVColor.textFaint)
            .accessibilityLabel(Text(verbatim: spoken))
    }
}
