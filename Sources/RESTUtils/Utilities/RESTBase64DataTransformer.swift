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
