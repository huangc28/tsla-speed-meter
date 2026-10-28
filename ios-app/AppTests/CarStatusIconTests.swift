import CoreText
import Foundation
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// The car-status icons (#78): the master's shapes, their clearance inside the ring measured on the
/// real ink (DESIGN.md "Car-status icons": ≥ 9 from the numeral, ≥ 6 from the 5 px ring, the unit,
/// `P R N D`, 「P 檔」, the reason and each other), and one VoiceOver sentence per lit icon.
@MainActor
struct CarStatusIconTests {
    typealias Segment = (a: CGPoint, b: CGPoint)

    /// `path` as straight segments, curves split finely enough to follow it, subpaths closed.
    static func segments(_ path: CGPath) -> [Segment] {
        var segments: [Segment] = []
        var last = CGPoint.zero, start = CGPoint.zero
        func line(to p: CGPoint) {
            segments.append((last, p))
            last = p
        }
        path.applyWithBlock { element in
            let e = element.pointee, p = e.points
            switch e.type {
            case .moveToPoint:
                last = p[0]
                start = p[0]
            case .addLineToPoint:
                line(to: p[0])
            case .addQuadCurveToPoint:
                let p0 = last
                for i in 1...16 {
                    let t = CGFloat(i) / 16, u = 1 - t
                    line(to: CGPoint(x: u * u * p0.x + 2 * u * t * p[0].x + t * t * p[1].x,
                                     y: u * u * p0.y + 2 * u * t * p[0].y + t * t * p[1].y))
                }
            case .addCurveToPoint:
                let p0 = last
                for i in 1...16 {
                    let t = CGFloat(i) / 16, u = 1 - t
                    let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
                    line(to: CGPoint(x: a * p0.x + b * p[0].x + c * p[1].x + d * p[2].x,
                                     y: a * p0.y + b * p[0].y + c * p[1].y + d * p[2].y))
                }
            case .closeSubpath:
                line(to: start)
            @unknown default: break
            }
        }
        return segments
    }

    static func rectSegments(_ r: CGRect) -> [Segment] {
        let corners = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                       CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]
        return (0..<4).map { (corners[$0], corners[($0 + 1) % 4]) }
    }

    static func distance(_ p: CGPoint, _ s: Segment) -> CGFloat {
        let dx = s.b.x - s.a.x, dy = s.b.y - s.a.y, length = dx * dx + dy * dy
        let t = length == 0 ? 0 : max(0, min(1, ((p.x - s.a.x) * dx + (p.y - s.a.y) * dy) / length))
        return hypot(p.x - (s.a.x + t * dx), p.y - (s.a.y + t * dy))
    }

    static func cross(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    }

    static func distance(_ s: Segment, _ t: Segment) -> CGFloat {
        let d1 = cross(s.a, s.b, t.a), d2 = cross(s.a, s.b, t.b), d3 = cross(t.a, t.b, s.a), d4 = cross(t.a, t.b, s.b)
        if d1 * d2 < 0 && d3 * d4 < 0 { return 0 }
        return min(distance(s.a, t), distance(s.b, t), distance(t.a, s), distance(t.b, s))
    }

    static func bounds(_ segments: [Segment]) -> CGRect {
        segments.reduce(CGRect.null) { $0.union(CGRect(x: min($1.a.x, $1.b.x), y: min($1.a.y, $1.b.y),
                                                      width: abs($1.a.x - $1.b.x), height: abs($1.a.y - $1.b.y))) }
    }

    /// The gap between two inks given by their outlines (neither inside the other), or more than
    /// `beyond` when their bounds are already that far apart.
    static func gap(_ a: [Segment], _ b: [Segment], beyond: CGFloat = 40) -> CGFloat {
        let ba = bounds(a), bb = bounds(b)
        let dx = max(0, max(ba.minX, bb.minX) - min(ba.maxX, bb.maxX)), dy = max(0, max(ba.minY, bb.minY) - min(ba.maxY, bb.maxY))
        if hypot(dx, dy) > beyond { return hypot(dx, dy) }
        // Only the parts of each that come near the other.
        let near = { (s: [Segment], box: CGRect) in s.filter { bounds([$0]).insetBy(dx: -beyond, dy: -beyond).intersects(box) } }
        let na = near(a, bb), nb = near(b, ba)
        var best = CGFloat.infinity
        for s in na { for t in nb { best = min(best, distance(s, t)) } }
        return best
    }

    /// The icon's ink outline in gauge-area points: fills as drawn, strokes as their full outline
    /// (a dash's gaps are ignored, so the measure is never kinder than the drawing), or with
    /// `realDashes` each dash as drawn.
    static func iconInk(_ icon: CarStatusIcon, dashed: Bool, gaugeSize: CGFloat, realDashes: Bool = false) -> [Segment] {
        let center = icon.center(in: CarStatusSlots(gaugeSize: gaugeSize)), size = CarStatusIcon.size(gaugeSize: gaugeSize)
        let place = CGAffineTransform(translationX: center.x - size / 2, y: center.y - size / 2)
            .scaledBy(x: size / CarStatusIcon.box, y: size / CarStatusIcon.box)
        return icon.parts(dashed: dashed).flatMap { part -> [Segment] in
            let path: CGPath = switch part {
            case .fill(let path, _): path.cgPath
            case .stroke(let path, let style):
                (style.dash.isEmpty || !realDashes ? path.cgPath : path.cgPath.copy(dashingWithPhase: style.dashPhase, lengths: style.dash))
                    .copy(strokingWithWidth: style.lineWidth, lineCap: style.lineCap, lineJoin: style.lineJoin,
                          miterLimit: style.miterLimit)
            }
            var transform = place
            return segments(path.copy(using: &transform)!)
        }
    }

    /// Ink of each line of `string` in `font` (CoreText, with font fallback), for a centered text
    /// whose layout box is centered on `layoutCenter`, as SwiftUI's `.position` places the reason:
    /// each line `font.lineHeight` high, its baseline `font.ascender` below the line's top.
    static func textInk(_ string: String, font: UIFont, tracking: CGFloat, layoutCenter: CGPoint) -> [CGRect] {
        let lines = string.components(separatedBy: "\n")
        let top = layoutCenter.y - CGFloat(lines.count) * font.lineHeight / 2
        return lines.enumerated().map { i, text in
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font, .kern: tracking]))
            // Centered lines (two or more) are centered without their trailing tracking.
            let width = CTLineGetTypographicBounds(line, nil, nil, nil) - (lines.count > 1 ? tracking : 0)
            let ink = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
            let baseline = top + CGFloat(i) * font.lineHeight + font.ascender
            return CGRect(x: layoutCenter.x - width / 2 + ink.minX, y: baseline - ink.maxY, width: ink.width, height: ink.height)
        }
    }

    static let reasonFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
    /// What the gauge shows under "—", as `NoSpeedReason.text` resolves in each language.
    static let reasons = [("zh-Hant", "車速暫不可用"), ("zh-Hant", "GPS 不可用"), ("en", "Speed\nunavailable"), ("en", "GPS\nunavailable")]

    static func reasonInk(_ reason: String, geometry g: GaugeGeometry) -> [CGRect] {
        textInk(reason, font: reasonFont, tracking: 1, layoutCenter: CGPoint(
            x: g.size / 2, y: g.reasonCenterY - (reason.contains("\n") ? GaugeView.twoLineReasonRaise : 0)))
    }

    // MARK: Clearance

    @Test(arguments: [CGFloat(300), 280])
    func iconsClearEverythingInTheDisc(gaugeSize: CGFloat) throws {
        let g = GaugeGeometry(size: gaugeSize)
        var tightest: [String: (gap: CGFloat, at: String)] = [:]
        func note(_ what: String, _ gap: CGFloat, _ at: String) {
            if gap < tightest[what]?.gap ?? .infinity { tightest[what] = (gap, at) }
        }
        let icons = CarStatusIcon.allCases.flatMap { icon in
            [false, true].map { dashed in
                (name: "\(icon)\(dashed ? " dashed" : "")", ink: Self.iconInk(icon, dashed: dashed, gaugeSize: gaugeSize, realDashes: true))
            }
        }

        // The numeral at every speed (km/h and mph strings are both in 0–240) and "—".
        let numerals = try (0...240).map { speed in
            (String(speed), try GaugeATests.digitOutlines(String(speed), gaugeSize: gaugeSize).flatMap(Self.segments))
        }
        let dashFont = HUDFont.barlow(HUDFont.regular, size: g.numeralFontSize)
        let dashInk = HUDFont.inkBounds(HUDState.noSpeedNumeral, font: dashFont, tracking: 0)
        let dash = CGRect(x: gaugeSize / 2 - dashInk.width / 2, y: g.numeralCenterY - dashInk.height / 2,
                          width: dashInk.width, height: dashInk.height)
        for icon in icons {
            for (speed, ink) in numerals { note("numeral", Self.gap(icon.ink, ink), "\(icon.name) at \(speed)") }
            note("numeral", Self.gap(icon.ink, Self.rectSegments(dash)), "\(icon.name) at —")
            // The 5 px ring's inner edge.
            let farthest = icon.ink.flatMap { [$0.a, $0.b] }.map { hypot($0.x - g.center.x, $0.y - g.center.y) }.max()!
            note("ring", g.ringRadius - 2.5 - farthest, icon.name)
        }

        // The unit (km/h and mph), the gear row, the reasons and 「P 檔」.
        var others: [(String, CGRect)] = []
        for unit in [SpeedUnit.kilometersPerHour, .milesPerHour] {
            let state = HUDRenderTests.state([.authorization(.authorized)], car: [HUDRenderTests.car(88)], unit: unit)
            others.append(("unit \(unit.symbol)", try #require(GaugeLabels(state: state, geometry: g).unitInk)))
        }
        let gearTop = g.gearRowBaselineY - GearRow.capHeight
        others.append(("gear row", CGRect(x: gaugeSize / 2 - GearRow.width / 2, y: gearTop, width: GearRow.width,
                                          height: GearRow.capHeight + GearRow.underlineOffset + GearRow.underlineHeight)))
        for (_, reason) in Self.reasons {
            for (i, ink) in Self.reasonInk(reason, geometry: g).enumerated() {
                others.append(("reason \(reason.replacingOccurrences(of: "\n", with: " / ")) line \(i + 1)", ink))
                // The reason against the ring too.
                let corners = [CGPoint(x: ink.minX, y: ink.minY), CGPoint(x: ink.maxX, y: ink.minY),
                               CGPoint(x: ink.minX, y: ink.maxY), CGPoint(x: ink.maxX, y: ink.maxY)]
                note("reason to ring", g.ringRadius - 2.5 - corners.map { hypot($0.x - g.center.x, $0.y - g.center.y) }.max()!, reason)
            }
        }
        // 「P 檔」: centered by its advance, the ink of "P" on the numeral's center line; a wording
        // wider than 80% of the disc gets smaller (`GaugeLabels.drawParkedGear`).
        for pGear in ["P 檔", "Gear P"] {
            func advance(_ font: UIFont) -> CGFloat {
                CTLineGetTypographicBounds(CTLineCreateWithAttributedString(NSAttributedString(string: pGear, attributes: [.font: font])), nil, nil, nil)
            }
            var font = GaugeLabels.parkedGearFont
            if advance(font) > 1.6 * g.discRadius {
                font = HUDFont.barlow(HUDFont.regular, size: (font.pointSize * 1.6 * g.discRadius / advance(font)).rounded(.down))
            }
            let p = HUDFont.inkBounds("P", font: font, tracking: 0), ink = HUDFont.inkBounds(pGear, font: font, tracking: 0)
            let baseline = g.numeralCenterY + (p.maxY + p.minY) / 2
            others.append(("P gear \(pGear)", CGRect(x: gaugeSize / 2 - advance(font) / 2 + ink.minX, y: baseline - ink.maxY,
                                                     width: ink.width, height: ink.height)))
        }
        for icon in icons {
            for (name, rect) in others { note(name, Self.gap(icon.ink, Self.rectSegments(rect)), icon.name) }
        }

        // Between slots, solid and dashed alike.
        for (i, a) in icons.enumerated() {
            for b in icons[(i + 1)...] where a.name.prefix(4) != b.name.prefix(4) {
                note("slots", Self.gap(a.ink, b.ink), "\(a.name) – \(b.name)")
            }
        }

        for (what, value) in tightest.sorted(by: { $0.value.gap < $1.value.gap }) {
            print("gauge \(gaugeSize): \(what) \(value.gap) (\(value.at))")
            #expect(value.gap >= (what == "numeral" ? 9 : 6), "\(what): \(value.gap) at \(value.at)")
        }
    }

    // The reason's ink model above is where the gauge really draws it: English on two lines broken
    // at the space, Chinese on one, centered where the one line was.
    @Test(arguments: [CGFloat(300), 280])
    func reasonInkModelMatchesTheRender(gaugeSize: CGFloat) throws {
        let g = GaugeGeometry(size: gaugeSize), scale: CGFloat = 8
        let state = HUDRenderTests.state([.authorization(.authorized), HUDRenderTests.gps(72)], at: 3)
        #expect(state.reason == .speedUnavailable)
        for (locale, reason) in Self.reasons where reason.hasPrefix("Speed") || reason.hasPrefix("車速") {
            let renderer = ImageRenderer(content: GaugeView(state: state, size: gaugeSize).environment(\.locale, Locale(identifier: locale)))
            renderer.scale = scale
            let image = try #require(renderer.cgImage)
            let pixels = try HUDRenderTests.rgba(image), width = image.width
            // Ink below the "—" and inside the dashed ring, antialiased edges included (the disc's red is 15).
            var found = CGRect.null
            for y in Int((g.numeralCenterY + 30) * scale)..<image.height {
                for x in 0..<width where pixels[(y * width + x) * 4] > 50 {
                    let p = CGPoint(x: (CGFloat(x) + 0.5) / scale, y: (CGFloat(y) + 0.5) / scale)
                    if hypot(p.x - g.center.x, p.y - g.center.y) < g.ringRadius - 4 {
                        found = found.union(CGRect(x: CGFloat(x) / scale, y: CGFloat(y) / scale, width: 1 / scale, height: 1 / scale))
                    }
                }
            }
            let model = Self.reasonInk(reason, geometry: g).reduce(CGRect.null) { $0.union($1) }
            print("gauge \(gaugeSize) \(locale): reason ink drawn \(found), modelled \(model)")
            for (a, b) in [(found.minX, model.minX), (found.maxX, model.maxX), (found.minY, model.minY), (found.maxY, model.maxY)] {
                #expect(abs(a - b) <= 0.5, "\(locale): drawn \(found), modelled \(model)")
            }
        }
    }

    // MARK: Shapes

    // The master's shapes stay inside its 22 box (strokes included; the trunk lid's round cap pokes
    // 0.1 above it in the master too), and the curves parse.
    @Test func shapesFitTheBox() {
        for icon in CarStatusIcon.allCases {
            for dashed in [false, true] {
                let ink = Self.bounds(Self.iconInk(icon, dashed: dashed, gaugeSize: 300))
                let center = icon.center(in: CarStatusSlots(gaugeSize: 300))
                #expect(CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24).insetBy(dx: -0.25, dy: -0.25).contains(ink),
                        "\(icon) \(dashed) \(ink)")
            }
        }
        // `Q` follows the control point: the frunk's roof peaks between 6.2 and its control 6.2.
        let roof = SVGPath.parse("M0 10 Q5 0 10 10").boundingRect
        #expect(abs(roof.minY - 5) < 0.01 && roof.minX == 0 && roof.maxX == 10, "\(roof)")
        let relative = SVGPath.parse("M0 10 q5 -10 10 0").boundingRect
        #expect(relative == roof)
    }

    @Test func onlyOpenAndUnknownAreDrawn() {
        let status = CarStatus(frontTrunk: .closed, rearTrunk: .open, door: .unknown)
        #expect(CarStatusIcon.lit(status).map(\.icon) == [.rearTrunk, .door])
        #expect(CarStatusIcon.lit(CarStatus(frontTrunk: .closed, rearTrunk: .closed, door: .closed)).isEmpty)
    }

    // Lighting or putting out one icon changes no pixel outside its own slot.
    @Test(arguments: [HUDRenderTests.Screen.iPhone844, .iPhone667])
    func aSlotNeverMovesTheOthers(screen: HUDRenderTests.Screen) throws {
        let base = try #require(HUDRenderTests.carStatusStates["trunk"])
        var both = base
        both.carStatus?.frontTrunk = .open
        let a = try HUDRenderTests.render(base, screen: screen), b = try HUDRenderTests.render(both, screen: screen)
        let layout = DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
        let size = CarStatusIcon.size(gaugeSize: layout.gaugeArea.width), center = layout.carStatusSlots.frontTrunk
        let slot = CGRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size).insetBy(dx: -1, dy: -1)
        let (inSlot, outside) = HUDRenderTests.changedPixels(a, b, width: Int(screen.size.width), inside: slot)
        #expect(inSlot > 50, "the front trunk did not draw")
        #expect(outside == 0, "\(outside) pixels changed outside the front trunk's slot")
    }

    // MARK: Accessibility

    // One element per lit icon, with the master's sentence (`RING_SAY` / `SAY_EN`, `sayOf` / `sayL`),
    // read from the hosted drive screen in each language; closed parts have none.
    @Test(arguments: [
        ("zh-Hant", [CarStatusIcon.frontTrunk: ("前車廂開著", "前車廂狀態未知"), .rearTrunk: ("後車廂開著", "後車廂狀態未知"),
                     .door: ("車門開著", "車門狀態未知")]),
        ("en", [CarStatusIcon.frontTrunk: ("Frunk open", "Frunk status unknown"), .rearTrunk: ("Rear trunk open", "Rear trunk status unknown"),
                .door: ("Door open", "Door status unknown")]),
    ])
    func eachLitIconSpeaksItsSentence(locale: String, sentences: [CarStatusIcon: (open: String, unknown: String)]) throws {
        let screen = HUDRenderTests.Screen.iPhone844
        var state = try #require(HUDRenderTests.carStatusStates["trunk"])
        let all = sentences.values.flatMap { [$0.open, $0.unknown] }
        func spoken() -> [String] {
            let view = DriveScreen(state: state, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left,
                                   rightInset: screen.right, bottomInset: screen.bottom)
            return DriveScreenAccessibilityTests.elementLabels(view, size: screen.size, locale: locale).filter(all.contains)
        }
        // Each icon alone, open and then unknown: exactly its own sentence.
        for icon in CarStatusIcon.allCases {
            for lit in [CarPartState.open, .unknown] {
                var status = CarStatus(frontTrunk: .closed, rearTrunk: .closed, door: .closed)
                switch icon {
                case .frontTrunk: status.frontTrunk = lit
                case .rearTrunk: status.rearTrunk = lit
                case .door: status.door = lit
                }
                state.carStatus = status
                let expected = lit == .open ? sentences[icon]!.open : sentences[icon]!.unknown
                #expect(spoken() == [expected], "\(locale) \(icon) \(lit)")
            }
        }
        // Two at once: one element each.
        state.carStatus = CarStatus(frontTrunk: .closed, rearTrunk: .open, door: .unknown)
        #expect(spoken().sorted() == [sentences[.rearTrunk]!.open, sentences[.door]!.unknown].sorted(), "\(locale)")
        state.carStatus = CarStatus(frontTrunk: .closed, rearTrunk: .closed, door: .closed)
        #expect(spoken().isEmpty, "\(locale)")
        state.carStatus = nil
        #expect(spoken().isEmpty, "\(locale)")
    }
}
