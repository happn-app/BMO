/*
 * RequestManager.swift
 * BMO
 *
 *
 * BMO means "Backed Managed Objects"
 * Other names considered:
 *    AMO (Asynchronous Managed Objects) <-- Actually a better name than BMO, but we love BMO!
 *    CADF (Custom Async Db Front)
 *    ACDC (Async Core Data Front)
 *    Core Data Cache for Backing Store
 *    BSF (Backing Store Front)
 *    FLCAIS (FL Custom Async Incremental Store (historic name))
 *
 *
 * BMO is a concept. Any Db Object can be a BMO.
 *
 * When saving a Db context through a BMORequestManager, the manager will query
 * its backing store to save the changes detected in the Db context.
 * Similarly, when executing a Db fetch request through the BMO manager, the
 * request will be executed synchronously first, then the manager will contact
 * its backing store to retrieve new object if applicable. The retrieved objects
 * will be inserted in the Db context and the client will be called
 * asynchronously to be notified of the update.
 *
 * This principle historically comes from Apple documentation about the
 * incremental data store. In theory, with incremental data stores, one should
 * be able to hook Core Data to a WebService (so they say). In practice, this
 * would be done using a separate Core Data stack to store the results of
 * previous requests from the WebService. When a fetch request is done on such a
 * stack, the incremental store would first query its private stack, and return
 * the results directly. Just before that, it would have launched a web
 * operation. When the operation finishes, it will send a notification so that
 * concerned clients can re-fetch their data (if possible blocking the creation
 * of a web operation to avoid infinite requests to the backing store…).
 * Even though it's not very practical, this solution _could_, at a first
 * glance, work. However, in practice, this solution is **not** compatible with
 * NSFetchedResultsController. (When the web operation finishes, the private CD
 * stack is updated, but the client context has no notification to be informed
 * of the changes. Re-fetching the new objects won't trigger the required
 * notifications for the fetched results controller to be aware new objects are
 * available in the context! Even refreshing the objects (which is in itself an
 * expensive operation) does not work if I recall correctly…)
 * After some thinking, I came up with the FLCAISRequestManager, which is the
 * ancestor of the BMORequestManager.
 * FYI, here is an implementation of the original “async incremental store” (the
 * project has been archived):
 * https://github.com/AFNetworking/AFIncrementalStore/tree/development
 *
 *                            .
 *                          `-----.
 *                     .::+++//////+++/::-.`
 *                .-:++////////////////////+++/::-.`
 *           .-:/+/////////////////////////////////+++/::--`
 *      .-:/+//////////////////////////////////////////////+++/::--`
 *   /ssoo+/////////////////////////////////////////////////////////++/::--`
 *  `h++++oosoo+++////////////////////////////////////////////////////////+s:
 *  `y+++++++++++oosoo+++/////////////////////////////////////////////++ooooo
 *  `y++++++++++++++++++oosoo+++//////////////////////////////////+oooooooooo
 *  `y+++++o++++o+++++++++++++++osoo+++//////////////////////++oooooooooooooo
 *  `y++++o/``..-:/++++o+++++++++++++++ooooo++///////////+ooooooooooooooooooo
 *  `y++++s-`````````..-:/++++++++++++++++++ooooooo+++oooooooooooooosyooooos+
 *  `y++++s.````````````````.--:/++++++++++++++++++yyoooooooosysooooshooooos/
 *  `y++++s.```````````````````````.--:/+++++++++++syooooooooshsooooooooooos/
 *  `y++++s```````````````````````````````.-/++++++syooooooooooooosooooshooy:
 *  `y++++s```````:.````````````````````````:o+++++ysooooooooooooohyooossooy:
 *  `y++++s```````s:````````````````````````:o+++++ysoooooossooooooooooooooy-
 *  `y++++s``````````````````````s/`````````/++++++ysoooooossooooooooosooooy.
 *  `y++++o``````````````````````/:`````````/++++++ysoooooooooossooooshsoooh.
 *  `y++++o```````````-------```````````````+++++++ysooooooooooyhooooooooooh`
 *  `y++++o`````````````````````````````````+++++++hsooooooooooooooooooooooh
 *  `y++++o`````````````````````````````````+++++++hooooooooooooossyhyoooooh
 *  `y++++o:...`````````````````````````````o++++++hooooooooosshdmNMMmoooooh
 *  `y++++++o++//:...```````````````````````o++++++hooooooooodMMMMMNMNoooooh
 *  `y++++++++++++oo++/:-.``````````````````o++++++hooooooooomMNmMMNMNoooooy
 *  `y+++++++++++++++++++o++/:-.````````````o++++++hooooooooomMMMMNMMdoooooy
 *  `y+++++mdhys+++++++++++++++o++//:.``````s++++++hooooooooohMMNdsyyooooooy
 *  `y+++++NNNNNNmdhso+++++++++++++++oo+//::s++++++hoooooooooossooossoooooos
 *  `y+++++oyhdmNNNNNNNmdyso+++++++++++++++++++++++hoooooooooooshdNMMsooooos
 *  `y+++++++++++syhmNNNNNNNNdhyo++++++++++++++++++hooooooooohNMMMMMMsooooos
 *  `y++++++++++++++++osydmNNNNNh++++oyys++++++++++hooooooooomNmMMMMdooooooo
 *  `y++++++++++++++++++++++oyhdy++++hmmm++++++++++hooooooooossNMMMMNooooooo
 *  `y++++++++++++++++++++++++++++++++syo++++++++++hoooooooooshmNMMMmooooos+
 *  `y+++++++++ssoo++++++++++++++++++++++++++++++++hoooooooooNMMNdhssooooos+
 *  `y++++++oss+-:ss++++++++++++sso++++++++++++++++hooooooooodhhdmddysoooos/
 *  `y++++++s::---+osoo++++++++s+sy++++++++++++++++hoooooooooyNMMMNMMmsooos/
 *  `y++++++o+/------os+++++++yo/sso+++++++++++++++hoooooooosNMMmsohMMyoooy:
 *  `y++++++++o+--/+/so+++++++++oss+++osyys++++++++hoooooooosNMMo+++Mmsoooy-
 *  `y+++++++++o++ss++++++++++++++++++yoohy++++++++hoooooooooymN++++dsooooy-
 *  `y++++oso++++++++++++++++++syhyyo++ooo+++++++++hoooooooooosh++++hoooooh`
 *  `y++++sddmh+osoo++++++++++yyyyyhho+++++++++++++hoooooooooooy++++hoooooh
 *  `y++++++ooo+sdmmdo++++++++hyyyyyhs++++++++++++ohoooooooooooy+++oyoooss/
 *   -/+++o+++++++oos+++++++++oyyyyhs+++++++++++++ohoooooooooooy+++sssso:`
 *    :oo/-/+++o++++++++++++++++ooo+++++++++++++++oyoooooooooooy+++ys/.
 *   -hssh.  `-:oysoo+++++++++++++++++++++++++++++oyoooooooooooy+sos`
 *   /yssyo-/ossyssyyys+++++++++++++++++++++++++++syooooooooossyoss/
 *   :ysssyysssssss+-.  `.-++o++++++++++++++++++++syoooooosss/.`-..
 *   `hssssssso/-.       -oso..-:/oso+++++++++++++syooooss+-
 *    +ssso/-`           ysssy `-+syyyyso+++++++++syosso:`
 *     --`               hssshosysssss/.`.-:+o++++yyo/.
 *                       ysssssssss/.         `-:/+-
 *                       ossssss/-
 *                       .sys+-
 *                         -
 *
 * Created by François Lamboley on 1/23/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation

import AsyncOperationResult



public final class RequestManager {
	
	public static var defaultBackOperationQueue: OperationQueue {
		let ret = OperationQueue()
		ret.name = "Default BMO Back Operation Queue (Network Queue)"
		/* Apple MVC Networking example sets 4 (was deployed on iOS 3).
		 * We want this queue to be used on operations that use URL Session and
		 * store their result in memory (said later in doc). We don't really need
		 * to limit the number of concurrent requests as the session correctly
		 * manages its resources, and writing stuff to memory is a lightweight
		 * operation.
		 *
		 * Limiting at Int.max works. However, testing showed limiting to a lower
		 * value results in a smoother application (main threads blocks less) and
		 * actually faster processing in general. */
		ret.maxConcurrentOperationCount = numberOfCores.flatMap{ $0*8 } ?? Int.max
		ret.qualityOfService = .background
		return ret
	}
	
	public static var defaultParseOperationQueue: OperationQueue {
		let ret = OperationQueue()
		ret.name = "Default BMO Parse Operation Queue (CPU Queue)"
		/* We use the default max concurrent operation count which should be equal
		 * to the best possible count for CPU operations depending on the current
		 * hardware.
		 * Below is a way to limit exactly to the current number of cores. */
//		if let n = numberOfCores {ret.maxConcurrentOperationCount = n}
		ret.qualityOfService = .utility
		return ret
	}
	
	public let backOperationQueue: OperationQueue
	public let parseOperationQueue: OperationQueue
	
	/** Helper to find a bridge if none is given when creating the operation for
	a given request with the request manager (automatic bridge retrieving).
	
	Required **only** if you plan on using the automatic bridge retrieving, which
	is not mandatory. */
	public var bridges: [Any]?
	
	public var defaultResultsImporterFactory: AnyBackResultsImporterFactory?
	
	/** Initializer for the RequestManager.
	
	- Parameter backOperationQueue: The queue on which the back operations (API
	calls) will be made. If nil, a default queue (well suited for back operations
	using URL Session) will be used. */
	public init(bridges bs: [Any]? = nil, resultsImporterFactory: AnyBackResultsImporterFactory? = nil, backOperationQueue bq: OperationQueue? = nil, parseOperationQueue pq: OperationQueue? = nil) {
		backOperationQueue = bq ?? RequestManager.defaultBackOperationQueue
		parseOperationQueue = pq ?? RequestManager.defaultParseOperationQueue
		
		bridges = bs
		defaultResultsImporterFactory = resultsImporterFactory
	}
	
	/** Creates and returns the operation for the given Db request. The operation
	can be executed only once. If you did not start it automatically when
	creating the operation, you can simply start it with `op.start()`, or by
	adding it to a queue.
	If you want to start the operation manually with `start()`, you’ll have to
	make sure all dependencies are finished before starting the operation. (As
	you would for any other operations.)
	The returned operation is guaranteed to have no dependencies. You can add
	dependencies if autoStart was set to false.
	
	You can also cancel the operation at any time with `op.cancel()`.
	
	- Important: The completion handler given in this method is called from the
	completion block of the operation. Do **not** change the completion block of
	the operation if you expect the handler to be called.
	
	- Parameter bridge: The bridge to use to create and parse the API
	request/results. If nil, the first bridge of the correct type in the bridges
	property will be used.
	- Parameter resultsImporterFactory: The results importer factory to use to
	create the results importer that'll be used to import the results of the
	bridge operation to the database. */
	@discardableResult
	public func operation<RequestType, BridgeType>(forBackRequest request: RequestType, withBridge bridge: BridgeType? = nil, resultsImporterFactory: AnyBackResultsImporterFactory? = nil, autoStart: Bool, handler: ((_ response: AsyncOperationResult<BackRequestResult<RequestType, BridgeType>>) -> Void)? = nil) -> BackRequestOperation<RequestType, BridgeType> {
		let bridge = getBridge(from: bridge)
		let importerFactory = resultsImporterFactory ?? defaultResultsImporterFactory
		let operation = BackRequestOperation(request: request, bridge: bridge, importer: importerFactory?.createResultsImporter(), backOperationQueue: backOperationQueue, parseOperationQueue: parseOperationQueue, requestManager: self)
		if let handler = handler {
			operation.completionBlock = {
				operation.completionBlock = nil /* TBT: Can this be removed? */
				handler(operation.result)
			}
		}
		
		if autoStart {operation.start()}
		return operation
	}
	
	public func cancelAllOperations() {
		NotificationCenter.default.post(name: .BMORequestManagerCancelAllBackRequestOperations, object: self)
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private func getBridge<BridgeType: Bridge>(from bridge: BridgeType?) -> BridgeType {
		if let bridge = bridge {return bridge}
		
		for bridge in bridges! {
			if let bridge = bridge as? BridgeType {
				return bridge
			}
		}
		
		fatalError("Could not find a bridge matching the given requirements.")
	}
	
}


extension NSNotification.Name {
	
	static let BMORequestManagerCancelAllBackRequestOperations = NSNotification.Name(rawValue: "com.happn.BMO.notif_names.cancel_all_back_request_operations")
	
}
