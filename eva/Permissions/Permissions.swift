//
//  PermissionsManager.swift
//  eva
//
//  Created by Panayiotis Stylianou on 11/11/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import Foundation
import AddressBook
import AVFoundation

enum PermissionType: String
{
   case Contacts = "Contacts"
   case Camera = "Camera"
   case Microphone = "Microphone"
   case Notifications = "Notifications"
   case Facebook = "Facebook"
   case Twitter = "Twitter"
}

enum PermissionStatus: String
{
   case Authorized = "Authorized"
   case Denied = "Denied"
   case Unknown = "Unknown"
   case Disabled = "Disabled"
   case NoAccount = "NoAccount"
}

protocol PermissionsProtocol
{
   func authDidChange(permissionType: PermissionType, permissionStatus: PermissionStatus)
   func authAlreadySet(permissionType: PermissionType, permissionStatus: PermissionStatus)
   func authError(permissionType: PermissionType)
}

class PermissionsManager
{
   var delegate: PermissionsProtocol?

   private lazy var _defaults:NSUserDefaults = {
      return .standardUserDefaults()
   }()

   private let _fbPermissions = [ACFacebookAppIdKey: FBAPPID, ACFacebookPermissionsKey: ["email"], ACFacebookAudienceKey: ACFacebookAudienceOnlyMe] as [NSObject:AnyObject]

   static let kRequestedNotifications = "EvaRequestedNotifications"

   init(delegate: PermissionsProtocol) { self.delegate = delegate }

   // MARK: - Contacts

   func checkContacts() -> PermissionStatus
   {
      switch ABAddressBookGetAuthorizationStatus()
      {
      case .Authorized:
         return .Authorized

      case .Restricted, .Denied:
         return .Denied

      case .NotDetermined:
         return .Unknown
      }
   }

   func requestContacts()
   {
      switch checkContacts()
      {
      case .Unknown:
         ABAddressBookRequestAccessWithCompletion(nil)
            { [weak self](granted: Bool, error: CFError!) in
               guard let strongSelf = self else { return }
               if error != nil
               {
                  strongSelf.delegate?.authDidChange(.Contacts, permissionStatus: granted ? PermissionStatus.Authorized : PermissionStatus.Denied)
               }
               else
               {
                  strongSelf.delegate?.authError(.Contacts)
               }
         }

      case .Denied:
         delegate?.authAlreadySet(.Contacts, permissionStatus: .Denied)

      case .Authorized:
         delegate?.authAlreadySet(.Contacts, permissionStatus: .Authorized)

      case .Disabled:
         delegate?.authAlreadySet(.Contacts, permissionStatus: .Disabled)

      case .NoAccount:
         fatalError()
      }
   }

   // MARK: - Camera

   func checkCamera() -> PermissionStatus
   {
      switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
      {
      case .Authorized:
         return .Authorized

      case .Restricted, .Denied:
         return .Denied

      case .NotDetermined:
         return .Unknown
      }
   }

   func requestCamera()
   {
      switch checkCamera()
      {
      case .Unknown:
         AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo)
            { [weak self] (granted) in
               guard let strongSelf = self else { return }
               strongSelf.delegate?.authDidChange(.Camera, permissionStatus: granted ? PermissionStatus.Authorized : PermissionStatus.Denied)
         }

      case .Denied:
         delegate?.authAlreadySet(.Camera, permissionStatus: .Denied)

      case .Disabled:
         delegate?.authAlreadySet(.Camera, permissionStatus: .Disabled)

      case .Authorized:
         delegate?.authAlreadySet(.Camera, permissionStatus: .Authorized)

      case .NoAccount:
         fatalError()
      }

   }

   // MARK: - Microphone

   func checkMicrophone() -> PermissionStatus
   {
      switch AVAudioSession.sharedInstance().recordPermission()
      {
      case AVAudioSessionRecordPermission.Denied:
         return .Denied

      case AVAudioSessionRecordPermission.Granted:
         return .Authorized

      default:
         return .Unknown
      }
   }

   func requestMicrophone()
   {
      switch checkMicrophone()
      {
      case .Unknown:
         AVAudioSession.sharedInstance().requestRecordPermission( { [weak self] granted in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.authDidChange(.Microphone, permissionStatus: granted ? PermissionStatus.Authorized : PermissionStatus.Denied)
         })

      case .Denied:
         delegate?.authAlreadySet(.Microphone, permissionStatus: .Denied)

      case .Disabled:
         delegate?.authAlreadySet(.Microphone, permissionStatus: .Disabled)

      case .Authorized:
         delegate?.authAlreadySet(.Microphone, permissionStatus: .Authorized)

      case .NoAccount:
         fatalError()
      }
   }

   // MARK: - Twitter

   func requestTwitter()
   {
      let accountStore = ACAccountStore()
      let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)

      accountStore.requestAccessToAccountsWithType(accountType, options: nil, completion: { [weak self](granted, error) -> Void in
         guard let strongSelf = self else { return }
         if granted
         {
            if accountStore.accountsWithAccountType(accountType).isEmpty == false
            {
               strongSelf.delegate?.authDidChange(.Twitter, permissionStatus: .Authorized)
            }
            else
            {
               strongSelf.delegate?.authDidChange(.Twitter, permissionStatus: .NoAccount)
            }
         }
         else
         {
            strongSelf.delegate?.authDidChange(.Twitter, permissionStatus: .Denied)
         }
      })
   }

   // MARK: - Facebook

   func requestFacebook()
   {
      let accountStore = ACAccountStore()
      let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)

      accountStore.requestAccessToAccountsWithType(accountType, options: _fbPermissions, completion: { [weak self](granted, error) -> Void in
         guard let strongSelf = self else { return }
         if granted
         {
            if accountStore.accountsWithAccountType(accountType).isEmpty == false
            {
               strongSelf.delegate?.authDidChange(.Facebook, permissionStatus: .Authorized)
            }
            else
            {
               strongSelf.delegate?.authDidChange(.Facebook, permissionStatus: .NoAccount)
            }
         }
         else
         {
            strongSelf.delegate?.authDidChange(.Facebook, permissionStatus: .Denied)
         }
      })
   }
}
