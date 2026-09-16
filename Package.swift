// swift-tools-version: 5.9
import PackageDescription

var products: [Product] = [.library(name: "NotchDockCore", targets: ["NotchDockCore"])]
var targets: [Target] = [
    .target(name: "NotchDockCore"),
    .testTarget(name: "NotchDockCoreTests", dependencies: ["NotchDockCore"])
]
#if os(macOS)
products.append(.executable(name: "NotchDock", targets: ["NotchDock"]))
targets.append(.executableTarget(name: "NotchDock", dependencies: ["NotchDockCore"]))
#endif
let package = Package(name: "NotchDock", platforms: [.macOS(.v13)], products: products, targets: targets)
