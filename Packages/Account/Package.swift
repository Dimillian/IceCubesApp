// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Account",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v18),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "Account",
      targets: ["Account"]
    )
  ],
  dependencies: [
    .package(name: "NetworkClient", path: "../NetworkClient"),
    .package(name: "Models", path: "../Models"),
    .package(name: "StatusKit", path: "../StatusKit"),
    .package(name: "Env", path: "../Env"),
    .package(name: "DesignSystem", path: "../DesignSystem"),
    .package(url: "https://github.com/Dean151/ButtonKit", from: "0.6.1"),
    .package(url: "https://github.com/dkk/WrappingHStack", from: "2.2.11"),
  ],
  targets: [
    .target(
      name: "Account",
      dependencies: [
        .product(name: "NetworkClient", package: "NetworkClient"),
        .product(name: "Models", package: "Models"),
        .product(name: "StatusKit", package: "StatusKit"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "ButtonKit", package: "ButtonKit"),
        .product(name: "WrappingHStack", package: "WrappingHStack"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
    .testTarget(
      name: "AccountTests",
      dependencies: ["Account"]
    ),
  ]
)
