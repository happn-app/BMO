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
