// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Explore",
  platforms: [
    .iOS(.v16),
  ],
  products: [
    .library(
      name: "Explore",
      targets: ["Explore"]),
  ],
  dependencies: [
    .package(name: "Network", path: "../Network"),
    .package(name: "Models", path: "../Models"),
    .package(name: "Env", path: "../Env"),
    .package(name: "Status", path: "../Status"),
    .package(url: "https://github.com/markiv/SwiftUI-Shimmer", exact: "1.1.0")
  ],
  targets: [
    .target(
      name: "Explore",
      dependencies: [
        .product(name: "Network", package: "Network"),
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "Status", package: "Status"),
        .product(name: "Shimmer", package: "SwiftUI-Shimmer")
      ])
  ]
)

