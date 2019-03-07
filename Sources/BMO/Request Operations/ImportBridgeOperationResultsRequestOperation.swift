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

import AsyncOperationResult



public final class ImportBridgeOperationResultsRequestOperation<BridgeType : Bridge> : Operation {
	
	public typealias DbRepresentationImporterResultType = (importResult: ImportResult<BridgeType.DbType>, bridgeBackRequestResult: BridgeBackRequestResult<BridgeType>)
	
	public let request: ImportBridgeOperationResultsRequest<BridgeType>
	public let importer: AnyBackResultsImporter<BridgeType>
	
	public private(set) var result: AsyncOperationResult<BridgeBackRequestResult<BridgeType>> = .error(OperationError.notFinished)
	
	public init(request r: ImportBridgeOperationResultsRequest<BridgeType>, importer i: AnyBackResultsImporter<BridgeType>) {
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
			let dbRepresentationCount = importer.retrieveDbRepresentations(fromRemoteRepresentations: remoteRepresentations, expectedEntity: request.expectedEntity, userInfo: requestParsingUserInfo, bridge: request.bridge, shouldContinueHandler: { !self.isCancelled })
			try throwIfCancelled()
			
			guard dbRepresentationCount > 0 || request.importPreparationBlock != nil || request.importSuccessBlock != nil else {
				result = .success(BridgeBackRequestResult(metadata: metadata, returnedObjectIDsAndRelationships: [], asyncChanges: ChangesDescription()))
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
						self.result = .error(OperationError.cancelled)
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
		guard !isCancelled else {throw OperationError.cancelled}
	}
	
}
