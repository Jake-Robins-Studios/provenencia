import SwiftUI

/// One card in a ``PVToastList``. The `id` survives a refresh, so a card that
/// moves to the top keeps its view identity. VoiceOver does not read a refreshed card
/// again when its text is unchanged; new text is spoken.
struct PVToastEntry: Identifiable, Equatable {
    let id: UUID
    let tone: PVToastTone
    let title: String?
    let message: String?
}

/// The toasts of one window, newest first, each leaving on its own timer or when
/// dismissed. Kept apart from the view so a test proves the timing without a window
/// or a real wait (the shape of ``PVClipboardCopyState``).
///
/// Every add makes a card and returns its id; the list never compares text. A caller
/// that wants one card for a repeating event holds the id and passes it back as
/// `replacing`: that card takes the new text, moves to the top, keeps its `id`, and
/// its five seconds restart. There is no cap.
@MainActor
@Observable
final class PVToastList {
    /// How long a card stays before it leaves on its own.
    static let lifetime: Duration = .seconds(5)

    private(set) var entries: [PVToastEntry] = []

    @ObservationIgnored private let sleep: @MainActor (Duration) async -> Void
    @ObservationIgnored private var timers: [PVToastEntry.ID: Task<Void, Never>] = [:]

    init(sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) }) {
        self.sleep = sleep
    }

    /// Adds a card on top and returns its id. An empty title or message counts as
    /// none. A caller that holds the id of a card it raised passes it back as
    /// `replacing`: that card takes the new text in place, moves to the top, and its
    /// five seconds restart. An id no longer listed adds a new card.
    @discardableResult
    func add(
        tone: PVToastTone,
        title: String?,
        message: String?,
        replacing: PVToastEntry.ID? = nil
    ) -> PVToastEntry.ID {
        let title = title.flatMap { $0.isEmpty ? nil : $0 }
        let message = message.flatMap { $0.isEmpty ? nil : $0 }
        let id: PVToastEntry.ID
        if let replacing, let index = entries.firstIndex(where: { $0.id == replacing }) {
            entries.remove(at: index)
            id = replacing
        } else {
            id = UUID()
        }
        entries.insert(PVToastEntry(id: id, tone: tone, title: title, message: message), at: 0)
        startTimer(for: id)
        return id
    }

    /// Removes one card and its timer. An unknown id does nothing.
    func dismiss(_ id: PVToastEntry.ID) {
        timers.removeValue(forKey: id)?.cancel()
        entries.removeAll { $0.id == id }
    }

    private func startTimer(for id: PVToastEntry.ID) {
        timers[id]?.cancel()
        timers[id] = Task { [weak self, sleep] in
            await sleep(Self.lifetime)
            guard !Task.isCancelled, let self else { return }
            dismiss(id)
        }
    }
}
