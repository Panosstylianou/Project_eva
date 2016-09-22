//
//  DictionaryExtensionsTest.swift
//  eva
//
//  Created by Panayiotis Stylianou on 08/01/2016.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation
import XCTest

class DictionaryExtensionsTest: XCTestCase
{
   func testDictionaryHasKey()
   {
      let emptyDictionary: [String:String] = [String:String]()
      let noEmptyDictionary: [String:String] = ["key1":"value1", "key2":"value2", "key3":"value3"]

      XCTAssert(emptyDictionary.dictionaryHasKey("key1") == false, "dictionaryHasKey in DictionaryTools not working properly")
      XCTAssert(noEmptyDictionary.dictionaryHasKey("key1") == true, "dictionaryHasKey in DictionaryTools not working properly")
      XCTAssert(noEmptyDictionary.dictionaryHasKey("key3") == true, "dictionaryHasKey in DictionaryTools not working properly")
      XCTAssert(noEmptyDictionary.dictionaryHasKey("key4") == false, "dictionaryHasKey in DictionaryTools not working properly")
   }
}
