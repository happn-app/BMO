/*
 * RESTMapping.swift
 * RESTUtils
 *
 * Created by François Lamboley on 1/31/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



/* Note: DbPropertyDescription would not need the DbRESTPropertyDescription
 *       restriction if it weren't for the CoreData bug described in the
 *       _propertyMapping... method. */
struct RESTMapping<DbEntityDescription : DbRESTEntityDescription & Hashable, DbPropertyDescription : DbRESTPropertyDescription & Hashable> {
	
	let entitiesMapping: [DbEntityDescription: RESTEntityMapping<DbPropertyDescription>]
	
	let queryParamParser: ParameterizedStringSetParser
	
	let forcedParametersOnFetch: [String: Any]
	let forcedValuesOnSave: [String: Any]
	
	func entityMapping(forEntity entity: DbEntityDescription) -> RESTEntityMapping<DbPropertyDescription>? {
		if let m = entitiesMapping[entity] {return m}
		guard let superentity = entity.superentity else {return nil}
		return entityMapping(forEntity: superentity as! DbEntityDescription /* See comment about SubSuperEntityType in DbRESTEntityDescription for explanation of the "as!" */)
	}
	
	/* We do not differentiate (mainly because we don't need it yet) between an
	 * entity not found in the mapping, an entity who does not have a uniquing
	 * type or an entity who have a `.none` uniquing type. */
	func entityUniquingType(forEntity entity: DbEntityDescription) -> RESTEntityUniquingType<DbPropertyDescription> {
		if let u = entitiesMapping[entity]?.uniquingType {return u}
		guard let superentity = entity.superentity else {return .none}
		return entityUniquingType(forEntity: superentity as! DbEntityDescription /* See comment about SubSuperEntityType in DbRESTEntityDescription for explanation of the "as!" */)
	}
	
	/** Will try and find the property mapping for the given property, starting
	from the given expected entity, then going up (superentities), then if still
	not found, going down (sub-entities). Will never go to an unrelated entity.
	
	If the expected entity is not given, all entities will be tested. */
	func propertyMapping(forProperty property: DbPropertyDescription, expectedEntity entity: DbEntityDescription?) -> RESTPropertyMapping? {
		guard let entity = entity else {return propertyMapping(forProperty: property)}
		return _propertyMapping(forProperty: property, expectedEntity: entity, canGoUp: true, canGoDown: true)
	}
	
	private func propertyMapping(forProperty property: DbPropertyDescription) -> RESTPropertyMapping? {
		for (entity, _) in entitiesMapping {
			if let r = propertyMapping(forProperty: property, expectedEntity: entity) {
				return r
			}
		}
		return nil
	}
	
	private func _propertyMapping(forProperty property: DbPropertyDescription, expectedEntity entity: DbEntityDescription, canGoUp: Bool, canGoDown: Bool) -> RESTPropertyMapping? {
		/* CoreData bug spotted:
		 *    - Entity A is parent of entity B and declares the property p;
		 *    - Asking CoreData the property description for the property p on A
		 *      or B will both return a valid property description (let's call
		 *      them p1 & p2);
		 *    - Both property descriptions returned are equal (p1 == p2 in the
		 *      Swift sense (not pointer equal, but isEqual: equal));
		 *    - However, they do **NOT** have the same hash! The property
		 *      description returned for B is a _proxy_ for the description of the
		 *      A property description. And apparently, Apple miscalculated the
		 *      hash in the proxy :(
		 * This is **NOT** a Swift/ObjC interoperability problem, as the same bug
		 * has been observed on an ObjC-only project.
		 *
		 * To “fix” this, if the subscript fetch in propertiesMapping for the
		 * given property returns nil, we check then if it wouldn't be set anyway
		 * using the property name, thus bypassing the hash.
		 * Indeed, the second check is much much slower...
		 *
		 * Without the bug, the whole if below is reduced to this simple line:
		 * if let m = entitiesMapping[entity]?.propertiesMapping[property] {return m}*/
		if let entityMapping = entitiesMapping[entity] {
			if let m = entityMapping.propertiesMapping[property] {return m}
			for (k, v) in entityMapping.propertiesMapping {
				if k.name == property.name {
					return v
				}
			}
		}
		/* Mapping not found, first let's go up if allowed. */
		if canGoUp, let superentity = entity.superentity {
			if let m = _propertyMapping(forProperty: property, expectedEntity: superentity as! DbEntityDescription, canGoUp: true, canGoDown: false) {
				return m
			}
		}
		/* Mapping still not found, let's go down if allowed. */
		if canGoDown {
			for subentity in entity.subentities {
				if let m = _propertyMapping(forProperty: property, expectedEntity: subentity as! DbEntityDescription, canGoUp: false, canGoDown: true) {
					return m
				}
			}
		}
		return nil
	}
	
}
