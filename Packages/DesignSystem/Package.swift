// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DesignSystem",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "DesignSystem",
      targets: ["DesignSystem"]
    ),
  ],
  dependencies: [
    .package(name: "Models", path: "../Models"),
    .package(name: "Env", path: "../Env"),
    .package(url: "https://github.com/markiv/SwiftUI-Shimmer", exact: "1.1.0"),
    .package(url: "https://github.com/kean/Nuke", from: "12.0.0"),
    .package(url: "https://github.com/divadretlaw/EmojiText", from: "3.2.1"),
  ],
  targets: [
    .target(
      name: "DesignSystem",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "Shimmer", package: "SwiftUI-Shimmer"),
        .product(name: "NukeUI", package: "Nuke"),
        .product(name: "Nuke", package: "Nuke"),
        .product(name: "EmojiText", package: "EmojiText"),
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),
      ]
    ),
  ]
)
