import SwiftUI

/// A window's toasts in one column, newest on top, in the top-trailing corner of the
/// container it overlays. Each card leaves on its own timer or its dismiss button
/// (``PVToastList``); the column is cut at the container's bottom and draws no
/// background, so a click beside a card reaches the page. With no entries it shows
/// nothing; the column stays mounted so the last card's leave animation runs, and with
/// no background or content shape it catches no click. A card slides in from the
/// trailing edge while fading; with Reduce Motion it only fades.
struct PVToastStack: View {
    /// How far a card travels as it enters or leaves.
    static let slideDistance: CGFloat = 28

    let list: PVToastList
    let identifier: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .trailing, spacing: PVSpacing.space4) {
            ForEach(list.entries) { entry in
                PVToast(
                    tone: entry.tone,
                    title: entry.title,
                    message: entry.message,
                    onDismiss: { list.dismiss(entry.id) }                )
                .transition(transition)
            }
        }
        .animation(reduceMotion ? nil : PVMotion.easeStandard, value: list.entries.map(\.id))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
        .padding(PVSpacing.space8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .clipped()
    }

    private var transition: AnyTransition {
        if reduceMotion {
            return .opacity.animation(.linear(duration: PVMotion.durationNormal))
        }
        return .asymmetric(
            insertion: .offset(x: Self.slideDistance).combined(with: .opacity).animation(PVMotion.easeOut),
            removal: .offset(x: Self.slideDistance).combined(with: .opacity).animation(PVMotion.easeIn)
        )
    }
}

#Preview {
    let list = PVToastList(sleep: { _ in await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in } })
    list.add(tone: .success, title: "Portrait updated", message: "Marriage register, p. 12")
    list.add(tone: .info, title: "Filed", message: nil)
    list.add(tone: .danger, title: "Couldn’t refresh catalog counts", message: "The catalog is busy.")
    return PVToastStack(list: list, identifier: "preview.toasts")
        .frame(width: 640, height: 400)
        .background(PVColor.surfacePage)
}
