/*
 * RESTMaxIdPaginator.swift
 * RESTUtils
 *
 * Created by Thomas Levy on 24/09/15.
 * Copyright © 2015 happn. All rights reserved.
 */

import Foundation



public struct RESTMaxIdPaginatorInfo {
	
	public let maxReachedId: String?
	public let count: Int
	
	public init(maxReachedId i: String?, count c: Int) {
		maxReachedId = i
		count = c
	}
	
}


public class RESTMaxIdPaginator : RESTPaginator {
	
	public let maxReachedIdKey: String
	public let countKey: String
	
	public init(maxReachedIdKey mrik: String, countKey ck: String = "count") {
		maxReachedIdKey = mrik
		countKey = ck
	}
	
	public func paginationParams(withPaginatorInfo info: Any?) -> [String: String]? {
		guard let info = info as? RESTMaxIdPaginatorInfo else {return nil}
		
		var ret = [countKey: String(info.count)]
		if let mri = info.maxReachedId {ret[maxReachedIdKey] = mri}
		return ret
	}
	
}
