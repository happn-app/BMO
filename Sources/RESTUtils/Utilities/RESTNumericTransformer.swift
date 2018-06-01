/*
 * RESTNumericTransformer.swift
 * BMO
 *
 * Created by François Lamboley on 29/05/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



/** Uses a Scanner to convert an object into a Number (float, double or int
depending on the configuration of the transformer).

Does not allow reverse transformation because there are no real sane default
value for converting a numeric value to a String (except for Ints, of course,
but this is a generic transformer for all numeric values). */
public final class RESTNumericTransformer : ValueTransformer {
	
	public enum StringParsingBase {
		
		case ten
		case sixteen
		
	}
	
	public enum NumericFormat {
		
		case int
		case float
		case double
		
		case intBase(StringParsingBase)
		case floatBase(StringParsingBase)
		case doubleBase(StringParsingBase)
		
		case intWithOptions(doubleToIntRoundingRule: FloatingPointRoundingRule, base: StringParsingBase, ignoredCharacters: CharacterSet, parserMustScanWholeString: Bool, scannerLocale: Locale?, failOnNonWholeNumbers: Bool, parseStringAsDouble: Bool)
		case floatWithOptions(base: StringParsingBase, ignoredCharacters: CharacterSet, parserMustScanWholeString: Bool, scannerLocale: Locale?)
		case doubleWithOptions(base: StringParsingBase, ignoredCharacters: CharacterSet, parserMustScanWholeString: Bool, scannerLocale: Locale?)
		
	}
	
	/** Try and convert the given object to an Int.
	
	Supported input object types:
	- Int
	
	- NSNumber (or any type that dynamically casts into an NSNumber in Swift like
	Double, Float, Decimal, etc.): will return the double value of the number,
	rounded using the given rounding method, then cast to an Int using an exact
	conversion (fails but does not crash if the value is too big or too small).
	The default rounding method is the “schoolbook rounding.”
	If the `failOnNonWholeNumbers` is set to `true`, the double value is checked
	to be whole before being converted into an Int. This is relative to precision
	problems (for instance a very big number with a decimal value might see its
	decimal value dropped when converted to a Double and thus being considered as
	a whole number).
	
	- String: the object will be parsed with a Scanner, with the given ignored
	characters (by default whitespaces and newlines) and the given locale.
	If `parseStringAsDouble` is `true`, will try and parse the string as a Double
	and return the value, converting the same way as with an NSNumber. */
	public static func convertObjectToInt(
		_ obj: Any?, doubleToIntRoundingRule: FloatingPointRoundingRule = .toNearestOrAwayFromZero, stringParsingBase: StringParsingBase = .ten,
		ignoredCharacters: CharacterSet = .whitespacesAndNewlines, parserMustScanWholeString: Bool = true, scannerLocale: Locale? = nil,
		failOnNonWholeNumbers: Bool = false, parseStringAsDouble: Bool = false
	) -> Int? {
		if let n = obj as? Int {return n}
		if let n = obj as? NSNumber {
			guard !failOnNonWholeNumbers || RESTNumericTransformer.isDecimalWhole(n.decimalValue) else {return nil}
			return Int(exactly: n.doubleValue.rounded(doubleToIntRoundingRule))
		}
		
		guard let str = obj as? String else {return nil}
		
		if !parseStringAsDouble {
			/* Let's parse the number */
			var int = 0
			let scanner = Scanner(string: str)
			scanner.locale = scannerLocale
			scanner.charactersToBeSkipped = ignoredCharacters
			switch stringParsingBase {
			case .ten: guard scanner.scanInt(&int) else {return nil}
			case .sixteen:
				var uint64 = UInt64(0)
				guard scanner.scanHexInt64(&uint64), let i = Int(exactly: uint64) else {return nil}
				int = i
			}
			guard !parserMustScanWholeString || scanner.isAtEnd else {return nil}
			return int
		} else {
			var double: Double = 0
			let scanner = Scanner(string: str)
			scanner.locale = scannerLocale
			scanner.charactersToBeSkipped = ignoredCharacters
			switch stringParsingBase {
			case .ten:     guard scanner.scanDouble(&double)    else {return nil}
			case .sixteen: guard scanner.scanHexDouble(&double) else {return nil}
			}
			guard !parserMustScanWholeString || scanner.isAtEnd else {return nil}
			guard !failOnNonWholeNumbers || RESTNumericTransformer.isDecimalWhole(Decimal(double)) else {return nil}
			return Int(exactly: double.rounded(doubleToIntRoundingRule))
		}
	}
	
	/** Try and convert the given object to a Float.
	
	Supported input object types:
	- Float
	
	- NSNumber (or any type that dynamically casts into an NSNumber in Swift like
	Int, Double, Decimal, etc.).
	
	- String: the object will be parsed with a Scanner, with the given ignored
	characters (by default whitespaces and newlines) and the given locale. */
	public static func convertObjectToFloat(_ obj: Any?, stringParsingBase: StringParsingBase = .ten, ignoredCharacters: CharacterSet = .whitespacesAndNewlines, parserMustScanWholeString: Bool = true, scannerLocale: Locale? = nil) -> Float? {
		if let f = obj as? Float {return f}
		if let n = obj as? NSNumber {return n.floatValue}
		
		guard let str = obj as? String else {return nil}
		
		/* Let's parse the number */
		var float: Float = 0
		let scanner = Scanner(string: str)
		scanner.locale = scannerLocale
		scanner.charactersToBeSkipped = ignoredCharacters
		switch stringParsingBase {
		case .ten:     guard scanner.scanFloat(&float)    else {return nil}
		case .sixteen: guard scanner.scanHexFloat(&float) else {return nil}
		}
		guard !parserMustScanWholeString || scanner.isAtEnd else {return nil}
		return float
	}
	
	/** Try and convert the given object to a Double.
	
	Supported input object types:
	- Double
	
	- NSNumber (or any type that dynamically casts into an NSNumber in Swift like
	Int, Float, Decimal, etc.).
	
	- String: the object will be parsed with a Scanner, with the given ignored
	characters (by default whitespaces and newlines) and the given locale. */
	public static func convertObjectToDouble(_ obj: Any?, stringParsingBase: StringParsingBase = .ten, ignoredCharacters: CharacterSet = .whitespacesAndNewlines, parserMustScanWholeString: Bool = true, scannerLocale: Locale? = nil) -> Double? {
		if let d = obj as? Double {return d}
		if let n = obj as? NSNumber {return n.doubleValue}
		
		guard let str = obj as? String else {return nil}
		
		/* Let's parse the number */
		var double: Double = 0
		let scanner = Scanner(string: str)
		scanner.locale = scannerLocale
		scanner.charactersToBeSkipped = ignoredCharacters
		switch stringParsingBase {
		case .ten:     guard scanner.scanDouble(&double)    else {return nil}
		case .sixteen: guard scanner.scanHexDouble(&double) else {return nil}
		}
		guard !parserMustScanWholeString || scanner.isAtEnd else {return nil}
		return double
	}
	
	override public class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	override public class func transformedValueClass() -> AnyClass {
		return NSNumber.self
	}
	
	public let numericFormat: NumericFormat
	
	public init(numericFormat f: NumericFormat) {
		numericFormat = f
	}
	
	public override func transformedValue(_ value: Any?) -> Any? {
		switch numericFormat {
		case .int:    return RESTNumericTransformer.convertObjectToInt(value)
		case .float:  return RESTNumericTransformer.convertObjectToFloat(value)
		case .double: return RESTNumericTransformer.convertObjectToDouble(value)
			
		case .intBase(let base):    return RESTNumericTransformer.convertObjectToInt(value, stringParsingBase: base)
		case .floatBase(let base):  return RESTNumericTransformer.convertObjectToFloat(value, stringParsingBase: base)
		case .doubleBase(let base): return RESTNumericTransformer.convertObjectToDouble(value, stringParsingBase: base)
			
		case .intWithOptions(doubleToIntRoundingRule: let r, base: let base, ignoredCharacters: let ic, parserMustScanWholeString: let w, scannerLocale: let l, failOnNonWholeNumbers: let fnw, parseStringAsDouble: let d):
			return RESTNumericTransformer.convertObjectToInt(value, doubleToIntRoundingRule: r, stringParsingBase: base, ignoredCharacters: ic, parserMustScanWholeString: w, scannerLocale: l, failOnNonWholeNumbers: fnw, parseStringAsDouble: d)
			
		case .floatWithOptions(base: let base, ignoredCharacters: let ic, parserMustScanWholeString: let w, scannerLocale: let l):
			return RESTNumericTransformer.convertObjectToFloat(value, stringParsingBase: base, ignoredCharacters: ic, parserMustScanWholeString: w, scannerLocale: l)
			
		case .doubleWithOptions(base: let base, ignoredCharacters: let ic, parserMustScanWholeString: let w, scannerLocale: let l):
			return RESTNumericTransformer.convertObjectToDouble(value, stringParsingBase: base, ignoredCharacters: ic, parserMustScanWholeString: w, scannerLocale: l)
		}
	}
	
	/* ***************
      MARK: - Private
	   *************** */
	
	/* From https://stackoverflow.com/a/46331176/1152894
	 * I found many variations on the same method to check whether a decimal is
	 * whole, this method seemed the best. */
	private static func isDecimalWhole(_ d: Decimal) -> Bool {
		guard !d.isZero else {return true}
		guard d.isNormal else {return false}
		
		var d = d
		var rounded = Decimal()
		NSDecimalRound(&rounded, &d, 0, .plain)
		return d == rounded
	}
	
}
