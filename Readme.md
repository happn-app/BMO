# BMOSpotifyClient

This project is a light demo of [BMO](https://github.com/happn-app/BMO) implementation using Spotify API.

# BMO (wip readme)

- [Presentation](#presentation)
- [Getting started](#getting-started)
    - [Template files](#template-files)
    - [CoreData](#coredata)
    - [BMO Operation](#bmo-operation)
    - [BMO Bridge](#bmo-bridge)
    - [Usage](#usage)
- [Advanced Usage](#advanced-usage)

## Presentation

BMO or Backed Managed Objects was made for linking any local database (CoreData, Realm, etc.) to any API (REST, SOAP, etc.).
In this example we use a CoreData stack and BMO link our local DB to our API.
<br />
Schematic present how you communicate with your CoreData stack and BMO intercept your request to fetch fresh new data from API and inject results in your DB.
<br />
<br />
For example :
- 1./ Fetch list of user from CoreData
- 2./ Get local result
- 2./ BMO intercept your fetch request
- 3./ BMO ask to API list of users
- 4./ BMO gets results from API
- 5./ BMO insert fresh new results in your DB
- 6./ CoreData notifiy your fetch result controller with fresh new users
<br />
Schematic sequence of a classic fetch request with BMO with a CoreData DB:
<img src="https://github.com/happn-app/BMOSpotifyClient/blob/master/Ressources/bmo-schema-front.png" width="310">

## Getting started

Follow this instructions to setup your own project with BMO in only few minutes!
<br />
- Initialize your project with CoreData usage
- Import BMO with carthage
```swift
//  Cartfile

github "happn-app/BMO" "master"
github "Alamofire/Alamofire" "master" // Optional. Use with template files.
```
- Setup your project with carthage builds. ([Carthage quick start](https://github.com/Carthage/Carthage#quick-start))

### Template files

You can easily configure this three files to perform your first light BMO implementation. This following easy-to-use will guide you to achieve your first light implementation!
<br />
Download an import [template demo files](https://github.com/happn-app/BMOSpotifyClient/tree/master/Template) in your projet.
- AsyncOperation
- DemoBMOOperation
- DemoBMOBridge

### CoreData

- Prepare your CoreData model with your entities and attributes (cf example)
- Set a 'bmoId' attribute as name of your unique key value of each entity
- Setup your CoreData context from persistent container in AppDelegate
```swift
//  AppDelegate.swift

private(set) var context: NSManagedObjectContext!

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    /* Setup CoreData context */
    let container = NSPersistentContainer(name: "DemoBMO") // Replace 'DemoBMO' by your xcdatamodeld name
    container.loadPersistentStores(completionHandler: { _, _ in })
    context = container.viewContext

    [...]
}
```
CoreData model Example:
<br />
<img src="https://github.com/happn-app/BMOSpotifyClient/blob/master/Ressources/bmo-demo-xcdatamodel.png" width="300">

### BMO Operation

BMO use Operation object to perform request. You need to implement your own Operation to perform BMO request and retrieve results.
<br />
DemoBMOOperation provide you a practical example, we use an [AsyncOperation](https://gist.github.com/Thomaslegravier/03346fc9a2e7bd065e5ea461a404b43c) implementation and [Alamofire](https://github.com/Alamofire/Alamofire) to perform calls.
<br />
You can easily use native URLRequestSession and URLRequestOperation instead Alamofire if you want, just update DemoBMOOperation startOperation block.
<br />
- Update "apiURL" path with your own API path in DemoBMOOperation class
```swift
//  DemoBMOOperation.swift

static let apiURL: URL = URL(string: "https://your-api-path.com")!
```
- Add your access token if necessary
```swift
//  DemoBMOOperation.swift

override func startOperation() -> ((@escaping (AsyncOperation.Result?) -> Void) -> ())? {
    return { (operationEnded) in
        var authenticatedRequest = self.request
        authenticatedRequest.addValue("Bearer \("your-access-token")", forHTTPHeaderField: "Authorization")

        Alamofire.request(authenticatedRequest).validate().responseJSON{ response in
            if let json = response.result.value as? [String: Any?] {
                operationEnded(.success(json))
            } else {
                operationEnded(.error(response.error ?? Err.unknownError))
            }
        }
    }
}
```

### BMO Bridge

A bridge is the interface between your local CoreData database and API. This bridge is your major settings file to configure and guide BMO for in/out requests.
<br />
- Prepare your mapping in DemoBMOBridge <br />
To link your local database to your API you need to communicate your mapping to BMO. This mapping define the link between your local and distant datas.
Define your mapping in a RestMapper object for a simple usage in all your bridge methods.<br />
Update this mapping with your own needs.
```swift
//  DemoBMOBridge.swift

private lazy var restMapper: RESTMapper<NSEntityDescription, NSPropertyDescription> = {
    let urlTransformer = RESTURLTransformer()
    let boolTransformer = RESTBoolTransformer()
    let dateTransformer = RESTDateAndTimeTransformer()
    let intTransformer = RESTNumericTransformer(numericFormat: .int)

    let userMapping: [_RESTConvenienceMappingForEntity] = [
        .restPath("/users"),
        .uniquingPropertyName("bmoId"),
        .propertiesMapping([
            "bmoId":           [.restName("id")],
            "username":        [.restName("unque_name")],
            "firstname":       [.restName("firstname")],
            "lastname":        [.restName("lastname")],
            "registerDate":    [.restName("register_date"), .restToLocalTransformer(dateTransformer)],
            "profileUrl":      [.restName("link"), .restToLocalTransformer(urlTransformer)],
            "profilePictures": [.restName("profile_pictures")],
            "isActive":        [.restName("active"), .restToLocalTransformer(boolTransformer)]
        ])
    ]

    let imageMapping: [_RESTConvenienceMappingForEntity] = [
        .propertiesMapping([
            "height": [.restName("height"), .restToLocalTransformer(intTransformer)],
            "width":  [.restName("width"), .restToLocalTransformer(intTransformer)],
            "url":    [.restName("url"), .restToLocalTransformer(urlTransformer)]
        ])
    ]

    return RESTMapper(
        model: dbModel,
        defaultPaginator: RESTOffsetLimitPaginator(),
        convenienceMapping: [
            "User":  userMapping,
            "Image": imageMapping
        ]
    )
}()
```
- Results from fetch request <br />
You need pass to BMO your fetch request results, so he can process them.<br />
Update DemoBridge to provide JSON key where your results are.
```swift
//  DemoBMOBridge.swift

func remoteObjectRepresentations(fromFinishedOperation operation: BackOperationType, userInfo: UserInfoType) throws -> [RemoteObjectRepresentationType]? {
    switch operation.results {
    case .success(let success): return success["items"] as? [DemoBMOOperation.RemoteObjectRepresentationType] // Replace "items" by your key data in JSON results
    case .error(let e):         throw Err.operationError(e)
    }
}
```
<br />
Ok so now we have an operational bridge with a mapping. Let's use it !

### Usage

- Prepare your request manager in the AppDelegate
```swift
//  AppDelegate.swift

import BMO

private(set) var requestManager: RequestManager!

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    [...]

    /* Setup BMO request manager */
    requestManager = RequestManager(bridges: [DemoBMOBridge(dbModel: container.managedObjectModel)], resultsImporterFactory: DemoBMOBridge.DemoBMOImporter())
}
```
- Implement a fetch result controller <br />
Template files provide you a DemoUserListViewController. <br />
This controller use a fetch result controller with a CoreData fetch request:
```swift
//  DemoUserListViewController.swift

let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "%K != NULL", #keyPath(User.username))
fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(User.username), ascending: true)]
fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: AppDelegate.shared.context!, sectionNameKeyPath: nil, cacheName: nil)
fetchedResultsController?.delegate = self
try! self.fetchedResultsController?.performFetch()
```
- Perform data fetch
```swift
//  DemoUserListViewController.swift

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
That's it 🥳, you can now run your project and your data will be automatically display in your table view.
<br />
<br />
Demo files are given as simple template. Update mapping and configuration to fit your API and local data model.
## Advanced Usage
<strong>TODO:</strong>
- Insert request
- Update request
- Delete request
- Metadata
- UserInfos
- RemoteObjectRepresentations
- MixedRepresentation
- Advanced RestMapper
- Transformers
- Paginator
    - RESTOffsetLimitPaginator
    - RESTMaxIdPaginator
