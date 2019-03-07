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



/** Currently always parses with support for backslashing, zero length values
and no braces shortcut when parsing flatified string.

The reason for this is I converted the parser from PHP and I'm lazy enough not
to change it to support non-backslashing, nonzero length, and especially braces. */
public struct StandardRESTParameterizedStringSetParser : ParameterizedStringSetParser {
	
	public enum Error : Swift.Error {
		
		case unexpectedCharAfterParamValueEnd(Character?)
		case earlyEndValue
		case earlyEndParam
		case earlyEndParamValue
		
		case internalError
		
	}
	
	public let supportsBackslashing: Bool /* true for happn, but set to false as the back does not want to receive the backslashes... */
	public let supportsZeroLengthValues: Bool /* true for happn, but weird, confusing and unused, so set to false... */
	public let subValueNameForBracesShortcut: String? /* "fields" for Facebook */
	
	public init(supportsBackslashing b: Bool = false, supportsZeroLengthValues z: Bool = false, subValueNameForBracesShortcut s: String? = nil) {
		supportsBackslashing = b
		supportsZeroLengthValues = z
		subValueNameForBracesShortcut = s
	}
	
	/** Can be called as much as needed (and should even be thread-safe!)
	
	However, you should keep the parsed value for obvious performance reasons... */
	public func parse(flatifiedParam: String) throws -> ParameterizedStringSet {
		var engine: Engine = waitEndValue
		var engineState = EngineState()
		for char in flatifiedParam {
			engine = try engine(char, &engineState) as! Engine /* See Engine definition for explanation of the "as!" */
		}
		_ = try engine(nil, &engineState)
		return ParameterizedStringSet(valuesAndParams: engineState.result)
	}
	
	public func flatify(param: ParameterizedStringSet) -> String {
		var first = true
		var ret = String()
		for (val, subparam) in param.valuesAndParams {
			guard !val.isEmpty || supportsZeroLengthValues else {continue}
			/* Note: We don't check if value is safe in case there are no support
			 * for backslashing (no comma, dot, parenthesis, etc.) */
			ret += (first ? "" : ",") + backslashedValue(val)
			
			for (subparamVal, subsubparam) in subparam {
				guard subparamVal != subValueNameForBracesShortcut else {continue} /* Braces must be added after all other params */
				ret += "." + backslashedValue(subparamVal) + "(" + backslashedValue(flatify(param: subsubparam)) + ")"
			}
			if let subValueNameForBracesShortcut = subValueNameForBracesShortcut, let subsubparam = subparam[subValueNameForBracesShortcut] {
				ret += "{" + backslashedValue(flatify(param: subsubparam)) + "}"
			}
			
			first = false
		}
		return ret
	}
	
	/* I'd like the Engine definition to make the function return an Engine, but
	 * a typealias cannot circularly reference itself! :( */
	private typealias Engine = (_ char: Character?, _ engineState: inout EngineState) throws -> Any
	
	private struct EngineState {
		
		var level = 0
		
		var curValue = String()
		var curParam = String()
		var curParamValue = String()
		
		var result = [String: [String: ParameterizedStringSet]]()
		
	}
	
	private func waitStartFieldOrStartParam(char: Character?, engineState s: inout EngineState) throws -> Engine {
		switch char {
		case nil: return waitStartFieldOrStartParam
		case ","?: s.curValue = ""; return waitEndValue
		case "."?:                  return waitEndParam
		default: throw Error.unexpectedCharAfterParamValueEnd(char)
		}
	}
	
	private func waitEndParamValueQuoteBackslash(char: Character?, engineState s: inout EngineState) throws -> Engine {
		guard let char = char else {throw Error.earlyEndParamValue}
		s.curParamValue.append(treatBackslashedChar(char))
		return waitEndParamValueQuote
	}
	
	private func waitEndParamValueBackslash(char: Character?, engineState s: inout EngineState) throws -> Engine {
		guard let char = char else {throw Error.earlyEndParamValue}
		s.curParamValue.append(treatBackslashedChar(char))
		return waitEndParamValue
	}
	
	private func waitEndParamValueQuote(char: Character?, engineState s: inout EngineState) throws -> Engine {
		switch char {
		case nil: throw Error.earlyEndParamValue
		case "\""?: return waitEndParamValue
		case "\\"?: return waitEndParamValueQuoteBackslash
		case .some(let char): s.curParamValue.append(char); return waitEndParamValueQuote
		}
	}
	
	private func waitEndParamValue(char: Character?, engineState s: inout EngineState) throws -> Engine {
		switch char {
		case nil: throw Error.earlyEndParamValue
		case "\""?: return waitEndParamValueQuote
		case "\\"?: return waitEndParamValueBackslash
		case "("?: s.level += 1; s.curParamValue.append("(")
		case ")"?:
			if s.level == 0 {
				guard !s.curValue.isEmpty else {throw Error.internalError}
				guard !s.curParam.isEmpty else {throw Error.internalError}
				
				var subParam = s.result[s.curValue] ?? [String: ParameterizedStringSet]()
				subParam[s.curParam] = try parse(flatifiedParam: s.curParamValue)
				s.result[s.curValue] = subParam
				
				s.curParam = ""; s.curParamValue = ""
				return waitStartFieldOrStartParam
			} else {
				s.level -= 1
				s.curParamValue.append(")")
			}
			
		case .some(let char):
			s.curParamValue.append(char)
		}
		return waitEndParamValue
	}
	
	private func waitEndParamQuoteBackslash(char: Character?, engineState s: inout EngineState) throws -> Engine {
		guard let char = char else {throw Error.earlyEndParam}
		s.curParam.append(treatBackslashedChar(char))
		return waitEndParamQuote
	}
	
	private func waitEndParamBackslash(char: Character?, engineState s: inout EngineState) throws -> Engine {
		guard let char = char else {throw Error.earlyEndParam}
		s.curParam.append(treatBackslashedChar(char))
		return waitEndParam
	}
	
	private func waitEndParamQuote(char: Character?, engineState s: inout EngineState) throws -> Engine {
		switch char {
		case nil: throw Error.earlyEndParam
		case "\""?: return waitEndParam
		case "\\"?: return waitEndParamQuoteBackslash
		case .some(let char): s.curParam.append(char); return waitEndParamQuote
		}
	}
	
	private func waitEndParam(char: Character?, engineState s: inout EngineState) throws -> Engine {
		switch char {
		case nil: throw Error.earlyEndParam
		case "\""?: return waitEndParamQuote
		case "\\"?: return waitEndParamBackslash
		case "("?:
			guard !s.curValue.isEmpty else {throw Error.internalError}
			guard !s.curParam.isEmpty else {throw Error.earlyEndParam}
			
			s.curParamValue = ""
			return waitEndParamValue
			
		case .some(let char):
			s.curParam.append(char)
			return waitEndParam
		}
	}
	
	private func waitEndValueQuoteBackslash(char: Character?, engineState s: inout EngineState) throws -> Engine {
		guard let char = char else {throw Error.earlyEndValue}
		s.curValue.append(treatBackslashedChar(char))
		return waitEndValueQuote
	}
	
	private func waitEndValueBackslash(char: Character?, engineState s: inout EngineState) throws -> Engine {
		guard let char = char else {throw Error.earlyEndValue}
		s.curValue.append(treatBackslashedChar(char))
		return waitEndValue
	}
	
	private func waitEndValueQuote(char: Character?, engineState s: inout EngineState) throws -> Engine {
		switch char {
		case nil: throw Error.earlyEndValue
		case "\""?: return waitEndValue
		case "\\"?: return waitEndValueQuoteBackslash
		case .some(let char): s.curValue.append(char); return waitEndValueQuote
		}
	}
	
	private func waitEndValue(char: Character?, engineState s: inout EngineState) throws -> Engine {
		var nextEngine: Engine = waitEndValue
		switch char {
		case "\""?: return waitEndValueQuote
		case "\\"?: return waitEndValueBackslash
		case "."?: nextEngine = waitEndParam; fallthrough
		case ","?: fallthrough
		case nil:
			s.result[s.curValue] = [:]
			
			if char != "." {s.curValue = ""}
			return nextEngine
			
		case .some(let char):
			s.curValue.append(char)
			return waitEndValue
		}
	}
	
	private func treatBackslashedChar(_ char: Character) -> Character {
		switch char {
		case "t": return "\t"
		case "n": return "\n"
		default: return char
		}
	}
	
	private func backslashedValue(_ v: String) -> String {
		guard supportsBackslashing else {return v}
		return v
			.replacingOccurrences(of: "\\", with: "\\\\")
			.replacingOccurrences(of: ",", with: "\\,")
			.replacingOccurrences(of: ".", with: "\\.")
			.replacingOccurrences(of: "(", with: "\\(")
			.replacingOccurrences(of: ")", with: "\\)")
			.replacingOccurrences(of: "{", with: "\\{") /* We replace braces even if not supported; it does not matter anyway. */
			.replacingOccurrences(of: "}", with: "\\}")
			.replacingOccurrences(of: "\"", with: "\\\"")
	}
	
}
