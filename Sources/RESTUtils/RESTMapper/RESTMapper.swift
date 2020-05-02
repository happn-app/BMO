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

import CoreData
import Foundation
import os.log



public class RESTMapper<DbEntityDescription : DbRESTEntityDescription & Hashable, DbPropertyDescription : DbRESTPropertyDescription & Hashable> {
	
	let restMapping: RESTMapping<DbEntityDescription, DbPropertyDescription>
	
	init(restMapping mapping: RESTMapping<DbEntityDescription, DbPropertyDescription>) {
		restMapping = mapping
	}
	
	public func restPath(forEntity entity: DbEntityDescription) -> RESTPath? {
		if let r = restMapping.entitiesMapping[entity]?.restPath {return r}
		if let s = entity.superentity {return restPath(forEntity: s as! DbEntityDescription /* See comment about SubSuperEntityType in DbRESTEntityDescription for explanation of the "as!" */)}
		return nil
	}
	
	public func parameters(fromAdditionalRESTInfo additionalRESTInfo: AdditionalRESTRequestInfo<DbPropertyDescription>?, forEntity entity: DbEntityDescription, forcedPagniator: RESTPaginator? = nil) -> [String: Any] {
		var params = _parameters(fromAdditionalRESTInfo: additionalRESTInfo, forEntity: entity, firstLevel: true, forcedPaginator: forcedPagniator)
		for (k, v) in params {
			/* We assume we won't have a ParameterizedStringSet in a sub-param. */
			if let v = v as? ParameterizedStringSet {
				params[k] = restMapping.queryParamParser.flatify(param: v)
			}
		}
		return params
	}
	
	public func uniquingId(forLocalRepresentation localRepresentation: [String: Any?], ofEntity entity: DbEntityDescription) -> String? {
		switch restMapping.entityUniquingType(forEntity: entity) {
		case .none:                                               return nil
		case .singleton(let v):                                   return v
		case .custom(let h):                                      return h(localRepresentation)
		case .onProperty(constantPrefix: let c, property: let p): return localRepresentation[p.name].flatMap{ $0.flatMap{ (c ?? "") + String(describing: $0) } }
		}
	}
	
	public func actualLocalEntity(forRESTRepresentation restRepresentation: [String: Any?], expectedEntity: DbEntityDescription, canUseSuperentities: Bool = true) -> DbEntityDescription? {
		var visitedEntities = Set<DbEntityDescription>()
		return actualLocalEntity(forRESTRepresentation: restRepresentation, expectedEntity: expectedEntity, canUseSuperentities: canUseSuperentities, visitedEntities: &visitedEntities)
	}
	
	/* The user info is passthrough'd to the transformer/handler if it needs it.
	 * It is never used by the method directly. */
	public func mixedRepresentation(ofEntity entity: DbEntityDescription, fromRESTRepresentation restRepresentation: [String: Any?], userInfo: Any?) -> [String: Any?] {
		var result = [String: Any?]()
		var entity: DbEntityDescription? = entity
		while let currentEntity = entity {
			defer {entity = currentEntity.superentity.flatMap{ ($0 as! DbEntityDescription) }}
			guard let mapping = restMapping.entitiesMapping[currentEntity] else {continue}
			
			for (property, mapping) in mapping.propertiesMapping {
				let newValue: Any??
				
				switch mapping.restToLocalMapping {
				case .skipped: continue
					
				case .constant(let c):
					newValue = .some(c)
					
				case .propertyMapping(sourcePropertyPath: let sourcePropertyPath):
					guard let objcNewValue = value(forKeyPath: sourcePropertyPath, inRepresentation: restRepresentation) else {continue}
					
					/* nil is the new NSNull */
					if objcNewValue is NSNull {newValue = .some(nil)}
					else                      {newValue = objcNewValue}
					
				case .propertyTransformerMapping(sourcePropertyPath: let sourcePropertyPath, transformer: let restMapperTransformer):
					guard let restValue = value(forKeyPath: sourcePropertyPath, inRepresentation: restRepresentation) else {continue}
					newValue = restMapperTransformer.applyTransform(sourceValue: restValue, userInfo: userInfo)
					
				case .objectTransformerMapping(transformer: let restMapperTransformer):
					newValue = restMapperTransformer.applyTransform(sourceValue: restRepresentation, userInfo: userInfo)
					
				case .propertyHandlerMapping(sourcePropertyPath: let sourcePropertyPath, transformer: let transformerHandler):
					guard let restValueObjC = value(forKeyPath: sourcePropertyPath, inRepresentation: restRepresentation) else {continue}
					
					/* nil is the new NSNull */
					let restValue: Any? = (restValueObjC is NSNull ? nil : restValueObjC)
					newValue = transformerHandler(restValue, userInfo)
					
				case .objectHandlerMapping(transformer: let transformerHandler):
					newValue = transformerHandler(restRepresentation, userInfo)
				}
				
				if let newValue = newValue {
					if let propertyValueType = property.valueType, let newValue = newValue {
						/* Checking new value type. */
						if (newValue as AnyObject).isKind(of: propertyValueType) {
							result[property.name] = newValue
						} else {
							if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Got new value %@ of type %{public}@ for property %{public}@. Expecting %{public}@. Skipping value.", log: $0, type: .info, String(describing: newValue), String(describing: type(of: newValue)), String(describing: property), String(describing: propertyValueType)) }}
							else                                                          {NSLog("Got new value %@ of type %@ for property %@. Expecting %@. Skipping value.", String(describing: newValue), String(describing: type(of: newValue)), String(describing: property), String(describing: propertyValueType))}
						}
					} else {
						/* No type checking; setting value directly. */
						result[property.name] = newValue
					}
				}
			}
		}
		return result
	}
	
	/* The user info is passthrough'd to the transformer/handler if it needs it.
	 * It is never used by the method directly. */
	public func restRepresentation(ofEntity entity: DbEntityDescription, fromLocalRepresentation localRepresentation: [String: Any?], userInfo: Any?, didMapProperties: inout Bool) -> [String: Any?] {
		didMapProperties = false
		
		var result = [String: Any?]()
		var forcedValues = [String: Any?]()
		var entity: DbEntityDescription? = entity
		while let currentEntity = entity {
			defer {entity = currentEntity.superentity.flatMap{ ($0 as! DbEntityDescription) }}
			guard let mapping = restMapping.entitiesMapping[currentEntity] else {continue}
			
			for (key, mapping) in mapping.propertiesMapping {
				guard let value = localRepresentation[key.name] else {continue}
				let newValues: [String: Any?]
				
				switch mapping.localToRESTMapping {
				case .skipped: continue
					
				case .propertyMapping(destinationPropertyPath: let destinationPropertyPath):
					var newValuesBuilding = value
					for curKey in destinationPropertyPath.reversed() {newValuesBuilding = [curKey: newValuesBuilding]}
					newValues = (newValuesBuilding as! [String: Any?]) /* Internal logic error if cast is not true */
					
				case .propertyTransformerMapping(destinationPropertyPath: let destinationPropertyPath, transformer: let restMapperTransformer):
					guard let newValue = restMapperTransformer.applyTransform(sourceValue: value, userInfo: userInfo) else {continue}
					
					var newValuesBuilding = newValue
					for curKey in destinationPropertyPath.reversed() {newValuesBuilding = [curKey: newValuesBuilding]}
					newValues = (newValuesBuilding as! [String: Any?]) /* Internal logic error if cast is not true */
					
				case .objectTransformerMapping(transformer: let restMapperTransformer):
					guard let newValuesObjC = restMapperTransformer.applyTransform(sourceValue: value, userInfo: userInfo) as? [String: Any?] else {continue}
					
					var newValuesBuilding = [String: Any?]()
					for (key, val) in newValuesObjC {newValuesBuilding[key] = (val is NSNull ? Optional<Any>.none : val)}
					newValues = newValuesBuilding
					
				case .propertyHandlerMapping(destinationPropertyPath: let destinationPropertyPath, transformer: let handlerTransformer):
					guard let newValue = handlerTransformer(value, userInfo) else {continue}
					
					var newValuesBuilding = newValue
					for curKey in destinationPropertyPath.reversed() {newValuesBuilding = [curKey: newValuesBuilding]}
					newValues = (newValuesBuilding as! [String: Any?]) /* Internal logic error if cast is not true */
					
				case .objectHandlerMapping(transformer: let handlerTransformer):
					guard let newComputedValues = handlerTransformer(value, userInfo) else {continue}
					newValues = newComputedValues
					
				case .objectToObjectHandlerMapping(transformer: let handlerTransformer):
					guard let newComputedValues = handlerTransformer(localRepresentation, userInfo) else {continue}
					newValues = newComputedValues
				}
				
				/* Merging the new values with the current rest representation */
				merge(restRepresentation: &result, newValues: newValues)
				didMapProperties = true
			}
			/* Adding forced values for current entity to the current forcedValues.
			 * Note: We do not overwrite current forced values: The forced values
			 *       of the lowest entity in the hierarchy prime over the others. */
			for (k, v) in mapping.forcedValuesOnSave {
				guard forcedValues[k] == nil else {continue}
				forcedValues[k] = v
			}
		}
		
		/* Adding forced values for global mapping to the current forcedValues.
		 * Note: We do not overwrite current forced values: The previous forced
		 *       values prime over the others. */
		for (k, v) in restMapping.forcedValuesOnSave {
			guard forcedValues[k] == nil else {continue}
			forcedValues[k] = v
		}
		
		/* Adding forced values to the result. The forced values overwrite values
		 * in the result. */
		merge(restRepresentation: &result, newValues: forcedValues)
		return result
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private func actualLocalEntity(forRESTRepresentation restRepresentation: [String: Any?], expectedEntity: DbEntityDescription, canUseSuperentities: Bool, visitedEntities: inout Set<DbEntityDescription>) -> DbEntityDescription? {
		guard !visitedEntities.contains(expectedEntity) else {return nil}
		do {
			let noMatchError = NSError(domain: "_internal_ (no match; ignored)", code: 1, userInfo: nil)
			guard let representationDescription = restMapping.entitiesMapping[expectedEntity]?.restEntityDescription else {
				guard visitedEntities.count == 0 else {throw noMatchError}
				return expectedEntity
			}
			
			switch representationDescription {
			case .abstract: throw noMatchError
			case .noSpecificities: (/*nop: Anything matches*/)
			case .hasProperties(let p):          guard Set(restRepresentation.keys).isSuperset(of: p)   else {throw noMatchError}
			case .doesNotHaveProperties(let p):  guard Set(restRepresentation.keys).isDisjoint(with: p) else {throw noMatchError}
			case .matchesProperties(let p):      for (k, v) in p {guard let tO = restRepresentation[k], let t = tO, t == v else {throw noMatchError}}
			case .complex(matchesEntity: let h): guard h(restRepresentation) else {throw noMatchError}
			}
			
			return expectedEntity
		} catch {
			/* The rest representation did not match the description. */
			visitedEntities.insert(expectedEntity)
			for subentity in expectedEntity.subentities {
				let subentity = subentity as! DbEntityDescription /* See comment about SubSuperEntityType in DbRESTEntityDescription for explanation of the "as!" */
				if let r = actualLocalEntity(forRESTRepresentation: restRepresentation, expectedEntity: subentity, canUseSuperentities: canUseSuperentities, visitedEntities: &visitedEntities) {
					return r
				}
			}
			guard canUseSuperentities, let superentity = expectedEntity.superentity else {return nil}
			return actualLocalEntity(forRESTRepresentation: restRepresentation, expectedEntity: superentity as! DbEntityDescription, canUseSuperentities: canUseSuperentities, visitedEntities: &visitedEntities)
		}
	}
	
	private func _parameters(fromAdditionalRESTInfo additionalRESTInfo: AdditionalRESTRequestInfo<DbPropertyDescription>?, forEntity entity: DbEntityDescription?, firstLevel: Bool, forcedFieldsKeyName: String? = nil, forcedPaginator: RESTPaginator? = nil) -> [String: Any] {
		var result = [String: Any]()
		let pssParser = restMapping.queryParamParser
		let entityMapping = entity.flatMap{ restMapping.entityMapping(forEntity: $0) }
		
		var mappingEntityForcedParams = entityMapping?.forcedParametersOnFetch ?? [:]
		var clientForcedParams = additionalRESTInfo?.additionalRequestParameters ?? [:]
		var mappingForcedParams = (firstLevel ? restMapping.forcedParametersOnFetch : [:])
		var paginatorParams = additionalRESTInfo?.paginatorInfo.flatMap{ (forcedPaginator ?? additionalRESTInfo?.forcedPaginator ?? entityMapping?.paginator)?.paginationParams(withPaginatorInfo: $0) } ?? [:]
		
		/* *** Fields params *** */
		if let fieldsKeyName = forcedFieldsKeyName ?? entityMapping?.fieldsKeyName {
			let mappingForcedFields = mappingEntityForcedParams[fieldsKeyName]
			let mappingEntityForcedFields = mappingForcedParams[fieldsKeyName]
			let clientForcedFields = clientForcedParams[fieldsKeyName]
			let paginatorForcedFields = paginatorParams[fieldsKeyName]
			
			mappingEntityForcedParams.removeValue(forKey: fieldsKeyName)
			mappingForcedParams.removeValue(forKey: fieldsKeyName)
			clientForcedParams.removeValue(forKey: fieldsKeyName)
			paginatorParams.removeValue(forKey: fieldsKeyName)
			
			result.removeValue(forKey: fieldsKeyName)
			
			/* Forced fields priority: Client, Paginator, Entity Mapping, Mapping */
			let tmp1         = merge(forcedFields: clientForcedFields, withLowerPriorityForcedFields: paginatorForcedFields,     pssParser: pssParser)
			let tmp2         = merge(forcedFields: tmp1,               withLowerPriorityForcedFields: mappingEntityForcedFields, pssParser: pssParser)
			let forcedFields = merge(forcedFields: tmp2,               withLowerPriorityForcedFields: mappingForcedFields,       pssParser: pssParser)
			
			/* Let's try and get a ParameterizedStringSet from what's been given us
			 * in the forced params. If we cannot get a ParameterizedStringSet, we
			 * set the fields value to the forced fields and we won't compute the
			 * fields from the fetched properties. */
			if var computedFields = ParameterizedStringSet.fromAny(forcedFields, withPSSParser: pssParser) {
				var properties = additionalRESTInfo?.fetchedProperties ?? Set()
				var curEntityO = entity
				while let curEntity = curEntityO {
					if let fp = restMapping.entitiesMapping[curEntity]?.forcedPropertiesOnFetch {properties.formUnion(fp)}
					curEntityO = curEntity.superentity as? DbEntityDescription /* See comment about SubSuperEntityType in DbRESTEntityDescription for explanation of the "as" */
				}
				for property in properties {
					let subinfo = additionalRESTInfo?[property]
					let propertyMapping = restMapping.propertyMapping(forProperty: property, expectedEntity: entity)
					let destinationEntity = property.destinationEntity.flatMap{ ($0 as! DbEntityDescription) /* See comment about SubSuperEntityType in DbRESTEntityDescription for explanation of the "as!" */ }
					
					guard let propertyPathInFields = propertyMapping?.restPropertyPathInFields else {
						/* We do not have a path for the fields. We move the params
						 * for sub-additional REST info to the current level instead
						 * of them being a sub-level. */
						merge(queryParams: &result, newValues: _parameters(fromAdditionalRESTInfo: subinfo, forEntity: destinationEntity, firstLevel: firstLevel, forcedFieldsKeyName: fieldsKeyName, forcedPaginator: propertyMapping?.relationshipPaginator), pssParser: pssParser)
						continue
					}
					
					assert(propertyPathInFields.count > 0)
					
					var subFields = _parameters(fromAdditionalRESTInfo: subinfo, forEntity: destinationEntity, firstLevel: false, forcedFieldsKeyName: fieldsKeyName, forcedPaginator: propertyMapping?.relationshipPaginator)
					for component in propertyPathInFields.reversed() {
						var params = [String: ParameterizedStringSet]()
						merge(queryParams: &params, newValues: subFields, pssParser: pssParser)
						subFields = [fieldsKeyName: ParameterizedStringSet(valuesAndParams: [component: params])]
					}
					
					computedFields.merge(subFields[fieldsKeyName]! as! ParameterizedStringSet)
				}
				if let curFields = result[fieldsKeyName] {result[fieldsKeyName] = computedFields.merged(curFields, pssParser: pssParser)}
				else                                     {result[fieldsKeyName] = computedFields.valuesAndParams.count > 0 ? computedFields : nil}
			} else {
				if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Got forced param \"%@\" for fields. Don't know how to merge. Not computing fields.", log: $0, type: .info, String(describing: forcedFields)) }}
				else                                                          {NSLog("Got forced param \"%@\" for fields. Don't know how to merge. Not computing fields.", String(describing: forcedFields))}
				result[fieldsKeyName] = forcedFields
			}
		}
		
		/* *** Forced params *** */
		for (k, v) in mappingForcedParams       {result[k] = v}
		for (k, v) in mappingEntityForcedParams {result[k] = v}
		for (k, v) in paginatorParams           {result[k] = v}
		for (k, v) in clientForcedParams        {result[k] = v}
		
		return result
	}
	
	private func value(forKeyPath keyPath: [String], inRepresentation representation: [String: Any?]) -> Any?? {
		let val = representation[keyPath.first!]
		guard keyPath.count > 1 else {return val}
		switch val {
		case let dic as [String: Any?]: return value(forKeyPath: Array(keyPath.dropFirst()), inRepresentation: dic)
		case let arr as [Any?]:         return value(forKeyPath: Array(keyPath.dropFirst()), inRepresentation: arr)
		default:                        return nil
		}
	}
	
	private func value(forKeyPath keyPath: [String], inRepresentation representation: [Any?]) -> [Any?]? {
		var res = [Any?]()
		for v in representation {
			switch v {
			case let dic as [String: Any?]: guard let v = value(forKeyPath: Array(keyPath), inRepresentation: dic) else {return nil}; res.append(v)
			case let arr as [Any?]:         guard let v = value(forKeyPath: Array(keyPath), inRepresentation: arr) else {return nil}; res.append(v)
			default:                        return nil
			}
		}
		return res
	}
	
	private func merge(restRepresentation: inout [String: Any?], newValues: [String: Any?]) {
		for (key, val) in newValues {
			if let valAsDic = val as? [String: Any?], var newValue = restRepresentation[key] as? [String: Any?] {
				/* The value is a dictionary and the original REST representation
				 * contains a dictionary for the given key. We merge both
				 * dictionaries. */
				merge(restRepresentation: &newValue, newValues: valAsDic)
				restRepresentation[key] = newValue
			} else {
				restRepresentation[key] = val
			}
		}
	}
	
	private func merge(queryParams: inout [String: ParameterizedStringSet], newValues: [String: Any]?, pssParser: ParameterizedStringSetParser) {
		guard let newValues = newValues else {return}
		
		for (k, v) in newValues {
			if let pss = queryParams[k] {queryParams[k] = pss.merged(v, pssParser: pssParser)}
			else                        {queryParams[k] = ParameterizedStringSet.fromAny(v, withPSSParser: pssParser)}
		}
	}
	
	private func merge(queryParams: inout [String: Any], newValues: [String: Any]?, pssParser: ParameterizedStringSetParser) {
		guard let newValues = newValues else {return}
		
		for (k, v) in newValues {
			switch queryParams[k] {
			case nil:                                      queryParams[k] = v
			case .some(let pss as ParameterizedStringSet): queryParams[k] = pss.merged(v, pssParser: pssParser)
			default:
				if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("TODO. Got some untreated edge case when merging two query params dictionary. Not merging value \"%@\" (original, will stay) and \"%@\" (new, will be dropped)", log: $0, type: .error, String(describing: queryParams[k]), String(describing: v)) }}
				else                                                          {NSLog("TODO. Got some untreated edge case when merging two query params dictionary. Not merging value \"%@\" (original, will stay) and \"%@\" (new, will be dropped)", String(describing: queryParams[k]), String(describing: v))}
			}
		}
	}
	
	private func merge(forcedFields: Any?, withLowerPriorityForcedFields lowerPriorityForcedFields: Any?, pssParser: ParameterizedStringSetParser) -> Any? {
		switch (forcedFields, lowerPriorityForcedFields) {
		case (nil, nil): return nil
		case (.some(let v), nil): return v
		case (nil, .some(let v)): return v
		case (.some(let h), .some(let l)):
			let hpss = ParameterizedStringSet.fromAny(h, withPSSParser: pssParser)
			if
				let hpss = hpss,
				let lpss = ParameterizedStringSet.fromAny(l, withPSSParser: pssParser)
			{
				return lpss.merged(hpss)
			} else {
				if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Cannot merge \"%@\" and \"%@\" forced fields. Using first version.", log: $0, type: .info, String(describing: h), String(describing: l)) }}
				else                                                          {NSLog("Cannot merge \"%@\" and \"%@\" forced fields. Using first version.", String(describing: h), String(describing: l))}
				return hpss ?? h /* Client primes over paginator... */
			}
		}
	}
	
}
