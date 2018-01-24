/*
 * UniquingRequest.swift
 * BMO
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



/** This is used to insert objects in the local Db, with uniquing.

If the object is already in the Db (in regard to the uniquing given by the db),
the already inserted object will be updated. In this case, the object given in
argument to this enum case will be deleted.

- warning: Not corresponding operation implemented yet */
public struct UniquingRequest<DbType : Db> {
	
	let db: DbType
	
	let object: DbType.ObjectType
	
}
