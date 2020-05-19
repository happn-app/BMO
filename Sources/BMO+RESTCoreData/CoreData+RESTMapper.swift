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

import CoreData
import Foundation
import os.log

import BMO
import BMO_CoreData
import RESTUtils



extension NSEntityDescription : DbRESTEntityDescription {}

extension NSPropertyDescriptionHashableWrapper : DbRESTPropertyDescription {
	
	public typealias EntityDescription = NSEntityDescription
	
	public var name: String {
		return wrappedProperty.name
	}
	
	public var entity: NSEntityDescription {
		return wrappedProperty.entity
	}
	
	public var isOptional: Bool {
		return wrappedProperty.isOptional
	}
	
	public var valueType: AnyClass? {
		switch wrappedProperty {
		case let attributeDescription as NSAttributeDescription:
			/* We force cast in String? because while it is valid for the user info
			  * not to have a value for the forced class name key, if there is a value
			  * it is invalid that it is not a string. */
			if let forcedClassName = attributeDescription.userInfo?["BMO_ObjCAttributeValueClassName"] as! String? {
				/* We assume if the user has set a forced class name, it has taken care
				  * for the class to actually be available in the ObjC runtime. */
				return NSClassFromString(forcedClassName)!
			}
			guard let className = attributeDescription.attributeValueClassName else {
				if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Got an attribute description whose attributeValueClassName is nil; returning nil valueType. Wrapped attribute is %{public}@", log: $0, type: .info, self.wrappedProperty) }}
				else                                                          {NSLog("Got an attribute description whose attributeValueClassName is nil; returning nil valueType. Wrapped attribute is %@", self.wrappedProperty)}
				return nil
			}
			guard let objcClass = NSClassFromString(className) else {
				if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Got an attribute value class name (%{public}@) which is unreachable in the ObjC runtime; returning nil valueType. Wrapped attribute is %{public}@", log: $0, type: .info, className, self.wrappedProperty) }}
				else                                                          {NSLog("Got an attribute value class name (%@) which is unreachable in the ObjC runtime; returning nil valueType. Wrapped attribute is %@", className, self.wrappedProperty)}
				return nil
			}
			return objcClass
			
		default:
			return nil
		}
	}
	
	public var destinationEntity: NSEntityDescription? {
		switch wrappedProperty {
		case                           _ as NSAttributeDescription:       return nil
		case                           _ as NSExpressionDescription:      return nil
		case                           _ as NSFetchedPropertyDescription: return nil
		case let relationshipDescription as NSRelationshipDescription:    return relationshipDescription.destinationEntity
		default:
			if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Got a property description whose type is unknown when computing the destination entity: %{public}@", log: $0, type: .info, self.wrappedProperty) }}
			else                                                          {NSLog("Got a property description whose type is unknown when computing the destination entity: %@", self.wrappedProperty)}
			return nil
		}
	}
	
}



public typealias CoreDataRESTMapper = RESTMapper<NSEntityDescription, NSPropertyDescriptionHashableWrapper>

public extension RESTMapper where DbEntityDescription == NSEntityDescription, DbPropertyDescription == NSPropertyDescriptionHashableWrapper {
	
	convenience init(
		model: NSManagedObjectModel,
		defaultFieldsKeyName: String? = "fields", defaultPaginator: RESTPaginator? = nil, forcedParametersOnFetch: [String: Any]? = nil,
		restQueryParamParser: ParameterizedStringSetParser = StandardRESTParameterizedStringSetParser(),
		convenienceMapping: [String: [_RESTConvenienceMappingForEntity]]
	) {
		self.init(
			entityGetter: { model.entitiesByName[$0]! },
			propertyGetter: { $0.propertiesByName[$1]!.hashableWrapper() },
			defaultFieldsKeyName: defaultFieldsKeyName,
			defaultPaginator: defaultPaginator,
			forcedParametersOnFetch: forcedParametersOnFetch,
			restQueryParamParser: restQueryParamParser,
			convenienceMapping: convenienceMapping
		)
	}
	
}
