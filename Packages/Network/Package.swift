// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Network",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v18),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "Network",
      targets: ["Network"]
    )
  ],
  dependencies: [
    .package(name: "Models", path: "../Models")
  ],
  targets: [
    .target(
      name: "Network",
      dependencies: [
        .product(name: "Models", package: "Models")
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
    .testTarget(
      name: "NetworkTests",
      dependencies: ["Network"]
    ),
  ]
)
