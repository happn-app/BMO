/*
 * RESTMapper+ConvenienceInit.swift
 * RESTUtils
 *
 * Created by François Lamboley on 1/31/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public enum _RESTConvenienceMappingForEntity {
	
	case restPath(String)
	case paginator(RESTPaginator)
	case uniquingPropertyName(String?) /* If not given, entity does not have uniquing. If given property name is nil, entity is singleton. */
	
	case forcedParametersOnFetch([String: Any])
	
	case forcedValuesOnSave([String: Any])
	
	case restEntityDescription(RESTEntityDescription)
	case propertiesMapping([String: [_RESTConvenienceMappingForProperty]])
	
}


public enum _RESTConvenienceMappingForProperty {
	
	case isMandatory(Bool) /* Defaults to !property.isOptional */
	
	case restNameInFields(String?)   /* Alias for .restPathInFields(restNameInFields?.components(separatedBy: ".")) */
	case restPathInFields([String]?) /* Defaults to restPath (whether taken over by restToLocalMapping or not) */
	
	case restName(String)                         /* Alias for .restPath(restName.components(separatedBy: ".")) */
	case restPath([String])                       /* If not set, key is unmapped when converting from REST to Local, **unless a transformer is defined**. */
	case restToLocalTransformer(ValueTransformer) /* Defaults to nil (no transformations). If a transformer is set but no rest path is given, the transformer will be input the whole object when converting. */
	case restToLocalTransformerIsReversed         /* Defaults to false */
	case restToLocalTransformerNeedsUserInfo      /* Defaults to false */
	case restToLocalTransformerTransformsNil      /* Defaults to false. If true, the transformer will be given nil inputs. Otherwise, if source REST property value is nil, the local property will be set to nil too, ignoring the transformer. */
	case localConstant(Any?)                            /* For a local property whose value is not mapped to a REST value, but is always set to a constant */
	case restToLocalMapping(RESTToLocalPropertyMapping) /* Takes over all REST to Local cases above if set */
	
	case restNameOnSave(String?)                  /* Alias for .restPathOnSave(restNameOnSave?.components(separatedBy: ".")) */
	case restPathOnSave([String]?)                /* Defaults to restPath (whether taken over by restToLocalMapping or not) */
	case localToRESTTransformer(ValueTransformer) /* Defaults to nil (no transformations) */
	case localToRESTTransformerIsReversed         /* Defaults to false */
	case localToRESTTransformerNeedsUserInfo      /* Defaults to false */
	case localToRESTTransformerTransformsNil      /* Defaults to false */
	case useRESTToLocalTransformerForLocalToRESTTransformation(reversed: Bool) /* If set, the LtR transformer property is ignored and the RtL transformer is used. The argument is a convenience that sets (or removes) the localToRESTTransformerIsReversed property. */
	case localToRESTMapping(LocalToRESTPropertyMapping) /* Takes over all Local to REST cases above if set */
	
}


public extension RESTMapper {
	
	convenience init(
		entityGetter: (_ entityName: String) -> DbEntityDescription, propertyGetter: (_ entity: DbEntityDescription, _ propertyName: String) -> DbPropertyDescription,
		defaultFieldsKeyName: String? = "fields", defaultPaginator: RESTPaginator? = nil, forcedParametersOnFetch: [String: Any]? = nil,
		restQueryParamParser: ParameterizedStringSetParser = StandardRESTParameterizedStringSetParser(),
		convenienceMapping: [String: [_RESTConvenienceMappingForEntity]]
	) {
		var entitiesMapping = [DbEntityDescription: RESTEntityMapping<DbPropertyDescription>]()
		for (entityName, convenienceEntityMapping) in convenienceMapping {
			let entity = entityGetter(entityName)
			
			var restPathStr: String? = nil
			var paginator: RESTPaginator? = nil
			var forcedValuesOnSave = [String: Any]()
			var forcedParametersOnFetch = [String: Any]()
			var uniquingProperty: DbPropertyDescription?? = nil
			var restEntityDescription: RESTEntityDescription? = nil
			var forcedPropertiesOnFetch = Set<DbPropertyDescription>()
			var propertiesMapping = [DbPropertyDescription: RESTPropertyMapping]()
			
			for convenienceEntityMappingPart in convenienceEntityMapping {
				switch convenienceEntityMappingPart {
				case .restPath(let p):                restPathStr = p
				case .paginator(let p):               paginator = p
				case .uniquingPropertyName(let n):    uniquingProperty = .some(n.flatMap{ propertyGetter(entity, $0) })
				case .forcedParametersOnFetch(let v): forcedParametersOnFetch = v
				case .forcedValuesOnSave(let v):      forcedValuesOnSave = v
				case .restEntityDescription(let d):   restEntityDescription = d
					
				case .propertiesMapping(let conveniencePropertiesMapping):
					for (propertyName, conveniencePropertyMapping) in conveniencePropertiesMapping {
						let property = propertyGetter(entity, propertyName)
						
						var mandatory: Bool? = nil
						
						var restPropertyPathInFields: [String]?? = nil
						
						var restPropertyPath: [String]? = nil
						var rtlTransformer: ValueTransformer? = nil
						var rtlTransformerReversed: Bool = false
						var rtlTransformerNeedsUserInfo: Bool = false
						var rtlTransformerTransformsNil: Bool = false
						var rtlMapping: RESTToLocalPropertyMapping? = nil
						
						var restPropertyPathOnSave: [String]?? = nil
						var ltrTransformer: ValueTransformer? = nil
						var ltrTransformerReversed: Bool = false
						var ltrTransformerNeedsUserInfo: Bool = false
						var ltrTransformerTransformsNil: Bool = false
						var useRTLTransformerForLTR: Bool = false
						var ltrMapping: LocalToRESTPropertyMapping? = nil
						
						for conveniencePropertyMappingPart in conveniencePropertyMapping {
							switch conveniencePropertyMappingPart {
							case .isMandatory(let b): mandatory = b
								
							case .restNameInFields(let n): restPropertyPathInFields = .some(n?.components(separatedBy: "."))
							case .restPathInFields(let p): restPropertyPathInFields = p; assert(p?.count ?? 1 > 0)
								
							case .restName(let n):                     restPropertyPath = n.components(separatedBy: ".")
							case .restPath(let p):                     restPropertyPath = p; assert(p.count > 0)
							case .restToLocalTransformer(let t):       rtlTransformer = t
							case .restToLocalTransformerIsReversed:    rtlTransformerReversed = true
							case .restToLocalTransformerNeedsUserInfo: rtlTransformerNeedsUserInfo = true
							case .restToLocalTransformerTransformsNil: rtlTransformerTransformsNil = true
							case .localConstant(let c):      rtlMapping = .constant(c)
							case .restToLocalMapping(let m): rtlMapping = m
								
							case .restNameOnSave(let n):               restPropertyPathOnSave = .some(n?.components(separatedBy: "."))
							case .restPathOnSave(let p):               restPropertyPathOnSave = p; assert(p?.count ?? 1 > 0)
							case .localToRESTTransformer(let t):       ltrTransformer = t
							case .localToRESTTransformerIsReversed:    ltrTransformerReversed = true
							case .localToRESTTransformerNeedsUserInfo: ltrTransformerNeedsUserInfo = true
							case .localToRESTTransformerTransformsNil: ltrTransformerTransformsNil = true
							case .useRESTToLocalTransformerForLocalToRESTTransformation(reversed: let i): useRTLTransformerForLTR = true; ltrTransformerReversed = i
							case .localToRESTMapping(let m): ltrMapping = m
							}
						}
						let rtlFinalMapping: RESTToLocalPropertyMapping
						if let mapping = rtlMapping {rtlFinalMapping = mapping}
						else {
							let finalRTLTransformer = rtlTransformer.map{ (transformer: ValueTransformer) -> RESTMapperTransformer in
								assert(!rtlTransformerReversed || type(of: transformer).allowsReverseTransformation(), "Invalid convenience mapping with an reversed RTL transformer with a transformer class that does not support reverse transformation.")
								return RESTMapperTransformer(transformer: transformer, reversed: rtlTransformerReversed, transformNilProperties: rtlTransformerTransformsNil, transformerNeedsUserInfo: rtlTransformerNeedsUserInfo)
							}
							switch (restPropertyPath, finalRTLTransformer) {
							case (.some(let restPropertyPath), .some(let rtlTransformer)):
								rtlFinalMapping = .propertyTransformerMapping(sourcePropertyPath: restPropertyPath, transformer: rtlTransformer)
								
							case (.some(let restPropertyPath), nil):
								rtlFinalMapping = .propertyMapping(sourcePropertyPath: restPropertyPath)
								
							case (nil, .some(let rtlTransformer)):
								rtlFinalMapping = .objectTransformerMapping(transformer: rtlTransformer)
								
							case (nil, nil):
								rtlFinalMapping = .skipped
							}
						}
						let ltrFinalMapping: LocalToRESTPropertyMapping
						if let mapping = ltrMapping {ltrFinalMapping = mapping}
						else {
							let finalLTRTransformer = (useRTLTransformerForLTR ? rtlTransformer : ltrTransformer).map{ (transformer: ValueTransformer) -> RESTMapperTransformer in
								assert(!ltrTransformerReversed || type(of: transformer).allowsReverseTransformation(), "Invalid convenience mapping with an reversed LTR transformer with a transformer class that does not support reverse transformation.")
								return RESTMapperTransformer(transformer: transformer, reversed: ltrTransformerReversed, transformNilProperties: ltrTransformerTransformsNil, transformerNeedsUserInfo: ltrTransformerNeedsUserInfo)
							}
							switch (restPropertyPathOnSave ?? restPropertyPath, finalLTRTransformer) {
							case (.some(let restPropertyPath), .some(let ltrTransformer)):
								ltrFinalMapping = .propertyTransformerMapping(destinationPropertyPath: restPropertyPath, transformer: ltrTransformer)
								
							case (.some(let restPropertyPath), nil):
								ltrFinalMapping = .propertyMapping(destinationPropertyPath: restPropertyPath)
								
							case (nil, .some(let ltrTransformer)):
								ltrFinalMapping = .objectTransformerMapping(transformer: ltrTransformer)
								
							case (nil, nil):
								ltrFinalMapping = .skipped
							}
						}
						if mandatory ?? !property.isOptional {forcedPropertiesOnFetch.insert(property)}
						propertiesMapping[property] = RESTPropertyMapping(
							restToLocalMapping: rtlFinalMapping,
							localToRESTMapping: ltrFinalMapping,
							restPropertyPathInFields: restPropertyPathInFields ?? restPropertyPath
						)
					}
				}
			}
			let restPath: RESTPath?
			if let restPathStr = restPathStr {restPath = RESTPath(restPathStr)!}
			else                             {restPath = nil}
			let uniquingType: RESTEntityUniquingType<DbPropertyDescription>?
			if let uniquingProperty = uniquingProperty {uniquingType = uniquingProperty.flatMap{ .onProperty(constantPrefix: entityName + "/", property: $0) } ?? .singleton(entityName)}
			else                                       {uniquingType = nil}
			entitiesMapping[entity] = RESTEntityMapping<DbPropertyDescription>(
				restPath: restPath,
				restEntityDescription: restEntityDescription,
				uniquingType: uniquingType,
				forcedPropertiesOnFetch: forcedPropertiesOnFetch,
				forcedParametersOnFetch: forcedParametersOnFetch,
				forcedValuesOnSave: forcedValuesOnSave,
				propertiesMapping: propertiesMapping,
				fieldsKeyName: defaultFieldsKeyName, /* TODO */
				paginator: paginator ?? defaultPaginator
			)
		}
		
		self.init(
			restMapping: RESTMapping<DbEntityDescription, DbPropertyDescription>(
				entitiesMapping: entitiesMapping,
				queryParamParser: restQueryParamParser,
				forcedParametersOnFetch: forcedParametersOnFetch ?? [:],
				forcedValuesOnSave: [:] /* TODO */
			)
		)
	}
	
}
