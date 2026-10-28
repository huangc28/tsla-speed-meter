import Foundation

/// The car's navigation, from a drive reply (#77).
public enum CarNavigation: Equatable, Sendable {
    /// No destination is set: no route.
    case noRoute
    case route(CarRoute)
}

/// The car's active route, as reported. A part the car did not send is nil.
public struct CarRoute: Equatable, Sendable {
    public var destination: String
    public var minutesToArrival: Double?
    public var kilometersToArrival: Double?
    /// The battery level on arrival.
    // The car-run check (#77's human step) must confirm it is a percentage.
    public var energyAtArrival: Double?

    public init(destination: String, minutesToArrival: Double?, kilometersToArrival: Double?, energyAtArrival: Double?) {
        self.destination = destination
        self.minutesToArrival = minutesToArrival
        self.kilometersToArrival = kilometersToArrival
        self.energyAtArrival = energyAtArrival
    }
}

/// The drive screen's right panel while it is the car-navigation panel (L73 Q11, L84-4).
public enum NavigationPanel: Equatable, Sendable {
    case route(NavigationRoute)
    /// A fresh drive reply has no destination: the route is known to have ended, and the panel is
    /// empty (L84-4).
    case ended
    /// No fresh drive reply while on Car Bluetooth: a dashed destination pin in place, no words (L84-4).
    case stale
}

/// A route as shown: values are whole or to 0.1 as shown, so the state changes only when the screen
/// does. A part the car did not send is nil.
public struct NavigationRoute: Equatable, Sendable {
    public var destination: String
    /// Whole minutes to arrival.
    public var minutes: Int?
    /// Km, or miles in mph mode: to 0.1 under 10, whole from 10 (`7.5 mi`, `12 km`).
    public var distance: Double?
    /// The battery % on arrival, whole; nil hides the sentence (L78).
    public var arrivalPercent: Int?

    public init(destination: String, minutes: Int?, distance: Double?, arrivalPercent: Int?) {
        self.destination = destination
        self.minutes = minutes
        self.distance = distance
        self.arrivalPercent = arrivalPercent
    }

    init(_ route: CarRoute, unit: SpeedUnit) {
        destination = route.destination
        minutes = route.minutesToArrival.map { Int($0.rounded()) }
        distance = route.kilometersToArrival.map { km in
            let distance = unit.distance(fromKilometers: km)
            let tenths = (distance * 10).rounded() / 10
            return tenths < 10 ? tenths : distance.rounded()
        }
        arrivalPercent = route.energyAtArrival.map { Int($0.rounded()) }
    }
}

/// The car's navigation and what the drive screen's right panel shows (M12-04, L73 Q11). `HUDEngine`
/// owns it and updates it with the layout at each event, like the trip.
///
/// - Entering the drive layout (the first update, or the first after parked) chooses the panel once:
///   navigation if a fresh route is present, otherwise empty. Values then update in place.
/// - Q11: if it was not navigation, the first fresh route switches it to navigation once (`switches`
///   counts it; the view fades it in). It then stays navigation until drive is entered again, and only
///   a valid park leads there: the parked layout, the same auto-parked P that ends a trip, re-arms the
///   switch. A cancelled route (the panel is empty, L84-4), a new destination or a reconnect do not.
/// - The car's data is forgotten in the background, but the choice is kept: the panel's route comes
///   back in place, which is not a switch.
struct NavigationTracker: Sendable {
    /// The last drive reply's navigation, valid like the gear: for `HUDEngine.carMaxAge` from the
    /// phone receive time of the first reading that carried its car timestamp.
    private var last: (navigation: CarNavigation, validFrom: Date)?
    private var lastCarTimestamp: Date?
    /// The right panel is the navigation panel in this stretch of driving.
    private(set) var showsNavigation = false
    /// The layout at the last update; nil before the first.
    private var parked: Bool?
    /// Q11 switches so far.
    private(set) var switches = 0

    /// A drive reply's navigation, in order by car timestamp like the gear.
    mutating func ingest(_ navigation: CarNavigation, carTimestamp: Date, receivedAt: Date) {
        if let lastCarTimestamp, carTimestamp < lastCarTimestamp { return }
        let distinct = lastCarTimestamp.map { carTimestamp > $0 } ?? true
        // A repeated car timestamp keeps the window of its first arrival.
        let validFrom = distinct ? receivedAt : (last?.validFrom ?? receivedAt)
        last = (navigation, validFrom)
        lastCarTimestamp = carTimestamp
    }

    /// Background readings are void; the panel's choice stays.
    mutating func forgetCar() {
        last = nil
        lastCarTimestamp = nil
    }

    /// The navigation of a fresh drive reply; nil when none is fresh.
    func fresh(at now: Date) -> CarNavigation? {
        guard let last else { return nil }
        let age = now.timeIntervalSince(last.validFrom)
        return age >= -GPSSpeedProcessor.futureTolerance && age <= HUDEngine.carMaxAge ? last.navigation : nil
    }

    /// The layout at `now`: entering drive chooses the panel, and a fresh route may switch it once
    /// (Q11), but not while the car's fresh gear is P (`inPark`): like a trip, the switch waits for the
    /// car to leave P, so a car about to park on opening the app does not use it.
    mutating func update(at now: Date, parked: Bool, inPark: Bool) {
        defer { self.parked = parked }
        guard !parked else { return }
        let route = if case .route = fresh(at: now) { true } else { false }
        if self.parked != false {
            showsNavigation = route
        } else if !showsNavigation, route, !inPark {
            showsNavigation = true
            switches += 1
        }
    }

    /// The navigation panel at `now` while it is chosen; `onCar` says the car's data may show
    /// (linked and not on GPS, like the battery block).
    func panel(at now: Date, onCar: Bool, unit: SpeedUnit) -> NavigationPanel? {
        guard showsNavigation, onCar else { return nil }
        switch fresh(at: now) {
        case .route(let route)?: return .route(NavigationRoute(route, unit: unit))
        case .noRoute?: return .ended
        case nil: return .stale
        }
    }
}
