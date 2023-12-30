// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Status",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "Status",
      targets: ["Status"]
    ),
  ],
  dependencies: [
    .package(name: "AppAccount", path: "../AppAccount"),
    .package(name: "Models", path: "../Models"),
    .package(name: "MediaUI", path: "../MediaUI"),
    .package(name: "Network", path: "../Network"),
    .package(name: "Env", path: "../Env"),
    .package(name: "DesignSystem", path: "../DesignSystem"),
    .package(url: "https://github.com/Giphy/giphy-ios-sdk", from: "2.2.7"),
    .package(url: "https://github.com/nicklockwood/LRUCache", from: "1.0.4"),
  ],
  targets: [
    .target(
      name: "Status",
      dependencies: [
        .product(name: "AppAccount", package: "AppAccount"),
        .product(name: "Models", package: "Models"),
        .product(name: "MediaUI", package: "MediaUI"),
        .product(name: "Network", package: "Network"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "GiphyUISDK", package: "giphy-ios-sdk"),
        .product(name: "LRUCache", package: "LRUCache"),
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency"),
      ]
    ),
  ]
)
