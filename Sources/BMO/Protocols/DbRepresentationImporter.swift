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

import Foundation



/* Note: This protocol is not used directly in BMO yet (but new requests type
 *       will be created that will need it). */
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
