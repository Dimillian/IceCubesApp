// swift-tools-version: 6.0
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
    )
  ],
  dependencies: [
    .package(name: "Models", path: "../Models"),
    .package(name: "Env", path: "../Env"),
    .package(url: "https://github.com/kean/Nuke", exact: "12.8.0"),
    .package(url: "https://github.com/divadretlaw/EmojiText", exact: "4.2.0"),
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
        .swiftLanguageMode(.v6)
      ]
    )
  ]
)
