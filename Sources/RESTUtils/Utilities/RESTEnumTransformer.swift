/*
 * RESTEnumTransformer.swift
 * BMO
 *
 * Created by François Lamboley on 01/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



/** Must be initialized with a mapping (eg. `["male": Gender.male.rawValue,
"female": Gender.female.rawValue]`). When doing the forward transformation, the
string given in input will be compared case-insensitively. However, for a
reverse transformation, the same case as the one given in the mapping will be
returned.

- Important: The `transformedValueClass` for this transformer will always return
`AnyObject.self`. The actual transformed value will be `EnumRawValueType` which
might not be an Objective-C compatible object… (But Swift will still make it
available at run-time for Objective-C with a custom class depending on many
rules.) */
public class RESTEnumTransformer<EnumRawValueType : Hashable> : ValueTransformer {
	
	public override class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	public override class func transformedValueClass() -> AnyClass {
		return AnyObject.self
	}
	
	public let mapping: [String: EnumRawValueType]
	public let reverseMapping: [EnumRawValueType: String]
	public let invalidValue: EnumRawValueType?
	public let invalidReverseValue: String?
	
	/* If invalidValue is nil, the conversion will fail for the given input for
	 * strings not in the mapping. */
	init(mapping m: [String: EnumRawValueType], invalidValue i: EnumRawValueType? = nil, invalidReverseValue ir: String? = nil) {
		var mappingBuilding = [String: EnumRawValueType]()
		var reverseMappingBuilding = [EnumRawValueType: String]()
		for (k, v) in m {
			reverseMappingBuilding[v] = k
			mappingBuilding[k.lowercased()] = v
		}
		mapping = mappingBuilding
		reverseMapping = reverseMappingBuilding
		
		invalidValue = i
		invalidReverseValue = ir
	}
	
	public override func transformedValue(_ value: Any?) -> Any? {
		if let v = value as? EnumRawValueType {return v}
		guard let str = value as? String else {return nil}
		return mapping[str.lowercased()] ?? invalidValue
	}
	
	public override func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let value = value as? EnumRawValueType else {return nil}
		return reverseMapping[value] ?? invalidReverseValue
	}
	
}
