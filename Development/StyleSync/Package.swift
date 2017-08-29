// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

import PackageDescription

let package = Package(
	name: "StyleSync",
	targets: [
		.target(
			name: "StyleSync",
			dependencies: ["StyleSyncCore"]
		),
		.target(name: "StyleSyncCore"),
		.testTarget(
			name: "StyleSyncTests",
			dependencies: ["StyleSyncCore"]
		)
	]
)
