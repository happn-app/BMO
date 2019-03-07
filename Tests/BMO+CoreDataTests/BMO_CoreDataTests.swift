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
