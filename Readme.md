BMO is a concept. Any Db Object can be a BMO.

BMO or Backed Managed Objects is made for linking any local database (CoreData, Realm, etc.) to any API (REST, SOAP, etc.).
For now BMO has a concrete implementation with CoreData and REST

Below you can find a schema which present how you communicate with CoreData and how BMO translate your CoreData request to create/read/update/delete data with an API and reflect results in CoreData.

<img src="https://github.com/happn-app/BMOSpotifyClient/blob/master/Ressources/bmo-schema-front.png" width="310">

- [Features](#features)
- [Component Libraries](#component-libraries)
- [Dependencies](#dependencies)
- [Requirements](#requirements)
- [Installation](#installation)
- [Getting started](#getting-started)
    - [CoreData](#coredata)
    - [BMOBridge](#bmobridge)
        - [RestMapper](#restmapper)
        - [BackOperation](#backoperation)
        - [RemoteObjectRepresentations](#remoteobjectrepresentations)
        - [MixedRepresentation](#mixedrepresentation)
    - [Usage](#usage)
        - [RequestManager](#requestmanager)
        - [NSFetchedResultsController](#nsfetchedresultscontroller)
        - [Fetch datas](#fetch-datas)
- [Advanced Usage](#advanced-usage)


## Features
- Create objects
- Read objects
- Update objects
- Delete objects

## Component Libraries
BMO is built with layers of concrete implementations
- BMO 
- RestUtils
- BMO+FastImportRepresentation
- BMO+CoreData
- BMO+RESTCoreData : THE concrete implementation
- CollectionLoader+RESTCoreData (Documentation TODO)

## Dependencies
In order to keep BMO+RESTCoreData focused specifically on synchronizing your CoreData DB and your REST API, additional component libraries have been created by the happn to allow you to go to the essential.

- AsyncOperationResult
- CollectionLoader
- KVObserver
- RecursiveSyncDispatch
- RetryingOperation
- SemiSingleton
- URLRequestOperation

## Requirements
iOS 10.0+ / macOS 10.12+ / tvOS 10.0+ / watchOS 3.0+
Xcode 10.1+
Swift 4.2+

## Installation
Carthage

Carthage is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate BMO into your Xcode project using Carthage, specify it in your Cartfile:

```swift
//  Cartfile

github "happn-tech/BMO" ~> 1.0
github "happn-tech/URLRequestOperation" ~> 1.1
```


## Getting started

### CoreData

- Prepare your CoreData model with your entities and attributes
- Set a 'bmoId' attribute as name of your unique key value of each entity
- Setup your CoreData context from persistent container in AppDelegate
```swift
//  AppDelegate.swift

private(set) var context: NSManagedObjectContext!

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    /* Setup CoreData context */
    let container = NSPersistentContainer(name: "XXX") // Replace 'XXX' by your xcdatamodeld name
    container.loadPersistentStores(completionHandler: { _, _ in })
    context = container.viewContext

    [...]
}
```
<img src="https://github.com/happn-app/BMOSpotifyClient/blob/master/Ressources/bmo-demo-xcdatamodel.png" width="300">

### BMO Bridge

The BMO Bridge is the interface between your local CoreData database and API. This bridge is your main settings file to configure and guide BMO for in/out requests.
Create a class which implements Bridge protocol.

Your defined bridge will define and provides all these informations : 

- Before and after request
    - *restMapper* : Define the mapping between you local and remote objects

- Before request
    - *backOperation* : Define how requests to your API will be built (backOperation())

- After request and before inserting in local model
    - *remoteObjectRepresentations* : Provides the Datas returned by API and allows you to return the [String: Any?] representations of your datas (remoteObjectRepresentations())
    - *mixedRepresentation*         : Provides the remoteObjectRepresentations returned previsously and allows you to return a representation ready to be inserted in your local model (mixedRepresentation)


#### RestMapper
Here we asssume we have created an entity called "User" in our CodeData DB

This entity has three attributes : 
    - bmoId (primary key)
    - username
    - firstname

We can see here that the remote representations (in JSON returned by API) these three attributes looks like that : 
    - id
    - user_name
    - first_name

Thanks to that mapping BMO will know how to build request and how to map JSON to local model

```swift
//  MyBridge.swift

private lazy var restMapper: RESTMapper<NSEntityDescription, NSPropertyDescription> = {
    let userMapping: [_RESTConvenienceMappingForEntity] = [
        .restPath("/users"),
        .uniquingPropertyName("bmoId"),
        .propertiesMapping([
            "bmoId":           [.restName("id")],
            "username":        [.restName("user_name")],
            "firstname":       [.restName("first_name")],
        ])
    ]
        
    return RESTMapper(
        model: dbModel,
        defaultPaginator: RESTOffsetLimitPaginator(),
        convenienceMapping: [
            "User":  userMapping,
        ]
    )
}()
```

#### BackOperation
Now you can create your backOperations which contains the URLSession which will make the concrete requests

Here you can see how to build a simple GET request
```swift
//  MyBridge.swift

    func backOperation(forFetchRequest fetchRequest: DbType.FetchRequestType, additionalInfo: AdditionalRequestInfoType?, userInfo: inout UserInfoType) throws -> BackOperationType? {
        var request = try MyBridge.urlRequest(forFetchRequest: fetchRequest, additionalRequestInfo: additionalInfo, forcedRESTPathResolutionValues: nil, restMapper: restMapper!, apiRoot: SpotifyBMOBridge.apiURL)
        return URLRequestOperation(request: request)
    }
```

#### RemoteObjectRepresentations
Once more, BMO is operation-based.
So here you are told by BMO that one of your backOperation is finished.
You can get the datas fetched by this operation, deserialize and returns it.
(Here you can see we get the "items" key of our JSON because we want the Array of users contained in it)

```swift
//  MyBridge.swift

    func remoteObjectRepresentations(fromFinishedOperation operation: BackOperationType, userInfo: UserInfoType) throws -> [RemoteObjectRepresentationType]? {
        switch operation.results {
        case .success(let success): return success["items"] as? [MyBridge.RemoteObjectRepresentationType] // Replace "items" by your key data in JSON results
        case .error(let e):         throw Err.operationError(e)
        }
    }

```

#### MixedRepresentation
The cherry on the cake.
In most of the cases you really can user this default implementation of this method.
The idea here is to create a mixed representations of the above remoteObjectRepresentations.
This is called mixed because it has all the infos of the type of local entity it is supposed to represent. And it also embbed a [String : Any?] called attributes in which all keys are local attributes name and all values are the values fetched by API.

```swift
//  MyBridge.swift

    func mixedRepresentation(fromRemoteObjectRepresentation remoteRepresentation: RemoteObjectRepresentationType, expectedEntity: DbType.EntityDescriptionType, userInfo: UserInfoType) -> MixedRepresentation<DbType.EntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, UserInfoType>? {
        guard let restMapper = restMapper, let entity = restMapper.actualLocalEntity(forRESTRepresentation: remoteRepresentation, expectedEntity: expectedEntity) else {return nil}

        let mixedRepresentationDictionary = restMapper.mixedRepresentation(ofEntity: entity, fromRESTRepresentation: remoteRepresentation, userInfo: userInfo)

        let uniquingId = restMapper.uniquingId(forLocalRepresentation: mixedRepresentationDictionary, ofEntity: entity)

        return MixedRepresentation(entity: entity, uniquingId: uniquingId, mixedRepresentationDictionary: mixedRepresentationDictionary, userInfo: userInfo)
    }


//  MixedRepresentation.swift
public struct MixedRepresentation {
    ...
    public let entity: NSEntityDescription
    public let uniquingId: AnyHashable?
    public let attributes: [String : Any?]
    ...
}

```

### Usage

#### RequestManager

You can instantiate your request manager in the AppDelegate for example

```swift
//  AppDelegate.swift

import BMO

private(set) var requestManager: RequestManager!

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    /* Setup BMO request manager */
    requestManager = RequestManager(bridges: [DemoBMOBridge(dbModel: container.managedObjectModel)], resultsImporterFactory: MyBridge.DemoBMOImporter())
}
```
#### NSFetchedResultsController

One of the best way to fetch CoreData and display it in a UITableView for example is to use a NSFetchedResultsController

Here you create it, bind it to a NSFetchRequest of Users and tell that your it will delegate to your ViewController the processing of new datas linked to that NSFetchRequest (insert, update, delete, move)

```swift
//  ViewController.swift

let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "%K != NULL", #keyPath(User.username))
fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.username), ascending: true)]
fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: AppDelegate.shared.context!, sectionNameKeyPath: nil, cacheName: nil)
fetchedResultsController?.delegate = self
try! self.fetchedResultsController?.performFetch()
```

Please refer to Apple Documentation to implement NSFetchedResultsController (https://developer.apple.com/documentation/coredata/nsfetchedresultscontroller)
happn provides you an helper for this implementation (https://github.com/happn-tech/CollectionAndTableViewUpdateConveniences)


#### Fetch datas
Here you just ask your previously created RequestManager to fetch objects corresponding to the above NSFetchRequest

```swift
//  ViewController.swift

private func performBMOUserFetch() {
    guard let fetchRequest = fetchedResultsController?.fetchRequest else {return}
    let context = AppDelegate.shared.context!
    let requestManager = AppDelegate.shared.requestManager!
    let _: BackRequestOperation<RESTCoreDataFetchRequest, DemoBMOBridge> = requestManager.fetchObject(
        fromFetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>, additionalRequestInfo: nil,
        fetchType: .always, onContext: context
    )
}
```

That's it 🥳, you can now run your project and your datas will be automatically display in your table view.


## Advanced Usage 
- *UserInfos*     : Define various UserInfos you would like to define before building your requests
- *Metadatas*     : Define metadatas your API could provide (pagination,...)

## Evolving BMO
- BMO+Realm
- BMO+RESTRealm
- BMO+SOAPCoreData
...



