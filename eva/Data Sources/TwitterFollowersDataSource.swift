//
//  TwitterFollowersDataSource.swift
//  eva
//
//  Created by Panayiotis Stylianou on 03/03/2016.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

enum TwitterDataSourceError: ErrorType
{
   case NoAccount
   case FetchingError(String)
}

protocol TwitterDataSourceProtocol: DataSourceProtocol
{
   func failedWithError(error: TwitterDataSourceError)
   func noTwitterFollowers(message: String)
   func noTwitterAccount(message: String)
   func followersToInvite()
   func noFollowersToInvite()
   func inviteFinished()
}

class TwitterFollowersDataSource: NSObject
{
   // MARK: - Properties

   var delegate: TwitterDataSourceProtocol?
   var count: Int { return self._dataSource.count }
   var isEmpty: Bool { return self._dataSource.isEmpty }
   var hasInvites: Bool { return self._invitesTwitter.isEmpty }

   // MARK: - Private properties

   private var _dataSource: [TwitterUser] = []
   private var _twitterAccounts: [ACAccount]?
   private var _invitesTwitter: [TwitterUser] = []

   init(delegate: TwitterDataSourceProtocol) { self.delegate = delegate }

   func fetchFollowers()
   {
      let twitterManager = TwitterManager()
      twitterManager.delegate = self
      twitterManager.fetchTwitterAccounts()
   }
}

extension TwitterFollowersDataSource: UITableViewDataSource
{
   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return _dataSource.count }

   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
   {
      let twFollowerTableViewCell = tableView.dequeueReusableCellWithIdentifier(InvitesTableViewCell.CellIdentifier) as! InvitesTableViewCell
      let twitterFollower: TwitterUser = _dataSource[indexPath.row]

      twFollowerTableViewCell.screenName?.text = twitterFollower.userName
      twFollowerTableViewCell.dataLabel?.text = NSLocalizedString("prefix", comment:"screenName prefix") + twitterFollower.screenName
      twFollowerTableViewCell.inviteButton?.indexPath = indexPath
      twFollowerTableViewCell.inviteButton?.twitterUser = twitterFollower
      twFollowerTableViewCell.inviteButton?.addTarget(self, action: "inviteContact:", forControlEvents: .TouchUpInside)
      twFollowerTableViewCell.inviteButton?.needsInvite = _invitesTwitter.contains(twitterFollower)
      twFollowerTableViewCell.avatarImage.sd_setImageWithURL(twitterFollower.profileImage.toHTTPS(), placeholderImage: UIImage(named: "avatar"))

      twFollowerTableViewCell.inviteButton!.needsInvite ? twFollowerTableViewCell.inviteButton?.setImage(UIImage(named: "added"), forState: .Normal) : twFollowerTableViewCell.inviteButton?.setImage(UIImage(named: "add"), forState: .Normal)

      return twFollowerTableViewCell
   }

   func inviteContact(sender: InviteContactButton)
   {
      if let twitterUser = sender.twitterUser
      {
         if _invitesTwitter.contains(twitterUser) == false
         {
            _invitesTwitter.append(twitterUser)
            if _invitesTwitter.isEmpty == false { delegate?.followersToInvite() }
         }
         else
         {
            _invitesTwitter.removeAtIndex(_invitesTwitter.indexOf(twitterUser)!)
            if _invitesTwitter.isEmpty { delegate?.noFollowersToInvite() }
         }
      }
      sender.needsInvite = !sender.needsInvite
      sender.needsInvite ? sender.setImage(UIImage(named: "added"), forState: .Normal) : sender.setImage(UIImage(named: "add"), forState: .Normal)
   }

   func sendInvites(inviteAll: Bool)
   {
      if let accounts = _twitterAccounts, appStoreUrl = GlobalSettingsManager.sharedInstance.getAppStoreUrl()
      {
         let twitterManager = TwitterManager()
         let invitationText = "Download eva the video social network \(appStoreUrl)"

         for account: ACAccount in accounts
         {
            let users: [TwitterUser] = inviteAll ? _dataSource.filter { $0.account == account } : _invitesTwitter.filter { $0.account == account }
            if users.isEmpty == false
            {
               twitterManager.sendDirectMessageToUsers(users, text: invitationText, account: account)
            }
         }
      }
      delegate?.inviteFinished()
   }

   func clearInvites() { _invitesTwitter = [] }

   func inviteAll()
   {
      if _invitesTwitter.count != _dataSource.count
      {
         _invitesTwitter = _dataSource
         delegate?.followersToInvite()
      }
      else
      {
         _invitesTwitter = []
         delegate?.noFollowersToInvite()

      }
      delegate?.refreshData()
   }
}

extension TwitterFollowersDataSource: TwitterManagerProtocol
{
   func didFetchAccountsNoPermission() { delegate?.failedWithError(.FetchingError(NSLocalizedString("o.eva.invite.twitter.nopermissions", comment:"no permissions twitter"))) }

   func didFinishRequestWithData(requestName: TwitterManagerRequests, account: ACAccount, data: NSData)
   {
      let twitterParser = TwitterDataParser()

      if let twFollowers = twitterParser.parseFriendsData(data, account: account) where twFollowers.isEmpty == false
      {
         _dataSource = twFollowers
         delegate?.refreshData()
      }
      else
      {
         delegate?.noTwitterFollowers(NSLocalizedString("co.eva.invite.twitter.noFollowers", comment:"no followers twitter"))
      }
   }

   func didFinishRequestWithError(requestName: TwitterManagerRequests, account: ACAccount, error: NSError?)
   {
      switch requestName
      {
      case .RequestingPermissions:
         delegate?.failedWithError(.FetchingError(NSLocalizedString("co.eva.invite.twitter.nopermissions", comment:"no permissions twitter")))

      case .FetchFriends:
         delegate?.failedWithError(.FetchingError(NSLocalizedString("co.eva.invite.twitter.errorFollowers", comment:"error followers")))

      case .NoAccount:
         delegate?.noTwitterAccount(NSLocalizedString("co.eva.invite.twitter.noAccount", comment:"no account twitter"))

      default:
         EvaLogger.sharedInstance.logMessage("Twitter Request: \(requestName) not handled")
      }
   }

   func didFetchAccounts(accounts: [ACAccount]?)
   {
      if let accounts = accounts
      {
         _twitterAccounts = accounts
         let twitterManager = TwitterManager()
         twitterManager.delegate = self
         for account: ACAccount in accounts
         {
            twitterManager.fetchPeopleFollowingMe(account)
         }
      }
   }
}
