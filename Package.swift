// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Lisdex",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "Lisdex", targets: ["Lisdex"])
  ],
  targets: [
    // Pure, testable decision logic. Foundation only: no AppKit / SwiftUI / IOKit imports.
    .target(name: "LisdexCore"),
    // Menu bar app shell: AppKit status item + SwiftUI popover.
    .executableTarget(
      name: "Lisdex",
      dependencies: ["LisdexCore"]
    ),
    .testTarget(
      name: "LisdexCoreTests",
      dependencies: ["LisdexCore"]
    ),
  ]
)
