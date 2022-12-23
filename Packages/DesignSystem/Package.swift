// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DesignSystem",
  platforms: [
    .iOS(.v16),
  ],
  products: [
    .library(
      name: "DesignSystem",
      targets: ["DesignSystem"]),
  ],
  dependencies: [
    .package(name: "Models", path: "../Models"),
    .package(name: "Env", path: "../Env"),
    .package(url: "https://github.com/markiv/SwiftUI-Shimmer", exact: "1.1.0")],
  targets: [
    .target(
      name: "DesignSystem",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "Shimmer", package: "SwiftUI-Shimmer")
      ]),
  ]
)

