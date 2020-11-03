// swift-tools-version:5.0
import PackageDescription


let package = Package(
	name: "BMO",
	products: [
		.library(name: "BMO", targets: ["BMO"]),
		.library(name: "RESTUtils", targets: ["RESTUtils"]),
		/* A Library for BMO w/ CoreData and REST. */
		.library(
			name: "Jake",
			targets: ["BMO", "RESTUtils", "BMO+FastImportRepresentation", "BMO+CoreData", "BMO+RESTCoreData", "CollectionLoader+RESTCoreData"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/happn-tech/AsyncOperationResult.git", from: "1.0.5"),
		.package(url: "https://github.com/happn-tech/CollectionLoader.git", from: "0.9.4")
	],
	targets: [
		.target(name: "BMO",                           dependencies: ["AsyncOperationResult"]),
		.target(name: "RESTUtils",                     dependencies: []),
		.target(name: "BMO+FastImportRepresentation",  dependencies: ["BMO"]),
		.target(name: "BMO+CoreData",                  dependencies: ["AsyncOperationResult", "BMO", "BMO+FastImportRepresentation"]),
		.target(name: "BMO+RESTCoreData",              dependencies: ["AsyncOperationResult", "BMO", "RESTUtils", "BMO+FastImportRepresentation", "BMO+CoreData"]),
		.target(name: "CollectionLoader+RESTCoreData", dependencies: ["AsyncOperationResult", "CollectionLoader", "BMO", "RESTUtils", "BMO+FastImportRepresentation", "BMO+CoreData", "BMO+RESTCoreData"]),
		.testTarget(name: "BMOTests",                           dependencies: ["BMO"]),
		.testTarget(name: "RESTUtilsTests",                     dependencies: ["RESTUtils"]),
		.testTarget(name: "BMO-FastImportRepresentationTests",  dependencies: ["BMO+FastImportRepresentation"]),
		.testTarget(name: "BMO-CoreDataTests",                  dependencies: ["BMO+CoreData"]),
		.testTarget(name: "BMO-RESTCoreDataTests",              dependencies: ["BMO+RESTCoreData"]),
		.testTarget(name: "CollectionLoader-RESTCoreDataTests", dependencies: ["CollectionLoader+RESTCoreData"])
	]
)
