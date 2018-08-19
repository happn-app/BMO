/*
 * NSPredicateUtils.swift
 * happn
 *
 * Created by François Lamboley on 2/28/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import CoreData
import Foundation
import os.log

import BMO



public extension NSPredicate {
	
	/* If failForUnknownPredicate is true, the function will gather all the first
	 * level predicates it can and ignore any unknown predicates. */
	func firstLevelComparisonSubpredicates(failForUnknownPredicates: Bool, withOrCompound allowOrCompound: Bool = false, withAndCompound allowAndCompound: Bool = false) -> [NSComparisonPredicate]? {
		switch self {
		case let comparison as NSComparisonPredicate:
			return [comparison]
			
		case let compound as NSCompoundPredicate where (compound.compoundPredicateType == .or && allowOrCompound) || (compound.compoundPredicateType == .and && allowAndCompound):
			return try? compound.subpredicates.compactMap{
				guard let comparison = $0 as? NSComparisonPredicate else {
					if !failForUnknownPredicates {return nil}
					else                         {throw NSError(domain: "ignored", code: 1, userInfo: nil)}
				}
				return comparison
			}
			
		default:
			return (failForUnknownPredicates ? nil : [])
		}
	}
	
	var firstLevelComparisonSubpredicates: [NSComparisonPredicate] {
		return firstLevelComparisonSubpredicates(failForUnknownPredicates: false)!
	}
	
	func firstLevelConstants(forKeyPath keyPath: String, failForUnknownPredicates: Bool, withOrCompound allowOrCompound: Bool = true, withAndCompound allowAndCompound: Bool = false) -> [Any]? {
		var res = [Any]()
		let noUnknownPredicatesFound = enumerateFirstLevelConstants(forKeyPath: keyPath, stopAtUnknownPredicates: failForUnknownPredicates, withOrCompound: allowOrCompound, withAndCompound: allowAndCompound){
			res.append($1)
		}
		if !failForUnknownPredicates || noUnknownPredicatesFound {
			return res
		}
		return nil
	}
	
	func firstLevelConstants(forKeyPath keyPath: String, withOrCompound allowOrCompound: Bool = true, withAndCompound allowAndCompound: Bool = false) -> [Any] {
		return firstLevelConstants(forKeyPath: keyPath, failForUnknownPredicates: false, withOrCompound: allowOrCompound, withAndCompound: allowAndCompound)!
	}
	
	/** - returns: `true` if no unknown predicates have been encountered. */
	@discardableResult
	func enumerateFirstLevelConstants(forKeyPath keyPath: String?, stopAtUnknownPredicates: Bool = false, withOrCompound allowOrCompound: Bool = true, withAndCompound allowAndCompound: Bool = false, _ handler: (_ keyPath: String, _ constant: Any) -> Void) -> Bool {
		guard let subpredicates = firstLevelComparisonSubpredicates(failForUnknownPredicates: stopAtUnknownPredicates, withOrCompound: allowOrCompound, withAndCompound: allowAndCompound) else {return false}
		
		var res = true
		for predicate in subpredicates {
			switch (predicate.comparisonPredicateModifier, predicate.predicateOperatorType, predicate.leftExpression.expressionType, predicate.rightExpression.expressionType) {
			case (.direct, .in, .keyPath, .constantValue):
				guard keyPath == nil || predicate.leftExpression.keyPath == keyPath else {
					if stopAtUnknownPredicates {return false}
					else                       {res = false; continue}
				}
				/* We got a "keyPath IN object" predicate! */
				switch predicate.rightExpression.constantValue {
				case let a as [Any]:            for e in a {handler(predicate.leftExpression.keyPath, e)}
				case let s as Set<AnyHashable>: for e in s {handler(predicate.leftExpression.keyPath, e)}
				default:
					if stopAtUnknownPredicates {return false}
					else                       {res = false; continue}
				}
				
			case (.direct, .contains, .constantValue, .keyPath):
				guard keyPath == nil || predicate.rightExpression.keyPath == keyPath else {
					if stopAtUnknownPredicates {return false}
					else                       {res = false; continue}
				}
				/* We got a "object CONTAINS keyPath" predicate! */
				switch predicate.leftExpression.constantValue {
				case let a as [Any]:            for e in a {handler(predicate.rightExpression.keyPath, e)}
				case let s as Set<AnyHashable>: for e in s {handler(predicate.rightExpression.keyPath, e)}
				default:
					if stopAtUnknownPredicates {return false}
					else                       {res = false; continue}
				}
				
			case (.direct, .equalTo, _, _):
				guard let kp = predicate.keyPathExpression?.keyPath, (keyPath == nil || kp == keyPath) else {
					if stopAtUnknownPredicates {return false}
					else                       {res = false; continue}
				}
				/* We got a "keyPath == constant" predicate! */
				if let c = predicate.constantValueExpression?.constantValue {handler(kp, c)}
				
			default:
				if stopAtUnknownPredicates {return false}
				else                       {res = false; continue}
			}
		}
		return res
	}
	
	func predicateByAddingKeyPathPrefix(_ keyPathPrefix: String) -> NSPredicate {
		switch self {
		case let comparisonPredicate as NSComparisonPredicate:
			return NSComparisonPredicate(
				leftExpression: comparisonPredicate.leftExpression.expressionByAddingKeyPathPrefix(keyPathPrefix),
				rightExpression: comparisonPredicate.rightExpression.expressionByAddingKeyPathPrefix(keyPathPrefix),
				modifier: comparisonPredicate.comparisonPredicateModifier, type: comparisonPredicate.predicateOperatorType, options: comparisonPredicate.options
			)
			
		case let compoundPredicate as NSCompoundPredicate:
			return NSCompoundPredicate(
				type: compoundPredicate.compoundPredicateType,
				subpredicates: compoundPredicate.subpredicates.compactMap{ ($0 as? NSPredicate)?.predicateByAddingKeyPathPrefix(keyPathPrefix) }
			)
			
		default: fatalError("Unknown predicate type to form sub-query predicate for \(self)")
		}
	}
	
}



public extension NSComparisonPredicate {
	
	var keyPathExpression: NSExpression? {
		if leftExpression.expressionType  == .keyPath {return leftExpression}
		if rightExpression.expressionType == .keyPath {return rightExpression}
		return nil
	}
	
	var constantValueExpression: NSExpression? {
		if leftExpression.expressionType  == .constantValue {return leftExpression}
		if rightExpression.expressionType == .constantValue {return rightExpression}
		return nil
	}
	
}



public extension NSExpression {
	
	func expressionByAddingKeyPathPrefix(_ keyPathPrefix: String) -> NSExpression {
		switch expressionType {
		case .constantValue, .variable, .anyKey:
			return copy() as! NSExpression
			
		case .evaluatedObject:
			return NSExpression(forKeyPath: keyPathPrefix)
			
		case .keyPath:
			return NSExpression(forKeyPath: keyPathPrefix + "." + keyPath)
			
		case .function:
			if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {BMO.di.log.flatMap{ os_log("Adding a key path prefix to a function expression might result to a flawed NSExpression or unexpected results.", log: $0, type: .info) }}
			else                                                          {NSLog("Adding a key path prefix to a function expression might result to a flawed NSExpression or unexpected results.")}
			return NSExpression(forFunction: operand.expressionByAddingKeyPathPrefix(keyPathPrefix), selectorName: function, arguments: arguments /* We do not transform arguments. Should we? I don't know. */)
			
		case .unionSet:
			return NSExpression(forUnionSet: left.expressionByAddingKeyPathPrefix(keyPathPrefix), with: right.expressionByAddingKeyPathPrefix(keyPathPrefix))
			
		case .intersectSet:
			return NSExpression(forIntersectSet: left.expressionByAddingKeyPathPrefix(keyPathPrefix), with: right.expressionByAddingKeyPathPrefix(keyPathPrefix))
			
		case .minusSet:
			return NSExpression(forMinusSet: left.expressionByAddingKeyPathPrefix(keyPathPrefix), with: right.expressionByAddingKeyPathPrefix(keyPathPrefix))
			
		case .subquery:
			if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {BMO.di.log.flatMap{ os_log("Adding a key path prefix to a sub-query expression might result to a flawed NSExpression or unexpected results.", log: $0, type: .info) }}
			else                                                          {NSLog("Adding a key path prefix to a sub-query expression might result to a flawed NSExpression or unexpected results.")}
			switch collection {
			case let str as String:        return NSExpression(forSubquery: NSExpression(forKeyPath: keyPathPrefix + "." + str), usingIteratorVariable: variable, predicate: predicate)
			case let expr as NSExpression: return NSExpression(forSubquery: expr.expressionByAddingKeyPathPrefix(keyPathPrefix), usingIteratorVariable: variable, predicate: predicate)
			default:
				if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {BMO.di.log.flatMap{ os_log("Unknown collection %@ for sub-query expression %@ when adding key path prefix \"%@\". Returning original expression.", log: $0, type: .error, String(describing: collection), self, keyPathPrefix) }}
				else                                                          {NSLog("Unknown collection %@ for sub-query expression %@ when adding key path prefix \"%@\". Returning original expression.", String(describing: collection), self, keyPathPrefix)}
				return copy() as! NSExpression
			}
			
		case .aggregate:
			if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {BMO.di.log.flatMap{ os_log("Adding a key path prefix to an aggregate expression might result to a flawed NSExpression or unexpected results.", log: $0, type: .info) }}
			else                                                          {NSLog("Adding a key path prefix to an aggregate expression might result to a flawed NSExpression or unexpected results.")}
			/* Note: For all maps below, we “flat” map instead of simply mapping to
			         be sure to have NSExpression. In theory it shouldn't be
			         possible for the collection to contain something else than
			         NSExpressions, but we never know! */
			switch collection {
			case let exprs as [Any]:            return NSExpression(forAggregate: exprs.compactMap{ ($0 as? NSExpression)?.expressionByAddingKeyPathPrefix(keyPathPrefix) ?? nil })
			case let exprs as Set<AnyHashable>: return NSExpression(forAggregate: exprs.compactMap{ ($0 as? NSExpression)?.expressionByAddingKeyPathPrefix(keyPathPrefix) ?? nil })
			case let exprs as [AnyHashable: Any]:
				if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {BMO.di.log.flatMap{ os_log("Doc says we can initialize an aggregate expression with a dictionary, but method signature says otherwise... Returning an aggregate expression with a collection being the values of the original collection (prefixed by added prefix).", log: $0, type: .info) }}
				else                                                          {NSLog("Doc says we can initialize an aggregate expression with a dictionary, but method signature says otherwise... Returning an aggregate expression with a collection being the values of the original collection (prefixed by added prefix).")}
				return NSExpression(forAggregate: exprs.values.compactMap{ ($0 as? NSExpression)?.expressionByAddingKeyPathPrefix(keyPathPrefix) ?? nil })
				
			default:
				if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {BMO.di.log.flatMap{ os_log("Unknown collection %@ for aggregate expression %@ when adding key path prefix \"%@\". Returning original expression.", log: $0, type: .error, String(describing: collection), self, keyPathPrefix) }}
				else                                                          {NSLog("Unknown collection %@ for aggregate expression %@ when adding key path prefix \"%@\". Returning original expression.", String(describing: collection), self, keyPathPrefix)}
				return copy() as! NSExpression
			}
			
		case .block:
			if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {BMO.di.log.flatMap{ os_log("Adding a key path prefix to a block expression might result to a flawed NSExpression or unexpected results.", log: $0, type: .info) }}
			else                                                          {NSLog("Adding a key path prefix to a block expression might result to a flawed NSExpression or unexpected results.")}
			return NSExpression(block: expressionBlock, arguments: arguments?.map{ $0.expressionByAddingKeyPathPrefix(keyPathPrefix) })
			
		case .conditional:
			/* Not sure what a conditional expression is... */
			guard #available(OSX 10.11, iOS 9.0, *) else {fatalError("Conditional expression shouldn't be available on this OS version!")}
			if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {BMO.di.log.flatMap{ os_log("Adding a key path prefix to a conditional expression might result to a flawed NSExpression or unexpected results.", log: $0, type: .info) }}
			else                                                          {NSLog("Adding a key path prefix to a conditional expression might result to a flawed NSExpression or unexpected results.")}
			return NSExpression(forConditional: predicate.predicateByAddingKeyPathPrefix(keyPathPrefix), trueExpression: `true`.expressionByAddingKeyPathPrefix(keyPathPrefix), falseExpression: `false`.expressionByAddingKeyPathPrefix(keyPathPrefix))
		}
	}
	
}
