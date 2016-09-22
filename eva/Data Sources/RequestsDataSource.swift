//
//  RequestsDataSource.swift
//  eva
//
//  Created by Panayiotis Stylianou on 21/01/2016.
//  Copyright © 2016 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

protocol RequestsInteractiveProtocol
{
   func reload(indedPath: NSIndexPath)
}

class RequestsDataSource: NSObject , ServerResponseProtocol, UITableViewDataSource, UserTableViewCellProtocol, PaginatedDataSourceProtocol, UITableViewDelegate
{

   // MARK: - Constants

   static let PAGE_SIZE: Int32 = 25
   static let LOAD_THRESHOLD: Int = 10
   static let CELL_STANDARD_HEIGHT: CGFloat = 100.0
   static let CELL_BUTTON_MARGIN: CGFloat = 30.0

   // MARK: - Properties

   lazy var serverResponse:ServerResponse = ServerResponse(delegate:self)
   var delegate: DataSourceProtocol?
   var interactiveDelegate: RequestsInteractiveProtocol?
   var networkDelegate: UnsafeMutablePointer<Void> { return self.serverResponse.networkDelegate }
   var items = [EvaUserSearched]()

   // MARK: - Private properties

   private var lastReceived: Int = 0
   private var loadingData: Bool = false

   // MARK: - PaginatedDataSourceProtocol

   var nextPageString: String?

   init(delegate: DataSourceProtocol)
   {
      self.delegate = delegate
      super.init()
   }

   convenience init(delegate: DataSourceProtocol, interactiveDelegate: RequestsInteractiveProtocol)
   {
      self.init(delegate: delegate)
      self.interactiveDelegate = interactiveDelegate
   }

   func getRequestsForUser()
   {
      if loadingData == false
      {
         loadingData = true
         let getRequestsString = ("1" as NSString).UTF8String
         let screenName = ("screenName" as NSString).UTF8String
         let limit = Int32(100)
         let avatarWidth = Int32(Constants.EVA_USER_SEARCH_AVATAR_IMAGE_SIZE)
         if let nextPage = nextPageString
         {
            UserSearch(nil, nil, getRequestsString , nil, nil, nil, nil, screenName, (nextPage as NSString).UTF8String, limit, avatarWidth, true, networkDelegate)
         }
         else
         {
            UserSearch(nil, nil, getRequestsString , nil, nil, nil, nil, screenName, nil, limit, avatarWidth, true, networkDelegate)
         }
      }
   }

   private func createEntriesFromResponse(data: [JsonDictionary])
   {
      for dataNode: JsonDictionary in data
      {
         let item = EvaUserSearched(jsonDictionary: dataNode)
         items.append(item)
         ++self.lastReceived
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

   private func prepareRequestItemCell(cell: RequestItemCell, indexPath: NSIndexPath) -> RequestItemCell
   {
      let item: EvaUserSearched = self.items[indexPath.row] as EvaUserSearched

      item.setAvatarImageForImageView(&cell.avatarImage!)
      cell.avatarImage!.layer.cornerRadius =  cell.avatarImage!.frame.width / 2
      cell.avatarImage!.clipsToBounds = true
      cell.avatarImage!.layer.borderWidth = 0
      cell.avatarImage!.layer.borderColor = UIColor.avatarRoundBorderColor(1.0).CGColor

      let attrNameText = NSAttributedString(string: item.screenName!, attributes: [NSForegroundColorAttributeName: UIColor.mainColor(1.0), NSFontAttributeName: UIFont(name: "Ubuntu-Bold", size: 14.0)!])
      cell.detailsLabel?.attributedText = attrNameText

      let attrDescriptionText = NSAttributedString(string: item.tagLine!, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Ubuntu-Bold", size: 13.0)!])

      cell.descriptionLabel.attributedText = attrDescriptionText
      cell.descriptionLabel.lineBreakMode = .ByWordWrapping
      cell.descriptionLabel.numberOfLines = 0

      cell.acceptButton.actionType = .ApproveRequest
      cell.acceptButton.userId = item.userId
      cell.acceptButton.indexPath = indexPath
      cell.acceptButton.addTarget(self, action: "approveRequest:", forControlEvents: .TouchUpInside)

      cell.rejectButton.actionType = .RejectRequest
      cell.rejectButton.addTarget(self, action: "rejectRequest:", forControlEvents: .TouchUpInside)
      cell.rejectButton.userId = item.userId
      cell.rejectButton.indexPath = indexPath

      cell.rejectButton.alpha = 1.0
      cell.acceptButton.alpha = 1.0

      cell.selectionStyle = UITableViewCellSelectionStyle.None
      cell.accessoryType = UITableViewCellAccessoryType.None
      cell.delegate = self
      cell.indexPath = indexPath

      return cell
   }

   private func loadMoreData()
   {
      if let _ = self.nextPageString where loadingData == false { getRequestsForUser() }
   }

   func reloadData()
   {
      getRequestsForUser()
   }

   func approveRequest(sender: ReplyUIButton)
   {
      let row = sender.indexPath?.row
      let state = FollowState.Following.rawValue as NSString
      FollowsMe(sender.userId!, state.UTF8String, self.networkDelegate)
      items.removeAtIndex(row!)
      interactiveDelegate?.reload(sender.indexPath!)
   }

   func rejectRequest(sender: ReplyUIButton)
   {
      let row = sender.indexPath?.row
      let state = FollowState.NotFollowing.rawValue as NSString
      FollowsMe(sender.userId!, state.UTF8String, self.networkDelegate)
      items.removeAtIndex(row!)
      interactiveDelegate?.reload(sender.indexPath!)
   }

   // MARK: - UITableViewDataSource

   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return items.count }

   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
   {
      let requestTableViewCell = tableView.dequeueReusableCellWithIdentifier(REQUESTITEM_VIEW_CELL) as! RequestItemCell

      return self.prepareRequestItemCell(requestTableViewCell, indexPath: indexPath)
   }

   func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
   {
      return RequestsDataSource.CELL_STANDARD_HEIGHT
   }

   func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
   {
      if indexPath.row == items.count - RequestsDataSource.LOAD_THRESHOLD { loadMoreData() }
   }

   // MARK: - UserTableViewCellProtocol

   internal func didFollowUnFollow(indexPath:NSIndexPath?) -> FollowState
   {
      let item: EvaUserSearched = self.items[indexPath!.row]
      let followState = (item.followedByMe ? FollowState.NotFollowing : FollowState.Following)

      BridgeObjC.followForUserId(item.userId!, state: followState.rawValue, delegate: self.networkDelegate)
      return followState
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
      EvaLogger.sharedInstance.logMessage("ServerResponse jsonDictionary not implemented", .Error)
   }

   internal func serverResponse(responseFrom:ServerResponseType, nextObject: String?, jsonDictionaryArray:[JsonDictionary])
   {
      if responseFrom == .UserSearch
      {
         self.createEntriesFromResponse(jsonDictionaryArray)
         loadingData = false
         self.nextPageString = nextObject
      }
   }
}
