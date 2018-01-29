/*
 * CoreDataUtils.swift
 * BMO+CoreData
 *
 * Created by François Lamboley on 1/29/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData

import BMO_RESTUtils



extension NSManagedObjectContext {
	
	func saveOrRollback() {
		do    {try save()}
		catch {rollback()}
	}
	
	func saveToDiskOrRollback() {
		do {
			try save()
			
			/* Let's save the parent contexts */
			guard let parent = parent else {return}
			parent.performAndWait{ parent.saveToDiskOrRollback() }
		} catch {
			rollback()
		}
	}
	
}


extension NSManagedObject {
	
	var isUsable: Bool {
		return !isDeleted && managedObjectContext != nil
	}
	
}

extension NSManagedObject : RESTPathKeyResovable {
	
	public func restPathObject(for key: String) -> Any? {
		guard entity.propertiesByName.keys.contains(key) else {return nil}
		return value(forKey: key)
	}
	
}
