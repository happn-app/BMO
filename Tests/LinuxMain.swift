import XCTest

import BMOTests
import BMO_CoreDataTests
import BMO_FastImportRepresentationTests
import BMO_RESTCoreDataTests
import CollectionLoader_RESTCoreDataTests
import RESTUtilsTests

var tests = [XCTestCaseEntry]()
tests += BMOTests.__allTests()
tests += BMO_CoreDataTests.__allTests()
tests += BMO_FastImportRepresentationTests.__allTests()
tests += BMO_RESTCoreDataTests.__allTests()
tests += CollectionLoader_RESTCoreDataTests.__allTests()
tests += RESTUtilsTests.__allTests()

XCTMain(tests)
