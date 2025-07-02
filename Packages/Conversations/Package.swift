// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Conversations",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v18),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "Conversations",
      targets: ["Conversations"]
    )
  ],
  dependencies: [
    .package(name: "Models", path: "../Models"),
    .package(name: "NetworkClient", path: "../NetworkClient"),
    .package(name: "Env", path: "../Env"),
    .package(name: "DesignSystem", path: "../DesignSystem"),
    .package(name: "StatusKit", path: "../StatusKit"),
  ],
  targets: [
    .target(
      name: "Conversations",
      dependencies: [
        .product(name: "Models", package: "Models"),
        .product(name: "NetworkClient", package: "NetworkClient"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "StatusKit", package: "StatusKit"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    )
  ]
)
