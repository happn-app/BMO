/*
 * BackResultsImporterForCoreDataWithFastImportRepresentation.swift
 * BMO+CoreData
 *
 * Created by François Lamboley on 07/06/2017.
 * Copyright © 2017 happn. All rights reserved.
 */

import CoreData
import Foundation

import BMO
import BMO_FastImportRepresentation



public class BackResultsImporterForCoreDataWithFastImportRepresentation<BridgeType : Bridge> : BackResultsImporter where BridgeType.DbType == NSManagedObjectContext {
	
	public func retrieveDbRepresentations(fromRemoteRepresentations remoteRepresentations: [BridgeType.RemoteObjectRepresentationType], expectedEntity entity: BridgeType.DbType.EntityDescriptionType, userInfo: BridgeType.UserInfoType, bridge: BridgeType, shouldContinueHandler: () -> Bool) -> Int {
		dbRepresentations = FastImportRepresentation.fastImportRepresentations(fromRemoteRepresentations: remoteRepresentations, expectedEntity: entity, userInfo: userInfo, bridge: bridge, shouldContinueHandler: shouldContinueHandler)
		return dbRepresentations.count
	}
	
	public func createAndPrepareDbImporter(rootMetadata: BridgeType.MetadataType?) throws {
		let resultBuilder = ResultBuilderType(metadata: rootMetadata)
		importer = FastImportRepresentationCoreDataImporter<ResultBuilderType>(representations: dbRepresentations, resultBuilder: resultBuilder)
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
