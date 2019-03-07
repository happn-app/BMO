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

import BMO



public struct CoreDataSaveRequest<AdditionalInfoType> : BackRequest {
	
	public typealias DbType = NSManagedObjectContext
	public typealias RequestPartId = DbType.ObjectIDType
	
	public enum SaveWorkflow {
		case saveBeforeBackReturns
		/* TODO: Technically this mode is not fully supported yet.
		 * - Because we want to always have a non-modified Core Data view context,
		 *   we have to allow using this workflow from a child context.
		 * - When using a sub-context, the back results are not imported because
		 *   the importer we use today do not support sub-contexts (no inter-
		 *   context locking). A modification to BMO would allow us to change the
		 *   importer per request part. See TODO in Request. */
		case saveAfterBackReturns
		case rollbackBeforeBackReturns
		case doNothing
	}
	
	public let db: NSManagedObjectContext
	public let additionalInfo: AdditionalInfoType?
	
	public let objectsToSave: [NSManagedObject]?
	
	/* TODO: Implement this properly */
	public let saveWorkflow: SaveWorkflow
	
	public init(db database: NSManagedObjectContext, additionalInfo i: AdditionalInfoType?, objectsToSave o: [NSManagedObject]?, saveWorkflow w: SaveWorkflow) {
		db = database
		additionalInfo = i
		objectsToSave = o
		saveWorkflow = w
	}
	
	public var needsEnteringBridgeOnContext: Bool {
		return true
	}
	
	public var needsRetrievingBackRequestPartsOnContext: Bool {
		return true
	}
	
	public func enterBridge() throws -> Bool {
		assert(db.parent == nil || saveWorkflow == .saveAfterBackReturns || saveWorkflow == .rollbackBeforeBackReturns)
		guard db.hasChanges else {return false}
		
		db.processPendingChanges()
		try db.obtainPermanentIDs(for: Array(db.insertedObjects))
		return true
	}
	
	public func backRequestParts() throws -> [RequestPartId: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalInfoType>] {
		var res = [RequestPartId: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalInfoType>]()
		if let objectsToSave = objectsToSave {
			for object in objectsToSave {
				if      object.isDeleted  {res[object.objectID] = .delete(object, additionalInfo); internals.deletedObjectIDs.insert(object.objectID)}
				else if object.isInserted {res[object.objectID] = .insert(object, additionalInfo)}
				else if object.isUpdated  {res[object.objectID] = .update(object, additionalInfo)}
			}
		} else {
			for deletedObject  in db.deletedObjects  {res[deletedObject.objectID]  = .delete(deletedObject,  additionalInfo); internals.deletedObjectIDs.insert(deletedObject.objectID)}
			for insertedObject in db.insertedObjects {res[insertedObject.objectID] = .insert(insertedObject, additionalInfo)}
			for updatedObject  in db.updatedObjects  {res[updatedObject.objectID]  = .update(updatedObject,  additionalInfo)}
		}
		return res
	}
	
	public func leaveBridge() throws -> Bool {
		if      saveWorkflow == .saveBeforeBackReturns     {try db.save()}
		else if saveWorkflow == .rollbackBeforeBackReturns {db.rollback()}
		return true
	}
	
	public func processBridgeError(_: Swift.Error) {
		/* Not sure if we should rollback or save 🤔 */
		db.rollback()
	}
	
	public func dbForImportingResults(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalInfoType>, withId id: RequestPartId) -> NSManagedObjectContext? {
		return (!internals.deletedObjectIDs.contains(id) ? db : nil)
	}
	
	public func prepareResultsImport(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalInfoType>, withId id: RequestPartId, inDb db: NSManagedObjectContext) throws -> Bool {
		guard db.parent == nil else {db.saveToDiskOrRollback(); return false} /* We do not support sub-context with our current importers */
		return true
	}
	
	public func endResultsImport(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalInfoType>, withId id: NSManagedObjectContext.ObjectIDType, inDb db: NSManagedObjectContext, importResults: ImportResult<NSManagedObjectContext>) throws {
		assert(db.parent == nil)
		db.saveToDiskOrRollback()
	}
	
	public func processResultsImportError(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalInfoType>, withId id: NSManagedObjectContext.ObjectIDType, inDb db: NSManagedObjectContext, error: Swift.Error) {
		db.rollback()
	}
	
	private class Internals {
		var deletedObjectIDs = Set<NSManagedObjectID>()
	}
	private let internals = Internals()
	
}
