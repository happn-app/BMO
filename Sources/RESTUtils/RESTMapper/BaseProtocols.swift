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
	For other types of properties, returns nil. */
	var destinationEntity: EntityDescription? {get}
	
}
