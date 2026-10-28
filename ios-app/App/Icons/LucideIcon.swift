import SwiftUI

/// The Lucide icons the drive screen uses (ISC License, `App/Icons/LICENSE-lucide.txt`),
/// drawn from their SVG data in Lucide's 24×24 box.
enum LucideIcon: CaseIterable {
    case bluetooth, bluetoothOff, navigation, triangleAlert, circleDashed, settings

    /// SVG path data in the 24×24 box. Polygons and circles are written as paths.
    var pathData: [String] {
        switch self {
        case .bluetooth: ["m7 7 10 10-5 5V2l5 5L7 17"]
        case .bluetoothOff: ["m17 17-5 5V12l-5 5", "m2 2 20 20", "M14.5 9.5 17 7l-5-5v4.5"]
        case .navigation: ["M3 11 22 2 13 21 11 13z"]
        case .triangleAlert:
            ["m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3", "M12 9v4", "M12 17h.01"]
        case .circleDashed:
            ["M10.1 2.182a10 10 0 0 1 3.8 0", "M13.9 21.818a10 10 0 0 1-3.8 0", "M17.609 3.721a10 10 0 0 1 2.69 2.7",
             "M2.182 13.9a10 10 0 0 1 0-3.8", "M20.279 17.609a10 10 0 0 1-2.7 2.69", "M21.818 10.1a10 10 0 0 1 0 3.8",
             "M3.721 6.391a10 10 0 0 1 2.7-2.69", "M6.391 20.279a10 10 0 0 1-2.69-2.7"]
        case .settings:
            ["M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z",
             "M15 12a3 3 0 1 1-6 0a3 3 0 1 1 6 0z"]
        }
    }

    /// The outline in the 24×24 box.
    var path: Path {
        var path = Path()
        for data in pathData { path.addPath(SVGPath.parse(data)) }
        return path
    }
}

/// A Lucide icon at `size`: stroke 2 in the 24 box (scaled with it), round caps and joins, no fill.
struct LucideIconView: View {
    let icon: LucideIcon
    let size: CGFloat
    let color: Color

    var body: some View {
        LucideShape(icon: icon)
            .stroke(color, style: StrokeStyle(lineWidth: 2 * size / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

struct LucideShape: Shape {
    let icon: LucideIcon

    func path(in rect: CGRect) -> Path {
        icon.path.applying(CGAffineTransform(translationX: rect.minX, y: rect.minY)
            .scaledBy(x: rect.width / 24, y: rect.height / 24))
    }
}

/// The subset of SVG path data Lucide's icons and the car-status shapes use: M L H V Q A Z,
/// absolute and relative, with implicit repeats.
enum SVGPath {
    static func parse(_ data: String) -> Path {
        var path = Path()
        var tokens = data.matches(of: /[A-Za-z]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?/).map { String($0.output) }[...]
        var command: Character = "M"
        var current = CGPoint.zero, start = CGPoint.zero

        func number() -> CGFloat { CGFloat(Double(tokens.popFirst() ?? "0") ?? 0) }
        func point(relative: Bool) -> CGPoint {
            let x = number(), y = number()
            return relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
        }

        while let token = tokens.first {
            if let letter = token.first, letter.isLetter {
                command = letter
                tokens.removeFirst()
                if letter == "Z" || letter == "z" {
                    path.closeSubpath()
                    current = start
                    continue
                }
            }
            let relative = command.isLowercase
            switch command.uppercased() {
            case "M":
                current = point(relative: relative)
                start = current
                path.move(to: current)
                // Further pairs after a move are lines.
                command = relative ? "l" : "L"
            case "L":
                current = point(relative: relative)
                path.addLine(to: current)
            case "H":
                let x = number()
                current.x = relative ? current.x + x : x
                path.addLine(to: current)
            case "V":
                let y = number()
                current.y = relative ? current.y + y : y
                path.addLine(to: current)
            case "Q":
                let control = point(relative: relative), end = point(relative: relative)
                path.addQuadCurve(to: end, control: control)
                current = end
            case "A":
                let rx = number(), ry = number(), rotation = number(), large = number() != 0, sweep = number() != 0
                let end = point(relative: relative)
                addArc(to: &path, from: current, to: end, rx: rx, ry: ry, degrees: rotation, large: large, sweep: sweep)
                current = end
            default:
                tokens.removeFirst()
            }
        }
        return path
    }

    /// An elliptical arc from its endpoint form (SVG 1.1 implementation notes, F.6.5).
    private static func addArc(to path: inout Path, from p1: CGPoint, to p2: CGPoint, rx: CGFloat, ry: CGFloat,
                               degrees: CGFloat, large: Bool, sweep: Bool) {
        var rx = abs(rx), ry = abs(ry)
        guard rx > 0, ry > 0, p1 != p2 else {
            path.addLine(to: p2)
            return
        }
        let phi = degrees * .pi / 180, c = cos(phi), s = sin(phi)
        let dx = (p1.x - p2.x) / 2, dy = (p1.y - p2.y) / 2
        let x1 = c * dx + s * dy, y1 = -s * dx + c * dy
        let lambda = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
        if lambda > 1 {
            rx *= lambda.squareRoot()
            ry *= lambda.squareRoot()
        }
        let numerator = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1
        let coefficient = (large == sweep ? -1 : 1) * max(0, numerator / denominator).squareRoot()
        let cxPrime = coefficient * rx * y1 / ry, cyPrime = -coefficient * ry * x1 / rx
        let center = CGPoint(x: c * cxPrime - s * cyPrime + (p1.x + p2.x) / 2,
                             y: s * cxPrime + c * cyPrime + (p1.y + p2.y) / 2)
        let theta1 = atan2((y1 - cyPrime) / ry, (x1 - cxPrime) / rx)
        let theta2 = atan2((-y1 - cyPrime) / ry, (-x1 - cxPrime) / rx)
        var delta = theta2 - theta1
        if sweep && delta < 0 { delta += 2 * .pi }
        if !sweep && delta > 0 { delta -= 2 * .pi }
        // Drawn on the unit circle, mapped onto the ellipse. With y down, a positive sweep is
        // counterclockwise in CoreGraphics' terms.
        let transform = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: phi).scaledBy(x: rx, y: ry)
        path.addArc(center: .zero, radius: 1, startAngle: .radians(theta1), endAngle: .radians(theta1 + delta),
                    clockwise: delta < 0, transform: transform)
    }
}
