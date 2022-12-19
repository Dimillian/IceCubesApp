// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Status",
  platforms: [
    .iOS(.v16),
  ],
  products: [
    .library(
      name: "Status",
      targets: ["Status"]),
  ],
  dependencies: [
    .package(name: "Models", path: "../Models"),
    .package(name: "Routeur", path: "../Routeur"),
    .package(name: "DesignSystem", path: "../DesignSystem"),
    .package(url: "https://github.com/markiv/SwiftUI-Shimmer", exact: "1.1.0")
  ],
  targets: [
    .target(
      name: "Status",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Routeur", package: "Routeur"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "Shimmer", package: "SwiftUI-Shimmer")
      ]),
  ]
)

