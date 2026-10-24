import CryptoKit
import Foundation
import Testing

extension SymmetricKey {
    var data: Data { withUnsafeBytes { Data($0) } }
}

/// Polls `condition` until it holds or about two seconds pass.
func eventually(_ condition: () async -> Bool) async throws {
    for _ in 0..<200 {
        if await condition() { return }
        try await Task.sleep(for: .milliseconds(10))
    }
    Issue.record("condition never became true")
}
