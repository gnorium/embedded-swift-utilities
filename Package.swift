// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "embedded-swift-utilities",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "EmbeddedSwiftUtilities",
            targets: ["EmbeddedSwiftUtilities"]
        ),
    ],
    targets: [
        .target(
            name: "EmbeddedSwiftUtilities",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EmbeddedSwiftUtilitiesTests",
            dependencies: ["EmbeddedSwiftUtilities"]
        ),
    ]
)
