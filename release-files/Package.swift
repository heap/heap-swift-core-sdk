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
            url: "https://github.com/heap/heap-swift-core-sdk/releases/download/0.10.1/package.zip",
            checksum: "9b581c3c73779741167f828c0b6d3c033c1d75916ae98f91dc99b871f3d486e0"
    )
    ],
    swiftLanguageVersions: [.v5]
)
