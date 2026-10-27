import CoreText
import Foundation
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// Gauge A (#75) measured on the real glyphs: the numeral where `NumeralLayout` puts it, its ink
/// height and its clearance from the ring, the fixed unit, the chip's labels and the icon shapes.
@MainActor
struct GaugeATests {
    /// Each digit's glyph outline at its layout origin, in gauge-area points (y down), as CoreText
    /// shapes it with the tabular font the gauge draws with.
    static func digitOutlines(_ digits: String, gaugeSize: CGFloat) throws -> [CGPath] {
        let layout = try #require(NumeralLayout(digits: digits, gaugeSize: gaugeSize))
        let font = HUDFont.barlow(HUDFont.regular, size: layout.fontSize)
        return try zip(digits, layout.digitOrigins).map { digit, x in
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: String(digit), attributes: [.font: font]))
            let run = try #require((CTLineGetGlyphRuns(line) as? [CTRun])?.first)
            var glyph = CGGlyph()
            CTRunGetGlyphs(run, CFRange(location: 0, length: 1), &glyph)
            let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont
            var place = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: x, ty: layout.baselineY)
            return try #require(CTFontCreatePathForGlyph(runFont, glyph, &place))
        }
    }

    /// Points along `path`, with curves sampled finely enough to follow the outline.
    static func outlinePoints(_ path: CGPath) -> [CGPoint] {
        var points: [CGPoint] = []
        var last = CGPoint.zero
        path.applyWithBlock { element in
            let e = element.pointee, p = e.points
            switch e.type {
            case .moveToPoint, .addLineToPoint:
                last = p[0]
                points.append(last)
            case .addQuadCurveToPoint:
                for i in 1...32 {
                    let t = CGFloat(i) / 32, u = 1 - t
                    points.append(CGPoint(x: u * u * last.x + 2 * u * t * p[0].x + t * t * p[1].x,
                                          y: u * u * last.y + 2 * u * t * p[0].y + t * t * p[1].y))
                }
                last = p[1]
            case .addCurveToPoint:
                for i in 1...32 {
                    let t = CGFloat(i) / 32, u = 1 - t
                    let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
                    points.append(CGPoint(x: a * last.x + b * p[0].x + c * p[1].x + d * p[2].x,
                                          y: a * last.y + b * p[0].y + c * p[1].y + d * p[2].y))
                }
                last = p[2]
            case .closeSubpath: break
            @unknown default: break
            }
        }
        return points
    }

    // The fixed lines (unit, reason, P R N D) hang off HUDCore's ink of "0"; it must be the font's.
    @Test func zeroInkMatchesTheFont() {
        let font = HUDFont.barlow(HUDFont.regular, size: 1000)
        let ink = HUDFont.inkBounds("0", font: font, tracking: 0)
        #expect(abs(ink.minY - NumeralLayout.zeroInk.min) < 0.5 && abs(ink.maxY - NumeralLayout.zeroInk.max) < 0.5,
                "\(ink)")
    }

    // The numeral uses the tabular glyphs (L38) that `NumeralLayout`'s ink table describes:
    // the narrow 1 advances as far as 0, with its ink at 74…335 per 1000 em.
    @Test func numeralFontUsesTabularDigits() {
        let font = HUDFont.barlow(HUDFont.regular, size: 1000)
        func line(_ s: String) -> CTLine { CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: [.font: font])) }
        let one = CTLineGetTypographicBounds(line("1"), nil, nil, nil), zero = CTLineGetTypographicBounds(line("0"), nil, nil, nil)
        #expect(abs(one - 481) < 0.5 && abs(zero - 481) < 0.5, "advances \(one), \(zero)")
        let ink = CTLineGetBoundsWithOptions(line("1"), .useGlyphPathBounds)
        #expect(abs(ink.minX - 74) <= 1 && abs(ink.maxX - 335) <= 1, "\(ink)")
    }

    // L39 / L88: "147" ink height 112 at 844 and 104.5 at 667.
    @Test(arguments: [(CGFloat(300), CGFloat(112)), (280, 104.5)])
    func inkHeightOf147(gaugeSize: CGFloat, expected: CGFloat) throws {
        let ink = try Self.digitOutlines("147", gaugeSize: gaugeSize).map(\.boundingBoxOfPath).reduce(CGRect.null) { $0.union($1) }
        #expect(abs(ink.height - expected) <= 1, "ink height \(ink.height)")
    }

    // R7-02 / L48: the numeral ink stays ≥ 9 from the ring at every speed, even with the 5 px
    // threshold ring (stroke inner edge at 139k − 2.5).
    @Test(arguments: [CGFloat(300), 280])
    func numeralInkClearsTheRing(gaugeSize: CGFloat) throws {
        let g = GaugeGeometry(size: gaugeSize)
        let ringInnerEdge = g.ringRadius - 2.5
        var tightest = (clearance: CGFloat.infinity, speed: -1)
        for speed in 0...240 {
            let points = try Self.digitOutlines(String(speed), gaugeSize: gaugeSize).flatMap(Self.outlinePoints)
            let farthest = points.map { hypot($0.x - g.center.x, $0.y - g.center.y) }.max() ?? 0
            if ringInnerEdge - farthest < tightest.clearance { tightest = (ringInnerEdge - farthest, speed) }
        }
        print("gauge \(gaugeSize): tightest numeral clearance \(tightest.clearance) at \(tightest.speed) km/h")
        #expect(tightest.clearance >= 9, "\(tightest.clearance) at \(tightest.speed)")
    }

    // The digits are drawn at the layout's origins: each digit's ink starts at origin + xMin.
    @Test(arguments: ["112", "88", "207"])
    func digitsAreDrawnAtTheLayoutOrigins(_ digits: String) throws {
        let size: CGFloat = 300, scale: CGFloat = 4
        let state = HUDRenderTests.state([.authorization(.authorized)], car: [HUDRenderTests.car(Double(digits)!)])
        #expect(state.numeral == digits)
        let renderer = ImageRenderer(content: GaugeView(state: state, size: size))
        renderer.scale = scale
        let image = try #require(renderer.cgImage)
        let pixels = try HUDRenderTests.rgba(image)
        let width = image.width
        let layout = try #require(NumeralLayout(digits: digits, gaugeSize: size))
        // Rows through the digits' whole 0–700 band (so the 1's flag joins its stem), columns inside the ring.
        let rows = Int((layout.baselineY - 690 * 0.16) * scale)...Int((layout.baselineY - 10 * 0.16) * scale)
        let inked = (Int(30 * scale)..<Int(270 * scale)).map { x in rows.contains { pixels[($0 * width + x) * 4] > 128 } }
        // Starts of the inked column runs, in points.
        let starts = inked.indices.filter { inked[$0] && ($0 == 0 || !inked[$0 - 1]) }.map { CGFloat($0) / scale + 30 }
        let expected = try Self.digitOutlines(digits, gaugeSize: size).map(\.boundingBoxOfPath.minX)
        #expect(starts.count == expected.count, "\(starts)")
        for (start, ink) in zip(starts, expected) {
            #expect(abs(start - ink) <= 0.5, "ink starts at \(start), expected \(ink)")
        }
    }

    // The unit hangs off the ink of "0": it does not move between digit counts.
    @Test(arguments: [CGFloat(300), 280])
    func unitDoesNotMoveWithTheDigitCount(gaugeSize: CGFloat) throws {
        let g = GaugeGeometry(size: gaugeSize)
        func unitInk(_ kmh: Double) throws -> CGRect {
            let state = HUDRenderTests.state([.authorization(.authorized)], car: [HUDRenderTests.car(kmh)])
            #expect(state.numeral == String(Int(kmh)))
            return try #require(GaugeLabels(state: state, geometry: g).unitInk)
        }
        #expect(try unitInk(99) == unitInk(100))
        #expect(try unitInk(9) == unitInk(10))
        #expect(try abs(unitInk(9).midY - g.unitCenterY) < 1e-9 && abs(unitInk(9).midX - gaugeSize / 2) < 1e-9)
    }

    // L87: the cue is drawn only on GPS: green as the normal source, amber as the fallback; it
    // sits 8 left of the unit ink, centered on it.
    @Test func gpsCueOnlyOnGPS() throws {
        let g = GaugeGeometry(size: 300)
        let gps = GaugeLabels(state: HUDRenderTests.state([.authorization(.authorized), HUDRenderTests.gps(88)]), geometry: g)
        let cue = try #require(gps.gpsCue), unit = try #require(gps.unitInk)
        #expect(cue.color == Palette.sourceOK && cue.size == 14)
        #expect(abs(cue.origin.x + 23 * 14 / 24 + 8 - unit.minX) < 1e-9)
        #expect(abs(cue.origin.y + 11.5 * 14 / 24 - unit.midY) < 1e-9)
        let fallback = GaugeLabels(state: HUDRenderTests.state([.authorization(.authorized), HUDRenderTests.gps(118)],
                                                               car: [HUDRenderTests.car(121, age: 3)]), geometry: g)
        #expect(fallback.gpsCue?.color == Palette.sourceDegraded)
        let car = GaugeLabels(state: HUDRenderTests.state([.authorization(.authorized)], car: [HUDRenderTests.car(112)]), geometry: g)
        #expect(car.gpsCue == nil)
        let none = GaugeLabels(state: HUDRenderTests.state([.authorization(.authorized), HUDRenderTests.gps(72)], at: 3), geometry: g)
        #expect(none.gpsCue == nil && none.unitInk == nil)
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
