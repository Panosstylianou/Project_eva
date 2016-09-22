//
//  UserTableViewCell.swift
//  eva
//
//  Created by Jens Wikholm on 05/11/2014.
//  Copyright (c) 2014 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell
{
   override func awakeFromNib()
   {
      super.awakeFromNib()
   }

   @IBOutlet weak var avatar: UIImageView!
   @IBOutlet weak var screenName: UILabel!
   @IBOutlet weak var followButton: UIButton!

   override init(style: UITableViewCellStyle, reuseIdentifier: String?)
   {
      super.init(style: style, reuseIdentifier: reuseIdentifier?)

   }


   required init(coder aDecoder: NSCoder)
   {
       super.init(coder: aDecoder)
   }

    override func setSelected(selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
    }

   @IBAction func followUnfollow(sender: UIButton)
   {
     // TODO : - Follow ro unfollow API
   }
}
