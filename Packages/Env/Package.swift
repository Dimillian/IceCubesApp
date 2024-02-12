// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Env",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17),
    .visionOS(.v1),
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
    .package(url: "https://github.com/evgenyneu/keychain-swift", branch: "master"),
  ],
  targets: [
    .target(
      name: "Env",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Network", package: "Network"),
        .product(name: "KeychainSwift", package: "keychain-swift"),
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),
      ]
    ),
    .testTarget(
      name: "EnvTests",
      dependencies: ["Env"]
    ),
  ]
)
