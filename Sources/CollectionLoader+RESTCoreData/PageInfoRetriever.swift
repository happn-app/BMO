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



/* Ideally, this protocol would not exist and would instead be an extension of
 * Bridge. The extension would have a default implementation for these methods
 * (as is expected for protocol extensions), and concrete Bridge implementations
 * would overwrite the implementations as needed. However, because of a Swift
 * weirdness (not sure if normal behavior or not; will write on Swift forums),
 * when calling the extension from the same module it has been defined, if the
 * override is in another module, the default implementation is used instead,
 * which make this solution impossible for us. */
public protocol PageInfoRetriever {
	
	associatedtype BridgeType : Bridge
	
	func pageInfoFor(startOffset: Int, endOffset: Int) -> Any
	
	func nextPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: Any, nElementsPerPage: Int) -> Any??
	func previousPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: Any, nElementsPerPage: Int) -> Any?
	
}
