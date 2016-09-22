//
//  ApprovedAsset+CoreDataProperties.swift
//  eva
//
//  Created by Panayiotis Stylianou on 14/11/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ApprovedAsset {

    @NSManaged var approved: NSNumber?
    @NSManaged var assetId: String?

}
