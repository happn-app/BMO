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

/* A test to write an umbrella Framework to avoid importing all these each time
 * one wants to use BMO with REST and CoreData. Does not seem to work (at least
 * not in Xcode, not tested with anything else). */

@_exported import BMO
@_exported import RESTUtils
@_exported import BMO_FastImportRepresentation
@_exported import BMO_CoreData
@_exported import BMO_RESTCoreData
@_exported import CollectionLoader
@_exported import CollectionLoader_RESTCoreData
