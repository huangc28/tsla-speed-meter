import Foundation

/// VIN rules for pairing (L63): the alphabet, look-alike fixes, the 9th-character
/// check digit and candidates in recognized text. Pure: no camera, no UI, no I/O.
/// The car's Bluetooth name comes from `TeslaBLEConstants.localName(forVIN:)`.
///
/// A failed check digit is a warning, never a block: the digit is not required
/// in every market, and the nearby match is the proof.
public enum VIN {
    public static let length = 17

    /// Digits and capitals, without I, O and Q.
    public static func isAllowed(_ character: Character) -> Bool {
        guard character.isASCII, let value = character.asciiValue else { return false }
        switch value {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): return true
        case UInt8(ascii: "A")...UInt8(ascii: "Z"): return !"IOQ".contains(character)
        default: return false
        }
    }

    /// O → 0 and I → 1; with `includingQ`, Q → 0 too (camera reads; a typed Q
    /// stays, so the field can say VINs have none).
    public static func fixingLookAlikes(_ text: String, includingQ: Bool) -> String {
        String(text.map { character -> Character in
            switch character {
            case "O": "0"
            case "I": "1"
            case "Q" where includingQ: "0"
            default: character
            }
        })
    }

    /// The 9th character `vin` should have (49 CFR 565.15, ISO 3779): letters
    /// as numbers, weighted, sum mod 11, 10 written X. Nil unless `vin` is 17
    /// allowed characters.
    public static func checkDigit(for vin: String) -> Character? {
        let characters = Array(vin)
        guard characters.count == length, characters.allSatisfy(isAllowed) else { return nil }
        let sum = zip(characters, weights).reduce(0) { $0 + value(of: $1.0) * $1.1 }
        let remainder = sum % 11
        return remainder == 10 ? "X" : Character(String(remainder))
    }

    public static func hasValidCheckDigit(_ vin: String) -> Bool {
        guard let expected = checkDigit(for: vin) else { return false }
        return Array(vin)[8] == expected
    }

    /// The VINs in one piece of recognized text, in order: upper-cased, O/I/Q
    /// fixed, then every run of exactly 17 VIN characters.
    public static func candidates(in text: String) -> [String] {
        let fixed = fixingLookAlikes(text.uppercased(), includingQ: true)
        return fixed.split { !isAllowed($0) }.filter { $0.count == length }.map(String.init)
    }

    private static let weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2]

    /// A-H 1-8, J-N 1-5, P 7, R 9, S-Z 2-9; digits as themselves.
    private static func value(of character: Character) -> Int {
        if let digit = character.wholeNumberValue { return digit }
        for (letters, first) in [("ABCDEFGH", 1), ("JKLMN", 1), ("P", 7), ("R", 9), ("STUVWXYZ", 2)] {
            if let index = letters.firstIndex(of: character) {
                return first + letters.distance(from: letters.startIndex, to: index)
            }
        }
        return 0
    }
}

/// Agreement over consecutive camera reads: a VIN is accepted only after the
/// same one was read `required` frames in a row, so a half-read number is
/// never taken.
public struct VINReadAgreement: Sendable {
    public let required: Int
    private var last: String?
    private var streak = 0

    public init(required: Int = 3) {
        self.required = required
    }

    /// One frame's read, nil when the frame had no VIN (that ends the run too).
    /// Returns the VIN once it has been read `required` times in a row.
    public mutating func add(_ read: String?) -> String? {
        guard let read else {
            last = nil
            streak = 0
            return nil
        }
        streak = read == last ? streak + 1 : 1
        last = read
        return streak >= required ? read : nil
    }
}

/// The typed VIN on S14 (L63): upper-cased, O → 0 and I → 1, grouped
/// 3 · 6 · 8 (WMI, VDS with the check digit, VIS) and counted. Anything but
/// letters and digits (spaces, dashes from a paste) is dropped. A Q is kept,
/// so the field can say VINs have none.
public struct VINEntry: Equatable, Sendable {
    public enum Problem: Equatable, Sendable {
        /// A character no VIN has (Q): 「VIN 不會有 I、O、Q」.
        case invalidCharacter
        /// More than 17 characters.
        case wrongLength
        /// 17 VIN characters whose 9th does not check out: a warning only.
        case checkDigit
    }

    /// The characters kept, without grouping.
    public let characters: String

    public init(_ typed: String) {
        let kept = typed.uppercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
        characters = VIN.fixingLookAlikes(kept, includingQ: false)
    }

    public var count: Int { characters.count }

    /// Up to three groups of 3, 6 and 8 (the last takes any extra), empty
    /// ones left out.
    public var groups: [String] {
        let all = Array(characters)
        let bounds = [0, 3, 9, max(all.count, 9)]
        return zip(bounds, bounds.dropFirst()).compactMap { start, end in
            let slice = all[min(start, all.count)..<min(end, all.count)]
            return slice.isEmpty ? nil : String(slice)
        }
    }

    /// The groups with a space between them, for the field.
    public var formatted: String { groups.joined(separator: " ") }

    public var problem: Problem? {
        if !characters.allSatisfy(VIN.isAllowed) { return .invalidCharacter }
        if count > VIN.length { return .wrongLength }
        if count == VIN.length, !VIN.hasValidCheckDigit(characters) { return .checkDigit }
        return nil
    }

    /// 17 VIN characters, whether or not the check digit agrees.
    public var isComplete: Bool {
        count == VIN.length && characters.allSatisfy(VIN.isAllowed)
    }

    /// The VIN to pair with, once complete.
    public var vin: String? { isComplete ? characters : nil }
}
