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

    /// The accessibility elements `view` exposes, with their frames in the window.
    static func elements(_ view: some View, size: CGSize) -> [(label: String, frame: CGRect)] {
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

        var found: [(label: String, frame: CGRect)] = []
        var seen = Set<ObjectIdentifier>()
        func walk(_ object: NSObject) {
            guard seen.insert(ObjectIdentifier(object)).inserted else { return }
            if object.isAccessibilityElement {
                found.append((object.accessibilityLabel ?? "", object.accessibilityFrame))
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

    // #49: battery / range is one element, named, with the shown text as its value.
    @Test func batteryBlockIsOneElement() {
        let screen = HUDRenderTests.Screen.iPhone667
        let state = HUDRenderTests.state([.authorization(.authorized)],
                                         car: HUDRenderTests.driving(88, gear: .drive, battery: (100, 520)))
        let view = DriveScreen(state: state, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left,
                               rightInset: screen.right, bottomInset: screen.bottom)
        let labels = Self.elementLabels(view, size: screen.size)
        #expect(labels.filter { $0 == "電量與續航" }.count == 1, "\(labels)")
        #expect(!labels.contains { $0.contains("520") }, "\(labels)")
    }
}
