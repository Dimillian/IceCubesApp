// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Conversations",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "Conversations",
      targets: ["Conversations"]
    ),
  ],
  dependencies: [
    .package(name: "Models", path: "../Models"),
    .package(name: "Network", path: "../Network"),
    .package(name: "Env", path: "../Env"),
    .package(name: "DesignSystem", path: "../DesignSystem"),
  ],
  targets: [
    .target(
      name: "Conversations",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Network", package: "Network"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),
      ]
    ),
  ]
)
