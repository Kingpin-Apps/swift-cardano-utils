// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-cardano-utils",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftCardanoUtils",
            targets: ["SwiftCardanoUtils"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-configuration", .upToNextMinor(from: "0.1.1")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.2"),
        .package(url: "https://github.com/apple/swift-system.git", from: "1.6.3"),
        .package(url: "https://github.com/Kingpin-Apps/swift-cardano-core.git", from: "0.2.17"),
        .package(url: "https://github.com/tuist/Command.git", .upToNextMajor(from: "0.2.0")),
        .package(url: "https://github.com/Kolos65/Mockable", .upToNextMajor(from: "0.3.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftCardanoUtils",
            dependencies: [
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SystemPackage", package: "swift-system"),
                .product(name: "SwiftCardanoCore", package: "swift-cardano-core"),
                .product(name: "Command", package: "Command"),
            ],
            swiftSettings: [
                .define("MOCKING", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "SwiftCardanoUtilsTests",
            dependencies: [
                "SwiftCardanoUtils",
                .product(name: "Mockable", package: "Mockable")],
            resources: [
                .copy("data")
            ]
        ),
    ]
)
