// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MediaUI",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17),
  ],
  products: [
    .library(
      name: "MediaUI",
      targets: ["MediaUI"]
    ),
  ],
  dependencies: [
    .package(name: "Models", path: "../Models"),
  ],
  targets: [
    .target(
      name: "MediaUI",
      dependencies: [
        .product(name: "Models", package: "Models"),
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),
      ]
    ),
  ]
)
