/*
 * CoreDataUtils.swift
 * BMO+RESTCoreData
 *
 * Created by François Lamboley on 1/30/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData

import RESTUtils



/* Ideally this extension should be uncommented here and clients that link to
 * BMO_RESTCoreData would benefit from it directly.
 * I tried, it does not seem to work! (Xcode 9.2, (9C40b), default Swift
 * toolchain)
 * Instead, clients will have to put this extension is their code...
 * Note: If the extension is not commented here, clients won't be able to put it
 *       in their code as compiler will complain about redeclaring protocol
 *       conformance for NSManagedObject! */
//extension NSManagedObject : RESTPathKeyResovable {
//
//	public func restPathObject(for key: String) -> Any? {
//		guard entity.propertiesByName.keys.contains(key) else {return nil}
//		return value(forKey: key)
//	}
//
//}
