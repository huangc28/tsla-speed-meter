import CoreGraphics
import Testing
@testable import HUDCore

/// The Centred Numeral Rule (`numT(v, "hk")`): one fixed 57.8 cell per digit, the group centred on the ring.
struct NumeralLayoutTests {
    private func close(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 1e-9 }

    // The page's `xs(B.m8.adv)`: cell centres at 422 + (i − (n − 1) / 2) · 57.792, each glyph centred by its advance.
    @Test func cellsAreCentredOnTheRing() throws {
        let cell = 0.56 * 103.2
        let one = try #require(NumeralLayout(digits: "8"))
        #expect(close(one.digitOrigins[0], 422 - cell / 2))
        let two = try #require(NumeralLayout(digits: "86"))
        #expect(close(two.digitOrigins[0], 422 - cell) && close(two.digitOrigins[1], 422))
        let three = try #require(NumeralLayout(digits: "147"))
        #expect(close(three.digitOrigins[0], 422 - 1.5 * cell) && close(three.digitOrigins[2], 422 + 0.5 * cell))
        // The tightest disc case at 1x: the third digit's pen at 450.896.
        #expect(abs(three.digitOrigins[2] - 450.896) < 1e-9)
    }

    @Test func oneBaselineForEveryNumber() throws {
        for digits in ["0", "7", "72", "147", "250"] {
            #expect(close(try #require(NumeralLayout(digits: digits)).baselineY, RoundGauge.Numeral.baselineY))
        }
    }

    @Test func onlyDigitsHaveALayout() {
        #expect(NumeralLayout(digits: "—") == nil)
        #expect(NumeralLayout(digits: "") == nil)
        #expect(NumeralLayout(digits: "-3") == nil)
        #expect(NumeralLayout(digits: "١٢") == nil)
    }

    // Within one digit count no digit moves; the group re-centres only at 10 and at 100.
    @Test func digitsMoveOnlyWithTheDigitCount() throws {
        for speed in 0..<250 {
            let a = try #require(NumeralLayout(digits: String(speed))), b = try #require(NumeralLayout(digits: String(speed + 1)))
            if String(speed).count == String(speed + 1).count {
                #expect(a == b, "\(speed)→\(speed + 1)")
            } else {
                #expect(a != b && [9, 99].contains(speed))
            }
        }
    }
}
