/*
 * ParameterizedStringSetParser.swift
 * RESTUtils
 *
 * Created by François Lamboley on 1/30/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public protocol ParameterizedStringSetParser {
	
	func parse(flatifiedParam: String) throws -> ParameterizedStringSet
	func flatify(param: ParameterizedStringSet) -> String
	
}
