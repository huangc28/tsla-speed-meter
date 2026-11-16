import Foundation
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// The round gauge's clearance gate (#96 "Gates", DESIGN-atelier-tesla-edition.md "Clearances"), measured
/// as the design measured it (`tools/clr.py`): each layer drawn alone on black at native 1× 844 × 390, an
/// ink mask of the pixels brighter than 60 of 255 (40 for the 0.8-wide ticks, as `clr.py` does), and the
/// distance between pixel centres from each disc to the nearest ink (`edt(…).min()`). The four discs are
/// the 37.1 circles drawn white, as the page's `&ink=disc` draws them, although #99 draws the icons.
@MainActor
struct RoundGaugeClearanceTests {
    static let screen = HUDRenderTests.Screen.iPhone844
    static let canvas = DesignCanvas(screen: screen.size)
    static let width = Int(screen.size.width), height = Int(screen.size.height)
    /// Only the ring's box can hold gauge ink.
    static let box = (x: 250..<594, y: 0..<344)

    /// Pixel indices of `view`'s ink, drawn on black at 1×: luminance (ITU-R 601, as PIL's "L") above `threshold`.
    static func ink(_ view: some View, threshold: Double = 60) throws -> Set<Int> {
        let renderer = ImageRenderer(content: ZStack(alignment: .topLeading) { Color.black; view }
            .frame(width: screen.size.width, height: screen.size.height, alignment: .topLeading))
        renderer.scale = 1
        let image = try #require(renderer.cgImage)
        #expect(image.width == width && image.height == height)
        let pixels = try HUDRenderTests.rgba(image)
        var found = Set<Int>()
        for y in box.y { for x in box.x {
            let i = (y * width + x) * 4
            if 0.299 * Double(pixels[i]) + 0.587 * Double(pixels[i + 1]) + 0.114 * Double(pixels[i + 2]) > threshold {
                found.insert(y * width + x)
            }
        } }
        return found
    }

    static func gauge(_ state: HUDState, _ layers: Set<GaugeLayer>, locale: String = "en") -> some View {
        let frame = GaugeView.frame(canvas)
        return GaugeView(state: state, canvas: canvas, layers: layers)
            .offset(x: frame.minX, y: frame.minY)
            .environment(\.locale, Locale(identifier: locale))
    }

    /// One disc, white, as `discT` draws it with `&ink=`.
    static func disc(_ center: CGPoint) -> some View {
        Canvas { context, _ in
            let r = canvas.length(RoundGauge.discDiameter / 2), c = canvas.point(center)
            context.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(.white))
        }
    }

    static let discNames = ["front trunk", "door", "rear trunk", "tire"]

    /// The four discs' ink, in `discNames` order.
    static func discs() throws -> [Set<Int>] {
        try RoundGauge.slots.discs.map { try ink(disc($0)) }
    }

    /// The pixels of `set` with a 4-neighbour outside it: the nearest pair between two separate inks
    /// always lies on both boundaries.
    static func boundary(_ set: Set<Int>) -> [Int] {
        set.filter { p in [p - 1, p + 1, p - width, p + width].contains { !set.contains($0) } }
    }

    /// The smallest distance between pixel centres of `a` and `b` (0 when they touch the same pixel),
    /// or `limit` when nothing of `b` is nearer.
    static func distance(_ a: Set<Int>, _ b: Set<Int>, limit: Double = 60) -> Double {
        if !a.isDisjoint(with: b) { return 0 }
        let ea = boundary(a), eb = boundary(b)
        let xs = ea.map { $0 % width }, ys = ea.map { $0 / width }
        let near = eb.filter { p in
            let x = p % width, y = p / width
            return x >= xs.min()! - Int(limit) && x <= xs.max()! + Int(limit) && y >= ys.min()! - Int(limit) && y <= ys.max()! + Int(limit)
        }
        var best = limit * limit
        for p in ea {
            let px = Double(p % width), py = Double(p / width)
            for q in near {
                let dx = px - Double(q % width), dy = py - Double(q / width)
                best = min(best, dx * dx + dy * dy)
            }
        }
        return best.squareRoot()
    }

    /// The tightest value per disc, with what it was measured against.
    struct Tightest: CustomStringConvertible {
        var value = Double.infinity, at = ""
        mutating func note(_ v: Double, _ what: String) { if v < value { value = v; at = what } }
        var description: String { String(format: "%.2f (%@)", value, at) }
    }

    static func speedState(_ speed: Int) throws -> HUDState {
        let state = HUDRenderTests.state([.authorization(.authorized)], car: [HUDRenderTests.car(Double(speed))])
        try #require(state.numeral == String(speed))
        return state
    }

    // Disc to numeral ≥ 9 for every speed from 0 to 250, the dash and 「P 檔」 / "Gear P", for all four discs.
    @Test func discsClearTheNumeral() throws {
        let discs = try Self.discs()
        var tightest = Array(repeating: Tightest(), count: 4)
        func measure(_ ink: Set<Int>, _ what: String) {
            #expect(!ink.isEmpty, "\(what) drew nothing")
            for (i, disc) in discs.enumerated() { tightest[i].note(Self.distance(disc, ink), what) }
        }
        for speed in 0...250 {
            measure(try Self.ink(Self.gauge(try Self.speedState(speed), [.numeral])), "\(speed)")
        }
        measure(try Self.ink(Self.gauge(HUDRenderTests.driveStates["no-data"]!.state, [.numeral])), "the dash")
        let parked = try #require(HUDRenderTests.parkedStates["p-unknown"])
        measure(try Self.ink(Self.gauge(parked, [.numeral], locale: "zh-Hant")), "P 檔")
        measure(try Self.ink(Self.gauge(parked, [.numeral], locale: "en")), "Gear P")
        for (name, t) in zip(Self.discNames, tightest) {
            print("round gauge 844 1x: \(name) disc to numeral \(t)")
            #expect(t.value >= 9, "\(name) disc to numeral \(t)")
        }
    }

    // Disc to unit ≥ 8 (km/h and mph, the GPS cue, the reasons under the dash and under 「P 檔」, both
    // languages), disc to gear row ≥ 8 (each gear lit), disc to ticks ≥ 6, disc to disc ≥ 8.
    @Test func discsClearTheRest() throws {
        let discs = try Self.discs()
        var unit = Tightest(), gear = Tightest(), ticks = Tightest(), disc = Tightest()
        var units: [(String, HUDState, String)] = [
            ("km/h", try Self.speedState(188), "en"), ("km/h", try Self.speedState(188), "zh-Hant"),
            ("mph", HUDRenderTests.state([.authorization(.authorized)], car: [HUDRenderTests.car(160)], unit: .milesPerHour), "en"),
            ("km/h with the GPS cue", HUDRenderTests.state([.authorization(.authorized), HUDRenderTests.gps(188)]), "en"),
            ("mph with the fallback cue", HUDRenderTests.state([.authorization(.authorized), HUDRenderTests.gps(118)],
                                                               car: [HUDRenderTests.car(121, age: 3)], unit: .milesPerHour), "en"),
            ("the reason under P", HUDRenderTests.parkedStates["p-unknown"]!, "zh-Hant"),
            ("the reason under Gear P", HUDRenderTests.parkedStates["p-unknown"]!, "en"),
        ]
        let noSpeed = HUDRenderTests.driveStates["no-data"]!.state
        #expect(noSpeed.reason == .speedUnavailable)
        var noGPS = noSpeed
        noGPS.reason = .gpsUnavailable
        for (state, name) in [(noSpeed, "speed"), (noGPS, "GPS")] {
            units += [("the \(name) reason", state, "zh-Hant"), ("the \(name) reason", state, "en")]
        }
        for (what, state, locale) in units {
            let ink = try Self.ink(Self.gauge(state, [.unit], locale: locale))
            #expect(!ink.isEmpty, "\(what) drew nothing")
            for (i, d) in discs.enumerated() { unit.note(Self.distance(d, ink), "\(Self.discNames[i]) – \(what) \(locale)") }
        }
        for g in [CarGear.park, .reverse, .neutral, .drive] {
            let row = GearRow.frame(Self.canvas)
            let ink = try Self.ink(GearRow(gear: g, canvas: Self.canvas).offset(x: row.minX, y: row.minY))
            #expect(!ink.isEmpty)
            for (i, d) in discs.enumerated() { gear.note(Self.distance(d, ink), "\(Self.discNames[i]) – \(g) lit") }
        }
        let tickInk = try Self.ink(Self.gauge(noSpeed, [.ticks]), threshold: 40)
        #expect(tickInk.count > 44)
        for (i, d) in discs.enumerated() { ticks.note(Self.distance(d, tickInk), Self.discNames[i]) }
        for i in discs.indices {
            for j in discs.indices where j > i {
                disc.note(Self.distance(discs[i], discs[j]), "\(Self.discNames[i]) – \(Self.discNames[j])")
            }
        }
        print("round gauge 844 1x: disc to unit \(unit); disc to gear row \(gear); disc to ticks \(ticks); disc to disc \(disc)")
        #expect(unit.value >= 8, "disc to unit \(unit)")
        #expect(gear.value >= 8, "disc to gear row \(gear)")
        #expect(ticks.value >= 6, "disc to ticks \(ticks)")
        #expect(disc.value >= 8, "disc to disc \(disc)")
    }

    // The measure itself: a disc touching ink is 0, and 9 pixels between centres is 9.
    @Test func distanceIsBetweenPixelCentres() {
        let w = Self.width
        #expect(Self.distance([10 * w + 10], [10 * w + 19]) == 9)
        #expect(Self.distance([10 * w + 10, 10 * w + 11], [10 * w + 11]) == 0)
        #expect(abs(Self.distance([10 * w + 10], [13 * w + 14]) - 5) < 1e-12)
    }
}
