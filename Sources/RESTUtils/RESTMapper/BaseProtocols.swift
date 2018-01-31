/*
 * BaseProtocols.swift
 * BMO
 *
 * Created by François Lamboley on 1/31/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public protocol DbRESTEntityDescription {
	
	/* Cannot constraint to DbRESTEntityDescription :( */
	associatedtype SubSuperEntityType
	
	/* SubSuperEntityType instead of Self because NSEntityDescription is not a final class :( */
	var superentity: SubSuperEntityType? {get}
	var subentities: [SubSuperEntityType] {get}
	
}


public protocol DbRESTPropertyDescription {
	
	associatedtype EntityDescription
	
	var name: String {get}
	var entity: EntityDescription {get}
	
	var isOptional: Bool {get}
	
	/** Returns the type of the attribute for attribute properties, nil for
	relationship properties (or for properties you don't want to type validate in
	general). */
	var valueType: AnyClass? {get}
	/** Returns the type of the destination entity for relationship properties.
	For other types of properties, return nil. */
	var destinationEntity: EntityDescription? {get}
	
}
