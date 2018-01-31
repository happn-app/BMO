/*
 * RESTPathProtocols.swift
 * RESTUtils
 *
 * Created by François Lamboley on 1/28/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public protocol RESTPathStringConvertible {
	
	var stringValueForRESTPath: String {get}
	
}


public protocol RESTPathKeyResovable {
	
	func restPathObject(for key: String) -> Any?
	
}
