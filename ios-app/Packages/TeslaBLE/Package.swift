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
        .testTarget(
            name: "TeslaBLETests",
            dependencies: ["TeslaBLE"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
