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

import AsyncOperationResult
import BMO
import BMO_RESTCoreData
import RESTUtils



@available(OSX 10.12, *)
public enum AnyCoreDataCLH<FetchedObjectsType : NSManagedObject, BridgeType, PageInfoRetrieverType : PageInfoRetriever> : CoreDataCLH
	where BridgeType.DbType == NSManagedObjectContext, BridgeType.AdditionalRequestInfoType == AdditionalRESTRequestInfo<NSPropertyDescription>, PageInfoRetrieverType.BridgeType == BridgeType
{
	
	case search(CoreDataSearchCLH<FetchedObjectsType, BridgeType, PageInfoRetrieverType>)
	case listElement(CoreDataListElementCLH<FetchedObjectsType, BridgeType, PageInfoRetrieverType>)
	
	public var resultsController: NSFetchedResultsController<FetchedObjectsType> {
		switch self {
		case .search(let helper):      return helper.resultsController
		case .listElement(let helper): return helper.resultsController
		}
	}
	
	public func pageInfoFor(startOffset: Int, endOffset: Int) -> Any {
		switch self {
		case .search(let helper):      return helper.pageInfoFor(startOffset: startOffset, endOffset: endOffset)
		case .listElement(let helper): return helper.pageInfoFor(startOffset: startOffset, endOffset: endOffset)
		}
	}
	
	public func operationForLoading(pageInfo: Any, preRun: (() -> Bool)?, preImport: (() -> Bool)?, preCompletion: ((_ importResults: ImportResult<NSManagedObjectContext>) throws -> Void)?) -> BackRequestOperation<RESTCoreDataFetchRequest, BridgeType> {
		switch self {
		case .search(let helper):      return helper.operationForLoading(pageInfo: pageInfo as! CoreDataSearchCLH<FetchedObjectsType, BridgeType, PageInfoRetrieverType>.PageInfo, preRun: preRun, preImport: preImport, preCompletion: preCompletion)
		case .listElement(let helper): return helper.operationForLoading(pageInfo: pageInfo,                                                                                       preRun: preRun, preImport: preImport, preCompletion: preCompletion)
		}
	}
	
	public func results(fromFinishedLoadingOperation operation: BackRequestOperation<RESTCoreDataFetchRequest, BridgeType>) -> AsyncOperationResult<BridgeBackRequestResult<BridgeType>> {
		switch self {
		case .search(let helper):      return helper.results(fromFinishedLoadingOperation: operation)
		case .listElement(let helper): return helper.results(fromFinishedLoadingOperation: operation)
		}
	}
	
	public var numberOfCachedObjects: Int {
		switch self {
		case .search(let helper):      return helper.numberOfCachedObjects
		case .listElement(let helper): return helper.numberOfCachedObjects
		}
	}
	
	public func unsafeCachedObjectId(at index: Int) -> NSManagedObjectID {
		switch self {
		case .search(let helper):      return helper.unsafeCachedObjectId(at: index)
		case .listElement(let helper): return helper.unsafeCachedObjectId(at: index)
		}
	}
	
	public func numberOfFetchedObjects(for preCompletionResults: ImportResult<NSManagedObjectContext>) -> Int {
		switch self {
		case .search(let helper):      return helper.numberOfFetchedObjects(for: preCompletionResults)
		case .listElement(let helper): return helper.numberOfFetchedObjects(for: preCompletionResults)
		}
	}
	
	public func unsafeFetchedObjectId(at index: Int, for preCompletionResults: ImportResult<NSManagedObjectContext>) -> NSManagedObjectID {
		switch self {
		case .search(let helper):      return helper.unsafeFetchedObjectId(at: index, for: preCompletionResults)
		case .listElement(let helper): return helper.unsafeFetchedObjectId(at: index, for: preCompletionResults)
		}
	}
	
	public func unsafeRemove(objectId: NSManagedObjectID, hardDelete: Bool) {
		switch self {
		case .search(let helper):      return helper.unsafeRemove(objectId: objectId, hardDelete: hardDelete)
		case .listElement(let helper): return helper.unsafeRemove(objectId: objectId, hardDelete: hardDelete)
		}
	}
	
	public func nextPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: Any, nElementsPerPage: Int) -> Any?? {
		switch self {
		case .search(let helper):      return helper.nextPageInfo(for: completionResults, from: pageInfo as! CoreDataSearchCLH<FetchedObjectsType, BridgeType, PageInfoRetrieverType>.PageInfo, nElementsPerPage: nElementsPerPage)
		case .listElement(let helper): return helper.nextPageInfo(for: completionResults, from: pageInfo,                                                                                       nElementsPerPage: nElementsPerPage)
		}
	}
	
	public func previousPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: Any, nElementsPerPage: Int) -> Any? {
		switch self {
		case .search(let helper):      return helper.previousPageInfo(for: completionResults, from: pageInfo as! CoreDataSearchCLH<FetchedObjectsType, BridgeType, PageInfoRetrieverType>.PageInfo, nElementsPerPage: nElementsPerPage)
		case .listElement(let helper): return helper.previousPageInfo(for: completionResults, from: pageInfo,                                                                                       nElementsPerPage: nElementsPerPage)
		}
	}
	
}
