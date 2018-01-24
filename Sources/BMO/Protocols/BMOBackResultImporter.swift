/*
 * BMOBackResultsImporter.swift
 * BMO
 *
 * Created by François Lamboley on 5/23/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation



public protocol BMOBackResultsImporter {
	
	associatedtype BridgeType : BMOBridge
	
	func retrieveDbRepresentations(fromRemoteRepresentations remoteRepresentations: [BridgeType.RemoteObjectRepresentationType], expectedEntity entity: BridgeType.DbType.EntityDescriptionType, userInfo: BridgeType.UserInfoType, bridge: BridgeType, shouldContinueHandler: () -> Bool) -> Int
	func createAndPrepareDbImporter(rootMetadata: BridgeType.MetadataType?) throws
	func unsafeImport(in db: BridgeType.DbType, updatingObject updatedObject: BridgeType.DbType.ObjectType?) throws -> BMOImportBridgeOperationResultsRequestOperation<BridgeType>.DbRepresentationImporterResultType
	
}


public struct AnyBMOBackResultsImporter<BridgeType : BMOBridge> : BMOBackResultsImporter {
	
	let retrieveDbRepresentationsHandler: (_ remoteRepresentations: [BridgeType.RemoteObjectRepresentationType], _ expectedEntity: BridgeType.DbType.EntityDescriptionType, _ userInfo: BridgeType.UserInfoType, _ bridge: BridgeType, _ shouldContinueHandler: () -> Bool) -> Int
	let createAndPrepareDbImporterHandler: (_ rootMetadata: BridgeType.MetadataType?) throws -> Void
	let unsafeImportHandler: (_ db: BridgeType.DbType, _ updatedObject: BridgeType.DbType.ObjectType?) throws -> BMOImportBridgeOperationResultsRequestOperation<BridgeType>.DbRepresentationImporterResultType
	
	public init<BackResultsImporterType : BMOBackResultsImporter>(importer: BackResultsImporterType) where BackResultsImporterType.BridgeType == BridgeType {
		retrieveDbRepresentationsHandler = importer.retrieveDbRepresentations
		createAndPrepareDbImporterHandler = importer.createAndPrepareDbImporter
		unsafeImportHandler = importer.unsafeImport
	}
	
	public func retrieveDbRepresentations(fromRemoteRepresentations remoteRepresentations: [BridgeType.RemoteObjectRepresentationType], expectedEntity entity: BridgeType.DbType.EntityDescriptionType, userInfo: BridgeType.UserInfoType, bridge: BridgeType, shouldContinueHandler: () -> Bool) -> Int {
		return retrieveDbRepresentationsHandler(remoteRepresentations, entity, userInfo, bridge, shouldContinueHandler)
	}
	
	public func createAndPrepareDbImporter(rootMetadata: BridgeType.MetadataType?) throws {
		return try createAndPrepareDbImporterHandler(rootMetadata)
	}
	
	public func unsafeImport(in db: BridgeType.DbType, updatingObject updatedObject: BridgeType.DbType.ObjectType?) throws -> BMOImportBridgeOperationResultsRequestOperation<BridgeType>.DbRepresentationImporterResultType {
		return try unsafeImportHandler(db, updatedObject)
	}
	
}


public protocol AnyBMOBackResultsImporterFactory {
	
	func createResultsImporter<BridgeType : BMOBridge>() -> AnyBMOBackResultsImporter<BridgeType>?
	
}
