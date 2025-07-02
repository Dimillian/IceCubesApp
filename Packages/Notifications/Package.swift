// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Notifications",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v18),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "Notifications",
      targets: ["Notifications"]
    )
  ],
  dependencies: [
    .package(name: "NetworkClient", path: "../NetworkClient"),
    .package(name: "Models", path: "../Models"),
    .package(name: "Env", path: "../Env"),
    .package(name: "StatusKit", path: "../StatusKit"),
    .package(name: "DesignSystem", path: "../DesignSystem"),
  ],
  targets: [
    .target(
      name: "Notifications",
      dependencies: [
        .product(name: "NetworkClient", package: "NetworkClient"),
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "StatusKit", package: "StatusKit"),
        .product(name: "DesignSystem", package: "DesignSystem"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    )
  ]
)
