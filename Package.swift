// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription



let package = Package(
	name: "BMO",
	products: [
		.library(
			name: "BMOCore",
			targets: ["BMO"]
		),
		.library(
			name: "BMO+CoreData",
			targets: ["BMO", "BMO+FastImportRepresentation", "BMO+CoreData"]
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
		),
		.target(
			name: "BMO+FastImportRepresentation",
			dependencies: ["BMO"]
		),
		.testTarget(
			name: "BMO+FastImportRepresentationTests",
			dependencies: ["BMO+FastImportRepresentation"]
		),
		.target(
			name: "BMO+CoreData",
			dependencies: ["AsyncOperationResult", "BMO", "BMO+FastImportRepresentation"]
		),
		.testTarget(
			name: "BMO+CoreDataTests",
			dependencies: ["BMO+CoreData"]
		)
	]
)
