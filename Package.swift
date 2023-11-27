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
            url: "https://cdn.heapanalytics.com/ios/heap-swift-core-interfaces-0.5.1.zip", // END HeapSwiftCoreInterfaces URL
            checksum: "dca51c26bc2f3fce7554e6440d51d2fa371ec19953046e48653ea6531bd79fab" // END HeapSwiftCoreInterfaces checksum
        )
    ]
)
