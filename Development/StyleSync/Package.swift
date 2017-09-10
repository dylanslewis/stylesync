// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "StyleSync",
	dependencies: [
		.package(
			url: "https://github.com/johnsundell/files.git",
			from: "1.0.0"
		)
	],
	targets: [
		.target(
			name: "StyleSync",
			dependencies: ["StyleSyncCore"]
		),
		.target(
			name: "StyleSyncCore",
			dependencies: ["Files"]
		),
		.testTarget(
			name: "StyleSyncTests",
			dependencies: ["StyleSyncCore"]
		)
	]
)
