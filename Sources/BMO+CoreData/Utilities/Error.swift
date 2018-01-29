/*
 * Error.swift
 * BMO+CoreData
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public enum Error : Swift.Error {
	
	case tooManyRepresentationsToUpdateObject
	case updatedObjectAndRepresentedObjectEntitiesDoNotMatch
	
}
