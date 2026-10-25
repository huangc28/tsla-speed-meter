import Testing
import TeslaBLE

/// The 9th-character check, computed here from a hand-written table so the
/// test does not reuse the code it checks (49 CFR 565.15, ISO 3779).
private enum HandCheckDigit {
    static let values: [Character: Int] = [
        "0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
        "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6, "G": 7, "H": 8,
        "J": 1, "K": 2, "L": 3, "M": 4, "N": 5, "P": 7, "R": 9,
        "S": 2, "T": 3, "U": 4, "V": 5, "W": 6, "X": 7, "Y": 8, "Z": 9,
    ]
    static let weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2]

    /// `pattern` with its 9th character (any placeholder) replaced by the check digit.
    static func complete(_ pattern: String) -> String {
        let characters = Array(pattern)
        // The 9th position weighs 0, so its placeholder never counts.
        let sum = zip(characters, weights).enumerated().reduce(0) { total, item in
            item.offset == 8 ? total : total + values[item.element.0]! * item.element.1
        }
        var completed = characters
        completed[8] = sum % 11 == 10 ? "X" : Character(String(sum % 11))
        return String(completed)
    }
}

@Suite("VIN rules")
struct VINTests {
    // MARK: Check digit

    @Test("the 49 CFR 565 / ISO 3779 worked example passes with check digit X")
    func worked() {
        #expect(VIN.checkDigit(for: "1M8GDM9AXKP042788") == "X")
        #expect(VIN.hasValidCheckDigit("1M8GDM9AXKP042788"))
    }

    // Real Tesla VINs from public sale listings and records (found 2026-10-25). Shanghai
    // (LRW) and Berlin (XP7) cars carry a valid check digit too, like Fremont and Austin.
    @Test(arguments: [
        // Shanghai: https://carsbat.com/de/detail/lrw3e7ek8nc515025-fejzij/
        "LRW3E7EK8NC515025",
        // Shanghai: https://fastcarcheck.uk/vin-check/LRW3F7EL7PC822212
        "LRW3F7EL7PC822212",
        // Fremont: https://northscottsdale.porsche.com/en/inventory/other-brands/tesla-model-3-preowned-1WELPV
        "5YJ3E1EA2SF935028",
        // Fremont: https://www.myfloridalegal.com/resale_vehicle/5YJ3E1EA0MF921986
        "5YJ3E1EA0MF921986",
        // Austin: https://grapevine.porsche.com/en/inventory/other-brands/tesla-model-y-preowned-4NWNML
        "7SAYGDEE3PA065575",
        // Austin: https://minneapolis.porsche.com/en/inventory/other-brands/tesla-model-y-preowned-0M9466
        "7SAYGDEE7PA084467",
        // Berlin, check digit X: https://carsbat.com/de/detail/xp7ygcekxpb215373-m1mhc9/
        "XP7YGCEKXPB215373",
        // Berlin: https://carsbat.com/de/detail/xp7ygcek9pb099227-0la2ca/
        "XP7YGCEK9PB099227",
        // 2026 cars, T in position 10.
        // Shanghai: https://fastcarcheck.uk/vin-check/LRW3F7FS7TC863620
        "LRW3F7FS7TC863620",
        // Austin: https://forcar.org/vin-check/7SAYGDEE6TF402611/
        "7SAYGDEE6TF402611",
        // Berlin, also an H: https://fastcarcheck.uk/vin-check/XP7YHCER6TB904184
        "XP7YHCER6TB904184",
    ])
    func realTeslaVINsPass(_ vin: String) {
        #expect(VIN.checkDigit(for: vin) == Array(vin)[8])
        #expect(VIN.hasValidCheckDigit(vin), "\(vin)")
        #expect(HandCheckDigit.complete(vin) == vin)
    }

    // Synthetic VINs (not real cars) for letters the real ones miss: U, V in position 10
    // (model year 2027) and Z. Their 9th character comes from the table above.
    @Test(arguments: ["5YJ3E1EU_VF000001", "LRWYGCEZ_VC000002", "XP7YUZEK_VB000003"])
    func syntheticLettersPass(_ pattern: String) {
        let vin = HandCheckDigit.complete(pattern)
        #expect(VIN.checkDigit(for: vin) == Array(vin)[8])
        #expect(VIN.hasValidCheckDigit(vin), "\(vin)")
    }

    @Test("a wrong 9th character fails; so does anything that is not 17 VIN characters")
    func failures() {
        #expect(!VIN.hasValidCheckDigit("1M8GDM9A1KP042788"))
        #expect(!VIN.hasValidCheckDigit("1M8GDM9AXKP04278"))
        #expect(!VIN.hasValidCheckDigit("1M8GDM9AXKP0427880"))
        #expect(!VIN.hasValidCheckDigit("1M8GDM9AXKPO42788"))
        #expect(VIN.checkDigit(for: "1M8GDM9AXKPQ42788") == nil)
    }

    // MARK: Look-alikes and candidates

    @Test("look-alikes: O → 0 and I → 1 always, Q → 0 only for camera reads")
    func lookAlikes() {
        #expect(VIN.fixingLookAlikes("OIQ", includingQ: true) == "010")
        #expect(VIN.fixingLookAlikes("OIQ", includingQ: false) == "01Q")
    }

    @Test("candidates in noisy recognized text: upper-cased, O/I/Q fixed, exactly 17 VIN characters")
    func candidates() {
        let vin = HandCheckDigit.complete("5YJ3E1EA_KF000001")
        let misread = vin.lowercased()
            .replacingOccurrences(of: "000", with: "0oq")
            .replacingOccurrences(of: "1", with: "I")
        let text = "Software v12\nVIN: \(misread)\n5YJ3E1EA0KF00000 1234567890ABCDEFGH"
        #expect(VIN.candidates(in: text) == [vin])
    }

    @Test func candidatesKeepTheOrderOfTheText() {
        #expect(VIN.candidates(in: "1M8GDM9AXKP042788 / 1M8GDM9A1KP042788") == ["1M8GDM9AXKP042788", "1M8GDM9A1KP042788"])
        #expect(VIN.candidates(in: "nothing here").isEmpty)
    }

    // MARK: Agreement over reads

    @Test("a read is accepted after 3 identical reads in a row")
    func agreement() {
        var agreement = VINReadAgreement()
        #expect(agreement.add("1M8GDM9AXKP042788") == nil)
        #expect(agreement.add("1M8GDM9AXKP042788") == nil)
        #expect(agreement.add("1M8GDM9AXKP042788") == "1M8GDM9AXKP042788")
    }

    @Test("a different read or a frame with no VIN starts the count again")
    func agreementResets() {
        var agreement = VINReadAgreement()
        _ = agreement.add("1M8GDM9AXKP042788")
        _ = agreement.add("1M8GDM9AXKP042788")
        #expect(agreement.add("1M8GDM9A1KP042788") == nil)
        #expect(agreement.add("1M8GDM9A1KP042788") == nil)
        #expect(agreement.add(nil) == nil)
        #expect(agreement.add("1M8GDM9A1KP042788") == nil)
        #expect(agreement.add("1M8GDM9A1KP042788") == nil)
        #expect(agreement.add("1M8GDM9A1KP042788") == "1M8GDM9A1KP042788")
    }

    // MARK: Manual entry (S14, L63)

    @Test("typing: upper-cased, O → 0 and I → 1, grouped 3 · 6 · 8, counted")
    func typing() {
        let entry = VINEntry("5yj3e1eaoki")
        #expect(entry.characters == "5YJ3E1EA0K1")
        #expect(entry.groups == ["5YJ", "3E1EA0", "K1"])
        #expect(entry.formatted == "5YJ 3E1EA0 K1")
        #expect(entry.count == 11)
        #expect(entry.problem == nil)
        #expect(!entry.isComplete)
    }

    @Test("an empty field has no groups, no count and no message")
    func empty() {
        let entry = VINEntry("")
        #expect(entry.groups.isEmpty)
        #expect(entry.formatted.isEmpty)
        #expect(entry.count == 0)
        #expect(entry.problem == nil)
    }

    @Test("Q is not converted while typing: it is the character error")
    func typedQ() {
        let entry = VINEntry("5YJ3Q")
        #expect(entry.characters == "5YJ3Q")
        #expect(entry.problem == .invalidCharacter)
        #expect(!entry.isComplete)
        #expect(!VINEntry("5YJ3E1EA0KF00000Q").isComplete)
    }

    @Test("a paste goes through the same rules, dropping spaces and dashes")
    func paste() {
        let vin = HandCheckDigit.complete("5YJ3E1EA_KF000001")
        let wmi = String(vin.prefix(3)), vds = String(vin.dropFirst(3).prefix(6)), vis = String(vin.suffix(8))
        let entry = VINEntry(" \(wmi)-\(vds) \(vis.lowercased())\n")
        #expect(entry.characters == vin)
        #expect(entry.groups == [wmi, vds, vis])
        #expect(entry.count == 17)
        #expect(entry.problem == nil)
        #expect(entry.isComplete)
        #expect(entry.vin == vin)
    }

    @Test("reformatting its own output changes nothing")
    func idempotent() {
        let entry = VINEntry("5YJ3E1EA0KF00")
        #expect(VINEntry(entry.formatted) == entry)
    }

    @Test("17 characters with a wrong check digit: a warning, still complete")
    func checkDigitWarning() {
        let entry = VINEntry("1M8GDM9A1KP042788")
        #expect(entry.problem == .checkDigit)
        #expect(entry.isComplete)
        #expect(entry.vin == "1M8GDM9A1KP042788")
    }

    @Test("a pasted VIN with a label around it: the one VIN in it is taken")
    func pasteWithLabel() {
        #expect(VINEntry("VIN: 5YJ3E1EA2SF935028").characters == "5YJ3E1EA2SF935028")
        #expect(VINEntry("車身號碼 LRW3F7FS7TC863620。").characters == "LRW3F7FS7TC863620")
        // Two VINs in it, or none: it stays as pasted, with the length error.
        #expect(VINEntry("5YJ3E1EA2SF935028 5YJ3E1EA0MF921986").problem == .wrongLength)
        #expect(VINEntry("VIN 5YJ3E1EA2SF93502").problem == .wrongLength)
        // A Q is never turned into 0 on the way.
        #expect(VINEntry("VIN: 5YJ3E1EA2SF93502Q").problem == .invalidCharacter)
    }

    @Test("more than 17 characters is the length error")
    func tooLong() {
        let entry = VINEntry("1M8GDM9AXKP0427881")
        #expect(entry.count == 18)
        #expect(entry.problem == .wrongLength)
        #expect(!entry.isComplete)
        #expect(entry.vin == nil)
    }
}
