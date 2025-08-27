// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Timeline",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v18),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "Timeline",
      targets: ["Timeline"]
    )
  ],
  dependencies: [
    .package(name: "NetworkClient", path: "../NetworkClient"),
    .package(name: "Models", path: "../Models"),
    .package(name: "Env", path: "../Env"),
    .package(name: "StatusKit", path: "../StatusKit"),
    .package(name: "DesignSystem", path: "../DesignSystem"),
    .package(url: "https://github.com/siteline/swiftui-introspect", exact: "1.2.0"),
    .package(url: "https://github.com/mergesort/Bodega", exact: "2.1.3"),
  ],
  targets: [
    .target(
      name: "Timeline",
      dependencies: [
        .product(name: "NetworkClient", package: "NetworkClient"),
        .product(name: "Models", package: "Models"),
        .product(name: "Env", package: "Env"),
        .product(name: "StatusKit", package: "StatusKit"),
        .product(name: "DesignSystem", package: "DesignSystem"),
        .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect"),
        .product(name: "Bodega", package: "Bodega"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
    .testTarget(
      name: "TimelineTests",
      dependencies: ["Timeline"]
    ),
  ]
)
