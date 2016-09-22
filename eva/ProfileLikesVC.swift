//
//  ProfileLikesVC.swift
//  eva
//
//  Created by Jens Wikholm on 13/11/2014.
//  Copyright (c) 2014 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

class ProfileLikesVC: UIViewController, UITableViewDelegate, UITableViewDataSource
{
   let users = ["1.jpg","2.jpg","3.jpg","4.jpg","5.jpg","6.jpg","7.jpg","8.jpg","9.jpg","10.jpg","11.jpg","12.jpg","14.jpg","15.jpg","16.jpg","17.jpg","18.jpg","19.jpg","20.jpg"]

   let screenNames = ["@amandaholt","@superstar23","@joseph_cool","@jenswikholm","@vickylloyd","@carmenelectra","@iamjoe","@hello22","@amandajoner1974","@joejoe","@amandaholt","@superstar23","@joseph_cool","@jenswikholm","@vickylloyd","@carmenelectra","@iamjoe","@hello22","@amandajoner1974","@joejoe"]

   let followingStatus = ["0","0","1","0","1","0","0","1","0","1","0","0","1","0","1","0","0","1","0","1"]

   @IBOutlet weak var tableView: UITableView!

   override func viewDidLoad()
   {
      self.tableView.dataSource = self
      self.tableView.delegate = self

      UIApplication .sharedApplication().statusBarHidden = false
      navigationController?.hidesBarsOnSwipe = true

      super.viewDidLoad()
   }

   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
   }


   // MARK : - UITableView

   func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
      cell.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1)
      UIView.animateWithDuration(0.25, animations: { () -> Void in
         cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
      })
   }

   func tableView(tableView: UITableView, numberOfSectionsInTableView section: Int) -> Int
   {
      return 1
   }

   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
   {
      return users.count
   }

   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
   {
      var cell = tableView.dequeueReusableCellWithIdentifier("UserTableViewCell") as UserTableViewCell
      if(cell.screenName == nil)
      {
         self.tableView.registerClass(UserTableViewCell.classForCoder(), forCellReuseIdentifier: "UserTableViewCell")
         cell = UserTableViewCell(style: UITableViewCellStyle.Default , reuseIdentifier: "UserTableViewCell")
      }

      cell.avatar.image = UIImage(named: "\(users[indexPath.row])")
      cell.screenName.text = ("\(screenNames[indexPath.row])") as String

      // MARK : - Set follow button status
      if ((followingStatus[indexPath.row]) == "1")
      {
         cell.followButton.setImage(UIImage (named:"following.png"), forState: UIControlState.Normal)
      }
      else
      {
         cell.followButton.setImage(UIImage (named:"follow.png"), forState: UIControlState.Normal)
      }

      cell.followButton.frame = CGRectMake(self.view.frame.size.width-45, 8, 35, 35)
      cell.avatar.layer.cornerRadius = cell.avatar.frame.width / 2
      cell.avatar.clipsToBounds = true
      cell.avatar.layer.borderWidth = 0
      cell.avatar.layer.borderColor = UIColor (red: 50, green: 50, blue: 50).CGColor
      return cell
   }
}

