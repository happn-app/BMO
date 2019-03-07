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

import BMO
import RESTUtils



public protocol PageInfoRetriever {
	
	associatedtype BridgeType : Bridge
	
	func pageInfoFor(startOffset: Int, endOffset: Int) -> Any
	
	func nextPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: Any, nElementsPerPage: Int) -> Any??
	func previousPageInfo(for completionResults: BridgeBackRequestResult<BridgeType>, from pageInfo: Any, nElementsPerPage: Int) -> Any?
	
}
