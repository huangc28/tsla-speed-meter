import HUDCore
import SwiftUI
import UIKit

/// Gauge C "fan" with the numeral and unit, drawn in the gauge area (DESIGN.md Gauge spec).
/// Text is placed by its ink, like the mockups: the numeral's ink center sits at
/// `numeralCenterY`, the unit and reason below the digit ink.
struct GaugeView: View {
    let state: HUDState
    let size: CGFloat

    private var geometry: GaugeGeometry { GaugeGeometry(size: size) }

    var body: some View {
        let numeral = NumeralMetrics(state: state, geometry: geometry)
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                switch state.gauge {
                case .noData: drawNoData(in: &context)
                case .live(let kmh): drawDial(at: kmh, in: &context)
                }
                numeral.draw(in: &context, geometry: geometry, unit: state.hasSpeed ? state.unit.symbol : nil)
            }
            if let reason = state.reason {
                Text(reason.text)
                    .font(.system(size: 18, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize()
                    .position(x: size / 2, y: numeral.digitInkBottom + geometry.reasonGap)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: HUDAccessibility.speedLabel(for: state)))
    }

    // MARK: Dial

    private func halfAnnulus(_ g: GaugeGeometry) -> Path {
        var path = Path()
        path.move(to: g.point(radius: g.outerRadius, angle: 180))
        arc(&path, g, radius: g.outerRadius, from: 180, to: 0)
        path.addLine(to: g.point(radius: g.innerRadius, angle: 0))
        arc(&path, g, radius: g.innerRadius, from: 0, to: 180)
        path.closeSubpath()
        return path
    }

    /// Adds an arc between dial angles (degrees, counterclockwise from 3 o'clock, as in `GaugeGeometry`).
    private func arc(_ path: inout Path, _ g: GaugeGeometry, radius: CGFloat, from a0: Double, to a1: Double) {
        // Screen angles run the other way (y down), so a dial sweep toward smaller angles is clockwise on screen.
        path.addArc(center: g.center, radius: radius, startAngle: .degrees(-a0), endAngle: .degrees(-a1),
                    clockwise: a1 > a0)
    }

    private func drawNoData(in context: inout GraphicsContext) {
        context.stroke(halfAnnulus(geometry), with: .color(Palette.dialNoData),
                       style: StrokeStyle(lineWidth: 2, dash: [5, 8]))
    }

    private func drawDial(at kmh: Double, in context: inout GraphicsContext) {
        let g = geometry, k = g.k, c = g.center
        let a = g.angle(forKilometersPerHour: kmh)

        var face = Path()
        face.move(to: g.point(radius: g.innerRadius, angle: 180))
        arc(&face, g, radius: g.innerRadius, from: 180, to: 0)
        face.closeSubpath()
        context.fill(face, with: .radialGradient(Gradient(colors: [Palette.dialFaceCenter, Palette.dialFace]),
                                                 center: c, startRadius: 0, endRadius: g.innerRadius * 1.4))

        context.fill(halfAnnulus(g), with: .linearGradient(
            Gradient(colors: [Palette.dialBandTop, Palette.dialBandBottom]),
            startPoint: CGPoint(x: c.x, y: c.y - g.outerRadius), endPoint: c))

        if kmh > 0 {
            var fill = Path()
            fill.move(to: g.point(radius: g.outerRadius, angle: 180))
            arc(&fill, g, radius: g.outerRadius, from: 180, to: a)
            fill.addLine(to: g.point(radius: g.fillInnerRadius, angle: a))
            arc(&fill, g, radius: g.fillInnerRadius, from: a, to: 180)
            fill.closeSubpath()
            context.fill(fill, with: .color(Palette.dialFill))

            var edge = Path()
            edge.move(to: g.point(radius: g.outerRadius - 2 * k, angle: 180))
            arc(&edge, g, radius: g.outerRadius - 2 * k, from: 180, to: a)
            context.stroke(edge, with: .color(Palette.dialEdge), lineWidth: 4 * k)
        }

        for mark in stride(from: 0, through: Int(GaugeGeometry.maxKilometersPerHour), by: 10) {
            let major = mark % 40 == 0
            let angle = g.angle(forKilometersPerHour: Double(mark))
            var tick = Path()
            tick.move(to: g.point(radius: g.outerRadius - 5 * k, angle: angle))
            tick.addLine(to: g.point(radius: g.outerRadius - (major ? 17 : 11) * k, angle: angle))
            context.stroke(tick, with: .color(major ? Palette.dialTickMajor : Palette.dialTickMinor),
                           lineWidth: major ? 2.5 : 1.5)
        }

        var needle = Path()
        needle.move(to: g.point(radius: g.fillInnerRadius + 2 * k, angle: a))
        needle.addLine(to: g.point(radius: g.outerRadius - 4 * k, angle: a))
        context.stroke(needle, with: .color(Palette.needleOutline),
                       style: StrokeStyle(lineWidth: 5 * k + 4, lineCap: .round))
        context.stroke(needle, with: .color(Palette.needle), style: StrokeStyle(lineWidth: 5 * k, lineCap: .round))
    }
}

/// Font, tracking and ink-based placement of the numeral (digits or "—") and its unit.
struct NumeralMetrics {
    let text: String
    let font: UIFont
    let tracking: CGFloat
    let color: Color
    let ink: CGRect
    /// Bottom of the digit ink; for "—" the ink of "0" at the same size (as the mockups measure it).
    let digitInkBottom: CGFloat
    let baselineY: CGFloat

    init(state: HUDState, geometry g: GaugeGeometry) {
        let hasSpeed = state.hasSpeed
        let digits = hasSpeed ? state.numeral.count : 2
        text = state.numeral
        font = HUDFont.barlow(HUDFont.regular, size: g.numeralFontSize(digits: digits))
        tracking = hasSpeed ? g.numeralTracking(digits: digits) : 0
        color = hasSpeed ? Palette.textPrimary : Palette.speedUnavailable
        ink = HUDFont.inkBounds(text, font: font, tracking: tracking)
        baselineY = g.numeralCenterY + (ink.maxY + ink.minY) / 2
        let digitInk = hasSpeed ? ink : HUDFont.inkBounds("0", font: font, tracking: 0)
        digitInkBottom = g.numeralCenterY + digitInk.height / 2
    }

    func draw(in context: inout GraphicsContext, geometry g: GaugeGeometry, unit: String?) {
        drawCentered(text, font: font, tracking: tracking, color: color,
                     inkCenterX: g.size / 2, baselineY: baselineY, ink: ink, in: &context)
        guard let unit else { return }
        let unitFont = HUDFont.barlow(HUDFont.medium, size: g.unitFontSize)
        let unitInk = HUDFont.inkBounds(unit, font: unitFont, tracking: 2)
        let unitCenterY = digitInkBottom + g.unitGap
        drawCentered(unit, font: unitFont, tracking: 2, color: Palette.unit, inkCenterX: g.size / 2,
                     baselineY: unitCenterY + (unitInk.maxY + unitInk.minY) / 2, ink: unitInk, in: &context)
    }

    private func drawCentered(_ string: String, font: UIFont, tracking: CGFloat, color: Color,
                              inkCenterX: CGFloat, baselineY: CGFloat, ink: CGRect,
                              in context: inout GraphicsContext) {
        let resolved = context.resolve(
            Text(verbatim: string).font(Font(font)).monospacedDigit().tracking(tracking).foregroundStyle(color))
        let box = CGSize(width: 1000, height: 1000)
        let origin = CGPoint(x: inkCenterX - ink.midX, y: baselineY - resolved.firstBaseline(in: box))
        context.draw(resolved, at: origin, anchor: .topLeading)
    }
}

extension NoSpeedReason {
    var text: LocalizedStringKey {
        switch self {
        case .speedUnavailable: "Speed unavailable"
        case .gpsUnavailable: "GPS unavailable"
        }
    }
}

/// Screen-reader wording (01 §6.1, §7.3): the speed with its unit and source, or the same
/// reason the screen shows under "—".
enum HUDAccessibility {
    static func speedLabel(for state: HUDState) -> String {
        guard state.hasSpeed else {
            return state.reason == .gpsUnavailable ? String(localized: "GPS unavailable") : String(localized: "Speed unavailable")
        }
        let unit = state.unit == .kilometersPerHour ? String(localized: "kilometers per hour") : String(localized: "miles per hour")
        return String(localized: "Current speed \(state.numeral) \(unit), from \(sourceName(state.source))")
    }

    private static func sourceName(_ source: SourceStatus) -> String {
        switch source {
        case .valid(.gps): "GPS"
        default: ""
        }
    }
}
