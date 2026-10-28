import Foundation
import Observation
import SwiftUI
import TeslaBLE
import UIKit

/// The test drive logger behind the "行車紀錄(測試)" page: connect, enroll
/// the key, read once, record and export, all through the app's one
/// `CarFeed`. It does not poll the car itself: while recording it listens
/// to the feed and writes one row per drive slot (about 5 a second), with
/// phone GPS speed on the same timeline. A slot is a drive request and the
/// charge state or tire pressure the feed asked just before it (each once
/// every 10 s); when that earlier request hits a link failure, the slot's
/// drive request is skipped and the row says so. Drive state is the row's
/// last request, so the row's phone time and GPS fix are taken right after
/// its reply.
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

    private static let vinKey = "driveLogger.vin"
    private static let recentLimit = 40

    /// The page's VIN field: a testing override for 連線; empty means the paired car.
    var vin: String {
        didSet { defaults.set(vin, forKey: Self.vinKey) }
    }
    /// The paired car's VIN from the Keychain, the one source of truth (spec #52). Only
    /// pairing writes it; this page reads it.
    private(set) var pairedVIN: String?
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
    /// Set when the diagnostics folder cannot be created; kept until it can.
    private(set) var diagnosticsError: String?
    /// Lines the log files could not write, this app run.
    private(set) var writeFailureCount = 0
    private(set) var recordingStartedAt: Date?
    private(set) var sampleCount = 0
    /// Polls where drive state did not come back.
    private(set) var errorCount = 0
    /// Polls where drive state came back but charge state or tire pressure did not.
    private(set) var categoryErrorCount = 0
    private(set) var lastFolder: URL?
    private(set) var diagnosticsFolder: URL?
    private(set) var recent: [String] = []
    var shareItems: ShareItems?

    private let feed: CarFeed
    private let defaults: UserDefaults
    private let logsRoot: URL
    private let diagnosticsRoot: URL
    private let diagnosticsCapBytes: Int
    private let diagnosticsKeep: Int
    /// Diagnostics folders of this app run, oldest first (several after a rotation).
    private var runDiagnosticsFolders: [URL] = []
    private var finishedWriteFailures = 0
    private let gps = GPSRecorder()
    private var session: LogSession?
    private var diagnostics: LogSession?
    private var pollTask: Task<Void, Never>?
    private var eventTask: Task<Void, Never>?
    private var enrollmentAttempt = 0

    init(
        feed: CarFeed,
        defaults: UserDefaults = .standard,
        logsRoot: URL = LogSession.defaultRoot,
        diagnosticsRoot: URL = LogSession.diagnosticsRoot,
        diagnosticsCapBytes: Int = 50_000_000,
        diagnosticsKeep: Int = 10
    ) {
        self.feed = feed
        self.defaults = defaults
        self.logsRoot = logsRoot
        self.diagnosticsRoot = diagnosticsRoot
        self.diagnosticsCapBytes = diagnosticsCapBytes
        self.diagnosticsKeep = diagnosticsKeep
        vin = defaults.string(forKey: Self.vinKey) ?? ""
        lastFolder = Self.latestFolder(in: logsRoot)
        diagnosticsFolder = Self.latestFolder(in: diagnosticsRoot)
        gps.onFix = { [weak self] fix in self?.received(fix) }
        gps.onStatus = { [weak self] status in self?.gpsChanged(status) }
        let events = feed.events()
        eventTask = Task { [weak self] in
            for await event in events {
                self?.handle(event)
            }
        }
    }

    var normalizedVIN: String {
        vin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    /// The VIN 連線 uses: the field when filled, else the paired car.
    var targetVIN: String {
        normalizedVIN.isEmpty ? (pairedVIN ?? "") : normalizedVIN
    }

    var isVINValid: Bool {
        targetVIN.count == 17
    }

    var maskedVIN: String { LogFormat.maskedVIN(targetVIN) }

    func refreshPairedVIN() async {
        pairedVIN = await feed.pairedVIN
    }

    var canExport: Bool {
        lastFolder != nil || diagnosticsFolder != nil
    }

    // MARK: Steps

    func connect() async {
        await refreshPairedVIN()
        guard isVINValid else {
            lastError = "VIN 要剛好 17 碼。"
            return
        }
        let vin = targetVIN
        if !normalizedVIN.isEmpty { self.vin = vin }
        startDiagnostics()
        begin("連線中…")
        defer { busy = nil }
        linkStatus = .connecting
        keyHint = nil
        do {
            // A second tap reconnects cleanly instead of waiting out the scan.
            if await feed.isConnected { await feed.disconnect() }
            try await feed.connect(vin: vin)
            linkStatus = .connected
            note("已連上車子 \(maskedVIN)")
        } catch {
            linkStatus = .failed(Self.describe(error))
            lastError = Self.describe(error)
            return
        }
        do {
            try await feed.startSessions()
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
            try await feed.enrollKey { state in
                states.append(state)
                Task { @MainActor [weak self] in
                    guard let self, self.enrollmentAttempt == attempt, self.enrollmentOutcome == nil else { return }
                    self.enrollment = state
                }
            }
            note("鑰匙已加入")
            try? await feed.startSessions()
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
        let sample = stamp(await feed.readOnce(), timedBy: diagnostics)
        diagnostics?.write(sample: sample)
        diagnosticsWritten()
        lastSample = sample
        if sample.response == nil, let failure = sample.poll?.firstError {
            lastError = "讀取失敗:\(Self.describe(failure))"
        }
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
        categoryErrorCount = 0
        UIApplication.shared.isIdleTimerDisabled = true
        writeEvent(["type": "recording_started", "folder": session.directory.lastPathComponent])
        gps.start()
        note("開始紀錄 \(session.directory.lastPathComponent)")
        let polls = feed.polls()
        pollTask = Task { [weak self] in
            for await poll in polls {
                self?.record(poll)
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
            writeEvent(["type": "recording_stopped", "folder": session.directory.lastPathComponent])
            session.finish()
            finishedWriteFailures += session.writeFailures
            lastFolder = session.directory
            let categoryErrors = session.categoryErrorCount > 0 ? ",只有充電、胎壓或車門沒讀到 \(session.categoryErrorCount) 筆" : ""
            note("停止紀錄:\(session.sampleCount) 筆,錯誤 \(session.errorCount) 筆\(categoryErrors)")
        }
        session = nil
        isRecording = false
        isStopping = false
    }

    /// Shares one zip with this run's diagnostics and the latest recording
    /// (either may be missing), or their files when zipping fails.
    func export() {
        diagnostics?.checkpoint()
        let existing = runDiagnosticsFolders.filter { FileManager.default.fileExists(atPath: $0.path()) }
        let diagnosticsFolders = existing.isEmpty ? [diagnosticsFolder].compactMap { $0 } : existing
        let folders = diagnosticsFolders.map { ("diagnostics", $0) } + [lastFolder].compactMap { $0 }.map { ("recording", $0) }
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
        let poll = VehicleDataPoll(entries: [
            .init(category: .drive, result: .success(VehicleDataResponse(reading: reading, isEncrypted: true, roundTripMs: 84, retried: false))),
            .init(category: .charge, result: .success(VehicleDataResponse(reading: reading, isEncrypted: true, roundTripMs: 91, retried: false))),
            .init(category: .tirePressure, result: .failure(.session(.invalidResponseTag(reportedFault: .rrorResponseMtuExceeded)))),
        ])
        lastSample = Sample(
            poll: poll,
            phoneTime: Date(),
            monotonicMs: 0,
            gps: GPSFix(timestamp: Date(), speed: 1.4, speedAccuracy: 0.5, horizontalAccuracy: 5)
        )
        appendRecent("\(Self.clock(Date())) handshake_succeeded domain=infotainment duration_ms=212")
        appendRecent("\(Self.clock(Date())) response_received domain=infotainment duration_ms=84 request=getVehicleData")
    }
    #endif

    // MARK: Recording

    /// One row per poll from the feed (one drive slot each).
    func record(_ polled: VehicleDataPoll) {
        guard let poll = Self.recordable(polled), let session else { return }
        let sample = stamp(poll, timedBy: session)
        session.write(sample: sample)
        lastSample = sample
        sampleCount = session.sampleCount
        errorCount = session.errorCount
        categoryErrorCount = session.categoryErrorCount
        refreshWriteFailures()
    }

    /// The poll as a row, with the phone time and GPS fix of this moment
    /// (right after the last reply, which is drive state's).
    private func stamp(_ poll: VehicleDataPoll, timedBy log: LogSession?) -> Sample {
        Sample(poll: poll, phoneTime: Date(), monotonicMs: log?.monotonicMs() ?? 0, gps: latestFix)
    }

    /// The feed cancels the request in flight when polling stops or pauses
    /// (停止紀錄, 加入鑰匙, 讀一次); a cancelled category is not a result,
    /// so it is dropped. Nil (no row) when cancellation was the
    /// poll's only failure and drive state did not come back.
    static func recordable(_ poll: VehicleDataPoll) -> VehicleDataPoll? {
        let kept = poll.entries.filter { $0.result != .failure(.cancelled) }
        guard kept.count < poll.entries.count else { return poll }
        let trimmed = VehicleDataPoll(entries: kept, skipped: poll.skipped)
        guard trimmed.response(for: .drive) != nil || trimmed.firstError != nil else { return nil }
        return trimmed
    }

    /// One line per category asked for: came back, why not, or skipped.
    static func summary(_ poll: VehicleDataPoll) -> [String] {
        func name(_ category: VehicleDataCategory) -> String {
            switch category {
            case .drive: "行駛資料"
            case .charge: "充電資料"
            case .tirePressure: "胎壓資料"
            case .closures: "車門資料"
            }
        }
        return poll.entries.map { entry in
            switch entry.result {
            case .success: "\(name(entry.category)):有讀到"
            case .failure(let error): "\(name(entry.category)):沒讀到(\(describe(error)))"
            }
        } + poll.skipped.map { "\(name($0)):略過(連不上車子)" }
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
            diagnosticsWritten()
            session?.write(frame: bytes, sent: true, phoneTime: event.date)
            return
        case .frameReceived(let bytes):
            diagnostics?.write(frame: bytes, sent: false, phoneTime: event.date)
            diagnosticsWritten()
            session?.write(frame: bytes, sent: false, phoneTime: event.date)
            return
        case .disconnected(let reconnecting, let reason):
            linkStatus = reconnecting ? .reconnecting : .disconnected(reason ?? "")
        case .connected, .reconnected:
            if isAutoReconnecting { note("自動重新連線成功") }
            isAutoReconnecting = false
            linkStatus = .connected
        // The feed reconnects on its own while someone listens (the main
        // screen, or this page while recording).
        case .autoReconnect:
            isAutoReconnecting = true
            linkStatus = .connecting
        case .autoReconnectFailed(_, let failure):
            linkStatus = .failed(Self.describe(failure))
        case .autoReconnectCancelled:
            isAutoReconnecting = false
            linkStatus = .disconnected("")
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
        openDiagnostics(continuing: nil)
    }

    /// Opens a diagnostics folder, keeping only the newest `diagnosticsKeep`.
    private func openDiagnostics(continuing previous: URL?) {
        guard let log = try? LogSession(root: diagnosticsRoot, meta: meta(kind: "diagnostics")) else {
            diagnosticsError = "無法建立診斷紀錄檔。"
            return
        }
        diagnosticsError = nil
        diagnostics = log
        diagnosticsFolder = log.directory
        runDiagnosticsFolders.append(log.directory)
        var started: [String: Any] = ["type": "diagnostics_started", "vin_masked": maskedVIN]
        if let previous { started["continues"] = previous.lastPathComponent }
        log.write(event: started, phoneTime: Date())
        Self.prune(diagnosticsRoot, keep: diagnosticsKeep)
    }

    /// Starts the next diagnostics folder once the current one passes the cap.
    private func diagnosticsWritten() {
        refreshWriteFailures()
        guard let current = diagnostics, current.bytesWritten > diagnosticsCapBytes else { return }
        current.write(event: ["type": "diagnostics_rotated", "bytes": current.bytesWritten], phoneTime: Date())
        current.finish()
        finishedWriteFailures += current.writeFailures
        diagnostics = nil
        openDiagnostics(continuing: current.directory)
    }

    /// Deletes all but the newest `keep` folders in `root`.
    static func prune(_ root: URL, keep: Int) {
        let folders = ((try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? [])
            .filter(\.hasDirectoryPath)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        for folder in folders.dropLast(keep) {
            try? FileManager.default.removeItem(at: folder)
        }
    }

    private func refreshWriteFailures() {
        let count = finishedWriteFailures + (diagnostics?.writeFailures ?? 0) + (session?.writeFailures ?? 0)
        if count != writeFailureCount { writeFailureCount = count }
    }

    /// Writes to the diagnostics and, while recording, to the recording.
    private func writeEvent(_ fields: [String: Any], at date: Date = Date()) {
        diagnostics?.write(event: fields, phoneTime: date)
        session?.write(event: fields, phoneTime: date)
        diagnosticsWritten()
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
        let configuration = feed.configuration
        return [
            "kind": kind,
            "app_version": info["CFBundleShortVersionString"] as? String ?? "",
            "app_build": info["CFBundleVersion"] as? String ?? "",
            "ios_version": UIDevice.current.systemVersion,
            "device_model": Self.deviceModel(),
            "vin_masked": maskedVIN,
            "time_zone": TimeZone.current.identifier,
            "settings": [
                "one_request_in_flight": true,
                "one_category_per_request": true,
                "one_row_per_drive_slot": true,
                "drive_slot": "charge state, tire pressure or closures (when due), then drive state; a link failure on the first skips the drive request",
                "drive_request_min_interval_ms": LogFormat.ms(feed.cadence.driveInterval),
                "drive_request_sent_on_previous_reply": true,
                "charge_interval_ms": LogFormat.ms(feed.cadence.slowInterval),
                "tire_pressure_interval_ms": LogFormat.ms(feed.cadence.slowInterval),
                "closures_interval_ms": LogFormat.ms(feed.cadence.slowInterval),
                "slow_categories_between_drive_requests": true,
                "drive_state_asked_last": true,
                "connect_timeout_ms": LogFormat.ms(configuration.connectTimeout),
                "handshake_timeout_ms": LogFormat.ms(configuration.handshakeTimeout),
                "request_timeout_ms": LogFormat.ms(configuration.requestTimeout),
                "request_timeout_starts": "after the write completes",
                "request_lifetime_s": configuration.requestLifetimeSeconds,
                "reconnect_by": "car feed, while someone listens",
                "retry_delay_ms": LogFormat.ms(feed.cadence.retryDelay),
                "max_retry_delay_ms": LogFormat.ms(feed.cadence.maxRetryDelay),
                "system_reconnect_grace_ms": LogFormat.ms(feed.cadence.systemReconnectGrace),
                "capture_raw_frames": configuration.captureRawFrames,
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
            FaultText.verified(fault)
        case .session(.invalidResponseTag(let fault)) where fault != .rrorNone:
            FaultText.unverified(fault)
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
