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



public struct ImportBridgeOperationResultsRequest<BridgeType : Bridge> {
	
	let db: BridgeType.DbType
	
	let bridge: BridgeType
	/** The operation from which the results will be extracted to be processed.
	The operation does not have to be finished when creating the request, only
	when processing it. */
	let operation: BridgeType.BackOperationType
	
	let expectedEntity: BridgeType.DbType.EntityDescriptionType
	let updatedObjectId: BridgeType.DbType.ObjectIDType?
	
	let userInfo: BridgeType.UserInfoType
	
	let importPreparationBlock: (() throws -> Bool)?
	let importSuccessBlock: ((_ importResults: ImportResult<BridgeType.DbType>) throws -> Void)?
	/* Also called if `fastImportSuccessBlock` or `fastImportPreparationBlock`
	 * fail. NOT called if `fastImportPreparationBlock` returns `false` though. */
	let importErrorBlock: ((_ error: Swift.Error) -> Void)?
	
}
