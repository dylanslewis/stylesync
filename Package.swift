// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "stylesync",
	products: [
		.executable(name: "stylesync", targets: ["stylesync"]),
		.library(name: "stylesyncCore", targets: ["stylesyncCore"])
	],
	dependencies: [
		.package(
			url: "https://github.com/JohnSundell/Files.git",
			from: "1.0.0"
		),
		.package(
			url: "https://github.com/JohnSundell/ShellOut.git",
			from: "2.0.0"
		)
	],
	targets: [
		.target(
			name: "stylesync",
			dependencies: ["stylesyncCore"]
		),
		.target(
			name: "stylesyncCore",
			dependencies: ["Files", "ShellOut"]
		),
		.testTarget(
			name: "stylesyncTests",
			dependencies: ["stylesyncCore"]
		)
	]
)
