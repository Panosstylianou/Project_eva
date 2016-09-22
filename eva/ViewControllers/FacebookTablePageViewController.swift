//
//  FacebookTablePageViewController.swift
//  eva
//
//  Created by Panayiotis Stylianou on 24/02/2016.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

class FacebookTablePageViewController: BasePageViewController
{
   // MARK: - Outlets

   @IBOutlet weak var tableView: UITableView?
   @IBOutlet weak var activityView: UIActivityIndicatorView!
   @IBOutlet weak var errorLabel: UILabel!
   @IBOutlet weak var errorDescriptionLabel: UILabel!
   @IBOutlet weak var inviteButton: UIButton!
   @IBOutlet weak var fbAttachButton: UIButton!

   // MARK: - DataSources

   private lazy var _facebookFriendsDataSource: FacebookFriendsDataSource = FacebookFriendsDataSource(delegate: self)

   lazy var serverResponse:ServerResponse = ServerResponse(delegate:self)
   lazy var networkDelegate: UnsafeMutablePointer<Void> = self.serverResponse.networkDelegate

   // MARK: - Private properties

   private let _accountStore = ACAccountStore()
   private let _fbPermissions = [ACFacebookAppIdKey: FBAPPID, ACFacebookPermissionsKey: ["email"], ACFacebookAudienceKey: ACFacebookAudienceOnlyMe] as [NSObject:AnyObject]
   private var _accountType: ACAccountType { return _accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook) }
   private var _fbAccount: ACAccount?

   // MARK: - UIViewController

   override func viewDidLoad()
   {
      super.viewDidLoad()

      tableView?.dataSource = _facebookFriendsDataSource
      tableView?.delegate = self
      tableView?.tableFooterView = UIView(frame: CGRectZero)

      _facebookFriendsDataSource.fetchFriends()
   }
   // MARK: - Actions

   @IBAction func attachAction(sender: UIButton)
   {
      UIView.animateWithDuration(0.3) { [weak self]() -> Void in
         guard let strongSelf = self else { return }
         strongSelf.activityView.startAnimating()
         strongSelf.errorLabel.alpha = 0.0
         strongSelf.errorDescriptionLabel.alpha = 0.0
         strongSelf.fbAttachButton.alpha = 0.0
      }
      Analytics.tagEvent("Invite_Facebook_Attach")
      attachFBAccount()
   }

   @IBAction func inviteAction(sender: UIButton)
   {
      Analytics.tagEvent("Invite_Facebook_AppInvite")
      let inviteDialog = FBSDKAppInviteDialog()
      if inviteDialog.canShow()
      {
         let inviteContent = FBSDKAppInviteContent()
         inviteContent.appLinkURL = NSURL(string: SessionManager.sharedInstance.appInviteUrl)
         inviteContent.appInvitePreviewImageURL = NSURL(string: SessionManager.sharedInstance.appInviteImage)
         inviteDialog.content = inviteContent
         inviteDialog.delegate = self
         inviteDialog.show()
      }
      else
      {
         EvaLogger.sharedInstance.logMessage("FB was not able to open AppInviteDialog", .Error)
      }
   }

   private func updateUIForAttach()
   {
      dispatch_async(dispatch_get_main_queue())
         { [weak self]() in
            guard let strongSelf = self else { return }
            strongSelf.errorLabel.text = NSLocalizedString("co.eva.invite.facebook_no_account_attached", comment: "Title for facebook no account")
            strongSelf.errorDescriptionLabel.text = NSLocalizedString("co.eva.invite.facebook_no_account_attached_description", comment: "Description for no account")
            UIView.animateWithDuration(0.3, animations: { () -> Void in
               strongSelf.activityView.stopAnimating()
               strongSelf.errorLabel.alpha = 1.0
               strongSelf.errorDescriptionLabel.alpha = 1.0
               strongSelf.fbAttachButton.alpha = 1.0
            })
      }
   }

   private func updateUIForNoPermissions()
   {
      Analytics.tagEvent("Invite_Facebook_NoPermissions")
      dispatch_async(dispatch_get_main_queue())
         { [weak self]() in
            guard let strongSelf = self else { return }
            strongSelf.errorLabel.text = NSLocalizedString("co.eva.invite.facebook_no_permissions", comment: "Title for facebook no account")
            strongSelf.errorDescriptionLabel.text = NSLocalizedString("co.eva.invite.facebook_no_permissions_description", comment: "Description for no account")
            UIView.animateWithDuration(0.3, animations: { () -> Void in
               strongSelf.activityView.stopAnimating()
               strongSelf.errorLabel.alpha = 1.0
               strongSelf.errorDescriptionLabel.alpha = 1.0
               strongSelf.fbAttachButton.alpha = 1.0
            })
      }
   }

   private func updateUIForNoAccount()
   {
      Analytics.tagEvent("Invite_Facebook_NoAccount")
      dispatch_async(dispatch_get_main_queue())
         { [weak self]() in
            guard let strongSelf = self else { return }
            strongSelf.errorLabel.text = NSLocalizedString("co.eva.invite.facebook_no_account", comment: "Title for facebook no account")
            strongSelf.errorDescriptionLabel.text = NSLocalizedString("co.eva.invite.facebook_no_account_description", comment: "Description for no account")
            UIView.animateWithDuration(0.3, animations: { () -> Void in
               strongSelf.activityView.stopAnimating()
               strongSelf.errorLabel.alpha = 1.0
               strongSelf.errorDescriptionLabel.alpha = 1.0
               strongSelf.fbAttachButton.alpha = 0.0
            })
      }
   }

   private func updateUIForSocialIdInUse()
   {
      Analytics.tagEvent("Invite_Facebook_SocialIdInUse")
      dispatch_async(dispatch_get_main_queue())
         { [weak self]() in
            guard let strongSelf = self else { return }
            strongSelf.errorLabel.text = NSLocalizedString("co.eva.invite.facebook_account_used", comment: "Title for facebook no account")
            strongSelf.errorDescriptionLabel.text = NSLocalizedString("co.eva.invite.facebook_account_used_description", comment: "Description for no account")
            UIView.animateWithDuration(0.3, animations: { () -> Void in
               strongSelf.activityView.stopAnimating()
               strongSelf.errorLabel.alpha = 1.0
               strongSelf.errorDescriptionLabel.alpha = 1.0
               strongSelf.fbAttachButton.alpha = 0.0
            })
      }
   }
}

extension FacebookTablePageViewController: FBSDKAppInviteDialogDelegate
{
   func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [NSObject : AnyObject]!)
   {
      EvaLogger.sharedInstance.logMessage("FB Invite Dialog finished with results: \(results)")
   }

   func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: NSError!)
   {
      EvaLogger.sharedInstance.logMessage("FB Invite Dialog failed with error: \(error.localizedDescription)")
   }
}

extension FacebookTablePageViewController: FacebookDataSourceProtocol
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
               strongSelf.inviteButton.alpha = 1.0
            })
      }
   }

   func didNotHaveAnyFriendsToFollow()
   {
      dispatch_async(dispatch_get_main_queue())
         { [weak self]() in
            guard let strongSelf = self else { return }
            strongSelf.errorLabel.text = NSLocalizedString("co.eva.invite.facebook_no_friends", comment: "Title for facebook no friends")
            strongSelf.errorDescriptionLabel.text = NSLocalizedString("co.eva.invite.facebook_no_friends_description", comment: "Description for no friends")
            UIView.animateWithDuration(0.3, animations: { () -> Void in
               strongSelf.activityView.stopAnimating()
               strongSelf.errorLabel.alpha = 1.0
               strongSelf.errorDescriptionLabel.alpha = 1.0
               strongSelf.inviteButton.alpha = 1.0
               strongSelf.tableView?.alpha = 0.0
            })
      }
   }

   func didNotHaveAnAccount() { hasFBAccount() }

   func alreadyInUse()
   {
      updateUIForSocialIdInUse()
   }
}

extension FacebookTablePageViewController: UITableViewDelegate
{
   func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
   {
      let headerCell = tableView.dequeueReusableCellWithIdentifier(InviteSectionTableViewCell.CellIdentifier) as! InviteSectionTableViewCell

      switch section
      {
      case 0:
         headerCell.sectionTitle.text = NSLocalizedString("co.eva.invite.facebook_in_eva", comment: "Title for facebook friend on eva")
         headerCell.followAllButton.setTitle(NSLocalizedString("co.eva.invite.facebook_follow_all", comment: "Button title for facebook follow all"), forState: .Normal)
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
         Analytics.tagEvent("Invite_Facebook_FollowAll")
         _facebookFriendsDataSource.followAll()

      default:
         EvaLogger.sharedInstance.logMessage("No SelectAll action for section: \(sender.tag)")
      }
   }
}

extension FacebookTablePageViewController
{
   private func hasFBAccount()
   {
      _accountStore.requestAccessToAccountsWithType(_accountType, options: _fbPermissions, completion: { [weak self](granted, error) -> Void in
         guard let strongSelf = self else { return }
         if granted
         {
            if strongSelf._accountStore.accountsWithAccountType(strongSelf._accountType).isEmpty == false
            {
               strongSelf._fbAccount = strongSelf._accountStore.accountsWithAccountType(strongSelf._accountType)[0] as? ACAccount
               strongSelf.updateUIForAttach()
            }
            else
            {
               strongSelf.updateUIForNoAccount()
            }
         }
         else
         {
            strongSelf.updateUIForNoPermissions()
         }
      })
   }

   private func attachFBAccount()
   {
      _accountStore.requestAccessToAccountsWithType(_accountType, options: _fbPermissions, completion: { [weak self](granted, error) -> Void in
         guard let strongSelf = self else { return }
         if granted
         {
            if let fbAccount = strongSelf._accountStore.accountsWithAccountType(strongSelf._accountType).first as? ACAccount
            {
               strongSelf._fbAccount = fbAccount
               guard let fbAccount = strongSelf._fbAccount else { return }
               SessionManager.sharedInstance.loggedInUser.facebookId = fbAccount.credential.oauthToken
               AddSocialProfile((fbAccount.credential.oauthToken as NSString).UTF8String, nil, strongSelf.networkDelegate)
            }
            else
            {
               strongSelf.updateUIForNoAccount()
            }
         }
         else
         {
            strongSelf.updateUIForNoAccount()
         }
      })
   }
}

extension FacebookTablePageViewController: ServerResponseProtocol
{
   func errorResponse(networkError: ServerErrorType?, extraData: [String:AnyObject]?)
   {
      guard let error = networkError else
      {
         EvaLogger.sharedInstance.logMessage("ServerResponse network error: \(networkError)", .Error)
         return
      }

      switch error
      {
      case .socialIdInUse, .noSocialId:
         updateUIForSocialIdInUse()

      default:
         EvaLogger.sharedInstance.logMessage("ServerResponse network error: \(networkError)", .Error)
      }
   }

   func serverResponse(responseFrom: ServerResponseType, jsonString: String)
   {
      if responseFrom == .AddSocialProfile
      {
         if jsonString == "ok"
         {
            _facebookFriendsDataSource.fetchFriends()
         }
         else
         {
            updateUIForAttach()
            EvaLogger.sharedInstance.logMessage("Error while adding social profile to user", .Error)
         }
      }
   }

   func serverResponse(responseFrom: ServerResponseType, jsonDictionary: JsonDictionary) { EvaLogger.sharedInstance.logMessage("jsonDictionary is not implemented", .Error) }

   func serverResponse(responseFrom: ServerResponseType, nextObject: String?, jsonDictionaryArray: [JsonDictionary]) { EvaLogger.sharedInstance.logMessage("jsonDictionaryArray is not implemented", .Error) }
}
