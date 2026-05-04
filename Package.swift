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
        .package(url: "https://github.com/ContentSquare/apple-core-sdk.git", .upToNextMinor(from: "0.1.0")),
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
            url: "https://github.com/heap/heap-swift-core-sdk/releases/download/0.9.0/package.zip",
            checksum: "3fa8d25e2922ddb590d814a5176173ff360bd24b413ab842fd4ac697018ec919"
    )
    ],
    swiftLanguageVersions: [.v5]
)
