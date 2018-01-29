/*
 * CoreDataSaveRequest.swift
 * BMO+CoreData
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation

import BMO
import BMO_RESTUtils



public struct CoreDataSaveRequest : BackRequest {
	
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
	public let additionalRESTInfo: AdditionalRESTRequestInfo<NSPropertyDescription>?
	
	public let objectsToSave: [NSManagedObject]?
	
	/* TODO: Implement this properly */
	public let saveWorkflow: SaveWorkflow
	
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
	
	public func backRequestParts() throws -> [RequestPartId: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalRESTRequestInfo<NSPropertyDescription>>] {
		var res = [RequestPartId: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalRESTRequestInfo<NSPropertyDescription>>]()
		if let objectsToSave = objectsToSave {
			for object in objectsToSave {
				if      object.isDeleted  {res[object.objectID] = .delete(object, additionalRESTInfo); internals.deletedObjectIDs.insert(object.objectID)}
				else if object.isInserted {res[object.objectID] = .insert(object, additionalRESTInfo)}
				else if object.isUpdated  {res[object.objectID] = .update(object, additionalRESTInfo)}
			}
		} else {
			for deletedObject  in db.deletedObjects  {res[deletedObject.objectID]  = .delete(deletedObject,  additionalRESTInfo); internals.deletedObjectIDs.insert(deletedObject.objectID)}
			for insertedObject in db.insertedObjects {res[insertedObject.objectID] = .insert(insertedObject, additionalRESTInfo)}
			for updatedObject  in db.updatedObjects  {res[updatedObject.objectID]  = .update(updatedObject,  additionalRESTInfo)}
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
	
	public func dbForImportingResults(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalRESTRequestInfo<NSPropertyDescription>>, withId id: RequestPartId) -> NSManagedObjectContext? {
		return (!internals.deletedObjectIDs.contains(id) ? db : nil)
	}
	
	public func prepareResultsImport(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalRESTRequestInfo<NSPropertyDescription>>, withId id: RequestPartId, inDb db: NSManagedObjectContext) throws -> Bool {
		guard db.parent == nil else {db.saveToDiskOrRollback(); return false} /* We do not support sub-context with our current importers */
		return true
	}
	
	public func endResultsImport(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalRESTRequestInfo<NSPropertyDescription>>, withId id: NSManagedObjectContext.ObjectIDType, inDb db: NSManagedObjectContext, importResults: ImportResult<NSManagedObjectContext>) throws {
		assert(db.parent == nil)
		db.saveToDiskOrRollback()
	}
	
	public func processResultsImportError(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalRESTRequestInfo<NSPropertyDescription>>, withId id: NSManagedObjectContext.ObjectIDType, inDb db: NSManagedObjectContext, error: Swift.Error) {
		db.rollback()
	}
	
	private class Internals {
		var deletedObjectIDs = Set<NSManagedObjectID>()
	}
	private let internals = Internals()
	
}
