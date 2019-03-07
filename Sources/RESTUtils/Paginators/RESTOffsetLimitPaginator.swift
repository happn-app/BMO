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
