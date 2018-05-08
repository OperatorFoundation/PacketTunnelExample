// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PacketTunnelExampleDependencies",
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Shapeshifter-Swift-Transports.git", from: "0.1.0"),
        ],
    targets: [
        .target(
            name: "PacketTunnelExampleDependencies",
            dependencies: ["Meek"]),
        .testTarget(
            name: "PacketTunnelExampleDependenciesTests",
            dependencies: ["PacketTunnelExampleDependencies", "Meek"]),
        ]
)
