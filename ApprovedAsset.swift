//
//  ApprovedAsset.swift
//  eva
//
//  Created by Panayiotis Stylianou on 14/11/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation
import CoreData
import Crashlytics

class ApprovedAsset: NSManagedObject
{
   class func entityInContext(ctx: NSManagedObjectContext) -> NSEntityDescription { return NSEntityDescription.entityForName("ApprovedAsset", inManagedObjectContext: ctx)! }

   class func findApprovedAsset(assetId: String, ctx: NSManagedObjectContext) -> ApprovedAsset?
   {
      let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "ApprovedAsset")
      fetchRequest.predicate = NSPredicate(format: "assetId == %@", assetId)
      fetchRequest.fetchLimit = 1

      let result: [AnyObject]?
      do {
         result = try ctx.executeFetchRequest(fetchRequest)
         if let entries = result as? [ApprovedAsset] where entries.isEmpty == false
         {
            return entries.first
         }
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("Error fetching: \(error.localizedDescription)", .Error)
      }

      return nil
   }

   class func addApprovedAsset(assetId: String, approved: Bool, ctx: NSManagedObjectContext)
   {
      let approvedAsset = ApprovedAsset(entity: entityInContext(ctx), insertIntoManagedObjectContext: ctx)
      approvedAsset.assetId = assetId
      approvedAsset.approved = approved

      do {
         try ctx.save()
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("Error saving ApprovedAsset: \(error.localizedDescription))", .Error)
         CLSLogv("Error saving Approved Asset: \(error.localizedDescription)", getVaList([]))
      }
   }

   class func deleteApprovedAsset(approvedAsset: ApprovedAsset, ctx: NSManagedObjectContext)
   {
      ctx.deleteObject(approvedAsset)

      do {
         try ctx.save()
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("Error deleting ApprovedAsset: \(error.localizedDescription))", .Error)
         CLSLogv("Error deleting Approved Asset: \(error.localizedDescription)", getVaList([]))
      }
   }

   class func updateApprovedAsset(approvedAsset: ApprovedAsset, ctx: NSManagedObjectContext)
   {
      do {
         try ctx.save()
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("Error updating ApprovedAsset: \(error.localizedDescription))", .Error)
      }
   }
}
