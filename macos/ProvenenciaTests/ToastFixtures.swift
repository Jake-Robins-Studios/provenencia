import Testing
@testable import Provenencia

/// One toast card's tone, title and message, so a test compares a list's cards whole.
struct ToastCard: Equatable {
    let tone: PVToastTone
    let title: String?
    let message: String?

    init(_ tone: PVToastTone, _ title: String?, _ message: String? = nil) {
        self.tone = tone
        self.title = title
        self.message = message
    }
}

extension PVToastList {
    /// The list's cards, newest first, without their ids.
    @MainActor var cards: [ToastCard] {
        entries.map { ToastCard($0.tone, $0.title, $0.message) }
    }
}
