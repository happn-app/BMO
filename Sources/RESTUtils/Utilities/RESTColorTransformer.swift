/*
 * RESTColorTransformer.swift
 * BMO
 *
 * Created by François Lamboley on 01/06/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation

#if os(OSX)
	import AppKit
	public typealias BMOColor = NSColor
#else
	import UIKit
	public typealias BMOColor = UIColor
#endif



/** Reverse transformation is not supported. */
public class RESTColorTransformer : ValueTransformer {
	
	public enum ColorType {
		
		public enum ColorComponentInfo<ValueType> {
			
			case constant(ValueType)
			case mandatoryToken(id: String)
			case optionalToken(id: String, defaultValue: ValueType)
			
			func resolve(with vars: [String: Any]) -> ValueType? {
				switch self {
				case .constant(let v):                                return v
				case .mandatoryToken(id: let id):                     return vars[id] as? ValueType
				case .optionalToken(id: let id, defaultValue: let v): return vars[id] as? ValueType ?? v
				}
			}
			
		}
		
		case rgba(redInfo: ColorComponentInfo<CGFloat>, greenInfo: ColorComponentInfo<CGFloat>, blueInfo: ColorComponentInfo<CGFloat>, alphaInfo: ColorComponentInfo<CGFloat>)
		case hsba(hueInfo: ColorComponentInfo<CGFloat>, saturationInfo: ColorComponentInfo<CGFloat>, brightnessInfo: ColorComponentInfo<CGFloat>, alphaInfo: ColorComponentInfo<CGFloat>)
		
		case whiteAlpha(whiteInfo: ColorComponentInfo<CGFloat>, alphaInfo: ColorComponentInfo<CGFloat>)
		
		@available(OSX 10.13, tvOS 11.0, iOS 11.0, watchOS 4.0, *)
		case colorName(info: ColorComponentInfo<String>)
		
	}
	
	public indirect enum ColorFormatToken {
		
		case constant(value: String, optional: Bool)
		case string(from: CharacterSet, id: String, optional: Bool)
		
		case hexInt(nChars: Int?, transform: (Int) -> CGFloat, id: String, optional: Bool)
		case decInt(nChars: Int?, transform: (Int) -> CGFloat, id: String, optional: Bool)
		
		case hexDouble(transform: (Double) -> CGFloat, id: String, optional: Bool)
		case decDouble(transform: (Double) -> CGFloat, id: String, optional: Bool)
		
		case subTokens([ColorFormatToken], optional: Bool)
		
		/* Returns true when parsing succeeds, false when it does not. startIndex
		 * and vars may change even when parsing fails. Will return true even if
		 * parsing ends but the end of the string was not reached. */
		static func parse(tokens: [ColorFormatToken], in string: String, from startIndex: inout String.Index, vars: inout [String: Any]) -> Bool {
			for token in tokens {
				guard token.parse(string: string, from: &startIndex, vars: &vars) else {
					return false
				}
			}
			return true
		}
		
		func parse(string: String, from startIndex: inout String.Index, vars: inout [String: Any]) -> Bool {
			assert(startIndex <= string.endIndex)
			
			switch self {
			case .constant(value: let constant, optional: let optional):
				/* Let's parse the given constant using a Scanner */
				return scan(in: string, at: &startIndex, with: { $0.scanString(constant, into: nil) }) || optional
				
			case .string(from: let characterSet, id: let id, optional: let optional):
				/* Let's parse the given constant */
				var res: NSString?
				guard scan(in: string, at: &startIndex, with: { $0.scanCharacters(from: characterSet, into: &res) }) else {
					return optional
				}
				
				vars[id] = res! as String
				return true
				
			case .hexInt(nChars: let nChars, transform: let transform, id: let id, optional: let optional):
				var res: Int = 0
				if let nChars = nChars {
					guard let endSubStrIdx = string.index(startIndex, offsetBy: nChars, limitedBy: string.endIndex) else {return optional}
					
					let subStr = String(string[startIndex..<endSubStrIdx])
					var subStrStartIdx = subStr.startIndex
					var uint64: UInt64 = 0
					guard scan(in: subStr, at: &subStrStartIdx, with: { $0.scanHexInt64(&uint64) }), subStrStartIdx == subStr.endIndex, let i = Int(exactly: uint64) else {
						return optional
					}
					startIndex = endSubStrIdx
					res = i
				} else {
					var uint64: UInt64 = 0
					guard scan(in: string, at: &startIndex, with: { $0.scanHexInt64(&uint64) }), let i = Int(exactly: uint64) else {
						return optional
					}
					res = i
				}
				
				vars[id] = transform(res)
				return true
				
			case .decInt(nChars: let nChars, transform: let transform, id: let id, optional: let optional):
				var res: Int = 0
				if let nChars = nChars {
					guard let endSubStrIdx = string.index(startIndex, offsetBy: nChars, limitedBy: string.endIndex) else {return optional}
					
					let subStr = String(string[startIndex..<endSubStrIdx])
					var subStrStartIdx = subStr.startIndex
					guard scan(in: subStr, at: &subStrStartIdx, with: { $0.scanInt(&res) }), subStrStartIdx == subStr.endIndex else {
						return optional
					}
					startIndex = endSubStrIdx
				} else {
					guard scan(in: string, at: &startIndex, with: { $0.scanInt(&res) }) else {
						return optional
					}
				}
				
				vars[id] = transform(res)
				return true
				
			case .hexDouble(transform: let transform, id: let id, optional: let optional):
				var res: Double = 0
				guard scan(in: string, at: &startIndex, with: { $0.scanHexDouble(&res) }) else {
					return optional
				}
				
				vars[id] = transform(res)
				return true
				
			case .decDouble(transform: let transform, id: let id, optional: let optional):
				var res: Double = 0
				guard scan(in: string, at: &startIndex, with: { $0.scanDouble(&res) }) else {
					return optional
				}
				
				vars[id] = transform(res)
				return true
				
			case .subTokens(let subtokens, optional: let optional):
				var newVars = vars
				var newStartIndex = startIndex
				guard ColorFormatToken.parse(tokens: subtokens, in: string, from: &newStartIndex, vars: &newVars) else {
					return optional
				}
				
				startIndex = newStartIndex
				vars = newVars
				return true
			}
		}
		
		private func scan(in string: String, at startIndex: inout String.Index, with handler: (_ scanner: Scanner) -> Bool) -> Bool {
			let s = scanner(for: string, at: startIndex)
			
			guard handler(s), let newStartIndex = scannerLocationIndex(s, in: string) else {
				return false
			}
			
			startIndex = newStartIndex
			return true
		}
		
		private func scanner(for string: String, at index: String.Index) -> Scanner {
			let scanner = Scanner(string: string)
			if index < string.endIndex {
				let rangeForIndexConversion = Range<String.Index>(uncheckedBounds: (lower: index, upper: index))
				let objcIndex = NSRange(rangeForIndexConversion, in: string).location
				scanner.scanLocation = objcIndex
			} else {
				scanner.scanLocation = (string as NSString).length
			}
			scanner.charactersToBeSkipped = CharacterSet()
			return scanner
		}
		
		/* The conversion should never fail as the scanner should never parse
		 * half-emojis... but to be safe, let's treat the case it does happen!
		 * (This is why we return a nullable String.Index) */
		private func scannerLocationIndex(_ scanner: Scanner, in string: String) -> String.Index? {
			guard scanner.scanLocation < (string as NSString).length else {return string.endIndex}
			let rangeForIndexConversion = NSRange(location: scanner.scanLocation, length: 0)
			return Range(rangeForIndexConversion, in: string)?.lowerBound
		}
		
	}
	
	public static let defaultColorFormatTokens: [ColorFormatToken] = [
		.constant(value: "#", optional: true),
		.hexInt(nChars: 2, transform: { CGFloat($0)/255 }, id: "r", optional: false),
		.hexInt(nChars: 2, transform: { CGFloat($0)/255 }, id: "g", optional: false),
		.hexInt(nChars: 2, transform: { CGFloat($0)/255 }, id: "b", optional: false),
		.hexInt(nChars: 2, transform: { CGFloat($0)/255 }, id: "a", optional: true)
	]
	
	public static let defaultColorType = ColorType.rgba(
		redInfo: .mandatoryToken(id: "r"), greenInfo: .mandatoryToken(id: "g"), blueInfo: .mandatoryToken(id: "b"),
		alphaInfo: .optionalToken(id: "a", defaultValue: 1)
	)
	
	/** Try and convert the given object to a Color.
	
	Supported input object types:
	- Color
	
	- String: The string will be parsed using the given color type and format. */
	public static func convertObjectToColor(_ obj: Any?, colorType: ColorType = RESTColorTransformer.defaultColorType, colorFormat: [ColorFormatToken] = RESTColorTransformer.defaultColorFormatTokens) -> BMOColor? {
		if let c = obj as? BMOColor {return c}
		
		guard let str = obj as? String else {return nil}
		
		var vars = [String: Any]()
		var parseIndex = str.startIndex
		guard ColorFormatToken.parse(tokens: colorFormat, in: str, from: &parseIndex, vars: &vars) else {return nil}
		guard parseIndex == str.endIndex else {return nil}
		
		switch colorType {
		case .colorName(info: let info):
			guard #available(OSX 10.13, tvOS 11.0, iOS 11.0, watchOS 4.0, *) else {return nil}
			guard let colorName = info.resolve(with: vars) else {return nil}
			#if os(OSX)
				return NSColor(named: colorName)
			#else
				return UIColor(named: colorName)
			#endif
			
		case .whiteAlpha(whiteInfo: let whiteInfo, alphaInfo: let alphaInfo):
			guard let whiteValue = whiteInfo.resolve(with: vars) else {return nil}
			guard let alphaValue = alphaInfo.resolve(with: vars) else {return nil}
			return BMOColor(white: whiteValue, alpha: alphaValue)
			
		case .rgba(redInfo: let rInfo, greenInfo: let gInfo, blueInfo: let bInfo, alphaInfo: let aInfo):
			guard let rValue = rInfo.resolve(with: vars) else {return nil}
			guard let gValue = gInfo.resolve(with: vars) else {return nil}
			guard let bValue = bInfo.resolve(with: vars) else {return nil}
			guard let aValue = aInfo.resolve(with: vars) else {return nil}
			return BMOColor(red: rValue, green: gValue, blue: bValue, alpha: aValue)
			
		case .hsba(hueInfo: let hInfo, saturationInfo: let sInfo, brightnessInfo: let bInfo, alphaInfo: let aInfo):
			guard let hValue = hInfo.resolve(with: vars) else {return nil}
			guard let sValue = sInfo.resolve(with: vars) else {return nil}
			guard let bValue = bInfo.resolve(with: vars) else {return nil}
			guard let aValue = aInfo.resolve(with: vars) else {return nil}
			return BMOColor(hue: hValue, saturation: sValue, brightness: bValue, alpha: aValue)
		}
	}
	
	public override class func allowsReverseTransformation() -> Bool {
		return false
	}
	
	public override class func transformedValueClass() -> AnyClass {
		return BMOColor.self
	}
	
	public let colorType: ColorType
	public let colorFormat: [ColorFormatToken]
	
	public override convenience init() {
		self.init(colorType: RESTColorTransformer.defaultColorType, colorFormat: RESTColorTransformer.defaultColorFormatTokens)
	}
	
	public init(colorType t: ColorType, colorFormat f: [ColorFormatToken]) {
		colorType = t
		colorFormat = f
	}
	
	public override func transformedValue(_ value: Any?) -> Any? {
		return RESTColorTransformer.convertObjectToColor(value, colorType: colorType, colorFormat: colorFormat)
	}
	
}
