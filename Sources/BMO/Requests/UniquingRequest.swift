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



/** This is used to insert objects in the local Db, with uniquing.

If the object is already in the Db (in regard to the uniquing given by the db),
the already inserted object will be updated. In this case, the object given in
argument to this enum case will be deleted.

- warning: Not corresponding operation implemented yet */
public struct UniquingRequest<DbType : Db> {
	
	let db: DbType
	
	let object: DbType.ObjectType
	
}
