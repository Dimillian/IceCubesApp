// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Env",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v16),
  ],
  products: [
    .library(
      name: "Env",
      targets: ["Env"]
    ),
  ],
  dependencies: [
    .package(name: "Models", path: "../Models"),
    .package(name: "Network", path: "../Network"),
  ],
  targets: [
    .target(
      name: "Env",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Network", package: "Network"),
      ]
    ),
  ]
)
