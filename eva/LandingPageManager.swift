//
//  LandingPageManager.swift
//  eva
//
//  Created by Panayiotis Stylianou on 21/11/2015.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation
import CoreData

protocol LandingPageProtocol
{
   func willRequest(request: BatchRequest)
   func didRequest(request: BatchRequest, success: Bool)
   func dataUpdated()
}

final class LandingPageManager: NSObject, ServerResponseProtocol
{
   // MARK: - Constants

   static let LP_DEFAULT_START_POSITION: Int = 0

   enum FeedsDataKeys: String
   {
      case ChannelsFeed = "channels"
      case FriendsFeed = "friends"
      case PublicFeed = "public"
      case LikesFeed = "likes"
      case MyFeed = "my_feed"

      static let values = [ChannelsFeed, FriendsFeed, PublicFeed, LikesFeed, MyFeed]
   }

   // MARK: - Private Properties

   private var _operationsQueue: dispatch_queue_t = dispatch_queue_create("co.eva.landing_page_queue", DISPATCH_QUEUE_SERIAL)

   // MARK: - Public Properties

   var delegate: LandingPageProtocol?
   var assets: [String:Asset] = [:]
   var channels: [ChannelItem] = [ChannelItem]()
   var managedContext: NSManagedObjectContext!

   var startPosition: Int {
      get {
         return NSUserDefaults.standardUserDefaults().hasKey(UserDefaultSettings.US_START_INDEX) ? NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultSettings.US_START_INDEX) : LandingPageManager.LP_DEFAULT_START_POSITION
      }
      set {
         NSUserDefaults.standardUserDefaults().removeObjectForKey(UserDefaultSettings.US_START_INDEX)
         NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: UserDefaultSettings.US_START_INDEX)
         NSUserDefaults.standardUserDefaults().synchronize()
      }
   }

   // MARK: - Delegates

   lazy var serverResponse: ServerResponse = ServerResponse(delegate: self)
   lazy var networkDelegate: UnsafeMutablePointer<Void> =  self.serverResponse.networkDelegate

   // MARK: - Public methods

   func fetchDataForFeeds(feeds: FeedsDataKeys...)
   {
      var batchRequest: BatchRequest = BatchRequest()
      for feed in feeds
      {
         let request: BatchRequestItem
         switch feed
         {
         case .ChannelsFeed:
            request = getChannelsRequest()

         case .FriendsFeed:
            request = getFriendsRequest()

         case .PublicFeed:
            request = getPublicRequest()

         case .LikesFeed:
            request = getLikesRequest()

         case .MyFeed:
            request = getMyFeedRequest()

         }
         batchRequest.addRequest(request)
      }
      dispatch_async(_operationsQueue)
      {
         if batchRequest.count == 5
         {
            let path1: NSString = batchRequest.requestsItems[0].path
            let method1: NSString = batchRequest.requestsItems[0].method!.rawValue as String
            let key1: NSString = batchRequest.requestsItems[0].key!

            let path2: NSString = batchRequest.requestsItems[1].path
            let method2: NSString = batchRequest.requestsItems[1].method!.rawValue as String
            let key2: NSString = batchRequest.requestsItems[1].key!

            let path3: NSString = batchRequest.requestsItems[2].path
            let method3: NSString = batchRequest.requestsItems[2].method!.rawValue as String
            let key3: NSString = batchRequest.requestsItems[2].key!

            let path4: NSString = batchRequest.requestsItems[3].path
            let method4: NSString = batchRequest.requestsItems[3].method!.rawValue as String
            let key4: NSString = batchRequest.requestsItems[3].key!

            let path5: NSString = batchRequest.requestsItems[4].path
            let method5: NSString = batchRequest.requestsItems[4].method!.rawValue as String
            let key5: NSString = batchRequest.requestsItems[4].key!

            BatchRequestAction5(path1.UTF8String, method1.UTF8String, key1.UTF8String, path2.UTF8String, method2.UTF8String, key2.UTF8String, path3.UTF8String, method3.UTF8String, key3.UTF8String, path4.UTF8String, method4.UTF8String, key4.UTF8String, path5.UTF8String, method5.UTF8String, key5.UTF8String, self.networkDelegate)
         }
         else
         {
            fatalError("Not enough requests")
         }
      }
   }

   func fetchEvaNotifications() -> EvaNotifications? { return EvaNotification.fetchNotifications(managedContext) }

   func clearNotifications() { EvaNotification.deleteAll(managedContext) }

   // MARK: - Private methods

   private func getRequestUserId() -> String
   {
      if let loggedInUserId = SessionManager.sharedInstance.loggedInUser.userId
      {
         return loggedInUserId
      }
      else
      {
         if let featuredUserId = GlobalSettingsManager.sharedInstance.getFeaturedUserId()
         {
            return featuredUserId
         }
      }

      return ""
   }

   private func getChannelsRequest() -> BatchRequestItem
   {
      return BatchRequestItem(path: URLUtils.urlForChannelsRequest(), method: .Get, body: nil, key: FeedsDataKeys.ChannelsFeed.rawValue)
   }

   private func getFriendsRequest() -> BatchRequestItem
   {
      return BatchRequestItem(path: URLUtils.urlForFriendsRequest(getRequestUserId(), 1), method: .Get, body: nil, key: FeedsDataKeys.FriendsFeed.rawValue)
   }

   private func getPublicRequest() -> BatchRequestItem
   {
      return BatchRequestItem(path: URLUtils.urlForPublicRequest(1), method: .Get, body: nil, key: FeedsDataKeys.PublicFeed.rawValue)
   }

   private func getLikesRequest() -> BatchRequestItem
   {
      return BatchRequestItem(path: URLUtils.urlForLikesRequest(getRequestUserId(), 1), method: .Get, body: nil, key: FeedsDataKeys.LikesFeed.rawValue)
   }

   private func getMyFeedRequest() -> BatchRequestItem
   {
      return BatchRequestItem(path: URLUtils.urlForUserRequest(getRequestUserId(), 1), method: .Get, body: nil, key: FeedsDataKeys.MyFeed.rawValue)
   }

   // MARK: - Shared instance

   class var sharedInstance: LandingPageManager {
      struct Static {
         static var instance: LandingPageManager?
         static var token: dispatch_once_t = 0
      }

      dispatch_once(&Static.token) { Static.instance = LandingPageManager() }

      return Static.instance!
   }
}

extension LandingPageManager
{
   func errorResponse(networkError: ServerErrorType?, extraData: [String:AnyObject]?) { EvaLogger.sharedInstance.logMessage("ResponseError: \(networkError?.rawValue)", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonString: String) { EvaLogger.sharedInstance.logMessage("jsonString not implemented", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonDictionary: JsonDictionary) { EvaLogger.sharedInstance.logMessage("jsonDictionary not implemented", .Error) }

   func serverResponse(responseFrom: ServerResponseType, nextObject: String?, jsonDictionaryArray: [JsonDictionary])
   {
      for data: JsonDictionary in jsonDictionaryArray
      {
         let key: String = data["key"] as! String
         let results: [JsonDictionary] = data["results"] as! [JsonDictionary]
         if results.isEmpty == false
         {
            if key == FeedsDataKeys.ChannelsFeed.rawValue
            {
               channels = results.map { ChannelItem($0) }
            }
            else
            {
               assets[key] = Asset(possibleAsset: results.first!)
            }
         }
         else
         {
            assets[key] = nil
         }
      }
      channels = channels.sort({ $0.channelSortKey < $1.channelSortKey})
      if channels.isEmpty == false
      {
         CoreSpotlightService.indexChannels(channels, onSuccess: { () -> Void in
            EvaLogger.sharedInstance.logMessage("Channels added to spotlight")
            }, onError: { (error) -> Void in
               EvaLogger.sharedInstance.logMessage("Error while adding channels to index: \(error.localizedDescription)", .Error)
         })
      }
      self.delegate?.dataUpdated()
   }
}
