/*
 * ParameterizedStringSet.swift
 * RESTUtils
 *
 * Created by François Lamboley on 2/24/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation



/** Useful mainly for the "fields" query param of a REST request. */
public struct ParameterizedStringSet {
	
	public var valuesAndParams: [String: [String: ParameterizedStringSet]]
	
	init() {
		valuesAndParams = [:]
	}
	
	init(simpleValue: String) {
		valuesAndParams = [simpleValue: [:]]
	}
	
	init<S : Sequence>(simpleSequence: S) where S.Iterator.Element == String {
		valuesAndParams = [:]
		for v in simpleSequence {valuesAndParams[v] = [:]}
	}
	
	init(valuesAndParams vp: [String: [String: ParameterizedStringSet]]) {
		valuesAndParams = vp
	}
	
	var isEmpty: Bool {
		return valuesAndParams.count == 0
	}
	
	var isSimple: Bool {
		return valuesAndParams.count == 1 && valuesAndParams.values.first!.count == 0
	}
	
	var values: Set<String> {
		return Set(valuesAndParams.keys)
	}
	
	func hasValue(_ value: String) -> Bool {
		if let _ = valuesAndParams[value] {return true}
		return false
	}
	
	/* Returns nil if value is not in set */
	func params(forValue value: String) -> [String: ParameterizedStringSet]? {
		return valuesAndParams[value]
	}
	
	mutating func insert(_ value: String) {
		guard valuesAndParams[value] == nil else {return}
		valuesAndParams[value] = [:]
	}
	
	mutating func insert<S : Sequence>(_ values: S) where S.Iterator.Element == String {
		for v in values {insert(v)}
	}
	
	/** Inserts the given value with the given params if not in set. If the value
	was already in the set, updates the params for the given value. */
	mutating func add(simpleParams: [String: String], forValue value: String) {
		var currentParams = valuesAndParams[value] ?? [:]
		for (k, v) in simpleParams {currentParams[k] = ParameterizedStringSet(simpleValue: v)}
		valuesAndParams[value] = currentParams
	}
	
	mutating func merge(_ otherSet: ParameterizedStringSet) {
		for (value, params) in otherSet.valuesAndParams {
			merge(params: params, forValue: value)
		}
	}
	
	mutating func merge(params: [String: ParameterizedStringSet], forValue value: String) {
		var updatedParams = valuesAndParams[value] ?? [:]
		for (k, v) in params {
			var newV = updatedParams[k] ?? ParameterizedStringSet()
			newV.merge(v)
			
			updatedParams[k] = newV
		}
		valuesAndParams[value] = updatedParams
	}
	
	mutating func set(params: [String: ParameterizedStringSet], forValue value: String) {
		valuesAndParams[value] = params
	}
	
	func inserting<S : Sequence>(_ values: S) -> ParameterizedStringSet where S.Iterator.Element == String {
		var ret = self
		for v in values {ret.insert(v)}
		return ret
	}
	
	/* TODO: Force certain values to have only one parameter in their parameters */
	func merged(_ otherSet: ParameterizedStringSet) -> ParameterizedStringSet {
		var ret = self
		ret.merge(otherSet)
		return ret
	}
	
	/** If merge fails (unknown type given to merge), returns self unmodified. */
	func merged(_ newValue: Any?, pssParser: ParameterizedStringSetParser) -> ParameterizedStringSet {
		guard let newPSS = ParameterizedStringSet.fromAny(newValue, withPSSParser: pssParser) else {return self}
		return merged(newPSS)
	}
	
	static func fromAny(_ newValue: Any?, withPSSParser pssParser: ParameterizedStringSetParser) -> ParameterizedStringSet? {
		guard let newValue = newValue else {return ParameterizedStringSet()}
		
		switch newValue {
		case let pss as ParameterizedStringSet: return pss
		case let set as Set<String>:            return ParameterizedStringSet(simpleSequence: set)
		case let array as [String]:             return ParameterizedStringSet(simpleSequence: array)
		case let string as String:              return ((try? pssParser.parse(flatifiedParam: string)) ?? ParameterizedStringSet(simpleValue: string))
		case let int as Int:                    return ParameterizedStringSet(simpleValue: String(int))
		default: return nil
		}
	}
	
}
