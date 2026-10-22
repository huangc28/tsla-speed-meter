import Foundation
import Observation
import SwiftUI
import TeslaBLE
import UIKit

/// The test drive logger behind the "行車紀錄(測試)" page: connect, enroll
/// the key, read once, record (one vehicle-data poll at a time, about once a
/// second, with phone GPS speed on the same timeline) and export.
@MainActor
@Observable
final class DriveLogger {
    enum LinkStatus: Equatable {
        case idle, connecting, connected, reconnecting
        case failed(String)
        case disconnected(String)
    }

    static let pollInterval: Duration = .seconds(1)
    static let configuration = TeslaVehicleClient.Configuration(
        connectTimeout: .seconds(30),
        handshakeTimeout: .seconds(10),
        requestTimeout: .seconds(3),
        enrollmentTimeout: .seconds(60),
        enrollmentPollInterval: .seconds(2),
        captureRawFrames: true
    )
    private static let vinKey = "driveLogger.vin"
    private static let recentLimit = 40

    var vin: String {
        didSet { defaults.set(vin, forKey: Self.vinKey) }
    }
    private(set) var linkStatus: LinkStatus = .idle
    /// The action in progress, shown on the page; nil when idle.
    private(set) var busy: String?
    private(set) var enrollment: EnrollmentState?
    private(set) var keyHint: String?
    private(set) var lastError: String?
    private(set) var lastSample: Sample?
    private(set) var latestFix: GPSFix?
    private(set) var gpsStatus = ""
    private(set) var isRecording = false
    private(set) var isStopping = false
    private(set) var recordingStartedAt: Date?
    private(set) var sampleCount = 0
    private(set) var errorCount = 0
    private(set) var lastFolder: URL?
    private(set) var recent: [String] = []
    var shareItems: ShareItems?

    private let client: TeslaVehicleClient
    private let defaults: UserDefaults
    private let logsRoot: URL
    private let gps = GPSRecorder()
    private var session: LogSession?
    private var pollTask: Task<Void, Never>?
    private var eventTask: Task<Void, Never>?

    /// Created once at app launch, so CoreBluetooth state restoration can
    /// reach the central manager (`live()` creates it at once).
    static func live() -> DriveLogger {
        DriveLogger(client: .live(configuration: configuration))
    }

    init(client: TeslaVehicleClient, defaults: UserDefaults = .standard, logsRoot: URL = LogSession.defaultRoot) {
        self.client = client
        self.defaults = defaults
        self.logsRoot = logsRoot
        vin = defaults.string(forKey: Self.vinKey) ?? ""
        lastFolder = Self.latestFolder(in: logsRoot)
        gps.onFix = { [weak self] fix in self?.received(fix) }
        gps.onStatus = { [weak self] status in self?.gpsChanged(status) }
        let events = client.events
        eventTask = Task { [weak self] in
            for await event in events {
                self?.handle(event)
            }
        }
    }

    var normalizedVIN: String {
        vin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var isVINValid: Bool {
        normalizedVIN.count == 17
    }

    var maskedVIN: String { LogFormat.maskedVIN(normalizedVIN) }

    // MARK: Steps

    func connect() async {
        guard isVINValid else {
            lastError = "VIN 要剛好 17 碼。"
            return
        }
        let vin = normalizedVIN
        self.vin = vin
        begin("連線中…")
        defer { busy = nil }
        linkStatus = .connecting
        keyHint = nil
        do {
            // A second tap reconnects cleanly instead of waiting out the scan.
            if await client.isConnected { await client.disconnect() }
            try await client.connect(vin: vin)
            linkStatus = .connected
            note("已連上車子 \(maskedVIN)")
        } catch {
            linkStatus = .failed(Self.describe(error))
            lastError = Self.describe(error)
            return
        }
        do {
            try await client.startSessions()
            note("已和車子建立加密連線")
        } catch TeslaClientError.keyNotPaired {
            keyHint = "這支手機還不是車子的鑰匙,請按「加入鑰匙」。"
        } catch {
            lastError = Self.describe(error)
        }
    }

    func enrollKey() async {
        begin("加入鑰匙中…")
        defer { busy = nil }
        enrollment = nil
        keyHint = nil
        do {
            try await client.enrollKey { state in
                Task { @MainActor [weak self] in self?.enrollment = state }
            }
            enrollment = .enrolled
            note("鑰匙已加入")
            try? await client.startSessions()
        } catch TeslaClientError.enrollmentTimedOut {
            enrollment = .timedOut
        } catch TeslaClientError.enrollmentRejected(let reason) {
            enrollment = .rejected(reason)
        } catch {
            enrollment = nil
            lastError = Self.describe(error)
        }
    }

    func readOnce() async {
        begin("讀取中…")
        defer { busy = nil }
        let sample = await takeSample()
        lastSample = sample
        if sample.error != nil { lastError = sample.error.map { "讀取失敗:\($0)" } }
    }

    func startRecording() {
        guard !isRecording else { return }
        lastError = nil
        let session: LogSession
        do {
            session = try LogSession(root: logsRoot, meta: meta())
        } catch {
            lastError = "無法建立紀錄檔:\(error.localizedDescription)"
            return
        }
        self.session = session
        isRecording = true
        recordingStartedAt = session.startedAt
        sampleCount = 0
        errorCount = 0
        UIApplication.shared.isIdleTimerDisabled = true
        session.write(event: ["type": "recording_started", "vin_masked": maskedVIN], phoneTime: Date())
        gps.start()
        note("開始紀錄 \(session.directory.lastPathComponent)")
        pollTask = Task { [weak self] in
            await Poller.run(every: Self.pollInterval) {
                await self?.pollOnce()
            }
        }
    }

    func stopRecording() async {
        guard isRecording, !isStopping else { return }
        isStopping = true
        pollTask?.cancel()
        await pollTask?.value
        pollTask = nil
        gps.stop()
        if let session {
            session.write(event: ["type": "recording_stopped"], phoneTime: Date())
            session.finish()
            lastFolder = session.directory
            note("停止紀錄:\(session.sampleCount) 筆,錯誤 \(session.errorCount) 筆")
        }
        session = nil
        isRecording = false
        isStopping = false
    }

    /// Shares the last recording as one zip, or its files when zipping fails.
    func export() {
        guard let folder = lastFolder ?? Self.latestFolder(in: logsRoot) else {
            lastError = "還沒有紀錄可以匯出。"
            return
        }
        if let zip = Self.zip(folder) {
            shareItems = ShareItems(urls: [zip])
        } else {
            shareItems = ShareItems(urls: LogSession.fileNames.map { folder.appending(path: $0) })
        }
    }

    /// Logged so a gap in the samples can be explained.
    func scenePhaseChanged(_ phase: ScenePhase) {
        let name = switch phase {
        case .active: "active"
        case .inactive: "inactive"
        case .background: "background"
        @unknown default: "unknown"
        }
        session?.write(event: ["type": "app_phase", "phase": name], phoneTime: Date())
        if isRecording, phase == .active { UIApplication.shared.isIdleTimerDisabled = true }
    }

    #if DEBUG
    /// Fills the page with example values for screenshots. Debug builds only.
    func loadDemoState() {
        vin = "5YJ3E1EA0KF123456"
        linkStatus = .connected
        enrollment = .awaitingKeyCardTap
        var data = CarServer_VehicleData()
        data.driveState.speedFloat = -3.5
        data.driveState.shiftState.r = CarServer_Void()
        data.driveState.power = 4
        data.chargeState.batteryLevel = 78
        data.chargeState.batteryRange = 251.4
        data.chargeState.chargingState.disconnected = CarServer_Void()
        data.tirePressureState.tpmsPressureFl = 2.9
        data.tirePressureState.tpmsPressureFr = 2.875
        data.tirePressureState.tpmsPressureRl = 2.925
        data.tirePressureState.tpmsPressureRr = 2.9
        let reading = VehicleReading(vehicleData: data)
        lastSample = Sample(
            phoneTime: Date(),
            monotonicMs: 0,
            response: VehicleDataResponse(reading: reading, isEncrypted: true, roundTripMs: 84, retried: false),
            error: nil,
            gps: GPSFix(timestamp: Date(), speed: 1.4, speedAccuracy: 0.5, horizontalAccuracy: 5)
        )
        appendRecent("\(Self.clock(Date())) handshake_succeeded domain=infotainment duration_ms=212")
        appendRecent("\(Self.clock(Date())) response_received domain=infotainment duration_ms=84 request=getVehicleData")
    }
    #endif

    // MARK: Recording

    private func pollOnce() async {
        let sample = await takeSample()
        // Stopping cancels the request in flight; that is not a sample.
        if Task.isCancelled, sample.error == "\(TeslaClientError.cancelled)" { return }
        guard let session else { return }
        session.write(sample: sample)
        lastSample = sample
        sampleCount = session.sampleCount
        errorCount = session.errorCount
    }

    private func takeSample() async -> Sample {
        let response: VehicleDataResponse?
        let failure: String?
        do {
            response = try await client.fetchVehicleDataResponse()
            failure = nil
        } catch {
            response = nil
            failure = "\(TeslaVehicleClient.clientError(error))"
        }
        return Sample(
            phoneTime: Date(),
            monotonicMs: session?.monotonicMs() ?? 0,
            response: response,
            error: failure,
            gps: latestFix
        )
    }

    private func received(_ fix: GPSFix) {
        latestFix = fix
        session?.write(gps: fix, receivedAt: Date())
    }

    private func gpsChanged(_ status: String) {
        gpsStatus = status
        session?.write(event: ["type": "gps", "status": status], phoneTime: Date())
    }

    private func handle(_ event: TeslaClientEvent) {
        switch event.kind {
        case .frameSent(let bytes):
            session?.write(frame: bytes, sent: true, phoneTime: event.date)
            return
        case .frameReceived(let bytes):
            session?.write(frame: bytes, sent: false, phoneTime: event.date)
            return
        case .disconnected(let reconnecting, let reason):
            linkStatus = reconnecting ? .reconnecting : .disconnected(reason ?? "")
        case .reconnected:
            linkStatus = .connected
        default:
            break
        }
        guard let fields = EventJSON.fields(event.kind) else { return }
        session?.write(event: fields, phoneTime: event.date)
        let detail = fields.filter { $0.key != "type" }.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
        appendRecent("\(Self.clock(event.date)) \(fields["type"] ?? "") \(detail.joined(separator: " "))")
    }

    // MARK: Helpers

    private func begin(_ action: String) {
        busy = action
        lastError = nil
    }

    private func note(_ text: String) {
        appendRecent("\(Self.clock(Date())) \(text)")
        session?.write(event: ["type": "app", "message": text], phoneTime: Date())
    }

    private func appendRecent(_ line: String) {
        recent.append(line)
        if recent.count > Self.recentLimit { recent.removeFirst(recent.count - Self.recentLimit) }
    }

    private func meta() -> [String: Any] {
        let info = Bundle.main.infoDictionary ?? [:]
        return [
            "app_version": info["CFBundleShortVersionString"] as? String ?? "",
            "app_build": info["CFBundleVersion"] as? String ?? "",
            "ios_version": UIDevice.current.systemVersion,
            "device_model": Self.deviceModel(),
            "vin_masked": maskedVIN,
            "time_zone": TimeZone.current.identifier,
            "settings": [
                "poll_interval_ms": LogFormat.ms(Self.pollInterval),
                "connect_timeout_ms": LogFormat.ms(Self.configuration.connectTimeout),
                "handshake_timeout_ms": LogFormat.ms(Self.configuration.handshakeTimeout),
                "request_timeout_ms": LogFormat.ms(Self.configuration.requestTimeout),
                "request_lifetime_s": Self.configuration.requestLifetimeSeconds,
                "capture_raw_frames": Self.configuration.captureRawFrames,
                "gps_accuracy": "bestForNavigation",
                "gps_activity_type": "automotiveNavigation",
                "gps_coordinates_logged": false,
            ] as [String: Any],
        ]
    }

    static func deviceModel() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    static func latestFolder(in root: URL) -> URL? {
        let folders = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        return folders.filter(\.hasDirectoryPath).max { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// A zip of `folder` in the temporary directory, via the file
    /// coordinator's upload form of a directory.
    static func zip(_ folder: URL) -> URL? {
        var result: URL?
        var coordinatorError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: folder, options: .forUploading, error: &coordinatorError) { zipped in
            let target = FileManager.default.temporaryDirectory.appending(path: "drive-log-\(folder.lastPathComponent).zip")
            try? FileManager.default.removeItem(at: target)
            if (try? FileManager.default.copyItem(at: zipped, to: target)) != nil { result = target }
        }
        return result
    }

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    private static func clock(_ date: Date) -> String {
        clockFormatter.string(from: date)
    }

    /// Plain Chinese for the page; the logs keep the raw error.
    static func describe(_ error: any Error) -> String {
        switch TeslaVehicleClient.clientError(error) {
        case .link(.scanTimedOut):
            "找不到車子。請確認車子醒著(開一下車門或踩煞車)、手機藍牙開著,並靠近車子。"
        case .link(.bluetoothUnavailable(let state)):
            "手機藍牙不能用(\(state))。請到「設定」打開藍牙,並允許 Speed HUD 使用藍牙。"
        case .link(.notConnectable):
            "車子已連了太多藍牙裝置,請先關掉其他手機的藍牙再試。"
        case .link(let linkError):
            "藍牙連線失敗(\(linkError))。請再試一次。"
        case .timeout:
            "車子沒有回應(逾時)。車子可能在睡覺:開一下車門或踩煞車再試。"
        case .vehicleUnreachable:
            "車子沒有回應,所以還沒開始加入鑰匙。車子可能在睡覺:開一下車門或踩煞車,再按一次「加入鑰匙」。"
        case .cancelled:
            "已取消。"
        case .keyNotPaired:
            "這支手機還不是車子的鑰匙,請先按「加入鑰匙」。"
        case .notConnected:
            "還沒連線,請先按「連線」。"
        case .disconnected:
            "和車子的連線中斷了,請再按「連線」。"
        case .vehiclePublicKeyMismatch:
            "車子的金鑰和上次不一樣(可能是另一台車,或車子重設過)。"
        case .vehicleFault(let fault):
            "車子回報錯誤:\(fault)"
        case let other:
            "發生錯誤:\(other)"
        }
    }
}

struct ShareItems: Identifiable {
    let id = UUID()
    let urls: [URL]
}
