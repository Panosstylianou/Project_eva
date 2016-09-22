//
//  UploadEntryExtension.swift
//  eva
//
//  Created by Panayiotis Stylianou on 16/11/2015.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation
import CoreData

typealias UploadEntries = [UploadEntry]

func ==(lhs: UploadEntry, rhs: UploadEntry) -> Bool { return lhs.assetId == rhs.assetId && lhs.mediaId == rhs.mediaId }

extension UploadEntry
{
   class func entityInContext(ctx: NSManagedObjectContext) -> NSEntityDescription { return NSEntityDescription.entityForName("UploadEntry", inManagedObjectContext: ctx)! }

   class func findEntriesForAssetId(assetId: String, ctx: NSManagedObjectContext) -> UploadEntries?
   {
      let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "UploadEntry")
      fetchRequest.predicate = NSPredicate(format: "assetId == %@", assetId)

      let result: [AnyObject]?
      do {
         result = try ctx.executeFetchRequest(fetchRequest)
         if let entries = result as? UploadEntries where entries.isEmpty == false
         {
            return entries
         }
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("Error fetching: \(error.localizedDescription)", .Error)
      }

      return nil
   }

   class func addUploadEntry(assetId: String, edlId: String?, mediaId: String?, obfusId: String?, ctx: NSManagedObjectContext)
   {
      let uploadEntry = UploadEntry(entity: entityInContext(ctx), insertIntoManagedObjectContext: ctx)
      uploadEntry.assetId = assetId
      if let edlId = edlId { uploadEntry.edlId = edlId }
      if let mediaId = mediaId { uploadEntry.mediaId = mediaId }
      if let obfusId = obfusId { uploadEntry.obfusId = obfusId }

      do {
         try ctx.save()
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("Error saving UploadEntry: \(error.localizedDescription))", .Error)
      }
   }

   class func findUploadEntryForMediaId(mediaId: String, ctx: NSManagedObjectContext) -> UploadEntry?
   {
      let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "UploadEntry")
      fetchRequest.predicate = NSPredicate(format: "mediaId == %@", mediaId)
      fetchRequest.fetchLimit = 1

      let result: [AnyObject]?
      do {
         result = try ctx.executeFetchRequest(fetchRequest)
         if let entries = result as? UploadEntries where entries.isEmpty == false
         {
            return entries.first
         }
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("Error fetching: \(error.localizedDescription)", .Error)
      }

      return nil
   }

   class func findUploadEntryForObfusId(obfusId: String, ctx: NSManagedObjectContext) -> UploadEntry?
   {
      let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "UploadEntry")
      fetchRequest.predicate = NSPredicate(format: "obfusId == %@", obfusId)
      fetchRequest.fetchLimit = 1

      let result: [AnyObject]?
      do {
         result = try ctx.executeFetchRequest(fetchRequest)
         if let entries = result as? UploadEntries where entries.isEmpty == false
         {
            return entries.first
         }
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("Error fetching: \(error.localizedDescription)", .Error)
      }

      return nil
   }

   class func deleteUploadEntry(uploadEntry: UploadEntry, ctx: NSManagedObjectContext)
   {
      ctx.deleteObject(uploadEntry)

      do {
         try ctx.save()
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("Error deleting UploadEntry: \(error.localizedDescription))", .Error)
      }
   }

   class func updateUploadEntry(uploadEntry: UploadEntry, ctx: NSManagedObjectContext)
   {
      do {
         try ctx.save()
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("Error updating UploadEntry: \(error.localizedDescription))", .Error)
      }
   }

   class func getUploadValue(ctx: NSManagedObjectContext) -> Float
   {
      let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "UploadEntry")

      let result: [AnyObject]?
      do {
         result = try ctx.executeFetchRequest(fetchRequest)
         if let entries = result as? [UploadEntry] where entries.isEmpty == false
         {
            let uploaded: UInt64 = entries.map({ return $0.bytesSent.unsignedLongLongValue }).reduce(0, combine: +)
            let total: UInt64 = entries.map({ return $0.bytesTotal.unsignedLongLongValue }).reduce(0, combine: +)

            if total == 0
            {
               return 1.0
            }
            var progress: Float = Float(uploaded) / Float(total)
            progress = progress > 1.0 ? 1.0 : progress

            return progress
         }
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("Error fetching UploadValues: \(error.localizedDescription)", .Error)
      }

      return 1.0
   }
}
