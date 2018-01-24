/*
 * ChangesDescription.swift
 * BMO
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public struct ChangesDescription<DbObjectID : Hashable> {
	
	public var objectIDsInserted = Set<DbObjectID>()
	public var objectIDsUpdated = Set<DbObjectID>()
	public var objectIDsDeleted = Set<DbObjectID>()
	
}
