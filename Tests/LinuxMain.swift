import XCTest
@testable import BMOTests
@testable import RESTUtilsTests
@testable import BMO_FastImportRepresentationTests
@testable import BMO_CoreDataTests
@testable import BMO_RESTCoreDataTests
@testable import CollectionLoader_RESTCoreDataTests



XCTMain([
	testCase(BMOTests.allTests),
	testCase(RESTUtilsTests.allTests),
	testCase(BMO_FastImportRepresentationTests.allTests),
	testCase(BMO_CoreDataTests.allTests),
	testCase(BMO_RESTCoreDataTests.allTests),
	testCase(CollectionLoader_RESTCoreDataTests.allTests)
])
