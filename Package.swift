// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "stylesync",
	products: [
		.executable(name: "stylesync", targets: ["StyleSync"]),
		.library(name: "StyleSyncCore", targets: ["StyleSyncCore"])
	],
	dependencies: [
		.package(
			url: "https://github.com/JohnSundell/Files.git",
			from: "2.0.0"
		),
		.package(
			url: "https://github.com/JohnSundell/ShellOut.git",
			from: "2.0.0"
		)
	],
	targets: [
		.target(
			name: "StyleSync",
			dependencies: ["StyleSyncCore"]
		),
		.target(
			name: "StyleSyncCore",
			dependencies: ["Files", "ShellOut"]
		),
		.testTarget(
			name: "StyleSyncTests",
			dependencies: ["StyleSyncCore"]
		)
	]
)
