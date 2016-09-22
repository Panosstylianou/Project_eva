//
//  NSDateExtensions.swift
//  eva
//
//  Created by Panayiotis Stylianou on 08/01/2016.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation
import XCTest

class NSDateExtensionsTest: XCTestCase
{
   let minute: NSTimeInterval = 60
   let hour: NSTimeInterval = 60 * 60
   let day: NSTimeInterval = 60 * 60 * 24

   func testSecondsAgoStrings()
   {
      let twentySeconds: NSTimeInterval = 20
      let testDate = NSDate().dateByAddingTimeInterval(-twentySeconds)

      XCTAssert(testDate.elapsedTime == "20 seconds", "Seconds ago failed")
   }

   func testMinutesAgoStrings()
   {
      let twentyMinutes: NSTimeInterval = 20 * minute
      let testDate = NSDate().dateByAddingTimeInterval(-twentyMinutes)

      XCTAssert(testDate.elapsedTime == "20 minutes", "Minutes ago failed")
   }

   func testHoursAgoStrings()
   {
      let twoHours: NSTimeInterval = 2 * hour
      let testDate = NSDate().dateByAddingTimeInterval(-twoHours)

      XCTAssert(testDate.elapsedTime == "2 hours", "Hours ago failed")
   }

   func testYesterdayStrings()
   {
      let yesterday: NSTimeInterval = 1 * day
      let testDate = NSDate().dateByAddingTimeInterval(-yesterday)

      XCTAssert(testDate.elapsedTime == "yesterday", "Yesterday failed")
   }

   func testDaysAgoStrings()
   {
      let threeDays: NSTimeInterval = 3 * day
      let testDate = NSDate().dateByAddingTimeInterval(-threeDays)

      XCTAssert(testDate.elapsedTime == "3 days", "Days ago failed")
   }

   func testLastMonthAgoStrings()
   {
      let pastMonth: NSTimeInterval = 35 * day
      let testDate = NSDate().dateByAddingTimeInterval(-pastMonth)

      XCTAssert(testDate.elapsedTime == "last month", "Last month ago failed")
   }

   func testMonthsAgoStrings()
   {
      let twoMonths: NSTimeInterval = 75 * day
      let testDate = NSDate().dateByAddingTimeInterval(-twoMonths)

      XCTAssert(testDate.elapsedTime == "2 months", "Months ago failed")
   }

   func testYearAgoStrings()
   {
      let pastYear: NSTimeInterval = 1 * 365 * day
      let testDate = NSDate().dateByAddingTimeInterval(-pastYear)

      XCTAssert(testDate.elapsedTime == "year", "Year ago failed")
   }

   func testYearsAgoStrings()
   {
      let pastYear: NSTimeInterval = 2 * 365 * day
      let testDate = NSDate().dateByAddingTimeInterval(-pastYear)

      XCTAssert(testDate.elapsedTime == "year", "Years ago failed")
   }

   func testStringToDate()
   {
      let stringDate1: String = "2015-07-11T10:20:10"
      let stringDate2: String = "2015-07-11T10:20:10+0000"
      let stringDate3: String = "2015-01-31T00:00:10"
      let stringDate4: String = "2015-01-31T00:00:10+0000"
      let stringDate5: String = "2015-01-31T00:00:10Z"

      XCTAssert("\(stringDate1.date!)" == "2015-07-11 09:20:10 +0000", "String to NSDate in ISO8601sh failed")
      XCTAssert("\(stringDate2.date!)" == "2015-07-11 10:20:10 +0000", "String to NSDate in ISO8601 failed")
      XCTAssert("\(stringDate3.date!)" == "2015-01-31 00:00:10 +0000", "String to NSDate in ISO8601sh failed")
      XCTAssert("\(stringDate4.date!)" == "2015-01-31 00:00:10 +0000", "String to NSDate in ISO8601 failed")
      XCTAssert("\(stringDate5.date!)" == "2015-01-31 00:00:10 +0000", "String to NSDate in ISO8601 failed")
   }
}
