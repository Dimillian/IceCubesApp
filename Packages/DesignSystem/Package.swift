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
    .package(url: "https://github.com/kean/Nuke", exact: "12.7.3"),
    .package(url: "https://github.com/divadretlaw/EmojiText", exact: "4.0.0"),
  ],
  targets: [
    .target(
      name: "DesignSystem",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
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
