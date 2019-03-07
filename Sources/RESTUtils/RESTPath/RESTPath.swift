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



public enum RESTPath : LosslessStringConvertible, CustomDebugStringConvertible {
	
	case constant(String)
	case variable(String)
	case components([RESTPath], isRoot: Bool)
	
	/* Format: parent_element/|relationshipToParent.remoteId|/child_element(/|remoteId|)
	 *    The special characters "|", "(", ")" and "\" can be escaped with a
	 *    backslash ("\"). A non-special character being escaped will result in
	 *    an error (failed initialization). Parenthesis can be nested.
	 *    See the resolvedPath* methods for a description of the substitution. */
	public init?(_ string: String) {
		guard !string.isEmpty else {
			self = .constant("")
			return
		}
		
		var mstring = string
		guard let p = RESTPath(string: &mstring, isSubParse: false) else {return nil}
		let r: RESTPath
		switch p {
		case .components(let components, isRoot: _ /* We already know its false */):
			if components.count == 1 {r = components.first!}
			else                     {r = p}
			
		default:
			r = p
		}
		
		self = r
		assert(mstring.isEmpty)
		assert(serialized() == string) /* We can be LosslessStringConvertible because this assert is true */
	}
	
	/* For constant REST Path (no variables), this will return a non-nil value. */
	public var resolvedConstant: String? {
		switch self {
		case .variable: return nil
		case .constant(let str): return str
		case .components(let components, isRoot: _):
			var res = ""
			for c in components {
				guard let str = c.resolvedConstant else {return nil}
				res += str
			}
			return res
		}
	}
	
	public func resolvedPath(source: Any) -> String? {
		return resolvedPath(sources: [source])
	}
	
	/* The substitution is done as follow:
	 *   - Parts between pipes are key path, that must be resolved from the given
	 *     sources. A key path here is a simple dot-separated path of properties.
	 *     Source objects must conform to the RESTPathKeyResovable protocol or be
	 *     compatible [String: Any];
	 *   - If the key path is found, the value is replaced;
	 *   - If not, behavior will differ depending on whether the replacement is
	 *     in a subgroup (between parenthesis):
	 *     - If it is, the whole subgroup is dropped;
	 *     - Otherwise, the whole string is dropped. */
	public func resolvedPath(sources: [Any]) -> String? {
		switch self {
		case .constant(let str):
			return str
			
		case .variable(let variable):
			for source in sources {
				if let resolved = string(for: variable, in: source) {
					return resolved
				}
			}
			return nil
			
		case .components(let components, isRoot: _):
			var res = ""
			for component in components {
				if let resolved = component.resolvedPath(sources: sources) {
					res += resolved
				} else {
					switch component {
					case .components: (/*nop*/)
					default: return nil
					}
				}
			}
			return res
		}
	}
	
	public func serialized() -> String {
		switch self {
		case .constant(let str): return       str.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "(", with: "\\(").replacingOccurrences(of: ")", with: "\\)").replacingOccurrences(of: "|", with: "\\|")
		case .variable(let str): return "|" + str.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "(", with: "\\(").replacingOccurrences(of: ")", with: "\\)").replacingOccurrences(of: "|", with: "\\|") + "|"
		case .components(let components, isRoot: let root):
			return components.reduce(root ? "" : "(", { $0 + $1.serialized() }) + (root ? "" : ")")
		}
	}
	
	public var description: String {
		return serialized()
	}
	
	public var debugDescription: String {
		return "RESTPath<" + serialized() + ">"
	}
	
	/* ***************
      MARK: - Private
	   *************** */
	
	private enum Engine {
		
		case waitEndConstant
		case backslashedCharInConstant
		case waitEndVariable
		case backslashedCharInVariable

	}
	
	private struct EngineState {
		
		var curStringBuilding = ""
		
	}
	
	/* After the init returns, string will contain what's left of the string
	 * after parsing. Will always be an empty string in case of a non-subparsing
	 * init.
	 * Sub-parsing imply an optional components. */
	private init?(string: inout String, isSubParse: Bool) {
		assert(!string.isEmpty || isSubParse)
		if string.isEmpty {return nil}
		
		var componentsBuilding = [RESTPath]()
		var engine = Engine.waitEndConstant
		var engineState = EngineState()
		
		func endCurrentConstant() {
			guard !engineState.curStringBuilding.isEmpty else {return}
			componentsBuilding.append(.constant(engineState.curStringBuilding))
			engineState.curStringBuilding = ""
		}
		
		while let c = string.first {
			string.replaceSubrange(...string.startIndex, with: "")
			
			switch engine {
			case .waitEndConstant:
				switch c {
				case "\\": engine = .backslashedCharInConstant
					
				case "|":
					endCurrentConstant()
					engine = .waitEndVariable
					
				case "(":
					endCurrentConstant()
					
					guard let o = RESTPath(string: &string, isSubParse: true) else {return nil}
					componentsBuilding.append(o)
					
				case ")":
					guard isSubParse else {return nil}
					endCurrentConstant()
					self = .components(componentsBuilding, isRoot: false)
					return
					
				default:
					engineState.curStringBuilding.append(c)
				}
				
			case .backslashedCharInConstant:
				switch c {
				case "\\", "|", "(", ")": (/*nop*/)
				default: return nil
				}
				engineState.curStringBuilding.append(c)
				engine = .waitEndConstant
				
			case .waitEndVariable:
				switch c {
				case "\\": engine = .backslashedCharInVariable
					
				case "|":
					componentsBuilding.append(.variable(engineState.curStringBuilding))
					engineState.curStringBuilding = ""
					engine = .waitEndConstant
					
				case "(", ")":
					return nil
					
				default:
					engineState.curStringBuilding.append(c)
				}
				
			case .backslashedCharInVariable:
				switch c {
				case "\\", "|", "(", ")": (/*nop*/)
				default: return nil
				}
				engineState.curStringBuilding.append(c)
				engine = .waitEndVariable
			}
		}
		
		guard !isSubParse else {return nil}
		
		switch engine {
		case .waitEndVariable, .backslashedCharInVariable: return nil
		case .backslashedCharInConstant: engineState.curStringBuilding.append("\\")
		case .waitEndConstant: (/*nop*/)
		}
		
		endCurrentConstant()
		self = .components(componentsBuilding, isRoot: true)
	}
	
	private func string(for keyPath: String, in source: Any) -> String? {
		let keyPathComponents = keyPath.components(separatedBy: ".")
		var currentKey1 = keyPath
		var currentKey2: String?
		
		for i in (0..<keyPathComponents.count).reversed() {
			let firstLevelVal: Any?
			switch source {
			case let dic as [String: Any]:        firstLevelVal = dic[currentKey1]
			case let kvr as RESTPathKeyResovable: firstLevelVal = kvr.restPathObject(for: currentKey1)
			default:                              return nil /* If source is neither a dictionary nor a RESTPathKeyResovable, no need to even try resolving the path! */
			}
			
			let fullVal: Any?
			if let firstLevelVal = firstLevelVal, let currentKey2 = currentKey2 {fullVal = string(for: currentKey2, in: firstLevelVal)}
			else                                                                {fullVal = firstLevelVal}
			
			if let fullVal = fullVal, let strVal = string(from: fullVal) {
				return strVal
			}
			
			currentKey1 = keyPathComponents[0..<i].joined(separator: ".")
			currentKey2 = keyPathComponents[i...].joined(separator: ".")
		}
		
		return nil
	}
	
	private func string(from object: Any) -> String? {
		/* Note: The original ObjC implementation of this method used stringValue
		 * on the given object to create the string value we want if the object
		 * was not a String. With Swift, this is not possible anymore!
		 *
		 * Instead we check if the object is somehow “aware” that a RESTPath might
		 * ask for its string value by checking for conformance of the
		 * RESTPathStringConvertible protocol. If it is, we simply return the
		 * given string value.
		 * If not, we check for conformance to the LosslessStringConvertible
		 * protocol and use the “description” property as a string value. We do
		 * not check the CustomStringConvertible protocol because while it gives a
		 * representation of an object, the representation often does not make
		 * sense in a REST path (eg. all ObjC object conforms to the protocol
		 * through NSObject). Even the LosslessStringConvertible protocol check is
		 * far streched TBH. */
		switch object {
		case let str           as String:                    return str
		case let str           as Substring:                 return String(str)
		case let restPathAware as RESTPathStringConvertible: return restPathAware.stringValueForRESTPath
		case let describable   as LosslessStringConvertible: return describable.description
		default:                                             return nil
		}
	}
	
}
