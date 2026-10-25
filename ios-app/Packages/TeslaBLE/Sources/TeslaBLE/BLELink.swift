import Foundation

/// The GATT link to one vehicle, as `TeslaVehicleClient` needs it. The app
/// implements it with CoreBluetooth; tests use a mock. It moves raw GATT
/// values only: framing, routing and crypto live in `TeslaVehicleClient`.
public protocol BLELink: AnyObject, Sendable {
    /// Notifications from the vehicle's RX characteristic and link changes.
    /// One consumer (the client).
    var events: AsyncStream<BLELinkEvent> { get }

    /// Finds the vehicle advertising `localName`
    /// (`TeslaBLEConstants.localName(forVIN:)`), connects, discovers the
    /// Tesla service and subscribes to RX. Returns the largest value one
    /// `write` may carry. Throws `BLELinkError` and never waits longer than
    /// `timeout`. Emits `.found` when a scan sees `localName`.
    func connect(localName: String, timeout: Duration) async throws -> Int

    /// Writes one value (at most the length `connect` returned) to the TX
    /// characteristic with response, and returns once the vehicle acknowledged
    /// it. Throws `BLELinkError`.
    func write(_ value: Data) async throws

    /// Cancels any scan or connection. Does not emit `.disconnected`.
    func disconnect() async
}

public enum BLELinkEvent: Sendable, Equatable {
    /// One RX notification value (a chunk of a framed message).
    case received(Data)
    /// The link dropped. `reconnecting` is true when the system is already
    /// reconnecting on its own (CoreBluetooth auto-reconnect).
    case disconnected(reconnecting: Bool, reason: String?)
    /// The link is back after an automatic reconnect or state restoration,
    /// subscribed again. Vehicle sessions must be re-established.
    case reconnected(maxWriteLength: Int)
    /// A `connect` scan saw the vehicle advertising `localName` (before it
    /// connects; also when it then turns out not connectable).
    case found(localName: String)
}

public enum BLELinkError: Error, Equatable, Sendable {
    /// Bluetooth is off, unauthorized or unsupported; carries the state.
    case bluetoothUnavailable(String)
    /// No vehicle with the local name was found in time.
    case scanTimedOut
    /// Found, but connecting or service discovery did not finish in time.
    case connectTimedOut
    /// The vehicle advertises as not connectable (vehicle-command: it is
    /// already connected to the maximum number of BLE devices).
    case notConnectable
    case connectFailed(String)
    /// The Tesla service or its TX/RX characteristics are missing.
    case serviceNotFound
    case notConnected
    case writeFailed(String)
    case writeTimedOut
    /// Another connect or write is already in flight.
    case busy
}
