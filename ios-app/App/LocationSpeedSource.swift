import CoreLocation
import HUDCore

/// Phone GPS as a stream of `LocationEvent`s: when-in-use permission, best-for-navigation accuracy.
/// Validity is judged in HUDCore; this only translates CoreLocation.
@MainActor
final class LocationSpeedSource: NSObject, CLLocationManagerDelegate {
    private var manager: CLLocationManager?
    private var continuation: AsyncStream<LocationEvent>.Continuation?

    func events() -> AsyncStream<LocationEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { _ in
                Task { @MainActor in self.stop() }
            }
            start()
        }
    }

    private func start() {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .automotiveNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
        manager.delegate = self // reports the current authorization right away
        self.manager = manager
    }

    private func stop() {
        manager?.stopUpdatingLocation()
        manager?.delegate = nil
        manager = nil
        continuation = nil
    }

    private func authorizationChanged(_ authorization: LocationAuthorization) {
        continuation?.yield(.authorization(authorization))
        switch authorization {
        case .notDetermined: manager?.requestWhenInUseAuthorization()
        case .authorized: manager?.startUpdatingLocation()
        case .denied: manager?.stopUpdatingLocation()
        }
    }

    /// Approximate location gives no usable speed, so it counts as denied: "▲ GPS unavailable",
    /// not an endless search (01 §2 S02).
    nonisolated static func authorization(status: CLAuthorizationStatus,
                                          accuracy: CLAccuracyAuthorization) -> LocationAuthorization {
        switch status {
        case .notDetermined: .notDetermined
        case .authorizedWhenInUse, .authorizedAlways: accuracy == .fullAccuracy ? .authorized : .denied
        default: .denied // .denied, .restricted
        }
    }

    /// CoreLocation's fix as a HUDCore sample. Apple marks an invalid speed with a negative
    /// `speed` or a negative `speedAccuracy`; both become a negative (invalid) speed.
    /// The simulator reports `speedAccuracy` −1, so simulated routes show no speed.
    nonisolated static func sample(from location: CLLocation) -> GPSSample {
        GPSSample(
            speedMetersPerSecond: location.speedAccuracy < 0 ? -1 : location.speed,
            horizontalAccuracyMeters: location.horizontalAccuracy,
            timestamp: location.timestamp
        )
    }

    // CLLocationManager calls its delegate on the thread it was created on: the main thread here.

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorization = Self.authorization(status: manager.authorizationStatus,
                                               accuracy: manager.accuracyAuthorization)
        MainActor.assumeIsolated { authorizationChanged(authorization) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let samples = locations.map(Self.sample(from:))
        MainActor.assumeIsolated {
            for sample in samples { continuation?.yield(.sample(sample)) }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let denied = (error as? CLError)?.code == .denied
        MainActor.assumeIsolated {
            continuation?.yield(denied ? .authorization(.denied) : .failed)
        }
    }
}
