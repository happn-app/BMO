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



/* Type erasure for Equatable. */
public struct AnyEquatable : Equatable {
	
	private let base: Any
	private let equals: (Any) -> Bool
	
	public init<E : Equatable>(_ v: E) {
		base = v
		equals = {
			guard let t = $0 as? E else {return false}
			return t == v
		}
	}
	
	public static func ==(_ lhs: AnyEquatable, _ rhs: AnyEquatable) -> Bool {
		return lhs.equals(rhs.base)
	}
	
	public static func ==(_ lhs: AnyEquatable, _ rhs: Any) -> Bool {
		return lhs.equals(rhs)
	}
	
	public static func ==(_ lhs: Any, _ rhs: AnyEquatable) -> Bool {
		return rhs.equals(lhs)
	}
	
}
