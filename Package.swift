// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "embedded-swift-utilities",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .watchOS(.v10),
    .tvOS(.v17),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "EmbeddedSwiftUtilities",
      targets: ["EmbeddedSwiftUtilities"]
    )
  ],
  targets: [
    .target(
      name: "EmbeddedSwiftUtilities",
      swiftSettings: [
        .enableExperimentalFeature("Embedded", .when(platforms: [.wasi])),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("StrictConcurrency"),
        .define("CLIENT", .when(platforms: [.wasi])),
        .define("SERVER", .when(platforms: [.macOS, .linux, .windows])),
      ]
    ),
    .testTarget(
      name: "EmbeddedSwiftUtilitiesTests",
      dependencies: ["EmbeddedSwiftUtilities"]
    ),
  ]
)
