//
//  TrendsVC.swift
//  eva
//
//  Created by Panayiotis Stylianou on 21/02/2016.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

class TrendsVC: EvaBaseVC, DataSourceProtocol, CAPSPageMenuDelegate, TablePageViewControllerProtocol
{
   // MARK: - Outlets

   @IBOutlet weak var pageMenuHolder: UIView!
   @IBOutlet weak var activityView: UIActivityIndicatorView!

   // MARK: - Constants

   let STORYBOARD_ID: String = "TrendsVCID"
   static let TABLEPAGE_ID: String = "TablePageViewController"
   let numberOfItemsToFetch: Int = 20

   // MARK: - Private properties

   private lazy var dataSource: TrendsDataSource = TrendsDataSource(delegate: self)
   private var pageMenu : CAPSPageMenu?
   private var controllers: [String:TablePageViewController] = [:]
   private let nowTrendsVC : TablePageViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(TrendsVC.TABLEPAGE_ID) as! TablePageViewController
   private let weekTrendsVC : TablePageViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(TrendsVC.TABLEPAGE_ID) as! TablePageViewController
   private let monthTrendsVC : TablePageViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(TrendsVC.TABLEPAGE_ID) as! TablePageViewController

   // MARK: - Overriden properties

   override var taggingDescription: String? { return "TrendsVC" }

   // MARK: - UIViewController

   override func viewDidLoad()
   {
      super.viewDidLoad()

      controllers = createControllersForMenu()
      dataSource.fetchTrends(numberOfItemsToFetch)

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
         .MenuItemFont(UIFont(name: "Ubuntu-Bold", size: 15)!),
         .UseMenuLikeSegmentedControl(true),
         .MenuItemSeparatorRoundEdges(true),
         .SelectionIndicatorHeight(2.0),
         .MenuItemSeparatorPercentageHeight(0.1),
         .IntegratedMenu(false),
         .MenuMarginTop(40.0)
      ]

      pageMenu = CAPSPageMenu(viewControllers: getOrderedMenuItems(), frame: CGRectMake(0.0, 0.0, pageMenuHolder.frame.width, pageMenuHolder.frame.height), pageMenuOptions: menuOptions)
      pageMenu?.delegate = self

      pageMenuHolder.addSubview(pageMenu!.view)
   }

   // MARK: - Actions

   @IBAction func swipeDownToExit(sender: AnyObject)
   {
      NSNotificationCenter.defaultCenter().postNotificationName(NotificationsConstants.LANDINGPAGE_REFRESH, object: nil)
      dismissViewControllerAnimated(true, completion: nil)
   }

   @IBAction func dismissVC(sender: UIButton)
   {
      NSNotificationCenter.defaultCenter().postNotificationName(NotificationsConstants.LANDINGPAGE_REFRESH, object: nil)
      self.dismissViewControllerAnimated(true, completion: nil)
   }

   func getOrderedMenuItems() -> [TablePageViewController] { return [nowTrendsVC, weekTrendsVC, monthTrendsVC] }

   // MARK: - Private methods

   /**
   Creates the TablePageViewController that will appear in the menu

   - returns: [TablePageViewController]
   */
   private func createControllersForMenu() -> [String:TablePageViewController]
   {
      var pageControllers: [String:TablePageViewController] = [:]

      nowTrendsVC.parentNavigationController = self.navigationController
      nowTrendsVC.title = NSLocalizedString("now", comment: "Now trends menu page title")
      nowTrendsVC.delegate = self
      pageControllers[TrendsDataSource.TrendsTimePeriod.Day.rawValue] = nowTrendsVC

      weekTrendsVC.parentNavigationController = self.navigationController
      weekTrendsVC.title = NSLocalizedString("this week", comment: "Week trends menu page title")
      weekTrendsVC.delegate = self
      pageControllers[TrendsDataSource.TrendsTimePeriod.Day.rawValue] = weekTrendsVC

      monthTrendsVC.parentNavigationController = self.navigationController
      monthTrendsVC.title = NSLocalizedString("last month", comment: "Month trends menu page title")
      monthTrendsVC.delegate = self
      pageControllers[TrendsDataSource.TrendsTimePeriod.Day.rawValue] = monthTrendsVC

      return pageControllers
   }


   // MARK: - DataSourceProtocol

   func refreshData()
   {
      dispatch_async(dispatch_get_main_queue())
      {
         let dayTrends : [Trend]? = self.dataSource.trendsForTimePeriod(.Day)
         let weekTrends : [Trend]? = self.dataSource.trendsForTimePeriod(.Week)
         let monthTrends : [Trend]? = self.dataSource.trendsForTimePeriod(.Month)

         if let dailyTrends = dayTrends where dailyTrends.isEmpty == false
         {
            self.nowTrendsVC.dataSource = dailyTrends
         }

         if let weeklyTrends = weekTrends where weeklyTrends.isEmpty == false
         {
            self.weekTrendsVC.dataSource = weeklyTrends
         }

         if let monthTrends = monthTrends where monthTrends.isEmpty == false
         {
            self.monthTrendsVC.dataSource = monthTrends
         }

         self.nowTrendsVC.tableView?.reloadData()
         self.weekTrendsVC.tableView?.reloadData()
         self.monthTrendsVC.tableView?.reloadData()

         self.activityView.stopAnimating()
         UIView.animateWithDuration(0.4, animations: { self.pageMenuHolder.alpha = 1.0 })
      }
   }

   // MARK: - CAPSPageMenuDelegate

   func willMoveToPage(controller: UIViewController, index: Int) {}

   func didMoveToPage(controller: UIViewController, index: Int) {}

   // MARK: - TablePageViewControllerProtocol

   func didSelectObjectWithString(termString: String)
   {
      let tagString: String = termString.hasPrefix("#") == false ? "#\(termString)" : termString
      let config: ModalNotificationView.Config = ModalNotificationView.Config()
      ModalNotificationView.setConfig(config)
      ModalNotificationView.show(title: NSLocalizedString("loading trends feed...", comment: "load trends feed"), image: UIImage(named: "evayellow"), animated: true)

      let modalFeedVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PlayUserProfile") as! ModalFeedVC
      modalFeedVC.currentPlaybackMode = .SEARCHFEED
      modalFeedVC.searchTerms = tagString

      presentViewController(modalFeedVC, animated: true, completion: nil)
   }

   func dismissView() { self.dismissViewControllerAnimated(true, completion: nil) }
}
