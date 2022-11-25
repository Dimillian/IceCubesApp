// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Network",
  platforms: [
    .iOS(.v16),
  ],
  products: [
    .library(
      name: "Network",
      targets: ["Network"]),
  ],
  dependencies: [
    .package(url: "https://gitlab.com/mflint/HTML2Markdown", exact: "1.0.0")
  ],
  targets: [
    .target(
      name: "Network",
      dependencies: ["HTML2Markdown"]),
    .testTarget(
      name: "NetworkTests",
      dependencies: ["Network"]),
  ]
)
