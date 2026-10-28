import Foundation

/// The 車況 card's rows (#79, the master's `VEHICLE`); a row whose value is nil is not drawn.
public struct VehicleCard: Equatable, Sendable {
    /// Whole km, or miles in mph mode, rounded down like the car's.
    public var odometer: Int?
    /// °C as the car reports them; the app shows them in the system's unit.
    public var outsideCelsius: Double?
    public var insideCelsius: Double?
    public var windows: WindowState?

    public init(odometer: Int?, outsideCelsius: Double?, insideCelsius: Double?, windows: WindowState?) {
        self.odometer = odometer
        self.outsideCelsius = outsideCelsius
        self.insideCelsius = insideCelsius
        self.windows = windows
    }
}

/// The 車窗 row.
public enum WindowState: Equatable, Sendable {
    case allClosed
    /// The open windows, front left, front right, rear left, rear right.
    case open([CarWindow])

    /// Any window open names them; all four closed is 「都關著」; otherwise (a window the car did not send,
    /// none open) nothing is known for sure and the row is not drawn.
    init?(_ windows: [Bool?]) {
        // `CarClosures.windows` is driver front, driver rear, passenger front, passenger rear; the driver
        // sits on the left (left-hand drive).
        let positions: [(index: Int, window: CarWindow)] = [(0, .frontLeft), (2, .frontRight), (1, .rearLeft), (3, .rearRight)]
        let open = positions.filter { windows.indices.contains($0.index) && windows[$0.index] == true }.map(\.window)
        if !open.isEmpty {
            self = .open(open)
        } else if windows.count == 4, !windows.contains(nil) {
            self = .allClosed
        } else {
            return nil
        }
    }
}

public enum CarWindow: Equatable, Sendable {
    case frontLeft, frontRight, rearLeft, rearRight
}
