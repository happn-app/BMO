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

import BMO
import BMO_CoreData
import RESTUtils



public typealias RESTCoreDataFetchRequest = CoreDataFetchRequest<AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>>

extension CoreDataFetchRequest where AdditionalInfoType == AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper> {
	
	public init(context: NSManagedObjectContext, entity: NSEntityDescription, resultType: NSFetchRequestResultType = .managedObjectResultType, remoteId: String, remoteIdPropertyName: String = "remoteId", flatifiedFields: String?, alwaysFetchProperties: Bool, leaveBridgeHandler lb: (() -> Bool)? = nil, preImportHandler pi: (() -> Bool)? = nil, preCompletionHandler pc: ((_ importResults: ImportResult<NSManagedObjectContext>) throws -> Void)? = nil) {
		let fRequest = NSFetchRequest<NSFetchRequestResult>()
		fRequest.entity = entity
		fRequest.resultType = resultType
		fRequest.predicate = NSPredicate(format: "%K == %@", remoteIdPropertyName, remoteId)
		
		self.init(
			context: context, fetchRequest: fRequest, fetchType: (alwaysFetchProperties || !(flatifiedFields?.isEmpty ?? true)) ? .always : .onlyIfNoLocalResults,
			additionalInfo: AdditionalRESTRequestInfo<NSPropertyDescriptionHashableWrapper>(flatifiedFields: flatifiedFields, inEntity: entity),
			leaveBridgeHandler: lb, preImportHandler: pi, preCompletionHandler: pc
		)
	}
	
}
