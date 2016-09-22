//
//  TwitterTablePageViewController.swift
//  eva
//
//  Created by Panayiotis Stylianou on 03/03/2016.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

class TwitterTablePageViewController: BasePageViewController
{
   // MARK: - Outlets

   @IBOutlet weak var tableView: UITableView?
   @IBOutlet weak var activityView: UIActivityIndicatorView!
   @IBOutlet weak var sendInvitesButton: UIButton!
   @IBOutlet weak var errorLabel: UILabel!
   @IBOutlet weak var errorDescriptionLabel: UILabel!

   // MARK: - DataSources

   private lazy var _twitterFollowersDataSource: TwitterFollowersDataSource = TwitterFollowersDataSource(delegate: self)
   private var _allSelected: Bool = false

   // MARK: - UIViewController

   override func viewDidLoad()
   {
      super.viewDidLoad()

      tableView?.dataSource = _twitterFollowersDataSource
      tableView?.delegate = self
      tableView?.tableFooterView = UIView(frame: CGRectZero)

      _twitterFollowersDataSource.fetchFollowers()
   }

   // MARK: - Actions

   @IBAction func sendInvites(sender: UIButton)
   {
      Analytics.tagEvent("Invite_Twitter_InvitesSent")
      _twitterFollowersDataSource.sendInvites(false)
   }

   // MARK: - Private methods

   private func showSendInvitesButton()
   {
      dispatch_async(dispatch_get_main_queue()) { [weak self]() in
         guard let strongSelf = self else { return }
         if strongSelf.sendInvitesButton.alpha != 1.0
         {
            UIView.animateWithDuration(0.2, animations: {
               var newFrame = strongSelf.tableView!.frame
               newFrame.size.height -= strongSelf.sendInvitesButton.frame.size.height
               strongSelf.tableView?.frame = newFrame
               strongSelf.sendInvitesButton.alpha = 1.0
            })
         }
      }
   }

   private func hideSendInvitesButton()
   {
      dispatch_async(dispatch_get_main_queue()) { [weak self]() in
         guard let strongSelf = self else { return }
         if strongSelf.sendInvitesButton.alpha != 0.0
         {
            UIView.animateWithDuration(0.2, animations: {
               var newFrame = strongSelf.tableView!.frame
               newFrame.size.height += strongSelf.sendInvitesButton.frame.size.height
               strongSelf.tableView?.frame = newFrame
               strongSelf.sendInvitesButton.alpha = 0.0
            })
         }
      }
   }

   private func updateUIForError(errorText: String, _ errorDescription: String)
   {
      dispatch_async(dispatch_get_main_queue())
         { [weak self]() in
            guard let strongSelf = self else { return }
            strongSelf.errorLabel.text = errorText
            strongSelf.errorDescriptionLabel.text = errorDescription
            UIView.animateWithDuration(0.3, animations: { () -> Void in
               strongSelf.activityView.stopAnimating()
               strongSelf.errorLabel.alpha = 1.0
               strongSelf.errorDescriptionLabel.alpha = 1.0
         })
      }
   }
}

extension TwitterTablePageViewController: TwitterDataSourceProtocol
{
   func refreshData()
   {
      dispatch_async(dispatch_get_main_queue())
         { [weak self]() in
            guard let strongSelf = self else { return }
            strongSelf.tableView?.reloadData()
            UIView.animateWithDuration(0.3, animations: { () -> Void in
               strongSelf.activityView.stopAnimating()
               strongSelf.tableView?.alpha = 1.0
            })
      }
   }

   func failedWithError(error: TwitterDataSourceError)
   {
      updateUIForError(NSLocalizedString("co.eva.invite.twitter_error", comment: "Title for twitter error"), NSLocalizedString("co.eva.invite.twitter_error_description", comment: "Description for error"))
   }

   func noTwitterFollowers(message: String)
   {
      updateUIForError(NSLocalizedString("co.eva.invite.twitter_no_followers", comment: "Title for twitter no followers"), NSLocalizedString("co.eva.invite.twitter_no_followers_description", comment: "Description for no followers"))
   }

   func noTwitterAccount(message: String)
   {
      Analytics.tagEvent("Invite_Twitter_NoAccount")
      updateUIForError(NSLocalizedString("co.eva.invite.twitter_no_account", comment: "Title for twitter no account"), NSLocalizedString("co.eva.invite.twitter_no_account_description", comment: "Description for no account"))
   }

   func followersToInvite() { showSendInvitesButton() }

   func noFollowersToInvite() { hideSendInvitesButton() }

   func inviteFinished()
   {
      _twitterFollowersDataSource.clearInvites()
      _allSelected = false
      dispatch_async(dispatch_get_main_queue()) { [weak self]() in
         guard let strongSelf = self else { return }
         strongSelf.tableView?.reloadData()
      }
      hideSendInvitesButton()
      let alertController = UIAlertController(title: "eva", message: NSLocalizedString("co.eva.invite.twitter_finished", comment: "text after invites"), preferredStyle: .Alert)
      alertController.addAction(UIAlertAction(title: "ok", style: .Cancel, handler: nil))
      presentViewController(alertController, animated: true, completion: nil)
   }
}

extension TwitterTablePageViewController: UITableViewDelegate
{
   func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
   {
      let headerCell = tableView.dequeueReusableCellWithIdentifier(InviteSectionTableViewCell.CellIdentifier) as! InviteSectionTableViewCell

      switch section
      {
      case 0:
         headerCell.sectionTitle.text = NSLocalizedString("co.eva.invite.twitter_in_eva", comment: "Title for twitter followers")
         if _allSelected
         {
            headerCell.followAllButton.setTitle(NSLocalizedString("co.eva.invite.twitter_uninvite_all", comment: "Button title for twitter uninvite all"), forState: .Normal)
         }
         else
         {
            headerCell.followAllButton.setTitle(NSLocalizedString("co.eva.invite.twitter_invite_all", comment: "Button title for twitter invite all"), forState: .Normal)
         }
         headerCell.followAllButton.tag = section
         headerCell.followAllButton.addTarget(self, action: "selectAllAction:", forControlEvents: .TouchUpInside)

      default:
         EvaLogger.sharedInstance.logMessage("No custom view for header in section: \(section)")
      }

      return headerCell
   }

   func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return UIConstants.HEADER_HEIGHT }

   // MARK: - Actions

   func selectAllAction(sender: UIButton)
   {
      switch sender.tag
      {
      case 0:
         _twitterFollowersDataSource.inviteAll()
         _allSelected = !_allSelected

      default:
         EvaLogger.sharedInstance.logMessage("No SelectAll action for section: \(sender.tag)")
      }
   }
}

