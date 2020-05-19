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



public protocol Db {
	
	associatedtype ObjectType
	associatedtype ObjectIDType : Hashable
	associatedtype FetchRequestType
	
	associatedtype EntityDescriptionType
	/* Note:
	 * We could comment the associated type below. It is indeed not used by any
	 * object using a generic Db instance, because the FastImportRepresentation
	 * struct uses Strings for its properties keys instead of
	 * PropertyDescriptionType.
	 *
	 * We'll probably NOT change that anytime soon because:
	 *    - There's a CoreData bug related to hash value of NSPropertyDescription
	 *      (but that’s been mitigated w/ NSPropertyDescriptionHashableWrapper);
	 *    - I tried doing that one day, but for reasons I do not remember exactly
	 *      it was a hassle (problems related to the REST Mapper IIRC). */
	associatedtype PropertyDescriptionType : Hashable
	
	/* Both these methods should be re-entrant. */
	func perform(_ block: @escaping () -> Void)
	func performAndWait(_ block: () throws -> Void) rethrows
	
	func unsafeObjectID(forObject: ObjectType) -> ObjectIDType
	func unsafeRetrieveExistingObject(fromObjectID: ObjectIDType) throws -> ObjectType
	
}
