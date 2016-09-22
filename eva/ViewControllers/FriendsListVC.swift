//
//  FriendsListVC.swift
//  eva
//
//  Created by Panayiotis Stylianou on 24/11/2015.
//  Copyright © 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

class FriendsListVC: EvaBaseVC, CAPSPageMenuDelegate
{
   let STORYBOARD_ID = "FriendsListVC"
   let kShowUserProfile = "ShowUserProfileSegue"

   enum FriendsType: Int { case Following = 0, Followers = 1 }

   // MARK: - Outlets

   @IBOutlet weak var pageMenuHolder: UIView!

   // MARK: - Overriden properties

   override var taggingDescription: String? { return "FriendsListVC" }

   // MARK: - Properties

   var friendsType: FriendsType = .Following

   // MARK: - Private properties

   private var _pageMenu : CAPSPageMenu?
   private var _controllers: [String:UsersTablePageViewController] = [:]
   private let _followingVC : UsersTablePageViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(FriendsVC.USERS_TABLEPAGE_ID) as! UsersTablePageViewController
   private let _followersVC : UsersTablePageViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(FriendsVC.USERS_TABLEPAGE_ID) as! UsersTablePageViewController

   // MARK: - UIViewController

   override func viewDidLoad()
   {
      super.viewDidLoad()

      _controllers = createControllersForMenu()

      let menuOptions: [CAPSPageMenuOption] = [
         .MenuItemSeparatorWidth(0),
         .ScrollMenuBackgroundColor(UIColor.clearColor()),
         .ViewBackgroundColor(UIColor.clearColor()),
         .BottomMenuHairlineColor(UIColor.whiteColor(0.3)),
         .SelectionIndicatorColor(UIColor.mainColor(1.0)),
         .MenuMargin(20.0),
         .MenuHeight(25.0),
         .MenuContainerMargin(0.0),
         .SelectedMenuItemLabelColor(UIColor.mainColor(1.0)),
         .UnselectedMenuItemLabelColor(UIColor.whiteColor(0.8)),
         .MenuItemFont(UIFont(name: "Ubuntu-Bold", size: 15.0)!),
         .UseMenuLikeSegmentedControl(true),
         .MenuItemSeparatorRoundEdges(true),
         .SelectionIndicatorHeight(2.0),
         .MenuItemSeparatorPercentageHeight(0.1),
         .IntegratedMenu(false),
         .MenuMarginTop(40.0)
      ]

      _pageMenu = CAPSPageMenu(viewControllers: getOrderedMenuItems(), frame: CGRectMake(0.0, 0.0, pageMenuHolder.frame.width, pageMenuHolder.frame.height), pageMenuOptions: menuOptions)
      _pageMenu?.delegate = self

      pageMenuHolder.addSubview(_pageMenu!.view)
   }

   override func viewDidAppear(animated: Bool)
   {
      super.viewDidAppear(animated)

      _pageMenu?.moveToPage(friendsType.rawValue)
   }

   // MARK: - Private methods

   func getOrderedMenuItems() -> [UsersTablePageViewController] { return [_followingVC, _followersVC] }

   /**
    Creates the TablePageViewController that will appear in the menu

    - returns: [TablePageViewController]
    */
   private func createControllersForMenu() -> [String:UsersTablePageViewController]
   {
      var pageControllers: [String:UsersTablePageViewController] = [:]

      _followingVC.parentNavigationController = self.navigationController
      _followingVC.title = NSLocalizedString("following", comment: "Following users menu page title")
      _followingVC.userListType = .Following
      _followingVC.delegate = self
      pageControllers["following"] = _followingVC

      _followersVC.parentNavigationController = self.navigationController
      _followersVC.title = NSLocalizedString("followers", comment: "Followers users menu page title")
      _followersVC.userListType = .Follower
      _followersVC.delegate = self
      pageControllers["followers"] = _followersVC


      return pageControllers
   }

   // MARK: - Actions

   @IBAction func dismissVC(sender: UIBarButtonItem)
   {
      self.dismissViewControllerAnimated(true, completion: nil)
   }

   // MARK: - Navigation

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
   {
      guard let segueIdentifier = segue.identifier else {
         assertionFailure("No segue identifier")
         return
      }

      switch segueIdentifier
      {
      case kShowUserProfile:
         let userProfileVC = segue.destinationViewController as! UserProfileVC
         userProfileVC.parcialUser = true
         let evaUser = sender as! EvaUser
         let avatarId = evaUser.avatarId ?? nil
         let evaUserSearched = EvaUserSearched(evaUser: evaUser)
         userProfileVC.evaUserSearched = evaUserSearched

      default:
         EvaLogger.sharedInstance.logMessage("No specific actions for segue identifier: \(segueIdentifier)")
      }
   }
}

// MARK: - UsersTablePageViewControllerProtocol

extension FriendsListVC: UsersTablePageViewControllerProtocol
{
   func didSelectEvaUser(evaUser: EvaUser)
   {
      performSegueWithIdentifier(kShowUserProfile, sender: evaUser)
   }

   func dismissView()
   {
      self.dismissViewControllerAnimated(true, completion: nil)
   }
}

