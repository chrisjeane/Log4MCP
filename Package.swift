// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Log4MCP",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "Log4MCPLib",
            path: "Sources/Log4MCP"
        ),
        .executableTarget(
            name: "Log4MCP",
            dependencies: ["Log4MCPLib"],
            path: "Sources/Executable"
        ),
        .testTarget(
            name: "Log4MCPTests",
            dependencies: ["Log4MCPLib", .product(name: "Testing", package: "swift-testing")]
        ),
    ]
)
