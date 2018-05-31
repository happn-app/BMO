/*
 * RESTUUIDTransformer.swift
 * BMO
 *
 * Created by François Lamboley on 01/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public class RESTUUIDTransformer : ValueTransformer {
	
	public override class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	public override class func transformedValueClass() -> AnyClass {
		return NSUUID.self
	}
	
	public override func transformedValue(_ value: Any?) -> Any? {
		if let uuid = value as? UUID {return uuid}
		return (value as? String).flatMap{ UUID(uuidString: $0) }
	}
	
	public override func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let uuid = value as? UUID else {return nil}
		return uuid.uuidString
	}
	
}
