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



enum RESTEntityUniquingType<DbPropertyDescription> {
	
	/** No uniquing for the given entity */
	case none
	/** Singleton entity, the uniquing id is constant, set to the given value. */
	case singleton(String)
	/** The uniquing id will be a concatenation of the constant prefix if any and
	the value of the property converted to string (with `String(describing:)`).
	If the value of the property is nil (or if the property is not in the local
	representation of the object), the uniquing id will be nil. */
	case onProperty(constantPrefix: String?, property: DbPropertyDescription)
	/** The uniquing id will be computed using the given handler. */
	case custom((_ localRepresentation: [String: Any?]) -> String?)
	
}

public enum RESTEntityDescription {
	
	/** Matches nothing */
	case abstract
	/** Any representation matches */
	case noSpecificities
	/** The representation must have all the given properties to match */
	case hasProperties(Set<String>)
	/** The representation must have none of the given properties to match */
	case doesNotHaveProperties(Set<String>)
	/** The representation must have the given properties and their given values
	to match */
	case matchesProperties([String: AnyEquatable])
	/** The representation must pass the given block to match */
	case complex(matchesEntity: (_ remoteObject: [String: Any?]) -> Bool)
	
}

struct RESTEntityMapping<DbPropertyDescription : Hashable> {
	
	/** The REST path for fetching the entity.
	
	For example, for a user, it could be set to `users(/|remoteId|)`: when
	creating a user (remoteId would be nil), the resolved REST path would be
	`users` whereas when fetching a user, or updating an existing user, the path
	would be `users/:userId` as expected. */
	let restPath: RESTPath?
	/** How can we match a given REST representation to its entity?
	
	When retrieving an object from the back-end, you usually expect to retrieve
	an object kind of a given entity.
	
	A problem can arise, for example, if your original request asked for an
	abstract entity type. We have to have a way to specify which concrete
	realization of your entity was actually returned by the back!
	
	This is the purpose of this property.
	
	The RESTMapping class give you a method to find the concrete instance for a
	given REST representation, from an expected entity.
	
	The algorithm is as follow:
	- If the expected entity does not have a REST entity description, we consider
	we have found the correct entity and return it;
	- If the expected entity have a REST entity description which matches the
	current REST representation, we have found the correct entity and return it;
	- If the expected entity have a REST entity description which does not match
	the current REST representation, we try again with all subentities of the
	expected entity. For a subentity to match, the algorithm is the same, but the
	REST entity description has to be set to have a match.
	- If we still don't have a match after all subentities have been tested, we
	check the superentity, then go down again, etc. until all entities have been
	tested. Again, the REST entity description has to be set for a match to
	occur. */
	let restEntityDescription: RESTEntityDescription?
	
	/** If nil, inherited. If no superentity has a non-nil uniquing type, none. */
	let uniquingType: RESTEntityUniquingType<DbPropertyDescription>?
	
	let forcedPropertiesOnFetch: Set<DbPropertyDescription>
	let forcedParametersOnFetch: [String: Any]
	
	let forcedValuesOnSave: [String: Any]
	
	let propertiesMapping: [DbPropertyDescription: RESTPropertyMapping]
	
	let fieldsKeyName: String?
	let paginator: RESTPaginator?
	
}
