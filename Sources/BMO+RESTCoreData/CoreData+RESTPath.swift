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
