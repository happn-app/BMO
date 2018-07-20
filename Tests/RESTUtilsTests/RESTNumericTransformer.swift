/*
 * RESTNumericTransformer.swift
 * BMO
 *
 * Created by François Lamboley on 20/07/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation
import XCTest

@testable import RESTUtils



class RESTNumericTransformerTest : XCTestCase {
	
	func testWeirdFloatNumberToFloatConversion() {
		/* n as? Float == nil because 15.7 cannot be represented *exactly* as a
		 * Float: https://twitter.com/drewmccormack/status/1020319238291165185 */
		let n = NSNumber(value: 15.7)
		XCTAssertEqual(RESTNumericTransformer.convertObjectToFloat(n), 15.7)
	}
	
	
	/* Fill this array with all the tests to have Linux testing compatibility. */
	static var allTests = [
		("testWeirdFloatNumberToFloatConversion", testWeirdFloatNumberToFloatConversion),
	]
	
}
