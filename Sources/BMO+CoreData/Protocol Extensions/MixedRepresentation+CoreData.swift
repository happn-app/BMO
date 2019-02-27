/*
 * MixedRepresentation+CoreData.swift
 * BMO+CoreData
 *
 * Created by François Lamboley on 1/29/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import CoreData
import Foundation

import BMO



extension MixedRepresentation where DbEntityDescriptionType == NSEntityDescription {
	
	public init(entity e: DbEntityDescriptionType, uniquingId uid: AnyHashable?, mixedRepresentationDictionary: [String: Any?], userInfo info: BridgeUserInfoType, relationshipAndMetadataValuePreprocessor handler: (_ relationship: NSRelationshipDescription, _ value: Any??) -> RemoteRelationshipAndMetadataRepresentationType?? = {
		guard let relationshipValue = $1 else {return nil}
		return relationshipValue as? RemoteRelationshipAndMetadataRepresentationType?
	}) {
		self.init(entity: e, uniquingId: uid, mixedRepresentationDictionary: mixedRepresentationDictionary, userInfo: info, relationshipAndMetadataValuePreprocessorNoDefault: handler)
	}
	
	/* Note: Did not find a better way to have a default handler (Xcode 8E2002).
	 * Tried with default handler being a static var of the extension (static var
	 * not supported in extensions) or being a static var of a separate generic
	 * class with an extension when generic is a specific type, but neither
	 * worked.
	 * Also tried a solution where the default handler is a generic private
	 * function, with a specific implementation for a given type. */
	fileprivate init(entity e: DbEntityDescriptionType, uniquingId uid: AnyHashable?, mixedRepresentationDictionary: [String: Any?], userInfo info: BridgeUserInfoType, relationshipAndMetadataValuePreprocessorNoDefault handler: (_ relationship: NSRelationshipDescription, _ value: Any??) -> RemoteRelationshipAndMetadataRepresentationType??) {
		var attrs = [String: Any?]()
		for attributeName in e.attributesByName.keys /* Includes superentities attributes */ {
			guard let v = mixedRepresentationDictionary[attributeName] else {continue}
			attrs[attributeName] = .some(v)
		}
		
		var relationships = [String: RelationshipValue]()
		for (relationshipName, relationship) in e.relationshipsByName {
			guard let v = handler(relationship, mixedRepresentationDictionary[relationshipName]) else {continue}
			relationships[relationshipName] = .some(v.map{ (expectedEntity: relationship.destinationEntity!, value: $0) })
		}
		
		self.init(entity: e, uniquingId: uid, attributes: attrs, relationships: relationships, userInfo: info)
	}
	
}


extension MixedRepresentation where DbEntityDescriptionType == NSEntityDescription, RemoteRelationshipAndMetadataRepresentationType == [[String: Any?]] {
	
	public init(entity e: DbEntityDescriptionType, uniquingId uid: AnyHashable?, mixedRepresentationDictionary: [String: Any?], userInfo info: BridgeUserInfoType, relationshipAndMetadataValuePreprocessor handler: (_ relationship: NSRelationshipDescription, _ value: Any??) -> RemoteRelationshipAndMetadataRepresentationType?? = {
		/* In this usual case where the remote relationship representation is an
		 * array of dictionary, we handle the case where the relationship value is
		 * a simple dictionary and wraps it in an array. */
		guard let relationshipValue = $1 else {return nil}
		switch relationshipValue {
		case .none:                         return .some(nil)
		case let dic   as  [String: Any?]:  return [dic]
		case let array	as [[String: Any?]]: return array
		default:                            return nil
		}
	}) {
		self.init(entity: e, uniquingId: uid, mixedRepresentationDictionary: mixedRepresentationDictionary, userInfo: info, relationshipAndMetadataValuePreprocessorNoDefault: handler)
	}
	
}
