import SwiftUI

/// Lays children out as columns: a child with a fixed width gets it, the rest share what remains by
/// weight. `PVTable` (header and every row, `alignment: .center`) and the Citation composer's evidence
/// columns (`alignment: .top`) both use it, so the width rule lives once in `widths`, which tests
/// drive with made-up sizes.
///
/// Edges: a weight at or below 0, or not finite, counts as 1; a child beyond `fixed` and `weights` is
/// flexible with weight 1. With no proposed width the layout reports the fixed widths plus the gaps
/// plus each flexible child's ideal width, and lays out at that.
struct PVWeightedColumns: Layout {
    let fixed: [CGFloat?]
    let weights: [CGFloat]
    let spacing: CGFloat
    let alignment: VerticalAlignment

    init(fixed: [CGFloat?] = [], weights: [CGFloat] = [], spacing: CGFloat, alignment: VerticalAlignment = .center) {
        self.fixed = fixed
        self.weights = weights
        self.spacing = spacing
        self.alignment = alignment
    }

    /// Each column's width in `total`: fixed ones as given, the rest sharing what remains by weight.
    /// The column count is the longer of the two arrays.
    static func widths(fixed: [CGFloat?], weights: [CGFloat], total: CGFloat, spacing: CGFloat) -> [CGFloat] {
        let count = max(fixed.count, weights.count)
        guard count > 0 else { return [] }
        let fixedWidths: [CGFloat?] = (0..<count).map { $0 < fixed.count ? fixed[$0] : nil }
        let shares: [CGFloat] = (0..<count).map { index in
            guard fixedWidths[index] == nil else { return 0 }
            let weight = index < weights.count ? weights[index] : 1
            return weight.isFinite && weight > 0 ? weight : 1
        }
        let gaps = spacing * CGFloat(count - 1)
        let fixedSum = fixedWidths.reduce(0) { $0 + ($1 ?? 0) }
        let free = max(0, total - gaps - fixedSum)
        let shareSum = shares.reduce(0, +)
        return (0..<count).map { index in
            fixedWidths[index] ?? (shareSum > 0 ? free * shares[index] / shareSum : 0)
        }
    }

    /// Where a cell of `height` starts inside a row of `rowHeight`.
    static func cellY(height: CGFloat, rowHeight: CGFloat, alignment: VerticalAlignment) -> CGFloat {
        alignment == .center ? max(0, (rowHeight - height) / 2) : 0
    }

    private func columnWidths(_ subviews: Subviews, total: CGFloat) -> [CGFloat] {
        // Pad both arrays to the child count so extra children are flexible with weight 1.
        let count = subviews.count
        let paddedFixed: [CGFloat?] = (0..<count).map { $0 < fixed.count ? fixed[$0] : nil }
        let paddedWeights: [CGFloat] = (0..<count).map { $0 < weights.count ? weights[$0] : 1 }
        return Self.widths(fixed: paddedFixed, weights: paddedWeights, total: total, spacing: spacing)
    }

    /// With no proposed width: fixed widths and gaps plus each flexible child's ideal width.
    private func idealWidths(_ subviews: Subviews) -> [CGFloat] {
        subviews.enumerated().map { index, subview in
            if index < fixed.count, let width = fixed[index] { return width }
            return subview.sizeThatFits(.unspecified).width
        }
    }

    private func resolvedWidths(_ subviews: Subviews, proposedWidth: CGFloat?) -> [CGFloat] {
        if let proposedWidth { return columnWidths(subviews, total: proposedWidth) }
        return idealWidths(subviews)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let widths = resolvedWidths(subviews, proposedWidth: proposal.width)
        let height = zip(subviews, widths).map { $0.sizeThatFits(ProposedViewSize(width: $1, height: nil)).height }.max() ?? 0
        let total = proposal.width ?? (widths.reduce(0, +) + spacing * CGFloat(max(0, subviews.count - 1)))
        return CGSize(width: total, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let widths = resolvedWidths(subviews, proposedWidth: proposal.width ?? bounds.width)
        var x = bounds.minX
        for (subview, width) in zip(subviews, widths) {
            let size = ProposedViewSize(width: width, height: nil)
            let height = subview.sizeThatFits(size).height
            let y = bounds.minY + Self.cellY(height: height, rowHeight: bounds.height, alignment: alignment)
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: size)
            x += width + spacing
        }
    }
}
