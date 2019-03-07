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

import AsyncOperationResult

import BMO



extension AsyncOperationResult {
	
	public func simpleBackRequestResult<BridgeType>() -> AsyncOperationResult<BridgeBackRequestResult<BridgeType>> where T == BackRequestResult<CoreDataFetchRequest<BridgeType.AdditionalRequestInfoType>, BridgeType> {
		return simpleBackRequestResult(forRequestPartId: NSNull())
	}
	
	public func simpleBackRequestSuccessValue<BridgeType>() -> BridgeBackRequestResult<BridgeType>? where T == BackRequestResult<CoreDataFetchRequest<BridgeType.AdditionalRequestInfoType>, BridgeType> {
		return simpleBackRequestResult().successValue
	}
	
	public func simpleBackRequestError<BridgeType>() -> Swift.Error? where T == BackRequestResult<CoreDataFetchRequest<BridgeType.AdditionalRequestInfoType>, BridgeType> {
		return simpleBackRequestResult().error
	}
	
}
