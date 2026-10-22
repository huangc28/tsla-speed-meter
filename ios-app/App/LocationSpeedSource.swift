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

    private func authorizationChanged(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            continuation?.yield(.authorization(.notDetermined))
            manager?.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            continuation?.yield(.authorization(.authorized))
            manager?.startUpdatingLocation()
        default: // .denied, .restricted
            continuation?.yield(.authorization(.denied))
            manager?.stopUpdatingLocation()
        }
    }

    // CLLocationManager calls its delegate on the thread it was created on: the main thread here.

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated { authorizationChanged(status) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let samples = locations.map { location in
            GPSSample(
                // A negative speed accuracy marks the speed itself invalid.
                speedMetersPerSecond: location.speedAccuracy < 0 ? -1 : location.speed,
                horizontalAccuracyMeters: location.horizontalAccuracy,
                timestamp: location.timestamp
            )
        }
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
