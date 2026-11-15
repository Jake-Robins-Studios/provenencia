import SwiftUI

/// The Source-type icon grid and the chosen mark's meaning under it: inline in the Add type
/// dialog (5 columns) and the body of the type page's "Choose an icon" sheet (6 columns).
/// One Tab stop; ← → ↑ ↓ choose a mark. A snowflake: the marks are Source-type vocabulary.
struct SourceTypeIconGrid: View {
    @Binding var selection: String
    let columns: Int
    let groupLabel: LocalizedStringResource

    @FocusState private var isFocused: Bool

    enum Move { case left, right, up, down }

    /// The mark a move chooses from `selection`: one place back or on for ← / →, `columns`
    /// places for ↑ / ↓. Nil past either end, or when `selection` is not in `keys`; no wrap.
    static func arrowTarget(keys: [String], selection: String, columns: Int, move: Move) -> String? {
        guard let index = keys.firstIndex(of: selection) else { return nil }
        let target = switch move {
        case .left: index - 1
        case .right: index + 1
        case .up: index - columns
        case .down: index + columns
        }
        return keys.indices.contains(target) ? keys[target] : nil
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: PVSpacing.space4), count: columns)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space7) {
            LazyVGrid(columns: gridColumns, spacing: PVSpacing.space4) {
                ForEach(PVMarkKey.typeKeys, id: \.rawValue) { key in
                    iconCell(key, focused: isFocused && key.rawValue == selection)
                }
            }
            .focusable()
            .focusEffectDisabled()
            .focused($isFocused)
            .onKeyPress(.leftArrow) { arrow(.left) }
            .onKeyPress(.rightArrow) { arrow(.right) }
            .onKeyPress(.upArrow) { arrow(.up) }
            .onKeyPress(.downArrow) { arrow(.down) }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(groupLabel))
            .accessibilityIdentifier("sourceTypes.iconPicker")

            Text(selectedKey.typeMetaphor)
                .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                .foregroundStyle(PVColor.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func arrow(_ move: Move) -> KeyPress.Result {
        guard let target = Self.arrowTarget(
            keys: PVMarkKey.typeKeys.map(\.rawValue), selection: selection, columns: columns, move: move
        ) else { return .ignored }
        selection = target
        return .handled
    }

    private var selectedKey: PVMarkKey {
        PVMarkKey(catalogKey: selection)
    }

    private func iconCell(_ key: PVMarkKey, focused: Bool) -> some View {
        let selected = selection == key.rawValue
        return Button {
            selection = key.rawValue
        } label: {
            VStack(spacing: PVSpacing.space4) {
                PVMark(key, size: 32, decorative: true)
                Text(key.typePickerTitle)
                    .font(PVFont.body(size: PVTypeScale.micro))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PVSpacing.space4)
            .padding(.vertical, PVSpacing.space5)
            .foregroundStyle(selected ? PVColor.accent : PVColor.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: PVRadius.sm, style: .continuous)
                    .fill(selected ? PVColor.surfaceActive : PVColor.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PVRadius.sm, style: .continuous)
                    .stroke(selected ? PVColor.accent : PVColor.borderSubtle, lineWidth: 1)
            )
            .modifier(SelectedIconShadow(selected: selected))
            .pvFocusRing(focused, cornerRadius: PVRadius.sm)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .accessibilityLabel(Text(key.typePickerTitle))
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
        .accessibilityIdentifier("sourceTypes.iconPicker.\(key.rawValue)")
    }
}

private struct SelectedIconShadow: ViewModifier {
    let selected: Bool

    func body(content: Content) -> some View {
        if selected {
            content.pvShadow(PVElevation.sm)
        } else {
            content
        }
    }
}
