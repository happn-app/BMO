/*
 * BMODb.swift
 * BMO
 *
 * Created by François Lamboley on 2/5/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation



public protocol BMODb {
	
	associatedtype ObjectType
	associatedtype ObjectIDType : Hashable
	associatedtype FetchRequestType
	
	associatedtype EntityDescriptionType
	/* Note:
	 * We could comment the associated type below. It is indeed not used by any
	 * object using a generic BMODb instance, because the
	 * BMOFastImportRepresentation struct uses Strings for its properties keys
	 * instead of PropertyDescriptionType.
	 *
	 * We'll probably NOT change that anytime soon because:
	 *    - There's a CoreData bug related to hash value of NSPropertyDescription
	 *      (see _propertyMapping... function in RESTMapper for a more thorough
	 *      description of the bug);
	 *    - I tried doing that one day, but for reasons I do not remember exactly
	 *      it was a hassle (problems related to the REST Mapper IIRC). */
	associatedtype PropertyDescriptionType : Hashable
	
	/* Both these methods should be re-entrant. */
	func perform(_ block: @escaping () -> Void)
	func performAndWait(_ block: () throws -> Void) rethrows
	
	func unsafeObjectID(forObject: ObjectType) -> ObjectIDType
	func unsafeRetrieveExistingObject(fromObjectID: ObjectIDType) throws -> ObjectType
	
}
