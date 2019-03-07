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



public protocol BackResultsImporter {
	
	associatedtype BridgeType : Bridge
	
	func retrieveDbRepresentations(fromRemoteRepresentations remoteRepresentations: [BridgeType.RemoteObjectRepresentationType], expectedEntity entity: BridgeType.DbType.EntityDescriptionType, userInfo: BridgeType.UserInfoType, bridge: BridgeType, shouldContinueHandler: () -> Bool) -> Int
	func createAndPrepareDbImporter(rootMetadata: BridgeType.MetadataType?) throws
	func unsafeImport(in db: BridgeType.DbType, updatingObject updatedObject: BridgeType.DbType.ObjectType?) throws -> ImportBridgeOperationResultsRequestOperation<BridgeType>.DbRepresentationImporterResultType
	
}


public struct AnyBackResultsImporter<BridgeType : Bridge> : BackResultsImporter {
	
	let retrieveDbRepresentationsHandler: (_ remoteRepresentations: [BridgeType.RemoteObjectRepresentationType], _ expectedEntity: BridgeType.DbType.EntityDescriptionType, _ userInfo: BridgeType.UserInfoType, _ bridge: BridgeType, _ shouldContinueHandler: () -> Bool) -> Int
	let createAndPrepareDbImporterHandler: (_ rootMetadata: BridgeType.MetadataType?) throws -> Void
	let unsafeImportHandler: (_ db: BridgeType.DbType, _ updatedObject: BridgeType.DbType.ObjectType?) throws -> ImportBridgeOperationResultsRequestOperation<BridgeType>.DbRepresentationImporterResultType
	
	public init<BackResultsImporterType : BackResultsImporter>(importer: BackResultsImporterType) where BackResultsImporterType.BridgeType == BridgeType {
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
	
	public func unsafeImport(in db: BridgeType.DbType, updatingObject updatedObject: BridgeType.DbType.ObjectType?) throws -> ImportBridgeOperationResultsRequestOperation<BridgeType>.DbRepresentationImporterResultType {
		return try unsafeImportHandler(db, updatedObject)
	}
	
}


public protocol AnyBackResultsImporterFactory {
	
	func createResultsImporter<BridgeType : Bridge>() -> AnyBackResultsImporter<BridgeType>?
	
}
