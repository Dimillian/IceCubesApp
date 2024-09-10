// swift-tools-version: 6.0
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
    .package(url: "https://github.com/TelemetryDeck/SwiftSDK", from: "2.3.0"),
  ],
  targets: [
    .target(
      name: "Env",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Network", package: "Network"),
        .product(name: "KeychainSwift", package: "keychain-swift"),
        .product(name: "TelemetryDeck", package: "SwiftSDK")
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]
    ),
    .testTarget(
      name: "EnvTests",
      dependencies: ["Env"]
    ),
  ]
)
