// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "HeapSwiftCore",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "HeapSwiftCore", targets: [
            "__HeapSwiftCore",
        ]),
    ],
    dependencies: [
        .package(url: "https://github.com/ContentSquare/CSSwiftProtobuf.git", exact: "1.28.2"),
    ],
    targets: [
        .target(
            name: "__HeapSwiftCore",
            dependencies: [
                "CSSwiftProtobuf",
                "HeapSwiftCore",
            ]
        ),
        .binaryTarget(
            name: "HeapSwiftCore",
            url: "https://github.com/heap/heap-swift-core-sdk/releases/download/0.8.0/package.zip",
            checksum: "79ab0348e8113263b5957b4c9f9573e7e63d797ad3868541710302ff3cc30c1d"
    )
    ],
    swiftLanguageVersions: [.v5]
)
