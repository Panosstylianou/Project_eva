//
//  VideosILikeVC.swift
//  eva
//
//  Created by Jens Wikholm on 13/11/2014.
//  Copyright (c) 2014 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

class VideosILikeVC: UIViewController, UICollectionViewDelegate
{

     let favoriteVideos = ["1.jpg","2.jpg","3.jpg","4.jpg","5.jpg","6.jpg","7.jpg","8.jpg","9.jpg","10.jpg","11.jpg","12.jpg","14.jpg","15.jpg","16.jpg","17.jpg","18.jpg","19.jpg","20.jpg"]


   @IBOutlet weak var videoCollectionView: UICollectionView!

   var layoutnormal = true
   var layoutsmall = false
   var layoutmini = false

    override func viewDidLoad()
    {
        super.viewDidLoad()
      navigationController?.hidesBarsOnSwipe = true

      let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
      layout.itemSize = CGSize (width: SCREEN_WIDTH / 3 - 4, height: SCREEN_WIDTH / 3 - 4)
      layout.headerReferenceSize = CGSize (width: SCREEN_WIDTH, height: 70)
      layout.sectionInset = UIEdgeInsets (top: 0, left: 3, bottom: 0, right: 3)
      layout.minimumLineSpacing = (4.0)
      layout.minimumInteritemSpacing = (1.0)
      self.videoCollectionView.collectionViewLayout = layout
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

   @IBAction func handlePinch(sender: UIPinchGestureRecognizer) {

      if (sender.state == UIGestureRecognizerState.Began || sender.state == UIGestureRecognizerState.Changed)
      {
         println("pinching")
         if (sender.scale < 1){
            // TODO : - add scrinking adn growing animation of cells here
         }
      }
      else if (sender.state == UIGestureRecognizerState.Ended){
         println(sender.scale)

         if (sender.scale < 1){

            if layoutnormal
            {
               let layoutsmall: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
               layoutsmall.itemSize = CGSize (width: SCREEN_WIDTH / 6 - 4, height: SCREEN_WIDTH / 6 - 4)
               layoutsmall.headerReferenceSize = CGSize (width: SCREEN_WIDTH, height: 70)
               layoutsmall.sectionInset = UIEdgeInsets (top: 0, left: 3, bottom: 0, right: 3)
               layoutsmall.minimumLineSpacing = (4.0)
               layoutsmall.minimumInteritemSpacing = (1.0)
               self.videoCollectionView.collectionViewLayout = layoutsmall
               layoutsmall .invalidateLayout()

               self.layoutnormal = false
               self.layoutsmall = true
               self.layoutmini = false

            }
            else if layoutsmall
            {
               let layoutmini: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
               layoutmini.itemSize = CGSize (width: SCREEN_WIDTH / 10 - 4, height: SCREEN_WIDTH / 10 - 4)
               layoutmini.headerReferenceSize = CGSize (width: SCREEN_WIDTH, height: 70)
               layoutmini.sectionInset = UIEdgeInsets (top: 0, left: 3, bottom: 0, right: 3)
               layoutmini.minimumLineSpacing = (4.0)
               layoutmini.minimumInteritemSpacing = (1.0)
               self.videoCollectionView.collectionViewLayout = layoutmini
               layoutmini .invalidateLayout()

               self.layoutnormal = false
               self.layoutsmall = false
               self.layoutmini = true
            }
         }
         else
         {
            if layoutsmall
            {
               let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
               layout.itemSize = CGSize (width: SCREEN_WIDTH / 3 - 4, height: SCREEN_WIDTH / 3 - 4)
               layout.headerReferenceSize = CGSize (width: SCREEN_WIDTH, height: 70)
               layout.sectionInset = UIEdgeInsets (top: 0, left: 3, bottom: 0, right: 3)
               layout.minimumLineSpacing = (4.0)
               layout.minimumInteritemSpacing = (1.0)
               self.videoCollectionView.collectionViewLayout = layout
               layout .invalidateLayout()

               self.layoutnormal = true
               self.layoutsmall = false
               self.layoutmini = false
            }
            else if layoutmini
            {
               let layoutsmall: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
               layoutsmall.itemSize = CGSize (width: SCREEN_WIDTH / 6 - 4, height: SCREEN_WIDTH / 6 - 4)
               layoutsmall.headerReferenceSize = CGSize (width: SCREEN_WIDTH, height: 70)
               layoutsmall.sectionInset = UIEdgeInsets (top: 0, left: 3, bottom: 0, right: 3)
               layoutsmall.minimumLineSpacing = (4.0)
               layoutsmall.minimumInteritemSpacing = (1.0)
               self.videoCollectionView.collectionViewLayout = layoutsmall
               layoutsmall .invalidateLayout()

               self.layoutnormal = false
               self.layoutsmall = true
               self.layoutmini = false
            }
         }
      }
   }

   // MARK : - UICollectionView

   func numberOfSectionsInCollectionView(collectionView: UICollectionView) ->Int
   {
      return 1
   }
   func collectionView(collectionView: UICollectionView!, viewForSupplementaryElementOfKind kind: String!, atIndexPath indexPath: NSIndexPath!) -> UICollectionReusableView!
   {
      var identifier = "HeaderVideoCollection"
      var headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: identifier, forIndexPath: indexPath) as HeaderVideoCollection

      headerView.title.text = "play as feed"
      headerView.videosCount.text = "you have liked 35 videos"
      return headerView
   }

   func collectionView(collectionView: UICollectionView, numberOfItemsInSection: Int) ->Int
   {
         return favoriteVideos.count
   }

   func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
   {
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("VideosCell", forIndexPath: indexPath) as VideosCell

      cell.thumbnail.image = UIImage(named: "\(favoriteVideos[indexPath.row])")

      return cell
   }

   func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
   {
      let scale : CATransform3D = CATransform3DMakeScale(0, 0, 0)
      cell.contentView.alpha = 0.2;
      UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3, options:
         UIViewAnimationOptions.CurveEaseInOut, animations: ({
            cell.contentView.alpha = 1;
            cell.contentView.layer.shadowOffset = CGSizeMake(0, 0);
         }), completion: nil)
   }
   
   @IBAction func backToFavoriteVideos(segue:UIStoryboardSegue)
   {
   }
}
