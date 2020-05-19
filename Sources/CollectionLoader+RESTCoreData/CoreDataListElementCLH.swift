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



@available(OSX 10.12, *)
public class CoreDataListElementCLH<FetchedObjectsType : NSManagedObject, BridgeType, PageInfoRetrieverType : PageInfoRetriever> : CoreDataCLH
	where BridgeType.DbType == NSManagedObjectContext, BridgeType.AdditionalRequestInfoType == AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>, PageInfoRetrieverType.BridgeType == BridgeType
{
	
	public let bridge: BridgeType
	public let pageInfoRetriever: PageInfoRetrieverType?
	public let context: NSManagedObjectContext
	public let requestManager: RequestManager
	
	public let resultsController: NSFetchedResultsController<FetchedObjectsType>
	
	public var listElementObjectId: NSManagedObjectID?
	
	public convenience init(
		listElementEntity: NSEntityDescription, additionalElementFetchInfo aefi: AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>?, listProperty lp: NSRelationshipDescription,
		apiOrderProperty aop: NSAttributeDescription, apiOrderDelta aod: Int = 1, additionalFetchRequestPredicate afrp: NSPredicate? = nil,
		context c: NSManagedObjectContext, bridge b: BridgeType? = nil, pageInfoRetriever pir: PageInfoRetrieverType? = nil, requestManager rm: RequestManager
	) {
		let fr = NSFetchRequest<NSManagedObject>()
		fr.entity = listElementEntity
		fr.fetchLimit = 1
		self.init(listElementFetchRequest: fr, additionalElementFetchInfo: aefi, listProperty: lp, apiOrderProperty: aop, apiOrderDelta: aod, additionalFetchRequestPredicate: afrp, context: c, bridge: b, pageInfoRetriever: pir, requestManager: rm)
	}
	
	public init<ListElementObjectType : NSManagedObject>(
		listElementFetchRequest: NSFetchRequest<ListElementObjectType>, additionalElementFetchInfo aefi: AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>?, listProperty lp: NSRelationshipDescription,
		apiOrderProperty aop: NSAttributeDescription, apiOrderDelta aod: Int = 1, additionalFetchRequestPredicate afrp: NSPredicate? = nil,
		context c: NSManagedObjectContext, bridge b: BridgeType? = nil, pageInfoRetriever pir: PageInfoRetrieverType? = nil, requestManager rm: RequestManager
	) {
		assert(lp.isOrdered)
		
		context = c
		requestManager = rm
		pageInfoRetriever = pir
		bridge = rm.getBridge(from: b)
		
		fetchRequest = listElementFetchRequest as! NSFetchRequest<NSFetchRequestResult>
		additionalElementFetchInfo = aefi
		
		listProperty = lp
		
		apiOrderProperty = aop
		apiOrderDelta = aod
		
		var listObjectId: NSManagedObjectID? = nil
		c.performAndWait{ listObjectId = (try? c.fetch(listElementFetchRequest))?.first?.objectID }
		listElementObjectId = listObjectId
		
		let fetchedResultsControllerFetchRequest = NSFetchRequest<FetchedObjectsType>()
		fetchedResultsControllerFetchRequest.entity = listProperty.destinationEntity!
		fetchedResultsControllerFetchRequest.sortDescriptors = [NSSortDescriptor(key: aop.name, ascending: true)]
		if let listObjectId = listObjectId {fetchedResultsControllerFetchRequest.predicate = NSPredicate(format: "%K == %@", lp.inverseRelationship!.name, listObjectId)}
		else {
			/* We want to retrieve the objects whose inverse relationship name of
			 * the list property match the list element fetch request, but the list
			 * element fetch request currently matches nothing. So we have to
			 * create a predicate to match anyway.
			 * Two case:
			 *    - The list element fetch request has a predicate: it should be
			 *      enough to add the inverse relationship name to the key paths
			 *      of the predicate.
			 *    - The list element fetch request does not have a predicate: we
			 *      assume then any object of the type we want whose inverse
			 *      relationship name value is not nil will match. Indeed, if it is
			 *      set, the value must be to the list element we want as there
			 *      should only be one in the db... */
			fetchedResultsControllerFetchRequest.predicate =
				listElementFetchRequest.predicate?.predicateByAddingKeyPathPrefix(lp.inverseRelationship!.name) ??
				NSPredicate(format: "%K != NULL", lp.inverseRelationship!.name)
		}
		if let predicate = afrp, let fPredicate = fetchedResultsControllerFetchRequest.predicate {fetchedResultsControllerFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fPredicate, predicate])}
		else if let predicate = afrp                                                             {fetchedResultsControllerFetchRequest.predicate = predicate}
		resultsController = NSFetchedResultsController<FetchedObjectsType>(fetchRequest: fetchedResultsControllerFetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		try! resultsController.performFetch()
	}
	
	public func pageInfoFor(startOffset: Int, endOffset: Int) -> Any {
		return pageInfoRetriever?.pageInfoFor(startOffset: startOffset, endOffset: endOffset) ?? RESTOffsetLimitPaginatorInfo(startOffset: startOffset, endOffset: endOffset)
	}
	
	public func operationForLoading(pageInfo: Any, preRun: (() -> Bool)?, preImport: (() -> Bool)?, preCompletion: ((_ importResults: ImportResult<NSManagedObjectContext>) throws -> Void)?) -> BackRequestOperation<RESTCoreDataFetchRequest, BridgeType> {
		let additionalListInfo = AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>(fromInfo: additionalElementFetchInfo?[listProperty.hashableWrapper()], paginatorInfo: pageInfo)
		
		var additionalFetchInfo = additionalElementFetchInfo ?? AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>()
		additionalFetchInfo[listProperty.hashableWrapper()] = additionalListInfo
		
		let request = RESTCoreDataFetchRequest(context: context, fetchRequest: fetchRequest, fetchType: .always, additionalInfo: additionalFetchInfo, leaveBridgeHandler: preRun, preImportHandler: preImport, preCompletionHandler: { importResults in
			if importResults.rootObjectsAndRelationships.count > 1 {
				if #available(tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
					BMOConfig.oslog.flatMap{ os_log("Got more than one root element as a result of a request for a list element collection loader helper. Taking first. Got: %@", log: $0, type: .info, importResults.rootObjectsAndRelationships) }
				}
			}
			guard let root = importResults.rootObjectsAndRelationships.first?.object else {return}
			
			assert(!root.objectID.isTemporaryID)
			
			if let curRootObjectID = self.listElementObjectId, curRootObjectID != root.objectID {
				if #available(tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
					BMOConfig.oslog.flatMap{ os_log("Got different root object id from a result of a request for a list element collection loader helper than previous one. Replacing with new one. Previous: %{public}@; retrieved: %{public}@", log: $0, type: .info, curRootObjectID, root.objectID) }
				}
			}
			self.listElementObjectId = root.objectID
			
			let apiOrderPropertyName = self.apiOrderProperty.name
			let collection = (root.value(forKey: self.listProperty.name) as! NSOrderedSet).array as! [NSManagedObject]
			for (i, elt) in collection.enumerated() {
				let expectedOrderValue = i * self.apiOrderDelta
				guard elt.value(forKey: apiOrderPropertyName) as! Int != expectedOrderValue else {continue}
				elt.setValue(expectedOrderValue, forKey: apiOrderPropertyName)
			}
			try preCompletion?(importResults)
		})
		return requestManager.operation(forBackRequest: request, autoStart: false, handler: nil)
	}
	
	/* “Funny” note: If I set the type of the "operation" argument to
	 * LoadingOperationType instead of its realization, the AnyCoreDataCLH
	 * implementation compilation will crash... (Xcode 8E2002) */
	public func results(fromFinishedLoadingOperation operation: BackRequestOperation<RESTCoreDataFetchRequest, BridgeType>) -> AsyncOperationResult<BridgeBackRequestResult<BridgeType>> {
		return operation.result.simpleBackRequestResult()
	}
	
	public func numberOfFetchedObjects(for preCompletionResults: ImportResult<NSManagedObjectContext>) -> Int {
		return preCompletionResults.rootObjectsAndRelationships.first?.relationships![listProperty.name]?.rootObjectsAndRelationships.count ?? 0
	}
	
	public func unsafeFetchedObjectId(at index: Int, for preCompletionResults: ImportResult<NSManagedObjectContext>) -> NSManagedObjectID {
		return preCompletionResults.rootObjectsAndRelationships.first!.relationships![listProperty.name]!.rootObjectsAndRelationships[index].object.objectID
	}
	
	public func unsafeRemove(objectId: NSManagedObjectID, hardDelete: Bool) {
		context.object(with: objectId).setValue(nil, forKey: listProperty.inverseRelationship!.name)
	}
	
	public func nextPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: Any, nElementsPerPage: Int) -> Any?? {
		guard let pageInfoRetriever = pageInfoRetriever else {return nil}
		return pageInfoRetriever.nextPageInfo(for: completionResults, from: pageInfo, nElementsPerPage: nElementsPerPage)
	}
	
	public func previousPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: Any, nElementsPerPage: Int) -> Any? {
		guard let pageInfoRetriever = pageInfoRetriever else {return nil}
		return pageInfoRetriever.previousPageInfo(for: completionResults, from: pageInfo, nElementsPerPage: nElementsPerPage)
	}
	
	private let fetchRequest: NSFetchRequest<NSFetchRequestResult>
	private let additionalElementFetchInfo: AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>?
	
	private let listProperty: NSRelationshipDescription
	
	private let apiOrderProperty: NSAttributeDescription
	private let apiOrderDelta: Int /* Must be > 0 */
	
}
