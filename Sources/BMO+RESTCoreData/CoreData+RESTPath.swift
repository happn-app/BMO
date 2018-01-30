/*
 * CoreDataUtils.swift
 * BMO+RESTCoreData
 *
 * Created by François Lamboley on 1/30/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData

import RESTUtils



extension NSManagedObject : RESTPathKeyResovable {
	
	public func restPathObject(for key: String) -> Any? {
		guard entity.propertiesByName.keys.contains(key) else {return nil}
		return value(forKey: key)
	}
	
}
