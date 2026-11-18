import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// #101: the parked cards in the drive frame's bands: their clearance from the ring, the top row beside the ring and
/// the gear, the title buttons' hit areas at every size, what VoiceOver reads in which order, and the gauge.
@MainActor
struct ParkedCardsTests {
    typealias Screen = HUDRenderTests.Screen

    static func layout(_ screen: Screen) -> DriveLayout {
        DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
    }

    static func view(_ state: HUDState, screen: Screen = .iPhone844) -> DriveScreen {
        DriveScreen(state: state, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left, rightInset: screen.right,
                    bottomInset: screen.bottom)
    }

    /// The design point `p`'s distance from the ring's centre line (positive outside it).
    static func ringDistance(_ p: CGPoint) -> CGFloat {
        hypot(p.x - RoundGauge.center.x, p.y - RoundGauge.center.y) - RoundGauge.radius
    }

    /// As `DriveFrameTests.ringDistance`: a box's nearest point to the ring's centre.
    static func ringDistance(_ rect: CGRect) -> CGFloat {
        let c = RoundGauge.center
        return ringDistance(CGPoint(x: min(max(c.x, rect.minX), rect.maxX), y: min(max(c.y, rect.minY), rect.maxY)))
    }

    // MARK: Widest content

    /// 999,999 km on the odometer, −10° outside, the front-right window open: the longest 車況 rows.
    static func widestVehicle(english: Bool) -> HUDState {
        var state = HUDRenderTests.cardState("parked-vehicle-nav", english: english)
        state.vehicle = VehicleCard(odometer: 999_999, outsideCelsius: -10, insideCelsius: 38, windows: .open([.frontRight]))
        return state
    }

    /// Every trip row at its widest: four digits of distance, three of speed, double-digit hours and −100%.
    static func widestTrip(_ state: HUDState) -> HUDState {
        var state = state
        state.trip = TripSummary(distance: 1_234.5, driveMinutes: 12 * 60 + 34, averageSpeed: 188, maxSpeed: 248, batteryChange: -100)
        return state
    }

    static let longEnglishDestination = "National Taiwan University Hospital Emergency Department"

    /// The design points the cards draw on: `state` against itself with no cards (and no drive tire column), at 4×.
    static func cardInk(_ state: HUDState, locale: String) throws -> [CGPoint] {
        let screen = Screen.iPhone844, scale: CGFloat = 4
        var bare = state
        bare.panels = nil
        bare.tires = nil
        func render(_ shown: HUDState) throws -> [UInt8] {
            let view = Self.view(shown).environment(\.locale, Locale(identifier: locale)).transaction { $0.animation = nil }
            let image = try PairingRenderTests.renderInWindow(view, size: screen.size, scale: scale)
            return try HUDRenderTests.rgba(try #require(image.cgImage))
        }
        let a = try render(state), b = try render(bare)
        let width = Int(screen.size.width * scale)
        var points: [CGPoint] = []
        for pixel in stride(from: 0, to: a.count, by: 4)
        where (0..<3).contains(where: { abs(Int(a[pixel + $0]) - Int(b[pixel + $0])) > 2 }) {
            let x = CGFloat(pixel / 4 % width), y = CGFloat(pixel / 4 / width)
            // The pixel's square, nearest the ring's centre.
            let c = RoundGauge.center
            points.append(CGPoint(x: min(max(c.x, x / scale), (x + 1) / scale), y: min(max(c.y, y / scale), (y + 1) / scale)))
        }
        return points
    }

    // MARK: Clearance

    // The guide's gate, per element at 844 (DESIGN-atelier-tesla-edition.md "Layout", as `DriveFrameTests.theFrameClearsTheRing`):
    // everything each card's title and body draws stays 20 clear of the ring's line, for the widest content of each card, in
    // both languages. 行程 and 車況 are SwiftUI rows: every pixel they draw stays left of x 245, the left card's edge, so each
    // element's box is at least 21 from the ring. The right cards' text is placed by `PlacedText`, measured by its ink boxes.
    @Test(arguments: ["zh-Hant", "en"])
    func theCardsClearTheRing(locale: String) throws {
        let english = locale == "en"
        var worst: [String: CGFloat] = [:]
        // Left: the trip with every row, and the longest 車況 rows. Right: 車上導航 with a long destination, and 胎壓.
        let trip = Self.widestTrip(HUDRenderTests.cardState("parked-nav", english: english))
        let vehicle = Self.widestTrip(Self.widestVehicle(english: english))
        var navigation = HUDRenderTests.cardState("parked-nav", english: english)
        navigation = HUDRenderTests.withNavigation(navigation, destination: english ? Self.longEnglishDestination : HUDRenderTests.longDestination)
        let tires = Self.widestTrip(HUDRenderTests.parkedStates["tire-mixed"]!)
        for (name, state, side) in [("行程", trip, PanelSide.left), ("車況", vehicle, .left), ("車上導航", navigation, .right),
                                    ("胎壓", tires, .right)] {
            let ink = try Self.cardInk(state, locale: locale).filter { side == .left ? $0.x < RoundGauge.center.x : $0.x > RoundGauge.center.x }
            #expect(ink.count > 200, "\(name) drew nothing")
            let nearest = ink.map(Self.ringDistance).min() ?? .infinity
            worst[name] = nearest
            #expect(nearest >= DriveFrame.ringClearance, "\(name) \(locale): ink \(nearest) from the ring")
            if side == .left {
                let right = ink.map(\.x).max() ?? 0
                #expect(right <= DriveFrame.parkedLeft.maxX + 0.25, "\(name) \(locale) draws to x \(right)")
            }
        }
        // The right cards' text boxes.
        let language = Locale(identifier: locale).identifier
        for destination in [HUDRenderTests.longDestination, Self.longEnglishDestination, ""] {
            for (minutes, distance, arrival) in [(Int?.some(888), Double?.some(888), Int?.some(100)), (nil, nil, nil)] {
                let route = NavigationRoute(destination: destination, minutes: minutes, distance: distance, arrivalPercent: arrival)
                let texts = LeftCardContent.routeTexts(NavigationCopy(route: route, unit: .kilometersPerHour, locale: Locale(identifier: locale)),
                                                       language: language, layout: .parked)
                for text in texts {
                    let d = Self.ringDistance(text.box)
                    worst["車上導航 box"] = min(worst["車上導航 box"] ?? .infinity, d)
                    #expect(d >= DriveFrame.ringClearance, "\(text.box)")
                    #expect(text.box.maxX <= DriveFrame.parkedRight.maxX + 1e-9, "\(text.box)")
                }
            }
        }
        let pin = LeftCardContent.pin(.parked).boundingRect.insetBy(dx: -0.9, dy: -0.9)
        #expect(Self.ringDistance(pin) >= DriveFrame.ringClearance)
        worst["車上導航 pin"] = Self.ringDistance(pin)
        let line = TireColumnView.timeLines(english ? "Some readings: time unknown" : "部分讀值時間未知", language: language)
        worst["胎壓 time line"] = line.map { Self.ringDistance($0.box) }.min()
        #expect((worst["胎壓 time line"] ?? 0) >= DriveFrame.ringClearance)
        print("#101 clearance (design points at 844, \(locale)): " + worst.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }
            .joined(separator: ", "))
    }

    // MARK: Top row

    /// The ring's ink on the screen, 1× luminance above 60, as `DriveFrameTests.inkClearanceForTheRecord` takes it.
    static func ringInk(_ screen: Screen) throws -> [CGRect] {
        let canvas = DesignCanvas(screen: screen.size), frame = GaugeView.frame(canvas)
        let transform = canvas.transform.concatenating(CGAffineTransform(translationX: -frame.minX, y: -frame.minY))
        let renderer = ImageRenderer(content: ZStack(alignment: .topLeading) {
            Color.black
            RingView(canvas: canvas, transform: transform).frame(width: frame.width, height: frame.height).offset(x: frame.minX, y: frame.minY)
        }.frame(width: screen.size.width, height: screen.size.height, alignment: .topLeading))
        renderer.scale = 1
        let pixels = try HUDRenderTests.rgba(try #require(renderer.cgImage))
        let width = Int(screen.size.width)
        var ink: [CGRect] = []
        for i in stride(from: 0, to: pixels.count, by: 4)
        where 0.299 * Double(pixels[i]) + 0.587 * Double(pixels[i + 1]) + 0.114 * Double(pixels[i + 2]) > 60 {
            ink.append(CGRect(x: i / 4 % width, y: i / 4 / width, width: 1, height: 1))
        }
        return ink
    }

    // Parked, the date stays in front of the clock and the outside temperature at `temperatureSlot`: neither meets the ring's
    // ink or the gear's hit area, at 844, 667 and 956, in Chinese and English.
    @Test(arguments: [Screen.iPhone844, .iPhone667, .iPhone956], ["zh-Hant", "en"])
    func theTopRowClearsTheRingAndTheGear(screen: Screen, locale: String) throws {
        let state = HUDRenderTests.cardState("parked-temperature", english: locale == "en")
        let elements = DriveScreenAccessibilityTests.elements(Self.view(state, screen: screen), size: screen.size, locale: locale)
        let time = try #require(elements.first { $0.label.hasSuffix("14:05") }, "\(elements.map(\.label))")
        let temperature = try #require(elements.first { $0.label.hasPrefix("車外") || $0.label.hasPrefix("Outside") }, "\(elements.map(\.label))")
        #expect(time.label.hasPrefix("10/27") == (screen.size.width >= 844 && locale != "en"), "\(time.label)")
        let layout = Self.layout(screen), ring = try Self.ringInk(screen)
        for part in [time.frame, temperature.frame] {
            #expect(!part.intersects(layout.settingsGear), "\(part) meets the gear \(layout.settingsGear)")
            #expect(!ring.contains { $0.intersects(part) }, "\(part) meets the ring's ink")
        }
        #expect(layout.temperatureSlot.contains(temperature.frame.insetBy(dx: 0.5, dy: 0.5)), "\(temperature.frame) \(layout.temperatureSlot)")
    }

    // MARK: Title buttons

    // The title buttons' hit areas stay 44 high and at least 120 wide on the screen at every size (the title itself
    // scales), centred on the scaled title row, except where the gear is just above (the right at 667: it starts at the
    // gear's hit area rounded up to a whole point, about 1 lower than centred), and never meet the gear's hit area or the
    // top row. (Accessibility frames are Float, so 44 reads 43.99999.)
    @Test(arguments: [Screen.iPhone844, .iPhone667, .iPhone956])
    func theTitlesHitAreasDoNotScale(screen: Screen) throws {
        let state = HUDRenderTests.tripStates["parked-trip"]!.state
        let elements = DriveScreenAccessibilityTests.elements(Self.view(state, screen: screen), size: screen.size)
        let layout = Self.layout(screen), row = layout.canvas.point(0, DriveFrame.parkedTitleY).y
        for label in ["行程，第 1 張，共 2 張", "胎壓，第 1 張，共 2 張"] {
            let frame = try #require(elements.first { $0.label == label }?.frame, "\(elements.map(\.label))")
            #expect(frame.height >= 44 - 1e-3 && frame.width >= 120 - 1e-3, "\(label) \(frame)")
            if screen.size.width == 667 && label.hasPrefix("胎壓") {
                #expect(abs(frame.minY - layout.settingsGear.maxY.rounded(.up)) < 1e-3, "\(frame) \(layout.settingsGear)")
                #expect(frame.midY - row > 0 && frame.midY - row <= 1 + 1e-3, "\(label) \(frame) row \(row)")
            } else {
                #expect(abs(frame.midY - row) < 0.5, "\(label) \(frame) row \(row)")
            }
            #expect(frame.minY >= layout.settingsGear.maxY || !frame.intersects(layout.settingsGear), "\(frame) \(layout.settingsGear)")
            #expect(frame.minY >= layout.sourceChipOrigin.y + layout.topRowHeight, "\(frame)")
        }
    }

    // MARK: VoiceOver

    // Parked, each card reads its title button, then its body: the top row, 行程 and its rows, the speed, the gear, the
    // lit disc, 胎壓 and its wheels and time line, the footer, the settings gear.
    @Test func theParkedScreenReadsInOrder() throws {
        var state = HUDRenderTests.tripStates["parked-trip"]!.state
        state.carStatus?.door = .open
        let labels = DriveScreenAccessibilityTests.elementLabels(Self.view(state), size: Screen.iPhone844.size)
        let expected = ["車速來源:車輛藍牙", "10/27(二) 14:05", "行程，第 1 張，共 2 張", "行程", HUDAccessibility.speedLabel(for: state), "檔位 P",
                        "車門開著", "胎壓，第 1 張，共 2 張", "左前,42 psi", "右前,42 psi", "左後,41 psi", "右後,42 psi", "3 分鐘前",
                        "電量與續航", "設定"]
        #expect(labels.filter { expected.contains($0) } == expected, "\(labels)")
        #expect(!labels.contains(""), "\(labels)")

        let vehicleNav = HUDRenderTests.cardState("parked-vehicle-nav", english: false)
        let other = DriveScreenAccessibilityTests.elementLabels(Self.view(vehicleNav), size: Screen.iPhone844.size)
        let order = ["車況，第 2 張，共 2 張", "車況", "檔位 P", "車上導航，第 2 張，共 2 張", "車上導航"]
        #expect(other.filter { order.contains($0) } == order, "\(other)")
    }

    // While the one-time card shows, the left panel scrolls (a scroll view is its own accessibility container): its note,
    // 知道了, the 行程 title and the trip still read after the top row and before the gauge, at 667, 844 and 956, in both
    // languages, not after the settings gear.
    @Test(arguments: [Screen.iPhone844, .iPhone667, .iPhone956], ["zh-Hant", "en"])
    func theOneTimeCardReadsBeforeTheGauge(screen: Screen, locale: String) throws {
        let english = locale == "en"
        let state = HUDRenderTests.cardState("parked-hint", english: english)
        #expect(HUDRenderTests.needsWindow(state, screen: screen, locale: Locale(identifier: locale)))
        let labels = DriveScreenAccessibilityTests.elementLabels(Self.view(state, screen: screen), size: screen.size, locale: locale)
        func index(_ match: (String) -> Bool) throws -> Int {
            let found = labels.firstIndex(where: match)
            return try #require(found, "\(labels)")
        }
        let chip = try index { $0.hasPrefix(english ? "Speed source" : "車速來源") }
        let note = try index { $0.hasPrefix(english ? "Tire pressure is for reference" : "胎壓僅供參考") }
        let gotIt = try index { $0 == (english ? "Got it" : "知道了") }
        let title = try index { $0 == (english ? "Trip, card 1 of 2" : "行程，第 1 張，共 2 張") }
        let trip = try index { $0 == (english ? "Trip" : "行程") }
        let gear = try index { $0 == (english ? "Gear P" : "檔位 P") }
        let settings = try index { $0 == (english ? "Settings" : "設定") }
        #expect(chip < note && note < gotIt && gotIt < title && title < trip && trip < gear && gear < settings, "\(labels)")
    }

    // MARK: Swipe

    // The panel's swipe (`CardSwipe.Surface.panel`) sits on a container that holds the title button and the body, on both
    // sides, so a swipe works anywhere on the panel, the title row included (a drag can't be synthesized in-process, so this
    // pins the structure by place): the container is the panel's frame, and the title's row and every body element lie in it.
    @Test(arguments: [Screen.iPhone844, .iPhone667, .iPhone956])
    func thePanelSwipeHoldsTheTitleAndTheBody(screen: Screen) throws {
        let layout = Self.layout(screen)
        for (name, title, body) in [("parked-trip", "行程，第 1 張，共 2 張", ["行程"]),
                                    ("parked-nav", "車上導航，第 2 張，共 2 張", ["車上導航"])] {
            let state = name == "parked-trip" ? HUDRenderTests.tripStates["parked-trip"]!.state : HUDRenderTests.cardState(name, english: false)
            let elements = DriveScreenAccessibilityTests.elements(Self.view(state, screen: screen), size: screen.size)
            let row = layout.canvas.point(0, DriveFrame.parkedTitleY).y
            for (label, panel) in [(title, name == "parked-trip" ? layout.leftPanel : layout.tirePanel),
                                   ("胎壓，第 1 張，共 2 張", layout.tirePanel)] where elements.contains(where: { $0.label == label }) {
                let frame = try #require(elements.first { $0.label == label }?.frame)
                #expect(panel.insetBy(dx: -0.5, dy: -0.5).contains(CGPoint(x: frame.minX + 1, y: row)), "\(label) \(frame) \(panel)")
            }
            for label in body {
                let frame = try #require(elements.first { $0.label == label }?.frame, "\(elements.map(\.label))")
                #expect(frame.intersects(name == "parked-trip" ? layout.leftPanel : layout.tirePanel), "\(label) \(frame)")
            }
        }
    }

    // MARK: Gauge

    // Parked, `P` is lit and the discs follow the drive screen's event rule: a door open lights its disc, drawn exactly as
    // on the drive screen (the parked layout changes nothing inside the gauge).
    @Test(arguments: [Screen.iPhone844, .iPhone667, .iPhone956])
    func aLitDiscParkedIsTheDriveDisc(screen: Screen) throws {
        let parked = HUDRenderTests.state([.authorization(.authorized)],
                                          car: HUDRenderTests.parked(tires: HUDRenderTests.tires(minutesAgo: 3),
                                                                     closures: HUDRenderTests.closures(doors: true)))
        #expect(parked.layout == .parked && parked.gearRow == .park && parked.carStatus?.door == .open)
        var drive = parked
        drive.layout = .drive
        drive.tires = nil
        let a = try HUDRenderTests.render(parked, screen: screen), b = try HUDRenderTests.render(drive, screen: screen)
        let (inGauge, _) = HUDRenderTests.changedPixels(a, b, width: Int(screen.size.width), inside: Self.layout(screen).gaugeArea, tolerance: 1)
        #expect(inGauge == 0, "\(inGauge) pixels changed inside the gauge area")
    }
}
