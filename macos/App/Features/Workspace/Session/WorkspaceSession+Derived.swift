import Foundation

/// A value the app derives from cached reads and builds once per change of its
/// inputs. One closed list: each id has one value type.
enum DerivedValueID: Hashable {
    case evidenceGraphIndex
    case evidenceGraphSnapshot(graphID: String)
    case evidenceGraphText(graphID: String)
    case citationComposerVocabulary(graphID: String)
    case visibleSources
    case conclusionContent(CatalogQueryKey)
}

/// What a derived value is built from: a cached read, or another derived value.
enum DerivedInput: Equatable {
    case key(CatalogQueryKey)
    case derived(DerivedValueID)
}

/// What a stored derived value was built from: one revision per input (a key's
/// handle revision, or a derived input's version) and the caller's plain
/// values.
struct DerivedStamp: Equatable {
    let inputs: [Int]
    let extra: (any Equatable)?

    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.inputs == rhs.inputs else { return false }
        switch (lhs.extra, rhs.extra) {
        case (nil, nil): return true
        case let (left?, right?): return equal(left, right)
        default: return false
        }
    }

    private static func equal<Left: Equatable>(_ left: Left, _ right: any Equatable) -> Bool {
        (right as? Left) == left
    }
}

/// One derived value's record: the value with its stamp, what it reads and how
/// many times it was stored.
struct DerivedEntry {
    var memo: Memo<DerivedStamp, Any>
    var inputs: [DerivedInput]
    var version: Int
}

extension WorkspaceSession {
    /// The value for `id`, built once per change of `inputs` and `extra`. A
    /// read whose stamp matches returns the stored value; otherwise `build`
    /// runs and its result is stored. `build` reads only the handles `inputs`
    /// name (checked in debug builds), the derived values it names, and `extra`.
    func derived<Value>(
        _ id: DerivedValueID,
        inputs: [DerivedInput],
        extra: (any Equatable)? = nil,
        build: () -> Value
    ) -> Value {
        if let entry = derivedEntries[id], entry.inputs == inputs, let stamp = derivedStamp(inputs),
           let stored = entry.memo.value(for: DerivedStamp(inputs: stamp, extra: extra)) {
            return typed(stored, as: Value.self, id: id)
        }
        #if DEBUG
        derivedReads.append([])
        #endif
        let value = build()
        #if DEBUG
        let reads = derivedReads.removeLast()
        let declared = Set(inputs.compactMap { input -> CatalogQueryKey? in
            if case .key(let key) = input { return key }
            return nil
        })
        if let undeclared = reads.subtracting(declared).first {
            assertionFailure("DerivedValueID \(id) read \(undeclared), which its inputs do not name")
        }
        #endif
        guard let stamp = derivedStamp(inputs) else {
            assertionFailure("DerivedValueID \(id) names a derived input its build did not read")
            return value
        }
        var entry = derivedEntries[id] ?? DerivedEntry(memo: Memo(), inputs: inputs, version: 0)
        entry.inputs = inputs
        entry.memo.store(value, for: DerivedStamp(inputs: stamp, extra: extra))
        entry.version += 1
        derivedEntries[id] = entry
        derivedBuilds[id, default: 0] += 1
        return value
    }

    /// Moves the stored value across one merged change of `key` (the handle
    /// went from `previousRevision` to the next revision by that change alone)
    /// without a build. Nothing happens when there is no entry, when the entry
    /// was not current just before, or when another input moved too: the next
    /// read builds. The stored `extra` is kept.
    func carryDerived<Value>(
        _ id: DerivedValueID,
        across key: CatalogQueryKey,
        from previousRevision: Int,
        _ change: (Value) -> Value
    ) {
        guard var entry = derivedEntries[id], let stored = entry.memo.entry,
              let index = entry.inputs.firstIndex(of: .key(key)),
              stored.key.inputs[index] == previousRevision,
              inputRevision(key) == previousRevision + 1,
              let now = derivedStamp(entry.inputs),
              now.indices.allSatisfy({ $0 == index || now[$0] == stored.key.inputs[$0] }),
              let old = stored.value as? Value
        else { return }
        entry.memo.store(change(old), for: DerivedStamp(inputs: now, extra: stored.key.extra))
        entry.version += 1
        derivedEntries[id] = entry
    }

    /// How many times `id`'s build ran (a test hook; a carry is not a build).
    func derivedBuildCount(_ id: DerivedValueID) -> Int {
        derivedBuilds[id] ?? 0
    }

    /// Drops every entry that reads `key`, then every entry that reads a
    /// dropped one. Called when a key is evicted.
    func dropDerived(reading key: CatalogQueryKey) {
        var removed: Set<DerivedValueID> = []
        var changed = true
        while changed {
            changed = false
            for (id, entry) in derivedEntries where !removed.contains(id) {
                let reads = entry.inputs.contains { input in
                    switch input {
                    case .key(let inputKey): inputKey == key
                    case .derived(let child): removed.contains(child)
                    }
                }
                if reads {
                    removed.insert(id)
                    changed = true
                }
            }
        }
        for id in removed { derivedEntries[id] = nil }
    }

    /// A page's or section's content built from `value` and `extra`, kept while
    /// the reads it draws and `extra` hold.
    func conclusionContent<Value, Extra: Equatable, Content>(
        _ key: CatalogQueryKey,
        inputs: [CatalogQueryKey],
        extra: Extra,
        value: Value,
        make: (Value, Extra) -> Content
    ) -> Content {
        derived(.conclusionContent(key), inputs: inputs.map(DerivedInput.key), extra: extra) {
            make(value, extra)
        }
    }

    /// One stamp per input, or nil when a derived input has no entry or is no
    /// longer current.
    private func derivedStamp(_ inputs: [DerivedInput]) -> [Int]? {
        var stamp: [Int] = []
        for input in inputs {
            switch input {
            case .key(let key):
                stamp.append(inputRevision(key))
            case .derived(let child):
                guard let entry = derivedEntries[child], let stored = entry.memo.entry,
                      derivedStamp(entry.inputs) == stored.key.inputs
                else { return nil }
                stamp.append(entry.version)
            }
        }
        return stamp
    }

    private func typed<Value>(_ stored: Any, as type: Value.Type, id: DerivedValueID) -> Value {
        guard let value = stored as? Value else {
            preconditionFailure("DerivedValueID \(id) holds \(Swift.type(of: stored)), not \(Value.self)")
        }
        return value
    }
}
