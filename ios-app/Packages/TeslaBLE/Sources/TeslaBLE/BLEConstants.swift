import CryptoKit
import Foundation

/// Tesla vehicle BLE GATT identifiers and helpers
/// (teslamotors/vehicle-command pkg/connector/ble). Kept as strings so this
/// package stays free of CoreBluetooth; the app wraps them in `CBUUID`.
public enum TeslaBLEConstants {
    /// GATT service the vehicle exposes.
    public static let serviceUUID = "00000211-b2d1-43f0-9b88-960cebf8b91e"

    /// Characteristic the client writes requests to (to vehicle).
    public static let txCharacteristicUUID = "00000212-b2d1-43f0-9b88-960cebf8b91e"

    /// Characteristic the client subscribes to for responses (from vehicle).
    public static let rxCharacteristicUUID = "00000213-b2d1-43f0-9b88-960cebf8b91e"

    /// Max single message length the vehicle accepts/returns.
    public static let maxMessageLength = 1024

    /// The BLE advertised local name for a given VIN:
    /// `"S" + hex(SHA1(vin)[:8]) + "C"` (16 hex chars between S and C).
    public static func localName(forVIN vin: String) -> String {
        let digest = Insecure.SHA1.hash(data: Data(vin.utf8))
        return "S" + Data(digest.prefix(8)).hexString + "C"
    }
}

extension Data {
    /// Lower-case hex encoding, two characters per byte.
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
