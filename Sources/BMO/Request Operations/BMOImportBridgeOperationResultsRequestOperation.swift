/*
 * BMOImportBridgeOperationResultsRequestOperation.swift
 * BMO
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation

import AsyncOperationResult



public final class BMOImportBridgeOperationResultsRequestOperation<BridgeType : BMOBridge> : Operation {
	
	public typealias DbRepresentationImporterResultType = (importResult: BMOImportResult<BridgeType.DbType>, bridgeBackRequestResult: BMOBridgeBackRequestResult<BridgeType>)
	
	public let request: BMOImportBridgeOperationResultsRequest<BridgeType>
	public let importer: AnyBMOBackResultsImporter<BridgeType>
	
	public private(set) var result: AsyncOperationResult<BMOBridgeBackRequestResult<BridgeType>> = .error(BMOError.notFinished)
	
	public init(request r: BMOImportBridgeOperationResultsRequest<BridgeType>, importer i: AnyBMOBackResultsImporter<BridgeType>) {
		request = r
		importer = i
	}
	
	public override func main() {
		assert(request.operation.isFinished)
		do {
			let requestParsingUserInfo = request.bridge.userInfo(fromFinishedOperation: request.operation, currentUserInfo: request.userInfo)
			try throwIfCancelled()
			
			let metadata = request.bridge.bridgeMetadata(fromFinishedOperation: request.operation, userInfo: requestParsingUserInfo)
			try throwIfCancelled()
			
			let remoteRepresentations = try request.bridge.remoteObjectRepresentations(fromFinishedOperation: request.operation, userInfo: requestParsingUserInfo) ?? []
			try throwIfCancelled()
			let dbRepresentationCount = importer.retrieveDbRepresentations(fromRemoteRepresentations: remoteRepresentations, expectedEntity: request.expectedEntity, userInfo: requestParsingUserInfo, bridge: request.bridge, shouldContinueHandler: {!self.isCancelled})
			try throwIfCancelled()
			
			guard dbRepresentationCount > 0 || request.importPreparationBlock != nil || request.importSuccessBlock != nil else {
				result = .success(BMOBridgeBackRequestResult(metadata: metadata, returnedObjectIDsAndRelationships: [], asyncChanges: BMOChangesDescription()))
				return
			}
			
			try importer.createAndPrepareDbImporter(rootMetadata: metadata)
			
			/* I don't think NOT waiting is justified here.
			 * - We do not care about hogging the queue we're on because while the
			 *   stuff we have to do in the context is not done, the operation will
			 *   not be finished and will hog the queue.
			 * - Not waiting would make us convert the operation to an asynchronous
			 *   operation, which is not a trivial task, and not justified as per
			 *   the previous point. */
			try request.db.performAndWait {
				try self.throwIfCancelled()
				
				do {
					guard try self.request.importPreparationBlock?() ?? true else {
						self.result = .error(BMOError.cancelled)
						return
					}
					
					/* Once the import has started, it cannot be cancelled anymore. */
					let result = try importer.unsafeImport(in: self.request.db, updatingObject: self.request.updatedObjectId.flatMap{ try? self.request.db.unsafeRetrieveExistingObject(fromObjectID: $0) })
					try self.request.importSuccessBlock?(result.importResult)
					
					self.result = .success(result.bridgeBackRequestResult)
				} catch {
					self.request.importErrorBlock?(error)
					throw error
				}
			}
		} catch {
			result = .error(error)
		}
	}
	
	public override var isAsynchronous: Bool {
		return false
	}
	
	private func throwIfCancelled() throws {
		guard !isCancelled else {throw BMOError.cancelled}
	}
	
}
