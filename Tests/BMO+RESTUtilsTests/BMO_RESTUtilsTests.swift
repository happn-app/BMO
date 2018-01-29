/*
 * BMO_RESTUtilsTests.swift
 * BMO+RESTUtilsTests
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import XCTest
@testable import BMO_RESTUtils



class BMO_RESTUtilsTests: XCTestCase {
	
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
	
	/* Fill this array with all the tests to have Linux testing compatibility. */
	static var allTests = [
		("testInvalidPath1", testInvalidPath1),
		("testInvalidPath2", testInvalidPath2),
		("testInvalidPath3", testInvalidPath3),
		("testInvalidPath4", testInvalidPath4),
		("testInvalidPath5", testInvalidPath5),
		("testInvalidPath6", testInvalidPath6),
		("testInvalidPath7", testInvalidPath7),
		("testInvalidPath8", testInvalidPath8),
		("testInvalidPath9", testInvalidPath9),
		("testInvalidPath10", testInvalidPath10),
		("testInvalidPath11", testInvalidPath11),
		("testConstantRESTPath", testConstantRESTPath),
		("testVariableRESTPath", testVariableRESTPath),
		("testEmptySubpathRESTPath", testEmptySubpathRESTPath),
		("testEmptyVariableRESTPath", testEmptyVariableRESTPath),
		("testOpenParenthesisVariableRESTPath", testOpenParenthesisVariableRESTPath),
		("testConstantAndVariableRESTPath", testConstantAndVariableRESTPath),
		("testSimpleVariableReplacement", testSimpleVariableReplacement),
		("testTwoLevelsKeyPathVariableReplacement", testTwoLevelsKeyPathVariableReplacement),
		("testTwoLevelsKeyPathVariableReplacement2", testTwoLevelsKeyPathVariableReplacement2),
		("testSimpleAbsentVariableReplacement", testSimpleAbsentVariableReplacement),
		("testSimpleAbsentOptionalVariableReplacement", testSimpleAbsentOptionalVariableReplacement)
	]
	
}
