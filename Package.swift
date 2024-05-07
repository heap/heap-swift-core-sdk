// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HeapSwiftCore",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v12),
        .watchOS(.v5),
        .tvOS(.v12),
    ],
    products: [
        .library(
            name: "HeapSwiftCore",
            targets: ["HeapSwiftCore"]),
        .library(
            name: "HeapSwiftCoreInterfaces",
            targets: ["HeapSwiftCoreInterfaces"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
    ],
    targets: [
        .target(
            name: "HeapSwiftCore",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                "HeapSwiftCoreInterfaces",
            ],
            path: "Development/Sources/HeapSwiftCore"),
        .binaryTarget(
            name: "HeapSwiftCoreInterfaces",
            url: "https://cdn.heapanalytics.com/ios/heap-swift-core-interfaces-0.6.0-alpha.3.zip", // END HeapSwiftCoreInterfaces URL
            checksum: "8a6477840ec8871f5dca44c707d087e9e9a1b0c121f80dcb4cb04f2a5eaa625d" // END HeapSwiftCoreInterfaces checksum
        )
    ]
)
