//
//  RequestsVC.swift
//  eva
//
//  Created by Panayiotis Stylianou on 21/01/2016.
//  Copyright © 2016 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

protocol HistoryRequestsProtocol
{
   func updateRequestCell(count: Int)
}

class RequestsVC: UIViewController, DataSourceProtocol, RequestsInteractiveProtocol, UITableViewDelegate {

   @IBOutlet weak var tableView: UITableView!

   // MARK: - Properties

   lazy var dataSource: RequestsDataSource = RequestsDataSource(delegate: self, interactiveDelegate: self)
   lazy var items = [UserHistoryItem]()
   var historyDelegate: HistoryRequestsProtocol?

   // MARK: - Constants

   let showProfileSegue: String = "PushToProfile"

   override func viewDidLoad() {
      navigationController?.setNavigationBarHidden(false, animated: true)
      self.title = "Approve Requests"
        super.viewDidLoad()
      self.tableView.dataSource = self.dataSource
      self.tableView.delegate = self.dataSource

      if let _ = SessionManager.sharedInstance.loggedInUser.userId
      {
         self.dataSource.getRequestsForUser()
      }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

   func refreshData()
   {
      if NSThread.isMainThread()
      {
         self.tableView.reloadData()
         UIView.animateWithDuration(0.7, animations: { self.tableView.alpha = 1.0 })
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

   // MARK: - Segue

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
   {
      if segue.identifier == showProfileSegue
      {
         if let selectedIndex = self.tableView.indexPathForSelectedRow?.row
         {
            let selectedUser = self.dataSource.items[selectedIndex]
            let destinationVC = segue.destinationViewController as! UserProfileVC
            let evaUser = selectedUser
            destinationVC.evaUserSearched = evaUser
            destinationVC.parcialUser = true
         }
      }
   }

   // MARK: - RequestInteractiveProtocol

   func reload(indexPath: NSIndexPath)
   {
      tableView.beginUpdates()
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
      tableView.endUpdates()
      tableView.reloadData()

      historyDelegate?.updateRequestCell(dataSource.items.count)
      if dataSource.items.isEmpty { self.navigationController?.popViewControllerAnimated(true) }
   }
}
