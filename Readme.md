# BMO
![Platforms](https://img.shields.io/badge/platform-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS-lightgrey.svg?style=flat) [![SPM compatible](https://img.shields.io/badge/SPM-compatible-E05C43.svg?style=flat)](https://swift.org/package-manager/) [![License](https://img.shields.io/github/license/happn-tech/BMO.svg?style=flat)](License.txt) [![happn](https://img.shields.io/badge/from-happn-0087B4.svg?style=flat)](https://happn.com)

**BMO** is a concept. Any Database Object can be a **B**acked **M**anaged **O**bject.

- [What is it?](#what-is-it)
- [BMO Components](#bmo-Components)
- [Installation and Dependencies](#installation-and-dependencies)
- [Requirements](#requirements)
- [Getting started](#getting-started)
  - [The Core Data Stack](#the-core-data-stack)
  - [The BMO Bridge](#the-bmo-bridge)
    - [The RestMapper](#the-restmapper)
    - [Providing an Operation for a request](#providing-an-operation-for-a-request)
    - [Extract objects remote representations from a finished operation](#extract-objects-remote-representations-from-a-finished-operation)
    - [The MixedRepresentation](#the-mixedrepresentation)
  - [Once the Bridge is done: Using BMO!](#once-the-bridge-is-done-using-bmo)
    - [Creating a Request Manager](#creating-a-request-manager)
    - [Fetching Data](#fetching-data)
    - [NSFetchedResultsController](#NSFetchedResultsController)
- [Advanced Usage](#advanced-usage)
- [Possible Evolutions](#possible-evolutions)
- [Credits](#credits)


## What is it?
BMO is a collection of protocols that makes it easy to link any local database (CoreData, Realm, etc.) to any API (a REST or SOAP API, an SMB share, or anything else).
For now BMO has one concrete implementation, linking CoreData to a REST API.

Here is a diagram showing the lifecycle of a request through BMO:
![BMO Diagram](https://github.com/happn-tech/BMO/blob/master/docs/images/BMODiagram1.png)

1. A CoreData request is sent to BMO.
2. BMO returns the matching objects synchronously…
3. …while at the same time starting the remote update process. First it goes through your _bridge_ (we’ll see later how it works);
4. Your bridge will return a standard `Operation` subclass, which will be in charge of contacting your API;
5. When the operation ends, BMO will go through your bridge again with the result of the operation to get a so-called _`MixedRepresentation`_;
6. BMO imports the _`MixedRepresentation`_ in the CoreData database, taking care of the uniquing and merging of the objects;
7. Finally, you get the results of the import. All errors are reported, and you can optionally get the new CoreData objects matching the original request.


## BMO Components
In order to have a clear separation of roles, this repository has many targets:
- **BMO**: This is the base target, defining the base protocols for BMO, and containing the core logic of the project;
- **BMO+CoreData**: A collection of utilities for using BMO with a CoreData db;
- **BMO+RESTCoreData**: Additions to _BMO+CoreData_ to use BMO with a _REST_ API;
- **RESTUtils**: A collection of utilities to build a BMO bridge for a _REST_ API. This target is not BMO specific and could be used in any project;
- **BMO+FastImportRepresentation**: Usually you don’t have to deal with this one. It defines a structure which is used by BMO to import the _`MixedRepresentation`s_ in whatever db you use;
- **CollectionLoader+RESTCoreData**: For using a [CollectionLoader](https://github.com/happn-tech/CollectionLoader) with BMO.


## Installation and Dependencies
BMO is Carthage and SPM compatible.

BMO is heavily `Operation`-based. Creating a network operation is not very hard, but we recommend
using `URLRequestOperation` which takes care of a great deal of things in addition to providing
`Operation`-based network requests (e.g. automatic retrying based on network availability for
idempotent requests).

Here’s a basic Cartfile you can use for your BMO-based projects.
```ogdl
# Cartfile
github "happn-tech/BMO" ~> 0.1
github "happn-tech/URLRequestOperation" ~> 1.1.5
```

### Dependencies

BMO has the following dependencies:
- [AsyncOperationResult](https://github.com/happn-tech/AsyncOperationResult): Basically the `Result` type of the standard Swift library. (BMO was created with Swift 4.2; this dependency will be dropped.)
- [CollectionLoader](https://github.com/happn-tech/CollectionLoader): A generic collection loader, supporting page-based fetching.
   - [KVObserver](https://github.com/happn-tech/KVObserver): A clean wrapper around Objective-C’s KVO.

URLRequestOperation has the following dependencies:
- [AsyncOperationResult](https://github.com/happn-tech/AsyncOperationResult): Basically the `Result` type of the standard Swift library. (URLRequestOperation was created with Swift 4.2; this dependency will be dropped.)
- [RetryingOperation](https://github.com/happn-tech/RetryingOperation): Implementation of an abstract `Operation` providing conveniences for easily running and retrying a base operation.
- [SemiSingleton](https://github.com/happn-tech/SemiSingleton): An implementation of the "singleton by id".
   - [RecursiveSyncDispatch](https://github.com/happn-tech/RecursiveSyncDispatch): Recursively sync dispatch on private GCD queues.


## Requirements
- macOS 10.10+ / iOS 8.0+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 10.2+
- Swift 5.0+


## Getting started
This Readme will focus on using the CoreData+REST implementation of BMO. An advanced usage will show later how to create new concrete implementations of BMO for other databases or APIs.

The Readme here will give the general steps to follow to implement BMO in an app. If you want a more detailed and thorough guide, please see our [example project](https://github.com/happn-tech/BMOSpotifyClient).

### The Core Data Stack
There is only one requirement for your Core Data model: that all your mapped entities have a "uniquing property." This will be the property BMO will read and write to make sure you won't have duplicated instances in your stack. In effect, if you’re fetching an object already in the local database, the local and fetched objects will be merged together. The object that was already in the database will be updated.
The property can be named however you like, but must have the same name in all your entities.

Example of a simple model with the uniquing property name `bmoId`:

![CoreData Model](https://github.com/happn-tech/BMO/blob/master/docs/images/CoreDataModelExample1.png)

### The BMO Bridge
A bridge is an entity (class, struct, whatever) that implements the Bridge protocol. It is the interface between your local Core Data database and your API. This is the most important thing you have to provide to BMO.

The bridge responsabilities:
- From a Core Data fetch request, or an inserted, updated or deleted object, you'll have to provide an `Operation` that execute the given request on your API.  
_Note_: This is not a trivial task. The `RestMapper` is here to help you.
- From the finished operation you'll have to extract the fetched objects remote representations (most of the time this will simply be a `[[String: Any?]]`);
- From a remote object representation you'll have to return a `MixedRepresentation`. We'll see later what this is. For this task too, the `RestMapper` is here to help.

#### The RestMapper
For a standard "REST bridge," you'll probably want to use the **RESTUtils** module (which is a part of BMO), and in particular the `RESTMapper` class. The module will provide you with conveniences to convert a fetch or save request to an URL Operation that you can return to BMO, as well as converting a parsed JSON to a `MixedRepresentation` (don't worry, we'll definitely explain what's a `MixedRepresentation` later).

An example is worth a thousand words. Let's say we have a `User` entity in the Core Data model with the following properties:
- bmoId (String)
- username (String)
- firstname (String)
- age (Int)

The JSON our API returns for a `User` looks like this:
```json
{
	"id": "abc",
	"user_name": "bob.kelso",
	"first_name": "Bob",
	"age": 42
}
```

In our bridge, we'd keep a REST Mapper that would look like this:
```swift
/* MyBridge.swift */

private lazy var restMapper: RESTMapper<NSEntityDescription, NSPropertyDescription> = {
   let userMapping: [_RESTConvenienceMappingForEntity] = [
      .restPath("/users(/|username|)"),
      .uniquingPropertyName("bmoId"),
      .propertiesMapping([
         "bmoId":     [.restName("id")],
         "username":  [.restName("user_name")],
         "firstname": [.restName("first_name")],
         "age":       [.restName("age"),       .restToLocalTransformer(RESTIntTransformer())]
      ])
   ]
       
   return RESTMapper(
      model: dbModel,
      defaultPaginator: RESTOffsetLimitPaginator(),
      convenienceMapping: [
         "User": userMapping
      ]
   )
}()
```

#### Providing an `Operation` for a request
Once more, we'll trust RESTUtils to do the heavy lifting for this work.

TODO: Migrate connected http operation utils from happn to RESTUtils…

#### Extract objects remote representations from a finished operation
We must simply extract the remote representations (basically the parsed JSON from the API) and return it. BMO cannot guess how to retrieve the data from the operation that is finished as it does not have any information about it.

Example of implementation:
```swift
/* MyBridge.swift */

func remoteObjectRepresentations(fromFinishedOperation operation: BackOperationType, userInfo: UserInfoType) throws -> [RemoteObjectRepresentationType]? {
   /* In our case, the operation has a results property containing either the
    * parsed JSON from the API or an error. */
   switch operation.results {
   /* We access the "items" elements because our API returns the objects in this key. 
    * The behaviour may be different with another API. */
   case .success(let success): return success["items"] as? [MyBridge.RemoteObjectRepresentationType]
   case .error(let e):         throw Err.operationError(e)
   }
}

```

#### The `MixedRepresentation`
As promised, we explain here what is the `MixedRepresentation`!

A `MixedRepresentation` is a structure representing an object to import into your local database. The properties in the `MixedRepresentation` are saved as a `Dictionary`, whose keys are the property names, and the values are the actual property values. The relationships of the object to import are saved as a `Dictionary` whose keys are the relationship names, but the values are an array of remote (aka. API) representation!

This weird structure exists because it acutally simplifies the import and convertion of the result of an API in your local database. Usually, the `MixedRepresentation` is easy to create from the remote representation using the [`RestMapper`](#the-restmapper).

Here is an example of an implementation of this part of the bridge:
```swift
/* MyBridge.swift */

func mixedRepresentation(fromRemoteObjectRepresentation remoteRepresentation: RemoteObjectRepresentationType, expectedEntity: DbType.EntityDescriptionType, userInfo: UserInfoType) -> MixedRepresentation<DbType.EntityDescriptionType, RemoteRelationshipAndMetadataRepresentationType, UserInfoType>? {
   /* First let’s get which entity the remote representation represents.
    * The REST mapper will do this job for us. */
   guard let entity = restMapper.actualLocalEntity(forRESTRepresentation: remoteRepresentation, expectedEntity: expectedEntity) else {return nil}

   /* The REST mapper does not know about the MixedRepresentation
    * structure, but can convert a remote representation into a Dictionary
    * that we will use to build the MixedRepresentation instance we want. */
   let mixedRepresentationDictionary = restMapper.mixedRepresentation(ofEntity: entity, fromRESTRepresentation: remoteRepresentation, userInfo: userInfo)

   /* We need to use the REST mapper once again to retrieve the uniquing
    * id from the Dictionary we created above. */
   let uniquingId = restMapper.uniquingId(forLocalRepresentation: mixedRepresentationDictionary, ofEntity: entity)
   /* Finally, with everything we have retrieved above, we can create the
    * MixedRepresentation instance that we return to the caller. */
   return MixedRepresentation(entity: entity, uniquingId: uniquingId, mixedRepresentationDictionary: mixedRepresentationDictionary, userInfo: userInfo)
}
```

### Once the Bridge is done: Using BMO!

#### Creating a Request Manager
The request manager is the instance you'll use to send requests to BMO. You can keep it in your app delegate for instance.

```swift
/* AppDelegate.swift */

import BMO

class AppDelegate : NSObject, UIApplicationDelegate {

   private(set) var requestManager: RequestManager!

   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      /* Setup BMO request manager */
      requestManager = RequestManager(bridges: [YourBridge(dbModel: container.managedObjectModel)], resultsImporterFactory: BMOBackResultsImporterForCoreDataWithFastImportRepresentationFactory())
   }

   /* A struct to help BMO. We are actually working on several solutions
    * to avoid the use of this one. */
   private struct BMOBackResultsImporterForCoreDataWithFastImportRepresentationFactory : AnyBackResultsImporterFactory {

      func createResultsImporter<BridgeType : Bridge>() -> AnyBackResultsImporter<BridgeType>? {
         return (AnyBackResultsImporter(importer: BackResultsImporterForCoreDataWithFastImportRepresentation<YourBridge>(uniquingPropertyName: "bmoId")) as! AnyBackResultsImporter<BridgeType>)
      }

   }

}
```

#### Fetching Data
Once all the setup is done, you can use the request manager to fetch some objects.

```swift
/* ViewController.swift */

private func refreshUser(username: String) {
   let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
   fetchRequest.predicate = NSPredicate(format: "%K != %@", #keyPath(User.username), username)

   let context = AppDelegate.shared.context!
   _ = AppDelegate.shared.requestManager!.fetchObject(
      fromFetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>,
      fetchType: .always, onContext: context, handler: { (user: User?, fullResponse: AsyncOperationResult<BridgeBackRequestResult<YourBridge>>) -> Void in
         /* Use the fetched user here. */
      }
   )
}
```

#### NSFetchedResultsController
Using the NSFetchedResultsController is a great way to react to changes occurring in your CoreData database. Using this technology, you can ask BMO to fetch or update the local model, without needing even to setup a handler, and then react to the changes automatically.

Please refer to Apple Documentation to implement and use an NSFetchedResultsController (https://developer.apple.com/documentation/coredata/nsfetchedresultscontroller).

happn provides a helper in order to use an NSFetchedResultsController in combination with a UITableView or a UICollectionView (https://github.com/happn-tech/CollectionAndTableViewUpdateConveniences).


## Advanced Usage
The bridge has a support for user info and metadata.

The user info are to be used inside the bridge and have a type you define. They are passed throughout the lifecycle of one request, from the conversion to the CoreData request into an `Operation`, to converting the results of the `Operation` to a `MixedRepresentation`, etc. You can use these user info to help you in the different tasks required in the bridge.

The metadata are additional information that are returned when the request returns from BMO.


## Possible Evolutions
- BMO+Realm
- BMO+RESTRealm
- BMO+SOAPCoreData
- …


## Credits
This project was originally created by [François Lamboley](https://github.com/Frizlab) while working at [happn](https://happn.com).

Many thanks to the iOS devs at happn, without whom open-sourcing this project would not have been possible:
- [Julien Séchaud](https://github.com/juliensechaud)
- [Thomas le Gravier](https://github.com/Thomaslegravier)
- [Romain le Drogo](https://github.com/StrawHara)
- [Thibault le Cornec](https://github.com/juliensechaud)
- [Romain Talleu](https://github.com/romaintalleu)
- [Mathilde Henriot](https://github.com/Ptitematil2)
