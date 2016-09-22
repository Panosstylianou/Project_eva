//
//  EDLFileTest.swift
//  eva
//
//  Created by Panayiotis Stylianou on 08/01/2016.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation
import XCTest

class EDLFileTest: XCTestCase
{
   let mediaId1: String = "1431620708-000000-gr6-0000"
   let mediaId2: String = "1431623144-000000-gr6-0000"
   let duration1: Int64 = 3633
   let duration2: Int64 = 2367
   let duration3: Int64 = 1000

   let pair1: String = "video 1431620708-000000-gr6-0000.v0 00:00:00.000-00:00:03.633\naudio 1431620708-000000-gr6-0000.a0 00:00:00.000-00:00:03.633\n"
   let pair2: String = "video 1431623144-000000-gr6-0000.v0 00:00:00.000-00:00:02.367\naudio 1431623144-000000-gr6-0000.a0 00:00:00.000-00:00:02.367\n"

   let fileOneClip: String = "%EDL\nntsc\nvideo 1431620708-000000-gr6-0000.v0 00:00:00.000-00:00:03.633\naudio 1431620708-000000-gr6-0000.a0 00:00:00.000-00:00:03.633\n"
   let fileTwoClip: String = "%EDL\nntsc\nvideo 1431620708-000000-gr6-0000.v0 00:00:00.000-00:00:03.633\naudio 1431620708-000000-gr6-0000.a0 00:00:00.000-00:00:03.633\nvideo 1431623144-000000-gr6-0000.v0 00:00:00.000-00:00:02.367\naudio 1431623144-000000-gr6-0000.a0 00:00:00.000-00:00:02.367\n"
   let fileNoClips: String = "%EDL\nntsc\n"
   let fileLiveClip: String = "%EDL\nntsc\nvideo 1431620708-000000-gr6-0000.v0 00:00:00.000-00:00:01.000 live upload\naudio 1431620708-000000-gr6-0000.a0 00:00:00.000-00:00:01.000 live upload\n"

   let milliSeconds1: Int64 = 5578380
   let convertedString1: String = "01:32:58.380"

   let milliSeconds2: Int64 = 1800
   let convertedString2: String = "00:00:01.800"

   let milliSeconds3: Int64 = 800
   let convertedString3: String = "00:00:00.800"

   let milliSeconds4: Int64 = 1932580
   let convertedString4: String = "00:32:12.580"

   let edlString: String = "%EDL\nntsc\nvideo 1445426701-000000-gr6-0000.v0 00:00:00.000-00:00:04.900\naudio 1445426701-000000-gr6-0000.a0 00:00:00.000-00:00:04.900\n"

   let eldWithComment: String = "%EDL\nntsc\nvideo 1431620708-000000-gr6-0000.v0 00:00:00.000-00:00:03.633\naudio 1431620708-000000-gr6-0000.a0 00:00:00.000-00:00:03.633\n#OS: iOS\n#VERSION: 1.0.0\n"

   func testClipRepresentation()
   {
      let clip: ClipRepresentation = ClipRepresentation(mediaId: mediaId1, obfusId: mediaId1, startTime: 0, endTime: duration1)
      let clip2: ClipRepresentation = ClipRepresentation(mediaId: mediaId2, obfusId: mediaId2, startTime: 0, endTime: duration2)
      XCTAssert(clip.representation! == pair1, "ClipRepresentation for first clip is not correct")
      XCTAssert(clip2.representation! == pair2, "ClipRepresentation for second clip is not correct")
   }

   func testFileWithNoClips()
   {
      let emptyEDLFile: EDLFile = EDLFile(format: .NTSC)

      XCTAssert(emptyEDLFile.getFileRepresentation() == fileNoClips, "EDL empty file representation is not correct")
   }

   func testFileWithOneClip()
   {
      let clip: ClipRepresentation = ClipRepresentation(mediaId: mediaId1, obfusId: mediaId1, startTime: 0, endTime: duration1)
      var oneClipEDLFile: EDLFile = EDLFile(format: .NTSC)
      oneClipEDLFile.appendClip(clip)

      XCTAssert(oneClipEDLFile.getFileRepresentation() == fileOneClip, "EDL one clip file representation is not correct")
   }

   func testFileWithTwoClips()
   {
      let clip: ClipRepresentation = ClipRepresentation(mediaId: mediaId1, obfusId: mediaId1, startTime: 0, endTime: duration1)
      let clip2: ClipRepresentation = ClipRepresentation(mediaId: mediaId2, obfusId: mediaId2, startTime: 0, endTime: duration2)
      var twoClipEDLFile: EDLFile = EDLFile(format: .NTSC)
      twoClipEDLFile.appendClip(clip)
      twoClipEDLFile.appendClip(clip2)

      XCTAssert(twoClipEDLFile.getFileRepresentation() == fileTwoClip, "EDL two clips file representation is not correct")
   }

   func testFileFromString()
   {
      let edlFile = EDLFile(edlString: edlString)

      guard let edlFileValue = edlFile
         else {
            XCTFail(" Not able to create an EDL from the given string")
            return
      }

      XCTAssert(edlFileValue.getFileRepresentation() == edlString, "EDL from string file representation is not correct")
   }

   func testRemoveLastClip()
   {
      let clip: ClipRepresentation = ClipRepresentation(mediaId: mediaId1, obfusId: mediaId1, startTime: 0, endTime: duration1)
      let clip2: ClipRepresentation = ClipRepresentation(mediaId: mediaId2, obfusId: mediaId2, startTime: 0, endTime: duration2)
      var twoClipEDLFile: EDLFile = EDLFile(format: .NTSC)
      twoClipEDLFile.appendClip(clip)
      twoClipEDLFile.appendClip(clip2)
      let removedClip: ClipRepresentation? = twoClipEDLFile.removeAtIndex(twoClipEDLFile.count-1)

      XCTAssert(twoClipEDLFile.getFileRepresentation() == fileOneClip, "EDL remove clip representation is not correct")
      XCTAssert(removedClip?.representation == pair2, "Removed clip is not a match")
   }

   func testTimecodeGeneration()
   {
      XCTAssert(milliSeconds1.EDLTimeCodeString() == convertedString1, "EDL Timecode conversion from String is not correct")
      XCTAssert(milliSeconds2.EDLTimeCodeString() == convertedString2, "EDL Timecode conversion from String is not correct")
      XCTAssert(milliSeconds3.EDLTimeCodeString() == convertedString3, "EDL Timecode conversion from String is not correct")
      XCTAssert(milliSeconds4.EDLTimeCodeString() == convertedString4, "EDL Timecode conversion from String is not correct")
   }

   func testLiveClipGeneration()
   {
      let clip: ClipRepresentation = ClipRepresentation(mediaId: mediaId1, obfusId: mediaId1, startTime: 0, endTime: duration3, liveClip: true)
      let edlFile: EDLFile = EDLFile(format: .NTSC, clips: clip)
      XCTAssert(edlFile.getFileRepresentation() == fileLiveClip, "EDL live clip representation is not correct")
   }

   func testEdlWithComment()
   {
      let clip: ClipRepresentation = ClipRepresentation(mediaId: mediaId1, obfusId: mediaId1, startTime: 0, endTime: duration1)
      var oneClipEDLFileWithComment: EDLFile = EDLFile(format: .NTSC)
      oneClipEDLFileWithComment.appendClip(clip)
      oneClipEDLFileWithComment.addOSComment("iOS")
      oneClipEDLFileWithComment.addAppVersionComment("1.0.0")

      XCTAssert(oneClipEDLFileWithComment.getFileRepresentation() == eldWithComment, "EDL with comment representation is not correct")
   }
}
