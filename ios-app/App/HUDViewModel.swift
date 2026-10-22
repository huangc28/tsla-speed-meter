import Foundation
import HUDCore
import Observation

/// Feeds location events into `HUDEngine` and republishes the drive screen's state.
/// A periodic tick re-reads the state, so an expired speed turns into "—" with no new event.
@MainActor @Observable
final class HUDViewModel {
    private(set) var state: HUDState
    var unit: SpeedUnit {
        didSet { refresh() }
    }

    private var engine: HUDEngine
    private let now: () -> Date

    init(unit: SpeedUnit = .kilometersPerHour, engine: HUDEngine = HUDEngine(), now: @escaping () -> Date = Date.init) {
        self.unit = unit
        self.engine = engine
        self.now = now
        state = engine.state(at: now(), unit: unit)
    }

    func handle(_ event: LocationEvent) {
        engine.handle(event, now: now())
        refresh()
    }

    /// Re-evaluates the state at the current time.
    func refresh() {
        let next = engine.state(at: now(), unit: unit)
        if next != state { state = next }
    }

    /// Consumes `events` until they finish (then reports `.ended`) or the task is cancelled,
    /// refreshing every `tick` in between.
    func run(_ events: AsyncStream<LocationEvent>, tick: Duration = .milliseconds(250)) async {
        let ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: tick)
                self?.refresh()
            }
        }
        defer { ticker.cancel() }
        for await event in events { handle(event) }
        if !Task.isCancelled { handle(.ended) }
    }
}
