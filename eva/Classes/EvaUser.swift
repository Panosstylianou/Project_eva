//
//  EvaUser.swift
//  eva
//
//  Created by Panayiotis Stylianou on 02/12/2015.
//  Copyright (c) 2014 Forbidden Technologies PLC. All rights reserved.
//

import Foundation
import Crashlytics

enum EvaUserChangableDetails: String, CustomStringConvertible
{
   case avatarImage = "avatarImage"
   case avatarId = "avatarId"
   case firstName = "firstName"
   case lastName = "lastName"
   case email = "email"
   case tagLine = "tagLine"
   case website = "website"
   case privacy = "private"
   case notificationsStatus = "notificationsEnabled"

   var description: String { return self.rawValue }
}

enum EvaUserAccessLevel: String, CustomStringConvertible
{
   case Anonimous = "anon"
   case User = "user"
   case Moderator = "mod"
   case Admin = "admin"

   var description: String { return self.rawValue }
}

enum EvaUserBaseDetails: String, CustomStringConvertible
{
   case id = "id"
   case screenName = "screenName"
   case likeCount = "likeCount"
   case likedCount = "likedCount"
   case viewCount = "viewCount"
   case viewedCount = "viewedCount"
   case assetCount = "assetCount"
   case followerCount = "followerCount"
   case followingCount = "followingCount"
   case unviewedAssetCount = "unviewedAssetCount"
   case unreadNotificationsCount = "unreadNotificationsCount"
   case mediaAccount = "userMediaAccount"
   case role = "userRole"
   case rowversion = "rowversion"
   case FollowedByMeState = "followedByMeState"
   case FollowsMeState = "followsMeState"

   var description: String { return self.rawValue }
}

class EvaUser: NSObject, NSCoding, ServerResponseProtocol
{
   lazy var serverResponse: ServerResponse = ServerResponse(delegate: self)
   lazy var networkDelegate: UnsafeMutablePointer<Void> =  self.serverResponse.networkDelegate

   // EvaUserBaseDetails
   var userId: String?
   private var _screenName: String?
   var screenName: String? {
      get {
         if let screenName = self._screenName where screenName.hasPrefix("@") == false
         {
            return "@\(screenName)"
         }
         return self._screenName
      }
      set { self._screenName  = newValue }
   }
   var userFirstName: String?
   var userLastName: String?
   var likeCount: Int = 0
   var likeCountAsString: String? { return "\(self.likeCount)" }
   var likedCount: Int = 0
   var likedCountAsString: String? { return "\(self.likedCount)" }
   var viewCount: Int = 0
   var viewCountAsString: String? { return "\(self.viewCount)" }
   var viewedCount: Int = 0
   var viewedCountAsString: String? { return "\(self.viewedCount)" }
   var assetCount: Int = 0
   var assetCountAsString: String? { return "\(self.assetCount)" }
   var followerCount: Int = 0
   var followerCountAsString: String? { return "\(self.followerCount)" }
   var followingCount: Int = 0
   var followingCountAsString: String? { return "\(self.followingCount)" }
   var unviewedAssetCount: Int = 0
   var unviewedAssetCountAsString: String? { return "\(self.unviewedAssetCount)" }
   var unreadNotificationsCount: Int = 0
   var unreadNotificationsCountAsString: String? { return "\(self.unreadNotificationsCount)" }
   var role: EvaUserAccessLevel?
   var mediaAccount: String?
   private var rowversion: String?
   var privacy: Bool = true

   // EvaUserChangableDetails
   var avatarId: String?
   var avatarImage: UIImage = UIImage(named: "avatar")!
   var tagLine: String?
   var website: String?
   var followedByMeState: FollowState = FollowState.NotFollowing
   var followsMeState: FollowState = FollowState.NotFollowing

   lazy var details: String? = self.getDetails()

   override var description: String { return "\n{\n  id: \(self.userId)\n  screenName: \(self.screenName)\n  likeCount: \(self.likeCount)\n  likedCount: \(self.likedCount)\n  viewCount: \(self.viewCount)\n  viewedCount: \(self.viewedCount)\n  assetCount: \(self.assetCount)\n  followerCount: \(self.followerCount)\n  followingCount: \(self.followingCount)\n  unviewedAssetCount: \(self.unviewedAssetCount)\n unreadNotificationsCount: \(self.unreadNotificationsCount)\n  role: \(self.role)\n  mediaAccount: \(self.mediaAccount)\n  rowversion: \(self.rowversion)\n  avatarId: \(self.avatarId)\n  avatarImage: \(self.avatarImage)\n tagLine: \(self.tagLine)\n\n  website: \(self.website)\n  privacy: \(self.privacy)\n followedByMe: \(self.followedByMeState)\n  followsMe: \(self.followsMeState)\n  details: \(self.details)\n}\n"
   }

   override init()
   {
      super.init()
      self.serverResponse = ServerResponse(delegate: self)
   }

   required init?(coder aDecoder: NSCoder)
   {
      super.init()
      self.decodeWithDecoder(coder: aDecoder)
   }

   internal func updateDetails(possibleEvaUser: JsonDictionary)
   {
      // EvaUserBaseDetails
      if let userId = possibleEvaUser[EvaUserBaseDetails.id.description] as? String
      {
         self.userId = userId
      }

      if let screenName = possibleEvaUser[EvaUserBaseDetails.screenName.description] as? String
      {
         self.screenName = screenName
      }

      if let firstName = possibleEvaUser[EvaUserChangableDetails.firstName.description] as? String
      {
         self.userFirstName = firstName
      }

      if let lastName = possibleEvaUser[EvaUserChangableDetails.lastName.description] as? String
      {
         self.userLastName = lastName
      }

      if let likeCount = possibleEvaUser[EvaUserBaseDetails.likeCount.description] as? Int
      {
         self.likeCount = likeCount
      }

      if let likedCount = possibleEvaUser[EvaUserBaseDetails.likedCount.description] as? Int
      {
         self.likedCount = likedCount
      }

      if let viewCount = possibleEvaUser[EvaUserBaseDetails.viewCount.description] as? Int
      {
         self.viewCount = viewCount
      }

      if let viewedCount = possibleEvaUser[EvaUserBaseDetails.viewedCount.description] as? Int
      {
         self.viewedCount = viewedCount
      }

      if let assetCount = possibleEvaUser[EvaUserBaseDetails.assetCount.description] as? Int
      {
         self.assetCount = assetCount
      }

      if let followerCount = possibleEvaUser[EvaUserBaseDetails.followerCount.description] as? Int
      {
         self.followerCount = followerCount
      }

      if let followingCount = possibleEvaUser[EvaUserBaseDetails.followingCount.description] as? Int
      {
         self.followingCount = followingCount
      }

      if let unviewedAssetCount = possibleEvaUser[EvaUserBaseDetails.unviewedAssetCount.description] as? Int
      {
         self.unviewedAssetCount = unviewedAssetCount
      }

      if let unreadNotificationsCount = possibleEvaUser[EvaUserBaseDetails.unreadNotificationsCount.description] as? Int
      {
         self.unreadNotificationsCount = unreadNotificationsCount
      }

      if let role = possibleEvaUser[EvaUserBaseDetails.role.description] as? String
      {
         self.role = EvaUserAccessLevel(rawValue: role)
      }

      if let mediaAccount = possibleEvaUser[EvaUserBaseDetails.mediaAccount.description] as? String
      {
         self.mediaAccount = mediaAccount
      }

      if let rowversion = possibleEvaUser[EvaUserBaseDetails.rowversion.description] as? String
      {
         self.rowversion = rowversion
      }

      if let followedByMeState = possibleEvaUser[EvaUserBaseDetails.FollowedByMeState.description] as? String
      {
         self.followedByMeState = FollowState(rawValue: followedByMeState)!
      }

      if let followsMeState = possibleEvaUser[EvaUserBaseDetails.FollowsMeState.description] as? String
      {
         self.followsMeState = FollowState(rawValue: followsMeState)!
      }

      // EvaUserChangableDetails
      if let avatarId = possibleEvaUser[EvaUserChangableDetails.avatarId.description] as? String
      {
         if avatarId != self.avatarId { self.avatarId = avatarId }
      }

      if let privacy = possibleEvaUser[EvaUserChangableDetails.privacy.description] as? Bool
      {
         self.privacy = privacy
      }

      if let tagLine = possibleEvaUser[EvaUserChangableDetails.tagLine.description] as? String
      {
         self.tagLine = tagLine
      }

      if let _ = possibleEvaUser[EvaUserChangableDetails.website.description] as? String
      {
         self.website = tagLine
      }
   }

   func getDetails() -> String
   {
      return NSLocalizedString("\(self.likedCount) likedCount | \(self.assetCount) assetCount |  \(self.followerCount)  followerCount |  \(self.followingCount) followingCount", comment:"Eva User Details")
   }

   func updateProfile()
   {
      if NSThread.isMainThread()
      {
         weak var weakSelf = self
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { if let strongSelf = weakSelf { strongSelf.updateProfile() }}
      }
      else
      {
         if let userId = self.userId
         {
            EvaLogger.sharedInstance.logMessage("Getting profile details", .Custom)
            GetProfile(userId, self.networkDelegate)
         }
      }
   }

   // MARK: ServerResponseProtocol

   internal func errorResponse(serverError: ServerErrorType?, extraData: [String:AnyObject]?)
   {
      EvaLogger.sharedInstance.logMessage("ErrorResponse: \(serverError?.rawValue) data:\(extraData)", .Error)
      CLSLogv("ServerErrorResponse \(serverError?.rawValue)", getVaList([]))
   }

   internal func serverResponse(responseFrom: ServerResponseType, jsonString: String)
   {
      if responseFrom == .ChangeEmail
      {
         EvaLogger.sharedInstance.logMessage("Email succesfully changed")
      }
   }

   internal func serverResponse(responseFrom: ServerResponseType, jsonDictionary: JsonDictionary)
   {
      if responseFrom == ServerResponseType.GetProfile || responseFrom == ServerResponseType.UserSearch || responseFrom == ServerResponseType.UpdateProfile
      {
         self.updateDetails(jsonDictionary)
         NSNotificationCenter.defaultCenter().postNotificationName(NotificationsConstants.LOGGEDUSER_PROFILE_UPDATE, object: nil)
      }
      else if responseFrom == ServerResponseType.UpdateAvatar
      {
         if let avatarId = jsonDictionary[EvaUserChangableDetails.avatarId.description] as? String
         {
            if avatarId != self.avatarId
            {
               self.avatarId = avatarId
            }
         }
      }
   }

   internal func serverResponse(responseFrom: ServerResponseType, nextObject: String?, jsonDictionaryArray: [JsonDictionary]) { EvaLogger.sharedInstance.logMessage("ServerResponse jsonDictionaryArray not implemented", .Error) }

   // MARK: - Helper functions

   func setAvatarImageForImageView(inout imageView: UIImageView, width: Int = Constants.EVA_USER_SEARCH_AVATAR_IMAGE_SIZE)
   {
      if let avatarId = self.avatarId, userToken = SessionManager.sharedInstance.loggedInUser.userToken
      {
         let avatarUrl = URLUtils.urlForAvatarImage(avatarId, width: width)
         SDWebImageDownloader.sharedDownloader().setValue(userToken, forHTTPHeaderField: "X-Phoenix-Auth")
         imageView.sd_setImageWithURL(NSURL(string: avatarUrl), placeholderImage: UIImage(named: "avatar"))
      }
   }

   func isAdmin() -> Bool { return role == .Admin }

   // MARK: - NSCodingProtocol

   func decodeWithDecoder(coder aDecoder: NSCoder)
   {
      // EvaUserBaseDetails
      self.userId = aDecoder.decodeObjectForKey(EvaUserBaseDetails.id.description) as? String
      self.screenName = aDecoder.decodeObjectForKey(EvaUserBaseDetails.screenName.description) as? String
      self.likeCount = aDecoder.decodeIntegerForKey(EvaUserBaseDetails.likeCount.description)
      self.likedCount = aDecoder.decodeIntegerForKey(EvaUserBaseDetails.likedCount.description)
      self.viewCount = aDecoder.decodeIntegerForKey(EvaUserBaseDetails.viewCount.description)
      self.viewedCount = aDecoder.decodeIntegerForKey(EvaUserBaseDetails.viewedCount.description)
      self.assetCount = aDecoder.decodeIntegerForKey(EvaUserBaseDetails.assetCount.description)
      self.followerCount = aDecoder.decodeIntegerForKey(EvaUserBaseDetails.followerCount.description)
      self.followingCount = aDecoder.decodeIntegerForKey(EvaUserBaseDetails.followingCount.description)
      self.unviewedAssetCount = aDecoder.decodeIntegerForKey(EvaUserBaseDetails.unviewedAssetCount.description)
      self.unreadNotificationsCount = aDecoder.decodeIntegerForKey(EvaUserBaseDetails.unreadNotificationsCount.description)
      self.role = aDecoder.decodeObjectForKey(EvaUserBaseDetails.role.description) as? EvaUserAccessLevel
      self.mediaAccount = aDecoder.decodeObjectForKey(EvaUserBaseDetails.mediaAccount.description) as? String
      self.rowversion = aDecoder.decodeObjectForKey(EvaUserBaseDetails.rowversion.description) as? String
      //EvaUserChangableDetails
      self.avatarId = aDecoder.decodeObjectForKey(EvaUserChangableDetails.avatarId.description) as? String
      self.avatarImage = aDecoder.decodeObjectForKey(EvaUserChangableDetails.avatarImage.description) as! UIImage
      self.tagLine = aDecoder.decodeObjectForKey(EvaUserChangableDetails.tagLine.description) as? String
      self.website = aDecoder.decodeObjectForKey(EvaUserChangableDetails.website.description) as? String
      self.privacy = aDecoder.decodeBoolForKey(EvaUserChangableDetails.privacy.description)
      let followedByMe = aDecoder.decodeObjectForKey(EvaUserBaseDetails.FollowedByMeState.description) as? String
      if let followedByMe = followedByMe { self.followedByMeState = FollowState(rawValue: followedByMe)! }
      let followsMe = aDecoder.decodeObjectForKey(EvaUserBaseDetails.FollowsMeState.description) as? String
      if let followsMe = followsMe { self.followsMeState = FollowState(rawValue: followsMe)! }
   }

   func encodeWithCoder(aCoder: NSCoder)
   {
      // EvaUserBaseDetails
      aCoder.encodeObject(self.userId, forKey:EvaUserBaseDetails.id.description)
      aCoder.encodeObject(self.screenName, forKey:EvaUserBaseDetails.screenName.description)
      aCoder.encodeInteger(self.likeCount, forKey:EvaUserBaseDetails.likeCount.description)
      aCoder.encodeInteger(self.likedCount, forKey:EvaUserBaseDetails.likedCount.description)
      aCoder.encodeInteger(self.viewCount, forKey:EvaUserBaseDetails.viewCount.description)
      aCoder.encodeInteger(self.viewedCount, forKey:EvaUserBaseDetails.viewedCount.description)
      aCoder.encodeInteger(self.assetCount, forKey:EvaUserBaseDetails.assetCount.description)
      aCoder.encodeInteger(self.followerCount, forKey:EvaUserBaseDetails.followerCount.description)
      aCoder.encodeInteger(self.followingCount, forKey:EvaUserBaseDetails.followingCount.description)
      aCoder.encodeInteger(self.unviewedAssetCount, forKey:EvaUserBaseDetails.unviewedAssetCount.description)
      aCoder.encodeInteger(self.unreadNotificationsCount, forKey:EvaUserBaseDetails.unreadNotificationsCount.description)
      aCoder.encodeObject(self.role?.rawValue, forKey: EvaUserBaseDetails.role.description)
      aCoder.encodeObject(self.rowversion, forKey: EvaUserBaseDetails.rowversion.description)
      aCoder.encodeObject(self.mediaAccount, forKey: EvaUserBaseDetails.mediaAccount.description)
      //EvaUserChangableDetails
      aCoder.encodeObject(self.avatarId, forKey: EvaUserChangableDetails.avatarId.description)
      aCoder.encodeObject(self.avatarImage, forKey: EvaUserChangableDetails.avatarImage.description)
      aCoder.encodeObject(self.tagLine, forKey: EvaUserChangableDetails.tagLine.description)
      aCoder.encodeObject(self.website, forKey: EvaUserChangableDetails.website.description)
      aCoder.encodeBool(self.privacy, forKey: EvaUserChangableDetails.privacy.description)
      aCoder.encodeObject(self.followedByMeState.rawValue, forKey: EvaUserBaseDetails.FollowedByMeState.description)
      aCoder.encodeObject(self.followsMeState.rawValue, forKey: EvaUserBaseDetails.FollowsMeState.description)
   }
}

func ==(lhs: EvaUser, rhs: EvaUser) -> Bool { return lhs.userId == rhs.userId }
