@preconcurrency import CoreBluetooth
import Foundation
import TeslaBLE

/// `BLELink` over CoreBluetooth, on the main queue.
///
/// Connect follows vehicle-command pkg/connector/ble/ble.go
/// `tryToConnect`: find the advertisement whose local name matches, refuse
/// a non-connectable one, connect, discover the Tesla service and its TX/RX
/// characteristics, subscribe to RX. Writes are with response, one at a
/// time, each at most `min(ATT MTU - 3, 1021)` bytes: vehicle-command uses
/// `min(MTU, 1024) - 3`, and `maximumWriteValueLength(for: .withoutResponse)`
/// is iOS's MTU - 3 (the `.withResponse` value is the 512-byte long-write
/// limit, not the MTU).
///
/// Reconnects: the connection is made with
/// `CBConnectPeripheralOptionEnableAutoReconnect`, so after a drop the
/// system reconnects on its own (`.disconnected(reconnecting: true)`, then
/// `.reconnected` once RX is subscribed again). A later `connect` tries the
/// last vehicle by identifier before scanning. The central uses a restore
/// identifier; a restored connected peripheral is re-subscribed and
/// reported as `.reconnected`.
@MainActor
final class CoreBluetoothLink: NSObject, BLELink {
    static let restoreIdentifier = "com.tslaspeedmeter.hud.tesla-ble"
    static let writeTimeout: Duration = .seconds(5)

    nonisolated let events: AsyncStream<BLELinkEvent>
    private nonisolated let sink: AsyncStream<BLELinkEvent>.Continuation

    private let serviceUUID = CBUUID(string: TeslaBLEConstants.serviceUUID)
    private let txUUID = CBUUID(string: TeslaBLEConstants.txCharacteristicUUID)
    private let rxUUID = CBUUID(string: TeslaBLEConstants.rxCharacteristicUUID)

    /// Created on the first `connect`, so the Bluetooth prompt appears only
    /// when the app first talks to a car.
    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var tx: CBCharacteristic?
    private var localName: String?
    /// The last vehicle connected, so a reconnect can skip the scan.
    private var knownPeripheralID: UUID?
    /// RX is subscribed and writes may go out.
    private var isReady = false

    private var connectContinuation: CheckedContinuation<Int, any Error>?
    private var connectTimeoutTask: Task<Void, Never>?
    private var writeContinuation: CheckedContinuation<Void, any Error>?
    private var writeTimeoutTask: Task<Void, Never>?

    override init() {
        (events, sink) = AsyncStream.makeStream(of: BLELinkEvent.self)
        super.init()
    }

    // MARK: BLELink

    func connect(localName: String, timeout: Duration) async throws -> Int {
        guard connectContinuation == nil else { throw BLELinkError.busy }
        return try await withCheckedThrowingContinuation { continuation in
            connectContinuation = continuation
            self.localName = localName
            connectTimeoutTask = Task { [weak self] in
                try? await Task.sleep(for: timeout)
                guard !Task.isCancelled else { return }
                self?.connectTimedOut()
            }
            if let central {
                startConnecting(central)
            } else {
                // Continues in centralManagerDidUpdateState.
                central = CBCentralManager(
                    delegate: self,
                    queue: .main,
                    options: [CBCentralManagerOptionRestoreIdentifierKey: Self.restoreIdentifier]
                )
            }
        }
    }

    func write(_ value: Data) async throws {
        guard isReady, let peripheral, let tx, peripheral.state == .connected else { throw BLELinkError.notConnected }
        guard writeContinuation == nil else { throw BLELinkError.busy }
        try await withCheckedThrowingContinuation { continuation in
            writeContinuation = continuation
            writeTimeoutTask = Task { [weak self] in
                try? await Task.sleep(for: Self.writeTimeout)
                guard !Task.isCancelled else { return }
                self?.finishWrite(.failure(.writeTimedOut))
            }
            peripheral.writeValue(value, for: tx, type: .withResponse)
        }
    }

    func disconnect() async {
        central?.stopScan()
        let current = peripheral
        // Cleared first so the delegate ignores the disconnect it causes.
        tearDown()
        finishConnect(.failure(.notConnected))
        if let current { central?.cancelPeripheralConnection(current) }
    }

    // MARK: Connecting

    private func startConnecting(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            break
        case .unknown, .resetting:
            return
        default:
            finishConnect(.failure(.bluetoothUnavailable(Self.describe(central.state))))
            return
        }
        if let id = knownPeripheralID, let known = central.retrievePeripherals(withIdentifiers: [id]).first {
            connect(known, central: central)
        } else {
            // vehicle-command scans by local name, not by service.
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }

    private func connect(_ peripheral: CBPeripheral, central: CBCentralManager) {
        self.peripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: [CBConnectPeripheralOptionEnableAutoReconnect: true])
    }

    private func connectTimedOut() {
        guard connectContinuation != nil else { return }
        let wasScanning = central?.isScanning ?? false
        // The identifier may be stale; scan next time.
        knownPeripheralID = nil
        finishConnect(.failure(wasScanning ? .scanTimedOut : .connectTimedOut))
    }

    private func ready(_ peripheral: CBPeripheral) {
        knownPeripheralID = peripheral.identifier
        isReady = true
        let length = min(peripheral.maximumWriteValueLength(for: .withoutResponse), TeslaBLEConstants.maxMessageLength - 3)
        if connectContinuation != nil {
            finishConnect(.success(length))
        } else {
            sink.yield(.reconnected(maxWriteLength: length))
        }
    }

    private func finishConnect(_ result: Result<Int, BLELinkError>) {
        connectTimeoutTask?.cancel()
        connectTimeoutTask = nil
        guard let continuation = connectContinuation else { return }
        connectContinuation = nil
        if case .failure = result {
            central?.stopScan()
            if let peripheral, !isReady {
                self.peripheral = nil
                central?.cancelPeripheralConnection(peripheral)
            }
        }
        continuation.resume(with: result)
    }

    private func finishWrite(_ result: Result<Void, BLELinkError>) {
        writeTimeoutTask?.cancel()
        writeTimeoutTask = nil
        guard let continuation = writeContinuation else { return }
        writeContinuation = nil
        continuation.resume(with: result)
    }

    private func tearDown() {
        isReady = false
        tx = nil
        peripheral = nil
        finishWrite(.failure(.notConnected))
    }

    private static func describe(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOff: "poweredOff"
        case .unauthorized: "unauthorized"
        case .unsupported: "unsupported"
        case .resetting: "resetting"
        case .poweredOn: "poweredOn"
        default: "unknown"
        }
    }
}

extension CoreBluetoothLink: @MainActor CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if connectContinuation != nil {
            startConnecting(central)
        } else if central.state == .poweredOn, let peripheral, peripheral.state == .connected, !isReady {
            // Restored while connected: subscribe again.
            peripheral.discoverServices([serviceUUID])
        } else if central.state != .poweredOn, peripheral != nil {
            tearDown()
            sink.yield(.disconnected(reconnecting: false, reason: "Bluetooth \(Self.describe(central.state))"))
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        guard let restored = (dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral])?.first else { return }
        peripheral = restored
        restored.delegate = self
        knownPeripheralID = restored.identifier
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
        guard let localName, name == localName, connectContinuation != nil else { return }
        central.stopScan()
        if let connectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool, !connectable {
            finishConnect(.failure(.notConnectable))
            return
        }
        connect(peripheral, central: central)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard peripheral == self.peripheral else { return }
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        guard peripheral == self.peripheral else { return }
        finishConnect(.failure(.connectFailed(error?.localizedDescription ?? "failed to connect")))
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: (any Error)?
    ) {
        guard peripheral == self.peripheral else { return }
        let reason = error?.localizedDescription
        if connectContinuation != nil {
            finishConnect(.failure(.connectFailed(reason ?? "disconnected")))
            return
        }
        isReady = false
        tx = nil
        finishWrite(.failure(.notConnected))
        if !isReconnecting { self.peripheral = nil }
        sink.yield(.disconnected(reconnecting: isReconnecting, reason: reason))
    }
}

extension CoreBluetoothLink: @MainActor CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }), error == nil else {
            failSetup(.serviceNotFound)
            return
        }
        peripheral.discoverCharacteristics([txUUID, rxUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        let characteristics = service.characteristics ?? []
        guard error == nil,
              let tx = characteristics.first(where: { $0.uuid == txUUID }),
              let rx = characteristics.first(where: { $0.uuid == rxUUID })
        else {
            failSetup(.serviceNotFound)
            return
        }
        self.tx = tx
        peripheral.setNotifyValue(true, for: rx)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard characteristic.uuid == rxUUID else { return }
        if let error {
            failSetup(.connectFailed(error.localizedDescription))
        } else if characteristic.isNotifying {
            ready(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard characteristic.uuid == rxUUID, error == nil, let value = characteristic.value else { return }
        sink.yield(.received(value))
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard characteristic.uuid == txUUID else { return }
        finishWrite(error.map { .failure(.writeFailed($0.localizedDescription)) } ?? .success(()))
    }

    /// Setup failed during `connect`, or while re-subscribing after a reconnect.
    private func failSetup(_ error: BLELinkError) {
        if connectContinuation != nil {
            finishConnect(.failure(error))
        } else if let peripheral {
            tearDown()
            central?.cancelPeripheralConnection(peripheral)
            sink.yield(.disconnected(reconnecting: false, reason: "\(error)"))
        }
    }
}
