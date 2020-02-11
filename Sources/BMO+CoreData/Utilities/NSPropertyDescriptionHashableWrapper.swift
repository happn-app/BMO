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
override the hash. */
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
