/*
 * BMOBridge.swift
 * BMO
 *
 * Created by François Lamboley on 1/30/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation



public protocol BMOBridge {
	
	associatedtype DbType : BMODb
	associatedtype AdditionalDbRequestInfoType
	
	/** An internal type you can use for basically whatever you want. For
	instance if you need information about the original request when converting
	from remote object representation to mixed representation, you can use this
	type. */
	associatedtype UserInfoType
	
	/** A type to store "relationship" or "root" metadata. Whenever you need to
	store information for the caller that is not part of the model (eg. next or
	previous page info), you can use the metadata.
	
	There are no object or attributes metadata; you'll have to store those (if
	any) directly in your model, possibly in transient properties. */
	associatedtype MetadataType
	
	/* Typically [String: Any] (the type of a JSON object) */
	associatedtype RemoteObjectRepresentationType
	/* Some APIs (eg. Facebook's) give both a data and a metadata field in their
	 * relationship values. For other APIs, this type will probably simply be an
	 * array of RemoteObjectRepresentationType. */
	associatedtype RemoteRelationshipAndMetadataRepresentationType
	
	associatedtype BackOperationType : Operation
	
	func createUserInfoObject() -> UserInfoType
	
	/* Bridging -- Front end => Back end. Called on the correct db context. */
	
	func expectedResultEntity(forFetchRequest fetchRequest: DbType.FetchRequestType, additionalInfo: AdditionalDbRequestInfoType?) -> DbType.EntityDescriptionType?
	func expectedResultEntity(forObject object: DbType.ObjectType) -> DbType.EntityDescriptionType?
	
	func backOperation(forFetchRequest fetchRequest: DbType.FetchRequestType, additionalInfo: AdditionalDbRequestInfoType?, userInfo: inout UserInfoType) throws -> BackOperationType?
	
	func backOperation(forInsertedObject insertedObject: DbType.ObjectType, additionalInfo: AdditionalDbRequestInfoType?, userInfo: inout UserInfoType) throws -> BackOperationType?
	func backOperation(forUpdatedObject updatedObject: DbType.ObjectType, additionalInfo: AdditionalDbRequestInfoType?, userInfo: inout UserInfoType) throws -> BackOperationType?
	func backOperation(forDeletedObject deletedObject: DbType.ObjectType, additionalInfo: AdditionalDbRequestInfoType?, userInfo: inout UserInfoType) throws -> BackOperationType?
	
	/* Bridging -- Back end => Front end. NOT called on a db context. If you need to be on a db context you're probably doing it wrong... */
	
	/** Called when the back operation is finished, for requests who do not want
	the operation results to be imported in the db. Return `nil` if the operation
	was successful. */
	func error(fromFinishedOperation operation: BackOperationType) -> Error?
	
	func userInfo(fromFinishedOperation operation: BackOperationType, currentUserInfo: UserInfoType) -> UserInfoType
	
	/** Return here info that can be of use for the client but do not need to be
	saved in the model.
	
	Eg. The paginator info for getting the next page do not always have to be
	saved in the model as usually when the app relaunches we load the pages from
	the first one. To simplify the model, you can use metadata to return the
	paginator info for the next page without saving them in the model. */
	func bridgeMetadata(fromFinishedOperation operation: BackOperationType, userInfo: UserInfoType) -> MetadataType?
	
	/** This method should extract the remote representation of the retrieved
	objects from the finished back operation. For each remote representation
	returned, the bridge will be called to extract the attributes and
	relationships for the object.
	
	Return nil if the results should not be imported at all. */
	func remoteObjectRepresentations(fromFinishedOperation operation: BackOperationType, userInfo: UserInfoType) throws -> [RemoteObjectRepresentationType]?
	
	func mixedRepresentation(fromRemoteObjectRepresentation remoteRepresentation: RemoteObjectRepresentationType, expectedEntity: DbType.EntityDescriptionType, userInfo: UserInfoType) -> BMOMixedRepresentation<DbType.EntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, UserInfoType>?
	
	func subUserInfo(forRelationshipNamed relationshipName: String, inEntity entity: DbType.EntityDescriptionType, currentMixedRepresentation: BMOMixedRepresentation<DbType.EntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, UserInfoType>) -> UserInfoType
	func metadata(fromRemoteRelationshipAndMetadataRepresentation remoteRelationshipAndMetadataRepresentation: RemoteRelationshipAndMetadataRepresentationType, userInfo: UserInfoType) -> MetadataType?
	func remoteObjectRepresentations(fromRemoteRelationshipAndMetadataRepresentation remoteRelationshipAndMetadataRepresentation: RemoteRelationshipAndMetadataRepresentationType, userInfo: UserInfoType) -> [RemoteObjectRepresentationType]?
	
	/* If not implemented, defaults to .replace */
	func relationshipMergeType(forRelationshipNamed relationshipName: String, inEntity entity: DbType.EntityDescriptionType, currentMixedRepresentation: BMOMixedRepresentation<DbType.EntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, UserInfoType>) -> BMODbRepresentationRelationshipMergeType<DbType.EntityDescriptionType, DbType.ObjectType>
	
}

public enum BMODbRepresentationRelationshipMergeType<DbEntityDescriptionType, DbObjectType> {
	
	case replace
	case append
	case insertAtBeginning
	case custom(mergeHandler: (_ object: DbObjectType, _ relationshipName: String, _ values: [DbObjectType]) -> Void)
	
	public var isReplace: Bool {
		switch self {
		case .replace: return true
		default:       return false
		}
	}
	
}
