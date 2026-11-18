import Foundation
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// #50, #101: the parked 胎壓 card: the drive screen's tire column without its title, the shared time line under the
/// car (L82), its words and what VoiceOver reads.
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

    static let canvas = DesignCanvas(screen: HUDRenderTests.Screen.iPhone844.size)

    @Test func words() {
        let zh = TireCopy(panel: Self.mixed, locale: Self.zh)
        #expect(PanelCard.tires.name(Self.zh) == "胎壓")
        #expect(zh.spoken == ["左前,42 psi", "右前,42 psi,18 分鐘前", "左後,41 psi,時間未知", "右後,尚無讀值"])
        #expect(zh.summary == "部分讀值時間未知")
        let en = TireCopy(panel: Self.mixed, locale: Self.en)
        #expect(en.spoken == ["Front left, 42 psi", "Front right, 42 psi, 18 min ago", "Rear left, 41 psi, time unknown",
                              "Rear right, no reading yet"])
        #expect(TireCopy(panel: .wheels(.noReadings), locale: Self.zh).summary == "尚無讀值")
        #expect(TireCopy(panel: Self.wheels([42, 42, 41, 42]), locale: Self.zh).summary == "3 分鐘前")
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

    // L82: the time line is centred on the car, its ink 14 below the car's, inside the panel's text column (598.5–768) in
    // both languages; the longest, English 「部分讀值時間未知」, takes two lines.
    @Test(arguments: [zh, en])
    func theTimeLineFitsUnderTheCar(locale: Locale) {
        let old = TireWheel(psi: 42, ageMinutes: 59, freshness: .old), fresh = TireWheel(psi: 42, ageMinutes: 1, freshness: .fresh)
        let unknown = TireWheel(psi: 42, ageMinutes: nil, freshness: .unknownTime)
        let days = TireWheel(psi: 42, ageMinutes: 10 * 1440, freshness: .old)
        let panels: [TirePanel] = [.wheels(.noReadings), Self.mixed, Self.wheels([42, 42, 41, 42]),
                                   .wheels(TireWheels(frontLeft: fresh, frontRight: old, rearLeft: fresh, rearRight: fresh)),
                                   .wheels(TireWheels(frontLeft: fresh, frontRight: days, rearLeft: fresh, rearRight: fresh)),
                                   .wheels(TireWheels(frontLeft: unknown, frontRight: unknown, rearLeft: unknown, rearRight: unknown))]
        for panel in panels {
            let summary = TireCopy(panel: panel, locale: locale).summary ?? ""
            #expect(!summary.isEmpty)
            let lines = TireColumnView.timeLines(summary, language: locale.identifier)
            #expect((1...2).contains(lines.count), "\(summary)")
            #expect(abs(lines[0].box.minY - (TireColumnView.carInkBottom + 14)) < 1e-6)
            for line in lines {
                #expect(line.box.minX >= DriveFrame.parkedRightTextX && line.box.maxX <= DriveFrame.parkedRight.maxX, "\(summary) \(line.box)")
                #expect(abs(line.box.midX - TireColumnView.carCenterX) < 1e-6)
                #expect(line.box.maxY <= DriveFrame.parkedRight.maxY)
            }
        }
        #expect(TireColumnView.timeLines("Some readings: time unknown", language: "en").count == 2)
    }

    // L42, #101: each wheel is one element, read as 「左前,42 psi」, never "—"; the time line is read once, after them; the
    // car is not read. The card's title button takes the column's own title.
    @Test func voiceOverReadsEachWheelAndTheTimeLineOnce() {
        guard case .wheels(let wheels) = Self.mixed else { return }
        let view = TireColumnView(wheels: wheels, canvas: Self.canvas, showsTitle: false,
                                  timeLine: TireCopy(panel: Self.mixed, locale: Self.zh).summary)
        let labels = DriveScreenAccessibilityTests.elementLabels(view, size: DesignCanvas.size)
        #expect(labels == ["左前,42 psi", "右前,42 psi,18 分鐘前", "左後,41 psi,時間未知", "右後,尚無讀值", "部分讀值時間未知"], "\(labels)")
    }

    @Test func notSupportedSaysSo() throws {
        let screen = HUDRenderTests.Screen.iPhone844
        let state = try #require(HUDRenderTests.parkedStates["tire-none"])
        let view = DriveScreen(state: state, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left,
                               rightInset: screen.right, bottomInset: screen.bottom)
        let labels = DriveScreenAccessibilityTests.elementLabels(view, size: screen.size)
        let title = try #require(labels.firstIndex(of: "胎壓，第 1 張，共 2 張"), "\(labels)")
        #expect(labels.firstIndex(of: "這台車沒有提供胎壓資料") == title + 1, "\(labels)")
    }
}
