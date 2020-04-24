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



/** Conversion from REST to local: We know in which property the value will
ultimately be set, but we don't know where to get the value from. */
public enum RESTToLocalPropertyMapping {
	
	/** The value will be skipped during conversion. */
	case skipped
	
	/** The value will always be set to the given constant. */
	case constant(Any?)
	
	/** The value will be set to the value of the source property at the given
	path with no transformation. Type consistency will still be checked and the
	value will be skipped if type is not consistent between source and
	destination properties. */
	case propertyMapping(sourcePropertyPath: [String])
	
	/** The value will be mapped from the given source property, with a
	`ValueTransformer` transformation (the `ValueTransformer` is wrapped in a
	`RESTMapperTransformer`).
	
	It is not possible to return properly a double optional (`Any??`) from a
	`ValueTransformer`. If you have to return `.some(nil)`, your transformer
	should return objects of type `ObjC_RESTMapperOptionalWrapper`.
	
	If you return nil in the transformed value, the property will be skipped. If
	you return a value of any class but `ObjC_RESTMapperOptionalWrapper`, the
	value will be used. For `ObjC_RESTMapperOptionalWrapper` the value will be
	unwrapped and used. */
	case propertyTransformerMapping(sourcePropertyPath: [String], transformer: RESTMapperTransformer)
	/** The value will be mapped from the source object using the given
	transformer.
	
	See the `propertyTransformerMapping` case for a description of what the
	transformer can do. */
	case objectTransformerMapping(transformer: RESTMapperTransformer)
	
	/** The value will be mapped from the given source property, with a handler
	transformation.
	
	The handler must return a double optional. If the returned value is `nil`,
	the property is skipped. If it is `.some(nil)`, the value will be set to nil.
	For any other value, the value will be taken (after a type check). */
	case propertyHandlerMapping(sourcePropertyPath: [String], transformer: (_ restProperty: Any?, _ userInfo: Any?) -> Any??)
	/** The value will be mapped from the source object using the given handler.
	The same rules as `propertyHandlerMapping` apply. */
	case objectHandlerMapping(transformer: (_ restRepresentation: [String: Any?], _ userInfo: Any?) -> Any??)
	
}

/** Conversion from local to REST: We know the value, we want to convert it to
key/val pair(s). */
public enum LocalToRESTPropertyMapping {
	
	/** The value will be skipped during conversion. */
	case skipped
	
	/** The source (local) property value will be set directly at the given
	destination property path, with no transformation. */
	case propertyMapping(destinationPropertyPath: [String])
	
	/** The source (local) property value will be transformed using the given
	transformer then set at the given destination property path.
	
	Supports `ObjC_RESTMapperOptionalWrapper` values (see the
	`propertyTransformerMapping` case of `RESTToLocalPropertyMapping` for more
	information about this). */
	case propertyTransformerMapping(destinationPropertyPath: [String], transformer: RESTMapperTransformer)
	/** The source (local) property value will be given to the transformer which
	must return an object of type `[String: Any]`. `NSNull` values will be
	converted to `nil` (first level only). Returning an object of type
	`[String: Any?]` is acceptable too.
	
	The returned dictionary from the transformer will be merged with the current
	local representation of the object. */
	case objectTransformerMapping(transformer: RESTMapperTransformer)
	
	/** The source (local) property value will be transformerd using the given
	handler then set at the given destination property path. */
	case propertyHandlerMapping(destinationPropertyPath: [String], transformer: (_ value: Any?, _ userInfo: Any?) -> Any??)
	/** The source (local) object will be given to the handler. The results will
	be merged with the current local representation of the object. */
	case objectHandlerMapping(transformer: (_ object: Any?, _ userInfo: Any?) -> [String: Any?]?)
	
}

/* When converting, we will use the following algorithm:
 *    - Iterate on **local** properties (whether we're converting from local to
 *      REST or from REST to local representations);
 *    - If converting to local, use REST representation to set value of current
 *      converted property;
 *    - If converting to REST, use value of current converted property to
 *      populate some key/values of the REST representation (usually one key/val
 *      pair at a time).
 *
 * This means:
 *    - Multiple keys of a REST representation can be used to set the value of
 *      one property of a local representation;
 *    - One local representation key can be used to set multiple key/val pairs
 *      of a REST representation;
 * BUT
 *    - One REST representation key cannot be set using multiple local key
 *      values. */
struct RESTPropertyMapping {
	
	let restToLocalMapping: RESTToLocalPropertyMapping
	let localToRESTMapping: LocalToRESTPropertyMapping
	
	let restPropertyPathInFields: [String]?
	
	/** For to-many relationhips only, a paginator that will overwrite the
	paginator for the destination entity (or the default paginator if the
	destination entity does not have a paginator). */
	let relationshipPaginator: RESTPaginator?
	
}
