import CoreText
import HUDCore
import SwiftUI
import UIKit

/// Gauge A: a ring and a disc with the numeral and unit, drawn in the gauge area (DESIGN.md
/// "Main screen — direction A"). The digits sit at `NumeralLayout`'s origins (L88); "—", the
/// unit and the reason are placed by their ink, like the mockups.
struct GaugeView: View {
    let state: HUDState
    let size: CGFloat

    private var geometry: GaugeGeometry { GaugeGeometry(size: size) }

    var body: some View {
        let labels = GaugeLabels(state: state, geometry: geometry)
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                drawDial(in: &context)
                labels.draw(in: &context)
            }
            if let cue = labels.gpsCue {
                // The chip carries the sentence (L87).
                LucideIconView(icon: .navigation, size: cue.size, color: cue.color)
                    .offset(x: cue.origin.x, y: cue.origin.y)
                    .accessibilityHidden(true)
            }
            if let reason = state.reason {
                Text(reason.text)
                    .font(.system(size: 18, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize()
                    .position(x: size / 2, y: geometry.reasonCenterY)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: HUDAccessibility.speedLabel(for: state)))
    }

    /// The disc, then the ring; with no speed the ring is dashed so it never looks like 0 km/h (L39 Q39).
    private func drawDial(in context: inout GraphicsContext) {
        let g = geometry
        func circle(_ radius: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: g.center.x - radius, y: g.center.y - radius, width: 2 * radius, height: 2 * radius))
        }
        context.fill(circle(g.discRadius), with: .color(Palette.disc))
        if state.hasSpeed {
            context.stroke(circle(g.ringRadius), with: .color(Palette.ring), lineWidth: 2)
        } else {
            context.stroke(circle(g.ringRadius), with: .color(Palette.dialNoData),
                           style: StrokeStyle(lineWidth: 2, dash: [5, 8]))
        }
    }
}

/// Fonts and positions of the numeral (digits or "—"), the unit and the GPS cue, in gauge-area points.
struct GaugeLabels {
    let geometry: GaugeGeometry
    let text: String
    let numeralFont: UIFont
    /// The digits' glyph origins; nil for "—".
    let numeral: NumeralLayout?
    /// Ink of the unit; nil with no speed. It hangs off the ink of "0", so it never moves with the digits.
    let unitInk: CGRect?
    let unit: String
    let unitFont: UIFont
    let gpsCue: (origin: CGPoint, size: CGFloat, color: Color)?

    static let unitTracking: CGFloat = 2
    /// Gap between the cue's ink and the unit's ink (L87).
    static let gpsCueGap: CGFloat = 8

    init(state: HUDState, geometry g: GaugeGeometry) {
        geometry = g
        text = state.numeral
        numeral = state.hasSpeed ? NumeralLayout(digits: state.numeral, gaugeSize: g.size) : nil
        numeralFont = HUDFont.barlow(HUDFont.regular, size: numeral?.fontSize ?? g.numeralFontSize)
        unit = state.unit.symbol
        unitFont = HUDFont.barlow(HUDFont.medium, size: g.unitFontSize)
        guard state.hasSpeed else {
            unitInk = nil
            gpsCue = nil
            return
        }
        let ink = HUDFont.inkBounds(unit, font: unitFont, tracking: Self.unitTracking)
        let unitInk = CGRect(x: g.size / 2 - ink.width / 2, y: g.unitCenterY - ink.height / 2,
                             width: ink.width, height: ink.height)
        self.unitInk = unitInk
        // GPS only: amber as the fallback, green as the normal source.
        let color: Color? = switch state.source {
        case .valid(.gps): Palette.sourceOK
        case .gpsFallback: Palette.sourceDegraded
        default: nil
        }
        if let color {
            // Lucide's arrow ink (with its stroke) spans x 2–23 and y 1–22 of the 24 box.
            let size = 14 * g.k, scale = size / 24
            gpsCue = (CGPoint(x: unitInk.minX - Self.gpsCueGap - 23 * scale, y: unitInk.midY - 11.5 * scale), size, color)
        } else {
            gpsCue = nil
        }
    }

    func draw(in context: inout GraphicsContext) {
        if let numeral {
            drawDigits(numeral, in: &context)
        } else {
            let ink = HUDFont.inkBounds(text, font: numeralFont, tracking: 0)
            drawCentered(text, font: numeralFont, tracking: 0, color: Palette.speedUnavailable,
                         inkCenter: CGPoint(x: geometry.size / 2, y: geometry.numeralCenterY), ink: ink, in: &context)
        }
        if let unitInk {
            let ink = HUDFont.inkBounds(unit, font: unitFont, tracking: Self.unitTracking)
            drawCentered(unit, font: unitFont, tracking: Self.unitTracking, color: Palette.unit,
                         inkCenter: CGPoint(x: unitInk.midX, y: unitInk.midY), ink: ink, in: &context)
        }
    }

    /// One CoreText line per digit, with its pen at the layout's origin on the baseline, so the
    /// tabular glyphs land exactly where `NumeralLayout` puts them.
    private func drawDigits(_ layout: NumeralLayout, in context: inout GraphicsContext) {
        let font = numeralFont
        context.withCGContext { cg in
            cg.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            cg.setFillColor(UIColor(Palette.textPrimary).cgColor)
            for (digit, x) in zip(text, layout.digitOrigins) {
                let string = NSAttributedString(string: String(digit), attributes: [
                    .font: font,
                    NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
                ])
                cg.textPosition = CGPoint(x: x, y: layout.baselineY)
                CTLineDraw(CTLineCreateWithAttributedString(string), cg)
            }
        }
    }

    private func drawCentered(_ string: String, font: UIFont, tracking: CGFloat, color: Color,
                              inkCenter: CGPoint, ink: CGRect, in context: inout GraphicsContext) {
        let resolved = context.resolve(
            Text(verbatim: string).font(Font(font)).monospacedDigit().tracking(tracking).foregroundStyle(color))
        let box = CGSize(width: 1000, height: 1000)
        // `ink` is y-up from the baseline origin.
        let baselineY = inkCenter.y + (ink.maxY + ink.minY) / 2
        let origin = CGPoint(x: inkCenter.x - ink.midX, y: baselineY - resolved.firstBaseline(in: box))
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
        case .valid(.carBluetooth): String(localized: "Car Bluetooth")
        case .valid(.gps), .gpsFallback: "GPS"
        default: ""
        }
    }
}
