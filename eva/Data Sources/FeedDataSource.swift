//
//  FeedDataSource.swift
//  eva
//
//  Created by Panayiotis Stylianou on 06/12/2015.
//  Copyright (c) 2014 Forbidden Technologies PLC. All rights reserved.
//

import Foundation

class FeedDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate
{
   // MARK: - ServerResponse

   lazy var serverResponse:ServerResponse = ServerResponse(delegate:self)
   lazy var networkDelegate: UnsafeMutablePointer<Void> = self.serverResponse.networkDelegate

   // MARK: - Delegates

   var delegate: DataSourceProtocol?
   var headerViewDelegate: CollectionViewHeaderProtocol?

   // MARK: - Properties

   var count: Int { return self.feed.count }
   var isEmpty: Bool { return self.feed.isEmpty }
   var nextObject: String?
   var firstNextObject: String?
   var numberOfFetchedAssets: Int = 0
   var firstLoad: Bool = false
   var numberOfNewElements: Int = 0
   var lastEndTime: Int64 = 0
   var isLoading: Bool = false
   var dataSource: Assets {
      get { return feed.dataSource }
      set { feed.dataSource = newValue }
   }
   var playForwardInTime: Bool = false

   // MARK: - Private properties

   lazy private var feed: Feed = self.createFeed()

   // MARK: - Initializers

   convenience init(delegate: DataSourceProtocol?) { self.init(delegate: delegate, headerViewDelegate: nil) }

   init(delegate: DataSourceProtocol?, headerViewDelegate: CollectionViewHeaderProtocol?)
   {
      self.delegate = delegate
      self.headerViewDelegate = headerViewDelegate
   }

   func createFeedWithAsset(asset: Asset)
   {
      self.feed = self.createFeed(asset)
      self.firstLoad = true
      self.delegate?.refreshData()
   }

   // MARK: - Search methods

   func searchCountWithSearchTerm(searchTerm: String)
   {
      BridgeObjC.searchForFeedWithSearchTerm(searchTerm, start: nil, limit: Int32(Constants.SEARCH_FEED_LIMIT), delegate: self.networkDelegate)
   }

   /**
   Search for a feed created from the results of the search

   - parameter searchTerm: String The search string
   - parameter firstLoad:  Bool If it's the first load of the feed
   - parameter limit:      Int32 the limit of the request
   */
   func searchForFeedWithSearchTerm(searchTerm: String, firstLoad: Bool = false, limit: Int32 = Constants.FIRST_SEARCH_LIMIT)
   {
      self.firstLoad = firstLoad
      if firstLoad
      {
         BridgeObjC.searchForFeedWithSearchTerm(searchTerm, start: nil, limit: limit, delegate: self.networkDelegate)
      }
      else
      {
         if let nextLoad = self.nextObject
         {
            BridgeObjC.searchForFeedWithSearchTerm(searchTerm, start: nextLoad, limit: limit, delegate: self.networkDelegate)
         }
      }
   }

   /**
   Searchs for the assets of the logged in user. The difference between
   a normal user search, is that not fully uploaded clips are included
   in the results

   - parameter userId:    String The userId to search for
   - parameter firstLoad: Bool If it's the first load of the feed
   - parameter limit:     Int32 The limit of the request
   */
   func searchForUserIdFeed(userId: String?, firstLoad: Bool = false, limit: Int32 = Constants.FIRST_SEARCH_LIMIT)
   {
      self.firstLoad = firstLoad
      if firstLoad
      {
         BridgeObjC.searchFeedsWithUserId(userId, start: nil, limit: limit, includeNotUploaded: true, delegate: self.networkDelegate)
      }
      else
      {
         if let nextLoad = self.nextObject
         {
           BridgeObjC.searchFeedsWithUserId(userId, start: nextLoad, limit: limit, includeNotUploaded: true, delegate: self.networkDelegate)
         }
      }
   }

   func searchForUserIdFeedForPlayback(userId: String?, firstLoad: Bool = false, limit: Int32 = Constants.FIRST_SEARCH_LIMIT)
   {
      self.firstLoad = firstLoad
      if firstLoad
      {
         BridgeObjC.searchFeedsWithUserId(userId, start: nil, limit: limit, includeNotUploaded: false, delegate: self.networkDelegate)
      }
      else
      {
         if let nextLoad = self.nextObject
         {
            BridgeObjC.searchFeedsWithUserId(userId, start: nextLoad, limit: limit, includeNotUploaded: false, delegate: self.networkDelegate)
         }
      }
   }

   func searchForFriendsFeed(userId: String?, firstLoad: Bool = false, limit: Int32 = Constants.FIRST_SEARCH_LIMIT)
   {
      self.firstLoad = firstLoad
      if firstLoad
      {
         BridgeObjC.assetsFromFriendsOf(userId, start: nil, limit: limit, sortBy: "reverseDate", delegate: self.networkDelegate)
      }
      else
      {
         if let nextLoad = self.nextObject
         {
            BridgeObjC.assetsFromFriendsOf(userId, start: nextLoad, limit: limit, sortBy: "reverseDate", delegate: self.networkDelegate)
         }
      }
   }


   /**
   Searchs for the assets of the logged in user. Not fully uploaded clips are not included
   in the results

   - parameter userId:    String The userId to search for
   - parameter firstLoad: Bool If it's the first load of the feed
   - parameter limit:     Int32 The limit of the request
   */
   func searchForOtherUserFeed(userId: String?, firstLoad: Bool = false, limit: Int32 = Constants.FIRST_SEARCH_LIMIT)
   {
      self.firstLoad = firstLoad
      if firstLoad
      {
         BridgeObjC.searchFeedsWithUserId(userId, start: nil, limit: limit, includeNotUploaded: false, delegate: self.networkDelegate)
      }
      else
      {
         if let nextLoad = self.nextObject
         {
            BridgeObjC.searchFeedsWithUserId(userId, start: nextLoad, limit: limit, includeNotUploaded: false, delegate: self.networkDelegate)
         }
      }
   }

   /**
   Finds the feed of the assets the user have liked.

   - parameter userId:    String The userId to search for
   - parameter firstLoad: Bool If it's the first load of the feed
   - parameter limit:     Int32 The limit of the request
   */
   func searchForAssetsUserLikes(userId: String?, firstLoad: Bool = false, limit: Int32 = Constants.FIRST_SEARCH_LIMIT)
   {
      self.firstLoad = firstLoad
      if firstLoad
      {
         BridgeObjC.userGetAssetsLikedByUserId(userId, start: nil, limit: limit, sortBy: "reverseDate", delegate: self.networkDelegate)
      }
      else
      {
         if let nextLoad = self.nextObject
         {
            BridgeObjC.userGetAssetsLikedByUserId(userId, start: nextLoad, limit: limit, sortBy: "reverseDate", delegate: self.networkDelegate)
         }
      }
   }

   func searchForSavedFeed(savedFeedId: String )
   {
      GetSavedFeed((savedFeedId as NSString).UTF8String, networkDelegate)
   }

   func searchForChannel(channel: ChannelItem, firstLoad: Bool = false, limit: Int32 = Constants.FIRST_SEARCH_LIMIT)
   {
      searchForChannelId(channel.channelId, firstLoad: firstLoad, limit: limit)
   }

   /**
   Searchs for the assets in the channel

   :param: channel   ChannelItem
   :param: firstLoad Bool
   :param: limit     Int32
   */
   func searchForChannelId(channelId: String, firstLoad: Bool = false, limit: Int32 = Constants.FIRST_SEARCH_LIMIT)
   {
      self.firstLoad = firstLoad

      if firstLoad
      {
         BridgeObjC.searchChannel(channelId, start: nil, limit: limit, delegate: self.networkDelegate)
      }
      else
      {
         if let nextObject = nextObject
         {
            BridgeObjC.searchChannel(channelId, start: nextObject, limit: limit, delegate: self.networkDelegate)
            EvaLogger.sharedInstance.logMessage("Asking for channel items with nextObject: \(self.nextObject) and limit \(limit)", .Custom)
         }
         else
         {
            EvaLogger.sharedInstance.logMessage("No next object", .Error)
         }
      }
   }

   /**
   Searchs for asset without any filter. A.K.A. EvaFeed

   - parameter firstLoad: Bool If it's the first load of the feed
   - parameter limit:     Int32 The limit of the request
   */
   func searchForFeedUnfiltered(firstLoad: Bool = false, limit: Int32 = Constants.FIRST_SEARCH_LIMIT, forwardInTime: Bool = false, newAssetsIncluded: Bool = false)
   {
      self.playForwardInTime = forwardInTime
      if forwardInTime
      {
         if firstLoad
         {
            BridgeObjC.searchFeedUnfilteredForwardStart(nil, limit: limit, offset: -limit, unviewedOnly: true, delegate: self.networkDelegate)
            numberOfFetchedAssets += Int(limit)
            EvaLogger.sharedInstance.logMessage("Asking for EvaFeed items with offset: \(-limit) and limit \(limit) and total number of fetched assets: \(numberOfFetchedAssets)", .Custom)
            self.firstLoad = true
         }
         else
         {
            BridgeObjC.searchFeedUnfilteredForwardStart(nil, limit: limit, offset: -(limit + numberOfFetchedAssets), unviewedOnly: true, delegate: self.networkDelegate)
            numberOfFetchedAssets += Int(limit)
            EvaLogger.sharedInstance.logMessage("Asking for EvaFeed items with offset: \(-(limit + numberOfFetchedAssets)) and limit \(limit) and total number of fetched assets: \(numberOfFetchedAssets)", .Custom)
            self.firstLoad = false
         }
      }
      else
      {
         self.firstLoad = firstLoad

         if firstLoad
         {
            BridgeObjC.searchFeedUnfilteredStart(nil, limit: limit, unviewedOnly: true, delegate: self.networkDelegate)
         }
         else
         {
            if newAssetsIncluded
            {
               if let firstNext = firstNextObject
               {
                  BridgeObjC.searchFeedUnfilteredForwardStart(firstNext, limit: limit, offset: -limit, unviewedOnly: true, delegate: self.networkDelegate)
               }
            }
            if let nextObject = nextObject
            {
               BridgeObjC.searchFeedUnfilteredStart(nextObject, limit: limit, unviewedOnly: true, delegate: self.networkDelegate)
               EvaLogger.sharedInstance.logMessage("Asking for EvaFeed items with nextObject: \(self.nextObject) and limit \(limit)", .Custom)
            }
            else
            {
               EvaLogger.sharedInstance.logMessage("No next object", .Error)
            }
         }
      }
   }

   /**
   Gets new assets since the specified date.

   - parameter limit:        Int32
   - parameter unviewedOnly: Bool
   */
   func searchForFeedUnfilteredNewAssets(limit: Int32, unviewedOnly: Bool)
   {
      EvaLogger.sharedInstance.logMessage("Asking for new assets")
      BridgeObjC.searchFeedUnfilteredStart(nil, limit: limit, unviewedOnly: true, delegate: self.networkDelegate)
   }

   // MARK: - Assets operations

   func nextAsset(currentAsset: Asset, isForward:Bool) -> Asset? { return self.dataSource.findNext(currentAsset, isForward: isForward) }

   func findNextUserAsset(currentAsset: Asset, forward: Bool = true) -> Asset?
   {
      if self.dataSource.isEmpty == false
      {
         var loopCounter = 0
         var asset: Asset = currentAsset
         var nextFound = false

         while loopCounter < self.dataSource.count
         {
            if let nextAsset = self.dataSource.findNext(asset, isForward: forward)
            {
               asset = nextAsset
               if currentAsset.userId != asset.userId
               {
                  nextFound = true
                  break
               }
            }
            ++loopCounter
         }

         return nextFound ? asset : self.dataSource.findNext(currentAsset, isForward: forward)!
      }

      return nil
   }

   func remainingAssetsFromAsset(currentAsset: Asset?) -> Int
   {
      if let asset = currentAsset
      {
         if let index = self.dataSource.indexOf(asset)
         {
            return self.count - index
         }
      }

      return 0
   }

   // MARK: - UICollectionViewDataSource

   func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
   {
      let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: HEADER_VIDEO_COLLECTION, forIndexPath: indexPath) as! HeaderVideoCollection
      if self.isEmpty == false
      {
         headerView.playButton?.hidden = false
         headerView.title?.text = NSLocalizedString("search result", comment: "Header view search title")
         let localizedHeader = NSLocalizedString("matching moments", comment: "Matching moments")
         headerView.videosCount?.text = "\(self.count) \(localizedHeader)"
         headerView.indexPath = indexPath
         headerView.delegate = self.headerViewDelegate
      }
      else
      {
         headerView.playButton?.hidden = true
         headerView.title?.text = String()
         headerView.videosCount?.text = String()
         headerView.indexPath = nil
         headerView.delegate = nil
      }
      return headerView
   }

   func collectionView(collectionView: UICollectionView, numberOfItemsInSection: Int) -> Int { return self.count }

   func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
   {
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier(VIDEOS_CELL, forIndexPath: indexPath) as! VideosCell
      let asset = self.dataSource[indexPath.row] as Asset
      cell.backgroundColor = UIColor.grayColor()
      asset.setThumbnailImageForImageView(&cell.thumbnail!)

      return cell
   }

   func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
   {
      cell.contentView.alpha = 0.2;
      UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3, options: .CurveEaseInOut, animations: ({
            cell.contentView.alpha = 1;
            cell.contentView.layer.shadowOffset = CGSizeMake(0, 0);
         }), completion: nil)
   }

   func createFeed(feed feed: Feed) { self.checkFeed(feed: feed) }

   // MARK: - Player methods

   private func isPlayingDetailValid(playingDetail: PlayingDetails) -> Bool { return playingDetail.startTime > 0 && playingDetail.endTime > 0 }

   private func addAssetToPlaylist(asset: Asset, player: PlayerWrapper, cleanLoad: Bool = false) -> PlayingDetails?  { return cleanLoad ? player.play(asset, startPlayback: true) : player.append(asset) }

   func loadSingleAssetInPlayer(player: PlayerWrapper)
   {
      if let asset: Asset = dataSource.first
      {
         if let playingDetails = addAssetToPlaylist(asset, player: player, cleanLoad: true)
         {
            asset.endTime = playingDetails.endTime
            asset.startTime = 0

            EvaLogger.sharedInstance.logMessage("Asset loaded in feed with ID: \(asset.id) and EDL: \(asset.edlId) startTime: \(asset.startTime) endTime: \(asset.endTime)")
         }
         else
         {
            EvaLogger.sharedInstance.logMessage("Asset with end time 0: \(asset.edlId)", .Error)
         }
      }
   }

   func fullLoad(player: PlayerWrapper)
   {
      guard dataSource.isEmpty == false else {
         EvaLogger.sharedInstance.logMessage("No assets to load")
         return
      }
      var firstOne: Bool = true

      for asset in dataSource
      {
         if let playingDetails = addAssetToPlaylist(asset, player: player, cleanLoad: firstOne)
         {
            asset.endTime = playingDetails.endTime
            asset.startTime = (firstOne == false && isPlayingDetailValid(playingDetails) == false) ? lastEndTime : playingDetails.startTime

            firstOne = false
            if playingDetails.endTime > 0
            {
               lastEndTime = playingDetails.endTime
            }
            EvaLogger.sharedInstance.logMessage("Asset loaded in feed with ID: \(asset.id) and EDL: \(asset.edlId) startTime: \(asset.startTime) endTime: \(asset.endTime)")
         }
         else
         {
            EvaLogger.sharedInstance.logMessage("Asset with end time 0: \(asset.edlId)", .Error)
         }
      }
      dataSource = dataSource.filter({ $0.endTime > 0 })
   }

   func loadStartInPlayer(player: PlayerWrapper)
   {
      var firstOne: Bool = true

      if self.dataSource.isEmpty == false
      {
         for asset: Asset in dataSource
         {
            if let playingDetails = addAssetToPlaylist(asset, player: player, cleanLoad: firstOne)
            {
               asset.endTime = playingDetails.endTime
               asset.startTime = (firstOne == false && isPlayingDetailValid(playingDetails) == false) ? lastEndTime : playingDetails.startTime

               firstOne = false
               if playingDetails.endTime > 0
               {
                  lastEndTime = playingDetails.endTime
               }
               EvaLogger.sharedInstance.logMessage("Asset loaded in feed with ID: \(asset.id) and EDL: \(asset.edlId) startTime: \(asset.startTime) endTime: \(asset.endTime)")
            }
            else
            {
               EvaLogger.sharedInstance.logMessage("Asset with end time 0: \(asset.edlId)", .Error)
            }
         }
         dataSource = dataSource.filter({ $0.endTime > 0 })
      }
   }

   func loadNewClipsInPlayer(player: PlayerWrapper)
   {
      if self.isLoading == false
      {
         self.isLoading = true
         for asset: Asset in self.dataSource[(self.dataSource.count - self.numberOfNewElements)..<self.dataSource.count]
         {
            if let playingDetails = addAssetToPlaylist(asset, player: player)
            {
               asset.endTime = playingDetails.endTime
               asset.startTime = isPlayingDetailValid(playingDetails) == false ?  lastEndTime : playingDetails.startTime
               if playingDetails.endTime > 0 { lastEndTime = playingDetails.endTime }
               EvaLogger.sharedInstance.logMessage("Asset loaded in feed with ID: \(asset.edlId) startTime: \(asset.startTime) endTime: \(asset.endTime)")
            }
            else
            {
               EvaLogger.sharedInstance.logMessage("Asset with end time 0: \(asset.edlId)", .Error)
            }
         }
         dataSource = dataSource.filter({ $0.endTime > 0 })
         self.numberOfNewElements = 0
         self.isLoading = false
      }
   }

   // MARK: - Private methods

   private func checkFeed(feed feed: Feed)
   {
      if feed.isEmpty == false
      {
         self.numberOfNewElements = 0
         if self.isEmpty == false
         {
            for asset in feed.dataSource
            {
               if self.feed.dataSource.contains(asset) == false
               {
                  self.feed.dataSource.append(asset)
                  self.numberOfNewElements++
               }
            }
         }
         else
         {
            self.feed = feed
         }
      }
   }

   // MARK: - Feed

   func resetFeed() { self.feed = createFeed() }

   func createFeed() -> Feed { return Feed(possibleFeedDetails: JsonDictionary()) }

   func createFeed(asset: Asset) -> Feed { return Feed(asset: asset) }
}

extension FeedDataSource
{
   // MARK: - Description

   override var description: String { return "{\n\tdelegate: \(self.delegate)\n\tcount: \(self.count)\n\tdataSource: \(self.dataSource)\n}" }
}

extension FeedDataSource: ServerResponseProtocol
{
   // MARK: - ServerResponseProtocol

   func errorResponse(serverError: ServerErrorType?, extraData: [String:AnyObject]?) { EvaLogger.sharedInstance.logMessage("ServerResponse network error: \(serverError?.description)", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonString: String) { EvaLogger.sharedInstance.logMessage("ServerResponse jsonString not implemented", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonDictionary:JsonDictionary)
   {
      switch responseFrom
      {
      case .GetSavedFeed:
         let feed = Feed(possibleFeedDetails: JsonDictionary())
         feed.updateFeedDetails(possibleAssets: jsonDictionary["feed"] as! [JsonDictionary])
         checkFeed(feed: feed)
         delegate?.refreshData()

      default:
         assertionFailure("Response \(responseFrom.rawValue) not implemented")
      }
   }

   func serverResponse(responseFrom: ServerResponseType, nextObject: String?, jsonDictionaryArray:[JsonDictionary])
   {
      switch responseFrom
      {
      case .GetLikedAssets, .SearchFeeds:
         self.nextObject = nextObject
         if firstNextObject == nil { firstNextObject = nextObject }
         let feed = Feed(possibleFeedDetails: JsonDictionary())
         feed.updateFeedDetails(possibleAssets: jsonDictionaryArray)
         checkFeed(feed: feed)
         delegate?.refreshData()

      case .SearchFeedsOffset:
         let feed = Feed(possibleFeedDetails: JsonDictionary())
         feed.updateFeedDetails(possibleAssets: jsonDictionaryArray)
         checkFeed(feed: feed)
         delegate?.refreshData()

      default:
         assertionFailure("Response \(responseFrom.rawValue) not implemented")
      }
   }
}
