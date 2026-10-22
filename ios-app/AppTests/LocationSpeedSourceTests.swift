import CoreLocation
import HUDCore
import Testing
@testable import SpeedHUD

/// CoreLocation → HUDCore mapping, checked through the GPS validity rules it feeds.
struct LocationSpeedSourceTests {
    static let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    static func location(speed: Double, speedAccuracy: Double, horizontalAccuracy: Double = 5) -> CLLocation {
        CLLocation(coordinate: CLLocationCoordinate2D(latitude: 25.03, longitude: 121.56), altitude: 10,
                   horizontalAccuracy: horizontalAccuracy, verticalAccuracy: 5, course: 90, courseAccuracy: 5,
                   speed: speed, speedAccuracy: speedAccuracy, timestamp: now)
    }

    static func ingest(_ location: CLLocation) -> GPSRejection? {
        var processor = GPSSpeedProcessor()
        return processor.ingest(LocationSpeedSource.sample(from: location), now: now)
    }

    @Test func validSpeedAndAccuracyPassThrough() {
        let sample = LocationSpeedSource.sample(from: Self.location(speed: 20, speedAccuracy: 0.5))
        #expect(sample == GPSSample(speedMetersPerSecond: 20, horizontalAccuracyMeters: 5, timestamp: Self.now))
        #expect(Self.ingest(Self.location(speed: 20, speedAccuracy: 0.5)) == nil)
    }

    // Apple: a negative speedAccuracy means the speed is invalid (the simulator reports -1).
    @Test func negativeSpeedAccuracyIsNoSpeed() {
        let location = Self.location(speed: 20, speedAccuracy: -1)
        #expect(LocationSpeedSource.sample(from: location).speedMetersPerSecond < 0)
        #expect(Self.ingest(location) == .invalidSpeed)
    }

    @Test func negativeSpeedIsNoSpeed() {
        let location = Self.location(speed: -1, speedAccuracy: 0.5)
        #expect(LocationSpeedSource.sample(from: location).speedMetersPerSecond == -1)
        #expect(Self.ingest(location) == .invalidSpeed)
    }

    @Test func negativeHorizontalAccuracyIsNoFix() {
        let location = Self.location(speed: 20, speedAccuracy: 0.5, horizontalAccuracy: -1)
        #expect(LocationSpeedSource.sample(from: location).horizontalAccuracyMeters == -1)
        #expect(Self.ingest(location) == .poorAccuracy)
    }

    @Test func fullAccuracyPermissionIsAuthorized() {
        #expect(LocationSpeedSource.authorization(status: .authorizedWhenInUse, accuracy: .fullAccuracy) == .authorized)
        #expect(LocationSpeedSource.authorization(status: .authorizedAlways, accuracy: .fullAccuracy) == .authorized)
        #expect(LocationSpeedSource.authorization(status: .notDetermined, accuracy: .fullAccuracy) == .notDetermined)
    }

    // 01 §2 S02: approximate location counts as denied, so the HUD says "GPS unavailable".
    @Test func approximateLocationCountsAsDenied() {
        let authorization = LocationSpeedSource.authorization(status: .authorizedWhenInUse, accuracy: .reducedAccuracy)
        #expect(authorization == .denied)
        var engine = HUDEngine()
        engine.handle(.authorization(authorization), now: Self.now)
        let state = engine.state(at: Self.now + 30, unit: .kilometersPerHour)
        #expect(state.source == .gpsUnavailable)
        #expect(state.reason == .gpsUnavailable)
    }

    @Test func deniedAndRestrictedAreDenied() {
        #expect(LocationSpeedSource.authorization(status: .denied, accuracy: .fullAccuracy) == .denied)
        #expect(LocationSpeedSource.authorization(status: .restricted, accuracy: .fullAccuracy) == .denied)
    }
}
