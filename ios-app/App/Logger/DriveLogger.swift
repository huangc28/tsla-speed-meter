import Foundation
import Observation
import SwiftUI
import TeslaBLE
import UIKit

/// The test drive logger behind the "行車紀錄(測試)" page: connect, enroll
/// the key, read once, record (one vehicle-data poll at a time, about once a
/// second, with phone GPS speed on the same timeline) and export.
///
/// Two kinds of log folder:
/// - diagnostics (`Documents/Diagnostics/<time>/`): every event and frame
///   from the first 連線 (or 加入鑰匙 / 讀一次) of this app run on, plus
///   讀一次 rows, so a failed connect or enrollment is never lost;
/// - recordings (`Documents/Logs/<time>/`): one per 開始紀錄 … 停止紀錄.
/// 匯出 shares the current diagnostics and the latest recording in one zip.
@MainActor
@Observable
final class DriveLogger {
    enum LinkStatus: Equatable {
        case idle, connecting, connected, reconnecting
        case failed(String)
        case disconnected(String)
    }

    /// How a finished 加入鑰匙 ended, for the page.
    enum EnrollmentOutcome: Equatable {
        /// The key was already on the car; no card tap was needed.
        case alreadyEnrolled
        case enrolled
        /// Time ran out before the car sensed the key card.
        case timedOutBeforeCard
        /// The card was sensed, but the screen confirmation / Infotainment sync did not finish.
        case timedOutDuringSync
        case rejected(String)
        /// The car did not answer, so enrollment never started.
        case unreachable
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
    /// Live state while 加入鑰匙 runs.
    private(set) var enrollment: EnrollmentState?
    private(set) var enrollmentOutcome: EnrollmentOutcome?
    private(set) var keyHint: String?
    private(set) var lastError: String?
    private(set) var lastSample: Sample?
    private(set) var latestFix: GPSFix?
    private(set) var gpsStatus = ""
    private(set) var isRecording = false
    private(set) var isStopping = false
    private(set) var isAutoReconnecting = false
    private(set) var recordingStartedAt: Date?
    private(set) var sampleCount = 0
    private(set) var errorCount = 0
    private(set) var lastFolder: URL?
    private(set) var diagnosticsFolder: URL?
    private(set) var recent: [String] = []
    var shareItems: ShareItems?

    private let client: TeslaVehicleClient
    private let defaults: UserDefaults
    private let logsRoot: URL
    private let diagnosticsRoot: URL
    private let reconnectInterval: Duration
    private let gps = GPSRecorder()
    private var session: LogSession?
    private var diagnostics: LogSession?
    private var pollTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var eventTask: Task<Void, Never>?
    private var enrollmentAttempt = 0

    /// Created once at app launch, so CoreBluetooth state restoration can
    /// reach the central manager (`live()` creates it at once).
    static func live() -> DriveLogger {
        DriveLogger(client: .live(configuration: configuration))
    }

    init(
        client: TeslaVehicleClient,
        defaults: UserDefaults = .standard,
        logsRoot: URL = LogSession.defaultRoot,
        diagnosticsRoot: URL = LogSession.diagnosticsRoot,
        reconnectInterval: Duration = .seconds(5)
    ) {
        self.client = client
        self.defaults = defaults
        self.logsRoot = logsRoot
        self.diagnosticsRoot = diagnosticsRoot
        self.reconnectInterval = reconnectInterval
        vin = defaults.string(forKey: Self.vinKey) ?? ""
        lastFolder = Self.latestFolder(in: logsRoot)
        diagnosticsFolder = Self.latestFolder(in: diagnosticsRoot)
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

    var canExport: Bool {
        lastFolder != nil || diagnosticsFolder != nil
    }

    // MARK: Steps

    func connect() async {
        guard isVINValid else {
            lastError = "VIN 要剛好 17 碼。"
            return
        }
        let vin = normalizedVIN
        self.vin = vin
        startDiagnostics()
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
        startDiagnostics()
        begin("加入鑰匙中…")
        defer { busy = nil }
        enrollmentAttempt += 1
        let attempt = enrollmentAttempt
        enrollment = nil
        enrollmentOutcome = nil
        keyHint = nil
        let states = StateLog()
        var failure: TeslaClientError?
        do {
            try await client.enrollKey { state in
                states.append(state)
                Task { @MainActor [weak self] in
                    guard let self, self.enrollmentAttempt == attempt, self.enrollmentOutcome == nil else { return }
                    self.enrollment = state
                }
            }
            note("鑰匙已加入")
            try? await client.startSessions()
        } catch {
            failure = TeslaVehicleClient.clientError(error)
        }
        enrollment = nil
        enrollmentOutcome = Self.enrollmentOutcome(states: states.all, error: failure)
        if enrollmentOutcome == nil, let failure { lastError = Self.describe(failure) }
        writeEvent(["type": "app_enrollment_outcome", "outcome": enrollmentOutcome.map { "\($0)" } ?? "error"])
    }

    func readOnce() async {
        startDiagnostics()
        begin("讀取中…")
        defer { busy = nil }
        let sample = await takeSample(timedBy: diagnostics)
        diagnostics?.write(sample: sample)
        lastSample = sample
        if sample.error != nil { lastError = sample.error.map { "讀取失敗:\($0)" } }
    }

    func startRecording() {
        guard !isRecording else { return }
        lastError = nil
        startDiagnostics()
        let session: LogSession
        do {
            session = try LogSession(root: logsRoot, meta: meta(kind: "recording"))
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
        writeEvent(["type": "recording_started", "folder": session.directory.lastPathComponent])
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
        reconnectTask?.cancel()
        reconnectTask = nil
        isAutoReconnecting = false
        pollTask?.cancel()
        await pollTask?.value
        pollTask = nil
        gps.stop()
        if let session {
            writeEvent(["type": "recording_stopped", "folder": session.directory.lastPathComponent])
            session.finish()
            lastFolder = session.directory
            note("停止紀錄:\(session.sampleCount) 筆,錯誤 \(session.errorCount) 筆")
        }
        session = nil
        isRecording = false
        isStopping = false
    }

    /// Shares one zip with this run's diagnostics and the latest recording
    /// (either may be missing), or their files when zipping fails.
    func export() {
        diagnostics?.checkpoint()
        let folders = [("diagnostics", diagnosticsFolder), ("recording", lastFolder)]
            .compactMap { label, folder in folder.map { (label, $0) } }
        guard !folders.isEmpty else {
            lastError = "還沒有紀錄可以匯出。"
            return
        }
        if let zip = Self.zipExport(folders) {
            shareItems = ShareItems(urls: [zip])
        } else {
            shareItems = ShareItems(urls: folders.flatMap { _, folder in
                LogSession.fileNames.map { folder.appending(path: $0) }
            })
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
        writeEvent(["type": "app_phase", "phase": name])
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
        let sample = await takeSample(timedBy: session)
        // Stopping cancels the request in flight; that is not a sample.
        if Task.isCancelled, sample.error == "\(TeslaClientError.cancelled)" { return }
        guard let session else { return }
        session.write(sample: sample)
        lastSample = sample
        sampleCount = session.sampleCount
        errorCount = session.errorCount
    }

    private func takeSample(timedBy log: LogSession?) async -> Sample {
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
            monotonicMs: log?.monotonicMs() ?? 0,
            response: response,
            error: failure,
            gps: latestFix
        )
    }

    /// While recording, a dropped link is retried with the saved VIN every
    /// `reconnectInterval` until it is back or recording stops.
    private func startAutoReconnect() {
        guard isRecording, !isStopping, reconnectTask == nil, isVINValid else { return }
        reconnectTask = Task { [weak self] in
            await self?.autoReconnect()
        }
    }

    private func autoReconnect() async {
        isAutoReconnecting = true
        defer {
            isAutoReconnecting = false
            reconnectTask = nil
        }
        var attempt = 0
        while isRecording, !Task.isCancelled {
            attempt += 1
            writeEvent(["type": "auto_reconnect", "attempt": attempt])
            linkStatus = .connecting
            do {
                try await client.connect(vin: normalizedVIN)
                linkStatus = .connected
                note("自動重新連線成功(第 \(attempt) 次)")
                return
            } catch {
                let failure = TeslaVehicleClient.clientError(error)
                writeEvent(["type": "auto_reconnect_failed", "attempt": attempt, "error": "\(failure)"])
                linkStatus = .failed(Self.describe(failure))
            }
            try? await Task.sleep(for: reconnectInterval)
        }
    }

    private func received(_ fix: GPSFix) {
        latestFix = fix
        session?.write(gps: fix, receivedAt: Date())
    }

    private func gpsChanged(_ status: String) {
        gpsStatus = status
        writeEvent(["type": "gps", "status": status])
    }

    private func handle(_ event: TeslaClientEvent) {
        switch event.kind {
        case .frameSent(let bytes):
            diagnostics?.write(frame: bytes, sent: true, phoneTime: event.date)
            session?.write(frame: bytes, sent: true, phoneTime: event.date)
            return
        case .frameReceived(let bytes):
            diagnostics?.write(frame: bytes, sent: false, phoneTime: event.date)
            session?.write(frame: bytes, sent: false, phoneTime: event.date)
            return
        case .disconnected(let reconnecting, let reason):
            linkStatus = reconnecting ? .reconnecting : .disconnected(reason ?? "")
            if !reconnecting { startAutoReconnect() }
        case .reconnected:
            linkStatus = .connected
        default:
            break
        }
        guard let fields = EventJSON.fields(event.kind) else { return }
        writeEvent(fields, at: event.date)
        let detail = fields.filter { $0.key != "type" }.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
        appendRecent("\(Self.clock(event.date)) \(fields["type"] ?? "") \(detail.joined(separator: " "))")
    }

    // MARK: Helpers

    /// Opens this run's diagnostics folder on the first 連線, 加入鑰匙, 讀一次
    /// or 開始紀錄.
    private func startDiagnostics() {
        guard diagnostics == nil else { return }
        guard let log = try? LogSession(root: diagnosticsRoot, meta: meta(kind: "diagnostics")) else {
            lastError = "無法建立診斷紀錄檔。"
            return
        }
        diagnostics = log
        diagnosticsFolder = log.directory
        log.write(event: ["type": "diagnostics_started", "vin_masked": maskedVIN], phoneTime: Date())
    }

    /// Writes to the diagnostics and, while recording, to the recording.
    private func writeEvent(_ fields: [String: Any], at date: Date = Date()) {
        diagnostics?.write(event: fields, phoneTime: date)
        session?.write(event: fields, phoneTime: date)
    }

    private func begin(_ action: String) {
        busy = action
        lastError = nil
    }

    private func note(_ text: String) {
        appendRecent("\(Self.clock(Date())) \(text)")
        writeEvent(["type": "app", "message": text])
    }

    private func appendRecent(_ line: String) {
        recent.append(line)
        if recent.count > Self.recentLimit { recent.removeFirst(recent.count - Self.recentLimit) }
    }

    private func meta(kind: String) -> [String: Any] {
        let info = Bundle.main.infoDictionary ?? [:]
        return [
            "kind": kind,
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
                "request_timeout_starts": "after the write completes",
                "request_lifetime_s": Self.configuration.requestLifetimeSeconds,
                "reconnect_interval_ms": LogFormat.ms(reconnectInterval),
                "capture_raw_frames": Self.configuration.captureRawFrames,
                "unencrypted_reply_payloads_saved": false,
                "gps_accuracy": "bestForNavigation",
                "gps_activity_type": "automotiveNavigation",
                "gps_coordinates_logged": false,
            ] as [String: Any],
        ]
    }

    /// What the page says after 加入鑰匙, from the states the client reported
    /// and how it ended (nil error = success). Nil for errors shown as
    /// plain error text instead.
    static func enrollmentOutcome(states: [EnrollmentState], error: TeslaClientError?) -> EnrollmentOutcome? {
        let sawCardPrompt = states.contains(.awaitingKeyCardTap)
        let sawSync = states.contains(.waitingForSync)
        switch error {
        case nil:
            return sawCardPrompt || sawSync ? .enrolled : .alreadyEnrolled
        case .enrollmentTimedOut?:
            return sawSync ? .timedOutDuringSync : .timedOutBeforeCard
        case .enrollmentRejected(let reason)?:
            return .rejected(reason)
        case .vehicleUnreachable?:
            return .unreachable
        default:
            return nil
        }
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

    /// Copies each folder into one export folder (`diagnostics-<time>`,
    /// `recording-<time>`) and zips it.
    static func zipExport(_ folders: [(label: String, folder: URL)]) -> URL? {
        let fileManager = FileManager.default
        let stamp = LogSession.folderName(for: Date())
        let export = fileManager.temporaryDirectory.appending(path: "drive-log-\(stamp)", directoryHint: .isDirectory)
        try? fileManager.removeItem(at: export)
        do {
            try fileManager.createDirectory(at: export, withIntermediateDirectories: true)
            for (label, folder) in folders {
                try fileManager.copyItem(at: folder, to: export.appending(path: "\(label)-\(folder.lastPathComponent)"))
            }
        } catch {
            return nil
        }
        defer { try? fileManager.removeItem(at: export) }
        return zip(export)
    }

    /// A zip of `folder` in the temporary directory, via the file
    /// coordinator's upload form of a directory.
    static func zip(_ folder: URL) -> URL? {
        var result: URL?
        var coordinatorError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: folder, options: .forUploading, error: &coordinatorError) { zipped in
            let target = FileManager.default.temporaryDirectory.appending(path: "\(folder.lastPathComponent).zip")
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

/// Enrollment states as the client reports them (from its actor).
private final class StateLog: @unchecked Sendable {
    private let lock = NSLock()
    private var states: [EnrollmentState] = []

    func append(_ state: EnrollmentState) { lock.withLock { states.append(state) } }
    var all: [EnrollmentState] { lock.withLock { states } }
}

struct ShareItems: Identifiable {
    let id = UUID()
    let urls: [URL]
}
