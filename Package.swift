// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "SymbolViewer",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "SymbolViewer", targets: ["SymbolViewer"])],
    targets: [.executableTarget(name: "SymbolViewer", resources: [.process("Resources")])]
)
