import Foundation
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// Renders the main drive-screen states to PNGs for visual review (no snapshot-testing
/// dependency), compares the main ones against committed references, and checks the numeral
/// font against DESIGN.md's floors.
///
/// - Review PNGs (2x) go to `ios-app/Snapshots/` (git-ignored).
/// - References (1x) live in `AppTests/References/`. Re-record after an intended visual change with
///   `TEST_RUNNER_RECORD_REFERENCES=1 xcodebuild test …`, look at the new PNGs, and commit them.
@MainActor
struct HUDRenderTests {
    struct Screen {
        let size: CGSize
        let left, right, bottom: CGFloat
        static let iPhone844 = Screen(size: CGSize(width: 844, height: 390), left: 59, right: 59, bottom: 21)
        static let iPhone667 = Screen(size: CGSize(width: 667, height: 375), left: 0, right: 0, bottom: 0)
    }

    static let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    /// `cards`: the parked cards (#79); by default 行程 and 胎壓, with the one-time card already
    /// dismissed, as in the master's ③.
    static func state(_ events: [LocationEvent], car: [CarEvent] = [], unit: SpeedUnit = .kilometersPerHour,
                      at seconds: TimeInterval = 0, cards: CardSwitcher = CardSwitcher(hintDismissed: true),
                      actions: [CardAction] = []) -> HUDState {
        var engine = HUDEngine(cards: cards)
        for event in events { engine.handle(event, now: t0) }
        for event in car { engine.handle(event, now: t0) }
        for action in actions { engine.handle(action, now: t0) }
        return engine.state(at: t0 + seconds, unit: unit)
    }

    /// A car speed that reached the phone `age` seconds before `t0`.
    static func car(_ kmh: Double, age: TimeInterval = 0, gear: CarGear? = nil,
                    battery: (percent: Int, rangeKm: Double)? = nil, closures: CarClosures? = nil) -> CarEvent {
        .reading(CarReading(receivedAt: t0 - age, carTimestamp: t0 - age, speedMetersPerSecond: kmh / 3.6, gear: gear,
                            batteryPercent: battery?.percent, rangeKilometers: battery?.rangeKm, closures: closures))
    }

    /// Doors, frunk and rear trunk (#78); every part closed unless given, so nothing is drawn. Nil is unknown.
    static func closures(frunk: Bool? = false, trunk: Bool? = false, doors: Bool? = false,
                         windows: [Bool?] = [false, false, false, false]) -> CarClosures {
        // The driver's door carries `doors`; unknown leaves all four out.
        CarClosures(frontTrunk: frunk, rearTrunk: trunk, doors: doors.map { [$0, false, false, false] } ?? [nil, nil, nil, nil],
                    windows: windows, carTime: t0)
    }

    /// Two drive readings in `gear`, 0.2 s apart, the last at `t0`: enough to show the gear row (L43).
    /// The battery, if any, and the closures (all closed by default) come with the last one; without
    /// a battery the block waits, and without closures every car-status slot is unknown.
    static func driving(_ kmh: Double, gear: CarGear, battery: (percent: Int, rangeKm: Double)? = nil,
                        closures: CarClosures? = closures()) -> [CarEvent] {
        [car(kmh, age: 0.2, gear: gear), car(kmh, gear: gear, battery: battery, closures: closures)]
    }

    /// A tire measured `minutesAgo` before `t0`, or at no known time.
    static func tire(_ psi: Double, minutesAgo: Double?) -> CarTire {
        CarTire(psi: psi, lastSeen: minutesAgo.map { t0 - $0 * 60 })
    }

    /// The master's four readings, 42 / 42 / 41 / 42 psi, all measured `minutesAgo` before `t0`.
    static func tires(minutesAgo: Double?) -> CarTires {
        CarTires(frontLeft: tire(42, minutesAgo: minutesAgo), frontRight: tire(42, minutesAgo: minutesAgo),
                 rearLeft: tire(41, minutesAgo: minutesAgo), rearRight: tire(42, minutesAgo: minutesAgo))
    }

    /// Two P readings 0.2 s apart, the last at `t0` with the battery, tires and closures (all closed
    /// by default), if any: enough for the parked screen (#50). `kmh` nil sends no speed.
    static func parked(kmh: Double? = 0, battery: (percent: Int, rangeKm: Double)? = (72, 315),
                       tires: CarTires? = nil, closures: CarClosures? = closures(),
                       navigation: CarNavigation? = nil, odometer: Double? = nil, climate: CarClimate? = nil) -> [CarEvent] {
        let speed = kmh.map { $0 / 3.6 }
        return [.reading(CarReading(receivedAt: t0 - 0.2, carTimestamp: t0 - 0.2, speedMetersPerSecond: speed, gear: .park,
                                    navigation: navigation)),
                .reading(CarReading(receivedAt: t0, carTimestamp: t0, speedMetersPerSecond: speed, gear: .park,
                                    batteryPercent: battery?.percent, rangeKilometers: battery?.rangeKm, tires: tires,
                                    navigation: navigation, closures: closures, odometerKilometers: odometer, climate: climate))]
    }

    /// A battery reading that reached the phone `minutes` before `t0`.
    static func battery(minutesAgo minutes: Double) -> CarEvent {
        .reading(CarReading(receivedAt: t0 - minutes * 60, carTimestamp: t0 - minutes * 60, batteryPercent: 72, rangeKilometers: 315))
    }

    static func gps(_ kmh: Double) -> LocationEvent {
        .sample(GPSSample(speedMetersPerSecond: kmh / 3.6, horizontalAccuracyMeters: 5, timestamp: t0))
    }

    static let snapshotDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Snapshots")
    static let referenceDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().appendingPathComponent("References")
    static var recordingReferences: Bool { ProcessInfo.processInfo.environment["RECORD_REFERENCES"] == "1" }

    /// The time every render shows: 14:05 in the simulator's time zone.
    static let now = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 27, hour: 14, minute: 5))!

    /// The drive-screen states pinned by reference images (#75), each at 844 and 667, in zh and en.
    nonisolated static let driveStateNames = ["ble-112", "ble-reverse", "gps-fallback-118", "gps-88", "waiting", "no-data"]
    nonisolated static let variants = [("844-zh", "zh-Hant"), ("844", "en"), ("667-zh", "zh-Hant"), ("667", "en")]
    nonisolated static let referenceNames = driveStateNames.flatMap { state in variants.map { "drive-\(state)-\($0.0)" } }
        + ["drive-mph-844", "invite-card-844-zh", "invite-card-667",
           // #49: `100% / 520 km` fits one line at 844 and wraps at 667.
           "drive-battery-waiting-844", "drive-battery-waiting-667-zh", "drive-battery-100-844", "drive-battery-100-667"]
        // #50: the parked screen with tires, waiting for the first readings, and with stale data;
        // 「P 檔」 with no speed, and per-wheel freshness.
        + parkedStateNames.flatMap { state in variants.map { "parked-\(state)-\($0.0)" } }
        + ["parked-p-unknown-844-zh", "parked-p-unknown-667", "parked-tire-mixed-844-zh", "parked-tire-mixed-667",
           // The car sends P but no speed; GPS supplies 0 and P is lit.
           "parked-gps-0-844-zh", "parked-gps-0-667"]
        + tripReferenceNames + navReferenceNames
        + carStatusReferenceNames + cardReferenceNames
    /// #76: the trip as in the master's `A-drive-ble`, `A-v-667`, `A-v-en` and `A-parked`: the drive
    /// panel, `—` with no speed, and the parked card with and without its battery group.
    nonisolated static let tripReferenceNames = ["drive-trip", "parked-trip"].flatMap { state in variants.map { "\(state)-\($0.0)" } }
        + ["drive-trip-no-speed-844-zh", "drive-trip-mph-844", "parked-trip-no-battery-844-zh", "parked-trip-no-battery-667"]
    /// #78: the car-status icons, as in the master's A-drive-ble (①), A-drive-ble-unknown (④),
    /// A-v-all-open and A-v-unknown3. They have no words, so one language per size.
    nonisolated static let carStatusReferenceNames: [String] =
        carStatusNames.flatMap { ["drive-status-\($0)-844-zh", "drive-status-\($0)-667"] } + ["parked-status-door-844-zh"]
    /// A pixel differs when any channel moves by more than this (of 255); the render fails
    /// when more than `maxDifferingPixels` differ. A source-marker swap alone is about 140 px.
    static let channelTolerance = 16
    static let maxDifferingPixels = 40

    /// What the drive screen shows besides the HUD state: the gear's setup dot and the
    /// first-launch invitation, both only while no car is paired.
    enum Chrome {
        case paired, unpaired, invite
    }

    /// The pinned states: ● Car Bluetooth in D, reversing in R, ◐ GPS fallback with the amber cue,
    /// ● GPS with the green cue (no paired car), ◌ waiting, ▲ no data. The gear row and battery
    /// show only on the first two.
    static let driveStates: [String: (state: HUDState, chrome: Chrome)] = [
        "ble-112": (state([.authorization(.authorized), gps(110)], car: driving(112, gear: .drive, battery: (72, 315))), .paired),
        "ble-reverse": (state([.authorization(.authorized)], car: driving(-6, gear: .reverse, battery: (72, 315))), .paired),
        "gps-fallback-118": (state([.authorization(.authorized), gps(118)], car: [car(121, age: 3)]), .paired),
        "gps-88": (state([.authorization(.authorized), gps(88)]), .unpaired),
        "waiting": (state([]), .paired),
        "no-data": (state([.authorization(.authorized), gps(72)], at: 3), .paired),
    ]

    nonisolated static let parkedStateNames = ["tires", "waiting", "stale"]

    nonisolated static let carStatusNames = ["trunk", "trunk-door-unknown", "all-open", "all-unknown"]

    /// ● Car Bluetooth at 112 in D with battery / range, as `ble-112`: ① the rear trunk open; ④ the
    /// rear trunk open and the doors unknown (the reply left them out); all three open; and all three
    /// unknown (connected, no closures reply yet).
    static let carStatusStates: [String: HUDState] = [
        "trunk": state([.authorization(.authorized), gps(110)],
                       car: driving(112, gear: .drive, battery: (72, 315), closures: closures(trunk: true))),
        "trunk-door-unknown": state([.authorization(.authorized), gps(110)],
                                    car: driving(112, gear: .drive, battery: (72, 315), closures: closures(trunk: true, doors: nil))),
        "all-open": state([.authorization(.authorized), gps(110)],
                          car: driving(112, gear: .drive, battery: (72, 315), closures: closures(frunk: true, trunk: true, doors: true))),
        "all-unknown": state([.authorization(.authorized), gps(110)],
                             car: driving(112, gear: .drive, battery: (72, 315), closures: nil)),
    ]

    /// The parked screen (#50), as in the master's `A-parked`, `A-v-tire-*` and `A-v-p-unknown`:
    /// P lit, 0 km/h, readings 3 minutes old; waiting: `—` × 4 with 尚無讀值 and `—% / — km`;
    /// stale: every wheel 18 minutes old and a battery value 3 minutes old.
    static let parkedStates: [String: HUDState] = [
        "tires": state([.authorization(.authorized)], car: parked(tires: tires(minutesAgo: 3))),
        "waiting": state([.authorization(.authorized)], car: parked(battery: nil)),
        "stale": state([.authorization(.authorized)],
                       car: [battery(minutesAgo: 3)] + parked(battery: nil, tires: tires(minutesAgo: 18))),
        "p-unknown": state([.authorization(.authorized)], car: parked(kmh: nil, tires: tires(minutesAgo: 3))),
        "gps-0": state([.authorization(.authorized), gps(0)], car: parked(kmh: nil, tires: tires(minutesAgo: 3))),
        "tire-mixed": state([.authorization(.authorized)], car: parked(tires: CarTires(
            frontLeft: tire(42, minutesAgo: 1), frontRight: tire(42, minutesAgo: 18),
            rearLeft: tire(41, minutesAgo: nil), rearRight: nil))),
        "tire-unknown": state([.authorization(.authorized)], car: parked(tires: tires(minutesAgo: nil))),
        "tire-none": {
            var none = state([.authorization(.authorized)], car: parked())
            none.tires = .notSupported
            return none
        }(),
    ]

    /// The master's trip: 12.4 km, 38 and 76 km/h, 18 minutes driving (19 parked), −4%.
    static func withTrip(_ state: HUDState, distance: Double? = 12.4, minutes: Int = 18,
                         batteryChange: Int? = -4) -> HUDState {
        var state = state
        state.trip = TripSummary(distance: distance, driveMinutes: minutes, averageSpeed: distance.map { _ in 38 },
                                 maxSpeed: 76, batteryChange: batteryChange)
        return state
    }

    static let tripStates: [String: (state: HUDState, chrome: Chrome)] = [
        "drive-trip": (withTrip(driveStates["ble-112"]!.state), .paired),
        "parked-trip": (withTrip(parkedStates["tires"]!, minutes: 19), .paired),
        "drive-trip-no-speed": (withTrip(driveStates["no-data"]!.state, distance: nil), .paired),
        "drive-trip-mph": (withTrip(state([.authorization(.authorized)], car: driving(70, gear: .drive, battery: (72, 315)),
                                          unit: .milesPerHour), distance: 7.7), .paired),
        "parked-trip-no-battery": (withTrip(parkedStates["tires"]!, minutes: 19, batteryChange: nil), .paired),
    ]

    /// #77: the car's navigation as in the master's `A-drive-ble`, `A-v-667`, `A-v-en`, `A-v-mph`,
    /// `A-v-nav-stale`, `A-v-nav-ended` and `A-v-147-dest` (an ellipsis).
    nonisolated static let navReferenceNames = variants.map { "drive-nav-\($0.0)" }
        + ["drive-nav-stale-844-zh", "drive-nav-stale-667", "drive-nav-ended-844-zh", "drive-nav-long-dest-844-zh",
           "drive-nav-long-dest-667", "drive-nav-mph-844", "drive-nav-no-arrival-844-zh"]

    /// The master's route: 台北車站 (Taipei Main Station in English), 18 minutes, 12 km, 64% on arrival.
    static func withNavigation(_ state: HUDState, _ navigation: NavigationPanel? = nil, destination: String = "台北車站",
                               distance: Double = 12, arrivalPercent: Int? = 64) -> HUDState {
        var state = state
        state.navigation = navigation ?? .route(NavigationRoute(destination: destination, minutes: 18, distance: distance,
                                                                arrivalPercent: arrivalPercent))
        return state
    }

    static let longDestination = "國立臺灣大學醫學院附設醫院急診部"

    /// On top of the trip; the stale pin's state is built directly, since the route and the speed come in
    /// the same reply (the engine shows the pin with ▲ or GPS fallback, never beside a car speed).
    static let navStates: [String: HUDState] = [
        "drive-nav": withNavigation(tripStates["drive-trip"]!.state),
        "drive-nav-stale": withNavigation(tripStates["drive-trip"]!.state, .stale),
        "drive-nav-ended": withNavigation(tripStates["drive-trip"]!.state, .ended),
        "drive-nav-long-dest": withNavigation(withTrip(state([.authorization(.authorized)],
                                                             car: driving(147, gear: .drive, battery: (72, 315)))),
                                              destination: longDestination),
        "drive-nav-mph": withNavigation(tripStates["drive-trip-mph"]!.state, distance: 7.5),
        "drive-nav-no-arrival": withNavigation(tripStates["drive-trip"]!.state, arrivalPercent: nil),
    ]

    static let navCases: [(name: String, state: HUDState, screen: Screen, locale: String, chrome: Chrome)] =
        navStates.keys.sorted().flatMap { name in
            variants.map { variant, locale in
                var state = navStates[name]!
                // English names the master's destination in English.
                if locale == "en", case .route(var route) = state.navigation, route.destination == "台北車站" {
                    route.destination = "Taipei Main Station"
                    state.navigation = .route(route)
                }
                return ("\(name)-\(variant)", state, variant.hasPrefix("844") ? .iPhone844 : .iPhone667, locale, Chrome.paired)
            }
        }

    static let tripCases: [(name: String, state: HUDState, screen: Screen, locale: String, chrome: Chrome)] =
        tripStates.keys.sorted().flatMap { name in
            variants.map { variant, locale in
                ("\(name)-\(variant)", tripStates[name]!.state, variant.hasPrefix("844") ? .iPhone844 : .iPhone667,
                 locale, tripStates[name]!.chrome)
            }
        }

    static let carStatusCases: [(name: String, state: HUDState, screen: Screen, locale: String, chrome: Chrome)] =
        carStatusNames.flatMap { name -> [(name: String, state: HUDState, screen: Screen, locale: String, chrome: Chrome)] in
            [("drive-status-\(name)-844-zh", carStatusStates[name]!, .iPhone844, "zh-Hant", .paired),
             ("drive-status-\(name)-667", carStatusStates[name]!, .iPhone667, "en", .paired)]
        } + [
            // Parked shows them too: a door open with the tires (#50).
            ("parked-status-door-844-zh", state([.authorization(.authorized)],
                                                car: parked(tires: tires(minutesAgo: 3), closures: closures(doors: true))),
             .iPhone844, "zh-Hant", .paired),
        ]

    /// #79: the parked cards, as in the master's `A-v-park-nav` (the route, and 「車上沒有在導航」) and
    /// `A-v-park-vehicle` (all closed, and a window open), and the right card's list open over the tire panel. Each at 844 in Chinese and 667 in English; kept apart
    /// from the lists above so the type checker keeps up.
    nonisolated static let cardNames = ["parked-nav", "parked-nav-ended", "parked-list", "parked-vehicle", "parked-vehicle-open"]
    nonisolated static let cardReferenceNames: [String] = cardNames.flatMap { ["\($0)-844-zh", "\($0)-667"] }

    /// The master's route parked, in English as in `navCases`.
    static func parkedRoute(english: Bool) -> CarNavigation {
        .route(CarRoute(destination: english ? "Taipei Main Station" : "台北車站", minutesToArrival: 18,
                        kilometersToArrival: 12, energyAtArrival: 64))
    }

    /// The master's parked trip (`parked-trip`) beside the chosen right card.
    static func cardState(_ name: String, english: Bool) -> HUDState {
        let navigation = CardSwitcher(right: .navigation, hintDismissed: true)
        let state = switch name {
        case "parked-nav":
            state([.authorization(.authorized)], car: parked(tires: tires(minutesAgo: 3), navigation: parkedRoute(english: english)),
                  cards: navigation)
        case "parked-list":
            state([.authorization(.authorized)], car: parked(tires: tires(minutesAgo: 3)), actions: [.toggleList(.right)])
        // The master's 車況 (12,345 km, 23°, 26°, all closed); and with the rear-left window open.
        case "parked-vehicle", "parked-vehicle-open":
            state([.authorization(.authorized)],
                  car: parked(tires: tires(minutesAgo: 3),
                              closures: closures(windows: [false, name == "parked-vehicle-open", false, false]),
                              odometer: 12_345.6, climate: CarClimate(outsideCelsius: 23, insideCelsius: 26)),
                  cards: CardSwitcher(left: .vehicle, hintDismissed: true))
        default:
            state([.authorization(.authorized)], car: parked(tires: tires(minutesAgo: 3), navigation: .noRoute), cards: navigation)
        }
        return withTrip(state, minutes: 19)
    }

    static let cardCases: [(name: String, state: HUDState, screen: Screen, locale: String, chrome: Chrome)] =
        cardNames.flatMap { name -> [(name: String, state: HUDState, screen: Screen, locale: String, chrome: Chrome)] in
            [("\(name)-844-zh", cardState(name, english: false), .iPhone844, "zh-Hant", .paired),
             ("\(name)-667", cardState(name, english: true), .iPhone667, "en", .paired)]
        }

    static let cases: [(name: String, state: HUDState, screen: Screen, locale: String, chrome: Chrome)] =
        driveStateNames.flatMap { name in
            variants.map { variant, locale in
                ("drive-\(name)-\(variant)", driveStates[name]!.state, variant.hasPrefix("844") ? .iPhone844 : .iPhone667,
                 locale, driveStates[name]!.chrome)
            }
        } + parkedStates.keys.sorted().flatMap { name in
            variants.map { variant, locale in
                ("parked-\(name)-\(variant)", parkedStates[name]!, variant.hasPrefix("844") ? .iPhone844 : .iPhone667,
                 locale, Chrome.paired)
            }
        } + tripCases + navCases + carStatusCases + cardCases + [
            ("drive-gps-0-844", state([.authorization(.authorized), gps(0)]), .iPhone844, "en", .unpaired),
            ("drive-gps-7-844", state([.authorization(.authorized), gps(7)]), .iPhone844, "en", .unpaired),
            ("drive-gps-147-844", state([.authorization(.authorized), gps(147)]), .iPhone844, "en", .unpaired),
            ("drive-gps-147-667", state([.authorization(.authorized), gps(147)]), .iPhone667, "en", .unpaired),
            ("drive-ble-207-844", state([.authorization(.authorized)], car: [car(207)]), .iPhone844, "en", .paired),
            // mph: the unit ink is narrower, so the GPS cue sits further right.
            ("drive-mph-844", state([.authorization(.authorized), gps(72)], car: [car(75, age: 3)], unit: .milesPerHour),
             .iPhone844, "en", .paired),
            ("drive-battery-waiting-844", state([.authorization(.authorized)], car: driving(64, gear: .drive)),
             .iPhone844, "en", .paired),
            ("drive-battery-waiting-667-zh", state([.authorization(.authorized)], car: driving(64, gear: .drive)),
             .iPhone667, "zh-Hant", .paired),
            ("drive-battery-100-844", state([.authorization(.authorized)], car: driving(64, gear: .drive, battery: (100, 520))),
             .iPhone844, "en", .paired),
            ("drive-battery-100-667", state([.authorization(.authorized)], car: driving(64, gear: .drive, battery: (100, 520))),
             .iPhone667, "en", .paired),
            ("drive-battery-1015-844", state([.authorization(.authorized)], car: driving(64, gear: .drive, battery: (100, 1015))),
             .iPhone844, "en", .paired),
            ("drive-battery-mph-844", state([.authorization(.authorized)], car: driving(64, gear: .drive, battery: (72, 315)),
                                            unit: .milesPerHour), .iPhone844, "en", .paired),
            ("drive-searching-844-zh", state([.authorization(.authorized)]), .iPhone844, "zh-Hant", .unpaired),
            ("drive-permission-denied-844", state([.authorization(.denied)]), .iPhone844, "en", .unpaired),
            // #55: the first-launch invitation (L66) over the GPS drive screen.
            ("invite-card-844-zh", state([.authorization(.authorized), gps(72)]), .iPhone844, "zh-Hant", .invite),
            ("invite-card-844", state([.authorization(.authorized), gps(72)]), .iPhone844, "en", .invite),
            ("invite-card-667-zh", state([.authorization(.authorized), gps(112)]), .iPhone667, "zh-Hant", .invite),
            ("invite-card-667", state([.authorization(.authorized), gps(112)]), .iPhone667, "en", .invite),
        ]

    @Test func numeralFontsAreBundled() {
        #expect(UIFont(name: HUDFont.regular, size: 10) != nil)
        #expect(UIFont(name: HUDFont.medium, size: 10) != nil)
        #expect(UIFont(name: HUDFont.bold, size: 10) != nil)
        for name in [HUDFont.interRegular, HUDFont.interMedium, HUDFont.interSemiBold, HUDFont.interBold] {
            #expect(UIFont(name: name, size: 10) != nil, "\(name)")
        }
    }

    /// A parked trip card taller than its panel is a `ScrollView`, which `ImageRenderer` cannot draw:
    /// such a screen renders in a window (`PairingRenderTests.renderInWindow`).
    static func needsWindow(_ state: HUDState, screen: Screen, locale: Locale) -> Bool {
        guard state.layout == .parked, let panels = state.panels else { return false }
        let layout = DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
        return LeftCardView.scrolls(state, deck: panels.left, locale: locale, size: layout.leftPanel.size)
    }

    static func render(_ name: String, scale: CGFloat) throws -> UIImage {
        let item = try #require(cases.first { $0.name == name })
        let locale = Locale(identifier: item.locale)
        let view = DriveScreen(state: item.state, now: now, screen: item.screen.size, leftInset: item.screen.left,
                               rightInset: item.screen.right, bottomInset: item.screen.bottom,
                               setupPending: item.chrome != .paired, showsInvite: item.chrome == .invite)
            .environment(\.locale, locale)
        if needsWindow(item.state, screen: item.screen, locale: locale) {
            let image = try PairingRenderTests.renderInWindow(view.transaction { $0.animation = nil },
                                                              size: item.screen.size, scale: scale)
            #expect(image.size == item.screen.size)
            return image
        }
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(item.screen.size)
        renderer.scale = scale
        let image = try #require(renderer.uiImage, "\(name) did not render")
        #expect(image.size == item.screen.size)
        return image
    }

    @Test func rendersMainStatesToPNG() throws {
        try FileManager.default.createDirectory(at: Self.snapshotDirectory, withIntermediateDirectories: true)
        for item in Self.cases {
            let data = try #require(Self.render(item.name, scale: 2).pngData())
            try data.write(to: Self.snapshotDirectory.appendingPathComponent("\(item.name).png"))
        }
    }

    @Test(arguments: referenceNames)
    func matchesReference(_ name: String) throws {
        let image = try Self.render(name, scale: 1)
        let url = Self.referenceDirectory.appendingPathComponent("\(name).png")
        if Self.recordingReferences {
            try FileManager.default.createDirectory(at: Self.referenceDirectory, withIntermediateDirectories: true)
            try #require(image.pngData()).write(to: url)
            return
        }
        let reference = try #require(UIImage(contentsOfFile: url.path)?.cgImage,
                                     "No reference \(name).png; record with TEST_RUNNER_RECORD_REFERENCES=1")
        let actual = try #require(image.cgImage)
        let expected = try Self.rgba(reference), rendered = try Self.rgba(actual)
        #expect(reference.width == actual.width && reference.height == actual.height, "size changed")
        guard expected.count == rendered.count else { return }
        let differing = Self.differingPixels(expected, rendered)
        if differing > Self.maxDifferingPixels {
            try FileManager.default.createDirectory(at: Self.snapshotDirectory, withIntermediateDirectories: true)
            try image.pngData()?.write(to: Self.snapshotDirectory.appendingPathComponent("\(name)-actual.png"))
        }
        #expect(differing <= Self.maxDifferingPixels,
                "\(name): \(differing) pixels differ from the reference; see Snapshots/\(name)-actual.png")
    }

    /// Pixels where any channel differs by more than `channelTolerance`.
    static func differingPixels(_ a: [UInt8], _ b: [UInt8]) -> Int {
        var differing = 0
        for pixel in stride(from: 0, to: a.count, by: 4)
        where (0..<4).contains(where: { abs(Int(a[pixel + $0]) - Int(b[pixel + $0])) > channelTolerance }) {
            differing += 1
        }
        return differing
    }

    /// Pixels as premultiplied RGBA bytes in device RGB.
    static func rgba(_ image: CGImage) throws -> [UInt8] {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = try #require(CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8,
                                              bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }

    /// A driving screen at 1x, as RGBA bytes; in a window when `inWindow`.
    static func render(_ state: HUDState, screen: Screen, inWindow: Bool = false) throws -> [UInt8] {
        let view = DriveScreen(state: state, now: now, screen: screen.size, leftInset: screen.left,
                               rightInset: screen.right, bottomInset: screen.bottom)
        if inWindow {
            let image = try PairingRenderTests.renderInWindow(view.transaction { $0.animation = nil }, size: screen.size, scale: 1)
            return try rgba(try #require(image.cgImage))
        }
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(screen.size)
        renderer.scale = 1
        return try rgba(try #require(renderer.cgImage))
    }

    /// The 844 driving screen at 1x, optionally with a different state or an overlay.
    static func render844(_ state: HUDState, overlay: some View = EmptyView()) throws -> [UInt8] {
        let screen = Screen.iPhone844
        let view = DriveScreen(state: state, now: now, screen: screen.size, leftInset: screen.left,
                               rightInset: screen.right, bottomInset: screen.bottom)
            .overlay(alignment: .topLeading) { overlay }
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(screen.size)
        renderer.scale = 1
        return try rgba(try #require(renderer.cgImage))
    }

    // #48: showing or hiding `P R N D` moves the numeral 0 px. Everything that changes lies in
    // the row's band above the numeral, at 844 and at 667.
    @Test(arguments: [Screen.iPhone844, .iPhone667], [CarGear.drive, .reverse])
    func gearRowMovesNothingElse(screen: Screen, gear: CarGear) throws {
        let shown = Self.state([.authorization(.authorized)], car: Self.driving(88, gear: gear))
        #expect(shown.gearRow == gear)
        var hidden = shown
        hidden.gearRow = nil
        let a = try Self.render(shown, screen: screen), b = try Self.render(hidden, screen: screen)
        let layout = DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
        let band = CGRect(x: layout.gaugeArea.midX - GearRow.width / 2, y: layout.gearRowBaselineY - GearRow.capHeight - 2,
                          width: GearRow.width, height: GearRow.capHeight + 2 + GearRow.underlineOffset + GearRow.underlineHeight + 2)
        let (inBand, outside) = Self.changedPixels(a, b, width: Int(screen.size.width), inside: band)
        #expect(inBand > 100, "the row did not draw")
        #expect(outside == 0, "\(outside) pixels changed outside the gear row")
    }

    // #49: the battery block, one line or wrapped, stays in its bottom-left slot (two lines grow
    // up by 2 at 844, as in the master).
    @Test(arguments: [Screen.iPhone844, .iPhone667], [(72, 315.0), (100, 1015)])
    func batteryBlockStaysInItsSlot(screen: Screen, battery: (Int, Double)) throws {
        let shown = Self.state([.authorization(.authorized)], car: Self.driving(88, gear: .drive, battery: battery))
        #expect(shown.battery != nil)
        var hidden = shown
        hidden.battery = nil
        let a = try Self.render(shown, screen: screen), b = try Self.render(hidden, screen: screen)
        let layout = DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
        let slot = layout.batterySlot.insetBy(dx: 0, dy: -2).offsetBy(dx: 0, dy: -2)
        let (inSlot, outside) = Self.changedPixels(a, b, width: Int(screen.size.width), inside: slot)
        #expect(inSlot > 100, "the block did not draw")
        #expect(outside == 0, "\(outside) pixels changed outside the battery slot")
    }

    // #50 (L31): the parked layout draws the gauge exactly where and how the drive layout does;
    // everything that changes lies outside the gauge area.
    @Test(arguments: [Screen.iPhone844, .iPhone667], ["tires", "stale"])
    func parkedGaugeIsTheDriveGauge(screen: Screen, name: String) throws {
        let parked = try #require(Self.parkedStates[name])
        #expect(parked.layout == .parked)
        var drive = parked
        drive.layout = .drive
        drive.tires = nil
        let a = try Self.render(parked, screen: screen), b = try Self.render(drive, screen: screen)
        let layout = DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
        let (inGauge, outside) = Self.changedPixels(a, b, width: Int(screen.size.width), inside: layout.gaugeArea)
        #expect(outside > 100, "the parked layout drew nothing of its own")
        #expect(inGauge == 0, "\(inGauge) pixels changed inside the gauge area")
    }

    // #76: the trip draws only inside the left panel, driving and parked, at 844 and at 667.
    @Test(arguments: [Screen.iPhone844, .iPhone667], ["drive-trip", "parked-trip", "parked-trip-no-battery"])
    func tripStaysInTheLeftPanel(screen: Screen, name: String) throws {
        let shown = try #require(Self.tripStates[name]?.state)
        var hidden = shown
        hidden.trip = nil
        // Both the same way, so only the card can differ.
        let inWindow = Self.needsWindow(shown, screen: screen, locale: .current)
        let a = try Self.render(shown, screen: screen, inWindow: inWindow)
        let b = try Self.render(hidden, screen: screen, inWindow: inWindow)
        let layout = DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
        // A window render antialiases the scrolling card's edge 1 px into its neighbors (by 1–3 of 255).
        let panel = inWindow ? layout.leftPanel.insetBy(dx: -2, dy: -2) : layout.leftPanel
        let (inPanel, outside) = Self.changedPixels(a, b, width: Int(screen.size.width), inside: panel)
        #expect(inPanel > 100, "the trip did not draw")
        #expect(outside == 0, "\(outside) pixels changed outside the left panel")
    }

    // #77: navigation and its stale pin draw only inside the right panel, at 844 and at 667; a long
    // destination ends in an ellipsis inside it.
    @Test(arguments: [Screen.iPhone844, .iPhone667], ["drive-nav", "drive-nav-stale", "drive-nav-long-dest"])
    func navigationStaysInTheRightPanel(screen: Screen, name: String) throws {
        let shown = try #require(Self.navStates[name])
        var hidden = shown
        hidden.navigation = nil
        let a = try Self.render(shown, screen: screen), b = try Self.render(hidden, screen: screen)
        let layout = DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
        let (inPanel, outside) = Self.changedPixels(a, b, width: Int(screen.size.width), inside: layout.rightPanel)
        #expect(inPanel > 100, "the panel did not draw")
        #expect(outside == 0, "\(outside) pixels changed outside the right panel")
        // Parked, the right panel is the tire panel: navigation is not drawn (#79 makes it a card).
        var parked = try #require(Self.parkedStates["tires"])
        let parkedPixels = try Self.render(parked, screen: screen)
        parked.navigation = shown.navigation
        #expect(Self.differingPixels(try Self.render(parked, screen: screen), parkedPixels) == 0)
    }

    // #77: the Q11 switch fades over 0.2 s, and switches at once with Reduce Motion (L73).
    @Test func navigationFadeFollowsReduceMotion() {
        #expect(DriveScreen.navigationFade(reduceMotion: true) == nil)
        #expect(DriveScreen.navigationFade(reduceMotion: false) == .easeInOut(duration: 0.2))
    }

    @Test func navigationText() {
        #expect(NavigationCopy.distance(12) == "12")
        #expect(NavigationCopy.distance(7.5) == "7.5")
        #expect(NavigationCopy.distance(0) == "0.0")
        let route = NavigationRoute(destination: "Taipei Main Station", minutes: 18, distance: 12, arrivalPercent: 64)
        let en = NavigationCopy(route: route, unit: .kilometersPerHour, locale: Locale(identifier: "en"))
        #expect(en.remainingLabel == "Remaining")
        #expect(en.separator == "·")
        #expect(en.minutesUnit == "min")
        #expect(en.arrival == "About 64% on arrival")
        #expect(en.spoken == "Destination Taipei Main Station, Remaining 18 min and 12 kilometers, About 64% on arrival")
        let zh = NavigationCopy(route: route, unit: .milesPerHour, locale: Locale(identifier: "zh-Hant"))
        #expect(zh.separator == "・")
        #expect(zh.minutesUnit == "分")
        #expect(zh.distanceUnit == "mi")
        #expect(zh.arrival == "抵達時約剩 64%")
        let partial = NavigationCopy(route: NavigationRoute(destination: "", minutes: nil, distance: 7.5, arrivalPercent: nil),
                                     unit: .milesPerHour, locale: Locale(identifier: "zh-Hant"))
        #expect(partial.destination == "導航中")
        #expect(partial.minutes == "—" && partial.minutesUnit == nil)
        #expect(partial.arrival == nil)
        #expect(partial.spoken == "導航中,剩餘 7.5 英里")
    }

    // The screens rendered in a window are the same twice, so their references can be pinned.
    @Test func windowRendersAreRepeatable() throws {
        let names = Self.referenceNames.filter { name in
            Self.cases.first { $0.name == name }.map {
                Self.needsWindow($0.state, screen: $0.screen, locale: Locale(identifier: $0.locale))
            } ?? false
        }
        #expect(names.count >= 3, "\(names)")
        for name in names {
            let a = try Self.rgba(try #require(Self.render(name, scale: 1).cgImage))
            let b = try Self.rgba(try #require(Self.render(name, scale: 1).cgImage))
            #expect(Self.differingPixels(a, b) == 0, "\(name)")
        }
    }

    @Test func tripText() {
        #expect(TripCopy.driveTime(minutes: 0) == "0:00")
        #expect(TripCopy.driveTime(minutes: 18) == "0:18")
        #expect(TripCopy.driveTime(minutes: 125) == "2:05")
        #expect(TripCopy.signed(-4) == "\u{2212}4")
        #expect(TripCopy.signed(3) == "+3")
        #expect(TripCopy.signed(0) == "0")
        let trip = TripSummary(distance: 12.4, driveMinutes: 18, averageSpeed: 38, maxSpeed: 76, batteryChange: -4)
        let copy = TripCopy(trip: trip, unit: .milesPerHour, locale: Locale(identifier: "en"))
        #expect(copy.distance == "12.4" && copy.distanceUnit == "mi")
        #expect(copy.speedUnit(copy.max) == "mph")
        var dash = trip
        dash.distance = nil
        dash.averageSpeed = nil
        let dashCopy = TripCopy(trip: dash, unit: .kilometersPerHour, locale: Locale(identifier: "en"))
        #expect(dashCopy.distance == "—" && dashCopy.distanceUnit == nil)
        #expect(dashCopy.speedUnit(dashCopy.average) == nil)
    }

    @Test func parkedDateAndTime() {
        #expect(ClockText.text(Self.now, showsDate: true) == "10/27(二) 14:05")
        #expect(ClockText.text(Self.now, showsDate: false) == "14:05")
    }

    @Test func batteryText() {
        #expect(BatteryBlockView.parts(.value(percent: 72, range: 315), unit: .kilometersPerHour) == ("72%", "315 km"))
        #expect(BatteryBlockView.parts(.value(percent: 100, range: 1015), unit: .kilometersPerHour) == ("100%", "1,015 km"))
        #expect(BatteryBlockView.parts(.value(percent: 72, range: 196), unit: .milesPerHour) == ("72%", "196 mi"))
        #expect(BatteryBlockView.parts(.value(percent: 72, range: nil), unit: .kilometersPerHour) == ("72%", "— km"))
        #expect(BatteryBlockView.parts(.waiting, unit: .kilometersPerHour) == ("—%", "— km"))
        #expect(BatteryBlockView.parts(.stale(percent: 72, range: 196, ageMinutes: 3), unit: .milesPerHour) == ("—%", "— mi"))
    }

    /// Pixels that differ between `a` and `b`, inside and outside `rect` (screen points at 1x).
    static func changedPixels(_ a: [UInt8], _ b: [UInt8], width: Int, inside rect: CGRect) -> (inside: Int, outside: Int) {
        var inside = 0, outside = 0
        for pixel in stride(from: 0, to: a.count, by: 4)
        where (0..<4).contains(where: { a[pixel + $0] != b[pixel + $0] }) {
            let point = CGPoint(x: CGFloat(pixel / 4 % width) + 0.5, y: CGFloat(pixel / 4 / width) + 0.5)
            if rect.contains(point) { inside += 1 } else { outside += 1 }
        }
        return (inside, outside)
    }

    // A real visual change (another speed) must fail the comparison.
    @Test func comparisonCatchesAChangedNumeral() throws {
        let a = try Self.render844(Self.state([.authorization(.authorized), Self.gps(72)]))
        let b = try Self.render844(Self.state([.authorization(.authorized), Self.gps(73)]))
        #expect(Self.differingPixels(a, b) > Self.maxDifferingPixels)
    }

    // Swapping only the chip icon (green arrow for amber ▲) must fail the comparison too.
    @Test func comparisonCatchesAChipIconSwap() throws {
        let driving = Self.state([.authorization(.authorized), Self.gps(72)])
        let a = try Self.render844(driving)
        // Cover the 20 pt arrow at the chip origin (75, 16 + 4) and draw ▲ in its place.
        let swap = ZStack {
            Rectangle().fill(Palette.backgroundGlow)
            LucideIconView(icon: .triangleAlert, size: 20, color: Palette.sourceDegraded)
        }
        .frame(width: 22, height: 22)
        .offset(x: 74, y: 19)
        let b = try Self.render844(driving, overlay: swap)
        let differing = Self.differingPixels(a, b)
        #expect(differing > Self.maxDifferingPixels, "marker swap changed only \(differing) pixels")
    }

    // L46 / R7-01: vertical stems ≥9 px at 844 and ≥8.5 px at 667, and ≥ digit height ÷ 12.
    @Test(arguments: [(CGFloat(300), CGFloat(9)), (280, 8.5)])
    func numeralStemWidthMeetsFloor(gaugeSize: CGFloat, floor: CGFloat) throws {
        let font = HUDFont.barlow(HUDFont.regular, size: GaugeGeometry(size: gaugeSize).numeralFontSize)
        let digitHeight = HUDFont.inkBounds("0", font: font, tracking: 0).height
        let stem = try Self.stemWidth(of: "1", font: font)
        #expect(stem >= floor, "stem \(stem) at \(font.pointSize) pt")
        #expect(stem >= digitHeight / 12, "stem \(stem) vs height \(digitHeight)")
    }

    /// Width of the stroke crossing the middle row of `glyph`, from antialiased coverage.
    static func stemWidth(of glyph: String, font: UIFont) throws -> CGFloat {
        let scale: CGFloat = 4
        let view = Text(verbatim: glyph).font(Font(font)).foregroundStyle(.white)
            .padding(10).background(.black)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        let cgImage = try #require(renderer.cgImage)
        let width = cgImage.width, height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = try #require(CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8,
                                              bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        // Middle of the ink rows.
        let inkRows = (0..<height).filter { y in (0..<width).contains { pixels[(y * width + $0) * 4] > 128 } }
        let row = try #require(inkRows.isEmpty ? nil : inkRows[inkRows.count / 2])
        let coverage = (0..<width).reduce(0.0) { $0 + Double(pixels[(row * width + $1) * 4]) / 255 }
        return CGFloat(coverage) / scale
    }
}
