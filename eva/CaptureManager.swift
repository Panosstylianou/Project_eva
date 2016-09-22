//
//  CaptureManager.swift
//  eva
//
//  Created by Panayiotis Stylianou on 01/12/2015.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation
import CoreData

protocol CompressionProgressProtocol
{
   func updateProgress(compressed: Int, total: Int)
   func compressionFinished()
}

final class CaptureManager: NSObject, CompressionProtocol, CaptureResponseProtocol
{
   // MARK: - Constants

   static let EDLBASENAME: String = "evaedl"
   static let MAXCLIPS: Int = 1
   static let THUMBNAIL_SIZE: CGSize = CGSize(width: 360, height: 640)
   let MINIMUM_COMPRESSION_DURATION: Double = 0.1

   // MARK: - Private properties

   private var edlFile: EDLFile?
   private var iconPaths: [String]?
   private var isSessionStarted: Bool = false
   private var edlDelegate: UnsafeMutablePointer<Void> { return BridgeObjC.giveMeCaptureDelegate(self) }
   private var clipCounter: Int = 0
   private var sessionAssetId: String?
   private var sessionObfuses: [String]?
   private var assetAlreadyHasEdl: Bool = false
   private var captureDuration: Double = 0
   private var currentSessionObfusId: String?

   // MARK: - Public properties

   var managedContext: NSManagedObjectContext!
   var compressionDelegate: UnsafeMutablePointer<Void> { return BridgeObjC.giveMeCompressionDelegate(self) }
   lazy var serverResponse: ServerResponse = ServerResponse(delegate: self)
   var networkDelegate: UnsafeMutablePointer<Void> { return self.serverResponse.networkDelegate }
   var compressionProgressDelegate: CompressionProgressProtocol?
   var isCompressionFinished: Bool = true
   var isCaptureFinished: Bool = true
   var currentSessionVideoId: String?

   /**
   Restarts the capture manager to a fresh capture state.
   Dimisses all data and states.
   */
   func startNewCaptureSession()
   {
      isSessionStarted = false
      edlFile = EDLFile(format: .NTSC)
      edlFile?.addOSComment(UIDevice.currentDevice().systemVersion)
      edlFile?.addAppVersionComment(NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as! String)
      iconPaths = [String]()
      SetCompressionCompleteDelegate(compressionDelegate)
      SetCompressionProgressDelegate(compressionDelegate)
      SetCaptureDelegate(edlDelegate)
      isSessionStarted = true
      clipCounter = 0
      sessionObfuses = [String]()
      assetAlreadyHasEdl = false
      captureDuration = 0
      isCaptureFinished = true
      currentSessionObfusId = nil
      EvaLogger.sharedInstance.logMessage("Starting a new capture session")
   }

   /**
   Removes and returns the last clip in the collection.
   Nil if the collection is empty

   - returns: Optional ClipRepresentation
   */
   func popClip() -> ClipRepresentation? { return edlFile?.removeLastClip() }

   /**
   Creates an offline EDL using the current session's data.
   */
   func createOfflineEdlFromCurrentSession()
   {
      precondition(isSessionStarted, "Capture session not started")

      if let userAccount = SessionManager.sharedInstance.loggedInUser.mediaAccount, edl = edlFile where edl.isEmpty == false
      {
         EvaLogger.sharedInstance.logMessage("Creating offline EDL \(edlFile!.getFileRepresentation())")
         assetAlreadyHasEdl = true
         CreateEdl((getEdlName() as NSString).UTF8String, (getImagePath() as NSString).UTF8String, (edlFile!.getFileRepresentation() as NSString).UTF8String, "", 0, (userAccount as NSString).UTF8String, edlDelegate)
         Analytics.tagEvent("RecordCPP_EDLCreated")
      }
      else
      {
         EvaLogger.sharedInstance.logMessage("Not able to create Offline EDL from current session's EDL", .Error)
      }
   }

   /**
   Returns if CaptureManager already has all the allowed clips for the recording session.

   - returns: Bool
   */
   func isAbleToCapture() -> Bool { return clipCounter < CaptureManager.MAXCLIPS }

   /**
   Sets the current session asset id.

   - parameter assetId: String
   */
   func setSessionAssetId(assetId: String)
   {
      sessionAssetId = assetId
      ApprovedAsset.addApprovedAsset(assetId, approved: false, ctx: managedContext)
   }

   func approveCurrentAsset()
   {
      guard let assetId = sessionAssetId else {
         fatalError("Session does not have an assetId")
      }
      approveAsset(assetId)
   }

   func approveAsset(assetId: String)
   {
      let assetRecord = ApprovedAsset.findApprovedAsset(assetId, ctx: managedContext)
      guard let asset = assetRecord else {
         EvaLogger.sharedInstance.logMessage("No ApprovedAsset entry for assetId: \(assetId)", .Error)
         return
      }
      asset.approved = true
      dispatch_async(dispatch_get_main_queue()) { [weak self, asset]() in
         guard let strongSelf = self else {
            EvaLogger.sharedInstance.logMessage("Not able to capture self", .Error)
            return
         }
         ApprovedAsset.updateApprovedAsset(asset, ctx: strongSelf.managedContext)
      }
   }

   /**
   Calls the network reconnect methods.
   */
   func reconnectNetwork()
   {
      EvaLogger.sharedInstance.logMessage("Network reconnect trying to sync.")
      NetworkReconnected()
      ProxyNetworkReconnected()
   }

   func updateAssetDescription(text: String)
   {
      precondition(sessionAssetId != nil, "Capture session without session id")

      EvaLogger.sharedInstance.logMessage("Updating description with text: \(text) for asset id: \(sessionAssetId)")
      UpdateAsset(sessionAssetId!, nil, text, self.networkDelegate)
      commitAsset(sessionAssetId!)
   }

   /**
   Sets the local asset id commit flag to true.
   */
   func commitAsset()
   {
      precondition(sessionAssetId != nil, "Capture session without session id")
      if assetAlreadyHasEdl
      {
         createOfflineEdlFromCurrentSession()
      }
      EvaLogger.sharedInstance.logMessage("Setting commit status for asset id: \(sessionAssetId)")
      commitAsset(sessionAssetId!)
   }

   func commitAsset(assetId: String)
   {
      let assetRecord = ApprovedAsset.findApprovedAsset(assetId, ctx: managedContext)
      guard let asset = assetRecord else {
         EvaLogger.sharedInstance.logMessage("No entry for assetId: \(assetId) when trying to commit", .Error)
         return
      }
      if let assetApproved = asset.approved as? Bool where assetApproved
      {
         EvaLogger.sharedInstance.logMessage("Commiting asset with ID: \(assetId)")
         CommitAsset((assetId as NSString).UTF8String)
      }
      else
      {
         EvaLogger.sharedInstance.logMessage("Stop commit, user has not yet approved the clip")
      }
   }

   /**
   Cancels the creation of the current asset.
   */
   func cancelAssetCreation()
   {
      if let assetId = sessionAssetId
      {
         UploadManager.sharedInstance.deleteEntriesForAssetId(assetId)
         deleteAssetObfuses()
         if let assetRecord = ApprovedAsset.findApprovedAsset(assetId, ctx: managedContext)
         {
            dispatch_async(dispatch_get_main_queue()) { [weak self, assetRecord]() in
               guard let strongSelf = self else {
                  EvaLogger.sharedInstance.logMessage("Not able to capture self", .Error)
                  return
               }
               ApprovedAsset.deleteApprovedAsset(assetRecord, ctx: strongSelf.managedContext)
            }
         }
         sessionAssetId = nil
      }
   }

   /**
   Checks if the system is actually compressing.

   - returns: Bool
   */
   func compressionFinished() -> Bool { return isCompressionFinished }

   /**
   Gets the EDLFile representation of the current EDLFile

   - returns: Optional String
   */
   func edlFileToString() -> String? { return edlFile!.getFileRepresentation() }

   /**
   Sets the color correction string in the current EDLFile

   - parameter colorCorrection: String
   */
   func addColorCorrection(colorCorrection: String) { edlFile?.addColourCorrection(colorCorrection) }

   /**
   Asks the proxy to create a temp index file. Only if the compression is not finished.
   */
   func createIndexFile()
   {
      if isCompressionFinished == false
      {
         EvaLogger.sharedInstance.logMessage("Starting temp index file generation")
         ExecuteIndexUpdateWithDelegate(compressionDelegate)
      }
      else
      {
         EvaLogger.sharedInstance.logMessage("Not able to create temp index file as the compression is already finished")
         notifyIndexFileCreated()
      }
      Analytics.tagEvent("RecordCPP_IndexFileUpdated")
   }

   // MARK: - Private methods

   private func notifyIndexFileCreated() { NSNotificationCenter.defaultCenter().postNotificationName(NotificationsConstants.INDEXFILE_EXISTS, object: nil) }

   /**
   Gets the name to use when creating an EDL

   - returns: String
   */
   private func getEdlName() -> String { return CaptureManager.EDLBASENAME }

   /**
   Get the icon image path. By default gets the first one.

   - returns: String
   */
   private func getImagePath() -> String { return iconPaths!.isEmpty ? "" : iconPaths!.first! }

   /**
   Deletes the media files of the current session.
   */
   private func deleteAssetObfuses()
   {
      if let obfuses = sessionObfuses
      {
         for obfusId: String in obfuses { DeleteObfus((obfusId as NSString).UTF8String) }
         sessionObfuses = [String]()
      }
   }

   /**
   Once the compression is finished, this method updates the asset
   with the generated edlId.

   - parameter assetId:     String
   - parameter edlId:       String
   - parameter mediasIds:   [String]
   */
   private func compressionDidFinish(assetId: String, edlId: String, mediasIds: [String], obfuses: [String])
   {
      EvaLogger.sharedInstance.logMessage("Compression did finish with EDL: \(edlId) for asset: \(assetId) and medias: \(mediasIds) and obfuses: \(obfuses)")
      isCompressionFinished = true
      EvaLogger.sharedInstance.logMessage("Starting cloud files upload")
      UpdateAsset(assetId, edlId, nil, self.networkDelegate)
      addMediaCollectionToUploadManager(assetId, edlId: edlId, medias: mediasIds, obfuses: obfuses)
      compressionProgressDelegate?.compressionFinished()
      Analytics.tagEvent("Camera_CompressionDone")
      Analytics.tagEvent("RecordCPP_CompressionComplete")
   }

   /**
   Adds the media - edl - asset relationship to the UploadManager

   - parameter assetId: String
   - parameter edlId:   String
   - parameter medias:  [String]
   - parameter obfuses: [String]
   */
   private func addMediaCollectionToUploadManager(assetId: String, edlId: String, medias: [String], obfuses: [String])
   {
      if obfuses.isEmpty == false
      {
         for (index, createdObfusId): (Int, String) in obfuses.enumerate()
         {
            let createdMediaId: String = medias.count > index ? medias[index] : ""
            UploadManager.sharedInstance.addUploadEntry(assetId, edlId: edlId, mediaId: createdMediaId, obfusId: createdObfusId)
         }
      }
      else
      {
         EvaLogger.sharedInstance.logMessage("No medias or obfuses to add to UploadManager", .Error)
      }
   }

   /**
   Updates the asset with the given thumbnail.

   - parameter thumbnail: UIImage
   */
   private func captureThumbnail(thumbnail: UIImage)
   {
      precondition(sessionAssetId != nil, "Capture session without session id")

      let createdCoverImage: UIImage = thumbnail.imageRotatedByDegrees(90, flip: false)
      weak var weakSelf = self
      dispatch_async(dispatch_get_main_queue())
         {
            if let strongSelf = weakSelf
            {
               SessionManager.sharedInstance.increaseVideoCount()
               let imageData = UIImageJPEGRepresentation(createdCoverImage, 0.6)
               if imageData != nil
               {
                  EvaLogger.sharedInstance.logMessage("Uploading video's thumbnail to server for asset: \(strongSelf.sessionAssetId!)")
                  AssetThumbnail(strongSelf.sessionAssetId!, imageData!.bytes, Int32(imageData!.length), self.networkDelegate)
               }
            }
      }
   }

   private func secondsToMilliseconds(seconds: Double) -> Int { return Int(floor(seconds * 1000)) }

   // MARK: - CompressionProtocol

   @objc func captureForVideoIdPrepared(videoId: String!)
   {
      currentSessionVideoId = videoId;
   }

   @objc func compressionForObfusIdStarted(obfusId: String!)
   {
      currentSessionObfusId = obfusId;
      assert(isAbleToCapture());
      precondition(isSessionStarted, "Capture session not started")
      isCompressionFinished = false
      EvaLogger.sharedInstance.logMessage("Starting compression for clip with obfusId: \(obfusId)")
      let clip: ClipRepresentation = ClipRepresentation(mediaId: "", obfusId: obfusId, startTime: 0, endTime: 10000, liveClip: true)
      edlFile?.appendClip(clip)
      sessionObfuses?.append(obfusId)
      EvaLogger.sharedInstance.logMessage("Temporal EDL file: \n \(edlFile!.getFileRepresentation())", .Custom)
      Analytics.tagEvent("RecordCPP_CaptureStarted")
   }

   @objc func compressionForVideoIdFinished(videoId: String!, withObfusId obfusId: String!, withEndTime endTimecode: String!, andIconPath iconPath: String!)
   {
      if currentSessionObfusId != obfusId { return }
      assert(isCompressionFinished == false)
      precondition(isSessionStarted, "Capture session not started")
      isCompressionFinished = true
      EvaLogger.sharedInstance.logMessage("Finished compression for clip ID: \(videoId) and endTime: \(endTimecode)")
      iconPaths?.append(iconPath)
      _ = edlFile!.removeLastClip()
      let clip: ClipRepresentation = ClipRepresentation(mediaId: videoId, obfusId: obfusId, startTime: 0, endTime: endTimecode.toEDLTimeCode(), liveClip: false)
      edlFile?.appendClip(clip)
      clipCounter++
      createOfflineEdlFromCurrentSession()
      compressionProgressDelegate?.compressionFinished()
      NSNotificationCenter.defaultCenter().postNotificationName(NotificationsConstants.COMPRESSION_SESSION_FINISHED, object: nil)
      Analytics.tagEvent("RecordCPP_CompressionComplete")
   }

   @objc func indexFileUpdated() { notifyIndexFileCreated() }

   @objc func compressionProgressForVideoId(videoId: String!, withCompressedFrames compressedFrames: UInt32, ofTotalFrames totalFrames: UInt32)
   {
      if isCaptureFinished == true
      {
         compressionProgressDelegate?.updateProgress(Int(compressedFrames), total: Int(totalFrames))
         Analytics.tagEvent("RecordCPP_CompressionProgress")
      }
   }

   // MARK: - CaptureResponseProtocol

   /**
   Gets the generated EdlID when the compression finished.

   - parameter responseString: String
   */
   @objc func processResponse(responseString: String!)
   {
      if let assetId = sessionAssetId
      {
         compressionDidFinish(assetId, edlId: responseString, mediasIds: edlFile!.getMediaIds(), obfuses: edlFile!.getObfusIds())
      }
   }

   @objc func captureFinishedWithDuration(duration: Double)
   {
      if duration < MINIMUM_COMPRESSION_DURATION
      {
         isCompressionFinished = true
         NSNotificationCenter.defaultCenter().postNotificationName(NotificationsConstants.COMPRESSION_SESSION_FINISHED, object: nil)
      }

      captureDuration = duration
      isCaptureFinished = true
      EvaLogger.sharedInstance.logMessage("Capture finished with duration: \(duration)")
      Analytics.tagEvent("RecordCPP_CaptureCompleted")
   }

   // MARK: - Shared instance

   class var sharedInstance: CaptureManager {
      struct Static {
         static var instance: CaptureManager?
         static var token: dispatch_once_t = 0
      }

      dispatch_once(&Static.token) { Static.instance = CaptureManager() }

      return Static.instance!
   }
}

// MARK: - Pixel buffer methods

extension CaptureManager
{
   /**
   Creates an UIImage from the given pixel buffer. Then notifies there is a thumbnail.

   - parameter pixelBuffer: CVPixelBufferRef
   */
   func createCaptureThumbnail(pixelBuffer: CVPixelBufferRef)
   {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
         let ciImage: CIImage = CIImage(CVPixelBuffer: pixelBuffer)
         let ciContext: CIContext = CIContext(options: nil)
         let imageRef: CGImageRef = ciContext.createCGImage(ciImage, fromRect: CGRectMake(0, 0, CGFloat(CVPixelBufferGetWidth(pixelBuffer)), CGFloat(CVPixelBufferGetHeight(pixelBuffer))))
         let imageRefScaled: CGImage? = self.resizeCGIimage(imageRef, size: CaptureManager.THUMBNAIL_SIZE)

         if let capturedCGImage = imageRefScaled
         {
            self.captureThumbnail(UIImage(CGImage: capturedCGImage))
         }
         else
         {
            EvaLogger.sharedInstance.logMessage("Not able to create a thumbnail for the video", .Error)
         }
      }
   }

   /**
   Resizes a CGImage to the given size

   - parameter cgImage: CGImage
   - parameter size:    CGSize

   - returns: Optional CGImageRef
   */
   private func resizeCGIimage(cgImage: CGImage, size: CGSize) -> CGImageRef?
   {
      let colorSpace: CGColorSpaceRef = CGImageGetColorSpace(cgImage)!
      let context: CGContextRef = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), CGImageGetBitsPerComponent(cgImage), CGImageGetBytesPerRow(cgImage), colorSpace, CGImageGetBitmapInfo(cgImage).rawValue)!

      CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), cgImage)
      let imgRef: CGImageRef = CGBitmapContextCreateImage(context)!

      return imgRef
   }
}

// MARK: - ServerResponseProtocol

extension CaptureManager: ServerResponseProtocol
{
   func errorResponse(networkError: ServerErrorType?, extraData: [String:AnyObject]?) { EvaLogger.sharedInstance.logMessage("ServerResponse error: \(networkError?.rawValue)", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonString: String)
   {
      if responseFrom == .UpdateAsset
      {
         EvaLogger.sharedInstance.logMessage("Asset updated")
      }
      else
      {
         EvaLogger.sharedInstance.logMessage("Response type: \(responseFrom.rawValue) not defined", .Error)
      }
   }

   func serverResponse(responseFrom: ServerResponseType, jsonDictionary: JsonDictionary) { EvaLogger.sharedInstance.logMessage("jsonDictionary for response type: \(responseFrom.rawValue) not implemented", .Error) }

   func serverResponse(responseFrom: ServerResponseType, nextObject: String?, jsonDictionaryArray: [JsonDictionary]) { EvaLogger.sharedInstance.logMessage("jsonDictionaryArray for response type: \(responseFrom.rawValue) not implemented", .Error) }
}
