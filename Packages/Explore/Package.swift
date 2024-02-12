// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Explore",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "Explore",
      targets: ["Explore"]
    ),
  ],
  dependencies: [
    .package(name: "Account", path: "../Account"),
    .package(name: "Network", path: "../Network"),
    .package(name: "Models", path: "../Models"),
    .package(name: "Env", path: "../Env"),
    .package(name: "StatusKit", path: "../StatusKit"),
    .package(name: "DesignSystem", path: "../DesignSystem"),
  ],
  targets: [
    .target(
      name: "Explore",
      dependencies: [
        .product(name: "Account", package: "Account"),
        .product(name: "Network", package: "Network"),
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "StatusKit", package: "StatusKit"),
        .product(name: "DesignSystem", package: "DesignSystem"),
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),
      ]
    ),
  ]
)
