/*
 * CoreDataCLH.swift
 * happn
 *
 * Created by François Lamboley on 4/21/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import CoreData
import Foundation

import CollectionLoader



@available(OSX 10.12, *)
public protocol CoreDataCLH : CollectionLoaderHelper where FetchedObjectsIDType == NSManagedObjectID {
	
	associatedtype FetchedObjectsType : NSManagedObject
	
	var resultsController: NSFetchedResultsController<FetchedObjectsType> {get}
	
}


@available(OSX 10.12, *)
public extension CoreDataCLH {
	
	var numberOfCachedObjects: Int {
		return resultsController.fetchedObjects?.count ?? 0
	}
	
	func unsafeCachedObjectId(at index: Int) -> FetchedObjectsIDType {
		return resultsController.fetchedObjects![index].objectID
	}
	
}
