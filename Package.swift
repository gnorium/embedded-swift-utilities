// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EmbeddedSwiftUtilities",
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
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug)),
            ]
        ),
        .testTarget(
            name: "EmbeddedSwiftUtilitiesTests",
            dependencies: ["EmbeddedSwiftUtilities"]
        ),
    ]
)
