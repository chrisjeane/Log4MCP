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
            name: "MCPServer",
            path: "Sources/MCPServer"
        ),
        .target(
            name: "Log4MCPLib",
            dependencies: ["MCPServer"],
            path: "Sources/Log4MCP"
        ),
        .executableTarget(
            name: "Log4MCP",
            dependencies: ["Log4MCPLib", "MCPServer"],
            path: "Sources/Executable"
        ),
        .testTarget(
            name: "Log4MCPTests",
            dependencies: ["Log4MCPLib", "MCPServer", .product(name: "Testing", package: "swift-testing")],
            path: "Tests/Log4MCPTests"
        ),
    ]
)
