// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Timeline",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v16),
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
    .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "0.1.4"),
    .package(url: "https://github.com/mergesort/Boutique", from: "2.1.1"),
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
        .product(name: "Introspect", package: "SwiftUI-Introspect"),
        .product(name: "Boutique", package: "Boutique"),
      ]
    ),
    .testTarget(
      name: "TimelineTests",
      dependencies: ["Timeline"]
    ),
  ]
)
