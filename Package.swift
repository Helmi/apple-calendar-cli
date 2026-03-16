// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "acal",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "acal", targets: ["App"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                "AppCore",
                "EventKitAdapter",
                "Formatting",
                "Diagnostics",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(name: "AppCore"),
        .target(
            name: "EventKitAdapter",
            dependencies: ["AppCore"]
        ),
        .target(
            name: "Formatting",
            dependencies: ["AppCore"]
        ),
        .target(
            name: "Diagnostics",
            dependencies: [
                "AppCore",
                "EventKitAdapter"
            ]
        ),
        .testTarget(
            name: "ACalTests",
            dependencies: [
                "AppCore",
                "App",
                "Formatting",
                "EventKitAdapter",
                "Diagnostics"
            ]
        )
    ]
)
