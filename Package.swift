// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PhotoUtil",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "PhotoUtilCore", targets: ["PhotoUtilCore"]),
        .executable(name: "PhotoUtil", targets: ["PhotoUtil"]),
        .executable(name: "PhotoUtilChecks", targets: ["PhotoUtilChecks"])
    ],
    targets: [
        .target(
            name: "PhotoUtilCore",
            path: "Sources/PhotoUtilCore"
        ),
        .executableTarget(
            name: "PhotoUtil",
            dependencies: ["PhotoUtilCore"],
            path: "Sources/PhotoUtil"
        ),
        .executableTarget(
            name: "PhotoUtilChecks",
            dependencies: ["PhotoUtilCore"],
            path: "Sources/PhotoUtilChecks"
        )
    ]
)
