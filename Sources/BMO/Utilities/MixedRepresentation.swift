/*
 * MixedRepresentation.swift
 * BMO
 *
 * Created by François Lamboley on 3/5/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation



/** Same structure as FastImportRepresentation, except relationships values are
an array of (expectedEntity, remote representation and metadata) instead of a
simple FastImportRepresentation.

This structure is called mixed representation because the attributes are in a
local representation, but relationships are local for the key part, remote for
the value part. The request operation is in charge of resolving the recursivity
to create a FastImportRepresentation. */
public struct MixedRepresentation<DbEntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, BridgeUserInfoType> {
	
	public typealias RelationshipValue = (expectedEntity: DbEntityDescriptionType, value: RemoteRelationshipAndMetadataRepresentationType)?
	
	public let entity: DbEntityDescriptionType
	
	public let uniquingId: AnyHashable?
	public let attributes: [String: Any?]
	public let relationships: [String: RelationshipValue]
	
	public let userInfo: BridgeUserInfoType
	
}
