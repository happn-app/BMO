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



/** Wrap an optional value in this to get double (or more) optionality in a
ValueTransformer, and stay type coherent.

Class is prefixed with ObjC even though it is not @objc just to signify it
exists solely for historical reasons, and should be dropped as soon as
ValueTransformer is more Swifty and supports double-optionality natively. */
public class ObjC_RESTMapperOptionalWrapper : NSObject {
	
	public let value: Any?
	
	public override init() {value = nil}
	public init(_ v: Any)  {value = v}
	
}

public struct TransformerValueWithUserInfo {
	
	public let value: Any?
	public let userInfo: Any?
	
}

public struct RESTMapperTransformer {
	
	let transformer: ValueTransformer
	let reversed: Bool
	
	let transformNilProperties: Bool
	let transformerNeedsUserInfo: Bool
	
	public init(transformer t: ValueTransformer, reversed r: Bool, transformNilProperties n: Bool, transformerNeedsUserInfo i: Bool) {
		transformer = t
		reversed = r
		transformNilProperties = n
		transformerNeedsUserInfo = i
	}
	
	func applyTransform(sourceValue: Any?, userInfo: Any?) -> Any?? {
		let sourceValueTmp = (sourceValue is NSNull ? nil : sourceValue)
		if sourceValueTmp == nil && !transformNilProperties {return .some(nil)}
		
		let sourceValue = (!transformerNeedsUserInfo ? sourceValueTmp : TransformerValueWithUserInfo(value: sourceValueTmp, userInfo: userInfo))
		
		let transformedValue = (!reversed ? transformer.transformedValue(sourceValue) : transformer.reverseTransformedValue(sourceValue))
		if let objcWrapped = transformedValue as? ObjC_RESTMapperOptionalWrapper {return .some(objcWrapped.value)}
		/* Note for below, we do NOT return transformedValue directly... If we do,
		 * if transformedValue == nil, we actually return .some(nil) for whatever
		 * reason (Xcode 8.3.3 (8E3004b)). */
		if let value = transformedValue {return value}
		else                            {return nil}
	}
	
}
