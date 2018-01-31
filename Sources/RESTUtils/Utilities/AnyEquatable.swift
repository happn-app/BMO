/*
 * AnyEquatable.swift
 * RESTUtils
 *
 * Created by François Lamboley on 2/16/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation



/* Type erasure for Equatable. */
public struct AnyEquatable : Equatable {
	
	private let base: Any
	private let equals: (Any) -> Bool
	
	public init<E : Equatable>(_ v: E) {
		base = v
		equals = {
			guard let t = $0 as? E else {return false}
			return t == v
		}
	}
	
	public static func ==(_ lhs: AnyEquatable, _ rhs: AnyEquatable) -> Bool {
		return lhs.equals(rhs.base)
	}
	
	public static func ==(_ lhs: AnyEquatable, _ rhs: Any) -> Bool {
		return lhs.equals(rhs)
	}
	
	public static func ==(_ lhs: Any, _ rhs: AnyEquatable) -> Bool {
		return rhs.equals(lhs)
	}
	
}
