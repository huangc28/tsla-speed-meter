import Foundation
import Observation
import TeslaBLE

/// Pairing with a typed VIN (S13–S17, 01 §4.2 as changed by L63–L67): drives the app's one
/// car feed through the nearby match, adding the app key and one read, and gives the screens
/// one step to show.
///
/// - Bluetooth is first touched when S15 starts (`CarFeed.connect(vin:)` creates the central
///   on a phone that was never paired).
/// - Pairing is done only after a verified read: only then is the paired VIN stored (L65).
///   Until then any older paired car and its key stay, and a cancel or 稍後再說 sends the
///   feed back to it. Storing is the commit point: a cancel that arrives while the store
///   runs leaves the new car paired (the screen just closes); one that arrives before it
///   stores nothing.
/// - Every failure is one `.failed` step carrying the error; #56 turns them into S18 a–h.
@MainActor
@Observable
final class PairingFlow: Identifiable {
    enum Step: Equatable {
        /// S13: the checklist; 開始 once the car is confirmed parked (L67).
        case start
        /// S14: the typed VIN.
        case vin
        /// S15: looking for the VIN's Bluetooth name; `matched` once the scan found it
        /// (「✓ 就是旁邊這台」), while it connects and checks the key.
        case finding(matched: Bool)
        /// S16: tap the key card and confirm on the car screen.
        case keyCard
        /// S17: the key is in; reading the car once.
        case reading
        /// S17: the car was read and is the paired car now; a live preview until 完成.
        case paired(PairingPreview)
        case failed(TeslaClientError)
    }

    private(set) var step = Step.start {
        didSet { onStepChange?(step) }
    }
    /// Called on every step change, in order (tests record the steps with it).
    @ObservationIgnored var onStepChange: (@MainActor (Step) -> Void)?
    /// 「車子已經停好(P 檔)」 on S13.
    var parkedConfirmed = false
    private(set) var entry = VINEntry("")

    private let feed: CarFeed
    /// The VIN being paired, once S14 handed it over.
    private var vin: String?
    private var run: Task<Void, Never>?
    private var preview: Task<Void, Never>?
    /// Bumped by each run and by cancel, so a late update from an older run is dropped.
    private var attempt = 0
    /// Set by `cancel()` and `finish()`: the flow is ending; nothing starts again, and no
    /// preview is started.
    private var closing = false

    init(feed: CarFeed) {
        self.feed = feed
    }

    // MARK: S13, S14

    func begin() {
        guard !closing, step == .start, parkedConfirmed else { return }
        step = .vin
    }

    func back() {
        guard step == .vin else { return }
        step = .start
    }

    func type(_ text: String) {
        entry = VINEntry(text)
    }

    /// 下一步: only a complete VIN with nothing to warn about.
    func submitVIN() {
        guard !closing, step == .vin, entry.problem == nil, let vin = entry.vin else { return }
        pair(vin)
    }

    /// 仍要繼續 after the check-digit warning: the nearby match decides.
    func submitVINAnyway() {
        guard !closing, step == .vin, entry.problem == .checkDigit, let vin = entry.vin else { return }
        pair(vin)
    }

    // MARK: S15–S17

    /// 重試 after a failure: from S15 again, with the same VIN.
    func retry() {
        guard !closing, case .failed = step, let vin else { return }
        pair(vin)
    }

    /// 完成 on S17 (or the screen went away): the preview stops for good.
    func finish() {
        closing = true
        preview?.cancel()
        preview = nil
    }

    /// 取消, 返回 out of the flow, or 稍後再說: stops what is running and leaves nothing
    /// behind on the phone. A key the car already accepted stays on the car (01 §4.2).
    /// Nothing starts again afterwards, even while the screen is still closing.
    func cancel() async {
        attempt += 1
        finish()
        let running = run
        running?.cancel()
        await running?.value
        run = nil
        // Once pairing took a VIN, the feed must end up on the paired car (none: no car),
        // whether pairing moved the link or found it on that car already (a test-page
        // connect). A car stored by a store that had already started stays paired.
        guard vin != nil else { return }
        let paired = await feed.pairedVIN
        if await feed.targetVIN != paired {
            await feed.returnToPairedCar()
        }
    }

    private func pair(_ vin: String) {
        self.vin = vin
        attempt += 1
        step = .finding(matched: false)
        let attempt = attempt
        run = Task { await self.pair(vin, attempt: attempt) }
    }

    private func pair(_ vin: String, attempt: Int) async {
        // Subscribed before connecting: the feed replays no events.
        let found = TeslaClientEvent.Kind.vehicleFound(localName: TeslaBLEConstants.localName(forVIN: vin))
        let events = feed.events()
        let watcher = Task { [weak self] in
            for await event in events where event.kind == found {
                self?.matched(attempt)
            }
        }
        defer { watcher.cancel() }
        do {
            // Already connected to this car (the drive screen's link): the match is proven.
            let connected = await feed.connectedVIN
            if connected != vin {
                if connected != nil { await feed.disconnect() }
                try await feed.connect(vin: vin)
            }
            matched(attempt)
            try await feed.enrollKey { state in
                Task { @MainActor [weak self] in self?.enrollment(state, attempt: attempt) }
            }
            try Task.checkCancellation()
            step = .reading
            let poll = await feed.readOnce()
            guard poll.response(for: .drive) != nil else {
                throw poll.error(for: .drive) ?? poll.firstError ?? TeslaClientError.notConnected
            }
            // The commit point: from here on the car is paired, even if a cancel comes.
            try Task.checkCancellation()
            guard !closing else { return }
            try await feed.storePairedVIN(vin)
            // Closed while storing: paired, but no S17 and no preview.
            guard !closing else { return }
            step = .paired(PairingPreview(poll))
            followPreview()
        } catch {
            guard !Task.isCancelled, attempt == self.attempt else { return }
            step = .failed(TeslaVehicleClient.clientError(error))
        }
    }

    private func matched(_ attempt: Int) {
        guard attempt == self.attempt, step == .finding(matched: false) else { return }
        step = .finding(matched: true)
    }

    private func enrollment(_ state: EnrollmentState, attempt: Int) {
        guard attempt == self.attempt, case .finding = step else { return }
        switch state {
        case .awaitingKeyCardTap, .waitingForSync: step = .keyCard
        default: break
        }
    }

    /// Keeps the S17 preview live from the feed's polls until 完成.
    private func followPreview() {
        guard !closing else { return }
        let polls = feed.polls()
        preview = Task { [weak self] in
            for await poll in polls {
                guard let self, case .paired(var value) = self.step else { return }
                value.update(with: poll)
                self.step = .paired(value)
            }
        }
    }
}

/// The S17 preview: speed, gear and battery as the car last sent them.
struct PairingPreview: Equatable {
    /// The speed's magnitude.
    var speedKilometersPerHour: Double?
    var gear: Gear?
    var batteryPercent: Int?

    init(speedKilometersPerHour: Double? = nil, gear: Gear? = nil, batteryPercent: Int? = nil) {
        self.speedKilometersPerHour = speedKilometersPerHour
        self.gear = gear
        self.batteryPercent = batteryPercent
    }

    init(_ poll: VehicleDataPoll) {
        self.init()
        update(with: poll)
    }

    /// Takes what came back in `poll`; a category that did not keeps its value.
    mutating func update(with poll: VehicleDataPoll) {
        if let drive = poll.response(for: .drive)?.reading {
            speedKilometersPerHour = drive.speedMetersPerSecond.map { abs($0) * 3.6 }
            gear = drive.gear == .unknown ? nil : drive.gear
        }
        if let level = poll.response(for: .charge)?.reading.batteryLevel {
            batteryPercent = Int(level)
        }
    }
}
