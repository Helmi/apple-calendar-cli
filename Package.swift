// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "applecal",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "applecal", targets: ["applecal"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "applecal",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
