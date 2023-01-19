// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Network",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v16),
  ],
  products: [
    .library(
      name: "Network",
      targets: ["Network"]
    ),
  ],
  dependencies: [
    .package(name: "Models", path: "../Models"),
  ],
  targets: [
    .target(
      name: "Network",
      dependencies: [
        .product(name: "Models", package: "Models"),
      ]
    ),
    .testTarget(
      name: "NetworkTests",
      dependencies: ["Network"]
    ),
  ]
)
