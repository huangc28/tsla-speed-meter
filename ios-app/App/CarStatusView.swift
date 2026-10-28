import HUDCore
import SwiftUI

/// The car-status icons inside the ring (#78, DESIGN.md "Car-status icons", L71, L87): the master's
/// `ICON` shapes in its 22 box, drawn 24 × k wide at `DriveLayout`'s slot centers. Open is solid in
/// `telltale.open`; unknown is the same shape's dashed outline in `unit` (the master's `UNK`);
/// closed draws nothing. Each lit icon is its own accessibility element, with no words on screen.
enum CarStatusIcon: CaseIterable {
    /// Side view, nose to the left, the hood lifted (lower-left slot).
    case frontTrunk
    /// Side view, nose to the left, the trunk lid lifted (lower-right slot).
    case rearTrunk
    /// Top view, nose up, the right front door open (bottom-center slot).
    case door

    /// The master's icon box.
    static let box: CGFloat = 22
    /// The master's `UNK`: the dashed body and the solid lid of an unknown part.
    static let dashedWidth: CGFloat = 1.8, dash: [CGFloat] = [2, 2], dashedLidWidth: CGFloat = 2.5

    /// 24 at 844, 24 × k at 667; large text keeps it, because the disc has no room.
    static func size(gaugeSize: CGFloat) -> CGFloat { 24 * gaugeSize / 300 }

    /// The lit icons, in the master's order (front trunk, rear trunk, door).
    static func lit(_ status: CarStatus) -> [(icon: CarStatusIcon, state: CarPartState)] {
        allCases.map { ($0, $0.state(in: status)) }.filter { $0.state != .closed }
    }

    func state(in status: CarStatus) -> CarPartState {
        switch self {
        case .frontTrunk: status.frontTrunk
        case .rearTrunk: status.rearTrunk
        case .door: status.door
        }
    }

    func center(in slots: CarStatusSlots) -> CGPoint {
        switch self {
        case .frontTrunk: slots.frontTrunk
        case .rearTrunk: slots.rearTrunk
        case .door: slots.door
        }
    }

    /// The master's `RING_SAY` / `SAY_EN` and `sayOf` / `sayL`.
    func label(_ state: CarPartState) -> LocalizedStringKey {
        switch (self, state == .unknown) {
        case (.frontTrunk, false): "Frunk open"
        case (.rearTrunk, false): "Rear trunk open"
        case (.door, false): "Door open"
        case (.frontTrunk, true): "Frunk status unknown"
        case (.rearTrunk, true): "Rear trunk status unknown"
        case (.door, true): "Door status unknown"
        }
    }

    enum Part {
        case fill(Path, eoFill: Bool)
        case stroke(Path, StrokeStyle)
    }

    /// What the master draws, in its 22 box: solid (open) or the dashed outline (unknown).
    func parts(dashed: Bool) -> [Part] {
        func lid(_ data: String, width: CGFloat) -> Part {
            .stroke(SVGPath.parse(data), StrokeStyle(lineWidth: dashed ? Self.dashedLidWidth : width, lineCap: .round))
        }
        let outline = StrokeStyle(lineWidth: Self.dashedWidth, lineJoin: .round, dash: Self.dash)
        switch self {
        case .frontTrunk, .rearTrunk:
            let side = self == .frontTrunk ? Self.frunk : Self.trunk
            // The master's `sideIcon` draws both a unit higher.
            let up = CGAffineTransform(translationX: 0, y: -1)
            let parts: [Part] = dashed
                ? [.stroke(SVGPath.parse((side.dashedTop ?? side.top) + Self.roll), outline)]
                : [.fill(SVGPath.parse(side.top + Self.arch), eoFill: false), .fill(Self.wheels, eoFill: false)]
            return (parts + [lid(side.lid, width: side.lidWidth)]).map { $0.applying(up) }
        case .door:
            if dashed {
                return [.stroke(SVGPath.parse(Self.doorBody), outline), lid(Self.doorLid, width: 2.6)]
            }
            return [.fill(SVGPath.parse(Self.doorBody + " " + Self.doorHoles), eoFill: true),
                    .fill(SVGPath.parse(Self.doorNubs), eoFill: false), lid(Self.doorLid, width: 2.6)]
        }
    }

    func draw(dashed: Bool, color: Color, in context: inout GraphicsContext) {
        for part in parts(dashed: dashed) {
            switch part {
            case .fill(let path, let eoFill): context.fill(path, with: .color(color), style: FillStyle(eoFill: eoFill))
            case .stroke(let path, let style): context.stroke(path, with: .color(color), style: style)
            }
        }
    }

    // MARK: The master's shapes (`SHAPE`, `ARCH`, `ROLL`, `WHEELS`)

    private struct Side {
        let top: String
        /// The unknown outline's top, when it differs (the trunk's open recess is left out).
        var dashedTop: String? = nil
        let lid: String
        let lidWidth: CGFloat
    }

    private static let frunk = Side(
        top: "M1.5 16 V12.4 Q1.5 11.6 2.3 11.6 H7.8 L10.2 6.9 Q10.9 6.2 12 6.2 H15.4 Q16.4 6.2 17 6.9 L19.3 9.7 Q20.5 10 20.5 11.4 V16 ",
        lid: "M7.6 10.4 L2.8 5.4", lidWidth: 2)
    private static let trunk = Side(
        top: "M1.5 16 V12.6 Q1.5 11.4 2.8 11.2 L6.6 10.4 L9.3 7.2 Q9.9 6.5 10.9 6.5 H12.8 Q13.6 6.5 14.1 7.1 L16.3 10 V12.4 H19.2 V10.4 H19.9 Q20.5 10.4 20.5 11 V16 ",
        dashedTop: "M1.5 16 V12.6 Q1.5 11.4 2.8 11.2 L6.6 10.4 L9.3 7.2 Q9.9 6.5 10.9 6.5 H12.8 Q13.6 6.5 14.1 7.1 L16.3 10 H19.9 Q20.5 10.4 20.5 11 V16 ",
        lid: "M16.9 9.4 L20.1 2.3", lidWidth: 2.8)
    /// The solid side view's bottom edge, with the wheel arches cut out.
    private static let arch = "H19.9 A3.5 3.5 0 0 0 12.9 16 H9.1 A3.5 3.5 0 0 0 2.1 16 Z"
    /// The dashed side view's bottom edge, following the wheels' outer edges.
    private static let roll = "H18.9 A2.5 2.5 0 0 1 13.9 16 H8.1 A2.5 2.5 0 0 1 3.1 16 Z"
    private static let wheels = Path { path in
        for x: CGFloat in [5.6, 16.4] { path.addEllipse(in: CGRect(x: x - 2.5, y: 16.2 - 2.5, width: 5, height: 5)) }
    }
    private static let doorBody =
        "M8.6 1.6 H9.4 Q13.4 1.6 13.4 6 V9.4 H12.1 V14.8 H13.4 V17.6 Q13.4 20.6 10.4 20.6 H7.6 Q4.6 20.6 4.6 17.6 V6 Q4.6 1.6 8.6 1.6 Z"
    /// The windshield and rear window, cut out of the body (even-odd).
    private static let doorHoles = "M6 7.9 Q9 6.1 12 7.9 L11.4 10 Q9 9 6.6 10 Z M6.6 16.6 Q9 17.4 11.4 16.6 L11.6 18.4 Q9 19.4 6.4 18.4 Z"
    private static let doorNubs = "M3.3 4.6 H4.6 V8 H3.3 Z M3.3 14.6 H4.6 V18 H3.3 Z M13.4 4.6 H14.7 V8 H13.4 Z M13.4 14.9 H14.7 V18 H13.4 Z"
    private static let doorLid = "M13.6 9.6 L19.6 13.9"
}

extension CarStatusIcon.Part {
    func applying(_ transform: CGAffineTransform) -> Self {
        switch self {
        case .fill(let path, let eoFill): .fill(path.applying(transform), eoFill: eoFill)
        case .stroke(let path, let style): .stroke(path.applying(transform), style)
        }
    }
}

/// One lit icon, `size` square, with its own sentence (「後車廂開著」「車門狀態未知」).
struct CarStatusIconView: View {
    let icon: CarStatusIcon
    let state: CarPartState
    let size: CGFloat

    var body: some View {
        Canvas { context, _ in
            context.scaleBy(x: size / CarStatusIcon.box, y: size / CarStatusIcon.box)
            icon.draw(dashed: state == .unknown, color: state == .unknown ? Palette.unit : Palette.telltaleOpen, in: &context)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(icon.label(state)))
    }
}
