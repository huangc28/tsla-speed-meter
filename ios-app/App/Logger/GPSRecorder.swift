@preconcurrency import CoreLocation
import Foundation

/// Phone GPS for the drive log: best-for-navigation fixes while recording,
/// handed on as `GPSFix` (no coordinates). When-in-use only, so updates stop
/// while the app is in the background.
@MainActor
final class GPSRecorder: NSObject {
    var onFix: ((GPSFix) -> Void)?
    var onStatus: ((String) -> Void)?

    private lazy var manager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = false
        return manager
    }()

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    static func describe(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: "notDetermined"
        case .restricted: "restricted"
        case .denied: "denied"
        case .authorizedAlways: "authorizedAlways"
        case .authorizedWhenInUse: "authorizedWhenInUse"
        @unknown default: "unknown"
        }
    }
}

extension GPSRecorder: @MainActor CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            onFix?(GPSFix(location))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onStatus?("authorization \(Self.describe(manager.authorizationStatus))")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        onStatus?("error \(error.localizedDescription)")
    }
}
