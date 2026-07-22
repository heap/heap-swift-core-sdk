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
        .package(url: "https://github.com/ContentSquare/apple-core-sdk.git", .upToNextMinor(from: "0.2.0")),
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
            url: "https://github.com/heap/heap-swift-core-sdk/releases/download/0.9.2/package.zip",
            checksum: "95e816dfd19a64f30e1e9c9edc51d18c5e57612dbbc303af37fc4190745ce67b"
    )
    ],
    swiftLanguageVersions: [.v5]
)
