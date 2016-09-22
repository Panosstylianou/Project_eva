//
//  HeaderVideoCollection.swift
//  eva
//
//  Created by Jens Wikholm on 11/11/2014.
//  Copyright (c) 2014 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

class HeaderVideoCollection: UICollectionReusableView
{
        
   @IBOutlet weak var title: UILabel!
   @IBOutlet weak var videosCount: UILabel!
   @IBOutlet weak var playButton: UIButton!

   @IBAction func playSelection(sender: AnyObject) {
      // TOTO - Generate EDL from the secetion
   }
}
