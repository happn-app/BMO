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



public struct AdditionalRESTRequestInfo<DbPropertyDescription : Hashable> {
	
	/** Only has meaning for a root additional REST info. If set to a non-nil
	value, will replace the computed REST path from the REST mapping. */
	public var forcedRESTPath: RESTPath?
	public var forcedPaginator: RESTPaginator?
	
	public var fetchedProperties: Set<DbPropertyDescription>?
	public var additionalRequestParameters: [String: Any]
	
	public var paginatorInfo: Any?
	
	public subscript(property: DbPropertyDescription) -> AdditionalRESTRequestInfo<DbPropertyDescription>? {
		get {
			if let subInfo = _subAdditionalInfo[property] {return subInfo}
			if let property = property as? NSPropertyDescription {
				/* Let's workaround the hash bug of NSPropertyDescription... :( */
				for (k, v) in _subAdditionalInfo {
					if (k as? NSPropertyDescription)?.name == property.name {
						return v
					}
				}
			}
			return nil
		}
		set {
			defer {_subAdditionalInfo[property] = newValue}
			guard _subAdditionalInfo[property] == nil else {return}
			if let property = property as? NSPropertyDescription {
				/* Let's workaround the hash bug of NSPropertyDescription... :( */
				for (k, _) in _subAdditionalInfo {
					if (k as? NSPropertyDescription)?.name == property.name {
						_subAdditionalInfo.removeValue(forKey: k)
					}
				}
			}
		}
	}
	
	public init(fromInfo sourceInfo: AdditionalRESTRequestInfo<DbPropertyDescription>? = nil, forcedRESTPath frp: RESTPath? = nil, forcedPaginator fp: RESTPaginator? = nil, fetchedProperties f: Set<DbPropertyDescription>? = nil, additionalRequestParameters add: [String: Any]? = nil, paginatorInfo pi: Any? = nil, subAdditionalInfo subInfo: [DbPropertyDescription: AdditionalRESTRequestInfo<DbPropertyDescription>]? = nil) {
		forcedRESTPath = frp ?? sourceInfo?.forcedRESTPath
		forcedPaginator = fp ?? sourceInfo?.forcedPaginator
		fetchedProperties = f ?? sourceInfo?.fetchedProperties
		additionalRequestParameters = add ?? sourceInfo?.additionalRequestParameters ?? [:]
		paginatorInfo = pi ?? sourceInfo?.paginatorInfo
		_subAdditionalInfo = subInfo ?? sourceInfo?._subAdditionalInfo ?? [:]
	}
	
	/* Private (implicitely, we still need it though for ObjC compatibility)
	 * because the NSPropertyDescription class is buggy. Instead we'll implement
	 * a subscript directly in this struct to access sub-additional info which
	 * will workaround the hashing problem. */
	public private(set) var _subAdditionalInfo: [DbPropertyDescription: AdditionalRESTRequestInfo<DbPropertyDescription>]
	
}
