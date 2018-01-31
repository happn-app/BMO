/*
 * CoreData+RESTMapper.swift
 * BMO+RESTCoreData
 *
 * Created by François Lamboley on 1/31/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation

import RESTUtils



extension NSEntityDescription : DbRESTEntityDescription {}
extension NSPropertyDescription : DbRESTPropertyDescription {
	public typealias EntityDescription = NSEntityDescription
	@objc public var valueType: AnyClass? {return nil}
	@objc public var destinationEntity: NSEntityDescription? {return nil}
}

extension NSAttributeDescription {
	public override var valueType: AnyClass? {return attributeValueClassName.flatMap{ NSClassFromString($0)!}}
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
