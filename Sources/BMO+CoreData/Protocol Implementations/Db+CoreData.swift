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
