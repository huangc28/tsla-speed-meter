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
/// the production disc layer (#99, `CarStatusDiscs`), each slot lit in every state it can show: its ink is
/// the pixels it covers by more than 60 of 255, as the page's white `&ink=disc` circle passes 60 on black.
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

    /// Pixel indices that `view`, drawn alone on a clear ground at 1×, covers by more than `threshold` of 255
    /// (its alpha): what a white drawing of it on black would pass at luminance `threshold`.
    static func coverage(_ view: some View, threshold: Int = 60) throws -> Set<Int> {
        let renderer = ImageRenderer(content: view.frame(width: screen.size.width, height: screen.size.height, alignment: .topLeading))
        renderer.scale = 1
        let image = try #require(renderer.cgImage)
        #expect(image.width == width && image.height == height)
        let pixels = try HUDRenderTests.rgba(image)
        var found = Set<Int>()
        for y in box.y { for x in box.x where Int(pixels[(y * width + x) * 4 + 3]) > threshold { found.insert(y * width + x) } }
        return found
    }

    /// One disc, white, as `discT` draws it with `&ink=`: the design's own measure, kept beside the production one.
    static func whiteDisc(_ center: CGPoint) -> some View {
        Canvas { context, _ in
            let r = canvas.length(RoundGauge.discDiameter / 2), c = canvas.point(center)
            context.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(.white))
        }
    }

    static let discNames = ["front trunk", "door", "rear trunk", "tire"]

    /// The four discs' ink, in `discNames` order: each slot as `DriveScreen` draws it, lit alone in each of its
    /// states (open and unknown, or low), the union of their coverage.
    static func discs() throws -> [Set<Int>] {
        try CarStatusIcon.allCases.map { icon in
            try CarStatusIconTests.lights(icon).reduce(into: Set<Int>()) { ink, light in
                ink.formUnion(try coverage(CarStatusDiscs(status: CarStatusIconTests.status(icon, light), canvas: canvas)))
            }
        }
    }

    /// The design's white discs, in `discNames` order.
    static func whiteDiscs() throws -> [Set<Int>] {
        try RoundGauge.slots.discs.map { try ink(whiteDisc($0)) }
    }

    // The production disc layer covers at least the slot the design measured: each disc's ink against the white
    // disc's, pixel by pixel, with the clearance both give to the tightest numerals (tire: …4, rear trunk: …7).
    @Test func productionDiscsMatchTheMeasuredDiscs() throws {
        let discs = try Self.discs(), white = try Self.whiteDiscs()
        // The full silhouette, any coverage at all, for the record.
        let silhouettes = try CarStatusIcon.allCases.map { icon in
            try CarStatusIconTests.lights(icon).reduce(into: Set<Int>()) { ink, light in
                ink.formUnion(try Self.coverage(CarStatusDiscs(status: CarStatusIconTests.status(icon, light), canvas: Self.canvas), threshold: 0))
            }
        }
        let numerals = try [104, 114, 124, 194, 204, 244, 107, 117, 187, 247].map { speed in
            (speed, try Self.ink(Self.gauge(try Self.speedState(speed), [.numeral])))
        }
        for i in discs.indices {
            let extra = discs[i].subtracting(white[i]).count, missing = white[i].subtracting(discs[i]).count
            let near = numerals.map { ($0.0, Self.distance(discs[i], $0.1), Self.distance(white[i], $0.1)) }.min { $0.1 < $1.1 }!
            print("round gauge 844 1x: \(Self.discNames[i]) disc \(discs[i].count) px, white disc \(white[i].count) px; "
                + "\(extra) more, \(missing) fewer; nearest numeral \(near.0): \(String(format: "%.2f", near.1)) "
                + "(white disc \(String(format: "%.2f", near.2)))")
            #expect(discs[i].count > 1000, "\(Self.discNames[i]) drew nothing")
            let any = Self.distance(silhouettes[i], numerals.first { $0.0 == near.0 }!.1)
            print("round gauge 844 1x: \(Self.discNames[i]) silhouette (alpha > 0) \(silhouettes[i].count) px; to numeral \(near.0): "
                + String(format: "%.2f", any))
            // Never kinder than the design's measure.
            #expect(missing == 0, "\(Self.discNames[i]): \(missing) pixels of the white disc not covered")
        }
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
        var unit = Array(repeating: Tightest(), count: 4), gear = unit, ticks = unit, disc = Tightest()
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
            for (i, d) in discs.enumerated() { unit[i].note(Self.distance(d, ink), "\(what) \(locale)") }
        }
        for g in [CarGear.park, .reverse, .neutral, .drive] {
            let row = GearRow.frame(Self.canvas)
            let ink = try Self.ink(GearRow(gear: g, canvas: Self.canvas).offset(x: row.minX, y: row.minY))
            #expect(!ink.isEmpty)
            for (i, d) in discs.enumerated() { gear[i].note(Self.distance(d, ink), "\(g) lit") }
        }
        let tickInk = try Self.ink(Self.gauge(noSpeed, [.ticks]), threshold: 40)
        #expect(tickInk.count > 44)
        for (i, d) in discs.enumerated() { ticks[i].note(Self.distance(d, tickInk), "ticks") }
        for i in discs.indices {
            for j in discs.indices where j > i {
                disc.note(Self.distance(discs[i], discs[j]), "\(Self.discNames[i]) – \(Self.discNames[j])")
            }
        }
        for (i, name) in Self.discNames.enumerated() {
            print("round gauge 844 1x: \(name) disc to unit \(unit[i]); to gear row \(gear[i]); to ticks \(ticks[i])")
            #expect(unit[i].value >= 8, "\(name) disc to unit \(unit[i])")
            #expect(gear[i].value >= 8, "\(name) disc to gear row \(gear[i])")
            #expect(ticks[i].value >= 6, "\(name) disc to ticks \(ticks[i])")
        }
        print("round gauge 844 1x: disc to disc \(disc)")
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
