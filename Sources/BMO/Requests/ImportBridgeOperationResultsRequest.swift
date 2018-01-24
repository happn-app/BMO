/*
 * ImportBridgeOperationResultsRequest.swift
 * BMO
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

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
