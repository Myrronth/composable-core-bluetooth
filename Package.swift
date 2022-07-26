// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "composable-core-bluetooth",
  platforms: [
    .iOS(.v13)
//    .macOS(.v10_15),
//    .tvOS(.v13),
//    .watchOS(.v6)
  ],
  products: [
    .library(
      name: "ComposableCoreBluetooth",
      targets: ["ComposableCoreBluetooth"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMajor(from: "0.38.3")),
  ],
  targets: [
    .target(
      name: "ComposableCoreBluetooth",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]),
    .testTarget(
      name: "ComposableCoreBluetoothTests",
      dependencies: ["ComposableCoreBluetooth"]),
  ]
)

