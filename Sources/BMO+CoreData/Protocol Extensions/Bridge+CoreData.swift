/*
 * Bridge+CoreData.swift
 * BMO+CoreData
 *
 * Created by François Lamboley on 1/31/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation

import BMO



/* Swift Note: We can either tag the whole extension as public, in which case
 * there is no need to tag its functions public for them to be seen by clients,
 * or let the extension as internal and tag all the functions as public. */
public extension Bridge where DbType.FetchRequestType == NSFetchRequest<NSFetchRequestResult>, DbType.ObjectType == NSManagedObject, DbType.EntityDescriptionType == NSEntityDescription {
	
	func expectedResultEntity(forFetchRequest fetchRequest: DbType.FetchRequestType, additionalInfo: AdditionalRequestInfoType?) -> DbType.EntityDescriptionType? {
		return fetchRequest.entity
	}
	
	func expectedResultEntity(forObject object: DbType.ObjectType) -> DbType.EntityDescriptionType? {
		return object.entity
	}
	
}
