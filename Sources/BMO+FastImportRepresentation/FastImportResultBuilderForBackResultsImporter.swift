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

import CoreData /* We treat a special CoreData case in this file */
import Foundation

import BMO



/* So. This class takes a very specific case into account: Temporary Object IDs
 * in a Core Data Db.
 *
 * When an object is inserted in Core Data, it is assigned a temporary object ID
 * which is then converted to a permanent ID when the db is saved, or when the
 * obtainPermanentIDs method is called.
 *
 * To avoid calling the obtainPermanentIDs method each time an object is
 * inserted in the import, we simply call the method when all of the objects
 * have been inserted (in the FastImportRepresentationCoreDataImporter).
 * In the result builder (this class), when the import is over, if we’re a root
 * result builder, we’ll convert all objects whose objectID is temporary to a
 * permanent objectID.
 *
 * To avoid having temporary IDs in the bridge back request result, we do NOT
 * return the relationships. (Otherwise we’d have to iterate on all of the
 * relationships recursively to retrieve the permanent IDs for all the objects.)
 *
 * Note: We might be in a case of early optimization. Retrieving the permanent
 *       object ID after each insert might be an acceptable solution (and it
 *       would allow having the relationships in the bridge back result without
 *       having to iterate recursively over them). */
public final class FastImportResultBuilderForBackResultsImporter<BridgeType : Bridge> : SingleThreadDbRepresentationImporterResultBuilder {
	
	public typealias DbType = BridgeType.DbType
	public typealias DbRepresentationUserInfoType = BridgeType.MetadataType
	
	let metadata: BridgeType.MetadataType?
	
	var importResult: ImportResult<DbType> {
		return ImportResult(rootObjectsAndRelationships: objectsAndRelationships, changes: nil)
	}
	
	var bridgeBackRequestResult: BridgeBackRequestResult<BridgeType> {
		return BridgeBackRequestResult(metadata: metadata, returnedObjectIDsAndRelationships: objectIDs.map{ (objectID: $0, relationships: nil) }, asyncChanges: nil)
	}
	
	public var result: ImportBridgeOperationResultsRequestOperation<BridgeType>.DbRepresentationImporterResultType {
		return (importResult: importResult, bridgeBackRequestResult: bridgeBackRequestResult)
	}
	
	public init(metadata m: BridgeType.MetadataType?, parent p: FastImportResultBuilderForBackResultsImporter? = nil) {
		metadata = m
		parent = p
	}
	
	public func unsafeStartedImporting(object: DbType.ObjectType, inDb db: DbType) {
		assert(currentlyBuiltObject == nil)
		assert(currentlyBuiltObjectRelationships.count == 0)
		
		currentlyBuiltObject = object
	}
	
	public func unsafeStartImporting(relationshipName: String, userInfo: BridgeType.MetadataType?) -> FastImportResultBuilderForBackResultsImporter {
		let res = FastImportResultBuilderForBackResultsImporter(metadata: userInfo, parent: self)
		currentlyBuiltObjectRelationships[relationshipName] = res
		return res
	}
	
	public func unsafeFinishedImportingCurrentObject(inDb db: DbType) {
		var fastImportRelationships = [String: ImportResult<DbType>]()
		var bridgeBackRelationships = [String: BridgeBackRequestResult<BridgeType>]()
		currentlyBuiltObjectRelationships.forEach {
			fastImportRelationships[$0.key] = $0.value.importResult
			bridgeBackRelationships[$0.key] = $0.value.bridgeBackRequestResult
		}
		
		let objectID = db.unsafeObjectID(forObject: currentlyBuiltObject!)
		hasTemporaryIDs = hasTemporaryIDs || ((objectID as? NSManagedObjectID)?.isTemporaryID ?? false)
		
		objectIDs.append(objectID)
		objectsAndRelationships.append((object: currentlyBuiltObject!, relationships: fastImportRelationships))
		
		currentlyBuiltObjectRelationships.removeAll()
		currentlyBuiltObject = nil
	}
	
	public func unsafeInserted(object: DbType.ObjectType, fromDb db: DbType) {
		/* We won't report changes and async changes in the fast import results
		 * and the bridge back request results, so we'll just nop here. */
	}
	
	public func unsafeUpdated(object: DbType.ObjectType, fromDb db: DbType) {
		/* We won't report changes and async changes in the fast import results
		 * and the bridge back request results, so we'll just nop here. */
	}
	
	public func unsafeDeleted(object: DbType.ObjectType, fromDb db: DbType) {
		/* We won't report changes and async changes in the fast import results
		 * and the bridge back request results, so we'll just nop here. */
	}
	
	public func unsafeFinishedImport(inDb db: DbType) throws {
		if parent == nil, hasTemporaryIDs {
			let originalObjectIDs = objectIDs
			objectIDs.removeAll()
			for (idx, currentObjectID) in originalObjectIDs.enumerated() {
				guard let objectID = currentObjectID as? NSManagedObjectID, objectID.isTemporaryID else {
					objectIDs.append(currentObjectID)
					continue
				}
				
				let newObjectID = (objectsAndRelationships[idx].object as! NSManagedObject).objectID
				assert(!newObjectID.isTemporaryID)
				
				objectIDs.append(newObjectID as! BridgeType.DbType.ObjectIDType)
			}
		}
	}
	
	private let parent: FastImportResultBuilderForBackResultsImporter?
	
	private var hasTemporaryIDs = false
	
	private var objectsAndRelationships = Array<(object: DbType.ObjectType, relationships: [String: ImportResult<DbType>]?)>()
	private var objectIDs = Array<DbType.ObjectIDType>()
	
	private var currentlyBuiltObject: DbType.ObjectType?
	private var currentlyBuiltObjectRelationships = [String: FastImportResultBuilderForBackResultsImporter]()
	
}
