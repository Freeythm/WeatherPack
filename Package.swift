// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WeatherPack",
    products: [
        .library(
            name: "WeatherPack",
            targets: ["WeatherPack"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "WeatherPack",
            dependencies: ["SwiftyJSON"]),
        .testTarget(
            name: "WeatherPackTests",
            dependencies: ["WeatherPack"]),
    ]
)
