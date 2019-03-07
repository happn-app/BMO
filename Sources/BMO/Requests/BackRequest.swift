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



public enum BackRequestPart<DbObjectType, DbFetchRequestType, DbAdditionalInfoType> {
	
	case fetch(DbFetchRequestType, DbAdditionalInfoType?)
	case insert(DbObjectType, DbAdditionalInfoType?)
	case update(DbObjectType, DbAdditionalInfoType?)
	case delete(DbObjectType, DbAdditionalInfoType?)
	
}

public protocol BackRequest {
	
	associatedtype DbType : Db
	associatedtype AdditionalRequestInfoType
	
	associatedtype RequestPartId: Hashable
	
	var db: DbType {get}
	
	/** For some requests, entering the bridge is not required to be called on
	the context. Return false here if this is the case for your request. */
	var needsEnteringBridgeOnContext: Bool {get}
	/** For some requests, entering the bridge is not required to be called on
	the context. Return false here if this is the case for your request. */
	var needsRetrievingBackRequestPartsOnContext: Bool {get}
	
	/** Perform here the actions required to prepare the bridge for the
	computation of the operations for your request.
	
	You must return `true` if the operations should be computed by the bridge,
	`false` if you want to abort everything.
	
	Throwing an error also aborts the computation of the operations.
	
	Will be called on the context if needsEnteringBridgeOnContext is `true`.
	Setting this property to `false` will not guarantee you will not be called on
	the context though. */
	func enterBridge() throws -> Bool
	
	/* A Back Request is an array of Back Request Parts.
	
	Will be called on the context if needsRetrievingBackRequestPartsOnContext is
	`true`. Setting this property to `false` will not guarantee you will not be
	called on the context though. */
	func backRequestParts() throws -> [RequestPartId: BackRequestPart<DbType.ObjectType, DbType.FetchRequestType, AdditionalRequestInfoType>]
	
	/* TODO: The request should be able to give a different importer per request
	 *       part id (for instance to specify an importer with a more thorough
	 *       uniquing algorithm when dealing with db who has a parent). This
	 *       would offload the responsability of getting an importer from the
	 *       client and move it to the request.
	func backResultsImporter<BridgeType : Bridge>(for requestPartId: RequestPartId) -> AnyBackResultsImporter<BridgeType>? where BridgeType.DbType == DbType, BridgeType.AdditionalRequestInfoType == AdditionalRequestInfoType */
	
	/** Perform here the actions required after the operations for the given
	request have been computed.
	
	You must return `true` if the operation should be launched, `false` if you
	want to abort everything.
	
	Throwing an error also aborts the launch of the operations.
	
	Will always be called on the context. */
	func leaveBridge() throws -> Bool
	
	/** Gives you an opportunity to clean up if an error occurs while in the
	bridge. Including while entering or leaving the bridge (`enterBridge()` and
	`leaveBridge()`). Also called among other cases if `backRequestParts()`
	throws (this method is always called while in the bridge).
	
	Will always be called on the context. */
	func processBridgeError(_: Swift.Error)
	
	/* ********* */
	
	/** Return `nil` if the results of the request part should not be processed. */
	func dbForImportingResults(ofRequestPart requestPart: BackRequestPart<DbType.ObjectType, DbType.FetchRequestType, AdditionalRequestInfoType>, withId id: RequestPartId) -> DbType?
	
	/** Perform here the actions to prepare for the import of the data for the
	given request part. Return false if the results should not be imported.
	
	Will always be called on the context. */
	func prepareResultsImport(ofRequestPart requestPart: BackRequestPart<DbType.ObjectType, DbType.FetchRequestType, AdditionalRequestInfoType>, withId id: RequestPartId, inDb db: DbType) throws -> Bool
	
	/** Perform here the actions to finish the import of the data for the given
	request part.
	
	Will always be called on the context. */
	func endResultsImport(ofRequestPart requestPart: BackRequestPart<DbType.ObjectType, DbType.FetchRequestType, AdditionalRequestInfoType>, withId id: RequestPartId, inDb db: DbType, importResults: ImportResult<DbType>) throws
	
	/** Perform here the actions to finish the import of the data for the given
	request part, after an error occurred. Only called for fast import errors, or
	if any of the two methods above (`prepareResultsImport...` and
	`endResultsImport...`) fail.
	**Not** called if `prepareResultsImport...` returns `false` though.
	
	Will always be called on the context. */
	func processResultsImportError(ofRequestPart requestPart: BackRequestPart<DbType.ObjectType, DbType.FetchRequestType, AdditionalRequestInfoType>, withId id: RequestPartId, inDb db: DbType, error: Swift.Error)
	
}
