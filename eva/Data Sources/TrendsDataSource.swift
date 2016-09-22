//
//  TrendsDataSource.swift
//  eva
//
//  Created by Panayiotis Stylianou on 21/02/2016.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation

struct Trend
{
   enum TrendDataKeys: String
   {
      case TagName = "tag"
      case TagCount = "count"
   }

   var tagName: String?
   var tagCount: Int?

   init(jsonDictionary: JsonDictionary)
   {
      if let tName = jsonDictionary[TrendDataKeys.TagName.rawValue] as? String
      {
         tagName = tName
      }

      if let tCount = jsonDictionary[TrendDataKeys.TagCount.rawValue] as? Int
      {
         tagCount = tCount
      }
   }
}

class TrendsDataSource: NSObject
{
   /**
   Enum for representing the possible time periods
   of the Trends data source

   - Day:   Trends of the day
   - Week:  Trends of the week
   - Month: Trends of the month
   - Year:  Trends of the year
   */
   enum TrendsTimePeriod: String
   {
      case Day = "day"
      case Week = "week"
      case Month = "month"
      case Year = "year"
   }

   // MARK: - ServerResponse

   lazy var serverResponse:ServerResponse = ServerResponse(delegate:self)
   lazy var networkDelegate: UnsafeMutablePointer<Void> = self.serverResponse.networkDelegate

   // MARK: - Delegates

   var delegate: DataSourceProtocol?

   // MARK: - Properties

   var count: Int { return self.dataSource.count }
   var isEmpty: Bool { return self.dataSource.isEmpty }
   var dataSource: [String:[Trend]] = [:]
   var currentTimePeriod: TrendsDataSource.TrendsTimePeriod = .Day

   // MARK: - Initializers

   init(delegate: DataSourceProtocol?) { self.delegate = delegate }

   // MARK: - Search methods

   func fetchTrends(limit: Int = 20)
   {
      var batchRequest: BatchRequest = BatchRequest()

      let requestDay: BatchRequestItem = BatchRequestItem(path: "/api/1/searchTrends?period=\(TrendsTimePeriod.Day.rawValue)&fallback=year&limit=\(limit)", method: .Get, body: nil, key: TrendsTimePeriod.Day.rawValue)
      let requestWeek: BatchRequestItem = BatchRequestItem(path: "/api/1/searchTrends?period=\(TrendsTimePeriod.Week.rawValue)&fallback=year&limit=\(limit)", method: .Get, body: nil, key: TrendsTimePeriod.Week.rawValue)
      let requestMonth: BatchRequestItem = BatchRequestItem(path: "/api/1/searchTrends?period=\(TrendsTimePeriod.Month.rawValue)&fallback=year&limit=\(limit)", method: .Get, body: nil, key: TrendsTimePeriod.Month.rawValue)

      batchRequest.addRequest(requestDay)
      batchRequest.addRequest(requestWeek)
      batchRequest.addRequest(requestMonth)

      if batchRequest.count == 3
      {
         let path1: NSString = batchRequest.requestsItems[0].path
         let method1: NSString = batchRequest.requestsItems[0].method!.rawValue as String
         let key1: NSString = batchRequest.requestsItems[0].key!

         let path2: NSString = batchRequest.requestsItems[1].path
         let method2: NSString = batchRequest.requestsItems[1].method!.rawValue as String
         let key2: NSString = batchRequest.requestsItems[1].key!

         let path3: NSString = batchRequest.requestsItems[2].path
         let method3: NSString = batchRequest.requestsItems[2].method!.rawValue as String
         let key3: NSString = batchRequest.requestsItems[2].key!

         BatchRequestAction3(path1.UTF8String, method1.UTF8String, key1.UTF8String, path2.UTF8String, method2.UTF8String, key2.UTF8String, path3.UTF8String, method3.UTF8String, key3.UTF8String, self.networkDelegate)
      }
      else
      {
         fatalError("Not enough requests")
      }
   }

   func trendsForTimePeriod(timePeriod: TrendsTimePeriod) -> [Trend]? { return dataSource[timePeriod.rawValue] }
}

extension TrendsDataSource: ServerResponseProtocol
{
   func errorResponse(networkError: ServerErrorType?, extraData: [String:AnyObject]?) { EvaLogger.sharedInstance.logMessage("ServerResponse network error: \(networkError)", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonString: String) { EvaLogger.sharedInstance.logMessage("jsonString is not implemented", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonDictionary: JsonDictionary) { EvaLogger.sharedInstance.logMessage("jsonDictionary is not implemented", .Error) }

   func serverResponse(responseFrom: ServerResponseType, nextObject: String?, jsonDictionaryArray: [JsonDictionary])
   {
      if jsonDictionaryArray.isEmpty == false
      {
         for trendsBlock: JsonDictionary in jsonDictionaryArray
         {
            let key: String = trendsBlock["key"] as! String
            let results: [JsonDictionary] = trendsBlock["results"] as! [JsonDictionary]
            var trends: [Trend] = [Trend]()
            for trend: JsonDictionary in results
            {
               let tag: Trend = Trend(jsonDictionary: trend)
               trends.append(tag)
            }
            dataSource[key] = trends
         }
         delegate?.refreshData()
      }
   }
}
