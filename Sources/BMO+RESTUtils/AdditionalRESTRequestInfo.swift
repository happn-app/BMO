/*
 * AdditionalRESTRequestInfo.swift
 * BMO+RESTUtils
 *
 * Created by François Lamboley on 4/23/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import CoreData
import Foundation



public struct AdditionalRESTRequestInfo<DbPropertyDescription : Hashable> {
	
	/** Only has meaning for a root additional REST info. If set to a non-nil
	value, will replace the computed REST path from the REST mapping. */
	public var forcedRESTPath: RESTPath?
	
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
	
	public init(fromInfo sourceInfo: AdditionalRESTRequestInfo<DbPropertyDescription>? = nil, forcedRESTPath frp: RESTPath? = nil, fetchedProperties f: Set<DbPropertyDescription>? = nil, additionalRequestParameters add: [String: Any]? = nil, paginatorInfo pi: Any? = nil, subAdditionalInfo subInfo: [DbPropertyDescription: AdditionalRESTRequestInfo<DbPropertyDescription>]? = nil) {
		forcedRESTPath = frp ?? sourceInfo?.forcedRESTPath
		fetchedProperties = f ?? sourceInfo?.fetchedProperties
		additionalRequestParameters = add ?? sourceInfo?.additionalRequestParameters ?? [:]
		paginatorInfo = pi ?? sourceInfo?.paginatorInfo
		_subAdditionalInfo = subInfo ?? sourceInfo?._subAdditionalInfo ?? [:]
	}
	
	/* Private (implicitely, we still need it though for ObjC compatibility)
	 * because the NSPropertyDescription class is buggy. Se we'll implement a
	 * subscript directly in this struct to access sub-additional info which will
	 * workaround the hashing problem. */
	var _subAdditionalInfo: [DbPropertyDescription: AdditionalRESTRequestInfo<DbPropertyDescription>]
	
}
