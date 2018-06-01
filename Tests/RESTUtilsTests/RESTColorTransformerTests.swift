/*
 * RESTColorTransformerTests.swift
 * BMO
 *
 * Created by François Lamboley on 01/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import XCTest
@testable import RESTUtils



class RESTColorTransformerTests: XCTestCase {
	
	func testSimpleFail() {
		XCTAssertNil(RESTColorTransformer.convertObjectToColor("#000000 "))
	}
	
	func testSimpleHexColorWithSharpConversion() {
		XCTAssertEqual(RESTColorTransformer.convertObjectToColor("#000000"), BMOColor(red: 0, green: 0, blue: 0, alpha: 1))
	}
	
	func testSimpleHexColorWithoutSharpConversion() {
		XCTAssertEqual(RESTColorTransformer.convertObjectToColor("00000000"), BMOColor(red: 0, green: 0, blue: 0, alpha: 0))
	}
	
	/* Fill this array with all the tests to have Linux testing compatibility. */
	static var allTests = [
		("testSimpleFail", testSimpleFail),
		("testSimpleHexColorWithSharpConversion", testSimpleHexColorWithSharpConversion),
		("testSimpleHexColorWithoutSharpConversion", testSimpleHexColorWithoutSharpConversion)
	]
	
}
