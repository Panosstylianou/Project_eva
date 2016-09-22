//
//  UserHistoryDataSource.swift
//  eva
//
//  Created by Panayiotis Stylianou on 10/02/2016.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation

protocol UserHistoryInteractiveProtocol
{
   func didChooseToReplyTo(screenName: String, assetId: String)
   func didChooseToView(assetId: String)
   func didChooseToViewRequests()
   func dismissView()
}

class UserHistoryDataSource: NSObject, ServerResponseProtocol, UITableViewDataSource, UserTableViewCellProtocol, PaginatedDataSourceProtocol, UITableViewDelegate
{
   // MARK: - Constants

   static let PAGE_SIZE: Int32 = 25
   static let LOAD_THRESHOLD: Int = 10
   static let CELL_STANDARD_HEIGHT: CGFloat = 70.0
   static let CELL_BUTTON_MARGIN: CGFloat = 30.0
   static let CELL_REQUEST_HEIGHT: CGFloat = 90.0

   enum Sections: Int
   {
      case Activity = 0
      case Requests
   }

   // MARK: - Properties

   lazy var serverResponse:ServerResponse = ServerResponse(delegate:self)
   var delegate: DataSourceProtocol?
   var interactiveDelegate: UserHistoryInteractiveProtocol?
   var networkDelegate: UnsafeMutablePointer<Void> { return self.serverResponse.networkDelegate }
   var items = [Sections.Activity: [UserHistoryItem](), Sections.Requests: [UserHistoryItem]()]
   var count: Int { return items[Sections(rawValue: items.count - 1)!]!.count }
   var isEmpty: Bool { return items[Sections(rawValue: items.count - 1)!]!.isEmpty }
   var showRequests = false
   var notificationList: [String]?
   var hasRequests: Bool = false
   var userRequests = [EvaUserSearched]()
   var requestsNumber: Int?
   var lastContentOffset: CGFloat = 0

   // MARK: - Private properties

   private var lastReceived: Int = 0
   private var loadingData: Bool = false
   private var lastRequestsReceived: Int = 0

   // MARK: - Printable

   override var description: String { return "{\n delegate: \(self.delegate)\n count: \(self.count)\n lastReceived: \(self.lastReceived)\n}" }

   // MARK: - PaginatedDataSourceProtocol

   var nextPageString: String?

   // MARK: - Initializers

   init(delegate: DataSourceProtocol)
   {
      self.delegate = delegate
      super.init()
   }

   convenience init(delegate: DataSourceProtocol, interactiveDelegate: UserHistoryInteractiveProtocol)
   {
      self.init(delegate: delegate)
      self.interactiveDelegate = interactiveDelegate
   }

   // MARK: - Public methods

   func getHistoryForUser(includeRead: Bool = true)
   {
      if loadingData == false
      {
         loadingData = true

         if let nextPage = nextPageString
         {
            GetHistory(SessionManager.sharedInstance.loggedInUser.userId!, nextPage, UserHistoryDataSource.PAGE_SIZE, includeRead, networkDelegate)
         }
         else
         {
            GetHistory(SessionManager.sharedInstance.loggedInUser.userId!, nil, UserHistoryDataSource.PAGE_SIZE, includeRead, networkDelegate)
         }
      }
   }

   func addRequestToNotifications()
   {
      if !items[Sections.Requests]!.isEmpty
      {
         let requestCell: UserHistoryItem = items[Sections.Requests]![0] as UserHistoryItem
         items[Sections.Activity]?.insert(requestCell, atIndex: 0)
      }
   }

   func removeRequestFromNotifications()
   {
      if items[Sections.Activity]![0].notificationType == .FollowRequest
      {
         items[Sections.Activity]?.removeAtIndex(0)
      }
   }

   // MARK: - Private methods

   private func isFullHistoryItem(dataNode: JsonDictionary) -> Bool
   {
      if let _ = dataNode[UserHistoryItemFields.notificationType.description] as? String
      {
         return true
      }

      return false
   }

   private func createEntriesFromResponse(data: [JsonDictionary])
   {
      for dataNode: JsonDictionary in data
      {
         if isFullHistoryItem(dataNode)
         {
            let item = UserHistoryItem(dataNode)
            item.notificationType == .FollowRequest ? items[Sections.Requests]!.append(item) : items[Sections.Activity]!.append(item)
            ++self.lastReceived
         }
      }
      if self.lastReceived > 0
      {
         if NSThread.isMainThread()
         {
            self.loadingData = false
            self.delegate?.refreshData()
         }
         else
         {
            weak var weakSelf = self
            dispatch_async(dispatch_get_main_queue()) { if let strongSelf = weakSelf { strongSelf.delegate?.refreshData() }}
         }
      }
   }

   private func createRequestsFromResponse(data: [JsonDictionary])
   {
      for dataNode: JsonDictionary in data
      {
         let item = EvaUserSearched(jsonDictionary: dataNode)
         userRequests.append(item)
         ++self.lastRequestsReceived
      }
      if self.lastRequestsReceived > 0
      {
         if NSThread.isMainThread()
         {
            self.loadingData = false
            self.delegate?.refreshData()
         }
         else
         {
            weak var weakSelf = self
            dispatch_async(dispatch_get_main_queue()) { if let strongSelf = weakSelf { strongSelf.delegate?.refreshData() }}
         }
      }
      requestsNumber = userRequests.count
   }

   private func prepareHistoryItemCell(cell: HistoryItemCell, indexPath: NSIndexPath) -> HistoryItemCell
   {
      let item: UserHistoryItem = self.items[Sections(rawValue:indexPath.section)!]![indexPath.row] as UserHistoryItem

      item.setAvatarImageForImageView(&cell.avatarImage!)
      cell.avatarImage!.layer.cornerRadius =  cell.avatarImage!.frame.width / 2
      cell.avatarImage!.clipsToBounds = true
      cell.avatarImage!.layer.borderWidth = 0
      cell.avatarImage!.layer.borderColor = UIColor.avatarRoundBorderColor(1.0).CGColor

      cell.followButton?.frame = CGRectMake(cell.frame.size.width - 50, 10, 40, 40)

      if let state = item.followedByMeState
      {
         switch state
         {
         case .Following:
            cell.followButton?.setImage(UIImage(named: "following"), forState: UIControlState.Normal)
         case .NotFollowing:
            cell.followButton?.setImage(UIImage(named: "follow"), forState: UIControlState.Normal)
         case .Requested:
            cell.followButton?.setImage(UIImage(named: "pending"), forState: UIControlState.Normal)
         case .Blocked:
            cell.followButton?.setImage(UIImage(named: "follow"), forState: UIControlState.Normal)
         }
      }
      if let destinationUserId = item.relatedUserId where destinationUserId != SessionManager.sharedInstance.loggedInUser.userId!
      {
         cell.followButton?.userInteractionEnabled = true
         cell.followButton?.alpha = 1.0
      }
      else
      {
         cell.followButton?.userInteractionEnabled = false
         cell.followButton?.alpha = 0.2
      }

      cell.detailsLabel?.attributedText = detailForHistoryItem(item)

      cell.actionAvatarImageView.alpha = 0.0
      cell.actionButton.alpha = 0.0
      cell.actionSecondaryButton.alpha = 0.0

      if let type = item.notificationType
      {
         if type == .Comment || type == .Mentioned
         {
            cell.actionButton.backgroundColor = UIColor.blueEvaColor(1.0)
            cell.actionButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            cell.actionButton.setTitle("reply", forState: .Normal)
            cell.actionButton.actionType = .ReplyComment
            cell.actionButton.userScreenNameToReply = item.relatedScreenName
            cell.actionButton.addTarget(self, action: "showReplyWindow:", forControlEvents: .TouchUpInside)

            cell.actionSecondaryButton.backgroundColor = UIColor.mainColor(1.0)
            cell.actionSecondaryButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
            cell.actionSecondaryButton.setTitle("view", forState: .Normal)
            cell.actionSecondaryButton.actionType = .ViewAsset
            cell.actionSecondaryButton.addTarget(self, action: "playSelectedAsset:", forControlEvents: .TouchUpInside)
            cell.actionSecondaryButton.assetIdToReplyTo = item.relatedAssetId
            cell.actionSecondaryButton.alpha = 1.0
         }

         if type == .Tagged || type == .Like
         {
            cell.actionButton.backgroundColor = UIColor.mainColor(1.0)
            cell.actionButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
            cell.actionButton.setTitle("view", forState: .Normal)
            cell.actionButton.actionType = .ViewAsset
            cell.actionButton.addTarget(self, action: "playSelectedAsset:", forControlEvents: .TouchUpInside)
         }

         if type == .FollowRequest
         {
            cell.actionButton.alpha = 0.0
            cell.followButton?.alpha = 0.0
            cell.requestNumberLabel.alpha = 1.0
            cell.requestNumberLabel.text = requestsNumber?.description
            cell.requestNumberLabel.textAlignment = .Center
            cell.rightArrowImage.alpha = 1.0
            cell.detailsLabel?.alpha = 0.0
            cell.requestLabel.alpha = 1.0
            cell.requestSecondaryLabel.alpha = 1.0

            let secondaryText: String = NSLocalizedString("follow or reject requests", comment: "follow or reject requests")
            let attrSecondaryText = NSAttributedString(string: secondaryText, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(1.0), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])
            cell.requestSecondaryLabel.attributedText = attrSecondaryText
            cell.requestLabel.attributedText = detailForHistoryItem(item)
            cell.requestNumberLabel.layer.masksToBounds = true
            cell.requestNumberLabel.layer.cornerRadius = 4
         }

         if type == .Comment || type == .Mentioned || type == .Tagged || type == .Like
         {
            cell.actionAvatarImageView.alpha = 1.0
            cell.actionButton.alpha = 1.0
            item.setAvatarImageForImageView(&cell.actionAvatarImageView!)
            cell.actionButton.assetIdToReplyTo = item.relatedAssetId
         }
      }

      cell.selectionStyle = UITableViewCellSelectionStyle.None
      cell.accessoryType = UITableViewCellAccessoryType.None
      cell.delegate = self
      cell.indexPath = indexPath

      return cell
   }

   private func loadMoreData()
   {
      if let _ = self.nextPageString where loadingData == false { getHistoryForUser(true) }
   }

   private func getCommentHeight(rectWidth: CGFloat, text: NSString) -> CGFloat
   {
      let size = CGSizeMake(rectWidth, CGFloat.max)
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineBreakMode = .ByWordWrapping
      let attributes = [NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!, NSParagraphStyleAttributeName:paragraphStyle.copy()]
      let rect = text.boundingRectWithSize(size, options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
      return rect.size.height
   }

   func changeFollowedByMeState(state: FollowState, privacy: Bool) -> FollowState
   {
      switch state
      {
      case FollowState.Following, FollowState.Requested:
         return FollowState.NotFollowing
      case FollowState.NotFollowing:
         if privacy { return FollowState.Requested } else { return FollowState.Following }
      case FollowState.Blocked:
         return FollowState.Blocked
      }
   }

   func showFollowRequests()
   {
      interactiveDelegate?.didChooseToViewRequests()
   }

   func checkForRequests()
   {
      let getRequestsString = ("1" as NSString).UTF8String
      let screenName = ("screenName" as NSString).UTF8String
      let limit = Int32(100)
      let avatarWidth = Int32(Constants.EVA_USER_SEARCH_AVATAR_IMAGE_SIZE)
      UserSearch(nil, nil, getRequestsString , nil, nil, nil, nil, screenName, nil, limit, avatarWidth, true, networkDelegate)
   }

   // MARK: UITableViewDelegate

   func scrollViewWillBeginDragging(scrollView: UIScrollView) { lastContentOffset = scrollView.contentOffset.y }

   func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
      let newOffset = scrollView.contentOffset.y
      if SessionManager.sharedInstance.needsExitSwipe(newOffset, initialOffset: lastContentOffset) { interactiveDelegate?.dismissView() }
   }

//    MARK: - UITableViewDataSource

   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return items[Sections(rawValue: section)!]!.count }

   func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1}

   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
   {
      let historyTableViewCell = tableView.dequeueReusableCellWithIdentifier(HISTORYITEM_VIEW_CELL) as! HistoryItemCell
      historyTableViewCell.resetDefaults()
      return self.prepareHistoryItemCell(historyTableViewCell, indexPath: indexPath)
   }

   func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
   {
      if indexPath.row == count - UserHistoryDataSource.LOAD_THRESHOLD { loadMoreData() }
   }

   func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
   {
      let item: UserHistoryItem = self.items[Sections(rawValue:indexPath.section)!]![indexPath.row] as UserHistoryItem
      let historyTableViewCell = tableView.dequeueReusableCellWithIdentifier(HISTORYITEM_VIEW_CELL) as! HistoryItemCell
      var cellHeight = UserHistoryDataSource.CELL_STANDARD_HEIGHT
      if let commentText = item.actionText
      {
         cellHeight += getCommentHeight(historyTableViewCell.actionDetailsLabel.bounds.width, text: commentText as NSString)
      }

      if let notType = item.notificationType where notType != .Follow
      {
         cellHeight += UserHistoryDataSource.CELL_BUTTON_MARGIN
      }

      if let itemType = item.notificationType where itemType == .FollowRequest
      {
         cellHeight = UserHistoryDataSource.CELL_REQUEST_HEIGHT
      }

      if let itemType = item.notificationType where itemType == .Like
      {
         cellHeight += getCommentHeight(historyTableViewCell.actionDetailsLabel.bounds.width, text: item.relatedAssetDescription! as NSString)
      }
      return cellHeight
   }

   func scrollViewDidScroll(scrollView: UIScrollView) {
      let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
      if bottomEdge + Constants.SCROLL_MYHISTORY_THRESHOLD >= scrollView.contentSize.height
      {
         if let _ = nextPageString
         {
            getHistoryForUser()
         }
      }
   }

   // MARK: - ServerResponseProtocol

   internal func errorResponse(networkError:ServerErrorType?, extraData: [String:AnyObject]?)
   {
      EvaLogger.sharedInstance.logMessage("ServerResponse networkError: \(networkError?.description)", .Error)
   }

   internal func serverResponse(responseFrom:ServerResponseType, jsonString:String)
   {
      EvaLogger.sharedInstance.logMessage("ServerResponse jsonString not implemented", .Error)
   }

   internal func serverResponse(responseFrom:ServerResponseType, jsonDictionary:JsonDictionary)
   {
      if responseFrom == ServerResponseType.Follow
      {
         if let state = FollowState(rawValue: jsonDictionary["state"] as! String)
         {
            EvaLogger.sharedInstance.logMessage("FollowedByMe Status Changed to \(state)")
         }
      }
   }

   internal func serverResponse(responseFrom:ServerResponseType, nextObject: String?, jsonDictionaryArray:[JsonDictionary])
   {
      if responseFrom == .GetHistory
      {
         self.createEntriesFromResponse(jsonDictionaryArray)
         loadingData = false
         self.nextPageString = nextObject
         if hasRequests
         {
            addRequestToNotifications()
         }
      }
      if responseFrom == .UserSearch
      {
         if !jsonDictionaryArray.isEmpty
         {
            self.createRequestsFromResponse(jsonDictionaryArray)
            hasRequests = true
         }
      }
   }

   // MARK: - UserTableViewCellProtocol

   internal func didFollowUnFollow(indexPath:NSIndexPath?) -> FollowState
   {
      var item: UserHistoryItem = self.items[Sections(rawValue:indexPath!.section)!]![indexPath!.row]
      let newFollowState = changeFollowedByMeState(item.followedByMeState!, privacy: item.userPrivate!)
      item.followedByMeState = newFollowState
      self.items[Sections(rawValue:indexPath!.section)!]![indexPath!.row] = item
      BridgeObjC.followForUserId(item.relatedUserId!, state: newFollowState.rawValue, delegate: self.networkDelegate)

      return newFollowState
   }


   // MARK: - Private Methods

   private func detailForHistoryItem(item: UserHistoryItem) -> NSAttributedString
   {
      let emptyString: NSAttributedString = NSAttributedString(string: "")

      if let type = item.notificationType
      {
         switch type
         {
         case .Comment:
            return getTextForCommentCell(item)

         case .Follow:
            return getTextForFollowCell(item)

         case .Like:
            return getTextForLikedCell(item)

         case .Tagged:
            return getTextForTaggedCell(item)

         case .Mentioned:
            return getTextForMentionedCell(item)

         case .FollowRequest:
            return getTextForFollowRequestCell(item)
         }
      }
      return emptyString
   }

   /**
   Composes the string for "liked" notifications

   - parameter item: UserHistoryItem

   - returns: NSAttributedString
   */
   private func getTextForLikedCell(item: UserHistoryItem) -> NSAttributedString
   {
      if let relatedScreenName = item.relatedScreenName, relatedAssetDescription = item.relatedAssetDescription, elapsedTime = item.createdTime?.elapsedTime
      {
         let attrScreenName = NSAttributedString(string: relatedScreenName, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         let significantText: String = relatedAssetDescription.isEmpty ? NSLocalizedString("liked one of your videos", comment: "liked one of your videos") :  NSLocalizedString("liked your video", comment: "liked your video")
         let attrSignificantText = NSAttributedString(string: significantText, attributes: [NSForegroundColorAttributeName: UIColor.mainColor(1.0), NSFontAttributeName: UIFont(name: "Ubuntu-Bold", size: 13.0)!])

         let attrDescription = NSAttributedString(string: relatedAssetDescription, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         let attrElapsedTime = NSAttributedString(string: elapsedTime, attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         return joinAttributedStrings(" ", attributedStrings: attrScreenName, attrSignificantText, attrDescription, attrElapsedTime)
      }

      return NSAttributedString(string: "")
   }

   /**
    Composes the string for "follow" notifications

    - parameter item: UserHistoryItem

    - returns: NSAttributedString
    */
   private func getTextForFollowRequestCell(item: UserHistoryItem) -> NSAttributedString
   {
      let significantText: String = NSLocalizedString("you have new requests", comment: "you have new requests")
      let attrSignificantText = NSAttributedString(string: significantText, attributes: [NSForegroundColorAttributeName: UIColor.mainColor(1.0), NSFontAttributeName: UIFont(name: "Ubuntu-Bold", size: 16.0)!])

      return attrSignificantText
   }

   /**
   Composes the string for "follow" notifications

   - parameter item: UserHistoryItem

   - returns: NSAttributedString
   */
   private func getTextForFollowCell(item: UserHistoryItem) -> NSAttributedString
   {
      if let relatedScreenName = item.relatedScreenName, elapsedTime = item.createdTime?.elapsedTime
      {
         let attrScreenName = NSAttributedString(string: relatedScreenName, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         let significantText: String = NSLocalizedString("started following you", comment: "started following you")
         let attrSignificantText = NSAttributedString(string: significantText, attributes: [NSForegroundColorAttributeName: UIColor.mainColor(1.0), NSFontAttributeName: UIFont(name: "Ubuntu-Bold", size: 13.0)!])

         let attrElapsedTime = NSAttributedString(string: elapsedTime, attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         return joinAttributedStrings(" ", attributedStrings: attrScreenName, attrSignificantText, attrElapsedTime)
      }
      return NSAttributedString(string: "")
   }

   /**
   Composes the string for "comment" notifications

   - parameter item: UserHistoryItem

   - returns: NSAttributedString
   */
   private func getTextForCommentCell(item: UserHistoryItem) -> NSAttributedString
   {
      if let relatedScreenName = item.relatedScreenName, actionText = item.actionText, relatedAssetDescription = item.relatedAssetDescription, elapsedTime = item.createdTime?.elapsedTime
      {
         let attrScreenName = NSAttributedString(string: relatedScreenName, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         let significantText: String = relatedAssetDescription.isEmpty ? NSLocalizedString("commented one of your videos", comment: "commented one of your videos") :  NSLocalizedString("commented your video", comment: "commented your video")
         let attrSignificantText = NSAttributedString(string: significantText, attributes: [NSForegroundColorAttributeName: UIColor.mainColor(1.0), NSFontAttributeName: UIFont(name: "Ubuntu-Bold", size: 13.0)!])

         let commentText = NSAttributedString(string: "' \(actionText) '", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(1.0), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

//         let attrDescription = relatedAssetDescription.isEmpty ? NSAttributedString(string: "") : NSAttributedString(string: "'\(relatedAssetDescription)'", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         let attrElapsedTime = NSAttributedString(string: elapsedTime, attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         return joinAttributedStrings(" ", attributedStrings: attrScreenName, attrSignificantText, commentText, attrElapsedTime)
      }

      return NSAttributedString(string: "")
   }

   /**
   Composes the string for "tagged" notifications

   - parameter item: UserHistoryItem

   - returns: NSAttributedString
   */
   private func getTextForTaggedCell(item: UserHistoryItem) -> NSAttributedString
   {
      if let relatedScreenName = item.relatedScreenName, elapsedTime = item.createdTime?.elapsedTime
      {
         let attrScreenName = NSAttributedString(string: relatedScreenName, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         let significantText: String = NSLocalizedString("tagged", comment: "tagged")
         let attrSignificantText = NSAttributedString(string: significantText, attributes: [NSForegroundColorAttributeName: UIColor.mainColor(1.0), NSFontAttributeName: UIFont(name: "Ubuntu-Bold", size: 13.0)!])

         var attrDescription: NSAttributedString = NSAttributedString(string: "")
         if let actionText = item.actionText where actionText.isEmpty == false
         {
            let descriptionText = NSLocalizedString("you in a video", comment: "you in a video") + " ' \(actionText) '"
            attrDescription = NSAttributedString(string: descriptionText, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])
         }
         else
         {
            let descriptionText = NSLocalizedString("you in a video", comment: "you in a video")
            attrDescription = NSAttributedString(string: descriptionText, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])
         }

         let attrElapsedTime = NSAttributedString(string: elapsedTime, attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         return joinAttributedStrings(" ", attributedStrings: attrScreenName, attrSignificantText, attrDescription, attrElapsedTime)
      }

      return NSAttributedString(string: "")
   }

   /**
   Composes the string for "mentioned" notifications

   - parameter item: UserHistoryItem

   - returns: NSAttributedString
   */
   private func getTextForMentionedCell(item: UserHistoryItem) -> NSAttributedString
   {
      if let relatedScreenName = item.relatedScreenName, _ = item.actionText, elapsedTime = item.createdTime?.elapsedTime
      {
         let attrScreenName = NSAttributedString(string: relatedScreenName, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         let significantText: String = NSLocalizedString("messaged", comment: "messaged")
         let attrSignificantText = NSAttributedString(string: significantText, attributes: [NSForegroundColorAttributeName: UIColor.mainColor(1.0), NSFontAttributeName: UIFont(name: "Ubuntu-Bold", size: 13.0)!])

         var attrDescription: NSAttributedString = NSAttributedString(string: "")
         if let actionText = item.actionText where actionText.isEmpty == false
         {
            let descriptionText = NSLocalizedString("you", comment: "you") + " ' \(actionText) '"
            attrDescription = NSAttributedString(string: descriptionText, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])
         }
         else
         {
            let descriptionText = NSLocalizedString("you in a comment", comment: "you in a comment")
            attrDescription = NSAttributedString(string: descriptionText, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])
         }

         let attrElapsedTime = NSAttributedString(string: elapsedTime, attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 13.0)!])

         return joinAttributedStrings(" ", attributedStrings: attrScreenName, attrSignificantText, attrDescription, attrElapsedTime)
      }
      return NSAttributedString(string: "")
   }

   /**
   Joins a series of NSAttributedString using the given separator

   - parameter separator:         String
   - parameter attributedStrings: NSAttributedStrings

   - returns: NSAttributedString
   */
   private func joinAttributedStrings(separator: String, attributedStrings: NSAttributedString...) -> NSAttributedString
   {
      let attributedText: NSMutableAttributedString = NSMutableAttributedString()
      for item: NSAttributedString in attributedStrings
      {
         attributedText.appendAttributedString(item)
         attributedText.appendAttributedString(NSAttributedString(string: separator))
      }

      return attributedText.copy() as! NSAttributedString
   }

   // MARK: - Button Actions

   func showReplyWindow(sender: ReplyUIButton)
   {
      if let assetId = sender.assetIdToReplyTo, userScreenName = sender.userScreenNameToReply where sender.actionType == .ReplyComment
      {
         interactiveDelegate?.didChooseToReplyTo(userScreenName, assetId: assetId)
      }
   }

   func playSelectedAsset(sender: ReplyUIButton)
   {
      if let assetId = sender.assetIdToReplyTo where sender.actionType == .ViewAsset
      {
         interactiveDelegate?.didChooseToView(assetId)
      }
   }
}
