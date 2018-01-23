// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription



let package = Package(
	name: "BMO",
	products: [
		.library(
			name: "BMO",
			targets: ["BMO"]
		)
	],
	dependencies: [
	],
	targets: [
		.target(
			name: "BMO",
			dependencies: []
		),
		.testTarget(
			name: "BMOTests",
			dependencies: ["BMO"]
		)
	]
)
