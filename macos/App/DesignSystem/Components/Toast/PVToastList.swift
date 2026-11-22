import SwiftUI

/// One card in a ``PVToastList``. The `id` survives a refresh, so a card that
/// moves to the top keeps its view identity and VoiceOver does not read it again.
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
/// A toast equal on tone, title and message to one already listed refreshes it: it
/// moves to the top, keeps its `id`, and its five seconds restart. There is no cap.
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

    /// Adds a card on top, or refreshes the equal one already listed. An empty
    /// title or message counts as none.
    func add(tone: PVToastTone, title: String?, message: String?) {
        let title = title.flatMap { $0.isEmpty ? nil : $0 }
        let message = message.flatMap { $0.isEmpty ? nil : $0 }
        let id: PVToastEntry.ID
        if let index = entries.firstIndex(where: { $0.tone == tone && $0.title == title && $0.message == message }) {
            let entry = entries.remove(at: index)
            entries.insert(entry, at: 0)
            id = entry.id
        } else {
            id = UUID()
            entries.insert(PVToastEntry(id: id, tone: tone, title: title, message: message), at: 0)
        }
        startTimer(for: id)
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

private struct PVToastListKey: EnvironmentKey {
    static let defaultValue: PVToastList? = nil
}

extension EnvironmentValues {
    /// The toast list of the nearest host: the window, or a sheet over it, so a toast
    /// raised inside a sheet draws in the sheet.
    var pvToastList: PVToastList? {
        get { self[PVToastListKey.self] }
        set { self[PVToastListKey.self] = newValue }
    }
}
