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



public struct CoreDataFetchRequest<AdditionalInfoType> : BackRequest {
	
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
	public let additionalInfo: AdditionalInfoType?
	
	public let leaveBridgeHandler: (() -> Bool)? /* Called just after the bridge operations have been computed, on the context. */
	public let preImportHandler: (() -> Bool)? /* Return false if you want to stop the request before the import of the results. */
	public let preCompletionHandler: ((_ importResults: ImportResult<NSManagedObjectContext>) throws -> Void)?
	
	public init(context: NSManagedObjectContext, fetchRequest fr: NSFetchRequest<NSFetchRequestResult>, fetchType ft: FetchType, additionalInfo i: AdditionalInfoType?, leaveBridgeHandler lb: (() -> Bool)? = nil, preImportHandler pi: (() -> Bool)? = nil, preCompletionHandler pc: ((_ importResults: ImportResult<NSManagedObjectContext>) throws -> Void)? = nil) {
		db = context
		fetchRequest = fr
		fetchType = ft
		additionalInfo = i
		
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
	
	public func backRequestParts() throws -> [NSNull: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalInfoType>] {
		return [NSNull(): .fetch(fetchRequest, additionalInfo)]
	}
	
	public func leaveBridge() throws -> Bool {
		return leaveBridgeHandler?() ?? true
	}
	
	public func processBridgeError(_: Swift.Error) {
	}
	
	public func dbForImportingResults(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalInfoType>, withId id: NSNull) -> NSManagedObjectContext? {
		return db
	}
	
	public func prepareResultsImport(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalInfoType>, withId id: NSNull, inDb db: NSManagedObjectContext) throws -> Bool {
		return preImportHandler?() ?? true
	}
	
	public func endResultsImport(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalInfoType>, withId id: NSNull, inDb db: NSManagedObjectContext, importResults: ImportResult<NSManagedObjectContext>) throws {
		try preCompletionHandler?(importResults)
		try db.save()
	}
	
	public func processResultsImportError(ofRequestPart requestPart: BackRequestPart<NSManagedObject, NSFetchRequest<NSFetchRequestResult>, AdditionalInfoType>, withId id: NSNull, inDb db: NSManagedObjectContext, error: Swift.Error) {
		db.rollback()
	}
	
}
