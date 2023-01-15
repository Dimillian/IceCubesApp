// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Status",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v16),
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
    .package(name: "Network", path: "../Network"),
    .package(name: "Env", path: "../Env"),
    .package(name: "DesignSystem", path: "../DesignSystem"),
    .package(url: "https://github.com/Dimillian/TextView", branch: "main"),
  ],
  targets: [
    .target(
      name: "Status",
      dependencies: [
        .product(name: "AppAccount", package: "AppAccount"),
        .product(name: "Models", package: "Models"),
        .product(name: "Network", package: "Network"),
        .product(name: "Env", package: "Env"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "TextView", package: "TextView"),
      ]
    ),
  ]
)
