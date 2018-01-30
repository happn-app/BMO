/*
 * AsyncOperationResult+Results.swift
 * BMO
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation

import AsyncOperationResult



/* What I'd have liked below, but not possible with current Swift (or ever?). Instead we have generic functions in the extension.
extension AsyncOperationResult<BridgeType : Bridge> where T == BackRequestResult<CoreDataFetchRequest, BridgeType> {
	var simpleBackRequestResult: AsyncOperationResult<BridgeBackRequestResult<BridgeType>> {...}
	var simpleBackRequestSuccessValue: BridgeBackRequestResult<HappnBridge>? {...}
	var simpleBackRequestError: Swift.Error? {...}
}*/

public extension AsyncOperationResult {
	
	public func simpleBackRequestResult<RequestType, BridgeType>(forRequestPartId requestPartId: RequestType.RequestPartId) -> AsyncOperationResult<BridgeBackRequestResult<BridgeType>> where T == BackRequestResult<RequestType, BridgeType> {
		switch self {
		case .success(let value):
			/* If there are no results for the given request part id, that means
			 * the request has been denied going to a back request and was to
			 * succeed directly (eg. for a fetch request, when fetch type is only
			 * if no local results and there are local results). */
			return value.results[requestPartId] ?? .success(BridgeBackRequestResult(metadata: nil, returnedObjectIDsAndRelationships: [], asyncChanges: ChangesDescription()))
			
		case .error(let e):
			return .error(e)
		}
	}
	
	public func simpleBackRequestSuccessValue<RequestType, BridgeType>(forRequestPartId requestPartId: RequestType.RequestPartId) -> BridgeBackRequestResult<BridgeType>? where T == BackRequestResult<RequestType, BridgeType> {
		return simpleBackRequestResult(forRequestPartId: requestPartId).successValue
	}
	
	public func simpleBackRequestError<RequestType, BridgeType>(forRequestPartId requestPartId: RequestType.RequestPartId) -> Swift.Error? where T == BackRequestResult<RequestType, BridgeType> {
		return simpleBackRequestResult(forRequestPartId: requestPartId).error
	}
	
	public func backRequestResultHasErrors<RequestType, BridgeType>() -> Bool where T == BackRequestResult<RequestType, BridgeType> {
		switch self {
		case .error: return true
		case .success(let value):
			for (_, subValue) in value.results {
				switch subValue {
				case .error: return true
				case .success: (/*nop*/)
				}
			}
			return false
		}
	}
	
	public func backRequestResultErrors<RequestType, BridgeType>() -> [Swift.Error] where T == BackRequestResult<RequestType, BridgeType> {
		switch self {
		case .error(let e): return [e]
		case .success(let value):
			var errors = [Swift.Error]()
			for (_, subValue) in value.results {
				switch subValue {
				case .error(let e): errors.append(e)
				case .success: (/*nop*/)
				}
			}
			return errors
		}
	}
	
}
