import SwiftUI

extension View {
    /// One focus stop over a column of rows tagged `.id(rowID(i))`: ↑/↓ (⌥ to an end)
    /// move `focusIndex` (`PVListKeyboard`), the list scrolls to keep that row in view,
    /// and Return or Space calls `onActivate` with it; Page Up/Down and Home/End go on
    /// to the page (`PVPageScrollView`).
    /// The caller draws the focused row with `PVListKeyboard.isFocusedRow`.
    func pvListFocusStop<ID: Hashable>(
        count: Int,
        rowID: @escaping (Int) -> ID,
        focusIndex: Binding<Int>,
        isFocused: FocusState<Bool>.Binding,
        onActivate: @escaping (Int) -> Void
    ) -> some View {
        modifier(
            PVListFocusStop(
                count: count, rowID: rowID, focusIndex: focusIndex,
                isFocused: isFocused, onActivate: onActivate
            )
        )
    }
}

private struct PVListFocusStop<ID: Hashable>: ViewModifier {
    let count: Int
    let rowID: (Int) -> ID
    let focusIndex: Binding<Int>
    let isFocused: FocusState<Bool>.Binding
    let onActivate: (Int) -> Void

    func body(content: Content) -> some View {
        content
            .pvScrollsRowIntoView(
                (0..<count).contains(focusIndex.wrappedValue) ? rowID(focusIndex.wrappedValue) : nil,
                animated: false
            )
            .focusable()
            .focusEffectDisabled()
            .focused(isFocused)
            .onKeyPress { press in
                let action = PVListKeyboard.action(
                    for: press.key,
                    option: press.modifiers.contains(.option),
                    index: PVListKeyboard.clampedIndex(focusIndex.wrappedValue, count: count),
                    count: count
                )
                switch action {
                case .move(let index):
                    focusIndex.wrappedValue = index
                    return .handled
                case .activate(let index):
                    onActivate(index)
                    return .handled
                case .ignore:
                    return .ignored
                }
            }
    }
}

private struct PVListFocusStopPreview: View {
    @State private var focusIndex = 0
    @FocusState private var isFocused: Bool

    var body: some View {
        PVPageScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<30, id: \.self) { i in
                    Button {
                        focusIndex = i
                    } label: {
                        Text(verbatim: "Row \(i + 1)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(PVSpacing.space5)
                    }
                    .buttonStyle(
                        PVListRowStyle(
                            focused: PVListKeyboard.isFocusedRow(
                                i, focusIndex: focusIndex, count: 30, listFocused: isFocused
                            )
                        )
                    )
                    .id(i)
                }
            }
            .pvListFocusStop(
                count: 30, rowID: { $0 }, focusIndex: $focusIndex,
                isFocused: $isFocused, onActivate: { focusIndex = $0 }
            )
        }
    }
}

#Preview { PVListFocusStopPreview().frame(width: 320, height: 360) }
