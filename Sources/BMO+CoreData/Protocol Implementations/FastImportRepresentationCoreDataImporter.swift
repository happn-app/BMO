/*
 * FastImportRepresentationCoreDataImporter.swift
 * BMO+CoreData
 *
 * Created by François Lamboley on 5/22/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import CoreData
import Foundation
import os.log

import BMO
import BMO_FastImportRepresentation



final class FastImportRepresentationCoreDataImporter<ResultBuilderType : SingleThreadDbRepresentationImporterResultBuilder> : DbRepresentationImporter
	where ResultBuilderType.DbType == NSManagedObjectContext
{
	
	typealias DbType = NSManagedObjectContext
	typealias DbRepresentationType = FastImportRepresentation<NSEntityDescription, NSManagedObject, ResultBuilderType.DbRepresentationUserInfoType>
	
	init(representations r: [DbRepresentationType], resultBuilder rb: ResultBuilderType) {
		resultBuilder = rb
		representations = r
	}
	
	func prepareImport() throws {
		extractUniquingIds(representations: representations)
	}
	
	func unsafeImport(in db: NSManagedObjectContext, updatingObject updatedObject: DbType.ObjectType?) throws -> ResultBuilderType.ResultType {
		var objectsByUniquingIds = [AnyHashable: NSManagedObject]()
		for (entity, uniquingIds) in uniquingIdsByEntity {
			let request = NSFetchRequest<NSManagedObject>()
			request.entity = entity
			if db.parent == nil {request.propertiesToFetch = ["zzRID"]} /* If setting propertiesToFetch when context has a parent we get a CoreData exception (corrupt database). Tested on iOS 10. */
			request.predicate = NSPredicate(format: "%K IN %@", "zzRID", uniquingIds)
			let objects = try db.fetch(request)
			
			for object in objects {
				guard let rid = object.value(forKey: "zzRID") as? AnyHashable else {assertionFailure("Well… This is unexpected! Didn't get an AnyHashable value for RID of object \(object)"); continue}
				objectsByUniquingIds[rid] = object
			}
		}
		
		/* The insertedObjects variable is only used to know the objects who need
		 * a permanent ID retrieval. */
		var insertedObjects = [NSManagedObject]()
		_ = try unsafeImport(representations: representations, in: db, updatingObject: updatedObject, isRootImport: true, resultBuilder: resultBuilder, prefetchedObjectsByUniquingIds: &objectsByUniquingIds, insertedObjects: &insertedObjects)
		return resultBuilder.result
	}
	
	private func extractUniquingIds(representations: [DbRepresentationType]) {
		for representation in representations {
			if let uniquingId = representation.uniquingId {
				var uniquingIds = uniquingIdsByEntity[representation.entity] ?? []
				uniquingIds.insert(uniquingId)
				uniquingIdsByEntity[representation.entity] = uniquingIds
			}
			for relationshipValueDescription in representation.relationships.values {
				if let relationshipRepresentations = relationshipValueDescription.value?.0 {
					extractUniquingIds(representations: relationshipRepresentations)
				}
			}
		}
	}
	
	private func unsafeImport(representations: [DbRepresentationType], in db: NSManagedObjectContext, updatingObject updatedObject: DbType.ObjectType?, isRootImport: Bool, resultBuilder: ResultBuilderType, prefetchedObjectsByUniquingIds uniqIdToObject: inout [AnyHashable: NSManagedObject], insertedObjects: inout [NSManagedObject]) throws -> [DbType.ObjectType] {
		if let updatedObject = updatedObject, updatedObject.isUsable {
			guard representations.count <= 1 else {
				throw ImportError.tooManyRepresentationsToUpdateObject
			}
			if let r = representations.first {
				guard updatedObject.entity.isKindOf(entity: r.entity) else {
					throw ImportError.updatedObjectAndRepresentedObjectEntitiesDoNotMatch
				}
				if let uid = r.uniquingId {
					if let currentObjectForUID = uniqIdToObject[uid] {
						if currentObjectForUID != updatedObject {
							/* We're told to forcibly update an object, but another
							 * object has already been created for the given UID. We
							 * must delete the object we were told to update; the
							 * caller will have to check whether its object has been
							 * deleted before using it. */
							db.delete(updatedObject)
						}
					} else {
						/* We are told to forcibly update an object, and we can do it! */
						let updatedObjectUID = updatedObject.value(forKey: "zzRID")
						if updatedObjectUID as? AnyHashable != uid {
							if updatedObjectUID != nil {
								/* Object we're asked to update does not have the same
								 * UID as the one we're given in the representation.
								 * We'll update the UID of the object but print a
								 * message in the logs first! */
								if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Asked to update object %@ but representation has UID %@. Updating UID (aka. \"zzRID\") of updating object (experimental; might lead to unexpected results).", log: $0, type: .info, updatedObject, String(describing: uid)) }}
								else                                                          {NSLog("Asked to update object %@ but representation has UID %@. Updating UID (aka. \"zzRID\") of updating object (experimental; might lead to unexpected results).", updatedObject, String(describing: uid))}
							}
							updatedObject.setValue(uid, forKey: "zzRID")
						}
						uniqIdToObject[uid] = updatedObject
					}
				}
			}
		}
		
		var res = [NSManagedObject]()
		for representation in representations {
			let object: NSManagedObject
			if let uid = representation.uniquingId {
				if let o = uniqIdToObject[uid] {object = o}
				else {
					/* If the object is not in the uniqIdToObject dictionary we have
					 * to create it. */
					object = NSEntityDescription.insertNewObject(forEntityName: representation.entity.name!, into: db)
					object.setValue(uid, forKey: "zzRID")
					uniqIdToObject[uid] = object
					insertedObjects.append(object)
					try resultBuilder.unsafeInserted(object: object, fromDb: db)
				}
			} else if let updatedObject = updatedObject, updatedObject.isUsable {
				/* If there is an updated object but no uniquing the updated object
				 * won't be in the uniqIdToObject dictionary. We have to treat this
				 * case by checking if updatedObject is not nil.
				 * We know we're updating the correct object as the representations
				 * array is checked to contain only one element. (Checked at the
				 * beginning of the method.) */
				assert(representations.count == 1)
				object = updatedObject
			} else {
				object = NSEntityDescription.insertNewObject(forEntityName: representation.entity.name!, into: db)
				insertedObjects.append(object)
				try resultBuilder.unsafeInserted(object: object, fromDb: db)
			}
			
			try resultBuilder.unsafeStartedImporting(object: object, inDb: db)
			
			for (k, v) in representation.attributes {object.setValue(v, forKey: k)}
			
			for (relationshipName, relationshipValue) in representation.relationships {
				let (valueAndMergeType, userInfo) = relationshipValue
				let subBuilder = try resultBuilder.unsafeStartImporting(relationshipName: relationshipName, userInfo: userInfo)
				guard let (value, mergeType) = valueAndMergeType else {
					object.setValue(nil, forKey: relationshipName)
					try subBuilder.unsafeFinishedImport(inDb: db)
					continue
				}
				
				let importedRelationshipValue = try unsafeImport(representations: value, in: db, updatingObject: nil, isRootImport: false, resultBuilder: subBuilder, prefetchedObjectsByUniquingIds: &uniqIdToObject, insertedObjects: &insertedObjects)
				let relationship = representation.entity.relationshipsByName[relationshipName]!
				if !relationship.isToMany {
					/* To-one relationship */
					if !mergeType.isReplace {
						if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Got merge type %{public}@ for a to-one relationship (%{public}@). Ignoring, using replace.", log: $0, type: .info, String(describing: mergeType), relationshipName) }}
						else                                                          {NSLog("Got merge type %{public}@ for a to-one relationship (%{public}@). Ignoring, using replace.", String(describing: mergeType), relationshipName)}
					}
					if importedRelationshipValue.count > 1 {
						if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Got %d values for a to-one relationship (%{public}@). Taking first value.", log: $0, type: .info, importedRelationshipValue.count, relationshipName) }}
						else                                                          {NSLog("Got %d values for a to-one relationship (%{public}@). Taking first value.", importedRelationshipValue.count, relationshipName)}
					}
					object.setValue(importedRelationshipValue.first, forKey: relationshipName)
				} else {
					/* To-many relationship */
					let isOrdered = relationship.isOrdered
					switch mergeType {
					case .replace: object.setValue(isOrdered ? NSOrderedSet(array: importedRelationshipValue) : NSSet(array: importedRelationshipValue), forKey: relationshipName)
					case .append:
						if isOrdered {
							let mutableRelationship = object.mutableOrderedSetValue(forKey: relationshipName)
							mutableRelationship.addObjects(from: importedRelationshipValue)
						} else {
							let mutableRelationship = object.mutableSetValue(forKey: relationshipName)
							mutableRelationship.addObjects(from: importedRelationshipValue)
						}
						
					case .insertAtBeginning:
						if isOrdered {
							let mutableRelationship = object.mutableOrderedSetValue(forKey: relationshipName)
							mutableRelationship.insert(importedRelationshipValue, at: IndexSet(integersIn: 0..<importedRelationshipValue.count))
						} else {
							let mutableRelationship = object.mutableSetValue(forKey: relationshipName)
							/* Inserting at the beginning of a non-ordered relationship
							 * does not mean much... */
							mutableRelationship.addObjects(from: importedRelationshipValue)
						}
						
					case .custom(mergeHandler: let handler):
						handler(object, relationshipName, importedRelationshipValue)
					}
				}
			}
			try resultBuilder.unsafeFinishedImportingCurrentObject(inDb: db)
			res.append(object)
		}
		if isRootImport {try db.obtainPermanentIDs(for: insertedObjects)}
		try resultBuilder.unsafeFinishedImport(inDb: db)
		return res
	}
	
	private let representations: [DbRepresentationType]
	private let resultBuilder: ResultBuilderType
	
	private var uniquingIdsByEntity = [NSEntityDescription: Set<AnyHashable>]()
	
}
