//
//  Analytics.swift
//  eva
//
//  Created by Panayiotis Stylianou on 07/12/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation

class Analytics
{
   enum TaggingServices { case Localytics }

   class func startTrackingServices(services: TaggingServices...)
   {
      for service in services
      {
         switch service
         {
         case .Localytics:
            Localytics.openSession()
         }
      }
   }

   class func tagScreen(taggingDescription: String, service: TaggingServices = .Localytics)
   {
      switch service
      {

      case .Localytics:
         Localytics.tagScreen(taggingDescription)
      }
   }

   class func tagEvent(eventDescription: String, service: TaggingServices = .Localytics)
   {
      switch service
      {

      case .Localytics:
         Localytics.tagEvent(eventDescription)
      }
   }

   class func setCustomerId(customerId: String, service: TaggingServices = .Localytics)
   {
      switch service
      {

      case .Localytics:
         Localytics.setCustomerId(customerId)
      }
   }

   class func setCustomerFullName(customerFullName: String, service: TaggingServices = .Localytics)
   {
      switch service
      {

      case .Localytics:
         Localytics.setCustomerFullName(customerFullName)
      }
   }
}
