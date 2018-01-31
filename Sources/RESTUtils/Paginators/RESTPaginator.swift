/*
 * RESTPaginator.swift
 * RESTUtils
 *
 * Created by Thomas Levy on 24/09/15.
 * Copyright © 2015 happn. All rights reserved.
 */

import CoreData
import Foundation



public protocol RESTPaginator {
	
	func paginationParams(withPaginatorInfo: Any?) -> [String: String]?
	
}
