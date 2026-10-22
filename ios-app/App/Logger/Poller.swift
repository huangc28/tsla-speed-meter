import Foundation

enum Poller {
    /// Calls `tick` until the task is cancelled, one call at a time: the
    /// next call starts `interval` after the previous one started, or at
    /// once if that one took longer. A call in progress always finishes
    /// before `run` returns. Runs on the caller's actor.
    static func run(
        every interval: Duration,
        isolation: isolated (any Actor)? = #isolation,
        _ tick: () async -> Void
    ) async {
        let clock = ContinuousClock()
        while !Task.isCancelled {
            let started = clock.now
            await tick()
            let next = started + interval
            if next > clock.now {
                try? await clock.sleep(until: next)
            }
        }
    }
}
