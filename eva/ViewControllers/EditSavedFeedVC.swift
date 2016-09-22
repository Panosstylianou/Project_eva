//
//  EditSavedFeedVC.swift
//  eva
//
//  Created by Panayiotis Stylianou on 19/11/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

class EditSavedFeedVC: EvaBaseVC
{
   // MARK: - Constants

   static let STORYBOARD_ID = "EditSavedFeedVC"
   static let kEditFeedSegue = "EditFeedSegue"

   // MARK: - Overriden properties

   override var taggingDescription: String? { return "EditSavedFeedVC" }

   // MARK: - Outlets

   @IBOutlet var tableView: UITableView!

   // MARK: - Properties

   var feedId: String?

   // MARK: - Private properties

   private var _feed: SavedFeed?

   // MARK: - UIViewController

   override func viewDidLoad()
   {
      super.viewDidLoad()

      guard let selectedId = feedId else { fatalError("FeedID not set")}
      tableView.dataSource = self
      SavedFeedsManager.sharedInstance.delegate = self
      fetchData(selectedId)
   }

   // MARK: - Actions

   @IBAction func dismissViewController(sender: UIButton)
   {
      dismissViewControllerAnimated(true, completion: nil)
   }

   @IBAction func editAction(sender: UIButton)
   {
      if tableView.editing == false
      {
         tableView.editing = true
         sender.setTitle("finish", forState: .Normal)
      }
      else
      {
         tableView.editing = false
         sender.setTitle("edit", forState: .Normal)
      }
   }

   // MARK: - Private methods

   private func fetchData(feedId: String)
   {
      SavedFeedsManager.sharedInstance.fetchFeed(feedId)
   }
}

extension EditSavedFeedVC: SavedFeedsManagerProtocol
{
   func didFetchFeedsList(feeds: [SavedFeedSimple]) { assertionFailure("didFetchFeedsList not implemented") }

   func didFetchFeed(feed: SavedFeed)
   {
      dispatch_async(dispatch_get_main_queue())
         {[weak self, feed]() in
            guard let strongSelf = self else { return }
            strongSelf._feed = feed
            strongSelf.tableView.reloadData()
      }
   }

   func errorFetchingFeed() { assertionFailure("error fetching the feed") }
}

extension EditSavedFeedVC: UITableViewDataSource
{
   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
   {
      guard let currentFeed = _feed else { return 0 }
      return currentFeed.count
   }

   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
   {
      let asset = _feed!.feedItems[indexPath.row]
      let cell = tableView.dequeueReusableCellWithIdentifier(SavedFeedAssetTableViewCell.kCellIdentifier) as! SavedFeedAssetTableViewCell

      cell.descriptionLabel.text = asset.assetDescription
      cell.screenNameLabel.text = asset.userScreenName
      asset.setThumbnailImageForImageView(&cell.thumbnail!)
      cell.dateLabel.text = asset.createdTime?.elapsedTime

      return cell
   }

   func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool { return true }

   func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
   {
      if editingStyle == .Delete
      {
         let asset = _feed!.feedItems[indexPath.row]
         _feed!.removeAsset(asset)
         SavedFeedsManager.sharedInstance.updateFeed(_feed!)
         dispatch_async(dispatch_get_main_queue())
            {[weak self]() in
               guard let strongSelf = self else { return }
               strongSelf.tableView.reloadData()
         }
      }
   }

   func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool { return true }

   func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)
   {
      let assetToMove = _feed!.feedItems[sourceIndexPath.row]
      _feed!.removeAsset(assetToMove)
      _feed?.feedItems.insert(assetToMove, atIndex: destinationIndexPath.row)
      SavedFeedsManager.sharedInstance.updateFeed(_feed!)

   }
}
