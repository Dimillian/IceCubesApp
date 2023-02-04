// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Models",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v16),
  ],
  products: [
    .library(
      name: "Models",
      targets: ["Models"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.4.3"),
  ],
  targets: [
    .target(
      name: "Models",
      dependencies: ["SwiftSoup"]
    ),
    .testTarget(
      name: "ModelsTests",
      dependencies: ["Models"]
    ),
  ]
)
