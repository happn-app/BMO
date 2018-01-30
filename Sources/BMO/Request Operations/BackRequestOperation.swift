/*
 * BackRequestOperation.swift
 * BMO
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation

import AsyncOperationResult



public final class BackRequestOperation<RequestType : BackRequest, BridgeType : Bridge> : Operation
	where BridgeType.DbType == RequestType.DbType, BridgeType.AdditionalRequestInfoType == RequestType.AdditionalRequestInfoType
{
	
	public let bridge: BridgeType
	public let request: RequestType
	public let importer: AnyBackResultsImporter<BridgeType>?
	
	public let backOperationQueue: OperationQueue
	public let parseOperationQueue: OperationQueue
	
	public private(set) var result: AsyncOperationResult<BackRequestResult<RequestType, BridgeType>> = .error(OperationError.notFinished)
	
	public init(request r: RequestType, bridge b: BridgeType, importer i: AnyBackResultsImporter<BridgeType>?, backOperationQueue bq: OperationQueue, parseOperationQueue pq: OperationQueue, requestManager: RequestManager?) {
		bridge = b
		request = r
		importer = i
		
		backOperationQueue = bq
		parseOperationQueue = pq
		resultsProcessingQueue = OperationQueue(); resultsProcessingQueue.maxConcurrentOperationCount = 1
		
		super.init()
		
		if let requestManager = requestManager {
			globalCancellationObserver = NotificationCenter.default.addObserver(forName: .BMORequestManagerCancelAllBackRequestOperations, object: requestManager, queue: nil) { [weak self] n in
				self?.cancel()
			}
		}
	}
	
	deinit {
		if let o = globalCancellationObserver {NotificationCenter.default.removeObserver(o)} /* Shouldn't really be needed... */
	}
	
	/** If you're already in the request context, you can call this before
	starting the request. It is actually the only way to retrieve the operations
	for the request synchronously.
	
	This will avoid a context jump when actually starting the operation. (You can
	start it right after calling this method if you want.) Also, sometimes it is
	needed to have a known context state to compute the operations to execute for
	the given request, which can only be achieved by calling the preparation
	synchronously. */
	public func unsafePrepareStart() throws {
		try unsafePrepareStart(withSafePartResults: nil)
	}
	
	public override func start() {
		assert(state == .inited)
		guard !isCancelled else {result = .error(OperationError.cancelled); state = .finished; return}
		
		state = .running
		if let bridgeOperations = bridgeOperations {
			launchOperations(bridgeOperations)
		} else {
			do {
				let safePrepareResults = try prepareStartSafePart()
				if let requestParts = safePrepareResults.requestParts, requestParts.count == 0 {
					assert(safePrepareResults.enteredBridge)
					launchOperations([])
					return
				}
				request.db.perform {
					do {
						guard !self.isCancelled else {throw OperationError.cancelled}
						self.launchOperations(try self.unsafePrepareStart(withSafePartResults: safePrepareResults))
					} catch {
						self.result = .error(error)
						self.state = .finished
					}
				}
			} catch {
				self.result = .error(error)
				self.state = .finished
			}
		}
	}
	
	public override func cancel() {
		cancellationSemaphore.wait(); defer {cancellationSemaphore.signal()}
		super.cancel()
		
		bridgeOperations?.forEach{ $0.parseOperation?.cancel(); $0.backOperation.cancel(); /* NOT cancelling the results processing operation. */ }
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private var globalCancellationObserver: NSObjectProtocol? {
		willSet {
			if let o = globalCancellationObserver {NotificationCenter.default.removeObserver(o)}
		}
	}
	
	private enum RequestOperationState {
		
		case inited
		case running
		case finished
		
	}
	
	private func launchOperations(_ operations: [BridgeOperation]) {
		cancellationSemaphore.wait(); defer {cancellationSemaphore.signal()}
		guard !isCancelled else {result = .error(OperationError.cancelled); state = .finished; return}
		
		let completionOperation = BlockOperation { [weak self] in
			guard let strongSelf = self else {return}
			strongSelf.result = .success(BackRequestResult(results: strongSelf.resultsBuilding))
			strongSelf.state = .finished
		}
		/* The completion operation will be called only when ALL dependencies are
		 * finished. Even cancelled dependencies are waited. */
		operations.forEach{ completionOperation.addDependency($0.resultsProcessingOperation) }
		
		backOperationQueue.addOperations(operations.map{ $0.backOperation }, waitUntilFinished: false)
		parseOperationQueue.addOperations(operations.flatMap{ $0.parseOperation }, waitUntilFinished: false)
		resultsProcessingQueue.addOperations(operations.map{ $0.resultsProcessingOperation }, waitUntilFinished: false)
		resultsProcessingQueue.addOperation(completionOperation)
	}
	
	private func prepareStartSafePart() throws -> SafePartStartPreparationResults {
		guard !request.needsEnteringBridgeOnContext else {return (false, nil)}
		guard try request.enterBridge() else {return (true, [:])}
		
		guard !request.needsRetrievingBackRequestPartsOnContext else {return (true, nil)}
		return (true, try request.backRequestParts())
	}
	
	@discardableResult
	private func unsafePrepareStart(withSafePartResults safePart: SafePartStartPreparationResults?) throws -> [BridgeOperation] {
		do {
			if let bridgeOperations = bridgeOperations {return bridgeOperations}
			guard try (safePart?.enteredBridge ?? false) || request.enterBridge() else {bridgeOperations = []; return []}
			
			var operations = [BridgeOperation]()
			
			for (dbRequestId, dbRequestPart) in try safePart?.requestParts ?? request.backRequestParts() {
				guard !isCancelled else {throw OperationError.cancelled}
				guard let operation = try bridgeOperation(forDbRequestPart: dbRequestPart, withId: dbRequestId) else {continue}
				operations.append(operation)
			}
			
			guard try request.leaveBridge() else {
				bridgeOperations = []
				return []
			}
			
			bridgeOperations = operations
			return operations
		} catch {
			request.processBridgeError(error)
			throw error
		}
	}
	
	private func bridgeOperation(forDbRequestPart part: BackRequestPart<RequestType.DbType.ObjectType, RequestType.DbType.FetchRequestType, RequestType.AdditionalRequestInfoType>, withId requestPartId: RequestType.RequestPartId) throws -> BridgeOperation? {
		var userInfo = bridge.createUserInfoObject()
		
		/* Retrieve the back operation part of the bridge operation. */
		let expectedEntityO: BridgeType.DbType.EntityDescriptionType?
		let backOperationO: BridgeType.BackOperationType?
		let updatedObject: BridgeType.DbType.ObjectType?
		switch part {
		case .fetch(let fetchRequest, let additionalInfo): updatedObject = nil;    expectedEntityO = bridge.expectedResultEntity(forFetchRequest: fetchRequest, additionalInfo: additionalInfo); backOperationO = try bridge.backOperation(forFetchRequest: fetchRequest, additionalInfo: additionalInfo, userInfo: &userInfo)
		case .insert(let object, let additionalInfo):      updatedObject = object; expectedEntityO = bridge.expectedResultEntity(forObject: object);                                             backOperationO = try bridge.backOperation(forInsertedObject: object, additionalInfo: additionalInfo, userInfo: &userInfo)
		case .update(let object, let additionalInfo):      updatedObject = object; expectedEntityO = bridge.expectedResultEntity(forObject: object);                                             backOperationO = try bridge.backOperation(forUpdatedObject: object, additionalInfo: additionalInfo, userInfo: &userInfo)
		case .delete(let object, let additionalInfo):      updatedObject = object; expectedEntityO = bridge.expectedResultEntity(forObject: object);                                             backOperationO = try bridge.backOperation(forDeletedObject: object, additionalInfo: additionalInfo, userInfo: &userInfo)
		}
		
		guard let expectedEntity = expectedEntityO, let backOperation = backOperationO else {
			return nil
		}
		
		let parseOperation: Operation?
		let resultsProcessingOperation: Operation
		if let db = request.dbForImportingResults(ofRequestPart: part, withId: requestPartId) {
			let resultsImportRequest = ImportBridgeOperationResultsRequest(
				db: db, bridge: bridge, operation: backOperation, expectedEntity: expectedEntity,
				updatedObjectId: updatedObject.flatMap{ self.request.db.unsafeObjectID(forObject: $0) },
				userInfo: userInfo,
				importPreparationBlock: { try self.request.prepareResultsImport(ofRequestPart: part, withId: requestPartId, inDb: db) },
				importSuccessBlock: { try self.request.endResultsImport(ofRequestPart: part, withId: requestPartId, inDb: db, importResults: $0) },
				importErrorBlock: { self.request.processResultsImportError(ofRequestPart: part, withId: requestPartId, inDb: db, error: $0) }
			)
			let importOperation = ImportBridgeOperationResultsRequestOperation(request: resultsImportRequest, importer: importer!) /* Maybe think about it a little more, but it seems normal that if there is no importer, we should crash. Another solution would be to gracefully simply not import the results... (check if importer is nil in if above) */
			importOperation.addDependency(backOperation)
			parseOperation = importOperation
			resultsProcessingOperation = BlockOperation{ self.resultsBuilding[requestPartId] = importOperation.result }
			resultsProcessingOperation.addDependency(importOperation)
		} else {
			parseOperation = nil
			resultsProcessingOperation = BlockOperation {
				self.resultsBuilding[requestPartId] =
					self.bridge.error(fromFinishedOperation: backOperation).map{ .error($0) } ??
					.success(BridgeBackRequestResult(metadata: nil, returnedObjectIDsAndRelationships: [], asyncChanges: ChangesDescription()))
			}
			resultsProcessingOperation.addDependency(backOperation)
		}
		
		return (backOperation: backOperation, parseOperation: parseOperation, resultsProcessingOperation: resultsProcessingOperation)
	}
	
	private typealias SafePartStartPreparationResults = (enteredBridge: Bool, requestParts: [RequestType.RequestPartId: BackRequestPart<RequestType.DbType.ObjectType, RequestType.DbType.FetchRequestType, RequestType.AdditionalRequestInfoType>]?)
	
	private typealias BridgeOperation = (backOperation: Operation, parseOperation: Operation?, resultsProcessingOperation: Operation)
	
	private let cancellationSemaphore = DispatchSemaphore(value: 1)
	
	private var bridgeOperations: [BridgeOperation]?
	private let resultsProcessingQueue: OperationQueue /* A serial queue */
	private var resultsBuilding = Dictionary<RequestType.RequestPartId, AsyncOperationResult<BridgeBackRequestResult<BridgeType>>>()
	
	private var state = RequestOperationState.inited {
		willSet(newState) {
			let newStateExecuting = (newState == .running)
			let oldStateExecuting = (state == .running)
			let newStateFinished = (newState == .finished)
			let oldStateFinished = (state == .finished)
			
			self.willChangeValue(forKey: "state")
			if newStateExecuting != oldStateExecuting {self.willChangeValue(forKey: "isExecuting")}
			if newStateFinished  != oldStateFinished  {self.willChangeValue(forKey: "isFinished")}
		}
		didSet(oldState) {
			let newStateExecuting = (state == .running)
			let oldStateExecuting = (oldState == .running)
			let newStateFinished = (state == .finished)
			let oldStateFinished = (oldState == .finished)
			
			/* Let's cleanup the bridge operations to avoid a retain cycle. */
			if state == .finished {bridgeOperations?.removeAll()}
			
			if newStateFinished  != oldStateFinished  {self.didChangeValue(forKey: "isFinished")}
			if newStateExecuting != oldStateExecuting {self.didChangeValue(forKey: "isExecuting")}
			self.didChangeValue(forKey: "state")
		}
	}
	
	public final override var isExecuting: Bool {
		return state == .running
	}
	
	public final override var isFinished: Bool {
		return state == .finished
	}
	
	public final override var isAsynchronous: Bool {
		return true
	}
	
}
