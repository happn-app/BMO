/*
 * CoreDataFetchRequest.swift
 * BMO+CoreData
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation

import BMO
import BMO_RESTUtils



public struct CoreDataFetchRequest : BackRequest {
	
	public typealias DbType = NSManagedObjectContext
	public typealias RequestPartId = NSNull
	
	public enum FetchType {
		case always
		case onlyIfNoLocalResults
		case never
	}
	
	public let db: NSManagedObjectContext
	public let fetchRequest: NSFetchRequest<NSFetchRequestResult>
	
	public let fetchType: FetchType
	public let additionalRESTInfo: AdditionalRESTRequestInfo<NSPropertyDescription>?
	
	public let leaveBridgeHandler: (() -> Bool)? /* Called just after the bridge operations have been computed, on the context. */
	public let preImportHandler: (() -> Bool)? /* Return false if you want to stop the request before the import of the results. */
	public let preCompletionHandler: ((_ importResults: ImportResult<NSManagedObjectContext>) throws -> Void)?
	
	public init(context: NSManagedObjectContext, entity: NSEntityDescription, resultType: NSFetchRequestResultType = .managedObjectResultType, remoteId: String, remoteIdPropertyName: String = "remoteId", flatifiedFields: String?, alwaysFetchProperties: Bool, leaveBridgeHandler lb: (() -> Bool)? = nil, preImportHandler pi: (() -> Bool)? = nil, preCompletionHandler pc: ((_ importResults: ImportResult<NSManagedObjectContext>) throws -> Void)? = nil) {
		let fRequest = NSFetchRequest<NSFetchRequestResult>()
		fRequest.entity = entity
		fRequest.resultType = resultType
		fRequest.predicate = NSPredicate(format: "%K == %@", remoteIdPropertyName, remoteId)
		
		db = context
		fetchRequest = fRequest
		fetchType = (alwaysFetchProperties || !(flatifiedFields?.isEmpty ?? true)) ? .always : .onlyIfNoLocalResults
		additionalRESTInfo = AdditionalRESTRequestInfo<NSPropertyDescription>(flatifiedFields: flatifiedFields, inEntity: entity)
		
		leaveBridgeHandler = lb
		preImportHandler = pi
		preCompletionHandler = pc
	}
	
	public init(context: NSManagedObjectContext, fetchRequest fr: NSFetchRequest<NSFetchRequestResult>, fetchType ft: FetchType, additionalRESTInfo i: AdditionalRESTRequestInfo<NSPropertyDescription>?, leaveBridgeHandler lb: (() -> Bool)? = nil, preImportHandler pi: (() -> Bool)? = nil, preCompletionHandler pc: ((_ importResults: ImportResult<NSManagedObjectContext>) throws -> Void)? = nil) {
		db = context
		fetchRequest = fr
		fetchType = ft
		additionalRESTInfo = i
		
		leaveBridgeHandler = lb
		preImportHandler = pi
		preCompletionHandler = pc
	}
	
	public func unsafeExecute() throws -> [NSFetchRequestResult] {
		return try db.fetch(fetchRequest)
	}
	
	public var needsEnteringBridgeOnContext: Bool {
		return fetchType == .onlyIfNoLocalResults
	}
	
	public var needsRetrievingBackRequestPartsOnContext: Bool {
		return false
	}
	
	public func enterBridge() throws -> Bool {
		/* Note: We might wanna avoid fetching the entity if it is already set,
		 *       however, it is difficult checking whether the entity has been
		 *       set. Indeed, if the property is accessed before being set, an
		 *       execption is thrown... */
		fetchRequest.entity = db.persistentStoreCoordinator!.managedObjectModel.entitiesByName[fetchRequest.entityName!]
		switch fetchType {
		case .always:               return true
		case .onlyIfNoLocalResults: return try db.count(for: fetchRequest) == 0
		case .never:                return false
		}
	}
	
	public func backRequestParts() throws -> [NSNull: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalRESTRequestInfo<NSPropertyDescription>>] {
		return [NSNull(): .fetch(fetchRequest, additionalRESTInfo)]
	}
	
	public func leaveBridge() throws -> Bool {
		return leaveBridgeHandler?() ?? true
	}
	
	public func processBridgeError(_: Swift.Error) {
	}
	
	public func dbForImportingResults(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalRESTRequestInfo<NSPropertyDescription>>, withId id: NSNull) -> NSManagedObjectContext? {
		return db
	}
	
	public func prepareResultsImport(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalRESTRequestInfo<NSPropertyDescription>>, withId id: NSNull, inDb db: NSManagedObjectContext) throws -> Bool {
		return preImportHandler?() ?? true
	}
	
	public func endResultsImport(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalRESTRequestInfo<NSPropertyDescription>>, withId id: NSNull, inDb db: NSManagedObjectContext, importResults: ImportResult<NSManagedObjectContext>) throws {
		try preCompletionHandler?(importResults)
		try db.save()
	}
	
	public func processResultsImportError(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalRESTRequestInfo<NSPropertyDescription>>, withId id: NSNull, inDb db: NSManagedObjectContext, error: Swift.Error) {
		db.rollback()
	}
	
}
