/*
 * DbRepresentationImporter.swift
 * BMO
 *
 * Created by François Lamboley on 5/23/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation



public protocol DbRepresentationImporter {
	
	associatedtype DbType : Db
	associatedtype ResultType
	
	func prepareImport() throws
	
	/** Always called on the db context. */
	func unsafeImport(in db: DbType, updatingObject updatedObject: DbType.ObjectType?) throws -> ResultType
	
}

/* *********************************************
   MARK: - Single Thread Importer Result Builder
   ********************************************* */

/* RFC */
public protocol SingleThreadDbRepresentationImporterResultBuilder {

	associatedtype DbType : Db
	associatedtype DbRepresentationUserInfoType

	associatedtype ResultType

	func unsafeStartedImporting(object: DbType.ObjectType, inDb db: DbType) throws
	func unsafeStartImporting(relationshipName: String, userInfo: DbRepresentationUserInfoType?) throws -> Self
	func unsafeFinishedImportingCurrentObject(inDb db: DbType) throws

	func unsafeInserted(object: DbType.ObjectType, fromDb db: DbType) throws
	func unsafeUpdated(object: DbType.ObjectType, fromDb db: DbType) throws
	func unsafeDeleted(object: DbType.ObjectType, fromDb db: DbType) throws

	func unsafeFinishedImport(inDb db: DbType) throws

	/* Shall not be accessed before unsafeFinishedImport is called */
	var result: ResultType {get}

}
