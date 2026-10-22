import Foundation
import Testing
@testable import HUDCore

let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

func fix(_ speed: Double, at seconds: TimeInterval, accuracy: Double = 5) -> GPSSample {
    GPSSample(speedMetersPerSecond: speed, horizontalAccuracyMeters: accuracy, timestamp: t0 + seconds)
}

struct GPSSpeedProcessorTests {
    @Test func firstValidSampleShowsWithoutLag() {
        var p = GPSSpeedProcessor()
        #expect(p.ingest(fix(20, at: 0), now: t0) == nil)
        #expect(p.speed(at: t0)?.metersPerSecond == 20)
        #expect(p.speed(at: t0)?.source == .gps)
        #expect(p.speed(at: t0)?.timestamp == t0)
    }

    @Test func smoothsAcrossAnUnbrokenRun() {
        var p = GPSSpeedProcessor(smoothing: 0.3)
        p.ingest(fix(10, at: 0), now: t0)
        p.ingest(fix(20, at: 1), now: t0 + 1)
        #expect(abs(p.speed(at: t0 + 1)!.metersPerSecond - 13) < 1e-9)
    }

    @Test func snapsJitterToZero() {
        var p = GPSSpeedProcessor()
        p.ingest(fix(0.4, at: 0), now: t0)
        #expect(p.speed(at: t0)?.metersPerSecond == 0)
    }

    // #25: values expire; no new event is needed.
    @Test func validSpeedExpiresAfterMaxAgeWithoutANewSample() {
        var p = GPSSpeedProcessor(maxAge: 2)
        p.ingest(fix(20, at: 0), now: t0 + 0.2)
        #expect(p.speed(at: t0 + 2) != nil)
        #expect(p.speed(at: t0 + 2.01) == nil)
    }

    // #25: after expiry the next valid sample starts fresh instead of blending with the old value.
    @Test func expiryDropsSmoothingState() {
        var p = GPSSpeedProcessor(smoothing: 0.3)
        p.ingest(fix(10, at: 0), now: t0)
        p.ingest(fix(30, at: 5), now: t0 + 5)
        #expect(p.speed(at: t0 + 5)?.metersPerSecond == 30)
    }

    // #25: a rejected low-accuracy sample is not a fix and does not extend the last valid one.
    @Test func poorAccuracyIsRejectedAndDoesNotExtendFreshness() {
        var p = GPSSpeedProcessor(accuracyThresholdMeters: 50, maxAge: 2)
        p.ingest(fix(20, at: 0), now: t0)
        #expect(p.ingest(fix(25, at: 1.5, accuracy: 51), now: t0 + 1.5) == .poorAccuracy)
        #expect(p.speed(at: t0 + 1.5)?.metersPerSecond == 20)
        #expect(p.speed(at: t0 + 2.5) == nil)
    }

    @Test func poorAccuracyAloneNeverGivesASpeed() {
        var p = GPSSpeedProcessor()
        #expect(p.ingest(fix(20, at: 0, accuracy: 80), now: t0) == .poorAccuracy)
        #expect(p.ingest(fix(20, at: 1, accuracy: -1), now: t0 + 1) == .poorAccuracy)
        #expect(p.speed(at: t0 + 1) == nil)
    }

    // #25 / L7: NaN, infinite and negative speeds count as no speed (CoreLocation reports -1 for "invalid").
    @Test(arguments: [Double.nan, .infinity, -.infinity, -1, -0.01])
    func invalidSpeedValuesAreNoSpeed(_ value: Double) {
        var p = GPSSpeedProcessor()
        #expect(p.ingest(fix(value, at: 0), now: t0) == .invalidSpeed)
        #expect(p.speed(at: t0) == nil)
    }

    // #25 / L7: a sample older than, or as old as, the last accepted one is not a speed.
    @Test func backwardsAndRepeatedTimestampsAreRejected() {
        var p = GPSSpeedProcessor()
        p.ingest(fix(20, at: 1), now: t0 + 1)
        #expect(p.ingest(fix(30, at: 0.5), now: t0 + 1.2) == .notNewer)
        #expect(p.ingest(fix(30, at: 1), now: t0 + 1.2) == .notNewer)
        #expect(p.speed(at: t0 + 1.2)?.metersPerSecond == 20)
    }

    // #25 / L7: a sample stamped in the future is not a speed.
    @Test func futureTimestampIsRejected() {
        var p = GPSSpeedProcessor()
        #expect(p.ingest(fix(20, at: 5), now: t0) == .fromFuture)
        #expect(p.speed(at: t0) == nil)
        #expect(p.speed(at: t0 + 5) == nil)
    }

    // CoreLocation first delivers a cached fix; an already-expired sample is not a speed.
    @Test func sampleOlderThanMaxAgeOnArrivalIsRejected() {
        var p = GPSSpeedProcessor(maxAge: 2)
        #expect(p.ingest(fix(20, at: 0), now: t0 + 3) == .tooOld)
        #expect(p.speed(at: t0 + 3) == nil)
    }

    @Test func invalidateDropsSpeedButKeepsTheTimeHighWaterMark() {
        var p = GPSSpeedProcessor()
        p.ingest(fix(20, at: 1), now: t0 + 1)
        p.invalidate()
        #expect(p.speed(at: t0 + 1) == nil)
        #expect(p.ingest(fix(20, at: 0.5), now: t0 + 1.1) == .notNewer)
        #expect(p.ingest(fix(20, at: 1.5), now: t0 + 1.6) == nil)
    }
}
