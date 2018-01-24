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
		.package(url: "git@github.com:happn-app/AsyncOperationResult", from: "1.0.0")
	],
	targets: [
		.target(
			name: "BMO",
			dependencies: ["AsyncOperationResult"]
		),
		.testTarget(
			name: "BMOTests",
			dependencies: ["BMO"]
		)
	]
)
