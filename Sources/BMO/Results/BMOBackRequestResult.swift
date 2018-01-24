/*
 * BMOBackRequestResult.swift
 * BMO
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation

import AsyncOperationResult



public struct BMOBackRequestResult<RequestType : BMOBackRequest, BridgeType : BMOBridge> {
	
	public let results: [RequestType.RequestPartId: AsyncOperationResult<BMOBridgeBackRequestResult<BridgeType>>]
	
}
