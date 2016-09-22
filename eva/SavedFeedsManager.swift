//
//  SavedFeedsManager.swift
//  eva
//
//  Created by Panayiotis Stylianou on 16/11/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation

protocol SavedFeedsManagerProtocol
{
   func didFetchFeedsList(feeds: [SavedFeedSimple])
   func didFetchFeed(feed: SavedFeed)
   func errorFetchingFeed()
}

class SavedFeedsManager
{
   static let sharedInstance: SavedFeedsManager = SavedFeedsManager()

   lazy var serverResponse: ServerResponse = ServerResponse(delegate: self)
   lazy var networkDelegate: UnsafeMutablePointer<Void> =  self.serverResponse.networkDelegate

   var delegate: SavedFeedsManagerProtocol?

   func fetchFeedList(userId: String, limit: Int)
   {
      SearchSavedFeeds((userId as NSString).UTF8String, nil, nil, ("name" as NSString).UTF8String, nil, Int32(limit), self.networkDelegate)
   }

   func fetchFeedListForSearch(searchTerm: String, limit: Int)
   {
      SearchSavedFeeds(nil, (searchTerm as NSString).UTF8String, nil, ("name" as NSString).UTF8String, nil, Int32(limit), self.networkDelegate)
   }

   func fetchFeed(feedId: String)
   {
      GetSavedFeed((feedId as NSString).UTF8String, self.networkDelegate)
   }

   func createFeed(feedName: String, assetIds: String...)
   {
      if assetIds.isEmpty
      {
         CreateSavedFeed((feedName as NSString).UTF8String, nil, self.networkDelegate)
      }
      else
      {
         CreateSavedFeed((feedName as NSString).UTF8String, (assetIds.joinWithSeparator(":") as NSString).UTF8String, self.networkDelegate)
      }
   }

   func deleteFeed(feed: SavedFeed) { deleteFeed(feed.feedId) }

   func deleteFeed(feedId: String)
   {
      DeleteSavedFeed((feedId as NSString).UTF8String, self.networkDelegate)
   }

   func updateFeed(feed: SavedFeed)
   {
      UpdateSavedFeed((feed.feedId as NSString).UTF8String, (feed.feedName as NSString).UTF8String, (feed.feedItems.map({ $0.id! }).joinWithSeparator(":") as NSString).UTF8String, self.networkDelegate)
   }
}

extension SavedFeedsManager: ServerResponseProtocol
{
   func errorResponse(networkError: ServerErrorType?, extraData: [String:AnyObject]?) { EvaLogger.sharedInstance.logMessage("ServerResponse error: \(networkError?.description)", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonString: String) { EvaLogger.sharedInstance.logMessage("jsonString not implemented", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonDictionary: JsonDictionary)
   {
      switch responseFrom
      {
      case .GetSavedFeed:
         let feed = SavedFeed(data: jsonDictionary)
         guard let savedFeed = feed
            else {
               delegate?.errorFetchingFeed()
               return
         }
         delegate?.didFetchFeed(savedFeed)

      case .CreateSavedFeed:
         EvaLogger.sharedInstance.logMessage("SavedFeed created")

      case .UpdateSavedFeed:
         EvaLogger.sharedInstance.logMessage("Updated feed")

      default:
         fatalError("Response \(responseFrom.rawValue) not parsed")
      }
   }

   func serverResponse(responseFrom: ServerResponseType, nextObject: String?, jsonDictionaryArray: [JsonDictionary])
   {
      switch responseFrom
      {
      case .SearchSavedFeeds:
         var feeds: [SavedFeedSimple] = []
         for feedData in jsonDictionaryArray
         {
            let feed = SavedFeedSimple(data: feedData)
            if let savedFeed = feed
            {
               feeds.append(savedFeed)
            }
         }
         delegate?.didFetchFeedsList(feeds)

      default:
         EvaLogger.sharedInstance.logMessage("jsonDictionaryArray not implemented for response: \(responseFrom.rawValue)", .Error)
      }
   }
}
