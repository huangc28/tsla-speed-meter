// swift-tools-version: 6.0
import PackageDescription

// Pure HUD logic: no UIKit, SwiftUI or CoreBluetooth, so `swift test` runs on the Mac.
let package = Package(
    name: "HUDCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HUDCore", targets: ["HUDCore"]),
    ],
    targets: [
        .target(name: "HUDCore"),
        .testTarget(name: "HUDCoreTests", dependencies: ["HUDCore"]),
    ]
)
