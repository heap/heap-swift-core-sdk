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
            url: "https://github.com/heap/heap-swift-core-sdk/releases/download/0.8.7/package.zip",
            checksum: "0b78adbce272f343aa1a0b1467a057b0163de9953d5d387a81806d0ec72484bf"
    )
    ],
    swiftLanguageVersions: [.v5]
)
