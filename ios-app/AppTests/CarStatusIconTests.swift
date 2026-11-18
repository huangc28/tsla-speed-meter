import Foundation
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// The car-status icon discs (#99): the event rule (L108), the design page's shapes and dashes, and one
/// VoiceOver sentence per lit disc. The discs' clearance is `RoundGaugeClearanceTests`.
@MainActor
struct CarStatusIconTests {
    typealias Segment = (a: CGPoint, b: CGPoint)

    /// Everything closed and the tires normal: nothing lit.
    static let quiet = CarStatus(frontTrunk: .closed, rearTrunk: .closed, door: .closed, tire: .normal)

    /// `quiet` with only `icon` lit as `light`.
    static func status(_ icon: CarStatusIcon, _ light: CarStatusIcon.Light) -> CarStatus {
        var status = quiet
        let part: CarPartState = light == .unknown ? .unknown : .open
        switch icon {
        case .frontTrunk: status.frontTrunk = part
        case .door: status.door = part
        case .rearTrunk: status.rearTrunk = part
        case .tire: status.tire = .low
        }
        return status
    }

    /// Every way `icon` can light.
    static func lights(_ icon: CarStatusIcon) -> [CarStatusIcon.Light] {
        icon == .tire ? [.low] : [.open, .unknown]
    }

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

    /// The icon's ink outline in design points: fills as drawn, strokes as their full outline (a dash's
    /// gaps are ignored, so the measure is never kinder than the drawing).
    static func iconInk(_ icon: CarStatusIcon, _ light: CarStatusIcon.Light) -> [Segment] {
        icon.parts(light).flatMap { part -> [Segment] in
            let path: CGPath = switch part {
            case .line(let data, _, let width):
                SVGPath.parse(data).cgPath.copy(strokingWithWidth: width ?? CarStatusIcon.lineWidth,
                                                lineCap: light == .unknown ? .butt : .round, lineJoin: .round, miterLimit: 10)
            case .fill(let data): SVGPath.parse(data).cgPath
            case .dot(let p, let radius): CGPath(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: 2 * radius, height: 2 * radius),
                                                 transform: nil)
            }
            var transform = icon.cropTransform
            return segments(path.copy(using: &transform)!)
        }
    }

    // MARK: Event rule

    // L108: open and unknown light the front trunk, door and rear trunk; only a low tire lights the tire; the
    // discs come in the slots' order. Closed, normal and a tire with no reading draw nothing.
    @Test func onlyEventsLight() {
        typealias Lit = [String]
        func lit(_ status: CarStatus) -> Lit { CarStatusIcon.lit(status).map { "\($0.icon) \($0.light)" } }
        #expect(lit(Self.quiet).isEmpty)
        #expect(lit(CarStatus(frontTrunk: .closed, rearTrunk: .closed, door: .closed, tire: .noReading)).isEmpty)
        #expect(lit(CarStatus(frontTrunk: .closed, rearTrunk: .closed, door: .closed, tire: .low)) == ["tire low"])
        #expect(lit(CarStatus(frontTrunk: .closed, rearTrunk: .open, door: .unknown)) == ["door unknown", "rearTrunk open"])
        // Connected, no reply yet: the three unknown, the tire nothing.
        #expect(lit(.unknown) == ["frontTrunk unknown", "door unknown", "rearTrunk unknown"])
        #expect(lit(CarStatus(frontTrunk: .open, rearTrunk: .open, door: .open, tire: .low))
            == ["frontTrunk open", "door open", "rearTrunk open", "tire low"])
    }

    // The design's `main-NN` states, through the engine: 01, 04, 08 and 09 nothing, 02 a door and the tire, 05 the
    // front trunk, 06 the rear trunk, 07 all four, 10 the three unknown with the tires normal, 11 nothing for a tire
    // with no reading.
    @Test func designStatesLightTheirDiscs() throws {
        let expected: [String: [String]] = [
            "01": [], "04": [], "08": [], "09": [],
            "02": ["door open", "tire low"], "03": ["door open", "tire low"], "05": ["frontTrunk open"], "06": ["rearTrunk open"],
            "07": ["frontTrunk open", "door open", "rearTrunk open", "tire low"],
            "10": ["frontTrunk unknown", "door unknown", "rearTrunk unknown"], "11": [],
        ]
        for name in HUDRenderTests.mainNames {
            let status = try #require(HUDRenderTests.mainState(name).carStatus, "main-\(name)")
            #expect(CarStatusIcon.lit(status).map { "\($0.icon) \($0.light)" } == expected[name], "main-\(name)")
        }
        // No car data (GPS supplies the speed, or no car): no car status, so nothing is drawn.
        #expect(HUDRenderTests.driveStates["gps-88"]!.state.carStatus == nil)
        #expect(HUDRenderTests.driveStates["gps-fallback-118"]!.state.carStatus == nil)
    }

    // MARK: Shapes

    // Every icon's ink stays inside its disc, 1 inside the 37.1 fill (and so inside the rim), in both lights.
    @Test func iconsStayInsideTheirDiscs() {
        let r = CarStatusIcon.discRadius
        for icon in CarStatusIcon.allCases {
            for light in Self.lights(icon) {
                let c = icon.center
                let farthest = Self.iconInk(icon, light).flatMap { [$0.a, $0.b] }.map { hypot($0.x - c.x, $0.y - c.y) }.max() ?? 0
                #expect(farthest > 8 && farthest <= r - 1, "\(icon) \(light): ink reaches \(farthest) of \(r)")
            }
        }
    }

    /// Each unknown icon's closed outline, as drawn.
    static func outline(_ icon: CarStatusIcon) throws -> Path {
        let lines = icon.parts(.unknown).compactMap { part -> (String, Bool)? in
            if case .line(let data, let closed, _) = part { return (data, closed) }
            return nil
        }
        #expect(icon.parts(.unknown).count == lines.count, "\(icon): unknown has no fills")
        let (outline, closed) = try #require(lines.first)
        #expect(closed)
        return SVGPath.parse(outline)
    }

    /// The length of each piece of `path`, one per subpath.
    static func pieces(_ path: CGPath) -> [CGFloat] {
        var pieces: [CGMutablePath] = []
        path.applyWithBlock { element in
            let e = element.pointee, p = e.points
            switch e.type {
            case .moveToPoint:
                pieces.append(CGMutablePath())
                pieces[pieces.count - 1].move(to: p[0])
            case .addLineToPoint: pieces.last?.addLine(to: p[0])
            case .addQuadCurveToPoint: pieces.last?.addQuadCurve(to: p[1], control: p[0])
            case .addCurveToPoint: pieces.last?.addCurve(to: p[2], control1: p[0], control2: p[1])
            case .closeSubpath: pieces.last?.closeSubpath()
            @unknown default: break
            }
        }
        return pieces.map { CarStatusIcon.length($0) }
    }

    // The guide's "Shapes": lines about 1.7 at 1×; the unknown outline in dashes from the design's `tDash` at the
    // app's gap (45, 3.57), so each closed outline takes whole periods of the dash and gap drawn; the dash within
    // `tDash`'s own bounds (at least 50 units, at most 6.7 at 1×); the door's short sill solid; the tire never dashed.
    @Test func dashesFollowTheDesign() throws {
        #expect(abs(CarStatusIcon.lineWidth * CarStatusIcon.cropUnit - 1.665) < 0.001)
        #expect(abs(CarStatusIcon.nativeGap * CarStatusIcon.cropUnit - 3.568) < 0.001)
        for icon in [CarStatusIcon.frontTrunk, .door, .rearTrunk] {
            let outline = try Self.outline(icon)
            let length = CarStatusIcon.length(outline.cgPath)
            let dash = try #require(icon.dash(outline, closed: true))
            let period = dash.lengths[0] + dash.lengths[1], n = (length / period).rounded()
            print("\(icon) unknown: outline \(length), dash \(dash.lengths) phase \(dash.phase), \(length / period) periods")
            #expect(abs(n * period - length) < 0.05, "\(icon): \(length / period) periods of \(period)")
            #expect((CarStatusIcon.dashMin...(6.7 / CarStatusIcon.cropUnit)).contains(dash.lengths[0]), "\(icon): dash \(dash.lengths[0])")
            #expect(dash.lengths[1] == CarStatusIcon.nativeGap && dash.phase == icon.nativePhase)
        }
        #expect(CarStatusIcon.dash(length: 70, closed: false, phase: 33) == nil, "the door's sill is solid")
        // `tDash` on an open line: solid at both ends, the dash stretched to fit.
        let open = try #require(CarStatusIcon.dash(length: 250, closed: false, phase: 33, gap: 35))
        #expect(open.phase == 0 && abs(open.lengths[0] * 3 + 35 * 2 - 250) < 0.01 && open.lengths[1] == 35)
        // `tDash` at the design's gap gives the design's dashes (66.21, 62.68, 55.04).
        for (icon, designDash) in [(CarStatusIcon.frontTrunk, 66.21), (.door, 62.68), (.rearTrunk, 55.04)] {
            let length = CarStatusIcon.length(try Self.outline(icon).cgPath)
            #expect(CarStatusIcon.dash(length: length, closed: true, phase: 0, gap: 35)?.lengths[0] == CGFloat(designDash), "\(icon)")
        }
        // The path's length is SVG's: a 100 × 50 rectangle is 300, a circle of 100 is 2π · 100.
        #expect(abs(CarStatusIcon.length(SVGPath.parse("M0 0 H100 V50 H0 Z").cgPath) - 300) < 1e-9)
        #expect(abs(CarStatusIcon.length(SVGPath.parse("M0 100 A100 100 0 0 1 0 -100 A100 100 0 0 1 0 100").cgPath)
            - 2 * .pi * 100) < 0.1)
    }

    // CoreGraphics' own dashed outline: every piece it draws is one whole dash, with no stub and no two dashes merged,
    // except that the dash over the outline's start may be split there into two parts that add up to one dash. Within
    // 1 unit (0.08 px): CoreGraphics measures curves a little shorter than `length`, so a piece over a curve reads up
    // to 0.15 long here and the seam takes up the rest (0.6); a stub or a merged dash is off by 20 units or more.
    @Test func drawnDashesAreWhole() throws {
        let tolerance: CGFloat = 1
        for icon in [CarStatusIcon.frontTrunk, .door, .rearTrunk] {
            let outline = try Self.outline(icon)
            let dash = try #require(icon.dash(outline, closed: true))
            let seg = dash.lengths[0]
            var pieces = Self.pieces(outline.cgPath.copy(dashingWithPhase: dash.phase, lengths: dash.lengths))
            let n = Int((CarStatusIcon.length(outline.cgPath) / (seg + dash.lengths[1])).rounded())
            if pieces.count == n + 1, let first = pieces.first, let last = pieces.last, abs(first - seg) > tolerance {
                #expect(abs(first + last - seg) <= tolerance, "\(icon): the seam's parts \(first) + \(last), not \(seg)")
                pieces = Array(pieces.dropFirst().dropLast())
            }
            print("\(icon) drawn dashes: \(pieces.map { String(format: "%.2f", $0) })")
            #expect(pieces.count >= n - 1, "\(icon): \(pieces.count) whole pieces for \(n) dashes")
            for piece in pieces { #expect(abs(piece - seg) <= tolerance, "\(icon): a piece of \(piece), the dash is \(seg)") }
        }
    }

    // The guide's colours, one per light: open red `#EF6A69`, low amber `#EFA83F`, unknown grey `#A6ACB5`, the same
    // for every icon that can show it.
    @Test func eachLightHasItsColour() {
        func rgb(_ color: Color) -> [Int] {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
            return [r, g, b, a].map { Int(($0 * 255).rounded()) }
        }
        let expected: [CarStatusIcon.Light: [Int]] = [.open: [0xEF, 0x6A, 0x69, 255], .low: [0xEF, 0xA8, 0x3F, 255],
                                                      .unknown: [0xA6, 0xAC, 0xB5, 255]]
        for icon in CarStatusIcon.allCases {
            for light in Self.lights(icon) { #expect(rgb(icon.color(light)) == expected[light], "\(icon) \(light)") }
        }
    }

    // `C` follows its control points: a cubic from (0, 0) to (10, 0) with both controls at y 10 peaks at 7.5;
    // relative `c` is the same curve.
    @Test func cubicsParse() {
        let arch = SVGPath.parse("M0 0 C0 10 10 10 10 0").boundingRect
        #expect(abs(arch.maxY - 7.5) < 0.01 && arch.minX == 0 && arch.maxX == 10, "\(arch)")
        #expect(SVGPath.parse("M0 0 c0 10 10 10 10 0").boundingRect == arch)
    }

    // The unknown dashes leave a real gap of at least 2 px at native 1× 844, measured on the render as the
    // design measured it (`tools/dashgap.py`): ink is coverage over the disc ≥ 25%, a gap is a run of pixels
    // under 25% between two of 50% or more, along every row and column through the outline. Gated per icon at
    // 844; at 667 and 956 the canvas scales the gap, so it is reported, not gated. On a gap under 2 px the
    // render is saved as `Snapshots/dash-gaps-<width>-actual.png`.
    @Test(arguments: [HUDRenderTests.Screen.iPhone844, .iPhone667, .iPhone956])
    func unknownDashesLeaveRealGaps(screen: HUDRenderTests.Screen) throws {
        let view = DriveScreen(state: HUDRenderTests.mainState("10"), now: HUDRenderTests.now, screen: screen.size,
                               leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
            .environment(\.locale, Locale(identifier: "zh-Hant"))
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(screen.size)
        renderer.scale = 1
        let image = try #require(renderer.uiImage)
        let pixels = try HUDRenderTests.rgba(try #require(image.cgImage))
        let canvas = DesignCanvas(screen: screen.size)
        var smallest = Int.max
        for icon in [CarStatusIcon.frontTrunk, .door, .rearTrunk] {
            let gaps = Self.dashGaps(pixels, width: Int(screen.size.width), center: canvas.point(icon.center))
            print("dash gaps \(Int(screen.size.width)) 1x \(icon): \(gaps.count) gaps, smallest \(gaps.min() ?? -1) px")
            #expect(gaps.count >= 3, "\(icon): \(gaps.count) gaps found; the slot may be off")
            smallest = min(smallest, gaps.min() ?? 0)
            if screen.size.width == 844 {
                #expect((gaps.min() ?? 0) >= 2, "\(icon): a gap of \(gaps.min() ?? 0) px")
            }
        }
        if smallest < 2 {
            try FileManager.default.createDirectory(at: HUDRenderTests.snapshotDirectory, withIntermediateDirectories: true)
            try image.pngData()?.write(to: HUDRenderTests.snapshotDirectory.appendingPathComponent("dash-gaps-\(Int(screen.size.width))-actual.png"))
        }
    }

    /// `dashgap.py`'s `measure`: the gaps along rows and columns of the 35 × 35 window round `center`.
    static func dashGaps(_ pixels: [UInt8], width: Int, center: CGPoint) -> [Int] {
        let ink = (166.0 + 172 + 181) / 3, x0 = Int(center.x) - 17, y0 = Int(center.y) - 17
        var cover = Array(repeating: Array(repeating: 0.0, count: 35), count: 35)
        for r in 0..<35 {
            var lum = [Double](), inside = [Bool]()
            for c in 0..<35 {
                let i = ((y0 + r) * width + x0 + c) * 4
                lum.append((Double(pixels[i]) + Double(pixels[i + 1]) + Double(pixels[i + 2])) / 3)
                inside.append(hypot(Double(c + x0) + 0.5 - center.x, Double(r + y0) + 0.5 - center.y) < 16.5)
            }
            let disc = zip(lum, inside).filter(\.1).map(\.0).sorted()
            guard disc.count >= 4 else { continue }
            // numpy's 20th percentile, linear: this row's disc.
            let at = 0.2 * Double(disc.count - 1), lo = Int(at), t = at - Double(lo)
            let ground = disc[lo] + (disc[min(lo + 1, disc.count - 1)] - disc[lo]) * t
            for c in 0..<35 where inside[c] { cover[r][c] = min(1, max(0, (lum[c] - ground) / (ink - ground))) }
        }
        func runs(_ line: [Double]) -> [Int] {
            var out = [Int](), i = 0
            let n = line.count
            while i < n {
                guard line[i] >= 0.5 else { i += 1; continue }
                var j = i
                while j + 1 < n && line[j + 1] >= 0.25 { j += 1 }
                var k = j + 1
                while k < n && line[k] < 0.25 { k += 1 }
                if k < n && k - j - 1 <= 4 {
                    var e = k
                    while e < n && line[e] >= 0.25 && line[e] < 0.5 { e += 1 }
                    if e < n && line[e] >= 0.5 && k - j - 1 >= 1 { out.append(k - j - 1) }
                }
                i = max(k, i + 1)
            }
            return out
        }
        var gaps = [Int]()
        for r in 0..<35 where cover[r].filter({ $0 >= 0.5 }).count >= 5 { gaps += runs(cover[r]) }
        for c in 0..<35 {
            let column = (0..<35).map { cover[$0][c] }
            if column.filter({ $0 >= 0.5 }).count >= 5 { gaps += runs(column) }
        }
        return gaps
    }

    // MARK: Slots

    // Lighting or putting out one disc changes no pixel outside its own disc's box, in every state.
    @Test(arguments: [HUDRenderTests.Screen.iPhone844, .iPhone667])
    func aSlotNeverMovesTheOthers(screen: HUDRenderTests.Screen) throws {
        let base = try #require(HUDRenderTests.carStatusStates["trunk"])
        let canvas = DesignCanvas(screen: screen.size)
        for icon in CarStatusIcon.allCases where icon != .rearTrunk {
            for light in Self.lights(icon) {
                var lit = base
                lit.carStatus = Self.status(icon, light)
                lit.carStatus?.rearTrunk = .open
                let a = try HUDRenderTests.render(base, screen: screen), b = try HUDRenderTests.render(lit, screen: screen)
                let slot = CarStatusDiscView.frame(icon, canvas: canvas)
                let (inSlot, outside) = HUDRenderTests.changedPixels(a, b, width: Int(screen.size.width), inside: slot)
                #expect(inSlot > 300, "\(icon) \(light) did not draw")
                #expect(outside == 0, "\(outside) pixels changed outside the \(icon) disc")
            }
        }
    }

    // MARK: Accessibility

    // One element per lit disc, with its sentence, read from the hosted drive screen in each language; in the
    // slots' order when all four light; none when nothing lights or without car data.
    @Test(arguments: [
        ("zh-Hant", ["前車廂開著", "車門開著", "後車廂開著", "胎壓不足"], ["前車廂狀態未知", "車門狀態未知", "後車廂狀態未知"]),
        ("en", ["Frunk open", "Door open", "Rear trunk open", "Tire pressure low"],
         ["Frunk status unknown", "Door status unknown", "Rear trunk status unknown"]),
    ])
    func eachLitDiscSpeaksItsSentence(locale: String, open: [String], unknown: [String]) throws {
        let screen = HUDRenderTests.Screen.iPhone844
        var state = try #require(HUDRenderTests.carStatusStates["trunk"])
        let all = open + unknown
        func spoken() -> [String] {
            let view = DriveScreen(state: state, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left,
                                   rightInset: screen.right, bottomInset: screen.bottom)
            return DriveScreenAccessibilityTests.elementLabels(view, size: screen.size, locale: locale).filter(all.contains)
        }
        // Each alone, in each light: exactly its own sentence.
        for (index, icon) in CarStatusIcon.allCases.enumerated() {
            for light in Self.lights(icon) {
                state.carStatus = Self.status(icon, light)
                #expect(spoken() == [light == .unknown ? unknown[index] : open[index]], "\(locale) \(icon) \(light)")
            }
        }
        state.carStatus = CarStatus(frontTrunk: .open, rearTrunk: .open, door: .open, tire: .low)
        #expect(spoken() == open, "\(locale)")
        state.carStatus = .unknown
        #expect(spoken() == unknown, "\(locale)")
        state.carStatus = Self.quiet
        #expect(spoken().isEmpty, "\(locale)")
        state.carStatus?.tire = .noReading
        #expect(spoken().isEmpty, "\(locale)")
        state.carStatus = nil
        #expect(spoken().isEmpty, "\(locale)")
    }
}
