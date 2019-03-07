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

import BMO



/* Swift Note: We can either tag the whole extension as public, in which case
 * there is no need to tag its functions public for them to be seen by clients,
 * or let the extension as internal and tag all the functions as public. */
public extension Bridge where DbType.FetchRequestType == NSFetchRequest<NSFetchRequestResult>, DbType.ObjectType == NSManagedObject, DbType.EntityDescriptionType == NSEntityDescription {
	
	func expectedResultEntity(forFetchRequest fetchRequest: DbType.FetchRequestType, additionalInfo: AdditionalRequestInfoType?) -> DbType.EntityDescriptionType? {
		return fetchRequest.entity
	}
	
	func expectedResultEntity(forObject object: DbType.ObjectType) -> DbType.EntityDescriptionType? {
		return object.entity
	}
	
}
