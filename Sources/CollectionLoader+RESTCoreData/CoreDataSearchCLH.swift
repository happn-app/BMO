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
import os.log

import AsyncOperationResult
import BMO
import BMO_CoreData
import BMO_RESTCoreData
import RESTUtils



/* Interesting Note (Might Be TODO...): If the request makes the API (or the
 * bridge) return elements that are not kind of the requested entity (eg. with
 * happn we have the request for the conversations that might return an
 * FLHPConversationsCount object within the list of conversations; with
 * Instagram we might have an FLIGVideo elements when we ask for FLIGImage only)
 * the number of elements returned from the pre-completion result (and also
 * incidentally but it matters less the results from the finished loading
 * operation) will contain those elements.
 *
 * Because of this, when computing whether we have more elements to load——and
 * deleting the previously loaded elements on a “first page” load, those
 * “ghosts” will be taken into account in the calculation! Which is not what we
 * want.
 *
 * One solution would be to filter the pre-results to only contain elements kind
 * of the expected entity. */

@available(OSX 10.12, *)
public class CoreDataSearchCLH<FetchedObjectsType : NSManagedObject, BridgeType, PageInfoRetrieverType : PageInfoRetriever> : CoreDataCLH
	where BridgeType.DbType == NSManagedObjectContext, BridgeType.AdditionalRequestInfoType == AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>, PageInfoRetrieverType.BridgeType == BridgeType
{
	
	public let bridge: BridgeType
	public let pageInfoRetriever: PageInfoRetrieverType?
	public let context: NSManagedObjectContext
	public let requestManager: RequestManager
	
	public let resultsController: NSFetchedResultsController<FetchedObjectsType>
	
	public init(
		fetchRequest fr: NSFetchRequest<FetchedObjectsType>, additionalFetchInfo afi: AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>?,
		apiOrderProperty aop: NSAttributeDescription? = nil, apiOrderDelta aod: Int = 1,
		deletionDateProperty ddp: NSAttributeDescription? = nil,
		context c: NSManagedObjectContext, bridge b: BridgeType? = nil, pageInfoRetriever pir: PageInfoRetrieverType? = nil, requestManager rm: RequestManager
	) {
		assert(aod > 0)
		assert(ddp?.attributeValueClassName == nil || ddp?.attributeValueClassName == "NSDate" || ddp?.attributeValueClassName == "Date")
		
		context = c
		requestManager = rm
		pageInfoRetriever = pir ?? (rm.getBridge(from: b) as? PageInfoRetrieverType)
		bridge = rm.getBridge(from: b)
		
		fetchRequest = fr as! NSFetchRequest<NSFetchRequestResult>
		additionalFetchInfo = afi
		
		apiOrderProperty = aop
		apiOrderDelta = aod
		deletionDateProperty = ddp
		
		let controllerFetchRequest = fr.copy() as! NSFetchRequest<FetchedObjectsType> /* Must still copy because of ObjC legacy... */
		if let apiOrderProperty = aop {
			var sd = controllerFetchRequest.sortDescriptors ?? []
			sd.insert(NSSortDescriptor(key: apiOrderProperty.name, ascending: true), at: 0)
			controllerFetchRequest.sortDescriptors = sd
		}
		if let deletionDateProperty = ddp {
			let deletionPredicate = NSPredicate(format: "%K == NULL", deletionDateProperty.name)
			if let currentPredicate = controllerFetchRequest.predicate {controllerFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [currentPredicate, deletionPredicate])}
			else                                                       {controllerFetchRequest.predicate = deletionPredicate}
		}
		resultsController = NSFetchedResultsController<FetchedObjectsType>(fetchRequest: controllerFetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		try! resultsController.performFetch()
	}
	
	public func pageInfoFor(startOffset: Int, endOffset: Int) -> PageInfo {
		return PageInfo(offset: startOffset, paginatorInfo: pageInfoRetriever?.pageInfoFor(startOffset: startOffset, endOffset: endOffset) ?? RESTOffsetLimitPaginatorInfo(startOffset: startOffset, endOffset: endOffset))
	}
	
	public func operationForLoading(pageInfo: PageInfo, preRun: (() -> Bool)?, preImport: (() -> Bool)?, preCompletion: ((_ importResults: ImportResult<NSManagedObjectContext>) throws -> Void)?) -> BackRequestOperation<RESTCoreDataFetchRequest, BridgeType> {
		let fullPreCompletionHandler: ((ImportResult<NSManagedObjectContext>) throws -> Void)?
		
		if let apiOrderProperty = apiOrderProperty, let startIndex = pageInfo.offset {
			fullPreCompletionHandler = { importResults in
				for (i, elt) in importResults.rootObjectsAndRelationships.enumerated() {
					elt.object.setValue((i + startIndex) * self.apiOrderDelta, forKey: apiOrderProperty.name)
				}
				try preCompletion?(importResults)
			}
		} else {
			if apiOrderProperty != nil {
				if #available(tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
					BMOConfig.oslog.flatMap{ os_log("Got no start index, but I do have an API order property! Leaving to default value, object order will probably be random...", log: $0, type: .info) }
				}
			}
			fullPreCompletionHandler = preCompletion
		}
		
		let additionalInfo = AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>(fromInfo: additionalFetchInfo, paginatorInfo: pageInfo.paginatorInfo)
		let request = RESTCoreDataFetchRequest(context: context, fetchRequest: fetchRequest, fetchType: .always, additionalInfo: additionalInfo, leaveBridgeHandler: preRun, preImportHandler: preImport, preCompletionHandler: fullPreCompletionHandler)
		return requestManager.operation(forBackRequest: request, autoStart: false, handler: nil)
	}
	
	public func results(fromFinishedLoadingOperation operation: BackRequestOperation<RESTCoreDataFetchRequest, BridgeType>) -> AsyncOperationResult<BridgeBackRequestResult<BridgeType>> {
		return operation.result.simpleBackRequestResult()
	}
	
	public func numberOfFetchedObjects(for preCompletionResults: ImportResult<NSManagedObjectContext>) -> Int {
		return preCompletionResults.rootObjectsAndRelationships.count
	}
	
	public func unsafeFetchedObjectId(at index: Int, for preCompletionResults: ImportResult<NSManagedObjectContext>) -> NSManagedObjectID {
		return preCompletionResults.rootObjectsAndRelationships[index].object.objectID
	}
	
	public func unsafeRemove(objectId: NSManagedObjectID, hardDelete: Bool) {
		if !hardDelete, let deletionDateProperty = deletionDateProperty {context.object(with: objectId).setValue(Date(), forKey: deletionDateProperty.name)}
		else                                                            {context.delete(context.object(with: objectId))}
	}
	
	public func nextPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: PageInfo, nElementsPerPage: Int) -> PageInfo?? {
		guard let pageInfoRetriever = pageInfoRetriever else {return nil}
		guard let i = pageInfoRetriever.nextPageInfo(for: completionResults, from: pageInfo.paginatorInfo, nElementsPerPage: nElementsPerPage) else {return nil}
		return .some(i.flatMap{ PageInfo(offset: pageInfo.offset.flatMap{ $0 + nElementsPerPage }, paginatorInfo: $0) })
	}
	
	public func previousPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: PageInfo, nElementsPerPage: Int) -> PageInfo? {
		guard let pageInfoRetriever = pageInfoRetriever else {return nil}
		let i = pageInfoRetriever.previousPageInfo(for: completionResults, from: pageInfo.paginatorInfo, nElementsPerPage: nElementsPerPage)
		return i.flatMap{ PageInfo(offset: pageInfo.offset.flatMap{ $0 - nElementsPerPage }, paginatorInfo: $0) }
	}
	
	private let fetchRequest: NSFetchRequest<NSFetchRequestResult>
	private let additionalFetchInfo: AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>?
	
	private let apiOrderProperty: NSAttributeDescription?
	private let apiOrderDelta: Int /* Must be > 0 */
	private let deletionDateProperty: NSAttributeDescription?
	
	public struct PageInfo {
		
		let offset: Int?
		let paginatorInfo: Any
		
		public init(offset o: Int?, paginatorInfo i: Any) {
			offset = o
			paginatorInfo = i
		}
		
	}
	
}
