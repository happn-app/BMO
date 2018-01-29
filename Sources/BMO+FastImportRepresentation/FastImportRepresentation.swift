/*
 * FastImportRepresentation.swift
 * BMO+FastImportRepresentation
 *
 * Created by François Lamboley on 2/3/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation

import BMO



public struct FastImportRepresentation<DbEntityDescriptionType, DbObjectType, RelationshipUserInfoType> {
	
	public typealias RelationshipValue = (
		value: ([FastImportRepresentation<DbEntityDescriptionType, DbObjectType, RelationshipUserInfoType>], DbRepresentationRelationshipMergeType<DbEntityDescriptionType, DbObjectType>)?,
		userInfo: RelationshipUserInfoType?
	)
	
	public let entity: DbEntityDescriptionType
	
	public let uniquingId: AnyHashable?
	public let attributes: [String: Any?]
	public let relationships: [String: RelationshipValue]
	
	/** Creates an array of fast import representations from remote
	representations using the given bridge. A handler can be given to stop the
	conversion at any given time.
	
	- Important: If the `shouldContinueHandler` returns `false` at any given time
	during the conversion, the fast import representations returned will probably
	be incomplete and should be ignored.
	
	- Note: I'd like the `shouldContinueHandler` to be optional, but cannot be
	non-escaping if optional with current Swift status :( */
	public static func fastImportRepresentations<BridgeType : Bridge>(fromRemoteRepresentations remoteRepresentations: [BridgeType.RemoteObjectRepresentationType], expectedEntity entity: BridgeType.DbType.EntityDescriptionType, userInfo: BridgeType.UserInfoType, bridge: BridgeType, shouldContinueHandler: () -> Bool = {true}) -> [FastImportRepresentation<DbEntityDescriptionType, DbObjectType, RelationshipUserInfoType>]
		where DbEntityDescriptionType == BridgeType.DbType.EntityDescriptionType, DbObjectType == BridgeType.DbType.ObjectType, RelationshipUserInfoType == BridgeType.MetadataType
	{
		var fastImportRepresentations = [FastImportRepresentation<DbEntityDescriptionType, DbObjectType, RelationshipUserInfoType>]()
		for remoteRepresentation in remoteRepresentations {
			guard shouldContinueHandler() else {break}
			if let fastImportRepresentation = FastImportRepresentation(remoteRepresentation: remoteRepresentation, expectedEntity: entity, userInfo: userInfo, bridge: bridge, shouldContinueHandler: shouldContinueHandler) {
				fastImportRepresentations.append(fastImportRepresentation)
			}
		}
		return fastImportRepresentations
	}
	
	/** Creates a fast import representation from a remote representation.
	
	As this process can be long, it can be cancelled using the
	`shouldContinueHandler` block. If the block returns `false` at any given time
	during the init process, `nil` will probably be returned. If the init
	succeeds however, the returned fast-import representation is guaranteed to be
	the complete translation of the remote representation. (The init will never
	return a half-completed translation.) */
	init?<BridgeType : Bridge>(remoteRepresentation: BridgeType.RemoteObjectRepresentationType, expectedEntity: DbEntityDescriptionType, userInfo info: BridgeType.UserInfoType, bridge: BridgeType, shouldContinueHandler: () -> Bool = {true})
		where DbEntityDescriptionType == BridgeType.DbType.EntityDescriptionType, DbObjectType == BridgeType.DbType.ObjectType, RelationshipUserInfoType == BridgeType.MetadataType
	{
		guard let mixedRepresentation = bridge.mixedRepresentation(fromRemoteObjectRepresentation: remoteRepresentation, expectedEntity: expectedEntity, userInfo: info) else {return nil}
		
		var relationshipsBuilding = [String: RelationshipValue]()
		for (relationshipName, relationshipValue) in mixedRepresentation.relationships {
			guard shouldContinueHandler() else {return nil}
			guard let relationshipValue = relationshipValue else {relationshipsBuilding[relationshipName] = (value: nil, userInfo: nil); continue}
			
			let (relationshipEntity, relationshipAndMetadataRemoteRepresentations) = relationshipValue
			let subUserInfo = bridge.subUserInfo(forRelationshipNamed: relationshipName, inEntity: mixedRepresentation.entity, currentMixedRepresentation: mixedRepresentation)
			let metadata = bridge.metadata(fromRemoteRelationshipAndMetadataRepresentation: relationshipAndMetadataRemoteRepresentations, userInfo: subUserInfo)
			
			guard let relationshipRemoteRepresentations = bridge.remoteObjectRepresentations(fromRemoteRelationshipAndMetadataRepresentation: relationshipAndMetadataRemoteRepresentations, userInfo: subUserInfo) else {
				relationshipsBuilding[relationshipName] = (value: nil, userInfo: metadata)
				continue
			}
			
			relationshipsBuilding[relationshipName] = (
				value: (
					FastImportRepresentation<DbEntityDescriptionType, DbObjectType, RelationshipUserInfoType>.fastImportRepresentations(fromRemoteRepresentations: relationshipRemoteRepresentations, expectedEntity: relationshipEntity, userInfo: subUserInfo, bridge: bridge, shouldContinueHandler: shouldContinueHandler),
					bridge.relationshipMergeType(forRelationshipNamed: relationshipName, inEntity: mixedRepresentation.entity, currentMixedRepresentation: mixedRepresentation)
				),
				userInfo: metadata
			)
		}
		
		guard shouldContinueHandler() else {return nil}
		
		entity = mixedRepresentation.entity
		uniquingId = mixedRepresentation.uniquingId
		attributes = mixedRepresentation.attributes
		relationships = relationshipsBuilding
	}
	
}
