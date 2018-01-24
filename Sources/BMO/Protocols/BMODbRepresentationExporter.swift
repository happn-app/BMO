/*
 * BMODbRepresentationExporter.swift
 * BMO
 *
 * Created by François Lamboley on 5/23/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation



public protocol BMODbRepresentationExporter {
	
	associatedtype DbType : BMODb
	associatedtype DbRepresentationType
	
	init(unsafeObjects: [DbType.ObjectType])
	
	/* The number of returned objects might not be equal to the number of objects
	 * given in input (eg. the same object has been given twice in input, no need
	 * to put it twice in the results). */
	func unsafeExport(from db: DbType) throws -> [DbRepresentationType]
	
}
