//
//  ContactsDataSource.swift
//  eva
//
//  Created by Panayiotis Stylianou on 15/11/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit
import AddressBook

enum ContactsDataSourceErrorType: ErrorType
{
   case NotAuthorized
   case NotDetermined
   case NoContacts
}

protocol ContactsDataSourceProtocol: DataSourceProtocol
{
   func inviteFinished()
}

class ContactsDataSource: NSObject
{
   // MARK: - Constants

   static let kMaxBatchSize = 100

   // MARK: - ServerResponse

   lazy var serverResponse:ServerResponse = ServerResponse(delegate:self)
   lazy var networkDelegate: UnsafeMutablePointer<Void> = self.serverResponse.networkDelegate

   // MARK: - Delegates

   var delegate: ContactsDataSourceProtocol?

   // MARK: - Properties

   var count: Int { return self._dataSourceContacts.count + self._dataSourceUsers.count }
   var addressBookRef: ABAddressBook?
   var hasInvites: Bool { return !self._dataSourceContacts.isEmpty }
   var hasUsers: Bool { return !self._dataSourceUsers.isEmpty }

   // MARK: - Private properties

   private var _dataSourceContacts: [ABRecord] = []
   private var _dataSourceUsers: [EvaUserSearched] = []
   private var _contactsList: [ABRecord] = []
   private var _invitesRows: [Int] = []

   // MARK: - Initializers

   init(delegate: ContactsDataSourceProtocol?)
   {
      self.delegate = delegate
   }

   func fetchContacts() throws
   {
      do {
         let isAuthorized = try checkAuth()
         guard isAuthorized else { throw ContactsDataSourceErrorType.NotAuthorized }
         addressBookRef = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
         _contactsList = (ABAddressBookCopyArrayOfAllPeople(addressBookRef).takeRetainedValue() as NSArray as [ABRecord]).filter({ self.hasMails($0) })
         guard _contactsList.isEmpty == false else { throw ContactsDataSourceErrorType.NoContacts }
         FindFriendsContacts("email", (getContactsMails().joinWithSeparator(":") as NSString).UTF8String, networkDelegate)

      } catch ContactsDataSourceErrorType.NotDetermined { throw ContactsDataSourceErrorType.NotDetermined }
   }

   func followAll()
   {
      for evaUser in _dataSourceUsers
      {
         evaUser.changeToFollow()
      }
      _dataSourceUsers = []
      delegate?.refreshData()
   }

   func clearInvites() { _invitesRows = [] }

   func inviteAll()
   {
      if _invitesRows.count != _dataSourceContacts.count
      {
         _invitesRows = Array(0..<_dataSourceContacts.count)
      }
      else
      {
         _invitesRows = []
      }
      sendInvites()
      delegate?.refreshData()
   }

   func inviteContact(sender: InviteContactButton)
   {
      let mail = getEmail(_dataSourceContacts[sender.indexPath!.row])
      var emailList: [String] = [String]()
      emailList.append(mail)
      if let userId = SessionManager.sharedInstance.loggedInUser.userId
      {
         InviteEmails(userId, (emailList.joinWithSeparator(":") as NSString).UTF8String, networkDelegate)
      }
      _dataSourceContacts.removeAtIndex(sender.indexPath!.row)
      delegate?.refreshData()

   }

   func sendInvites()
   {
      var batches: [[String]] = [[String]]()

      if _invitesRows.count > ContactsDataSource.kMaxBatchSize
      {
         let numberOfBatchesNeeded = _invitesRows.count / ContactsDataSource.kMaxBatchSize
         for index in 0...numberOfBatchesNeeded
         {
            let lowerLimit: Int = index * ContactsDataSource.kMaxBatchSize
            let upperLimit: Int = _invitesRows.count <= (index + 1) * ContactsDataSource.kMaxBatchSize ? _invitesRows.count : (index + 1) * ContactsDataSource.kMaxBatchSize

            var mails: [String] = []
            for contactIndex in _invitesRows[lowerLimit..<upperLimit]
            {
               mails.append(getEmail(_dataSourceContacts[contactIndex]))
            }
            batches.append(Array(mails))
         }
      }
      else
      {
         var mails: [String] = []
         for contactIndex in _invitesRows
         {
            mails.append(getEmail(_dataSourceContacts[contactIndex]))
         }
         batches.append(mails)
      }
      for batch: [String] in batches
      {
         if let userId = SessionManager.sharedInstance.loggedInUser.userId
         {
            InviteEmails(userId, (batch.joinWithSeparator(":") as NSString).UTF8String, networkDelegate)
         }
      }
      _dataSourceContacts = []
      delegate?.inviteFinished()
   }

   // MARK: - Private methods

   private func checkAuth() throws -> Bool
   {
      switch ABAddressBookGetAuthorizationStatus()
      {
      case .Denied, .Restricted:
         return false

      case .Authorized:
         return true

      case .NotDetermined:
         throw ContactsDataSourceErrorType.NotDetermined
      }
   }

   private func hasMails(contactRecord: ABRecord) -> Bool { return ABMultiValueGetCount(ABRecordCopyValue(contactRecord, kABPersonEmailProperty).takeRetainedValue()) > 0 }

   private func getContactsMails() -> [String]
   {
      return _contactsList.map({ getEmail($0) })
   }

   private func getEmail(contactRecord: ABRecord) -> String
   {
      let contactMails: ABMutableMultiValueRef = ABRecordCopyValue(contactRecord, kABPersonEmailProperty).takeRetainedValue()

      return ABMultiValueCopyValueAtIndex(contactMails, 0).takeRetainedValue() as! String
   }
}

extension ContactsDataSource: ServerResponseProtocol
{
   func errorResponse(networkError: ServerErrorType?, extraData: [String:AnyObject]?) { EvaLogger.sharedInstance.logMessage("ServerResponse network error: \(networkError)", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonString: String) { EvaLogger.sharedInstance.logMessage("jsonString is not implemented", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonDictionary: JsonDictionary)
   {
      if responseFrom == .FindFriendsContacts
      {
         if jsonDictionary.isEmpty == false
         {
            for userResponse in jsonDictionary["users"] as! [JsonDictionary]
            {
               let evaUser = EvaUserSearched(jsonDictionary: userResponse)
               if evaUser.followedByMe == false
               {
                  _dataSourceUsers.append(evaUser)
               }
            }
            for email in jsonDictionary["emailInvites"] as! [String]
            {
               _dataSourceContacts.append(_contactsList.filter({ getEmail($0) == email }).first!)
            }
         }
         else
         {
            _dataSourceContacts = _contactsList
         }
         delegate?.refreshData()
      }
   }

   func serverResponse(responseFrom: ServerResponseType, nextObject: String?, jsonDictionaryArray: [JsonDictionary]) { EvaLogger.sharedInstance.logMessage("jsonDictionaryArray is not implemented", .Error) }
}

extension ContactsDataSource: UITableViewDataSource
{
   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
   {
      switch section
      {
      case 0 :
         return _dataSourceUsers.count

      case 1:
         return _dataSourceContacts.count

      default:
         fatalError("Section not defined")
      }
   }

   func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 2 }

   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
   {
      switch indexPath.section
      {
      case 0:
         let userTableViewCell = tableView.dequeueReusableCellWithIdentifier(USER_TABLE_VIEW_CELL) as! UserTableViewCell
         return prepareUserTableViewCell(userTableViewCell, indexPath: indexPath)

      case 1:
         let contactTableViewCell = tableView.dequeueReusableCellWithIdentifier(InvitesTableViewCell.CellIdentifier) as! InvitesTableViewCell
         return prepareContactTableViewCell(contactTableViewCell, indexPath: indexPath)

      default:
         fatalError("Section not defined")
      }
   }

   private func prepareUserTableViewCell(userTableViewCell: UserTableViewCell, indexPath:NSIndexPath) -> UserTableViewCell
   {
      _dataSourceUsers[indexPath.row].delegate = userTableViewCell
      let evaUserSearched = _dataSourceUsers[indexPath.row]

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

   private func prepareContactTableViewCell(contactTableViewCell: InvitesTableViewCell, indexPath:NSIndexPath) -> InvitesTableViewCell
   {
      let contactRecord = _dataSourceContacts[indexPath.row]
      let contactName = ABRecordCopyValue(contactRecord, kABPersonFirstNameProperty)?.takeRetainedValue() as! String? ?? ""
      let contactLastName = ABRecordCopyValue(contactRecord, kABPersonLastNameProperty)?.takeRetainedValue() as! String? ?? ""

      if ABPersonHasImageData(contactRecord)
      {
         contactTableViewCell.avatarImage?.image = UIImage(data: ABPersonCopyImageDataWithFormat(contactRecord, kABPersonImageFormatThumbnail).takeRetainedValue())
      }
      else
      {
         contactTableViewCell.avatarImage?.image = UIImage(named: "avatar")
      }

      contactTableViewCell.screenName?.text = contactName + " " + contactLastName
      contactTableViewCell.dataLabel?.text = getEmail(contactRecord) ?? ""
      contactTableViewCell.inviteButton?.indexPath = indexPath
      contactTableViewCell.inviteButton?.contactMail = getEmail(contactRecord) ?? ""
      contactTableViewCell.inviteButton?.addTarget(self, action: "inviteContact:", forControlEvents: .TouchUpInside)
      contactTableViewCell.inviteButton?.setImage(UIImage(named: "add"), forState: .Normal)

      return contactTableViewCell
   }
}

extension ContactsDataSource: UserTableViewCellProtocol
{
   func didFollowUnFollow(indexPath: NSIndexPath?) -> FollowState
   {
      guard let index = indexPath?.row else { fatalError("Not able to get an index") }
      _dataSourceUsers[index].changeFollowedByMeState()
      delegate?.refreshData()
      let followState = _dataSourceUsers[index].followedByMeState
      return followState
   }
}
