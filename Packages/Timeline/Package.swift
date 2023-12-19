// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Timeline",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "Timeline",
      targets: ["Timeline"]
    ),
  ],
  dependencies: [
    .package(name: "Network", path: "../Network"),
    .package(name: "Models", path: "../Models"),
    .package(name: "Env", path: "../Env"),
    .package(name: "Status", path: "../Status"),
    .package(name: "DesignSystem", path: "../DesignSystem"),
    .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "1.0.0"),
    .package(url: "https://github.com/mergesort/Bodega", exact: "2.1.0"),
  ],
  targets: [
    .target(
      name: "Timeline",
      dependencies: [
        .product(name: "Network", package: "Network"),
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "Status", package: "Status"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect"),
        .product(name: "Bodega", package: "Bodega"),
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),
      ]
    ),
    .testTarget(
      name: "TimelineTests",
      dependencies: ["Timeline"]
    ),
  ]
)
