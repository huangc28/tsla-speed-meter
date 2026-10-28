import Darwin
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// What VoiceOver reads on the drive screen (L81, L87), read from the hosted views' accessibility
/// elements: the icon-only chip speaks its words, and the GPS cue is never an element of its own.
@MainActor
struct DriveScreenAccessibilityTests {
    /// The labels of the accessibility elements `view` exposes, hosted in a window in zh-Hant.
    static func elementLabels(_ view: some View, size: CGSize) -> [String] {
        elements(view, size: size).map(\.label)
    }

    /// The accessibility elements `view` exposes, with their values and frames in the window.
    static func elements(_ view: some View, size: CGSize) -> [(label: String, value: String, frame: CGRect)] {
        // SwiftUI builds its accessibility elements only while accessibility is on in the process.
        if let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
           let symbol = dlsym(library, "_AXSApplicationAccessibilitySetEnabled") {
            typealias SetEnabled = @convention(c) (Bool) -> Void
            unsafeBitCast(symbol, to: SetEnabled.self)(true)
        }
        let host = UIHostingController(rootView: view.environment(\.locale, Locale(identifier: "zh-Hant")))
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        var found: [(label: String, value: String, frame: CGRect)] = []
        var seen = Set<ObjectIdentifier>()
        func walk(_ object: NSObject) {
            guard seen.insert(ObjectIdentifier(object)).inserted else { return }
            if object.isAccessibilityElement {
                found.append((object.accessibilityLabel ?? "", object.accessibilityValue ?? "", object.accessibilityFrame))
                return
            }
            for element in object.accessibilityElements as? [NSObject] ?? [] { walk(element) }
            let count = object.accessibilityElementCount()
            if count != NSNotFound {
                for i in 0..<count { (object.accessibilityElement(at: i) as? NSObject).map(walk) }
            }
            for subview in (object as? UIView)?.subviews ?? [] { walk(subview) }
        }
        walk(host.view)
        return found
    }

    @Test(arguments: [
        (SourceStatus.valid(.carBluetooth), "車速來源:車輛藍牙"),
        (.gpsFallback, "車速來源:GPS · 藍牙資料過期"),
        (.valid(.gps), "車速來源:GPS"),
        (.waiting, "車速來源:等待車速訊號"),
        (.searchingGPS, "車速來源:搜尋 GPS 訊號…"),
        (.speedUnavailable, "車速來源:車速暫不可用"),
        (.gpsUnavailable, "車速來源:GPS 不可用"),
    ])
    func chipSpeaksItsWords(status: SourceStatus, label: String) {
        #expect(Self.elementLabels(SourceIconChip(status: status), size: CGSize(width: 200, height: 60)) == [label])
    }

    // The GPS cue is drawn, but the gauge is one element, the whole gauge, with the speed
    // sentence (L87): the cue never becomes an element or carries the label.
    @Test func gpsCueIsNotAnElement() throws {
        let state = HUDRenderTests.state([.authorization(.authorized), HUDRenderTests.gps(88)])
        #expect(GaugeLabels(state: state, geometry: GaugeGeometry(size: 300)).gpsCue != nil)
        let elements = Self.elements(GaugeView(state: state, size: 300), size: CGSize(width: 300, height: 300))
        #expect(elements.map(\.label) == [HUDAccessibility.speedLabel(for: state)], "\(elements)")
        #expect(elements.first?.frame.size == CGSize(width: 300, height: 300), "\(elements)")
    }

    // #48: the gear row is one element of its own, read as 「檔位 D」; the gauge keeps the speed.
    @Test func gearRowIsOneElement() {
        let screen = HUDRenderTests.Screen.iPhone844
        let state = HUDRenderTests.state([.authorization(.authorized)], car: HUDRenderTests.driving(88, gear: .drive))
        let view = DriveScreen(state: state, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left,
                               rightInset: screen.right, bottomInset: screen.bottom)
        let labels = Self.elementLabels(view, size: screen.size)
        #expect(labels.filter { $0 == "檔位 D" }.count == 1, "\(labels)")
        #expect(labels.contains(HUDAccessibility.speedLabel(for: state)), "\(labels)")
    }

    // #49: battery / range is one element, named, with the shown text as its value; with no
    // value (waiting or stale) it says so in words, never "—% / — km".
    @Test(arguments: [(BatteryBlock.value(percent: 100, range: 520), "100% / 520 km"),
                      (.waiting, "電量尚無讀值"), (.stale(percent: 72, range: 315, ageMinutes: 3), "電量尚無讀值")])
    func batteryBlockIsOneElement(block: BatteryBlock, value: String) {
        let screen = HUDRenderTests.Screen.iPhone667
        var state = HUDRenderTests.state([.authorization(.authorized)], car: HUDRenderTests.driving(88, gear: .drive))
        state.battery = block
        let view = DriveScreen(state: state, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left,
                               rightInset: screen.right, bottomInset: screen.bottom)
        let battery = Self.elements(view, size: screen.size).filter { $0.label == "電量與續航" }
        #expect(battery.map(\.value) == [value], "\(battery)")
    }

    // #50: parked, a stale battery keeps its value and says its age; 「P 檔」 is read with the reason.
    @Test func parkedReadsTheStaleBatteryAndPGear() throws {
        let screen = HUDRenderTests.Screen.iPhone844
        let stale = try #require(HUDRenderTests.parkedStates["stale"])
        let view = DriveScreen(state: stale, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left,
                               rightInset: screen.right, bottomInset: screen.bottom)
        let elements = Self.elements(view, size: screen.size)
        #expect(elements.filter { $0.label == "電量與續航" }.map(\.value) == ["72% / 315 km, 3 分鐘前"], "\(elements)")
        #expect(elements.contains { $0.label == "左前,42 psi,18 分鐘前" }, "\(elements)")

        let pGear = try #require(HUDRenderTests.parkedStates["p-unknown"])
        #expect(HUDAccessibility.speedLabel(for: pGear) == String(localized: "Gear P, \(String(localized: "Speed unavailable"))"))
        let labels = Self.elementLabels(GaugeView(state: pGear, size: 300), size: CGSize(width: 300, height: 300))
        #expect(labels == [HUDAccessibility.speedLabel(for: pGear)], "\(labels)")
    }
}
