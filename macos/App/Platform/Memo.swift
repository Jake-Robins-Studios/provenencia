/// The last value stored, kept while its key is unchanged. A key holds every
/// input the build reads. The one-slot store under `WorkspaceSession.derived`
/// and the depiction preview.
struct Memo<Key: Equatable, Value> {
    /// The stored key and value, or nil before the first store.
    private(set) var entry: (key: Key, value: Value)?

    /// The stored value when `key` matches the stored key.
    func value(for key: Key) -> Value? {
        guard let entry, entry.key == key else { return nil }
        return entry.value
    }

    mutating func store(_ value: Value, for key: Key) {
        entry = (key, value)
    }
}
