/*
 * Bridge+CoreDataCLH.swift
 * BMO
 *
 * Created by François Lamboley on 25/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation

import BMO
import RESTUtils



public extension Bridge {
	
	/* Page info stuff */
	func pageInfoFor(startOffset: Int, endOffset: Int) -> Any {
		return RESTOffsetLimitPaginatorInfo(offset: startOffset, limit: endOffset)
	}
	
	public func nextPageInfo(for completionResults: BridgeBackRequestResult<Self>, from pageInfo: Any, nElementsPerPage: Int) -> Any?? {
		return nil
	}
	
	public func previousPageInfo(for completionResults: BridgeBackRequestResult<Self>, from pageInfo: Any, nElementsPerPage: Int) -> Any? {
		return nil
	}
	
}
