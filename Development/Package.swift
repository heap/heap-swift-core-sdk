// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HeapSwiftCoreDevelopment",
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
            name: "HeapSwiftCore-Dynamic",
            type: .dynamic,
            targets: ["HeapSwiftCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "5.0.1"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "10.0.0"),
    ],
    targets: [
        .target(
            name: "HeapSwiftCore",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                "HeapSwiftCoreInterfaces",
            ]),
        .binaryTarget(
            name: "HeapSwiftCoreInterfaces",
            url: "https://cdn.heapanalytics.com/ios/heap-swift-core-interfaces-0.5.1.zip", // END HeapSwiftCoreInterfaces URL
            checksum: "dca51c26bc2f3fce7554e6440d51d2fa371ec19953046e48653ea6531bd79fab" // END HeapSwiftCoreInterfaces checksum
        ),
        .target(
            name: "HeapSwiftCoreTestSupport",
            dependencies: [
                "HeapSwiftCore",
                "Quick",
                "Nimble",
            ]),
        .testTarget(
            name: "HeapSwiftCoreTests",
            dependencies: [
                "HeapSwiftCoreTestSupport",
                "Quick",
                "Nimble",
            ]),
        .testTarget(
            name: "HeapSwiftCoreTests-AdSupport",
            dependencies: [
                "HeapSwiftCoreTestSupport",
                "Quick",
                "Nimble",
            ]),
    ]
)
