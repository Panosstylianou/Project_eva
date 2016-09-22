//
//  ContactsTablePageViewController.swift
//  eva
//
//  Created by Panayiotis Stylianou on 15/11/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit
import AddressBook

protocol FindFriendsViewProtocol
{
   func dismissView()
}

class ContactsTablePageViewController: BasePageViewController
{
   // MARK: - Constants

   private let kContactsShown = "contacts_authorized"

   // MARK: - Outlets

   @IBOutlet weak var tableView: UITableView?
   @IBOutlet weak var activityView: UIActivityIndicatorView!
   @IBOutlet weak var errorLabel: UILabel!
   @IBOutlet weak var errorDescriptionLabel: UILabel!
   @IBOutlet weak var noContactsLabel: UILabel!

   // MARK: - DataSources

   private lazy var _contactsDataSource: ContactsDataSource = ContactsDataSource(delegate: self)
   private var _allSelected: Bool = false
   var delegate: FindFriendsViewProtocol?

   // MARK: - UIViewController

   override func viewDidLoad()
   {
      super.viewDidLoad()

      tableView?.dataSource = _contactsDataSource
      tableView?.delegate = self
      tableView?.tableFooterView = UIView(frame: CGRectZero)
   }

   override func viewDidAppear(animated: Bool)
   {
      super.viewDidAppear(animated)
   }

   // MARK: - Actions

   func fetchContacts()
   {
      do {
         try _contactsDataSource.fetchContacts()

      } catch ContactsDataSourceErrorType.NotDetermined {
         askPermissions()
      } catch {
         updateUIForUnauthorized()
         EvaLogger.sharedInstance.logMessage("Access to AddressBook not authorized")
      }
   }

   private func askPermissions()
   {
      ABAddressBookRequestAccessWithCompletion(_contactsDataSource.addressBookRef) {
         [weak self](granted: Bool, error: CFError!) in
         dispatch_async(dispatch_get_main_queue()) {
            guard let strongSelf = self else { return }
            !granted ? strongSelf.updateUIForUnauthorized() : strongSelf.fetchContacts()
         }
      }
   }

   func updateUIForUnauthorized()
   {
      Analytics.tagEvent("Invite_Contacts_NoPermissions")
      dispatch_async(dispatch_get_main_queue())
         { [weak self]() in
            guard let strongSelf = self else { return }
            strongSelf.errorLabel.text = NSLocalizedString("co.eva.invite.contacts_no_permissions", comment: "title for no permissions")
            strongSelf.errorDescriptionLabel.text = NSLocalizedString("co.eva.invite.contacts_no_permissions_description", comment: "description for no permissions")
            UIView.animateWithDuration(0.3, animations: { () -> Void in
               strongSelf.activityView.stopAnimating()
               strongSelf.errorLabel.alpha = 1.0
               strongSelf.errorDescriptionLabel.alpha = 1.0
            })
      }
   }

   func updateUIForFetchingContacts()
   {
      dispatch_async(dispatch_get_main_queue())
         { [weak self]() in
            guard let strongSelf = self else { return }
            UIView.animateWithDuration(0.3, animations: { () -> Void in
               strongSelf.errorLabel.alpha = 0.0
               strongSelf.errorDescriptionLabel.alpha = 0.0
               strongSelf.activityView.startAnimating()
         })
      }
   }

   func hasContacts() -> Bool
   {
      return _contactsDataSource.hasUsers || _contactsDataSource.hasInvites
   }
}

extension ContactsTablePageViewController: ContactsDataSourceProtocol
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
               if !strongSelf.hasContacts()
               {
                  strongSelf.noContactsLabel.alpha = 1.0
               }
            })
      }
   }

   func inviteFinished()
   {
      Analytics.tagEvent("Invite_Contacts_InvitesSent")
      _contactsDataSource.clearInvites()
      _allSelected = false
      dispatch_async(dispatch_get_main_queue()) { [weak self]() in
         guard let strongSelf = self else { return }
         strongSelf.tableView?.reloadData()
      }
      let alertController = UIAlertController(title: "eva", message: NSLocalizedString("co.eva.invite.contacts_finished", comment: "text after invites"), preferredStyle: .Alert)
      alertController.addAction(UIAlertAction(title: "ok", style: .Cancel, handler: nil))
      presentViewController(alertController, animated: true, completion: nil)
   }

   func dismissView() { delegate?.dismissView() }
}

extension ContactsTablePageViewController: UITableViewDelegate
{
   func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
   {
      let headerCell = tableView.dequeueReusableCellWithIdentifier(InviteSectionTableViewCell.CellIdentifier) as! InviteSectionTableViewCell

      headerCell.followAllButton.addTarget(self, action: "followAll:", forControlEvents: .TouchUpInside)
      headerCell.inviteAllButton.addTarget(self, action: "inviteAll:", forControlEvents: .TouchUpInside)
      headerCell.followAllButton.setTitle(NSLocalizedString("co.eva.invite.contacts_follow_all", comment: "Button title for contact follow all"), forState: .Normal)
      headerCell.inviteAllButton.setTitle(NSLocalizedString("co.eva.invite.contacts_invite_all", comment: "Button title for twitter invite all"), forState: .Normal)

      switch section
      {
      case 0:
         headerCell.sectionTitle.text = NSLocalizedString("co.eva.invite.contacts_in_eva", comment: "Title for contact friend on eva")
         headerCell.inviteAllButton.alpha = (_contactsDataSource.hasInvites ? 1 : 0 )

      case 1:
         if _contactsDataSource.hasUsers == false
         {
            headerCell.followAllButton.alpha = 0
            headerCell.inviteAllButton.alpha = (_contactsDataSource.hasInvites ? 1 : 0 )
            if _contactsDataSource.hasInvites == true { headerCell.inviteAllButton.frame = headerCell.followAllButton.frame }
         }
         else{
            headerCell.inviteAllButton.alpha = 0
            headerCell.followAllButton.alpha = 0
         }

         headerCell.sectionTitle.text = NSLocalizedString("co.eva.invite.contacts_not_in_eva", comment: "Title for contact friend not on eva")

      default:
         fatalError("No custom view for header in section: \(section)")
      }

      return headerCell
   }

   func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
   {
      if section == 0 && _contactsDataSource.hasUsers == false  { return 0.0 }

      if section == 1 && _contactsDataSource.hasInvites == false {return 0.0 }

      return UIConstants.HEADER_HEIGHT
   }

   // MARK: - Actions

   func inviteAll(sender: UIButton)
   {
      Analytics.tagEvent("Invite_Contacts_InviteAll")
      _contactsDataSource.inviteAll()
   }

   func followAll(sender: UIButton)
   {
      Analytics.tagEvent("Invite_Contacts_FollowAll")
      _contactsDataSource.followAll()
   }
}
