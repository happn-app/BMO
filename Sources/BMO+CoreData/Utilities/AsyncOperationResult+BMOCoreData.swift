/*
 * AsyncOperationResult+BMOCoreData.swift
 * BMO+CoreData
 *
 * Created by François Lamboley on 1/29/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation

import AsyncOperationResult

import BMO



extension AsyncOperationResult {
	
	public func simpleBackRequestResult<BridgeType>() -> AsyncOperationResult<BridgeBackRequestResult<BridgeType>> where T == BackRequestResult<CoreDataFetchRequest, BridgeType> {
		return simpleBackRequestResult(forRequestPartId: NSNull())
	}
	
	public func simpleBackRequestSuccessValue<BridgeType>() -> BridgeBackRequestResult<BridgeType>? where T == BackRequestResult<CoreDataFetchRequest, BridgeType> {
		return simpleBackRequestResult().successValue
	}
	
	public func simpleBackRequestError<BridgeType>() -> Swift.Error? where T == BackRequestResult<CoreDataFetchRequest, BridgeType> {
		return simpleBackRequestResult().error
	}
	
}
