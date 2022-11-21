// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Timeline",
  platforms: [
    .iOS(.v16),
  ],
  products: [
    .library(
      name: "Timeline",
      targets: ["Timeline"]),
  ],
  dependencies: [
    .package(name: "Network", path: "../Network"),
  ],
  targets: [
    .target(
      name: "Timeline",
      dependencies: [
        .product(name: "Network", package: "Network")
      ]),
    .testTarget(
      name: "TimelineTests",
      dependencies: ["Timeline"]),
  ]
)
