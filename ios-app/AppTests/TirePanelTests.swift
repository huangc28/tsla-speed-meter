import Foundation
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// #50: the parked screen's tire panel, ported from the master's `tirePanel`: its geometry, the
/// list fallback, its words and what VoiceOver reads.
@MainActor
struct TirePanelTests {
    nonisolated static let zh = Locale(identifier: "zh-Hant"), en = Locale(identifier: "en")

    static func wheels(_ psi: [Int?], minutes: Int? = 3) -> TirePanel {
        let w = psi.map { $0.map { TireWheel(psi: $0, ageMinutes: minutes, freshness: .fresh) } ?? .missing }
        return .wheels(TireWheels(frontLeft: w[0], frontRight: w[1], rearLeft: w[2], rearRight: w[3]))
    }

    static let mixed = TirePanel.wheels(TireWheels(
        frontLeft: TireWheel(psi: 42, ageMinutes: 1, freshness: .fresh),
        frontRight: TireWheel(psi: 42, ageMinutes: 18, freshness: .old),
        rearLeft: TireWheel(psi: 41, ageMinutes: nil, freshness: .unknownTime),
        rearRight: .missing))

    // The master's `tireGeometry(184)` and `(165)`.
    @Test func geometryFollowsTheMaster() {
        let big = TireGeometry(size: CGSize(width: 184, height: 288))
        #expect(big.carSize == CGSize(width: 104, height: 208) && big.carTop == 30)
        #expect(abs(big.labelRight - 58.72) < 1e-9 && abs(big.column - 58.72) < 1e-9 && abs(big.labelLeft - 125.28) < 1e-9)
        #expect(abs(big.frontBottomY - 61.52) < 1e-9 && abs(big.rearTop - 189.84) < 1e-9 && big.summaryTop == 254)
        let small = TireGeometry(size: CGSize(width: 165, height: 272))
        #expect(small.carSize == CGSize(width: 94, height: 188) && small.carTop == 34)
        #expect(abs(small.column - 52.42) < 1e-9 && abs(small.labelLeft - 112.58) < 1e-9)
        #expect(abs(small.frontBottomY - 61.72) < 1e-9 && abs(small.rearTop - 179.24) < 1e-9 && small.summaryTop == 238)
    }

    @Test func words() {
        let zh = TireCopy(panel: Self.mixed, locale: Self.zh)
        #expect(zh.title == "胎壓")
        #expect(zh.spoken == ["左前,42 psi", "右前,42 psi,18 分鐘前", "左後,41 psi,時間未知", "右後,尚無讀值"])
        #expect(zh.summary == "部分讀值時間未知")
        let en = TireCopy(panel: Self.mixed, locale: Self.en)
        #expect(en.spoken == ["Front left, 42 psi", "Front right, 42 psi, 18 min ago", "Rear left, 41 psi, time unknown",
                              "Rear right, no reading yet"])
        #expect(TireCopy(panel: .wheels(.noReadings), locale: Self.zh).summary == "尚無讀值")
        #expect(TireCopy(panel: Self.wheels([42, 42, 41, 42]), locale: Self.zh).summary == "3 分鐘前")
        #expect(TireCopy(panel: .notSupported, locale: Self.zh).notSupported == "這台車沒有提供胎壓資料")
    }

    @Test func sharedTimeLineWording() {
        func line(_ summary: TireSummary) -> String? {
            let old = TireWheel(psi: 42, ageMinutes: 125, freshness: .old)
            let fresh = TireWheel(psi: 42, ageMinutes: 1, freshness: .fresh)
            let panel: TirePanel = switch summary {
            case .age(_, true): .wheels(TireWheels(frontLeft: fresh, frontRight: old, rearLeft: fresh, rearRight: fresh))
            default: .wheels(TireWheels(frontLeft: old, frontRight: old, rearLeft: old, rearRight: old))
            }
            return TireCopy(panel: panel, locale: Self.zh).summary
        }
        #expect(line(.age(minutes: 125, partial: true)) == "部分讀值 2 小時前")
        #expect(line(.age(minutes: 125, partial: false)) == "2 小時前")
        #expect(AgeText.text(minutes: 0, locale: Self.zh) == "0 分鐘前")
        #expect(AgeText.text(minutes: 59, locale: Self.zh) == "59 分鐘前")
        #expect(AgeText.text(minutes: 1440, locale: Self.zh) == "1 天前")
        #expect(AgeText.text(minutes: 1440, locale: Self.en) == "1 day ago")
        #expect(AgeText.text(minutes: 3 * 1440, locale: Self.en) == "3 days ago")
    }

    // The master's `tireNeedsList`: the diagram holds every reading and time line at the default
    // text size, in both languages and both widths.
    @Test(arguments: [184.0, 165.0], [zh, en])
    func theDiagramFitsAtTheDefaultTextSize(width: CGFloat, locale: Locale) {
        let geometry = TireGeometry(size: CGSize(width: width, height: width < 184 ? 272 : 288))
        for panel in [Self.wheels([42, 42, 41, 42]), Self.mixed, .wheels(.noReadings), Self.wheels([99, 99, 99, 99], minutes: 2000)] {
            #expect(!TirePanelView.needsList(TireCopy(panel: panel, locale: locale), geometry: geometry, textScale: 1), "\(panel)")
        }
    }

    // A reading wider than its column (large text at 165, as in the master's `A-v-667-tire-list`),
    // or a time line over two lines, switches to the list.
    @Test func theListTakesOverWhenTheDiagramDoesNotFit() {
        let small = TireGeometry(size: CGSize(width: 165, height: 272))
        #expect(TirePanelView.needsList(TireCopy(panel: Self.wheels([42, 42, 41, 42]), locale: Self.zh), geometry: small, textScale: 1.3))
        #expect(TirePanelView.needsList(TireCopy(panel: Self.wheels([142, 42, 41, 42]), locale: Self.zh), geometry: small, textScale: 1))
    }

    static func panel(_ panel: TirePanel, width: CGFloat, scale: CGFloat = 1, locale: Locale = zh) -> some View {
        TirePanelView(panel: panel, size: CGSize(width: width, height: width < 184 ? 272 : 288), textScale: scale)
            .environment(\.locale, locale)
    }

    // L42: each wheel is one element, read as 「左前,42 psi」, never "—"; the shared time line and
    // the car are not read.
    @Test(arguments: [false, true])
    func voiceOverReadsEachWheel(asList: Bool) {
        let size = CGSize(width: 165, height: 272)
        let labels = DriveScreenAccessibilityTests.elementLabels(Self.panel(Self.mixed, width: 165, scale: asList ? 1.3 : 1), size: size)
        for sentence in ["左前,42 psi", "右前,42 psi,18 分鐘前", "左後,41 psi,時間未知", "右後,尚無讀值"] {
            #expect(labels.filter { $0 == sentence }.count == 1, "\(sentence) in \(labels)")
        }
        #expect(labels.contains("胎壓"), "\(labels)")
        #expect(!labels.contains { $0.contains("—") || $0.contains("部分讀值") }, "\(labels)")
    }

    @Test func notSupportedSaysSo() {
        let labels = DriveScreenAccessibilityTests.elementLabels(Self.panel(.notSupported, width: 184), size: CGSize(width: 184, height: 288))
        #expect(labels == ["胎壓", "這台車沒有提供胎壓資料"], "\(labels)")
    }

    /// The list scrolls, so it renders in a window (`ImageRenderer` draws scroll views as placeholders).
    nonisolated static let listReference = "parked-tire-list-667-zh"

    @Test func listMatchesReference() throws {
        let view = Self.panel(.wheels(TireWheels(
            frontLeft: TireWheel(psi: 42, ageMinutes: 3, freshness: .fresh), frontRight: TireWheel(psi: 42, ageMinutes: 3, freshness: .fresh),
            rearLeft: TireWheel(psi: 41, ageMinutes: 3, freshness: .fresh), rearRight: .missing)), width: 165, scale: 1.3)
            .transaction { $0.animation = nil }
        let size = CGSize(width: 165, height: 272)
        try FileManager.default.createDirectory(at: HUDRenderTests.snapshotDirectory, withIntermediateDirectories: true)
        try PairingRenderTests.renderInWindow(view, size: size, scale: 2).pngData()?
            .write(to: HUDRenderTests.snapshotDirectory.appendingPathComponent("\(Self.listReference).png"))
        let image = try PairingRenderTests.renderInWindow(view, size: size, scale: 1)
        let url = HUDRenderTests.referenceDirectory.appendingPathComponent("\(Self.listReference).png")
        if HUDRenderTests.recordingReferences {
            try #require(image.pngData()).write(to: url)
            return
        }
        let reference = try #require(UIImage(contentsOfFile: url.path)?.cgImage,
                                     "No reference \(Self.listReference).png; record with TEST_RUNNER_RECORD_REFERENCES=1")
        let differing = HUDRenderTests.differingPixels(try HUDRenderTests.rgba(reference), try HUDRenderTests.rgba(try #require(image.cgImage)))
        #expect(differing <= HUDRenderTests.maxDifferingPixels, "\(differing) pixels differ from the reference")
    }
}
