/*
 * RESTBase64DataTransformer.swift
 * BMO
 *
 * Created by François Lamboley on 01/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public class RESTDataBase64Transformer : ValueTransformer {
	
	public override class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	public override class func transformedValueClass() -> AnyClass {
		return NSData.self
	}
	
	public let decodingOptions: NSData.Base64DecodingOptions
	public let encodingOptions: NSData.Base64EncodingOptions
	
	public override convenience init() {
		self.init(decodingOptions: [], encodingOptions: [])
	}
	
	public init(decodingOptions d: NSData.Base64DecodingOptions, encodingOptions e: NSData.Base64EncodingOptions) {
		decodingOptions = d
		encodingOptions = e
	}
	
	public override func transformedValue(_ value: Any?) -> Any? {
		return (value as? String).flatMap{ Data(base64Encoded: $0, options: decodingOptions) }
	}
	
	public override func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let data = value as? Data else {return nil}
		return data.base64EncodedString(options: encodingOptions)
	}
	
}
