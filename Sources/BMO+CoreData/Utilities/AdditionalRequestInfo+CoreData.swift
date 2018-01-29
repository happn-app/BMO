/*
 * AdditionalRequestInfo+CoreData.swift
 * BMO+CoreData
 *
 * Created by François Lamboley on 1/29/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation

import BMO_RESTUtils



extension AdditionalRESTRequestInfo where DbPropertyDescription == NSPropertyDescription {
	
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
		var fetchedPropertiesBuilding = Set<NSPropertyDescription>()
		var subAdditionalInfoBuilding = [NSPropertyDescription: AdditionalRESTRequestInfo<NSPropertyDescription>]()
		for (paramName, paramValue) in params {
			switch paramName {
			case "fields":
				for (fieldName, v) in paramValue.valuesAndParams {
					guard let property = entity?.propertiesByName[fieldName] else {fatalError("Invalid fields \"\(fieldName)\" for entity named \(entity?.name ?? "<Unknown>") (property not found in entity)")}
					
					fetchedPropertiesBuilding.insert(property)
					let (subPaginatorInfo, subKeyPathPaginatorInfo) = AdditionalRESTRequestInfo.subKeyPathInfo(forField: fieldName, inKeyPathInfo: keyPathPaginatorInfo)
					let (subForcedEntity, subKeyPathForcedFieldsEntity) = AdditionalRESTRequestInfo.subKeyPathInfo(forField: fieldName, inKeyPathInfo: keyPathForcedFieldsEntity)
					if v.count > 0 {subAdditionalInfoBuilding[property] = AdditionalRESTRequestInfo<NSPropertyDescription>(parameters: v, inEntity: subForcedEntity ?? (property as? NSRelationshipDescription)?.destinationEntity, paginatorInfo: subPaginatorInfo, keyPathPaginatorInfo: subKeyPathPaginatorInfo, keyPathForcedFieldsEntity: subKeyPathForcedFieldsEntity)}
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
