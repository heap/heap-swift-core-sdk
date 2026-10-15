// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "HeapSwiftCore",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
        .macOS(.v11),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "HeapSwiftCore", targets: [
            "__HeapSwiftCore",
        ]),
    ],
    dependencies: [
        .package(url: "https://github.com/ContentSquare/apple-core-sdk.git", .upToNextMinor(from: "0.2.4")),
    ],
    targets: [
        .target(
            name: "__HeapSwiftCore",
            dependencies: [
                .product(name: "ContentsquareCore", package: "apple-core-sdk"),
                "HeapSwiftCore",
            ]
        ),
        .binaryTarget(
            name: "HeapSwiftCore",
            url: "https://github.com/heap/heap-swift-core-sdk/releases/download/0.10.0/package.zip",
            checksum: "840dd439372c52f95d4e6bd33d9b1ef0e22a20e17c51caf4efb16e03e3cdf18e"
    )
    ],
    swiftLanguageVersions: [.v5]
)
