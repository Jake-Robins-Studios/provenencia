import Foundation

/// How the Sources list is ordered: a column of its table and a direction. One value for the settings and
/// for the table's headers (`SourcesTable`).
struct SourcesSort: Codable, Hashable, Sendable {
    /// The columns a header click sorts by. Evidence, Status and Type do not sort.
    enum Column: String, Codable, CaseIterable, Sendable {
        case title
        case published
        case added
        case updated

        /// The direction a first click on the header sorts in: A to Z for Title, newest first for the dates.
        var firstOrder: SortOrder { self == .title ? .forward : .reverse }
    }

    var column: Column
    var order: SortOrder

    /// What a first visit shows: Added, newest first.
    static let initial = SourcesSort(column: .added, order: .reverse)

    init(column: Column, order: SortOrder) {
        self.column = column
        self.order = order
    }
}

/// What the Sources list remembers between visits: sort, type, evidence
/// status, and search. One value, saved as one JSON entry per install user.
struct SourcesListSettings: Codable, Hashable {
    var sort = SourcesSort.initial
    /// `source_types.id`, or empty for all types.
    var typeFilterID = ""
    var status: SourcesModel.EvidenceStatus?
    var query = ""

    init() {}

    /// Each field falls back to its default on its own, so one stale value
    /// (a sort stored before the table, a removed status) does not reset the rest.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sort = (try? container.decodeIfPresent(SourcesSort.self, forKey: .sort)) ?? .initial
        typeFilterID = (try? container.decodeIfPresent(String.self, forKey: .typeFilterID)) ?? ""
        // "filed" is what Promoted was stored as before S12-14.
        let stored = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? nil
        status = (stored == "filed" ? "promoted" : stored).flatMap(SourcesModel.EvidenceStatus.init(rawValue:))
        query = (try? container.decodeIfPresent(String.self, forKey: .query)) ?? ""
    }
}

/// Per-project, per-user JSON under Application Support
/// (`sources-list/{projectKey}.json`, keyed by user id). A smaller copy of
/// `NavigationHistoryStore`'s shape; see `navigation-history.md`.
struct SourcesListSettingsStore {
    private let fileURL: URL
    private let userID: String
    private let fileManager: FileManager

    /// Nil when the project uuid or user id is empty, or the default URL
    /// cannot be built. The list then keeps its settings in memory only.
    init?(
        projectUuid: String,
        userID: String,
        fileURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        let key = InstallPaths.projectKey(projectUuid: projectUuid)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let user = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !user.isEmpty else { return nil }
        if let fileURL {
            self.fileURL = fileURL
        } else if let url = try? InstallPaths.sourcesListSettingsFile(
            projectUuid: projectUuid,
            fileManager: fileManager
        ) {
            self.fileURL = url
        } else {
            return nil
        }
        self.userID = userID
        self.fileManager = fileManager
    }

    func load() -> SourcesListSettings {
        readAll()[userID] ?? SourcesListSettings()
    }

    /// Replaces this user's entry. A write error is ignored: the list keeps
    /// working from memory.
    func save(_ settings: SourcesListSettings) {
        var all = readAll()
        all[userID] = settings
        do {
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(all)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return
        }
    }

    private func readAll() -> [String: SourcesListSettings] {
        guard let data = try? Data(contentsOf: fileURL),
              let all = try? JSONDecoder().decode([String: SourcesListSettings].self, from: data)
        else { return [:] }
        return all
    }
}
