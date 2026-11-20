import Foundation

/// The newest of a stream of calls: starting one cancels the one pending and
/// drops its result, so only the call started last applies. A search typed
/// into, a count refreshed after each write, a preview rendered per keystroke:
/// each holds one.
///
/// `work` runs on the main actor; `apply` gets its result there, and never the
/// result of a call a newer one (or `cancel()`) has replaced.
@MainActor
final class LatestCall {
    private var task: Task<Void, Never>?
    private var generation = 0

    /// Starts `work` after `delay` as the newest call and returns at once.
    func start<T: Sendable>(
        after delay: Duration = .zero,
        _ work: @escaping @MainActor () async throws -> T,
        apply: @escaping @MainActor (Result<T, Error>) -> Void
    ) {
        task?.cancel()
        generation += 1
        let mine = generation
        task = Task { @MainActor [weak self] in
            if delay > .zero {
                try? await Task.sleep(for: delay)
            }
            guard let self, mine == self.generation else { return }
            let result: Result<T, Error>
            do {
                result = .success(try await work())
            } catch {
                result = .failure(error)
            }
            guard mine == self.generation else { return }
            apply(result)
        }
    }

    /// `start`, returning once this call's `apply` ran or a newer call (or
    /// `cancel()`) replaced it.
    func run<T: Sendable>(
        after delay: Duration = .zero,
        _ work: @escaping @MainActor () async throws -> T,
        apply: @escaping @MainActor (Result<T, Error>) -> Void
    ) async {
        start(after: delay, work, apply: apply)
        await task?.value
    }

    /// Returns once the newest call has finished or been cancelled, following
    /// any call started while it waited. Tests await this instead of polling
    /// against a deadline, which a busy main actor can outlast.
    func settle() async {
        while let held = task {
            await held.value
            if task == held { return }
        }
    }

    /// Drops the pending call and its result.
    func cancel() {
        task?.cancel()
        task = nil
        generation += 1
    }
}
