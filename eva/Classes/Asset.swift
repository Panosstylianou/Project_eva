//
//  AssetResponse.swift
//  eva
//
//  Created by Panayiotis Stylianou on 05/12/2015.
//  Copyright (c) 2014 Forbidden Technologies PLC. All rights reserved.
//

import Foundation

protocol AssetProtocol
{
   func updateOfAsset()
   func didRecordAssetView(asset: Asset)
}

class Asset: NSObject
{
   // MARK: - Mapping keys

   enum AssetBaseDetails: String, CustomStringConvertible
   {
      case id = "id"
      case edlId = "edlId"
      case userId = "userId"
      case userScreenName = "userScreenName"
      case userAvatarId = "userAvatarId"
      case userFollowedByMeState = "userFollowedByMeState"
      case userPrivate = "userPrivate"
      case moderatorFlags = "moderatorFlags"
      case userRowVersion = "userRowVersion"
      case assetDescription = "description"
      case likedByMe = "likedByMe"
      case likeCount = "likeCount"
      case commentCount = "commentCount"
      case mediaAccount = "mediaAccount"
      case createdTime = "createdTime"
      case uploaded = "uploaded"
      case shareUrl = "shareUrl"

      var description: String { return self.rawValue }
   }

   // MARK: - Delegates

   lazy var serverResponse: ServerResponse = ServerResponse(delegate: self)
   lazy var networkDelegate: UnsafeMutablePointer<Void> =  self.serverResponse.networkDelegate
   var assetProtocolDelegate: AssetProtocol?

   // MARK: - Properties

   var id: String?
   var edlId: String?
   var userId: String?
   var followedByMeState: FollowState?
   var userPrivate: Bool = false
   var userAvatarId: String?
   lazy var moderatorFlags: Flags = Flags()
   var userRowVersion: String?
   var assetDescription: String?
   var likedByMe: Bool = false
   var likeCount: Int = 0
   var commentCount: Int = 0
   var mediaAccount: String?
   var screenName: String? { return self.userScreenName }
   var startTime: Int64 = -1
   var endTime: Int64 = -1
   var createdTime: NSDate?
   var uploaded: Bool = false
   var shareUrl: String?
   var userScreenName: String? {
      get {
         let prefix = NSLocalizedString("prefix", comment:"EvaUser screenName with prefix")
         if let screenName = self._userScreenName { return "\(prefix)\(screenName)" }

         return "\(prefix)"
      }
      set { self._userScreenName  = newValue }
   }
   private var _userScreenName: String?

   // MARK: - Initializers

   init(possibleAsset: JsonDictionary)
   {
      super.init()
      self.updateAssetDetails(possibleAsset)
   }

   required init?(coder aDecoder: NSCoder)
   {
      super.init()
      self.decodeWithDecoder(coder: aDecoder)
   }

   func updateAssetDetails(possibleAsset: JsonDictionary)
   {
      if let id = possibleAsset[AssetBaseDetails.id.description] as? String
      {
         self.id = id
      }
      if let edlId = possibleAsset[AssetBaseDetails.edlId.description] as? String
      {
         self.edlId = edlId
      }
      if let userId = possibleAsset[AssetBaseDetails.userId.description] as? String
      {
         self.userId = userId
      }
      if let userScreenName = possibleAsset[AssetBaseDetails.userScreenName.description] as? String
      {
         self.userScreenName = userScreenName
      }
      if let followedByMeState = possibleAsset[AssetBaseDetails.userFollowedByMeState.description] as? String
      {
         self.followedByMeState = FollowState(rawValue: followedByMeState)
      }
      if let userPrivate = possibleAsset[AssetBaseDetails.userPrivate.description] as? Bool
      {
         self.userPrivate = userPrivate
      }
      if let userAvatarId = possibleAsset[AssetBaseDetails.userAvatarId.description] as? String
      {
         self.userAvatarId = userAvatarId
      }
      if let moderatorFlags = possibleAsset[AssetBaseDetails.moderatorFlags.description]  as? [String]
      {
         for moderatorFlag in moderatorFlags
         {
            if moderatorFlag.isEmpty == false
            {
               self.moderatorFlags.append(moderatorFlag)
            }
         }
      }
      if let userRowVersion = possibleAsset[AssetBaseDetails.userRowVersion.description] as? String
      {
         self.userRowVersion = userRowVersion
      }
      if let assetDescription = possibleAsset[AssetBaseDetails.assetDescription.description] as? String
      {
         self.assetDescription = assetDescription
      }
      if let shareUrl = possibleAsset[AssetBaseDetails.shareUrl.description] as? String
      {
         self.shareUrl = shareUrl
      }
      if let likedByMe = possibleAsset[AssetBaseDetails.likedByMe.description] as? Bool
      {
         self.likedByMe = likedByMe
      }
      if let commentCount = possibleAsset[AssetBaseDetails.commentCount.description] as? Int
      {
         self.commentCount = commentCount
      }
      if let likeCount = possibleAsset[AssetBaseDetails.likeCount.description] as? Int
      {
         self.likeCount = likeCount
      }
      if let mediaAccount = possibleAsset[AssetBaseDetails.mediaAccount.description] as? String
      {
         self.mediaAccount = mediaAccount
      }
      if let createdTime = possibleAsset[AssetBaseDetails.createdTime.description] as? String
      {
         self.createdTime = createdTime.date
      }
      if let uploaded = possibleAsset[AssetBaseDetails.uploaded.description] as? Bool
      {
         self.uploaded = uploaded
      }
   }

   // MARK: - Helper functions

   func setAvatarImageForImageView(inout imageView: UIImageView)
   {
      if let avatarId = self.userAvatarId, userToken = SessionManager.sharedInstance.loggedInUser.userToken where avatarId.isEmpty == false
      {
         dispatch_async(dispatch_get_main_queue())
         {
            let avatarUrl = URLUtils.urlForAvatarImage(avatarId)
            SDWebImageDownloader.sharedDownloader().setValue(userToken, forHTTPHeaderField: "X-Phoenix-Auth")
            imageView.sd_setImageWithURL(NSURL(string: avatarUrl), placeholderImage: UIImage(named: "avatar"))
         }
      }
      else
      {
         imageView.image = UIImage(named: "avatar")
      }
   }

   func setThumbnailImageForImageView(inout imageView: UIImageView)
   {
      if let assetId = self.id, userToken = SessionManager.sharedInstance.loggedInUser.userToken
      {
         let thumbnailUrl = URLUtils.urlForAssetImage(assetId)
         SDWebImageDownloader.sharedDownloader().setValue(userToken, forHTTPHeaderField: "X-Phoenix-Auth")
         imageView.sd_setImageWithURL(NSURL(string: thumbnailUrl))
      }
      else
      {
         EvaLogger.sharedInstance.logMessage("Asset don't have a correct ID", .Error)
      }
   }

   func changeLikedByMeState(inPoint inPoint: CGFloat)
   {
      self.likedByMe ? --self.likeCount : ++self.likeCount
      BridgeObjC.likeAsset(self.id, trash: self.likedByMe, inPoint: inPoint, delegate: self.networkDelegate)
      self.likedByMe = !self.likedByMe
   }

   func recordView(inPoint: Float, outPoint: Float)
   {
      EvaLogger.sharedInstance.logMessage("Asset: \(id) view record")
      AssetAddView(inPoint, outPoint, self.id!, self.networkDelegate)
   }

   func flagItAs(flag: String)
   {
      EvaLogger.sharedInstance.logMessage("Marking asset: \(id) as \(flag) content")
      AssetFlag(id!, flag, false, 0, self.networkDelegate)
   }
}

// MARK: - Printable

extension Asset
{
   override var description: String
      {
         return "{\n id: \(self.id) \n edlId: \(self.edlId) \n userId: \(self.userId) \n userScreenName: \(self.userScreenName) \n userFollowedByMe: \(self.followedByMeState) \n userAvatarId: \(self.userAvatarId) \n  moderatorFlags: \(self.moderatorFlags) \n userRowVersion: \(self.userRowVersion) \n  assetDescription: \(self.assetDescription) \n likedByMe: \(self.likedByMe) \n likeCount: \(self.likeCount) \n commentCount: \(self.commentCount) \n  mediaAccount: \(self.mediaAccount)\n startTime: \(self.startTime)\n endTime: \(self.endTime)\n createdTime: \(self.createdTime)\n elpasedTime: \(self.createdTime?.elapsedTime)\n shareUrl: \(self.shareUrl)\n}"
   }
}

// MARK: - NSCoding

extension Asset: NSCoding
{
   func decodeWithDecoder(coder aDecoder: NSCoder)
   {
      self.id = aDecoder.decodeObjectForKey(AssetBaseDetails.id.description) as? String
      self.edlId = aDecoder.decodeObjectForKey(AssetBaseDetails.edlId.description) as? String
      self.userId = aDecoder.decodeObjectForKey(AssetBaseDetails.userId.description) as? String
      self.userScreenName = aDecoder.decodeObjectForKey(AssetBaseDetails.userScreenName.description) as? String
      self.userAvatarId = aDecoder.decodeObjectForKey(AssetBaseDetails.userAvatarId.description) as? String
      self.followedByMeState = FollowState(rawValue: aDecoder.decodeObjectForKey(AssetBaseDetails.userFollowedByMeState.description) as! String)
      self.userPrivate = aDecoder.decodeObjectForKey(AssetBaseDetails.userPrivate.description) as! Bool
      self.moderatorFlags = aDecoder.decodeObjectForKey(AssetBaseDetails.moderatorFlags.description) as! Flags
      self.userRowVersion = aDecoder.decodeObjectForKey(AssetBaseDetails.userRowVersion.description) as? String
      self.assetDescription = aDecoder.decodeObjectForKey(AssetBaseDetails.assetDescription.description) as? String
      self.likedByMe = aDecoder.decodeBoolForKey(AssetBaseDetails.likedByMe.description)
      self.likeCount = aDecoder.decodeIntegerForKey(AssetBaseDetails.likeCount.description)
      self.commentCount = aDecoder.decodeIntegerForKey(AssetBaseDetails.commentCount.description)
      self.mediaAccount = aDecoder.decodeObjectForKey(AssetBaseDetails.mediaAccount.description) as? String
      self.createdTime = aDecoder.decodeObjectForKey(AssetBaseDetails.createdTime.description) as? NSDate
      self.uploaded = aDecoder.decodeBoolForKey(AssetBaseDetails.uploaded.description)
   }

   func encodeWithCoder(aCoder: NSCoder)
   {
      aCoder.encodeObject(self.id, forKey: AssetBaseDetails.id.description)
      aCoder.encodeObject(self.userId, forKey: AssetBaseDetails.userId.description)
      aCoder.encodeObject(self.userScreenName, forKey: AssetBaseDetails.userScreenName.description)
      aCoder.encodeObject(self.userAvatarId, forKey: AssetBaseDetails.userAvatarId.description)
      aCoder.encodeObject(self.followedByMeState?.rawValue, forKey: AssetBaseDetails.userFollowedByMeState.description)
      aCoder.encodeBool(self.userPrivate, forKey: AssetBaseDetails.userPrivate.description)
      aCoder.encodeObject(self.moderatorFlags, forKey: AssetBaseDetails.moderatorFlags.description)
      aCoder.encodeObject(self.userRowVersion, forKey: AssetBaseDetails.userRowVersion.description)
      aCoder.encodeObject(self.assetDescription, forKey: AssetBaseDetails.assetDescription.description)
      aCoder.encodeBool(self.likedByMe , forKey: AssetBaseDetails.likedByMe.description)
      aCoder.encodeInteger(self.likeCount, forKey: AssetBaseDetails.likeCount.description)
      aCoder.encodeInteger(self.commentCount, forKey: AssetBaseDetails.commentCount.description)
      aCoder.encodeObject(self.mediaAccount, forKey: AssetBaseDetails.mediaAccount.description)
      aCoder.encodeObject(self.createdTime, forKey: AssetBaseDetails.createdTime.description)
      aCoder.encodeObject(self.uploaded, forKey: AssetBaseDetails.uploaded.description)
   }
}

// MARK: ServerResponseProtocol

extension Asset: ServerResponseProtocol
{
   internal func errorResponse(serverError:ServerErrorType?, extraData: [String:AnyObject]?) { EvaLogger.sharedInstance.logMessage("ServerResponse network error: \(serverError?.description)", .Error) }

   internal func serverResponse(responseFrom: ServerResponseType, jsonString: String)
   {
      switch responseFrom
      {
      case .AssetLike where jsonString == "ok":
         EvaLogger.sharedInstance.logMessage("Asset with ID: \(self.edlId) like status changed")
         self.assetProtocolDelegate?.updateOfAsset()

      case .Follow where jsonString == "ok":
         EvaLogger.sharedInstance.logMessage("User with ID: \(self.userId) followed by my status is: \(self.followedByMeState)")

      case .AssetAddView:
         self.assetProtocolDelegate?.didRecordAssetView(self)

      case .AssetFlag where jsonString == "ok":
         EvaLogger.sharedInstance.logMessage("Asset flagged")

      default:
         EvaLogger.sharedInstance.logMessage("Not recognized response", .Error)
      }
   }

   internal func serverResponse(responseFrom: ServerResponseType, jsonDictionary: JsonDictionary) { EvaLogger.sharedInstance.logMessage("jsonDictionary response not implemented", .Error) }

   internal func serverResponse(responseFrom: ServerResponseType, nextObject: String?, jsonDictionaryArray: [JsonDictionary]) { EvaLogger.sharedInstance.logMessage("jsonDictionaryArray response not implemented", .Error) }
}

func ==(lhs: Asset, rhs: Asset) -> Bool { return lhs.id == rhs.id }
