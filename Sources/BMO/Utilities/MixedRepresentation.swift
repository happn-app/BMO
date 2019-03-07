/*
Copyright 2019 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

import Foundation



/** This structure is called mixed representation because the attributes are in
a local representation, but relationships are local for the key part, remote for
the value part. The request operation is in charge of resolving the recursivity
to create a DbRepresentation. */
public struct MixedRepresentation<DbEntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, BridgeUserInfoType> {
	
	public typealias RelationshipValue = (expectedEntity: DbEntityDescriptionType, value: RemoteRelationshipAndMetadataRepresentationType)?
	
	public let entity: DbEntityDescriptionType
	
	public let uniquingId: AnyHashable?
	public let attributes: [String: Any?]
	public let relationships: [String: RelationshipValue]
	
	public let userInfo: BridgeUserInfoType
	
	public init(entity e: DbEntityDescriptionType, uniquingId uid: AnyHashable?, attributes attrs: [String: Any?], relationships rels: [String: RelationshipValue], userInfo ui: BridgeUserInfoType) {
		entity = e
		uniquingId = uid
		attributes = attrs
		relationships = rels
		userInfo = ui
	}
	
}
