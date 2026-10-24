// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TeslaBLE",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "TeslaBLE", targets: ["TeslaBLE"]),
        // The fake car, for tests only (TeslaBLETests and the app's test
        // target). Never link it into the app.
        .library(name: "TeslaBLETestSupport", targets: ["TeslaBLETestSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.38.1"),
    ],
    targets: [
        .target(
            name: "TeslaBLE",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ]
        ),
        .target(
            name: "TeslaBLETestSupport",
            dependencies: ["TeslaBLE"]
        ),
        .testTarget(
            name: "TeslaBLETests",
            dependencies: ["TeslaBLE", "TeslaBLETestSupport"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
