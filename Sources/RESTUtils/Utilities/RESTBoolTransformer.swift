/*
 * RESTBoolTransformer.swift
 * BMO
 *
 * Created by François Lamboley on 01/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public final class RESTBoolTransformer : ValueTransformer {
	
	/** Try and convert the given object to a Boolean.
	
	Supported input object types:
	- Bool
	
	- Anything that parses as an Int (input must be a whole number) with the
	RESTNumericTransformer. If value is 0, converts to false, if 1, converts to
	true, for any other value, conversion fails (return nil).
	
	- String: The string will be tested against common boolean string values (in
	English, indeed). For true, we test for "true", "t", "yes", "y" and "ok"; for
	false, we test for "false", "f", "no", "n" and "ko".
	
	- Note: Does **not** convert any number to a boolean like NSNumber does. */
	public static func convertObjectToBool(_ obj: Any?, trimmedChars: CharacterSet = .whitespacesAndNewlines) -> Bool? {
		if let b = obj as? Bool {return b}
		
		/* Note: For our use case, trimmedChars and ignoredCharacters can be the
		 *       same, even though their meaning is not the same. (Because the
		 *       values that mean something to us are on one character only.) */
		switch RESTNumericTransformer.convertObjectToInt(obj, ignoredCharacters: trimmedChars, parserMustScanWholeString: true, scannerLocale: nil, failOnNonWholeNumbers: true, parseStringAsDouble: false) {
		case 0?: return false
		case 1?: return true
		case .some: return nil
		default: (/*nop*/)
		}
		
		guard let str = (obj as? String)?.trimmingCharacters(in: trimmedChars).lowercased() else {return nil}
		
		/* Checking for standard bool strings */
		if Set(arrayLiteral: "true", "t", "yes", "y", "ok").contains(str) {return true}
		if Set(arrayLiteral: "false", "f", "no", "n", "ko").contains(str) {return false}
		
		return nil
	}
	
	override public class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override public class func transformedValueClass() -> AnyClass {
		return NSNumber.self
	}
	
	public let trimmedChars: CharacterSet
	
	public init(trimmedChars c: CharacterSet = .whitespacesAndNewlines) {
		trimmedChars = c
	}
	
	public override func transformedValue(_ value: Any?) -> Any? {
		return RESTBoolTransformer.convertObjectToBool(value, trimmedChars: trimmedChars)
	}
	
}
