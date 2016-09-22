//
//  ImageUtils.swift
//  eva
//
//  Created by Alejandro Cuetos on 06/01/2015.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation

class ImageUtils
{
   internal class func pathForKey(key: String) -> NSString
   {
      let path: NSString = NSBundle.mainBundle().pathForResource("ApiUrls", ofType: "plist")!
      let dict = NSDictionary(contentsOfFile: path as String)

      let baseUrl: String =
      {
         if let userUrl = SessionManager.sharedInstance.loggedInUser.userURL where userUrl.isEmpty == false
         {
            return userUrl
         }
         else
         {
            return SessionManager.sharedInstance.baseUrl
         }
      }()

      let url = dict!.objectForKey(key) as! String

      return baseUrl + url
   }

   class func urlForAvatarImage(avatarId: String) -> String
   {
      return urlForAvatarImage(avatarId, width: Constants.EVA_USER_SEARCH_AVATAR_IMAGE_SIZE)
   }

   class func urlForAvatarImage(avatarId: String, width: Int) -> String
   {
      return NSString(format: ImageUtils.pathForKey("avatar_image_url"), avatarId, String(width)) as String
   }

   class func urlForAssetImage(assetId: String) -> String
   {
      return NSString(format: ImageUtils.pathForKey("asset_image_url"), assetId, String(Constants.ASSET_IMAGE_SIZE)) as String
   }

   class func urlForChannelImage(channelId: String) -> String
   {
      return NSString(format: ImageUtils.pathForKey("channel_image_url"), channelId, String(Constants.CHANNEL_IMAGE_SIZE)) as String
   }
}