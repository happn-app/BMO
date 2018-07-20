/*
 * BMO_CoreDataTests.swift
 * BMO+CoreDataTests
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import XCTest
@testable import BMO_CoreData

import CoreData



class BMO_CoreDataTests: XCTestCase {
    
	func testCompoundPredicateConstantsEnumeration() {
		let expectedKeyPath = ["toto", "titi", "tata"]
		let predicate = NSPredicate(format: "%K == TRUE AND %K == TRUE AND %K == %@", expectedKeyPath[0], expectedKeyPath[1], expectedKeyPath[2], NSManagedObject())
		
		var foundKeyPath = Set<String>()
		predicate.enumerateFirstLevelConstants(forKeyPath: nil, withAndCompound: true, { keyPath, constant in
			foundKeyPath.insert(keyPath)
		})
		
		XCTAssertEqual(foundKeyPath, Set(expectedKeyPath))
	}
	
	
	/* Fill this array with all the tests to have Linux testing compatibility. */
	static var allTests = [
		("testCompoundPredicateConstantsEnumeration", testCompoundPredicateConstantsEnumeration)
	]
	
}
