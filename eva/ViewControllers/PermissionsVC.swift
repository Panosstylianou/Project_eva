//
//  PermissionsVC.swift
//  eva
//
//  Created by Panayiotis Stylianou on 12/11/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

protocol PermissionsViewDelegate
{
   func setupFinished()
   func setupAborted()
}

class PermissionsVC: EvaBaseVC
{
   // MARK: - Constants

   static let STORYBOARD_ID = "PermissionsVCID"

   // MARK: - Overriden properties

   override var taggingDescription: String? { return "PermissionsVC" }

   // MARK: - Public properties

   var delegate: PermissionsViewDelegate?

   // MARK: - Outlets

   @IBOutlet weak var viewHolder: UIView!
   @IBOutlet weak var actionTitleLabel: UILabel!
   @IBOutlet weak var permission1Label: UILabel!
   @IBOutlet weak var permission2Label: UILabel!
   @IBOutlet weak var permission3Label: UILabel!
   @IBOutlet weak var startButton: UIButton!

   // MARK: - Private Properties

   private enum FlowStates { case Basic, Social }
   private var _flowState = FlowStates.Basic
   private lazy var _permissionsManager: PermissionsManager = PermissionsManager(delegate: self)
   private var _basicPermissions: Set<PermissionType> = [.Camera, .Microphone]
   private var _contactsPermissions: Set<PermissionType> = [.Contacts, .Facebook, .Twitter]


   // MARK: - UIViewController

   override func viewDidLoad()
   {
      super.viewDidLoad()

      setupForBasicPermissions()
   }

   // MARK: - Action

   @IBAction func skipAction(sender: UIButton)
   {
      dismissViewControllerAnimated(true, completion: nil)
      delegate?.setupAborted()
   }

   @IBAction func startAction(sender: UIButton)
   {
      switch _flowState
      {
      case .Basic:
         _permissionsManager.requestCamera()
         _permissionsManager.requestMicrophone()

      case .Social:
         _permissionsManager.requestContacts()
         _permissionsManager.requestFacebook()
         _permissionsManager.requestTwitter()
      }
   }

   // MARK: - Private methods

   private func setupForBasicPermissions()
   {
      actionTitleLabel.text = NSLocalizedString("co.eva.permission.basic.title", comment: "basic permissions title")
      permission1Label.text = NSLocalizedString("co.eva.permission.basic.permission1", comment: "basic permission 1")
      permission2Label.text = NSLocalizedString("co.eva.permission.basic.permission2", comment: "basic permission 2")
      permission3Label.text = NSLocalizedString("co.eva.permission.basic.permission3", comment: "basic permission 3")
      startButton.setTitle(NSLocalizedString("co.eva.permission.basic.action", comment: "basic permissions action"), forState: .Normal)
      _flowState = .Basic
   }

   private func setupForSocialPermissions()
   {
      actionTitleLabel.text = NSLocalizedString("co.eva.permission.contacts.title", comment: "contacts permissions title")
      permission1Label.text = NSLocalizedString("co.eva.permission.contacts.permission1", comment: "contacts permission 1")
      permission2Label.text = NSLocalizedString("co.eva.permission.contacts.permission2", comment: "contacts permission 2")
      permission3Label.text = NSLocalizedString("co.eva.permission.contacts.permission3", comment: "contacts permission 3")
      startButton.setTitle(NSLocalizedString("co.eva.permission.contacts.action", comment: "contacts permissions action"), forState: .Normal)
      _flowState = .Social
   }
}

extension PermissionsVC: PermissionsProtocol
{
   func authDidChange(permissionType: PermissionType, permissionStatus: PermissionStatus) { evaluateState(permissionType) }

   func authAlreadySet(permissionType: PermissionType, permissionStatus: PermissionStatus) { evaluateState(permissionType) }

   func authError(permissionType: PermissionType)
   {
      EvaLogger.sharedInstance.logMessage("Error while fetching permissions for \(permissionType.rawValue)")
      if _flowState == .Basic
      {
         setupForSocialPermissions()
      }
      else
      {
         dismissViewControllerAnimated(true, completion: nil)
         delegate?.setupAborted()
      }
   }

   private func evaluateState(permissionType: PermissionType)
   {
      if _basicPermissions.contains(permissionType)
      {
         _basicPermissions.removeAtIndex(_basicPermissions.indexOf(permissionType)!)
      }
      else if _contactsPermissions.contains(permissionType)
      {
         _contactsPermissions.removeAtIndex(_contactsPermissions.indexOf(permissionType)!)
      }

      if _flowState == .Basic && _basicPermissions.isEmpty
      {
         setupForSocialPermissions()
      }
      else if _flowState == .Social && _contactsPermissions.isEmpty
      {
         dismissViewControllerAnimated(true, completion: nil)
         delegate?.setupFinished()
      }
   }
}
