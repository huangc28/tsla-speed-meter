import Foundation
import TeslaBLE

/// One recording's folder, `Documents/Logs/<start time>/`:
/// `samples.csv`, `gps.csv`, `events.jsonl`, `frames.txt`, `meta.json`.
/// Lines are written straight to disk, so a crash keeps what was logged.
final class LogSession {
    static let fileNames = ["samples.csv", "gps.csv", "events.jsonl", "frames.txt", "meta.json"]

    let directory: URL
    let startedAt: Date
    let startInstant: ContinuousClock.Instant
    private(set) var sampleCount = 0
    private(set) var errorCount = 0
    private(set) var gpsCount = 0
    private(set) var eventCount = 0
    private(set) var frameCount = 0
    /// Lines that could not be written (disk full and the like).
    private(set) var writeFailures = 0

    private let meta: [String: Any]
    private let samples: FileHandle
    private let gps: FileHandle
    private let events: FileHandle
    private let frames: FileHandle

    /// `Documents/Logs`.
    static var defaultRoot: URL {
        URL.documentsDirectory.appending(path: "Logs", directoryHint: .isDirectory)
    }

    /// Creates the folder and the files with their headers, and writes `meta`.
    init(root: URL = LogSession.defaultRoot, startedAt: Date = Date(), meta: [String: Any]) throws {
        self.startedAt = startedAt
        startInstant = .now
        self.meta = meta
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        let base = Self.folderName(for: startedAt)
        var candidate = root.appending(path: base, directoryHint: .isDirectory)
        var suffix = 2
        while fileManager.fileExists(atPath: candidate.path()) {
            candidate = root.appending(path: "\(base)-\(suffix)", directoryHint: .isDirectory)
            suffix += 1
        }
        directory = candidate
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: false)

        samples = try Self.create("samples.csv", in: candidate, header: SampleCSV.header)
        gps = try Self.create("gps.csv", in: candidate, header: GPSCSV.header)
        events = try Self.create("events.jsonl", in: candidate, header: "")
        frames = try Self.create("frames.txt", in: candidate, header: "# phone_time monotonic_ms direction hex\n")
        try writeMeta(extra: [:])
    }

    private static func create(_ name: String, in directory: URL, header: String) throws -> FileHandle {
        let url = directory.appending(path: name)
        try Data(header.utf8).write(to: url)
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        return handle
    }

    deinit {
        for handle in [samples, gps, events, frames] { try? handle.close() }
    }

    var files: [URL] { Self.fileNames.map { directory.appending(path: $0) } }

    /// Local start time, sortable: `2026-10-22_14-30-05`.
    static func folderName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }

    func monotonicMs(at instant: ContinuousClock.Instant = .now) -> Int {
        LogFormat.ms(instant - startInstant)
    }

    func write(sample: Sample) {
        sampleCount += 1
        if sample.error != nil { errorCount += 1 }
        append(SampleCSV.row(sample), to: samples)
    }

    func write(gps fix: GPSFix, receivedAt: Date) {
        gpsCount += 1
        append(GPSCSV.row(fix, receivedAt: receivedAt, monotonicMs: monotonicMs()), to: gps)
    }

    /// One JSON object per line, with `phone_time` and `monotonic_ms` added.
    func write(event fields: [String: Any], phoneTime: Date) {
        var object = fields
        object["phone_time"] = LogFormat.iso(phoneTime)
        object["monotonic_ms"] = monotonicMs()
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes]) else {
            writeFailures += 1
            return
        }
        eventCount += 1
        append(String(decoding: data, as: UTF8.self) + "\n", to: events)
    }

    func write(frame: Data, sent: Bool, phoneTime: Date) {
        frameCount += 1
        append("\(LogFormat.iso(phoneTime)) \(monotonicMs()) \(sent ? "TX" : "RX") \(LogFormat.hex(frame))\n", to: frames)
    }

    /// Rewrites `meta.json` with the stop time and counts, and closes the files.
    func finish(stoppedAt: Date = Date()) {
        try? writeMeta(extra: [
            "stopped_at": LogFormat.iso(stoppedAt),
            "duration_ms": monotonicMs(),
            "sample_count": sampleCount,
            "error_count": errorCount,
            "gps_fix_count": gpsCount,
            "event_count": eventCount,
            "frame_count": frameCount,
            "write_failures": writeFailures,
        ])
        for handle in [samples, gps, events, frames] { try? handle.synchronize() }
    }

    private func writeMeta(extra: [String: Any]) throws {
        var object = meta.merging(extra) { _, new in new }
        object["started_at"] = LogFormat.iso(startedAt)
        object["folder"] = directory.lastPathComponent
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        try data.write(to: directory.appending(path: "meta.json"), options: .atomic)
    }

    private func append(_ line: String, to handle: FileHandle) {
        do {
            try handle.write(contentsOf: Data(line.utf8))
        } catch {
            writeFailures += 1
        }
    }
}

/// `TeslaClientEvent` as a flat JSON object for `events.jsonl`. Raw frames
/// go to `frames.txt` instead (nil here).
enum EventJSON {
    static func fields(_ kind: TeslaClientEvent.Kind) -> [String: Any]? {
        switch kind {
        case .connecting(let localName):
            return ["type": "connecting", "local_name": localName]
        case .connected(let localName, let maxWriteLength, let ms):
            return ["type": "connected", "local_name": localName, "max_write_length": maxWriteLength, "duration_ms": ms]
        case .connectFailed(let error, let ms):
            return ["type": "connect_failed", "error": "\(error)", "duration_ms": ms]
        case .disconnected(let reconnecting, let reason):
            return ["type": "disconnected", "reconnecting": reconnecting, "reason": reason ?? ""]
        case .reconnected(let maxWriteLength):
            return ["type": "reconnected", "max_write_length": maxWriteLength]
        case .handshakeStarted(let domain):
            return ["type": "handshake_started", "domain": name(domain)]
        case .handshakeSucceeded(let domain, let ms):
            return ["type": "handshake_succeeded", "domain": name(domain), "duration_ms": ms]
        case .handshakeFailed(let domain, let error, let ms):
            return ["type": "handshake_failed", "domain": name(domain), "error": "\(error)", "duration_ms": ms]
        case .requestSent(let domain, let kind, let bytes):
            return ["type": "request_sent", "domain": name(domain), "request": kind.rawValue, "bytes": bytes]
        case .responseReceived(let domain, let kind, let bytes, let ms):
            return ["type": "response_received", "domain": name(domain), "request": kind.rawValue, "bytes": bytes, "duration_ms": ms]
        case .fault(let domain, let fault):
            return ["type": "fault", "domain": name(domain), "fault": "\(fault)"]
        case .sessionResynced(let domain):
            return ["type": "session_resynced", "domain": name(domain)]
        case .timeout(let domain, let kind, let ms):
            return ["type": "timeout", "domain": name(domain), "request": kind.rawValue, "duration_ms": ms]
        case .enrollment(let state):
            return ["type": "enrollment", "state": "\(state)"]
        case .whitelistStatus(let status, let information):
            return ["type": "whitelist_status", "status": "\(status)", "information": "\(information)"]
        case .messageDropped(let reason):
            return ["type": "message_dropped", "reason": reason]
        case .frameSent, .frameReceived:
            return nil
        }
    }

    static func name(_ domain: UniversalMessage_Domain) -> String {
        switch domain {
        case .vehicleSecurity: "vcsec"
        case .infotainment: "infotainment"
        default: "\(domain)"
        }
    }
}
