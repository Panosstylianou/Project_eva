//
//  HistoryVC.swift
//  eva
//
//  Created by Panayiotis Stylianou on 10/02/2016.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

class HistoryVC: EvaBaseVC, DataSourceProtocol, UITableViewDelegate, ServerResponseProtocol, UserHistoryInteractiveProtocol, UITextFieldDelegate, HistoryRequestsProtocol
{
   // MARK: - Outlets

   @IBOutlet weak var tableView: UITableView!
   @IBOutlet weak var activityView: UIActivityIndicatorView!
   @IBOutlet weak var blackLayer: UIView!
   @IBOutlet weak var commentTextField: UITextField!

   // MARK: - Constants

   let showProfileSegue: String = "showHistoryProfile"

   // MARK: - Properties

   lazy var dataSource: UserHistoryDataSource = UserHistoryDataSource(delegate: self, interactiveDelegate: self)
   lazy var serverResponse: ServerResponse = ServerResponse(delegate: self)
   lazy var networkDelegate: UnsafeMutablePointer<Void> = self.serverResponse.networkDelegate

   // MARK: - Private properties

   private var readTimer: NSTimer?
   private var replyAssetId: String?
   private var replyScreenName: String?

   // MARK: - Overriden properties

   override var taggingDescription: String? { return "Notifications" }

   // MARK: - UIViewController

   override func viewDidLoad()
   {
      super.viewDidLoad()
      self.tableView.dataSource = self.dataSource
      self.tableView.delegate = self.dataSource
      if let _ = SessionManager.sharedInstance.loggedInUser.userId
      {
         self.dataSource.getHistoryForUser(true)
      }
      self.dataSource.checkForRequests()

      NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
   }

   override func viewWillAppear(animated: Bool)
   {
      tableView.reloadData()
      super.viewWillAppear(animated)
      navigationController?.setNavigationBarHidden(true, animated: false)
   }

   // MARK: - Actions

   @IBAction func closeLayerAction(sender: UIButton) { hideReplyLayer() }

   // MARK: - DataSourceProtocol protocol

   func refreshData()
   {
      if NSThread.isMainThread()
      {
         self.tableView.reloadData()
         self.activityView.stopAnimating()
         UIView.animateWithDuration(0.7, animations: { self.tableView.alpha = 1.0 })
         self.startReadMarkCountdown()
      }
      else
      {
         weak var weakSelf = self
         dispatch_async(dispatch_get_main_queue())
         {
            let strongSelf = weakSelf
            if strongSelf != nil { strongSelf?.tableView.reloadData() }
         }
      }
   }

   @IBAction func swipeDownToExit(sender: AnyObject)
   {
      NSNotificationCenter.defaultCenter().postNotificationName(NotificationsConstants.LANDINGPAGE_REFRESH, object: nil)
      dismissViewControllerAnimated(true, completion: nil)
   }

   @IBAction func dismissActivity(sender: UIButton)
   {
      NSNotificationCenter.defaultCenter().postNotificationName(NotificationsConstants.LANDINGPAGE_REFRESH, object: nil)
      dismissViewControllerAnimated(true, completion: nil)
   }

   @IBAction func dismissView(sender: UIBarButtonItem)
   {
      hideReplyLayer()
      NSNotificationCenter.defaultCenter().postNotificationName(NotificationsConstants.LANDINGPAGE_REFRESH, object: nil)
      dismissViewControllerAnimated(true, completion: nil)
   }

   // MARK: - Segue

   override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
      if let selectedIndex = self.tableView.indexPathForSelectedRow?.row
      {
         let selectedUserHistory = self.dataSource.items[UserHistoryDataSource.Sections.Activity]![selectedIndex]
         if selectedUserHistory.notificationType == .FollowRequest
         {
            didChooseToViewRequests()
            return false
         }
      }
      return true
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
   {
      if segue.identifier == showProfileSegue
      {
         if let selectedIndex = self.tableView.indexPathForSelectedRow?.row
         {
            let selectedUserHistory = self.dataSource.items[UserHistoryDataSource.Sections.Activity]![selectedIndex]
            let destinationVC = segue.destinationViewController as! UserProfileVC
            let evaUser = EvaUserSearched(userHistoryItem: selectedUserHistory)
            destinationVC.evaUserSearched = evaUser
            destinationVC.parcialUser = true
         }
      }
   }

   // MARK: - Private methods

   private func startReadMarkCountdown()
   {
      self.readTimer?.invalidate()
      self.readTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("markNotificationsAsRead"), userInfo: nil, repeats: false)
   }

   private func showReplyLayer()
   {
      UIView.animateWithDuration(0.7, animations: { self.blackLayer.alpha = 1.0 }) { (finished) -> Void in if finished { self.commentTextField.becomeFirstResponder() }}
   }

   private func hideReplyLayer()
   {
      self.commentTextField.resignFirstResponder()
      self.commentTextField.text = ""
      UIView.animateWithDuration(0.7, animations: { self.blackLayer.alpha = 0.0 })
   }

   private func configureCommentTextField()
   {
      self.commentTextField.font = UIFont(name: "Ubuntu", size: 15.0)!
      self.commentTextField.textColor = UIColor.whiteColor()
      self.commentTextField.delegate = self
      if let screenName = self.replyScreenName
      {
         let attrScreenName = NSAttributedString(string: "@\(screenName)", attributes: [NSForegroundColorAttributeName: UIColor.mainColor(1.0), NSFontAttributeName: UIFont(name: "Ubuntu-bold", size: 15.0)!])
         let attrPlaceholder = NSAttributedString(string: NSLocalizedString("Say something...", comment: "Say something..."), attributes: [NSForegroundColorAttributeName: UIColor.grayColor(), NSFontAttributeName: UIFont(name: "Ubuntu", size: 15.0)!])
         let attributedText: NSMutableAttributedString = NSMutableAttributedString(attributedString: attrScreenName)
         attributedText.appendAttributedString(NSAttributedString(string: " - "))
         attributedText.appendAttributedString(attrPlaceholder)
         self.commentTextField.attributedPlaceholder = attributedText
      }
   }

   func markNotificationsAsRead()
   {
      self.readTimer?.invalidate()
      MarkHistoryNotificationsAsRead(SessionManager.sharedInstance.loggedInUser.userId!, self.networkDelegate)
   }

   // MARK: - ServerResponseProtocol

   func errorResponse(networkError: ServerErrorType?, extraData: [String:AnyObject]?) { EvaLogger.sharedInstance.logMessage("ServerResponse network error: \(networkError?.description)", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonString: String)
   {
      if responseFrom == .MarkHistoryNotificationsAsRead
      {
         EvaLogger.sharedInstance.logMessage("All notifications set as read")
      }

      if responseFrom == .CreateComment
      {
         EvaLogger.sharedInstance.logMessage("Comment posted")
      }
   }

   func serverResponse(responseFrom: ServerResponseType, jsonDictionary: JsonDictionary)
   {
      if responseFrom == .GetAsset
      {
         let asset = Asset(possibleAsset: jsonDictionary)
         dispatch_async(dispatch_get_main_queue())
         {
            ModalNotificationView.hide()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let modalFeedViewController = storyboard.instantiateViewControllerWithIdentifier("PlayUserProfile") as! ModalFeedVC
            modalFeedViewController.currentPlaybackMode = .SINGLEASSET
            modalFeedViewController.disableKeyboardNotifications()
            modalFeedViewController.currentAsset = asset
            self.presentViewController(modalFeedViewController, animated: true, completion: nil)
         }
      }
      else
      {
         EvaLogger.sharedInstance.logMessage("ServerResponse JsonDictionary not implemented for response \(responseFrom.rawValue)", .Error)
      }
   }
   func serverResponse(responseFrom: ServerResponseType, nextObject: String?, jsonDictionaryArray: [JsonDictionary]) { EvaLogger.sharedInstance.logMessage("ServerResponse jsonDictionaryArray not implemented ", .Error)  }

   // MARK: - UserHistoryInteractiveProtocol

   func didChooseToReplyTo(screenName: String, assetId: String)
   {
      self.replyScreenName = screenName
      self.replyAssetId = assetId
      configureCommentTextField()
      showReplyLayer()
      Analytics.tagEvent("Activity_PostComment")
   }

   func didChooseToView(assetId: String)
   {
      let config: ModalNotificationView.Config = ModalNotificationView.Config()
      ModalNotificationView.setConfig(config)
      ModalNotificationView.show(title: NSLocalizedString("loading video...", comment: "loading video"), image: UIImage(named: "evayellow"), animated: true)
      GetAsset(assetId, self.networkDelegate)
      Analytics.tagEvent("Activity_ViewAsset")
   }

   func didChooseToViewRequests()
   {
      let requestsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ShowRequests") as! RequestsVC
      requestsVC.historyDelegate = self
      self.navigationController?.pushViewController(requestsVC, animated: true)
   }
   func dismissView() { dismissViewControllerAnimated(true, completion: nil) }

   // MARK: - Keyboard notifications

   func keyboardDidShow(notification: NSNotification)
   {
      dispatch_async(dispatch_get_main_queue())
      {
         if let userInfo = notification.userInfo, keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue()
         {
            UIView.animateWithDuration(0.7, animations:
            {
               var newFrame = self.commentTextField.frame
               newFrame.origin.y = self.view.bounds.height - keyboardSize.height + newFrame.size.height / 2
               self.commentTextField.frame = newFrame
            })
         }
      }
   }

   // MARK: - RequestsDelegate

   func updateRequestCell(count: Int)
   {
      if count > 0
      {
         dataSource.requestsNumber = count
      }
      else
      {
         dataSource.removeRequestFromNotifications()
      }
   }

   // MARK: - UITextFieldDelegate

   func textFieldShouldBeginEditing(textField: UITextField) -> Bool
   {
      if let screenName = self.replyScreenName
      {
         let attrScreenName = NSAttributedString(string: "@\(screenName)", attributes: [NSForegroundColorAttributeName: UIColor.mainColor(1.0), NSFontAttributeName: UIFont(name: "Ubuntu-bold", size: 15.0)!])

         let attributedText: NSMutableAttributedString = NSMutableAttributedString(attributedString: attrScreenName)
         attributedText.appendAttributedString(NSAttributedString(string: " - "))
         textField.attributedText = attributedText
      }
      else
      {
         EvaLogger.sharedInstance.logMessage("No reply screen name", .Error)
      }

      return true
   }

   func textFieldShouldReturn(textField: UITextField) -> Bool
   {
      if let assetId = self.replyAssetId where textField == commentTextField && textField.text!.isEmpty == false
      {
         BridgeObjC.createCommentForAssetId(assetId, comment: textField.text, inPoint: 0, delegate: self.networkDelegate)
         hideReplyLayer()
      }
      else
      {
         EvaLogger.sharedInstance.logMessage("Not able to create the comment", .Error)
      }

      return true
   }
}
