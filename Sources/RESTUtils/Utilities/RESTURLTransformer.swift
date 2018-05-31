/*
 * RESTURLTransformer.swift
 * BMO
 *
 * Created by François Lamboley on 01/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public class RESTURLTransformer : ValueTransformer {
	
	public override class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	public override class func transformedValueClass() -> AnyClass {
		return NSURL.self
	}
	
	public override func transformedValue(_ value: Any?) -> Any? {
		if let url = value as? URL {return url}
		return (value as? String).flatMap{ URL(string: $0) }
	}
	
	public override func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let url = value as? URL else {return nil}
		return url.absoluteString
	}
	
}
