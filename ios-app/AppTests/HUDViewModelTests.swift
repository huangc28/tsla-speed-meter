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

    @Test func defaultTickIs250Milliseconds() {
        #expect(HUDViewModel.defaultTick == .milliseconds(250))
    }

    // S04-g: going to the background shows "—" at once, for the app-switcher snapshot.
    @Test func backgroundDropsTheSpeedAtOnce() {
        let model = makeModel()
        model.handle(.authorization(.authorized))
        model.handle(sample(20))
        model.suspend()
        #expect(model.state.numeral == "—")
        #expect(model.state.gauge == .noData)
    }

    // S04-g: back in the foreground, "◌ Waiting for speed" until the first new valid reading.
    @Test func foregroundWaitsForTheFirstNewValidReading() {
        let model = makeModel()
        model.handle(.authorization(.authorized))
        model.handle(sample(20))
        model.suspend()
        clock.advance(60)
        model.resume()
        #expect(model.state.numeral == "—")
        #expect(model.state.source == .waiting)

        clock.advance(1)
        model.handle(sample(10))
        #expect(model.state.numeral == "36")
        #expect(model.state.source == .valid(.gps))
    }

    // 01 §3.2: readings delivered in the background, or stamped before the resume, are void.
    @Test func backgroundReadingsAreVoid() {
        let model = makeModel()
        model.handle(.authorization(.authorized))
        model.handle(sample(20))
        model.suspend()
        clock.advance(1)
        model.handle(sample(25))
        #expect(model.state.numeral == "—")

        let takenInBackground = sample(25)
        clock.advance(0.5)
        model.resume()
        clock.advance(0.1)
        model.handle(takenInBackground)
        #expect(model.state.numeral == "—")
        #expect(model.state.source == .waiting)
    }

    @Test func becomingActiveWithoutABackgroundTripChangesNothing() {
        let model = makeModel()
        model.handle(.authorization(.authorized))
        model.handle(sample(20))
        model.resume()
        #expect(model.state.numeral == "72")
    }

    // 01 §6.1 / §7.3: the spoken speed carries unit and source; the spoken reason matches the screen.
    @Test func voiceOverLabels() {
        let model = makeModel()
        model.handle(.authorization(.authorized))
        model.handle(sample(20))
        #expect(HUDAccessibility.speedLabel(for: model.state) == "Current speed 72 kilometers per hour, from GPS")
        model.unit = .milesPerHour
        #expect(HUDAccessibility.speedLabel(for: model.state) == "Current speed 45 miles per hour, from GPS")

        clock.advance(3)
        model.refresh()
        #expect(HUDAccessibility.speedLabel(for: model.state) == "Speed unavailable")
        model.handle(.authorization(.denied))
        #expect(HUDAccessibility.speedLabel(for: model.state) == "GPS unavailable")
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<200 where !condition() {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(condition())
    }
}
