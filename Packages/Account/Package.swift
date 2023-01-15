// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Account",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v16),
  ],
  products: [
    .library(
      name: "Account",
      targets: ["Account"]
    ),
  ],
  dependencies: [
    .package(name: "Network", path: "../Network"),
    .package(name: "Models", path: "../Models"),
    .package(name: "Status", path: "../Status"),
  ],
  targets: [
    .target(
      name: "Account",
      dependencies: [
        .product(name: "Network", package: "Network"),
        .product(name: "Models", package: "Models"),
        .product(name: "Status", package: "Status"),
      ]
    ),
    .testTarget(
      name: "AccountTests",
      dependencies: ["Account"]
    ),
  ]
)
