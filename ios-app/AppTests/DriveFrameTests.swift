import Darwin
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// #100: the drive screen's frame on the canvas: the left card (navigation or the trip), the tire column and the
/// footer, their clearance from the ring, what VoiceOver reads, and which changes fade.
@MainActor
struct DriveFrameTests {
    static let screen = HUDRenderTests.Screen.iPhone844
    static let canvas = DesignCanvas(screen: screen.size)

    static func view(_ state: HUDState, screen: HUDRenderTests.Screen = screen) -> DriveScreen {
        DriveScreen(state: state, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left, rightInset: screen.right,
                    bottomInset: screen.bottom)
    }

    /// The Euclidean distance from `rect` to the ring's line, in design points.
    static func ringDistance(_ rect: CGRect) -> CGFloat {
        let c = RoundGauge.center
        let near = CGPoint(x: min(max(c.x, rect.minX), rect.maxX), y: min(max(c.y, rect.minY), rect.maxY))
        return hypot(near.x - c.x, near.y - c.y) - RoundGauge.radius
    }

    /// Four wheels at `psi`.
    static func wheels(_ psi: Int) -> TireWheels {
        let wheel = TireWheel(psi: psi, ageMinutes: 0, freshness: .fresh)
        return TireWheels(frontLeft: wheel, frontRight: wheel, rearLeft: wheel, rearRight: wheel)
    }

    // MARK: Clearance

    // The guide's gate (DESIGN-atelier-tesla-edition.md "Layout"): the left card's frame and each of the tire
    // column's elements (the title mark and 胎壓, the car, each reading's ink box) stay 20 clear of the ring's line
    // at 844, for every two-digit reading. The nearest is the front-left reading (right-aligned at 640: 20.5 for the
    // widest, `44 psi`); the title mark is about 31.7. One box around all the readings would be 19.7: the gate is
    // per element.
    @Test func theFrameClearsTheRing() {
        #expect(Self.ringDistance(DriveFrame.leftCard) >= DriveFrame.ringClearance)
        let title = PlacedText("胎壓", .left(TireColumnView.titleX + 22), cy: TireColumnView.titleY, weight: .regular, size: 15,
                               color: .white, language: "zh-Hant")
        let mark = CGRect(x: TireColumnView.titleX + 7.5 - 6 * 1.25, y: TireColumnView.titleY - 5.6 * 1.25, width: 12 * 1.25, height: 13.6 * 1.25)
        let car = CGRect(x: TireColumnView.carCenterX - 64 * TireColumnView.carScale, y: TireColumnView.carTop,
                         width: 128 * TireColumnView.carScale, height: TireColumnView.carHeight)
        for part in [mark, title.box, car] { #expect(Self.ringDistance(part) >= DriveFrame.ringClearance, "\(part)") }
        var nearest = (distance: CGFloat.infinity, psi: 0), union = CGRect.null
        for psi in 10...99 {
            let readings = TireColumnView.readings(Self.wheels(psi), language: "zh-Hant")
            for reading in readings {
                let d = Self.ringDistance(reading.box)
                if d < nearest.distance { nearest = (d, psi) }
            }
            union = readings.reduce(union) { $0.union($1.box) }
        }
        #expect(nearest.distance >= DriveFrame.ringClearance, "\(nearest)")
        print("#100 clearance (frame, design points at 844): left card \(Self.ringDistance(DriveFrame.leftCard)), "
              + "tire mark \(Self.ringDistance(mark)), nearest reading \(nearest) (front left), "
              + "the readings' union box \(Self.ringDistance(union.union(mark)))")
    }

    /// Pixel indices of `view` drawn on black at 1×, 844 × 390: luminance (ITU-R 601) above 60.
    static func ink(_ view: some View) throws -> [(Int, Int)] {
        let renderer = ImageRenderer(content: ZStack(alignment: .topLeading) { Color.black; view }
            .frame(width: screen.size.width, height: screen.size.height, alignment: .topLeading))
        renderer.scale = 1
        let pixels = try HUDRenderTests.rgba(try #require(renderer.cgImage))
        let width = Int(screen.size.width)
        var found: [(Int, Int)] = []
        for i in stride(from: 0, to: pixels.count, by: 4)
        where 0.299 * Double(pixels[i]) + 0.587 * Double(pixels[i + 1]) + 0.114 * Double(pixels[i + 2]) > 60 {
            found.append((i / 4 % width, i / 4 / width))
        }
        return found
    }

    // For information, not a gate: the same clearance on ink, the panels alone and the ring alone (with its glow),
    // 1× luminance masks above 60 of 255, the Euclidean distance between pixel centres.
    @Test func inkClearanceForTheRecord() throws {
        let frame = GaugeView.frame(Self.canvas)
        let transform = Self.canvas.transform.concatenating(CGAffineTransform(translationX: -frame.minX, y: -frame.minY))
        let ring = try Self.ink(RingView(canvas: Self.canvas, transform: transform).frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY))
        let route = DriveLeftCard.navigation(.route(NavigationRoute(destination: "台北車站", minutes: 18, distance: 12, arrivalPercent: 64)))
        let left = try Self.ink(ZStack(alignment: .topLeading) {
            LeftCardFace(canvas: Self.canvas)
            LeftCardContent(card: route, unit: .kilometersPerHour, canvas: Self.canvas)
        }.environment(\.locale, Locale(identifier: "zh-Hant")))
        let right = try Self.ink(TireColumnView(wheels: Self.wheels(44), canvas: Self.canvas).environment(\.locale, Locale(identifier: "zh-Hant")))
        #expect(!ring.isEmpty && !left.isEmpty && !right.isEmpty)
        func distance(_ a: [(Int, Int)], _ b: [(Int, Int)]) -> Double {
            a.reduce(Double.infinity) { best, p in
                b.reduce(best) { min($0, hypot(Double(p.0 - $1.0), Double(p.1 - $1.1))) }
            }
        }
        // Only the ring's pixels on each side can be nearest.
        let leftInk = distance(left, ring.filter { $0.0 < 422 }), rightInk = distance(right, ring.filter { $0.0 > 422 })
        print("#100 clearance (ink, 1× 844, luminance > 60): left card \(leftInk), tire column \(rightInk)")
        #expect(leftInk > 0 && rightInk > 0)
    }

    // MARK: Left card

    // The Q11 switch fades the left card's content in; the card's face stays. A swap with no switch (a route that
    // ended, GPS fallback) is at once.
    @Test func onlyTheQ11SwitchFades() throws {
        let trip = HUDRenderTests.tripStates["drive-trip"]!.state
        var navigation = HUDRenderTests.navStates["drive-nav"]!
        navigation.navigationSwitches = trip.navigationSwitches + 1
        var noSwitch = navigation
        noSwitch.navigationSwitches = trip.navigationSwitches
        let card = DriveLayout(screen: Self.screen.size, leftInset: Self.screen.left, rightInset: Self.screen.right,
                               bottomInset: Self.screen.bottom).leftCard
        for (to, fades) in [(navigation, true), (noSwitch, false)] {
            let box = StateBox(trip)
            let hosted = HostedScreen(box, screen: Self.screen)
            defer { hosted.close() }
            let before = try hosted.pixels()
            box.state = to
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            let during = try hosted.pixels()
            let after = HostedScreen(StateBox(to), screen: Self.screen)
            defer { after.close() }
            let end = try after.pixels()
            let whole = HostedScreen.changed(before, end, inside: card), sofar = HostedScreen.changed(before, during, inside: card)
            #expect(whole > 500, "\(whole)")
            if fades {
                #expect(sofar * 2 < whole, "switched at once: \(sofar) of \(whole)")
            } else {
                #expect(HostedScreen.changed(during, end, inside: card) == 0, "faded: \(sofar) of \(whole)")
            }
        }
    }

    // MARK: VoiceOver

    // Each wheel is its own element, front left, front right, rear left, rear right, with its value, 「尚無讀值」 or
    // 「胎壓不足」; English the same.
    @Test func eachWheelIsItsOwnElement() {
        let wheels = TireWheels(frontLeft: TireWheel(psi: 42, ageMinutes: 0, freshness: .fresh),
                                frontRight: TireWheel(psi: 41, ageMinutes: 18, freshness: .old),
                                rearLeft: TireWheel(psi: 31, ageMinutes: 0, freshness: .fresh, isLow: true), rearRight: .missing)
        let size = DesignCanvas.size
        let zh = DriveScreenAccessibilityTests.elementLabels(TireColumnView(wheels: wheels, canvas: Self.canvas), size: size)
        #expect(zh == ["左前,42 psi", "右前,41 psi,18 分鐘前", "左後,31 psi,胎壓不足", "右後,尚無讀值"], "\(zh)")
        let en = DriveScreenAccessibilityTests.elementLabels(TireColumnView(wheels: wheels, canvas: Self.canvas), size: size, locale: "en")
        #expect(en == ["Front left, 42 psi", "Front right, 41 psi, 18 min ago", "Rear left, 31 psi, low", "Rear right, no reading yet"], "\(en)")
    }

    // The screen reads in a sensible order: the source and the time, the left card, the speed, the gear, the lit
    // discs, the wheels, the footer, and the settings gear.
    @Test func theScreenReadsInOrder() {
        let labels = DriveScreenAccessibilityTests.elementLabels(Self.view(HUDRenderTests.mainState("02")), size: Self.screen.size)
        let speed = HUDAccessibility.speedLabel(for: HUDRenderTests.mainState("02"))
        let expected = ["車速來源:車輛藍牙", "車上導航", speed, "檔位 D", "車門開著", "胎壓不足", "左前,42 psi", "右前,41 psi",
                        "左後,31 psi,胎壓不足", "右後,42 psi", "電量與續航", "總里程 48,213 公里", "設定"]
        let found = labels.filter { expected.contains($0) }
        #expect(found == expected, "\(labels)")
    }

    // The odometer reads 「總里程 48,213 公里」, or that it has no reading yet; never "—".
    @Test func theOdometerReadsInWords() {
        func label(_ odometer: Odometer, locale: String = "zh-Hant", unit: SpeedUnit = .kilometersPerHour) -> [String] {
            DriveScreenAccessibilityTests.elementLabels(OdometerView(odometer: odometer, unit: unit, canvas: Self.canvas),
                                                        size: DesignCanvas.size, locale: locale)
        }
        #expect(label(.value(48_213)) == ["總里程 48,213 公里"])
        #expect(label(.value(29_958), locale: "en", unit: .milesPerHour) == ["Odometer 29,958 miles"])
        #expect(label(.waiting) == ["總里程尚無讀值"])
    }

    @Test func footerText() {
        let texts = OdometerView.texts(.value(48_213), unit: .kilometersPerHour)
        #expect(texts.map { CTLineGetGlyphCount($0.line) } == [3, 9])
        #expect(abs(texts[1].box.maxX - DriveFrame.footerRight) < 1e-9)
        #expect(abs(texts[0].box.maxX - (texts[1].box.minX - 8)) < 1e-9)
        // `ODO` sits on the number's baseline, within the overshoot of their `0`s (the page's `asc0` placement).
        #expect(abs(texts[0].pen.y - texts[1].pen.y) < 0.25)
        let battery = BatteryBlockView.texts(.value(percent: 72, range: 315), unit: .kilometersPerHour, age: nil, stale: false, language: "zh-Hant")
        #expect(abs(battery[0].box.minX - (DriveFrame.footerLeft + 35.5)) < 1e-9)
        #expect(abs(battery[1].box.minX - (battery[0].box.maxX + 1)) < 1e-9)
        #expect(abs(battery[2].box.minX - (battery[1].box.maxX + 14.5)) < 1e-9)
    }
}

/// A `HUDState` a hosted screen shows; setting it updates the screen as the view model does.
@MainActor
@Observable
final class StateBox {
    var state: HUDState
    init(_ state: HUDState) { self.state = state }
}

/// The drive screen of a `StateBox`, hosted in the app's window scene so it can be captured mid-animation.
@MainActor
final class HostedScreen {
    let window: UIWindow

    private struct Screen: View {
        let box: StateBox
        let screen: HUDRenderTests.Screen
        var body: some View { DriveFrameTests.view(box.state, screen: screen) }
    }

    init(_ box: StateBox, screen: HUDRenderTests.Screen) {
        let host = UIHostingController(rootView: Screen(box: box, screen: screen).environment(\.locale, Locale(identifier: "zh-Hant"))
            .ignoresSafeArea())
        host.safeAreaRegions = []
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
            window.frame = CGRect(origin: .zero, size: screen.size)
        } else {
            window = UIWindow(frame: CGRect(origin: .zero, size: screen.size))
        }
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    }

    func close() { window.isHidden = true }

    func pixels() throws -> [UInt8] {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        return try HUDRenderTests.rgba(try #require(image.cgImage))
    }

    /// Pixels inside `rect` where a channel differs by more than `HUDRenderTests.channelTolerance`.
    static func changed(_ a: [UInt8], _ b: [UInt8], inside rect: CGRect, width: Int = 844) -> Int {
        var count = 0
        for pixel in stride(from: 0, to: a.count, by: 4)
        where (0..<4).contains(where: { abs(Int(a[pixel + $0]) - Int(b[pixel + $0])) > HUDRenderTests.channelTolerance }) {
            if rect.contains(CGPoint(x: CGFloat(pixel / 4 % width) + 0.5, y: CGFloat(pixel / 4 / width) + 0.5)) { count += 1 }
        }
        return count
    }
}
