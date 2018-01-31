/*
 * RESTOffsetLimitPaginator.swift
 * RESTUtils
 *
 * Created by Thomas Levy on 24/09/15.
 * Copyright © 2015 happn. All rights reserved.
 */

import CoreData
import Foundation



public struct RESTOffsetLimitPaginatorInfo {
	
	public let offset: Int
	public let limit: Int
	
	public init(offset o: Int = 0, limit l: Int) {
		assert(l >= 0)
		offset = o
		limit = l
	}
	
	public init(pageNumber: Int = 0, numberOfElementsPerPage: Int) {
		assert(numberOfElementsPerPage >= 0)
		offset = pageNumber * numberOfElementsPerPage
		limit = numberOfElementsPerPage
	}
	
	public init(startOffset: Int = 0, endOffset: Int) {
		assert(endOffset >= startOffset)
		offset = startOffset
		limit = endOffset-startOffset
	}
	
}


public class RESTOffsetLimitPaginator : RESTPaginator {
	
	public let offsetKey: String
	public let limitKey: String
	
	public init(offsetKey ok: String = "offset", limitKey lk: String = "limit") {
		offsetKey = ok
		limitKey = lk
	}
	
	public func paginationParams(withPaginatorInfo info: Any?) -> [String: String]? {
		guard let info = info as? RESTOffsetLimitPaginatorInfo else {return nil}
		
		return [
			limitKey: String(info.limit),
			offsetKey: String(info.offset)
		]
	}
	
}
