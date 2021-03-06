// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PacketTunnelExampleDependencies",
    dependencies: [
        .package(url:"https://github.com/OperatorFoundation/Transport.git", from: "0.0.12"),
        .package(url: "https://github.com/OperatorFoundation/Shapeshifter-Swift-Transports.git", from: "0.2.0"),
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", from: "0.0.3")
        ],
    targets: [
        .target(
            name: "PacketTunnelExampleDependencies",
            dependencies: ["Transport", "Wisp", "SwiftQueue"]),
        .testTarget(
            name: "PacketTunnelExampleDependenciesTests",
            dependencies: ["PacketTunnelExampleDependencies"]),
        ]
)
