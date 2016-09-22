//
//  InviteFriendsDataSource.swift
//  eva
//
//  Created by Panayiotis Stylianou on 24/02/2016.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

protocol FacebookDataSourceProtocol: DataSourceProtocol
{
   func didNotHaveAnyFriendsToFollow()
   func didNotHaveAnAccount()
   func alreadyInUse()
}

class FacebookFriendsDataSource: NSObject
{
   // MARK: - ServerResponse

   lazy var serverResponse:ServerResponse = ServerResponse(delegate:self)
   lazy var networkDelegate: UnsafeMutablePointer<Void> = self.serverResponse.networkDelegate

   // MARK: - Delegates

   var delegate: FacebookDataSourceProtocol?

   // MARK: - Properties

   var count: Int { return self._dataSource.count }
   var isEmpty: Bool { return self._dataSource.isEmpty }

   // MARK: - Private properties

   private var _dataSource: [EvaUserSearched] = []

   // MARK: - Initializers

   init(delegate: FacebookDataSourceProtocol?)
   {
      self.delegate = delegate
   }

   func fetchFriends()
   {
      guard let fbId = SessionManager.sharedInstance.loggedInUser.facebookId where fbId.isEmpty == false
         else {
            delegate?.didNotHaveAnAccount()
            return
      }
      FindFriends(("facebook" as NSString).UTF8String, networkDelegate)
   }

   func followAll()
   {
      for evaUser in _dataSource
      {
         evaUser.changeFollowedByMeState()
      }
      _dataSource = []
      delegate?.refreshData()
      delegate?.didNotHaveAnyFriendsToFollow()
   }
}

extension FacebookFriendsDataSource: ServerResponseProtocol
{
   func errorResponse(networkError: ServerErrorType?, extraData: [String:AnyObject]?)
   {
      guard let error = networkError else {
         EvaLogger.sharedInstance.logMessage("ServerResponse network error: \(networkError)", .Error)
         return
      }
      switch error
      {
      case .socialIdInUse, .noSocialId:
         delegate?.alreadyInUse()

      default:
         EvaLogger.sharedInstance.logMessage("ServerResponse network error: \(networkError)", .Error)
      }
   }

   func serverResponse(responseFrom: ServerResponseType, jsonString: String) { EvaLogger.sharedInstance.logMessage("jsonString is not implemented", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonDictionary: JsonDictionary)
   {
      if jsonDictionary.isEmpty == false
      {
         for userResponse in jsonDictionary["users"] as! [JsonDictionary]
         {
            let evaUser = EvaUserSearched(jsonDictionary: userResponse)
            if evaUser.followedByMe == false
            {
               _dataSource.append(evaUser)
            }
         }
         _dataSource.isEmpty ? delegate?.didNotHaveAnyFriendsToFollow(): delegate?.refreshData()
      }
      else
      {
         delegate?.didNotHaveAnyFriendsToFollow()
      }
   }

   func serverResponse(responseFrom: ServerResponseType, nextObject: String?, jsonDictionaryArray: [JsonDictionary]) { EvaLogger.sharedInstance.logMessage("jsonDictionaryArray is not implemented", .Error) }
}

extension FacebookFriendsDataSource: UITableViewDataSource
{
   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return _dataSource.count }

   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
   {
      let userTableViewCell = tableView.dequeueReusableCellWithIdentifier(USER_TABLE_VIEW_CELL) as! UserTableViewCell
      _dataSource[indexPath.row].delegate = userTableViewCell
      let evaUserSearched = _dataSource[indexPath.row]

      if let _ = evaUserSearched.avatarId
      {
         evaUserSearched.setAvatarImageForImageView(&userTableViewCell.avatarImage!)
      }
      else
      {
         userTableViewCell.avatarImage?.image = UIImage(named: "avatar")
      }

      if let avatarContainer = userTableViewCell.avatarImage
      {
         avatarContainer.layer.cornerRadius = avatarContainer.frame.width / 2
         avatarContainer.clipsToBounds = true
         avatarContainer.layer.borderWidth = 0
         avatarContainer.layer.borderColor = UIColor (red: 50, green: 50, blue: 50).CGColor
      }
      userTableViewCell.delegate = self
      userTableViewCell.indexPath = indexPath
      userTableViewCell.screenName?.text = evaUserSearched.screenName
      userTableViewCell.detailsLabel?.text = evaUserSearched.tagLine
      userTableViewCell.followButton?.frame = CGRectMake(userTableViewCell.frame.size.width-50, 10, 40, 40)
      userTableViewCell.followButton?.layer.cornerRadius = 20
      switch evaUserSearched.followedByMeState
      {
      case .Following:
         userTableViewCell.followButton?.setImage(UIImage(named: "following"), forState: UIControlState.Normal)
      case .NotFollowing:
         userTableViewCell.followButton?.setImage(UIImage(named: "follow"), forState: UIControlState.Normal)
      case .Requested:
         userTableViewCell.followButton?.setImage(UIImage(named: "pending"), forState: UIControlState.Normal)
      case .Blocked:
         userTableViewCell.followButton?.setImage(UIImage(named: "follow"), forState: UIControlState.Normal)
      }

      return userTableViewCell
   }
}

extension FacebookFriendsDataSource: UserTableViewCellProtocol
{
   func didFollowUnFollow(indexPath: NSIndexPath?) -> FollowState
   {
      guard let index = indexPath?.row else { fatalError("Index not existent") }
      _dataSource[index].changeFollowedByMeState()
      _dataSource.removeAtIndex(index)
      delegate?.refreshData()
      let followState = _dataSource[index].followedByMeState
      return followState
   }
}
