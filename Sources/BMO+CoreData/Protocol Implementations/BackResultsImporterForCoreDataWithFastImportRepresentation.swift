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
import BMO_FastImportRepresentation



public class BackResultsImporterForCoreDataWithFastImportRepresentation<BridgeType : Bridge> : BackResultsImporter where BridgeType.DbType == NSManagedObjectContext {
	
	/**
	The property the importer will use to do the uniquing. Must be an attribute
	(of any type); NOT a relationship.
	
	All of the entities of the objects that will be imported **must** have an
	attribute that have this name.
	
	If a fast import representation has a uniquing id and the uniquing property
	name is in the attributes of the fast import representation, it will be
	assert'd that the value of the uniquing property name attribute is equal to
	the given uniquing id. It is also always asserted that the uniquing property
	name is NOT in the relationship keys of the representation. Examples:
	
	    - uniquingPropertyName = "remoteId"
	    - fastImportRepresentation.uniquingId = "42"
	    - fastImportRepresentation.attributes = ["remoteId": "42", "name": "toto"]
	       -> OK
	
	    - uniquingPropertyName = "remoteId"
	    - fastImportRepresentation.uniquingId = "User/42"
	    - fastImportRepresentation.attributes = ["remoteId": "42", "name": "toto"]
	       -> "User/42" != "42": NOT OK (assertion failure at runtime in debug mode)
	
	    - uniquingPropertyName = "remoteId"
	    - fastImportRepresentation.uniquingId = 42
	    - fastImportRepresentation.attributes = ["remoteId": "42", "name": "toto"]
	       -> "42" != 42 (type mismatch): NOT OK (assertion failure at runtime in debug mode)
	
	    - uniquingPropertyName = "zzBID" /* BID for BMO ID, of course! */
	    - fastImportRepresentation.uniquingId = "User/42"
	    - fastImportRepresentation.attributes = ["remoteId": "42", "name": "toto"]
	       -> "zzBID" is not in the keys of the attributes: OK
	
	    - uniquingPropertyName = "zzBID"
	    - fastImportRepresentation.uniquingId = "User/42"
	    - fastImportRepresentation.attributes = ["remoteId": "42", "name": "toto"]
	    - fastImportRepresentation.relationships = ["zzBID": ...]
	       -> "zzBID" is in the keys of the relationships: NOT OK (assertion failure at runtime in debug mode)
	*/
	public let uniquingPropertyName: String
	
	public init(uniquingPropertyName p: String) {
		uniquingPropertyName = p
	}
	
	public func retrieveDbRepresentations(fromRemoteRepresentations remoteRepresentations: [BridgeType.RemoteObjectRepresentationType], expectedEntity entity: BridgeType.DbType.EntityDescriptionType, userInfo: BridgeType.UserInfoType, bridge: BridgeType, shouldContinueHandler: () -> Bool) -> Int {
		dbRepresentations = FastImportRepresentation.fastImportRepresentations(fromRemoteRepresentations: remoteRepresentations, expectedEntity: entity, userInfo: userInfo, bridge: bridge, shouldContinueHandler: shouldContinueHandler)
		return dbRepresentations.count
	}
	
	public func createAndPrepareDbImporter(rootMetadata: BridgeType.MetadataType?) throws {
		let resultBuilder = ResultBuilderType(metadata: rootMetadata)
		importer = FastImportRepresentationCoreDataImporter<ResultBuilderType>(uniquingPropertyName: uniquingPropertyName, representations: dbRepresentations, resultBuilder: resultBuilder)
		try importer.prepareImport()
	}
	
	public func unsafeImport(in db: BridgeType.DbType, updatingObject updatedObject: BridgeType.DbType.ObjectType?) throws -> (importResult: ImportResult<BridgeType.DbType>, bridgeBackRequestResult: BridgeBackRequestResult<BridgeType>) {
		return try importer.unsafeImport(in: db, updatingObject: updatedObject)
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private typealias ResultBuilderType = FastImportResultBuilderForBackResultsImporter<BridgeType>
	private typealias ResultType = ImportBridgeOperationResultsRequestOperation<BridgeType>.DbRepresentationImporterResultType
	
	private var importer: FastImportRepresentationCoreDataImporter<ResultBuilderType>!
	private var dbRepresentations: [FastImportRepresentation<BridgeType.DbType.EntityDescriptionType, BridgeType.DbType.ObjectType, BridgeType.MetadataType>]!
	
}
