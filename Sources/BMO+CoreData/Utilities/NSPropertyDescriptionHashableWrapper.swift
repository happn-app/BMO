//
/*
Copyright 2020 happn

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



/**
CoreData has a (f**ing) bug! It is possible to get two NSPropertyDescription
objects that are equal but have different hashes. So we wrap the properties to
override the hash.

More details on the bug:
  - Entity A is parent of entity B and declares the property p;
  - Asking CoreData the property description for the property p on A
    or B will both return a valid property description (let's call
    them p1 & p2);
  - Both property descriptions returned are equal (p1 == p2 in the
    Swift sense (not pointer equal, but isEqual: equal));
  - However, they do **NOT** have the same hash! The property
    description returned for B is a _proxy_ for the description of the
    A property description. And apparently, Apple miscalculated the
    hash in the proxy :(
This is **NOT** a Swift/ObjC interoperability problem, as the same bug
has been observed on an ObjC-only project. */
public struct NSPropertyDescriptionHashableWrapper : Hashable {
	
	public var wrappedProperty: NSPropertyDescription
	
	init(_ property: NSPropertyDescription) {
		wrappedProperty = property
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(wrappedProperty)
	}
	
}

public extension NSPropertyDescription {
	
	func hashableWrapper() -> NSPropertyDescriptionHashableWrapper {
		return NSPropertyDescriptionHashableWrapper(self)
	}
	
}
