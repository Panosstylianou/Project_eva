//
//  SavedFeedsVC.swift
//  eva
//
//  Created by Panayiotis Stylianou on 17/11/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

class SavedFeedsVC: EvaBaseVC
{
   // MARK: - Constants

   static let STORYBOARD_ID = "SavedFeedsVC"

   enum CRUDState { case AddItem, DeleteFeed, EditFeed }

   // MARK: - Overriden properties

   override var taggingDescription: String? { return "SavedFeedsVC" }

   // MARK: - Properties

   var asset: Asset?

   // MARK: - Private properties

   private var _CrudState: CRUDState?
   private var _selectedFeedId: String?

   // MARK: - UIViewController

   override func viewDidLoad()
   {
      super.viewDidLoad()
   }

   // MARK: - Actions

   @IBAction func dismissViewController(sender: UIButton)
   {
      dismissViewControllerAnimated(true, completion: nil)
   }

   @IBAction func addAssetToFeed(sender: UIButton)
   {
      _CrudState = .AddItem
      performSegueWithIdentifier(ListSavedFeedsVC.kSelectFeedSegue, sender: nil)
   }

   @IBAction func deleteFeed(sender: UIButton)
   {
      _CrudState = .DeleteFeed
      performSegueWithIdentifier(ListSavedFeedsVC.kSelectFeedSegue, sender: nil)
   }

   @IBAction func editFeed(sender: UIButton)
   {
      _CrudState = .EditFeed
      performSegueWithIdentifier(ListSavedFeedsVC.kSelectFeedSegue, sender: nil)
   }

   @IBAction func createFeed(sender: UIButton)
   {
      let alertController = UIAlertController(title: "Create Feed", message: "enter the name of the feed", preferredStyle: .Alert)
      let createAction = UIAlertAction(title: "Create", style: .Default) { (_) in
         let feedName = (alertController.textFields!.first! as UITextField).text!
         SavedFeedsManager.sharedInstance.createFeed(feedName)
      }
      createAction.enabled = false
      let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
      alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
         textField.placeholder = "Feed Name"
         NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
            createAction.enabled = textField.text != ""
         }
      }

      alertController.addAction(createAction)
      alertController.addAction(cancelAction)

      presentViewController(alertController, animated: true, completion: nil)
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
   {
      switch segue.identifier!
      {
      case ListSavedFeedsVC.kSelectFeedSegue:
         let destVC = segue.destinationViewController as! ListSavedFeedsVC
         destVC.delegate = self

      case EditSavedFeedVC.kEditFeedSegue:
         let destVC = segue.destinationViewController as! EditSavedFeedVC
         destVC.feedId = _selectedFeedId

      default:
         assertionFailure("Not valid segue identifier: \(segue.identifier)")
      }
   }
}

extension SavedFeedsVC: ListSavedFeedsProtocol
{
   func didSelectedFeed(feedId: String, _ feedName: String)
   {
      guard let crudState = _CrudState else { return }
      switch crudState
      {
      case .AddItem:
         SavedFeedsManager.sharedInstance.delegate = self
         SavedFeedsManager.sharedInstance.fetchFeed(feedId)

      case .DeleteFeed:
         let deleteConfirmation = UIAlertController(title: "WARNING", message: " Are you sure you want to delete the feed with name: \(feedName)", preferredStyle: .Alert)
         let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
         let okAction = UIAlertAction(title: "Sure", style: .Default)
            { [feedId](_) in SavedFeedsManager.sharedInstance.deleteFeed(feedId) }
         deleteConfirmation.addAction(cancelAction)
         deleteConfirmation.addAction(okAction)

         presentViewController(deleteConfirmation, animated: true, completion: nil)

      case .EditFeed:
         _selectedFeedId = feedId
         performSegueWithIdentifier(EditSavedFeedVC.kEditFeedSegue, sender: nil)
      }
   }

   func didNotSelectFeed() {}
}

extension SavedFeedsVC: SavedFeedsManagerProtocol
{
   func didFetchFeedsList(feeds: [SavedFeedSimple])
   {
      EvaLogger.sharedInstance.logMessage("didFetchFeedsList not implemented", .Error)
   }

   func didFetchFeed(var feed: SavedFeed)
   {
      guard let currentAsset = asset else { fatalError("Adding a not existing asset") }
      do {
         try feed.addAsset(currentAsset)
      } catch SavedFeedsError.AssetAlreadyInFeed(let asset) {
         EvaLogger.sharedInstance.logMessage("The asset \(asset.id) is already in the feed")
      } catch { assertionFailure("Error not catched") }
      SavedFeedsManager.sharedInstance.updateFeed(feed)
   }

   func errorFetchingFeed()
   {
      EvaLogger.sharedInstance.logMessage("didFetchFeedsList not implemented", .Error)
   }
}
