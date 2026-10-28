import Foundation

/// One car-status slot (L71, DESIGN.md "Car-status icons"): open draws the solid icon, unknown the
/// dashed outline, closed nothing, so the slot stays empty.
public enum CarPartState: Equatable, Sendable {
    case open
    case closed
    case unknown
}

/// The car-status icons inside the ring (L87): the front trunk, the rear trunk and the doors, each
/// judged on its own, so 「後車廂開著」 and 「車門狀態未知」 can show together.
public struct CarStatus: Equatable, Sendable {
    /// A closures value older than this is unknown (07 §4 A5: two 10 s polls missed).
    public static let maxAge: TimeInterval = 30

    public var frontTrunk: CarPartState
    public var rearTrunk: CarPartState
    /// Open when any door is open; unknown when none is open and any is unknown.
    public var door: CarPartState

    /// Connected, but no closures reply yet.
    public static let unknown = CarStatus(frontTrunk: .unknown, rearTrunk: .unknown, door: .unknown)

    public init(frontTrunk: CarPartState, rearTrunk: CarPartState, door: CarPartState) {
        self.frontTrunk = frontTrunk
        self.rearTrunk = rearTrunk
        self.door = door
    }

    /// The last closures reply, `age` seconds old: past `maxAge` every slot is unknown, and a value
    /// the car did not send is unknown, never closed.
    init(_ closures: CarClosures, age: TimeInterval) {
        guard age <= Self.maxAge else {
            self = .unknown
            return
        }
        func part(_ open: Bool?) -> CarPartState {
            open.map { $0 ? .open : .closed } ?? .unknown
        }
        frontTrunk = part(closures.frontTrunk)
        rearTrunk = part(closures.rearTrunk)
        if closures.doors.contains(true) {
            door = .open
        } else if closures.doors.isEmpty || closures.doors.contains(nil) {
            door = .unknown
        } else {
            door = .closed
        }
    }
}
