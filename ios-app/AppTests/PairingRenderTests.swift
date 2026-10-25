import Foundation
import HUDCore
import SwiftUI
import Testing
import TeslaBLE
import UIKit
@testable import SpeedHUD

/// Renders the pairing screens (S13–S17) to PNGs and compares the main ones against
/// committed references, like `HUDRenderTests`: review PNGs (2x) in `Snapshots/`,
/// references (1x) in `AppTests/References/`, re-recorded with `TEST_RUNNER_RECORD_REFERENCES=1`.
///
/// They render in a window, not with `ImageRenderer`, which draws UIKit-backed views (the
/// VIN field, the scroll view) as placeholders.
@MainActor
struct PairingRenderTests {
    typealias Screen = HUDRenderTests.Screen

    /// A synthetic VIN (not a real car) whose 9th character checks out, and the same one broken.
    static let goodVIN = "5YJ3E1EA8KF000001"
    static let brokenVIN = "5YJ3E1EA1KF000001"

    static let cases: [(name: String, step: PairingFlow.Step, typed: String, parked: Bool, screen: Screen, locale: String)] = [
        ("pair-start-844-zh", .start, "", false, .iPhone844, "zh-Hant"),
        ("pair-start-parked-844-zh", .start, "", true, .iPhone844, "zh-Hant"),
        ("pair-start-667-zh", .start, "", true, .iPhone667, "zh-Hant"),
        ("pair-start-667", .start, "", true, .iPhone667, "en"),
        ("pair-vin-empty-844-zh", .vin, "", true, .iPhone844, "zh-Hant"),
        ("pair-vin-partial-844-zh", .vin, "5YJ3E1EA8KF0", true, .iPhone844, "zh-Hant"),
        ("pair-vin-complete-844-zh", .vin, goodVIN, true, .iPhone844, "zh-Hant"),
        ("pair-vin-check-digit-844-zh", .vin, brokenVIN, true, .iPhone844, "zh-Hant"),
        ("pair-vin-q-844-zh", .vin, "5YJ3E1EAQ", true, .iPhone844, "zh-Hant"),
        ("pair-vin-check-digit-667-zh", .vin, brokenVIN, true, .iPhone667, "zh-Hant"),
        ("pair-vin-check-digit-667", .vin, brokenVIN, true, .iPhone667, "en"),
        ("pair-searching-844-zh", .finding(matched: false), goodVIN, true, .iPhone844, "zh-Hant"),
        ("pair-match-844-zh", .finding(matched: true), goodVIN, true, .iPhone844, "zh-Hant"),
        ("pair-match-667", .finding(matched: true), goodVIN, true, .iPhone667, "en"),
        ("pair-key-card-844-zh", .keyCard, goodVIN, true, .iPhone844, "zh-Hant"),
        ("pair-key-card-667", .keyCard, goodVIN, true, .iPhone667, "en"),
        ("pair-reading-844-zh", .reading, goodVIN, true, .iPhone844, "zh-Hant"),
        ("pair-paired-844-zh", .paired(PairingPreview(speedKilometersPerHour: 0, gear: .park, batteryPercent: 72)),
         goodVIN, true, .iPhone844, "zh-Hant"),
        ("pair-paired-667", .paired(PairingPreview(speedKilometersPerHour: 0, gear: .park, batteryPercent: 100)),
         goodVIN, true, .iPhone667, "en"),
        ("pair-failed-844-zh", .failed(.link(.scanTimedOut)), goodVIN, true, .iPhone844, "zh-Hant"),
    ]

    /// Pinned by references: S13, S14 empty / partial / complete / check-digit warning, S15 with
    /// the match, S16, S17 success.
    nonisolated static let referenceNames = ["pair-start-844-zh", "pair-vin-empty-844-zh", "pair-vin-partial-844-zh",
                                             "pair-vin-complete-844-zh", "pair-vin-check-digit-844-zh",
                                             "pair-match-844-zh", "pair-key-card-844-zh", "pair-paired-844-zh"]

    static func render(_ name: String, scale: CGFloat) throws -> UIImage {
        let item = try #require(cases.first { $0.name == name })
        let view = PairingScreen(step: item.step, entry: VINEntry(item.typed), parkedConfirmed: item.parked,
                                 screen: item.screen.size, leftInset: item.screen.left, rightInset: item.screen.right,
                                 bottomInset: item.screen.bottom, typed: .constant(VINEntry(item.typed).formatted),
                                 focusesField: false)
            .environment(\.locale, Locale(identifier: item.locale))
            .transaction { $0.animation = nil }
        let image = try renderInWindow(view, size: item.screen.size, scale: scale)
        #expect(image.size == item.screen.size)
        return image
    }

    /// Lays `view` out in a window of `size`, with no safe area, and draws it.
    static func renderInWindow(_ view: some View, size: CGSize, scale: CGFloat) throws -> UIImage {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        let host = UIHostingController(rootView: view.ignoresSafeArea())
        host.safeAreaRegions = []
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            _ = host.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
    }

    // Two renders of the same screen are the same, so the references can be pinned.
    @Test func rendersAreRepeatable() throws {
        for name in Self.referenceNames {
            let a = try HUDRenderTests.rgba(try #require(Self.render(name, scale: 1).cgImage))
            let b = try HUDRenderTests.rgba(try #require(Self.render(name, scale: 1).cgImage))
            #expect(HUDRenderTests.differingPixels(a, b) == 0, "\(name)")
        }
    }

    @Test func rendersPairingScreensToPNG() throws {
        try FileManager.default.createDirectory(at: HUDRenderTests.snapshotDirectory, withIntermediateDirectories: true)
        for item in Self.cases {
            let data = try #require(Self.render(item.name, scale: 2).pngData())
            try data.write(to: HUDRenderTests.snapshotDirectory.appendingPathComponent("\(item.name).png"))
        }
    }

    @Test(arguments: referenceNames)
    func matchesReference(_ name: String) throws {
        let image = try Self.render(name, scale: 1)
        let url = HUDRenderTests.referenceDirectory.appendingPathComponent("\(name).png")
        if HUDRenderTests.recordingReferences {
            try FileManager.default.createDirectory(at: HUDRenderTests.referenceDirectory, withIntermediateDirectories: true)
            try #require(image.pngData()).write(to: url)
            return
        }
        let reference = try #require(UIImage(contentsOfFile: url.path)?.cgImage,
                                     "No reference \(name).png; record with TEST_RUNNER_RECORD_REFERENCES=1")
        let actual = try #require(image.cgImage)
        let expected = try HUDRenderTests.rgba(reference), rendered = try HUDRenderTests.rgba(actual)
        #expect(reference.width == actual.width && reference.height == actual.height, "size changed")
        guard expected.count == rendered.count else { return }
        let differing = HUDRenderTests.differingPixels(expected, rendered)
        if differing > HUDRenderTests.maxDifferingPixels {
            try FileManager.default.createDirectory(at: HUDRenderTests.snapshotDirectory, withIntermediateDirectories: true)
            try image.pngData()?.write(to: HUDRenderTests.snapshotDirectory.appendingPathComponent("\(name)-actual.png"))
        }
        #expect(differing <= HUDRenderTests.maxDifferingPixels,
                "\(name): \(differing) pixels differ from the reference; see Snapshots/\(name)-actual.png")
    }
}
