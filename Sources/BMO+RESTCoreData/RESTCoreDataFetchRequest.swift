/*
 * RESTCoreDataFetchRequest.swift
 * BMO+RESTCoreData
 *
 * Created by François Lamboley on 1/30/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData

import BMO
import BMO_CoreData
import RESTUtils



public typealias RESTCoreDataFetchRequest = CoreDataFetchRequest<AdditionalRESTRequestInfo<NSPropertyDescription>>

public extension CoreDataFetchRequest where AdditionalInfoType == AdditionalRESTRequestInfo<NSPropertyDescription> {
	
	public init(context: NSManagedObjectContext, entity: NSEntityDescription, resultType: NSFetchRequestResultType = .managedObjectResultType, remoteId: String, remoteIdPropertyName: String = "remoteId", flatifiedFields: String?, alwaysFetchProperties: Bool, leaveBridgeHandler lb: (() -> Bool)? = nil, preImportHandler pi: (() -> Bool)? = nil, preCompletionHandler pc: ((_ importResults: ImportResult<NSManagedObjectContext>) throws -> Void)? = nil) {
		let fRequest = NSFetchRequest<NSFetchRequestResult>()
		fRequest.entity = entity
		fRequest.resultType = resultType
		fRequest.predicate = NSPredicate(format: "%K == %@", remoteIdPropertyName, remoteId)
		
		self.init(
			context: context, fetchRequest: fRequest, fetchType: (alwaysFetchProperties || !(flatifiedFields?.isEmpty ?? true)) ? .always : .onlyIfNoLocalResults,
			additionalInfo: AdditionalRESTRequestInfo<NSPropertyDescription>(flatifiedFields: flatifiedFields, inEntity: entity),
			leaveBridgeHandler: lb, preImportHandler: pi, preCompletionHandler: pc
		)
	}
	
}
