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

import XCTest
@testable import RESTUtils



class RESTUtilsTests: XCTestCase {
	
	func testInvalidPath1() {
		XCTAssertNil(RESTPath("("))
	}
	
	func testInvalidPath2() {
		XCTAssertNil(RESTPath("(a"))
	}
	
	func testInvalidPath3() {
		XCTAssertNil(RESTPath(")"))
	}
	
	func testInvalidPath4() {
		XCTAssertNil(RESTPath("|"))
	}
	
	func testInvalidPath5() {
		XCTAssertNil(RESTPath("|hell(o|)"))
	}
	
	func testInvalidPath6() {
		XCTAssertNil(RESTPath("|hell(o|\\)"))
	}
	
	func testInvalidPath7() {
		XCTAssertNil(RESTPath("hell(o|)"))
	}
	
	func testInvalidPath8() {
		XCTAssertNil(RESTPath("hell(o|)|)"))
	}
	
	func testInvalidPath9() {
		XCTAssertNil(RESTPath("hell(o|(|)"))
	}
	
	func testInvalidPath10() {
		XCTAssertNil(RESTPath("\\a"))
	}
	
	func testInvalidPath11() {
		XCTAssertNil(RESTPath("hell)o"))
	}
	
	func testConstantRESTPath() {
		guard let r = RESTPath("hello") else {
			XCTFail("Cannot parse REST path")
			return
		}
		switch r {
		case .constant(let str): XCTAssertEqual(str, "hello")
		default:                 XCTFail("Unexpected component type for path")
		}
	}
	
	func testVariableRESTPath() {
		guard let r = RESTPath("|hello|") else {
			XCTFail("Cannot parse REST path")
			return
		}
		switch r {
		case .variable(let str): XCTAssertEqual(str, "hello")
		default:                 XCTFail("Unexpected component type for path")
		}
	}
	
	func testEmptySubpathRESTPath() {
		guard let r = RESTPath("()") else {
			XCTFail("Cannot parse REST path")
			return
		}
		switch r {
		case .components(let components, isRoot: let root): XCTAssertEqual(components.count, 0); XCTAssertFalse(root)
		default:                                            XCTFail("Unexpected component type for path")
		}
	}
	
	func testEmptyVariableRESTPath() {
		guard let r = RESTPath("||") else {
			XCTFail("Cannot parse REST path")
			return
		}
		switch r {
		case .variable(let str): XCTAssertEqual(str, "")
		default:                 XCTFail("Unexpected component type for path")
		}
	}
	
	func testOpenParenthesisVariableRESTPath() {
		guard let r = RESTPath("|\\(|") else {
			XCTFail("Cannot parse REST path")
			return
		}
		switch r {
		case .variable(let str): XCTAssertEqual(str, "(")
		default:                 XCTFail("Unexpected component type for path")
		}
	}
	
	func testConstantAndVariableRESTPath() {
		guard let r = RESTPath("hello/|world|") else {
			XCTFail("Cannot parse REST path")
			return
		}
		switch r {
		case .components(let components, isRoot: let root):
			XCTAssertTrue(root)
			XCTAssertEqual(components.count, 2)
			let c0 = components[0]
			let c1 = components[1]
			switch c0 {
			case .constant(let str): XCTAssertEqual(str, "hello/")
			default:                 XCTFail("Unexpected component type for path")
			}
			switch c1 {
			case .variable(let str): XCTAssertEqual(str, "world")
			default:                 XCTFail("Unexpected component type for path")
			}
			
		default:
			XCTFail("Unexpected component type for path")
		}
	}
	
	func testSimpleVariableReplacement() {
		guard let r = RESTPath("|key|") else {
			XCTFail("Cannot parse REST path")
			return
		}
		XCTAssertEqual(r.resolvedPath(source: ["key": "val"]), "val")
	}
	
	func testTwoLevelsKeyPathVariableReplacement() {
		guard let r = RESTPath("|key1.key2|") else {
			XCTFail("Cannot parse REST path")
			return
		}
		XCTAssertEqual(r.resolvedPath(source: ["key1": ["key2": "val"]]), "val")
	}
	
	func testTwoLevelsKeyPathVariableReplacement2() {
		guard let r = RESTPath("|key1.key2|") else {
			XCTFail("Cannot parse REST path")
			return
		}
		XCTAssertEqual(r.resolvedPath(source: ["key1.key2": "val1", "key1": ["key2": "val2"]]), "val1")
	}
	
	func testSimpleAbsentVariableReplacement() {
		guard let r = RESTPath("hello/|invalid_key|") else {
			XCTFail("Cannot parse REST path")
			return
		}
		XCTAssertNil(r.resolvedPath(source: ["key": "val"]))
	}
	
	func testSimpleAbsentOptionalVariableReplacement() {
		guard let r = RESTPath("hello(/|invalid_key|)") else {
			XCTFail("Cannot parse REST path")
			return
		}
		XCTAssertEqual(r.resolvedPath(source: ["key": "val"]), "hello")
	}
	
}
