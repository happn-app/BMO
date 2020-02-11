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
	public var subAdditionalInfo: [DbPropertyDescription: AdditionalRESTRequestInfo<DbPropertyDescription>]
	
	/**
	Access and modify the subAdditionalInfo. Strictly equivalent to accessing the
	subAdditionalInfo dictionary directly, but kept for retro-compatibility w/
	previous version where the CoreData Db conformance was made with the
	NSPropertyDescription type directly, which caused problems because of a
	CoreData bug. */
	public subscript(property: DbPropertyDescription) -> AdditionalRESTRequestInfo<DbPropertyDescription>? {
		get {subAdditionalInfo[property]}
		set {subAdditionalInfo[property] = newValue}
	}
	
	public init(fromInfo sourceInfo: AdditionalRESTRequestInfo<DbPropertyDescription>? = nil, forcedRESTPath frp: RESTPath? = nil, forcedPaginator fp: RESTPaginator? = nil, fetchedProperties f: Set<DbPropertyDescription>? = nil, additionalRequestParameters add: [String: Any]? = nil, paginatorInfo pi: Any? = nil, subAdditionalInfo subInfo: [DbPropertyDescription: AdditionalRESTRequestInfo<DbPropertyDescription>]? = nil) {
		forcedRESTPath = frp ?? sourceInfo?.forcedRESTPath
		forcedPaginator = fp ?? sourceInfo?.forcedPaginator
		fetchedProperties = f ?? sourceInfo?.fetchedProperties
		additionalRequestParameters = add ?? sourceInfo?.additionalRequestParameters ?? [:]
		paginatorInfo = pi ?? sourceInfo?.paginatorInfo
		subAdditionalInfo = subInfo ?? sourceInfo?.subAdditionalInfo ?? [:]
	}
	
}
