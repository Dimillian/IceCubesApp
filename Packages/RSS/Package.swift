// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "RSS",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17),
    .visionOS(.v1),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "RSS",
      targets: ["RSS"]),
  ],
  dependencies: [
    .package(name: "DesignSystem", path: "../DesignSystem"),
    .package(name: "StatusKit", path: "../StatusKit"),
    .package(url: "https://github.com/Ranchero-Software/RSParser.git", from: "2.0.3"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "RSS",
      dependencies: [
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "StatusKit", package: "StatusKit"),
        .product(name: "RSParser", package: "RSParser"),
      ],
      resources: [
        .process("Models/RSSModel.xcdatamodeld"), // Process the model
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),
        .unsafeFlags(["-enable-bare-slash-regex"]),
      ]
    ),
    .testTarget(
      name: "RSSTests",
      dependencies: ["RSS"],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),
        .unsafeFlags(["-enable-bare-slash-regex"]),
      ]
    ),
  ]
)
