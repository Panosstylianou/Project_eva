//
//  UploadEntry.swift
//  eva
//
//  Created by Panayiotis Stylianou on 16/11/2015.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation
import CoreData

class UploadEntry: NSManagedObject {

    @NSManaged var assetId: String
    @NSManaged var edlId: String
    @NSManaged var mediaId: String
    @NSManaged var obfusId: String
    @NSManaged var bytesSent: NSNumber
    @NSManaged var bytesTotal: NSNumber

}
