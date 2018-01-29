import XCTest
@testable import BMOTests
@testable import BMO_FastImportRepresentationTests
@testable import BMO_RESTUtilsTests
@testable import BMO_CoreDataTests



XCTMain([
	testCase(BMOTests.allTests),
	testCase(BMO_FastImportRepresentationTests.allTests),
	testCase(BMO_RESTUtilsTests.allTests),
	testCase(BMO_CoreDataTests.allTests)
])
