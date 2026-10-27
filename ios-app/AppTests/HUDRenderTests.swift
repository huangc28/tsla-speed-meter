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

    static func state(_ events: [LocationEvent], car: [CarEvent] = [], unit: SpeedUnit = .kilometersPerHour,
                      at seconds: TimeInterval = 0) -> HUDState {
        var engine = HUDEngine()
        for event in events { engine.handle(event, now: t0) }
        for event in car { engine.handle(event, now: t0) }
        return engine.state(at: t0 + seconds, unit: unit)
    }

    /// A car speed that reached the phone `age` seconds before `t0`.
    static func car(_ kmh: Double, age: TimeInterval = 0, gear: CarGear? = nil,
                    battery: (percent: Int, rangeKm: Double)? = nil) -> CarEvent {
        .reading(CarReading(receivedAt: t0 - age, carTimestamp: t0 - age, speedMetersPerSecond: kmh / 3.6, gear: gear,
                            batteryPercent: battery?.percent, rangeKilometers: battery?.rangeKm))
    }

    /// Two drive readings in `gear`, 0.2 s apart, the last at `t0`: enough to show the gear row (L43).
    /// The battery, if any, comes with the last one; without it the block waits.
    static func driving(_ kmh: Double, gear: CarGear, battery: (percent: Int, rangeKm: Double)? = nil) -> [CarEvent] {
        [car(kmh, age: 0.2, gear: gear), car(kmh, gear: gear, battery: battery)]
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

    static let cases: [(name: String, state: HUDState, screen: Screen, locale: String, chrome: Chrome)] =
        driveStateNames.flatMap { name in
            variants.map { variant, locale in
                ("drive-\(name)-\(variant)", driveStates[name]!.state, variant.hasPrefix("844") ? .iPhone844 : .iPhone667,
                 locale, driveStates[name]!.chrome)
            }
        } + [
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

    static func render(_ name: String, scale: CGFloat) throws -> UIImage {
        let item = try #require(cases.first { $0.name == name })
        let view = DriveScreen(state: item.state, now: now, screen: item.screen.size, leftInset: item.screen.left,
                               rightInset: item.screen.right, bottomInset: item.screen.bottom,
                               setupPending: item.chrome != .paired, showsInvite: item.chrome == .invite)
            .environment(\.locale, Locale(identifier: item.locale))
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

    /// A driving screen at 1x, as RGBA bytes.
    static func render(_ state: HUDState, screen: Screen) throws -> [UInt8] {
        let view = DriveScreen(state: state, now: now, screen: screen.size, leftInset: screen.left,
                               rightInset: screen.right, bottomInset: screen.bottom)
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

    @Test func batteryText() {
        #expect(BatteryBlockView.parts(.value(percent: 72, range: 315), unit: .kilometersPerHour) == ("72%", "315 km"))
        #expect(BatteryBlockView.parts(.value(percent: 100, range: 1015), unit: .kilometersPerHour) == ("100%", "1,015 km"))
        #expect(BatteryBlockView.parts(.value(percent: 72, range: 196), unit: .milesPerHour) == ("72%", "196 mi"))
        #expect(BatteryBlockView.parts(.value(percent: 72, range: nil), unit: .kilometersPerHour) == ("72%", "— km"))
        #expect(BatteryBlockView.parts(.waiting, unit: .kilometersPerHour) == ("—%", "— km"))
        #expect(BatteryBlockView.parts(.stale, unit: .milesPerHour) == ("—%", "— mi"))
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
