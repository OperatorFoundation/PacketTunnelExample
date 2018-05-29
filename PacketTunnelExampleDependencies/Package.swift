// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PacketTunnelExampleDependencies",
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Shapeshifter-Swift-Transports.git", from: "0.1.0"),
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", from: "0.0.1")
        ],
    targets: [
        .target(
            name: "PacketTunnelExampleDependencies",
            dependencies: ["Meek", "SwiftQueue", "ShapeshifterTesting"]),
        .testTarget(
            name: "PacketTunnelExampleDependenciesTests",
            dependencies: ["PacketTunnelExampleDependencies", "Meek"]),
        ]
)
