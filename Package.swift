// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftCardanoUtils",
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
        .package(
            url: "https://github.com/apple/swift-configuration",
            from: "1.2.0",
            traits: [.defaults, "YAML"]
        ),
        .package(url: "https://github.com/mattt/swift-configuration-toml.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.12.0"),
        .package(url: "https://github.com/apple/swift-system.git", from: "1.6.4"),
        .package(url: "https://github.com/Kingpin-Apps/swift-cardano-core.git", from: "0.3.16"),
        .package(url: "https://github.com/tuist/Command.git", .upToNextMinor(from: "0.14.2")),
        .package(url: "https://github.com/Kolos65/Mockable", .upToNextMinor(from: "0.6.2")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftCardanoUtils",
            dependencies: [
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "ConfigurationTOML", package: "swift-configuration-toml"),
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
