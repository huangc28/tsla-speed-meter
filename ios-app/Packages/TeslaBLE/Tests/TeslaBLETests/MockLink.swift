import CryptoKit
import Foundation
import Testing
@testable import TeslaBLE

/// A vehicle simulated at the message level: answers session-info requests
/// with an HMAC-tagged SessionInfo, decrypts signed requests with the shared
/// key and checks their counter and expiry (so a request the real Verifier
/// would reject is rejected here too), and seals replies the way
/// vehicle-command's Verifier does.
struct FakeVehicle {
    struct Domain {
        var key = SoftwareKeyAgreementKey()
        var epoch = Data.random(count: 16)
        /// The last counter accepted in this epoch.
        var counter: UInt32 = 0
        /// Vehicle clock at `startedAt`, seconds into the epoch.
        var clockTimeAtStart: UInt32 = 1000
        var startedAt = ContinuousClock.now

        var clockTime: UInt32 {
            clockTimeAtStart + UInt32((ContinuousClock.now - startedAt).components.seconds)
        }
    }

    struct ScriptedFault {
        var fault: UniversalMessage_MessageFault_E
        var attachSessionInfo = false
        /// Seal the fault reply with AES-GCM, as newer firmware does.
        var encrypted = false
        /// Break the AES-GCM tag of an encrypted fault reply.
        var corruptTag = false
    }

    let vin: String
    var domains: [UniversalMessage_Domain: Domain] = [.vehicleSecurity: Domain(), .infotainment: Domain()]
    var vcsecKnowsKey = true
    var infotainmentKnowsKey = true
    /// Faults for the next signed requests, in order.
    var scriptedFaults: [ScriptedFault] = []
    /// Domains that never answer.
    var silentDomains: Set<UniversalMessage_Domain> = []
    /// Answer the next N session-info requests of a domain with WAIT/BUSY
    /// and no session info.
    var handshakeHiccups: [UniversalMessage_Domain: Int] = [:]
    /// Session info always reports counter 0, older than counters in use.
    var staleSessionCounter = false
    /// Echo a wrong `request_uuid` in replies to signed requests.
    var corruptRequestUUID = false
    /// Bare replies to the add-key request.
    var whitelistReplies: [VCSEC_FromVCSECMessage] = []
    /// The response plaintext of a successful GetVehicleData.
    var responsePlaintext = UpstreamResponseVector.responsePlaintext

    private(set) var addKeyRequests: [Data] = []
    private(set) var sessionInfoRequests: [UniversalMessage_Domain: Int] = [:]
    private(set) var signedRequests = 0

    init(vin: String = ProtocolDoc.vin) {
        self.vin = vin
    }

    /// Both domains know (or forget) the key.
    var keyOnWhitelist: Bool {
        get { vcsecKnowsKey && infotainmentKnowsKey }
        set {
            vcsecKnowsKey = newValue
            infotainmentKnowsKey = newValue
        }
    }

    func knowsKey(_ domain: UniversalMessage_Domain) -> Bool {
        domain == .vehicleSecurity ? vcsecKnowsKey : infotainmentKnowsKey
    }

    /// Starts a new epoch, as after a vehicle reboot: requests signed in the
    /// old one get INCORRECT_EPOCH with fresh session info attached.
    mutating func rotateEpoch(_ domain: UniversalMessage_Domain) {
        domains[domain]?.epoch = .random(count: 16)
        domains[domain]?.counter = 0
    }

    /// Whole reply messages for one whole request message.
    mutating func respond(to bytes: Data) throws -> [Data] {
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
        do {
            _ = try gcm.decrypt(
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
        if !scriptedFaults.isEmpty {
            let scripted = scriptedFaults.removeFirst()
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
        try seal(&reply, plaintext: responsePlaintext, request: request, requestHash: requestHash, fault: .rrorNone, gcm: gcm)
        return [try reply.serializedData()]
    }

    private func seal(
        _ reply: inout UniversalMessage_RoutableMessage,
        plaintext: Data,
        request: UniversalMessage_RoutableMessage,
        requestHash: Data,
        fault: UniversalMessage_MessageFault_E,
        gcm: TeslaGCM
    ) throws {
        let metadata = try SignatureMetadata.response(
            domain: reply.fromDestination.domain, vin: vin, counter: 1, flags: request.flags,
            requestHash: requestHash, fault: fault
        )
        let sealed = try gcm.encrypt(plaintext: plaintext, metadata: metadata.serialized)
        reply.flags = request.flags
        reply.protobufMessageAsBytes = sealed.ciphertext
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
actor MockLink: BLELink {
    nonisolated let events: AsyncStream<BLELinkEvent>
    private let sink: AsyncStream<BLELinkEvent>.Continuation

    private(set) var vehicle: FakeVehicle
    var maxWriteLength = 20
    var notifyChunkLength = 7
    var connectError: BLELinkError?
    var writeError: BLELinkError?
    /// Keep replies until `releaseHeld` (to reorder them).
    var holdReplies = false

    private(set) var isConnected = false
    private(set) var writes: [Data] = []
    private(set) var held: [Data] = []
    private(set) var disconnectCalls = 0
    private var outbound = FrameAssembler()

    init(vehicle: FakeVehicle = FakeVehicle()) {
        self.vehicle = vehicle
        (events, sink) = AsyncStream.makeStream(of: BLELinkEvent.self)
    }

    func connect(localName: String, timeout: Duration) async throws -> Int {
        if let connectError { throw connectError }
        guard localName == TeslaBLEConstants.localName(forVIN: vehicle.vin) else { throw BLELinkError.scanTimedOut }
        isConnected = true
        return maxWriteLength
    }

    func write(_ value: Data) async throws {
        if let writeError { throw writeError }
        guard isConnected else { throw BLELinkError.notConnected }
        precondition(value.count <= maxWriteLength, "write longer than the negotiated length")
        writes.append(value)
        for output in outbound.append(value) {
            guard case .message(let message) = output else { continue }
            for reply in try vehicle.respond(to: message) {
                if holdReplies { held.append(reply) } else { deliver(reply) }
            }
        }
    }

    func disconnect() async {
        isConnected = false
        disconnectCalls += 1
    }

    func update(_ body: @Sendable (inout FakeVehicle) -> Void) {
        body(&vehicle)
    }

    func set(holdReplies: Bool) { self.holdReplies = holdReplies }
    func set(writeError: BLELinkError?) { self.writeError = writeError }
    func set(connectError: BLELinkError?) { self.connectError = connectError }

    func releaseHeld(reversed: Bool = false) {
        let replies = reversed ? held.reversed() : held
        held = []
        replies.forEach(deliver)
    }

    /// One raw notification value.
    func inject(_ chunk: Data) {
        sink.yield(.received(chunk))
    }

    func deliver(_ message: Data) {
        for chunk in try! TeslaFraming.chunks(for: message, chunkLength: notifyChunkLength) {
            sink.yield(.received(chunk))
        }
    }

    func drop(reconnecting: Bool) {
        isConnected = false
        outbound.reset()
        sink.yield(.disconnected(reconnecting: reconnecting, reason: "test"))
    }

    func reconnect() {
        isConnected = true
        sink.yield(.reconnected(maxWriteLength: maxWriteLength))
    }
}

/// In-memory `TeslaKeyStore`.
final class InMemoryKeyStore: TeslaKeyStore, @unchecked Sendable {
    struct Locked: Error {}
    private let lock = NSLock()
    /// Every call throws, as the Keychain does while the phone is locked.
    var isLocked = false
    private var key: SoftwareKeyAgreementKey?
    private var vin: String?
    private var vehicleKeys: [String: Data] = [:]

    func clientKey() throws -> any KeyAgreementKey {
        if isLocked { throw Locked() }
        return lock.withLock {
            if let key { return key }
            let created = SoftwareKeyAgreementKey()
            key = created
            return created
        }
    }

    func pairedVIN() throws -> String? {
        if isLocked { throw Locked() }
        return lock.withLock { vin }
    }

    func setPairedVIN(_ vin: String) throws {
        if isLocked { throw Locked() }
        lock.withLock { self.vin = vin }
    }

    func vehiclePublicKey(vin: String, domain: UniversalMessage_Domain) throws -> Data? {
        if isLocked { throw Locked() }
        return lock.withLock { vehicleKeys["\(vin).\(domain.rawValue)"] }
    }

    func setVehiclePublicKey(_ key: Data, vin: String, domain: UniversalMessage_Domain) throws {
        if isLocked { throw Locked() }
        lock.withLock { vehicleKeys["\(vin).\(domain.rawValue)"] = key }
    }
}

extension TeslaVehicleClient {
    /// Ends the event stream and returns everything emitted so far.
    func drainEvents() async -> [TeslaClientEvent.Kind] {
        finishEvents()
        var kinds: [TeslaClientEvent.Kind] = []
        for await event in events { kinds.append(event.kind) }
        return kinds
    }
}

/// Polls `condition` until it holds or about two seconds pass.
func eventually(_ condition: () async -> Bool) async throws {
    for _ in 0..<200 {
        if await condition() { return }
        try await Task.sleep(for: .milliseconds(10))
    }
    Issue.record("condition never became true")
}
