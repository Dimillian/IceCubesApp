// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Routeur",
  platforms: [
    .iOS(.v16),
  ],
  products: [
    .library(
      name: "Routeur",
      targets: ["Routeur"]),
  ],
  dependencies: [
    .package(name: "Models", path: "../Models")
  ],
  targets: [
    .target(
      name: "Routeur",
      dependencies: [
        .product(name: "Models", package: "Models"),
      ]),
    .testTarget(
      name: "RouteurTests",
      dependencies: ["Routeur"]),
  ]
)
