// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DesignSystem",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v18),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "DesignSystem",
      targets: ["DesignSystem"]
    )
  ],
  dependencies: [
    .package(name: "Models", path: "../Models"),
    .package(name: "Env", path: "../Env"),
    .package(url: "https://github.com/kean/Nuke", exact: "12.8.0"),
    .package(url: "https://github.com/Dimillian/EmojiText", branch: "fix-ios26"),
    .package(url: "https://github.com/kaishin/Gifu.git", from: "4.0.1"),
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
        .product(name: "Gifu", package: "Gifu"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    )
  ]
)
