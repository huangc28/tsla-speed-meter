import CoreText
import Foundation
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// The car-status icons (#78): the master's shapes, drawn inside the round gauge's icon discs (#98; the
/// discs' clearance is `RoundGaugeClearanceTests`), and one VoiceOver sentence per lit icon.
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

    static func bounds(_ segments: [Segment]) -> CGRect {
        segments.reduce(CGRect.null) { $0.union(CGRect(x: min($1.a.x, $1.b.x), y: min($1.a.y, $1.b.y),
                                                      width: abs($1.a.x - $1.b.x), height: abs($1.a.y - $1.b.y))) }
    }

    /// The icon's ink outline in screen points on `layout`: fills as drawn, strokes as their full outline
    /// (a dash's gaps are ignored, so the measure is never kinder than the drawing), or with
    /// `realDashes` each dash as drawn.
    static func iconInk(_ icon: CarStatusIcon, dashed: Bool, layout: DriveLayout, realDashes: Bool = false) -> [Segment] {
        let center = icon.center(in: layout.carStatusSlots), size = CarStatusIcon.size(scale: layout.canvas.scale)
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

    nonisolated static let layouts = [HUDRenderTests.Screen.iPhone844, .iPhone667, .iPhone956].map {
        DriveLayout(screen: $0.size, leftInset: $0.left, rightInset: $0.right, bottomInset: $0.bottom)
    }

    // MARK: Discs

    // Until #99 draws the discs, today's icons sit on the disc centres: every icon's ink stays inside its
    // 37.1 disc, so the discs' clearance (`RoundGaugeClearanceTests`) covers the icons too.
    @Test(arguments: layouts)
    func iconsStayInsideTheirDiscs(layout: DriveLayout) {
        let r = layout.canvas.length(RoundGauge.discDiameter / 2)
        for icon in CarStatusIcon.allCases {
            for dashed in [false, true] {
                let center = icon.center(in: layout.carStatusSlots)
                let farthest = Self.iconInk(icon, dashed: dashed, layout: layout).flatMap { [$0.a, $0.b] }
                    .map { hypot($0.x - center.x, $0.y - center.y) }.max() ?? 0
                #expect(farthest <= r - 1, "\(icon) \(dashed): ink reaches \(farthest) of \(r)")
            }
        }
    }

    // MARK: Shapes

    // The master's shapes stay inside its 22 box (strokes included; the trunk lid's round cap pokes
    // 0.1 above it in the master too), and the curves parse.
    @Test func shapesFitTheBox() {
        for icon in CarStatusIcon.allCases {
            for dashed in [false, true] {
                let ink = Self.bounds(Self.iconInk(icon, dashed: dashed, layout: Self.layouts[0]))
                let center = icon.center(in: Self.layouts[0].carStatusSlots)
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
        let size = CarStatusIcon.size(scale: layout.canvas.scale), center = layout.carStatusSlots.frontTrunk
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
