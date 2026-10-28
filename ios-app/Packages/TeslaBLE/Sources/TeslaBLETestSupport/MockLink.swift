import CryptoKit
import Foundation
import TeslaBLE

/// A vehicle simulated at the message level: answers session-info requests
/// with an HMAC-tagged SessionInfo, decrypts signed requests with the shared
/// key and checks their counter and expiry (so a request the real Verifier
/// would reject is rejected here too), and seals replies the way
/// vehicle-command's Verifier does.
public struct FakeVehicle: Sendable {
    public struct Domain: Sendable {
        public var key = SoftwareKeyAgreementKey()
        public var epoch = Data.random(count: 16)
        /// The last counter accepted in this epoch.
        public var counter: UInt32 = 0
        /// Vehicle clock at `startedAt`, seconds into the epoch.
        public var clockTimeAtStart: UInt32 = 1000
        public var startedAt = ContinuousClock.now

        public init() {}

        public var clockTime: UInt32 {
            clockTimeAtStart + UInt32((ContinuousClock.now - startedAt).components.seconds)
        }
    }

    public struct ScriptedFault: Sendable {
        public var fault: UniversalMessage_MessageFault_E
        public var attachSessionInfo = false
        /// Seal the fault reply with AES-GCM, as newer firmware does.
        public var encrypted = false
        /// Break the AES-GCM tag of an encrypted fault reply.
        public var corruptTag = false

        public init(
            fault: UniversalMessage_MessageFault_E,
            attachSessionInfo: Bool = false,
            encrypted: Bool = false,
            corruptTag: Bool = false
        ) {
            self.fault = fault
            self.attachSessionInfo = attachSessionInfo
            self.encrypted = encrypted
            self.corruptTag = corruptTag
        }
    }

    public let vin: String
    public var domains: [UniversalMessage_Domain: Domain] = [.vehicleSecurity: Domain(), .infotainment: Domain()]
    public var vcsecKnowsKey = true
    public var infotainmentKnowsKey = true
    /// Faults for the next signed requests, in order.
    public var scriptedFaults: [ScriptedFault] = []
    /// A fault for every GetVehicleData request that asks for this category
    /// (after `scriptedFaults`).
    public var categoryFaults: [VehicleDataCategory: ScriptedFault] = [:]
    /// Domains that never answer.
    public var silentDomains: Set<UniversalMessage_Domain> = []
    /// Answer the next N session-info requests of a domain with WAIT/BUSY
    /// and no session info.
    public var handshakeHiccups: [UniversalMessage_Domain: Int] = [:]
    /// Session info always reports counter 0, older than counters in use.
    public var staleSessionCounter = false
    /// Echo a wrong `request_uuid` in replies to signed requests.
    public var corruptRequestUUID = false
    /// Bare replies to the add-key request.
    public var whitelistReplies: [VCSEC_FromVCSECMessage] = []
    /// The response plaintext of a successful GetVehicleData; a reply keeps
    /// only the sub-states the request asked for.
    public var responsePlaintext = UpstreamResponseVector.responsePlaintext

    public private(set) var addKeyRequests: [Data] = []
    public private(set) var sessionInfoRequests: [UniversalMessage_Domain: Int] = [:]
    public private(set) var signedRequests = 0
    /// The top-level field numbers of each GetVehicleData request (one per
    /// requested sub-message), in arrival order.
    public private(set) var vehicleDataRequests: [[Int]] = []

    public init(vin: String = ProtocolDoc.vin) {
        self.vin = vin
    }

    /// Both domains know (or forget) the key.
    public var keyOnWhitelist: Bool {
        get { vcsecKnowsKey && infotainmentKnowsKey }
        set {
            vcsecKnowsKey = newValue
            infotainmentKnowsKey = newValue
        }
    }

    public func knowsKey(_ domain: UniversalMessage_Domain) -> Bool {
        domain == .vehicleSecurity ? vcsecKnowsKey : infotainmentKnowsKey
    }

    /// Starts a new epoch, as after a vehicle reboot: requests signed in the
    /// old one get INCORRECT_EPOCH with fresh session info attached.
    public mutating func rotateEpoch(_ domain: UniversalMessage_Domain) {
        domains[domain]?.epoch = .random(count: 16)
        domains[domain]?.counter = 0
    }

    /// Whole reply messages for one whole request message.
    public mutating func respond(to bytes: Data) throws -> [Data] {
        let request = try UniversalMessage_RoutableMessage(serializedBytes: bytes)
        guard request.hasToDestination else { return try respondToBareVCSEC(bytes) }
        let domain = request.toDestination.domain
        guard !silentDomains.contains(domain), let state = domains[domain] else { return [] }

        if case .sessionInfoRequest(let hello)? = request.payload {
            sessionInfoRequests[domain, default: 0] += 1
            if let hiccups = handshakeHiccups[domain], hiccups > 0 {
                handshakeHiccups[domain] = hiccups - 1
                var reply = replyEnvelope(to: request, domain: domain)
                reply.signedMessageStatus.operationStatus = .operationstatusWait
                reply.signedMessageStatus.signedMessageFault = .rrorBusy
                return [try reply.serializedData()]
            }
            return [try sessionInfoReply(to: request, domain: domain, clientPublicKey: hello.publicKey).serializedData()]
        }

        signedRequests += 1
        let signature = request.signatureData.aesGcmPersonalizedData
        let clientPublicKey = request.signatureData.signerIdentity.publicKey
        let gcm = TeslaGCM(key: try TeslaSessionKey.derive(clientKey: state.key, vehiclePublicKeyX963: clientPublicKey))
        func fault(_ code: UniversalMessage_MessageFault_E, sessionInfo: Bool = false) throws -> [Data] {
            [try faultReply(to: request, domain: domain, fault: code, sessionInfoFor: sessionInfo ? clientPublicKey : nil).serializedData()]
        }
        guard knowsKey(domain) else { return try fault(.rrorUnknownKeyID) }
        guard signature.epoch == state.epoch else { return try fault(.rrorIncorrectEpoch, sessionInfo: true) }
        let requestMetadata = try SignatureMetadata.request(
            domain: domain, vin: vin, epoch: signature.epoch, expiresAt: signature.expiresAt,
            counter: signature.counter, flags: request.flags
        )
        let action: Data
        do {
            action = try gcm.decrypt(
                nonce: signature.nonce, ciphertext: request.protobufMessageAsBytes,
                tag: signature.tag, metadata: requestMetadata.serialized
            )
        } catch {
            return try fault(.rrorInvalidSignature)
        }
        // vehicle-command verifier: counters only go up; expiry within reach.
        guard signature.counter > state.counter else { return try fault(.rrorInvalidTokenOrCounter, sessionInfo: true) }
        guard signature.expiresAt >= state.clockTime else { return try fault(.rrorTimeExpired, sessionInfo: true) }
        guard signature.expiresAt <= state.clockTime + 60 else { return try fault(.rrorTimeToLiveTooLong, sessionInfo: true) }
        domains[domain]?.counter = signature.counter

        let requestHash = Data([UInt8(Signatures_SignatureType.aesGcmPersonalized.rawValue)]) + signature.tag
        var asked: CarServer_GetVehicleData?
        if let decoded = try? CarServer_Action(serializedBytes: action),
           case .getVehicleData(let getVehicleData)? = decoded.vehicleAction.vehicleActionMsg {
            asked = getVehicleData
            vehicleDataRequests.append(topLevelFieldNumbers(try getVehicleData.serializedData()) ?? [])
        }
        let categoryFault = asked.flatMap { asked in
            VehicleDataCategory.allCases.first { Self.asks(asked, for: $0) && categoryFaults[$0] != nil }
                .flatMap { categoryFaults[$0] }
        }
        if !scriptedFaults.isEmpty || categoryFault != nil {
            let scripted = scriptedFaults.isEmpty ? categoryFault! : scriptedFaults.removeFirst()
            var reply = try faultReply(
                to: request, domain: domain, fault: scripted.fault,
                sessionInfoFor: scripted.attachSessionInfo ? clientPublicKey : nil
            )
            if scripted.encrypted {
                try seal(&reply, plaintext: Data(), request: request, requestHash: requestHash, fault: scripted.fault, gcm: gcm)
                if scripted.corruptTag {
                    var tag = Data(reply.signatureData.aesGcmResponseData.tag)
                    tag[0] ^= 0xff
                    reply.signatureData.aesGcmResponseData.tag = tag
                }
            }
            return [try reply.serializedData()]
        }

        var reply = replyEnvelope(to: request, domain: domain)
        let plaintext = try asked.map { try Self.only($0, from: responsePlaintext) } ?? responsePlaintext
        try seal(&reply, plaintext: plaintext, request: request, requestHash: requestHash, fault: .rrorNone, gcm: gcm)
        return [try reply.serializedData()]
    }

    public static func asks(_ request: CarServer_GetVehicleData, for category: VehicleDataCategory) -> Bool {
        switch category {
        case .drive: request.hasGetDriveState
        case .charge: request.hasGetChargeState
        case .tirePressure: request.hasGetTirePressureState
        case .closures: request.hasGetClosuresState
        }
    }

    /// `plaintext` with only the sub-states `request` asked for.
    public static func only(_ request: CarServer_GetVehicleData, from plaintext: Data) throws -> Data {
        var response = try CarServer_Response(serializedBytes: plaintext)
        let full = response.vehicleData
        var kept = CarServer_VehicleData()
        if asks(request, for: .drive), full.hasDriveState { kept.driveState = full.driveState }
        if asks(request, for: .charge), full.hasChargeState { kept.chargeState = full.chargeState }
        if asks(request, for: .tirePressure), full.hasTirePressureState { kept.tirePressureState = full.tirePressureState }
        if asks(request, for: .closures), full.hasClosuresState { kept.closuresState = full.closuresState }
        response.vehicleData = kept
        return try response.serializedData()
    }

    private func seal(
        _ reply: inout UniversalMessage_RoutableMessage,
        plaintext: Data,
        request: UniversalMessage_RoutableMessage,
        requestHash: Data,
        fault: UniversalMessage_MessageFault_E,
        gcm: TeslaGCM
    ) throws {
        // The car sends a sealed fault without flags (and, with an empty
        // ciphertext, without a payload); a reply with data echoes the request's.
        let flags = fault == .rrorNone ? request.flags : 0
        let metadata = try SignatureMetadata.response(
            domain: reply.fromDestination.domain, vin: vin, counter: 1, flags: flags,
            requestHash: requestHash, fault: fault
        )
        let sealed = try gcm.encrypt(plaintext: plaintext, metadata: metadata.serialized)
        reply.flags = flags
        // An empty ciphertext leaves the payload field out, as the car does.
        if !sealed.ciphertext.isEmpty { reply.protobufMessageAsBytes = sealed.ciphertext }
        reply.signatureData.aesGcmResponseData.nonce = sealed.nonce
        reply.signatureData.aesGcmResponseData.counter = 1
        reply.signatureData.aesGcmResponseData.tag = sealed.tag
    }

    private mutating func respondToBareVCSEC(_ bytes: Data) throws -> [Data] {
        let envelope = try VCSEC_ToVCSECMessage(serializedBytes: bytes)
        let unsigned = try VCSEC_UnsignedMessage(serializedBytes: envelope.signedMessage.protobufMessageAsBytes)
        guard case .whitelistOperation(let operation)? = unsigned.subMessage,
              case .addKeyToWhitelistAndAddPermissions(let add)? = operation.subMessage
        else { return [] }
        addKeyRequests.append(add.key.publicKeyRaw)
        return try whitelistReplies.map { try $0.serializedData() }
    }

    private func replyEnvelope(to request: UniversalMessage_RoutableMessage, domain: UniversalMessage_Domain) -> UniversalMessage_RoutableMessage {
        var reply = UniversalMessage_RoutableMessage()
        reply.toDestination.routingAddress = request.fromDestination.routingAddress
        reply.fromDestination.domain = domain
        var isHandshake = false
        if case .sessionInfoRequest? = request.payload { isHandshake = true }
        reply.requestUuid = corruptRequestUUID && !isHandshake ? .random(count: 16) : request.uuid
        return reply
    }

    /// Session info, tagged with `HMAC(SESSION_INFO_KEY, metadata || info)`
    /// when the domain knows the key; untagged with status
    /// KEY_NOT_ON_WHITELIST otherwise.
    private func attachSessionInfo(
        to reply: inout UniversalMessage_RoutableMessage,
        challenge: Data,
        domain: UniversalMessage_Domain,
        clientPublicKey: Data
    ) throws {
        let state = domains[domain]!
        let known = knowsKey(domain)
        var info = Signatures_SessionInfo()
        info.counter = staleSessionCounter ? 0 : state.counter
        info.publicKey = state.key.publicKeyX963
        info.epoch = state.epoch
        info.clockTime = state.clockTime
        info.status = known ? .ok : .keyNotOnWhitelist
        let encoded = try info.serializedData()
        reply.sessionInfo = encoded
        guard known else { return }
        let sessionKey = try TeslaSessionKey.derive(clientKey: state.key, vehiclePublicKeyX963: clientPublicKey)
        let metadata = try SignatureMetadata.sessionInfo(vin: vin, challenge: challenge)
        reply.signatureData.sessionInfoTag.tag = Data(HMAC<SHA256>.authenticationCode(
            for: metadata.serialized + encoded,
            using: VehicleSession.sessionInfoKey(sessionKey)
        ))
    }

    private func sessionInfoReply(
        to request: UniversalMessage_RoutableMessage,
        domain: UniversalMessage_Domain,
        clientPublicKey: Data
    ) throws -> UniversalMessage_RoutableMessage {
        var reply = replyEnvelope(to: request, domain: domain)
        try attachSessionInfo(to: &reply, challenge: request.uuid, domain: domain, clientPublicKey: clientPublicKey)
        return reply
    }

    private func faultReply(
        to request: UniversalMessage_RoutableMessage,
        domain: UniversalMessage_Domain,
        fault: UniversalMessage_MessageFault_E,
        sessionInfoFor clientPublicKey: Data? = nil
    ) throws -> UniversalMessage_RoutableMessage {
        var reply = replyEnvelope(to: request, domain: domain)
        reply.signedMessageStatus.operationStatus = .rror
        reply.signedMessageStatus.signedMessageFault = fault
        if let clientPublicKey {
            try attachSessionInfo(to: &reply, challenge: request.uuid, domain: domain, clientPublicKey: clientPublicKey)
        }
        return reply
    }
}

/// `BLELink` over a `FakeVehicle`. Reassembles what the client writes with
/// the same `FrameAssembler`, and delivers replies framed and split into
/// `notifyChunkLength`-byte notifications.
public actor MockLink: BLELink {
    public nonisolated let events: AsyncStream<BLELinkEvent>
    private let sink: AsyncStream<BLELinkEvent>.Continuation

    public private(set) var vehicle: FakeVehicle
    public var maxWriteLength = 20
    public var notifyChunkLength = 7
    public var connectError: BLELinkError?
    public var writeError: BLELinkError?
    /// How long each write takes before it is acknowledged.
    public var writeDelay: Duration = .zero
    /// Connect scans this long first; cancelled, it fails with notConnected
    /// as CoreBluetoothLink does.
    public var connectDelay: Duration = .zero
    /// After `.found`, connect takes this long more before the link is up, as
    /// CoreBluetooth's connect and service discovery do.
    public var foundDelay: Duration = .zero
    /// Keep replies until `releaseHeld` (to reorder them).
    public var holdReplies = false
    /// Runs for each whole message the client writes, after the vehicle
    /// has seen it and before its replies are delivered.
    public var onMessage: (@Sendable (FakeVehicle) -> Void)?

    public private(set) var isConnected = false
    public private(set) var writes: [Data] = []
    public private(set) var held: [Data] = []
    public private(set) var disconnectCalls = 0
    public private(set) var connectCalls = 0
    private var outbound = FrameAssembler()

    public init(vehicle: FakeVehicle = FakeVehicle()) {
        self.vehicle = vehicle
        (events, sink) = AsyncStream.makeStream(of: BLELinkEvent.self)
    }

    /// Emits `.found` once the scan (`connectDelay`) sees the vehicle's name.
    public func connect(localName: String, timeout: Duration) async throws -> Int {
        connectCalls += 1
        if let connectError { throw connectError }
        if connectDelay > .zero {
            do { try await Task.sleep(for: connectDelay) } catch { throw BLELinkError.notConnected }
        }
        guard localName == TeslaBLEConstants.localName(forVIN: vehicle.vin) else { throw BLELinkError.scanTimedOut }
        sink.yield(.found(localName: localName))
        if foundDelay > .zero {
            do { try await Task.sleep(for: foundDelay) } catch { throw BLELinkError.notConnected }
        }
        isConnected = true
        return maxWriteLength
    }

    public func write(_ value: Data) async throws {
        if let writeError { throw writeError }
        if writeDelay > .zero { try await Task.sleep(for: writeDelay) }
        guard isConnected else { throw BLELinkError.notConnected }
        precondition(value.count <= maxWriteLength, "write longer than the negotiated length")
        writes.append(value)
        for output in outbound.append(value) {
            guard case .message(let message) = output else { continue }
            let replies = try vehicle.respond(to: message)
            onMessage?(vehicle)
            for reply in replies {
                if holdReplies { held.append(reply) } else { deliver(reply) }
            }
        }
    }

    public func disconnect() async {
        isConnected = false
        disconnectCalls += 1
    }

    public func update(_ body: @Sendable (inout FakeVehicle) -> Void) {
        body(&vehicle)
    }

    public func set(holdReplies: Bool) { self.holdReplies = holdReplies }
    public func set(writeError: BLELinkError?) { self.writeError = writeError }
    public func set(writeDelay: Duration) { self.writeDelay = writeDelay }
    public func set(connectDelay: Duration) { self.connectDelay = connectDelay }
    public func set(foundDelay: Duration) { self.foundDelay = foundDelay }
    public func set(connectError: BLELinkError?) { self.connectError = connectError }
    public func set(onMessage: (@Sendable (FakeVehicle) -> Void)?) { self.onMessage = onMessage }

    public func releaseHeld(reversed: Bool = false) {
        let replies = reversed ? held.reversed() : held
        held = []
        replies.forEach(deliver)
    }

    /// One raw notification value.
    public func inject(_ chunk: Data) {
        sink.yield(.received(chunk))
    }

    public func deliver(_ message: Data) {
        for chunk in try! TeslaFraming.chunks(for: message, chunkLength: notifyChunkLength) {
            sink.yield(.received(chunk))
        }
    }

    public func drop(reconnecting: Bool) {
        isConnected = false
        outbound.reset()
        sink.yield(.disconnected(reconnecting: reconnecting, reason: "test"))
    }

    public func reconnect() {
        isConnected = true
        sink.yield(.reconnected(maxWriteLength: maxWriteLength))
    }
}

/// In-memory `TeslaKeyStore`.
public final class InMemoryKeyStore: TeslaKeyStore, @unchecked Sendable {
    public struct Locked: Error {}
    private let lock = NSLock()
    /// Every call throws, as the Keychain does while the phone is locked.
    public var isLocked = false
    private var key: SoftwareKeyAgreementKey?
    private var vin: String?
    private var vehicleKeys: [String: Data] = [:]

    public init() {}

    public func clientKey() throws -> any KeyAgreementKey {
        if isLocked { throw Locked() }
        return lock.withLock {
            if let key { return key }
            let created = SoftwareKeyAgreementKey()
            key = created
            return created
        }
    }

    public func pairedVIN() throws -> String? {
        if isLocked { throw Locked() }
        return lock.withLock { vin }
    }

    public func setPairedVIN(_ vin: String) throws {
        if isLocked { throw Locked() }
        lock.withLock { self.vin = vin }
    }

    public func vehiclePublicKey(vin: String, domain: UniversalMessage_Domain) throws -> Data? {
        if isLocked { throw Locked() }
        return lock.withLock { vehicleKeys["\(vin).\(domain.rawValue)"] }
    }

    public func setVehiclePublicKey(_ key: Data, vin: String, domain: UniversalMessage_Domain) throws {
        if isLocked { throw Locked() }
        lock.withLock { vehicleKeys["\(vin).\(domain.rawValue)"] = key }
    }
}

extension TeslaVehicleClient {
    /// Ends the event stream and returns everything emitted so far.
    public func drainEvents() async -> [TeslaClientEvent.Kind] {
        finishEvents()
        var kinds: [TeslaClientEvent.Kind] = []
        for await event in events { kinds.append(event.kind) }
        return kinds
    }
}
