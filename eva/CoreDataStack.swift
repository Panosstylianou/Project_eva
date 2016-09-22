//
//  CoreDataStack.swift
//  eva
//
//  Created by Panayiotis Stylianou on 06/11/2015.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import CoreData

class CoreDataStack
{
   let modelName = "eva_db"
   let context: NSManagedObjectContext
   let psc: NSPersistentStoreCoordinator
   let model: NSManagedObjectModel
   var store: NSPersistentStore?

   init()
   {
      let modelURL = NSBundle.mainBundle().URLForResource(self.modelName, withExtension: "momd")

      model = NSManagedObjectModel(contentsOfURL: modelURL!)!
      psc = NSPersistentStoreCoordinator(managedObjectModel: model)
      context = NSManagedObjectContext()

      context.persistentStoreCoordinator = psc

      let storeURL = CoreDataStack.applicationDocumentsDirectory().URLByAppendingPathComponent(self.modelName)
      let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]

      do {
         store = try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
      } catch let error as NSError {
         EvaLogger.sharedInstance.logMessage("\(error.localizedDescription)", .Error)
         store = nil
      }

      if store == nil
      {
         do {
            try NSFileManager.defaultManager().removeItemAtURL(CoreDataStack.applicationDocumentsDirectory().URLByAppendingPathComponent(self.modelName))
         } catch let error as NSError {
            EvaLogger.sharedInstance.logMessage("\(error.localizedDescription)", .Error)
         }

         do {
            store = try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
         } catch let error as NSError {
            EvaLogger.sharedInstance.logMessage("\(error.localizedDescription)", .Error)
            store = nil
         }

         if store == nil
         {
            fatalError("Not able to migrate eva_db")
         }
      }
   }

   func saveContext()
   {
      if context.hasChanges
      {
         do {
            try context.save()
         } catch let error as NSError {
            EvaLogger.sharedInstance.logMessage("Error saving context: \(error.localizedDescription)", .Error)
         }
      }
   }

   class func applicationDocumentsDirectory() -> NSURL
   {
      let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
      return urls[0]
   }
}
