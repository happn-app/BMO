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

import BMO_CoreData
import RESTUtils



extension AdditionalRESTRequestInfo where DbPropertyDescription == NSPropertyDescriptionHashableWrapper {
	
	public init(flatifiedFields: String?, inEntity entity: NSEntityDescription, paginatorInfo: Any? = nil, keyPathPaginatorInfo: [String: Any]? = nil, keyPathForcedFieldsEntity: [String: NSEntityDescription]? = nil) {
		guard let flatifiedFields = flatifiedFields else {
			self.init()
			return
		}
		
		guard let pss = try? StandardRESTParameterizedStringSetParser().parse(flatifiedParam: flatifiedFields) else {fatalError("Invalid flatified params: \(flatifiedFields)")}
		self.init(parameters: ["fields": pss], inEntity: entity, paginatorInfo: paginatorInfo, keyPathPaginatorInfo: keyPathPaginatorInfo, keyPathForcedFieldsEntity: keyPathForcedFieldsEntity)
	}
	
	public init(parameters params: [String: ParameterizedStringSet], inEntity entity: NSEntityDescription?, paginatorInfo: Any? = nil, keyPathPaginatorInfo: [String: Any]? = nil, keyPathForcedFieldsEntity: [String: NSEntityDescription]? = nil) {
		var additionalRequestParametersBuilding = [String: Any]()
		var fetchedPropertiesBuilding = Set<NSPropertyDescriptionHashableWrapper>()
		var subAdditionalInfoBuilding = [NSPropertyDescriptionHashableWrapper: AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>]()
		for (paramName, paramValue) in params {
			switch paramName {
			case "fields":
				for (fieldName, v) in paramValue.valuesAndParams {
					guard let property = entity?.propertiesByName[fieldName]?.hashableWrapper() else {fatalError("Invalid fields \"\(fieldName)\" for entity named \(entity?.name ?? "<Unknown>") (property not found in entity)")}
					
					fetchedPropertiesBuilding.insert(property)
					let (subPaginatorInfo, subKeyPathPaginatorInfo) = AdditionalRESTRequestInfo.subKeyPathInfo(forField: fieldName, inKeyPathInfo: keyPathPaginatorInfo)
					let (subForcedEntity, subKeyPathForcedFieldsEntity) = AdditionalRESTRequestInfo.subKeyPathInfo(forField: fieldName, inKeyPathInfo: keyPathForcedFieldsEntity)
					if v.count > 0 {subAdditionalInfoBuilding[property] = AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>(parameters: v, inEntity: subForcedEntity ?? (property.wrappedProperty as? NSRelationshipDescription)?.destinationEntity, paginatorInfo: subPaginatorInfo, keyPathPaginatorInfo: subKeyPathPaginatorInfo, keyPathForcedFieldsEntity: subKeyPathForcedFieldsEntity)}
				}
				
			default:
				additionalRequestParametersBuilding[paramName] = StandardRESTParameterizedStringSetParser().flatify(param: paramValue)
			}
		}
		
		self.init(fetchedProperties: fetchedPropertiesBuilding, additionalRequestParameters: additionalRequestParametersBuilding, paginatorInfo: paginatorInfo ?? keyPathPaginatorInfo?[""], subAdditionalInfo: subAdditionalInfoBuilding)
	}
	
	private static func subKeyPathInfo<T>(forField field: String, inKeyPathInfo keyPathInfo: [String: T]?) -> (T?, [String: T]?) {
		guard let keyPathInfo = keyPathInfo else {return (nil, nil)}
		
		var subInfoBuilding: T? = nil
		var subKeyPathInfoBuilding = [String: T]()
		for (keyPath, value) in keyPathInfo where keyPath.hasPrefix(field) {
			let subKeyPath = keyPath.replacingCharacters(in: field.startIndex..<field.endIndex, with: "")
			if subKeyPath.isEmpty {
				subInfoBuilding = value
			} else if subKeyPath.first == "." {
				subKeyPathInfoBuilding[String(subKeyPath.dropFirst())] = value
			}
		}
		return (subInfoBuilding, subKeyPathInfoBuilding)
	}
	
}
