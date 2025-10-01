// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CardanoCLITools",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CardanoCLITools",
            targets: ["CardanoCLITools"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.2"),
        .package(url: "https://github.com/Kingpin-Apps/swift-cardano-core.git", from: "0.1.33"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CardanoCLITools",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SwiftCardanoCore", package: "swift-cardano-core"),
            ]
        ),
        .testTarget(
            name: "CardanoCLIToolsTests",
            dependencies: ["CardanoCLITools"],
            resources: [
                .copy("data")
            ]
        ),
    ]
)
