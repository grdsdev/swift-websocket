// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "WebSocket",
  platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "WebSocket", targets: ["WebSocket"]),
    .library(name: "WebSocketFoundation", targets: ["WebSocketFoundation"]),
    .executable(name: "Example", targets: ["Example"]),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(name: "WebSocket"),
    .testTarget(
      name: "WebSocketTests",
      dependencies: ["WebSocket"]
    ),
    .target(
      name: "WebSocketFoundation",
      dependencies: ["WebSocket"]
    ),
    .testTarget(
      name: "WebSocketFoundationTests",
      dependencies: ["WebSocketFoundation"]
    ),
    .executableTarget(name: "Example", dependencies: ["WebSocketFoundation"]),
  ],
  swiftLanguageModes: [.v6]
)
