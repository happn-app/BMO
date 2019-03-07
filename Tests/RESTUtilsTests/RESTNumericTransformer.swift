/*
Copyright 2019 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

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
	
}
