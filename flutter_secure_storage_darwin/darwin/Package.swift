// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_secure_storage",
    platforms: [
        .iOS("12.0"),
        .macOS("10.14")
    ],
    products: [
        .library(name: "flutter-secure-storage", targets: ["flutter_secure_storage"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_secure_storage",
            dependencies: [],
            resources: [
                .process("Resources"),
            ]
        )
    ]
)
