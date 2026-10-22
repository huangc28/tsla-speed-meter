/// Anti-replay check for response counters: rejects a counter already seen
/// for the same request, tolerating out-of-order delivery within 32 values.
///
/// Adapted from teslamotors/vehicle-command (Apache-2.0)
/// internal/authentication/window.go (`updateSlidingWindow`, `SlidingWindow`).
/// protocol.md "Counter verification": clients that skip this check are
/// vulnerable to replayed responses.
public struct SlidingWindow: Sendable, Equatable {
    static let windowSize: UInt32 = 32

    private(set) var history: UInt64 = 0
    private(set) var counter: UInt32 = 0
    private var used = false

    public init() {}

    /// A window that has already accepted `counter` (for tests).
    init(counter: UInt32, history: UInt64) {
        self.counter = counter
        self.history = history
        used = true
    }

    /// Records `newCounter`; returns false if it was seen before (or is too
    /// old to tell), leaving the window unchanged.
    public mutating func update(_ newCounter: UInt32) -> Bool {
        guard used else {
            used = true
            counter = newCounter
            return true
        }
        if newCounter == counter {
            return false
        }
        if newCounter < counter {
            let age = counter - newCounter
            if age > Self.windowSize {
                return false
            }
            if (history >> UInt64(age - 1)) & 1 == 1 {
                return false
            }
            history |= 1 << UInt64(age - 1)
            return true
        }
        let shift = UInt64(newCounter - counter)
        counter = newCounter
        // Smart shifts yield 0 for shift >= 64, matching Go.
        history <<= shift
        history |= 1 << (shift - 1)
        return true
    }
}
