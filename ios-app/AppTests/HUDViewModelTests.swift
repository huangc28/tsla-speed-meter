import Foundation
import HUDCore
import Testing
@testable import SpeedHUD

/// A clock the test moves by hand.
@MainActor
final class TestClock {
    var now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    func advance(_ seconds: TimeInterval) { now += seconds }
}

@MainActor
struct HUDViewModelTests {
    let clock = TestClock()

    private func makeModel(unit: SpeedUnit = .kilometersPerHour) -> HUDViewModel {
        let clock = clock
        return HUDViewModel(unit: unit, now: { clock.now })
    }

    private func sample(_ speed: Double, accuracy: Double = 5) -> LocationEvent {
        .sample(GPSSample(speedMetersPerSecond: speed, horizontalAccuracyMeters: accuracy, timestamp: clock.now))
    }

    @Test func startsWithDashAndNoGreenChip() {
        let model = makeModel()
        #expect(model.state.numeral == "—")
        #expect(model.state.source.marker != .valid)
        #expect(model.state.layout == .drive)
    }

    @Test func showsGPSSpeedThenDashOnceItExpiresWithoutANewEvent() {
        let model = makeModel()
        model.handle(.authorization(.authorized))
        model.handle(sample(20))
        #expect(model.state.numeral == "72")
        #expect(model.state.source == .valid(.gps))

        clock.advance(2.5)
        model.refresh() // what the periodic tick does
        #expect(model.state.numeral == "—")
        #expect(model.state.reason == .speedUnavailable)
        #expect(model.state.source == .speedUnavailable)
    }

    @Test func unitSettingSwitchesNumeralToMph() {
        let model = makeModel()
        model.handle(.authorization(.authorized))
        model.handle(sample(20))
        model.unit = .milesPerHour
        #expect(model.state.numeral == "45")
        #expect(model.state.unit == .milesPerHour)
    }

    // #24: an empty, finished source renders no "0" numeral and no green GPS chip.
    @Test func emptyFinishedSourceShowsDashAndNoGreenChip() async {
        let model = makeModel()
        await model.run(AsyncStream { $0.finish() })
        #expect(model.state.numeral == "—")
        #expect(model.state.numeral != "0")
        #expect(model.state.source.marker != .valid)
        #expect(model.state.layout == .drive)
    }

    // #25: stream end shows "—" plus the lost chip.
    @Test func streamEndAfterAFixShowsDashAndLostChip() async {
        let model = makeModel()
        let fix = sample(20)
        let events = AsyncStream<LocationEvent> { continuation in
            continuation.yield(.authorization(.authorized))
            continuation.yield(fix)
            continuation.finish()
        }
        await model.run(events)
        #expect(model.state.numeral == "—")
        #expect(model.state.source == .speedUnavailable)
    }

    // #25: the running tick turns an expired speed into "—" with no further event.
    @Test func runningTickExpiresSpeedWithoutANewEvent() async throws {
        let model = makeModel()
        let (events, continuation) = AsyncStream<LocationEvent>.makeStream()
        let task = Task { await model.run(events, tick: .milliseconds(10)) }
        continuation.yield(.authorization(.authorized))
        continuation.yield(sample(20))
        try await waitUntil { model.state.numeral == "72" }

        clock.advance(3)
        try await waitUntil { model.state.numeral == "—" }
        #expect(model.state.source == .speedUnavailable)
        task.cancel()
        await task.value
    }

    @Test func permissionDeniedShowsGPSUnavailable() {
        let model = makeModel()
        model.handle(.authorization(.denied))
        #expect(model.state.numeral == "—")
        #expect(model.state.reason == .gpsUnavailable)
        #expect(model.state.source == .gpsUnavailable)
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<200 where !condition() {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(condition())
    }
}
