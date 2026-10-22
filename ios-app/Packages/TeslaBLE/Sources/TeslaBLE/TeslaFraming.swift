import Foundation

/// BLE message framing (vehicle-command pkg/connector/ble/ble.go `Send`,
/// `rx` and `flush`; same wire format as Moblin
/// Moblin/Integrations/Tesla/TeslaVehicle.swift `sendData` / `handleData`):
/// each message is prefixed with its length as 2 bytes big-endian, and the
/// framed bytes are split into writes of at most the link's block length.
public enum TeslaFraming {
    public enum Error: Swift.Error, Equatable, Sendable {
        /// Longer than `TeslaBLEConstants.maxMessageLength`.
        case messageTooLong(Int)
        case invalidChunkLength(Int)
    }

    /// Frames `message` and splits it into chunks of at most `chunkLength` bytes.
    public static func chunks(for message: Data, chunkLength: Int) throws -> [Data] {
        guard message.count <= TeslaBLEConstants.maxMessageLength else {
            throw Error.messageTooLong(message.count)
        }
        guard chunkLength > 0 else { throw Error.invalidChunkLength(chunkLength) }
        let framed = Data([UInt8(message.count >> 8), UInt8(message.count & 0xff)]) + message
        return stride(from: 0, to: framed.count, by: chunkLength).map { offset in
            Data(framed[offset..<min(offset + chunkLength, framed.count)])
        }
    }
}

/// Reassembles RX notification values into whole messages, following
/// vehicle-command's `rx`/`flush`: a gap of more than `chunkGap` since the
/// previous chunk discards a half-received message, a length prefix over
/// `TeslaBLEConstants.maxMessageLength` discards the buffer, and one chunk may
/// complete several messages.
public struct FrameAssembler: Sendable {
    /// vehicle-command `rxTimeout`.
    public static let chunkGap: Duration = .seconds(1)

    public enum Output: Sendable, Equatable {
        case message(Data)
        /// Buffered bytes thrown away.
        case discarded(DiscardReason)
    }

    public enum DiscardReason: Sendable, Equatable {
        /// The length prefix exceeded the maximum message length.
        case tooLong(length: Int)
        /// A partial message was abandoned after a gap of more than `chunkGap`.
        case stale(bytes: Int)
    }

    private var buffer = Data()
    private var lastChunkAt: ContinuousClock.Instant?

    public init() {}

    /// Appends one notification value and returns what it completed.
    public mutating func append(_ chunk: Data, at now: ContinuousClock.Instant = .now) -> [Output] {
        var output: [Output] = []
        if let lastChunkAt, now - lastChunkAt > Self.chunkGap, !buffer.isEmpty {
            output.append(.discarded(.stale(bytes: buffer.count)))
            buffer = Data()
        }
        lastChunkAt = now
        buffer.append(chunk)

        while buffer.count >= 2 {
            let start = buffer.startIndex
            let length = Int(buffer[start]) << 8 | Int(buffer[start + 1])
            guard length <= TeslaBLEConstants.maxMessageLength else {
                output.append(.discarded(.tooLong(length: length)))
                buffer = Data()
                break
            }
            guard buffer.count >= 2 + length else { break }
            output.append(.message(Data(buffer[(start + 2)..<(start + 2 + length)])))
            buffer = Data(buffer[(start + 2 + length)...])
        }
        return output
    }

    public mutating func reset() {
        buffer = Data()
        lastChunkAt = nil
    }
}
