import CoreGraphics
import Testing
@testable import HUDCore

/// L88: the speed numeral in fixed cells, as the master's `NUM15` / `num15` lays it out.
struct NumeralLayoutTests {
    private func close(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 1e-9 }

    @Test func oneSizeForEveryDigitCount() throws {
        for digits in ["7", "72", "147"] {
            #expect(try #require(NumeralLayout(digits: digits, gaugeSize: 300)).fontSize == 160)
            #expect(try #require(NumeralLayout(digits: digits, gaugeSize: 280)).fontSize == 149)
        }
    }

    // The master at S = 300: g0 = 150 − 3·73.6/2 − 37·0.16, with a leading 1, the middle 1 of 11x and a final 2.
    @Test func matchesTheMasterFor112() throws {
        let layout = try #require(NumeralLayout(digits: "112", gaugeSize: 300))
        let g0: CGFloat = 150 - 3 * 73.6 / 2 - 37 * 0.16
        #expect(layout.digitOrigins.count == 3)
        #expect(close(layout.digitOrigins[0], g0 + 36.8 - 240.5 * 0.16 + 60 * 0.16))
        #expect(close(layout.digitOrigins[1], g0 + 73.6 + 36.8 - 240.5 * 0.16 + 30 * 0.16))
        #expect(close(layout.digitOrigins[2], g0 + 147.2 + 36.8 - 243.5 * 0.16))
        #expect(abs(layout.digitOrigins[0] - 41.6) < 1e-6 && abs(layout.digitOrigins[2] - 178.72) < 1e-6)
        #expect(close(layout.baselineY, 149 + 350 * 0.16))
    }

    @Test func baselineAt280() throws {
        let layout = try #require(NumeralLayout(digits: "88", gaugeSize: 280))
        #expect(abs(layout.baselineY - (139.2 + 350 * 0.149)) < 1e-9)
    }

    @Test func oneDigitIsCenteredOnItsInk() throws {
        let layout = try #require(NumeralLayout(digits: "8", gaugeSize: 300))
        #expect(close(layout.digitOrigins[0], 150 - 240.5 * 0.16))
        // A lone 1 gets no offsets: it sits on its advance center.
        let one = try #require(NumeralLayout(digits: "1", gaugeSize: 300))
        #expect(close(one.digitOrigins[0], 150 - 240.5 * 0.16))
    }

    @Test func onlyDigitsHaveALayout() {
        #expect(NumeralLayout(digits: "—", gaugeSize: 300) == nil)
        #expect(NumeralLayout(digits: "", gaugeSize: 300) == nil)
        #expect(NumeralLayout(digits: "-3", gaugeSize: 300) == nil)
    }

    // Within one digit count, a one-step change never moves the digits that did not change.
    @Test(arguments: [CGFloat(300), 280])
    func unchangedDigitsNeverMove(gaugeSize: CGFloat) throws {
        var checked = 0
        for speed in 0..<240 {
            let a = Array(String(speed)), b = Array(String(speed + 1))
            guard a.count == b.count else { continue }
            let pa = try #require(NumeralLayout(digits: String(a), gaugeSize: gaugeSize))
            let pb = try #require(NumeralLayout(digits: String(b), gaugeSize: gaugeSize))
            #expect(pa.baselineY == pb.baselineY)
            for i in a.indices where a[i] == b[i] {
                #expect(pa.digitOrigins[i] == pb.digitOrigins[i], "\(speed)→\(speed + 1), digit \(i)")
                checked += 1
            }
        }
        #expect(checked > 200)
    }
}
