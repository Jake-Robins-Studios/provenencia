import SwiftUI

/// The height a scroll view takes: its content's height, up to the cap.
enum PVFittedScrollHeight {
    static func height(content: CGFloat, cap: CGFloat) -> CGFloat {
        min(max(content, 0), cap)
    }
}

/// A vertical `ScrollView` as tall as its content, up to `maxHeight`; past the
/// cap it scrolls. A bare `ScrollView` takes all the height it is offered.
/// `onContentHeight` reports each measured content height (0 before the first
/// measure), for a caller that gates on it.
struct PVFittedScrollView<Content: View>: View {
    let maxHeight: CGFloat
    var onContentHeight: (CGFloat) -> Void = { _ in }
    @ViewBuilder let content: () -> Content
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        ScrollView(.vertical) {
            content()
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                    contentHeight = $0
                    onContentHeight($0)
                }
        }
        .frame(height: PVFittedScrollHeight.height(content: contentHeight, cap: maxHeight))
        .scrollBounceBehavior(.basedOnSize)
    }
}
