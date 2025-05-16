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
            url: "https://github.com/heap/heap-swift-core-sdk/releases/download/0.8.5/package.zip",
            checksum: "5c43592f8ff9e9f257f66376c9111f4bfd54cb132e12f4ed6787e117fad9444d"
    )
    ],
    swiftLanguageVersions: [.v5]
)
