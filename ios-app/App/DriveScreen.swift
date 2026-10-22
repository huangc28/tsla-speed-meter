import HUDCore
import SwiftUI

/// The drive screen (S04 / S05): source chip top-left, gauge C centered and fixed,
/// bottom-left battery slot (empty on GPS), nothing animated (L31, L32).
struct DriveScreen: View {
    let state: HUDState
    let screen: CGSize
    let layout: DriveLayout

    init(state: HUDState, screen: CGSize, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat) {
        self.state = state
        self.screen = screen
        layout = DriveLayout(screen: screen, leftInset: leftInset, rightInset: rightInset, bottomInset: bottomInset)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RadialGradient(colors: [Palette.backgroundGlow, Palette.background],
                           center: UnitPoint(x: 0.5, y: 0.45), startRadius: 0,
                           endRadius: hypot(screen.width / 2, screen.height * 0.55))
            SourceChip(status: state.source)
                .offset(x: layout.sourceChipOrigin.x, y: layout.sourceChipOrigin.y)
            GaugeView(state: state, size: layout.gaugeArea.width)
                .offset(x: layout.gaugeArea.minX, y: layout.gaugeArea.minY)
            // `layout.batterySlot` stays empty: battery / range needs Car Bluetooth (L50, 01 §7.4).
        }
        .frame(width: screen.width, height: screen.height, alignment: .topLeading)
        .background(Palette.background)
        .transaction { $0.animation = nil }
    }
}

/// Always names the current speed source with a shape, a color and a word (L3, L9, 01 §3.4).
struct SourceChip: View {
    let status: SourceStatus

    var body: some View {
        HStack(spacing: 8) {
            SourceMarkerView(marker: status.marker)
            Text(status.label)
                .font(.system(size: 13, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
                .fixedSize()
        }
        .frame(height: 28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Speed source: \(Text(status.label))"))
    }
}

struct SourceMarkerView: View {
    let marker: SourceMarker

    var body: some View {
        switch marker {
        case .valid:
            Circle().fill(Palette.sourceOK).frame(width: 12, height: 12)
        case .fallback:
            Circle()
                .fill(LinearGradient(stops: [.init(color: Palette.sourceDegraded, location: 0.5),
                                             .init(color: .clear, location: 0.5)],
                                     startPoint: .leading, endPoint: .trailing))
                .overlay(Circle().strokeBorder(Palette.sourceDegraded, lineWidth: 2))
                .frame(width: 12, height: 12)
        case .waiting:
            Circle().strokeBorder(Palette.unit, style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
                .frame(width: 12, height: 12)
        case .noSpeed:
            Triangle().fill(Palette.sourceDegraded).frame(width: 14, height: 12)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

extension SourceStatus {
    /// Chip wording from 01 §6.1. The GPS source is never called "Tesla".
    var label: LocalizedStringKey {
        switch self {
        case .valid(.gps): "GPS"
        case .waiting: "Waiting for speed"
        case .searchingGPS: "Searching for GPS…"
        case .speedUnavailable: "Speed unavailable"
        case .gpsUnavailable: "GPS unavailable"
        }
    }
}
