/*
 * Db+CoreData.swift
 * BMO+CoreData
 *
 * Created by François Lamboley on 2/5/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import CoreData

import BMO



extension NSManagedObjectContext : Db {
	
	public typealias ObjectType = NSManagedObject
	public typealias ObjectIDType = NSManagedObjectID
	public typealias FetchRequestType = NSFetchRequest<NSFetchRequestResult>
	
	public typealias EntityDescriptionType = NSEntityDescription
	public typealias PropertyDescriptionType = NSPropertyDescription
	
	public func performAndWait(_ block: () throws -> Void) rethrows {
		try withoutActuallyEscaping(block) { escapableBlock in
			var errorOnContext: Swift.Error? = nil
			self.performAndWait {
				do    {try escapableBlock()}
				catch {errorOnContext = error}
			}
			if let error = errorOnContext {throw error}
		}
	}
	
	/** Warning: Might return a temporary object ID... */
	public func unsafeObjectID(forObject object: NSManagedObject) -> NSManagedObjectID {
		return object.objectID
	}
	
	/** Warning: Might return a deleted object (if the object was deleted and the
	context not saved). */
	public func unsafeRetrieveExistingObject(fromObjectID objectID: NSManagedObjectID) throws -> NSManagedObject {
		return try existingObject(with: objectID)
		
		/* An alternative which does not return deleted objects. Another way to do
		 * this would simply be to check the object for the isDeleted property
		 * before returning it.
		let fetchRequest = NSFetchRequest<NSManagedObject>()
		fetchRequest.entity = objectID.entity
		fetchRequest.predicate = NSPredicate(format: "SELF == %@", objectID)
		guard let ret = try fetch(fetchRequest).first else {throw NSError(domain: ERR_DOMAIN, code: ERR_CODE, userInfo: nil)}
		return ret */
	}
	
}
