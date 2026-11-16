import CoreText
import Foundation
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// The round gauge (#98) measured on the real glyphs: HUDCore's font metrics against the bundled font,
/// the numeral where `NumeralLayout` puts it, its ink height and stems at three sizes, the fixed unit and
/// ring, the GPS cue, and the chip's labels and the icon shapes.
@MainActor
struct RoundGaugeTests {
    nonisolated static let screens = [HUDRenderTests.Screen.iPhone844, .iPhone667, .iPhone956]

    static func layout(_ screen: HUDRenderTests.Screen) -> DriveLayout {
        DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
    }

    /// Each digit's glyph outline at its layout origin, in design points (y down), as CoreText shapes it.
    static func digitOutlines(_ digits: String) throws -> [CGPath] {
        let layout = try #require(NumeralLayout(digits: digits))
        return try zip(digits, layout.digitOrigins).map { digit, x in
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: String(digit), attributes: [.font: GaugeLabels.numeralFont]))
            let run = try #require((CTLineGetGlyphRuns(line) as? [CTRun])?.first)
            var glyph = CGGlyph()
            CTRunGetGlyphs(run, CFRange(location: 0, length: 1), &glyph)
            let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont
            var place = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: x, ty: layout.baselineY)
            return try #require(CTFontCreatePathForGlyph(runFont, glyph, &place))
        }
    }

    // HUDCore lays the numeral, unit and gear row out from Hanken Grotesk 500's metrics: they must be the font's.
    @Test func hankenMetricsMatchTheFont() throws {
        let font = try #require(UIFont(name: HUDFont.hankenMedium, size: 1000))
        func line(_ s: String) -> CTLine { CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: [.font: font])) }
        for digit in "0123456789" {
            #expect(abs(CTLineGetTypographicBounds(line(String(digit)), nil, nil, nil) - HankenMetrics.digitAdvance * 1000) < 0.5, "\(digit)")
        }
        let eight = CTLineGetBoundsWithOptions(line("8"), .useGlyphPathBounds)
        #expect(abs(eight.minY - HankenMetrics.eightInk.min * 1000) < 0.5 && abs(eight.maxY - HankenMetrics.eightInk.max * 1000) < 0.5, "\(eight)")
        for letter in ["P", "k", "h"] {
            #expect(abs(CTLineGetBoundsWithOptions(line(letter), .useGlyphPathBounds).maxY - HankenMetrics.capHeight * 1000) < 0.5, "\(letter)")
        }
        // The current gear's 600 has the same cap height.
        let semiBold = try #require(UIFont(name: HUDFont.hankenSemiBold, size: 1000))
        let p600 = CTLineGetBoundsWithOptions(CTLineCreateWithAttributedString(NSAttributedString(string: "P", attributes: [.font: semiBold])),
                                              .useGlyphPathBounds)
        #expect(abs(p600.maxY - HankenMetrics.capHeight * 1000) < 0.5)
    }

    // The guide's ink height 73.7 at 844 (the ink of "8", which places the numeral; brief floor 72.8)
    // replaces DESIGN.md's ≥ 105 (L39) for this design. Recorded at 844, 667 and 956 × 440 with the
    // ink of "147" and the stems: the 1's stem and the thinnest stroke across the digits' middle rows.
    @Test(arguments: screens)
    func inkHeightAndStems(screen: HUDRenderTests.Screen) throws {
        let s = Self.layout(screen).canvas.scale
        let eight = try Self.digitOutlines("8").map(\.boundingBoxOfPath).reduce(CGRect.null) { $0.union($1) }
        let ink147 = try Self.digitOutlines("147").map(\.boundingBoxOfPath).reduce(CGRect.null) { $0.union($1) }
        #expect(abs(eight.height - 73.7) <= 0.1, "8: \(eight.height)")
        #expect(eight.height >= 72.8)
        // On screen, the design scaled.
        let font = GaugeLabels.numeralFont.withSize(RoundGauge.Numeral.fontSize * s)
        let stem1 = try HUDRenderTests.stemWidth(of: "1", font: font)
        let thinnest = try "0123456789".map { try Self.thinnestStroke(of: String($0), font: font) }.min() ?? 0
        print(String(format: "round gauge %.0f × %.0f (scale %.4f): ink height of 8 %.2f, of 147 %.2f; stem of 1 %.2f, thinnest stroke %.2f (points)",
                     screen.size.width, screen.size.height, s, eight.height * s, ink147.height * s, stem1, thinnest))
        // The guide's ink of "147" at 844 is 71.9 (1, 4 and 7 have no overshoot).
        #expect(abs(ink147.height - 71.93) <= 0.05, "147: \(ink147.height)")
        #expect(stem1 > 0 && thinnest > 0)
    }

    /// The narrowest inked run across `glyph`'s middle ink row, from antialiased coverage, in points.
    static func thinnestStroke(of glyph: String, font: UIFont) throws -> CGFloat {
        let scale: CGFloat = 4
        let view = Text(verbatim: glyph).font(Font(font)).foregroundStyle(.white).padding(10).background(.black)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        let image = try #require(renderer.cgImage)
        let pixels = try HUDRenderTests.rgba(image), width = image.width, height = image.height
        let inkRows = (0..<height).filter { y in (0..<width).contains { pixels[(y * width + $0) * 4] > 128 } }
        let row = try #require(inkRows.isEmpty ? nil : inkRows[inkRows.count / 2])
        var runs: [Double] = [], run = 0.0
        for x in 0..<width {
            let c = Double(pixels[(row * width + x) * 4]) / 255
            if c > 0 { run += c } else if run > 0 { runs.append(run); run = 0 }
        }
        if run > 0 { runs.append(run) }
        return CGFloat(runs.min() ?? 0) / scale
    }

    // The digits are drawn at the layout's origins: each digit's ink starts at origin + xMin, at 844.
    @Test(arguments: ["112", "88", "207", "4"])
    func digitsAreDrawnAtTheLayoutOrigins(_ digits: String) throws {
        let canvas = DesignCanvas(screen: HUDRenderTests.Screen.iPhone844.size), scale: CGFloat = 4
        let state = HUDRenderTests.state([.authorization(.authorized)], car: [HUDRenderTests.car(Double(digits)!)])
        #expect(state.numeral == digits)
        let frame = GaugeView.frame(canvas)
        let renderer = ImageRenderer(content: GaugeView(state: state, canvas: canvas, layers: [.numeral]).background(.black))
        renderer.scale = scale
        let image = try #require(renderer.cgImage)
        let pixels = try HUDRenderTests.rgba(image)
        let width = image.width
        // Rows through the digits' band, in the view's points.
        let rows = Int((RoundGauge.Numeral.inkTop - frame.minY + 2) * scale)...Int((RoundGauge.Numeral.inkBottom - frame.minY - 2) * scale)
        let inked = (0..<width).map { x in rows.contains { pixels[($0 * width + x) * 4] > 128 } }
        let starts = inked.indices.filter { inked[$0] && ($0 == 0 || !inked[$0 - 1]) }.map { CGFloat($0) / scale + frame.minX }
        let ends = inked.indices.filter { inked[$0] && ($0 == inked.count - 1 || !inked[$0 + 1]) }.map { CGFloat($0 + 1) / scale + frame.minX }
        let expected = try Self.digitOutlines(digits).map(\.boundingBoxOfPath)
        #expect(starts.count == expected.count && ends.count == expected.count, "\(starts) \(ends)")
        for (i, ink) in zip(expected.indices, expected) where i < starts.count && i < ends.count {
            #expect(abs(starts[i] - ink.minX) <= 0.5, "digit \(i) ink starts at \(starts[i]), expected \(ink.minX)")
            #expect(abs(ends[i] - ink.maxX) <= 0.5, "digit \(i) ink ends at \(ends[i]), expected \(ink.maxX)")
        }
    }

    // The unit hangs off the numeral's fixed ink: it does not move between digit counts, and its ink
    // top is 9.5 below the numeral's.
    @Test func unitDoesNotMoveWithTheDigitCount() throws {
        func unitInk(_ kmh: Double, unit: SpeedUnit = .kilometersPerHour) throws -> CGRect {
            let state = HUDRenderTests.state([.authorization(.authorized)], car: [HUDRenderTests.car(kmh)], unit: unit)
            return try #require(GaugeLabels(state: state, locale: Locale(identifier: "en")).unitInk)
        }
        #expect(try unitInk(99) == unitInk(100))
        #expect(try unitInk(9) == unitInk(10))
        #expect(try abs(unitInk(9).minY - RoundGauge.Unit.inkTop) < 1e-6 && abs(unitInk(9).midX - 422) < 1e-6)
        #expect(try abs(unitInk(40, unit: .milesPerHour).minY - RoundGauge.Unit.inkTop) < 1e-6)
    }

    // The Fixed Ring Rule: the ring and its ticks draw the same pixels in every state
    // (one, two or three digits, no speed, parked with 「P 檔」), at 844.
    @Test func ringNeverChanges() throws {
        let states: [HUDState] = [
            HUDRenderTests.state([.authorization(.authorized)], car: HUDRenderTests.driving(8, gear: .drive)),
            HUDRenderTests.state([.authorization(.authorized)], car: HUDRenderTests.driving(86, gear: .drive)),
            HUDRenderTests.state([.authorization(.authorized)], car: HUDRenderTests.driving(248, gear: .drive)),
            HUDRenderTests.driveStates["no-data"]!.state,
            HUDRenderTests.parkedStates["p-unknown"]!,
        ]
        let screen = HUDRenderTests.Screen.iPhone844, width = Int(screen.size.width)
        let renders = try states.map { try HUDRenderTests.render($0, screen: screen) }
        // The ticks, the ring and its glow, short of the panels 6 outside the ring (the parked tire panel
        // starts at x 585, inside the glow's reach at 3 o'clock).
        func inRing(_ pixel: Int) -> Bool {
            let r = hypot(CGFloat(pixel % width) + 0.5 - 422, CGFloat(pixel / width) + 0.5 - 172)
            return r >= 136 && r <= 161
        }
        for (i, render) in renders.enumerated().dropFirst() {
            var differing = 0, first: Int?
            for pixel in 0..<(render.count / 4) where inRing(pixel) {
                // 1 of 255 is the renderer's noise (one blue level of one pixel, parked).
                if (0..<4).contains(where: { abs(Int(render[pixel * 4 + $0]) - Int(renders[0][pixel * 4 + $0])) > 1 }) {
                    differing += 1
                    first = first ?? pixel
                }
            }
            #expect(differing == 0, "state \(i): \(differing) ring pixels changed, first at \(String(describing: first.map { ($0 % width, $0 / width) }))")
        }
    }

    // L87: the cue is drawn only on GPS: green as the normal source, amber as the fallback; its ink
    // sits 8 left of the unit's ink, centred on it.
    @Test func gpsCueOnlyOnGPS() throws {
        let en = Locale(identifier: "en")
        let gps = GaugeLabels(state: HUDRenderTests.state([.authorization(.authorized), HUDRenderTests.gps(88)]), locale: en)
        let cue = try #require(gps.gpsCue), unit = try #require(gps.unitInk)
        #expect(cue.color == Palette.sourceOK && cue.size == 14)
        #expect(abs(cue.origin.x + 23 * 14 / 24 + 8 - unit.minX) < 1e-9)
        #expect(abs(cue.origin.y + 11.5 * 14 / 24 - unit.midY) < 1e-9)
        let fallback = GaugeLabels(state: HUDRenderTests.state([.authorization(.authorized), HUDRenderTests.gps(118)],
                                                               car: [HUDRenderTests.car(121, age: 3)]), locale: en)
        #expect(fallback.gpsCue?.color == Palette.sourceDegraded)
        let car = GaugeLabels(state: HUDRenderTests.state([.authorization(.authorized)], car: [HUDRenderTests.car(112)]), locale: en)
        #expect(car.gpsCue == nil)
        let none = GaugeLabels(state: HUDRenderTests.state([.authorization(.authorized), HUDRenderTests.gps(72)], at: 3), locale: en)
        #expect(none.gpsCue == nil && none.unitInk == nil && none.reason == "Speed unavailable")
    }

    /// The design frames' states (`STATES`), with the existing fixtures and no car-status icons yet (#99):
    /// main-01 86 in D, main-04 8 in D, main-08 parked in P at 0, main-09 no speed with D lit (the engine
    /// hides the gear row without a car speed, so the fixture sets it, as the frame draws it).
    static let designStates: [(name: String, state: HUDState)] = {
        func noIcons(_ s: HUDState) -> HUDState { var s = s; s.carStatus = nil; return s }
        let drive = { (kmh: Double) in
            noIcons(HUDRenderTests.state([.authorization(.authorized)], car: HUDRenderTests.driving(kmh, gear: .drive, battery: (72, 315))))
        }
        var noSpeed = HUDRenderTests.driveStates["no-data"]!.state
        noSpeed.gearRow = .drive
        return [("main-01", drive(86)), ("main-04", drive(8)),
                ("main-08", noIcons(HUDRenderTests.state([.authorization(.authorized)], car: HUDRenderTests.parked(tires: HUDRenderTests.tires(minutesAgo: 3))))),
                ("main-09", noSpeed)]
    }()

    // For the reviewer's contact sheet: the design states at 844 (1x and 2x) in Chinese, and main-01 at
    // 667 × 375 and 956 × 440, to `Snapshots/round-gauge/`.
    @Test func rendersTheDesignStates() throws {
        let directory = HUDRenderTests.snapshotDirectory.appendingPathComponent("round-gauge")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        func write(_ state: HUDState, _ screen: HUDRenderTests.Screen, scale: CGFloat, _ name: String) throws {
            let view = DriveScreen(state: state, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left,
                                   rightInset: screen.right, bottomInset: screen.bottom)
                .environment(\.locale, Locale(identifier: "zh-Hant"))
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = ProposedViewSize(screen.size)
            renderer.scale = scale
            try #require(renderer.uiImage?.pngData()).write(to: directory.appendingPathComponent("\(name).png"))
        }
        for (name, state) in Self.designStates {
            try write(state, .iPhone844, scale: 1, "\(name)-844")
            try write(state, .iPhone844, scale: 2, "\(name)-844@2x")
        }
        let main01 = Self.designStates[0].state
        try write(main01, .iPhone667, scale: 2, "main-01-667@2x")
        try write(main01, .iPhone956, scale: 2, "main-01-956@2x")
        try write(Self.designStates[3].state, .iPhone667, scale: 2, "main-09-667@2x")
        try write(Self.designStates[3].state, .iPhone956, scale: 2, "main-09-956@2x")
    }

    // L81: the chip is icons only; each state keeps its own words as the accessibility label.
    @Test func eachChipStateHasItsOwnLabel() throws {
        let states: [SourceStatus] = [.valid(.carBluetooth), .gpsFallback, .valid(.gps), .waiting,
                                      .searchingGPS, .speedUnavailable, .gpsUnavailable]
        let keys = states.map(\.labelKey)
        #expect(Set(keys).count == states.count)
        let zh = try #require(Bundle.main.path(forResource: "zh-Hant", ofType: "lproj").flatMap(Bundle.init(path:)))
        let words = keys.map { zh.localizedString(forKey: $0, value: nil, table: nil) }
        #expect(words == ["車輛藍牙", "GPS · 藍牙資料過期", "GPS", "等待車速訊號", "搜尋 GPS 訊號…", "車速暫不可用", "GPS 不可用"])
    }

    // The icons parse inside Lucide's 24 box; the arcs bulge the right way (circle-dashed reaches the radius-10 circle).
    @Test func iconsFitTheirBox() {
        for icon in LucideIcon.allCases {
            let bounds = icon.path.boundingRect
            #expect(!bounds.isEmpty && CGRect(x: 0, y: 0, width: 24, height: 24).contains(bounds), "\(icon) \(bounds)")
        }
        let bluetooth = LucideIcon.bluetooth.path.boundingRect
        #expect(bluetooth == CGRect(x: 7, y: 2, width: 10, height: 20))
        let dashed = LucideIcon.circleDashed.path.boundingRect
        #expect(abs(dashed.minX - 2) < 0.01 && abs(dashed.maxX - 22) < 0.01 && abs(dashed.minY - 2) < 0.01 && abs(dashed.maxY - 22) < 0.01,
                "\(dashed)")
        let settings = LucideIcon.settings.path.boundingRect
        #expect(abs(settings.minY - 2) < 0.01 && abs(settings.maxY - 22) < 0.01, "\(settings)")
    }
}
