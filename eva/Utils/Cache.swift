//
//  Cache.swift
//  eva
//
//  Created by Joseph Caxton-Idowu on 19/11/2014.
//  Copyright (c) 2014 Forbidden Technologies PLC. All rights reserved.
//

import Foundation


class Cache
{
   var FileManager : NSFileManager!

   func writeImageDataToCache(dataToWrite : NSData, screenName: String)
   {
      let path = self.getCacheDirectoryOnDevice()
      if path != ""
      {
         let pathName : String = "\(path)/\(screenName)"
         FileManager.createFileAtPath(pathName, contents: dataToWrite, attributes: nil)
         println("File Created")
      }

   }

   init()
   {
      FileManager = NSFileManager.defaultManager()
   }

   private func getCacheDirectoryOnDevice() -> String
   {
      var error : NSError? = nil

      // Framework bug here this does not crete the directory
      let DirectoryPath : NSURL = FileManager.URLForDirectory(NSSearchPathDirectory.CachesDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: NSURL(fileURLWithPath:"ForbiddenCache"), create: true, error: &error)!

      if error == nil
      {
         FileManager.createDirectoryAtPath( "\(DirectoryPath)", withIntermediateDirectories: false, attributes: nil, error: &error)
         return "\(DirectoryPath)ForbiddenCache"
      }
      return ""
   }
}
