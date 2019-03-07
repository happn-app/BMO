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

import RESTUtils



extension NSEntityDescription : DbRESTEntityDescription {}
extension NSPropertyDescription : DbRESTPropertyDescription {
	public typealias EntityDescription = NSEntityDescription
	@objc public var valueType: AnyClass? {return nil}
	@objc public var destinationEntity: NSEntityDescription? {return nil}
}

extension NSAttributeDescription {
	public override var valueType: AnyClass? {
		/* We force cast in String? because while it is valid for the user info
		 * not to have a value for the forced class name key, if there is a value
		 * it is invalid that it is not a string. */
		if let forcedClassName = userInfo?["BMO_ObjCAttributeValueClassName"] as! String? {
			/* We assume if the user has set a forced class name, it has taken care
			 * for the class to actually be available in the ObjC runtime. */
			return NSClassFromString(forcedClassName)!
		}
		guard let className = attributeValueClassName else {
			if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Got an attribute description whose attributeValueClassName is nil; returning nil valueType. Attribute is %{public}@", log: $0, type: .info, self) }}
			else                                                          {NSLog("Got an attribute description whose attributeValueClassName is nil; returning nil valueType. Attribute is %@", self)}
			return nil
		}
		guard let objcClass = NSClassFromString(className) else {
			if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Got an attribute value class name (%{public}@) which is unreachable in the ObjC runtime; returning nil valueType. Attribute is %{public}@", log: $0, type: .info, className, self) }}
			else                                                          {NSLog("Got an attribute value class name (%@) which is unreachable in the ObjC runtime; returning nil valueType. Attribute is %{public}@", className, self)}
			return nil
		}
		return objcClass
	}
}



public typealias CoreDataRESTMapper = RESTMapper<NSEntityDescription, NSPropertyDescription>

public extension RESTMapper where DbEntityDescription == NSEntityDescription, DbPropertyDescription == NSPropertyDescription {
	
	convenience init(
		model: NSManagedObjectModel,
		defaultFieldsKeyName: String? = "fields", defaultPaginator: RESTPaginator? = nil, forcedParametersOnFetch: [String: Any]? = nil,
		restQueryParamParser: ParameterizedStringSetParser = StandardRESTParameterizedStringSetParser(),
		convenienceMapping: [String: [_RESTConvenienceMappingForEntity]]
	) {
		self.init(
			entityGetter: { model.entitiesByName[$0]! },
			propertyGetter: { $0.propertiesByName[$1]! },
			defaultFieldsKeyName: defaultFieldsKeyName,
			defaultPaginator: defaultPaginator,
			forcedParametersOnFetch: forcedParametersOnFetch,
			restQueryParamParser: restQueryParamParser,
			convenienceMapping: convenienceMapping
		)
	}
	
}
