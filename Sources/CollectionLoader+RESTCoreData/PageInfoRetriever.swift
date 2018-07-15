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



public protocol PageInfoRetriever {
	
	associatedtype BridgeType : Bridge
	
	func pageInfoFor(startOffset: Int, endOffset: Int) -> Any
	
	func nextPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: Any, nElementsPerPage: Int) -> Any??
	func previousPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: Any, nElementsPerPage: Int) -> Any?
	
}
