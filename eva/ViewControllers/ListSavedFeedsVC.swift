//
//  ListSavedFeedsVC.swift
//  eva
//
//  Created by Panayiotis Stylianou on 17/11/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

protocol ListSavedFeedsProtocol
{
   func didSelectedFeed(feedId: String, _ feedName: String)
   func didNotSelectFeed()
}

class ListSavedFeedsVC: EvaBaseVC
{
   // MARK: - Constants

   static let STORYBOARD_ID = "ListSavedFeedsVC"
   static let kSelectFeedSegue = "SelectFeedSegue"

   // MARK: - Overriden properties

   override var taggingDescription: String? { return "ListSavedFeedsVC" }

   // MARK: - Outlets
   @IBOutlet weak var tableView: UITableView!

   // MARK: - Properties

   var delegate: ListSavedFeedsProtocol?
   private var _feeds: [SavedFeedSimple] = []

   // MARK: - UIViewController

   override func viewDidLoad()
   {
      super.viewDidLoad()

      SavedFeedsManager.sharedInstance.delegate = self
      tableView.dataSource = self
      tableView.delegate = self

      fetchFeeds()
   }

   // MARK: - Actions

   @IBAction func dimissViewController(sender: UIButton)
   {
      dismissViewControllerAnimated(true) { [weak self]() -> Void in
         guard let strongSelf = self else { return }
         strongSelf.delegate?.didNotSelectFeed()
      }
   }

   // MARK: - Private methods

   private func fetchFeeds()
   {
      SavedFeedsManager.sharedInstance.fetchFeedList(SessionManager.sharedInstance.loggedInUser.userId!, limit: 200)
   }
}

extension ListSavedFeedsVC: UITableViewDataSource
{
   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return _feeds.count }

   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
   {
      let feed = _feeds[indexPath.row]
      let cell = tableView.dequeueReusableCellWithIdentifier(SavedFeedsTableViewCell.CellIdentifier)! as! SavedFeedsTableViewCell

      cell.feedNameLabel.text = feed.feedName
      cell.feedIdLabel.text = "(\(feed.feedId)"

      return cell
   }
}

extension ListSavedFeedsVC: UITableViewDelegate
{
   func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
   {
      let selectedFeed = _feeds[indexPath.row]
      dismissViewControllerAnimated(true) { [weak self, selectedFeed]() -> Void in
         guard let strongSelf = self else { return }
         strongSelf.delegate?.didSelectedFeed(selectedFeed.feedId, selectedFeed.feedName)
      }
   }
}

extension ListSavedFeedsVC: SavedFeedsManagerProtocol
{
   func didFetchFeedsList(feeds: [SavedFeedSimple])
   {
      dispatch_async(dispatch_get_main_queue())
         {[weak self, feeds]() in
            guard let strongSelf = self else { return }
            strongSelf._feeds = feeds
            strongSelf.tableView.reloadData()
      }
   }

   func didFetchFeed(feed: SavedFeed)
   {
      EvaLogger.sharedInstance.logMessage("didFetchFeed not implemented")
   }

   func errorFetchingFeed()
   {
      EvaLogger.sharedInstance.logMessage("Error fetching feed", .Error)
   }
}
