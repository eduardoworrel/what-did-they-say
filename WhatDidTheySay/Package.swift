// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WhatDidTheySay",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WhatDidTheySay", targets: ["WhatDidTheySay"])
    ],
    dependencies: [
        // NLLB-200 fallback via swift-transformers (optional — comment out if not needed)
        // .package(url: "https://github.com/huggingface/swift-transformers", from: "0.1.13"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0"),
    ],
    targets: [
        // Business logic library — testable without AppKit entrypoints
        .target(
            name: "WhatDidTheySayCore",
            dependencies: [],
            path: "Sources/WhatDidTheySayCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "WhatDidTheySay",
            dependencies: [
                "WhatDidTheySayCore",
                // Uncomment to enable NLLB fallback:
                // .product(name: "Transformers", package: "swift-transformers"),
            ],
            path: "Sources/WhatDidTheySay",
            resources: [
                .copy("../../Resources/Assets.xcassets")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "WhatDidTheySayTests",
            dependencies: [
                "WhatDidTheySayCore",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/WhatDidTheySayTests"
        )
    ]
)
