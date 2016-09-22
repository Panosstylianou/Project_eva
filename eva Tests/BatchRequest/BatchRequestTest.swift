//
//  BatchRequestTest.swift
//  eva
//
//  Created by Panayiotis Stylianou on 08/01/2016.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation
import XCTest

class BatchRequestTest: XCTestCase
{
   func testEmptyBatchRequest()
   {
      let bRequest: BatchRequest = BatchRequest()
      XCTAssert(bRequest.getRequestJsonString() == "", "BatchRequest empty failed")
   }

   func testOneRequestBatchRequest()
   {
      var bRequest: BatchRequest = BatchRequest()
      let requestItem: BatchRequestItem = BatchRequestItem(path: "/url/to/test", method: .Get, body: nil, key: "request1")
      bRequest.addRequest(requestItem)
      XCTAssert(bRequest.getRequestJsonString() == "[{\"method\":\"GET\",\"key\":\"request1\",\"path\":\"\\/url\\/to\\/test\"}]", "BatchRequest one request failed")
   }

   func testTwoRequestsBatchRequest()
   {
      var bRequest: BatchRequest = BatchRequest()
      let requestItem: BatchRequestItem = BatchRequestItem(path: "/url/to/test", method: .Get, body: nil, key: "request1")
      let requestItem2: BatchRequestItem = BatchRequestItem(path: "/url/to/test1", method: .Post, body: nil, key: "request2")
      bRequest.addRequests(requestItem, requestItem2)
      XCTAssert(bRequest.getRequestJsonString() == "[{\"method\":\"GET\",\"key\":\"request1\",\"path\":\"\\/url\\/to\\/test\"},{\"method\":\"POST\",\"key\":\"request2\",\"path\":\"\\/url\\/to\\/test1\"}]", "BatchRequest two requests failed")
   }
}
