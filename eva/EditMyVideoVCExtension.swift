//
//  EditMyVideoVCExtension.swift
//  eva
//
//  Created by Panayiotis Stylianou on 10/05/2016.
//  Copyright © 2016 Forbidden Technologies PLC. All rights reserved.
//

import Foundation

// MARK: - CaptureResponseProtocol

extension EditMyVideoVC: CaptureResponseProtocol
{
   @objc func processResponse(responseString: String!)
   {
      if let asset = currentAsset
      {
         UpdateAsset(asset.id!, responseString, asset.assetDescription!, networkDelegate);
      }
   }
}

extension EditMyVideoVC: CommentsProtocol
{
   func mustEnableComments()
   {
      enableKeyboardNotifications()
   }

   func mustDisableComments()
   {
      disableKeyboardNotifications()
   }
}

extension EditMyVideoVC: UICollectionViewDataSource, UICollectionViewDelegate
{
   // MARK: - UICollectionViewDataSource

   func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return PlaybackControl.NUMBER_OF_CELLS }

   func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
   {
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TIME_LINE_CELL, forIndexPath: indexPath) as! TimeLineCell
      cell.prepareCell()
      return cell
   }

   func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) { }

   func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
   {
      return CGSizeMake(UIConstants.TIMELINECELLHEIGHT, UIConstants.TIMELINECELLHEIGHT)
   }
}

extension EditMyVideoVC
{
   // MARK: - Keyboard notifications

   func keyboardDidShow(notification: NSNotification)
   {
      if SessionManager.sharedInstance.loginProcess == false && self.sharing == false && self.showingSimon == false
      {
         dispatch_async(dispatch_get_main_queue())
         {
            if let userInfo = notification.userInfo, keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue(), currentAsset = self.currentAsset
            {
               self.showingComments = true
               self.panGesture.enabled = false
               if self.commentsVC!.asset == nil || self.commentsVC!.asset != self.currentAsset
               {
                  self.commentsVC?.commentsDataSource.resetDataSource()
                  self.commentsVC?.asset = self.currentAsset
               }
               self.delegate?.userOpenedComments?(currentAsset)
               self.addCommentAnimationForKeyboardHeight(keyboardSize.height)
            }
         }
      }
   }
}

extension EditMyVideoVC
{
   // MARK: - Comments Animations

   func addCommentAnimationForKeyboardHeight(keyboardHeight: CGFloat)
   {
      showAllComentsAnimation()
      calculatedKeyboardHeight = keyboardHeight
      dispatch_async(dispatch_get_main_queue())
      {
         self.closeButton.hidden = false
         self.closeButton.alpha = 1.0
         UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveEaseInOut, animations: {
            var auxHolderFrame = self.commentsListHolder.frame
            var auxInputFrame = self.commentsTextField.frame
            auxHolderFrame.size.height = self.view.bounds.height - keyboardHeight
            auxInputFrame.origin.y = self.originalInputFrame!.origin.y - keyboardHeight
            self.commentsListHolder.frame = auxHolderFrame
            self.commentsTextField.frame = auxInputFrame
            }, completion: nil)
      }
   }

   func postedCommentAnimation()
   {
      dispatch_async(dispatch_get_main_queue())
      {
         self.closeButton.hidden = false
         self.closeButton.alpha = 1.0
         UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveEaseInOut, animations: {
            var auxHolderFrame = self.commentsListHolder.frame
            auxHolderFrame.size.height = self.view.bounds.height
            self.commentsListHolder.frame = auxHolderFrame
            self.commentsTextField.frame = self.originalInputFrame!
            self.socialActionsHolder.alpha = 0.0
            self.avatarHolder.alpha = 0.0
            self.commentsCountButton.alpha = 0.0
            self.commentCount.alpha = 0.0
            self.dotsCollectionView.alpha = 0.0
            self.commentsListHolder.alpha = 1.0
            }, completion: nil)
      }
   }

   func showAllComentsAnimation()
   {
      dispatch_async(dispatch_get_main_queue())
      {
         self.closeButton.hidden = false
         self.closeButton.alpha = 1.0
         UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveEaseInOut, animations: {
            var auxHolderFrame = self.commentsListHolder.frame
            auxHolderFrame.size.height = self.view.bounds.height
            self.commentsListHolder.frame = auxHolderFrame
            self.socialActionsHolder.alpha = 0.0
            self.avatarHolder.alpha = 0.0
            self.commentsCountButton.alpha = 0.0
            self.commentCount.alpha = 0.0
            self.dotsCollectionView.alpha = 0.0
            self.descriptionLabel.alpha = 0.0
            }, completion: nil)

         UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveEaseInOut, animations: { self.commentsListHolder.alpha = 1.0 }, completion: nil)
      }
   }

   func hideCommentsAnimation()
   {
      showingComments = false
      dispatch_async(dispatch_get_main_queue())
      {
         UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.socialActionsHolder.alpha = 1.0
            self.avatarHolder.alpha = 1.0
            self.commentsCountButton.alpha = 1.0
            self.commentCount.alpha = 1.0
            self.dotsCollectionView.alpha = 1.0
            self.commentsListHolder.alpha = 0.0
            self.descriptionLabel.alpha = 1.0
            var auxHolderFrame = self.commentsListHolder.frame
            auxHolderFrame.size.height = self.view.bounds.height + self.calculatedKeyboardHeight
            self.commentsListHolder.frame = auxHolderFrame
            self.commentsTextField.frame = self.originalInputFrame!
            }, completion: nil)
      }
   }
}

extension EditMyVideoVC: CommentsInteractiveProtocol
{
   func didChooseToReplyTo(screenName: String)
   {
      if commentsTextField.text!.rangeOfString(screenName) != nil
      {
         EvaLogger.sharedInstance.logMessage("Reply to ScreenName already in the text")
      }
      else
      {
         Analytics.tagEvent("Comments_Reply")
         commentsTextField.becomeFirstResponder()
         commentsTextField.text = "@\(screenName) " + commentsTextField.text!
      }
   }

   func didChooseToDeleteComment(commentId: String, _ commmentUserId: String, _ indexPath: NSIndexPath)
   {
      let alertView: UIAlertController = UIAlertController(title: "eva", message: NSLocalizedString("Are you sure you want to delete this comment?", comment: "delete comment"), preferredStyle: .Alert)
      let noAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("no", comment: "no"), style: .Cancel, handler: nil)
      let yesAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("yes", comment: "yes"), style: .Default) { [weak self](_) -> Void in
         dispatch_async(dispatch_get_main_queue()) {
            if let strongSelf = self, commentsDataSource = strongSelf.commentsVC?.commentsDataSource, commentsTableView = strongSelf.commentsVC?.commentsTable
            {
               commentsDataSource.dataSource.removeAtIndex(indexPath.row)
               commentsTableView.reloadData()
               DeleteComment(commentId, commentsDataSource.networkDelegate)
            }
         }
      }
      alertView.addAction(noAction)
      alertView.addAction(yesAction)

      presentViewController(alertView, animated: true, completion: nil)
   }
}

extension EditMyVideoVC: UITextFieldDelegate
{
   // MARK: - UITextField Delegate

   func textFieldShouldReturn(textField: UITextField) -> Bool
   {
      if showingSimon == false
      {
         if textField.tag == 1
         {
            stopPlayback()
            textField.resignFirstResponder()

            if let commentsVC = commentsVC, currentAsset = currentAsset where textField.text!.isEmpty == false
            {
               commentsVC.commentsDataSource.postComment(textField.text)
               currentAsset.commentCount++
               updateAssetValues(false)
               postedCommentAnimation()
               Analytics.tagEvent("Comment_Posted")
            }
            else
            {
               hideCommentsAnimation()
               panGesture.enabled = true
               if let currentAsset = currentAsset
               {
                  delegate?.userClosedComments?(currentAsset)
               }
               showingComments = false
               resumePlayback()
            }
            textField.text = ""
         }

         return true
      }
      else
      {
         textField.resignFirstResponder()
         if textField.text != currentAsset?.assetDescription
         {
            _hasChanges = true
         }
         simonWidget?.showSimon()

         return true
      }
   }

   func textFieldShouldBeginEditing(textField: UITextField) -> Bool
   {
      if showingSimon == false
      {
         SessionManager.sharedInstance.isAbleUser ? stopPlayback() : delegate?.userUnauthorisedAction?()
         return SessionManager.sharedInstance.isAbleUser
      }
      else
      {
         simonWidget?.hideSimon()
         return true
      }
   }
}

extension EditMyVideoVC
{
   /**
    Updates the diferent UI elements to the values of the current asset
    */
   func updateAssetValues(animated: Bool = true)
   {
      dispatch_async(dispatch_get_main_queue())
      {
         if let currentAsset = self.currentAsset
         {
            if let timeAgo = currentAsset.createdTime?.elapsedTime, metadata = currentAsset.assetDescription
            {
               self.descriptionLabel.text = metadata
               self.timeLabel.text = timeAgo
               if currentAsset.commentCount > 0
               {
                  self.showCommentCount()
                  self.commentCount.text = "\(currentAsset.commentCount)"
               }
               else
               {
                  self.hideCommentCount()
                  self.commentCount.text = ""
               }

               if currentAsset.likeCount > 0
               {
                  self.likeCount.text = "\(currentAsset.likeCount)"
                  self.likeCount.alpha = 1.0
               }
               else
               {
                  self.likeCount.text = ""
                  self.likeCount.alpha = 0.0
               }

               currentAsset.likedByMe ? self.likeButton.setImage(UIImage (named:"liked.png"),forState: .Normal) : self.likeButton.setImage(UIImage (named:"like.png"),forState: .Normal)

            }
         }
      }
   }
}

extension EditMyVideoVC
{
   // MARK: - Comments count animations

   func showCommentCount()
   {
      UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.65, initialSpringVelocity: 4.0, options: .CurveEaseInOut, animations: ({ self.commentsCountHolder.alpha = 1.0 }), completion: nil)
   }

   func hideCommentCount()
   {
      UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping: 0.65, initialSpringVelocity: 4.0, options: .CurveEaseInOut, animations: ({ self.commentsCountHolder.alpha = 0.0 }), completion: nil)
   }
}

extension EditMyVideoVC
{
   // MARK: - Avatar animations

   func centerAvatarImageView(imageView: UIImageView)
   {
      UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping:0.4, initialSpringVelocity: 13.0, options: .CurveEaseInOut, animations: {
         imageView.center = self.centerSelf
         }, completion: nil)
   }
}

extension EditMyVideoVC
{
   /**
    Jumps the player to the passed asset's start time.
    At the same time updates all related fields and displays.

    - parameter asset: Asset the asset to jump to
    */
   func moveToClip(asset: Asset)
   {
      playerWrapper?.changeAsset(asset, jumpToAsset: true, startPlayback: true)
      currentAsset = asset
      updateAssetValues(false)
      playerWrapper?.play(asset, startPlayback: true)
   }

   /**
    Jumps the player to the next clip in the playlist
    */
   func moveToNextClip()
   {

      if let asset = allAssets!.findNext(currentAsset, isForward: true) where allAssets!.isEmpty == false
      {
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { self.moveToClip(asset) }
         dispatch_async(dispatch_get_main_queue()) { self.centerAvatarImageView(self.avatarImage) }
      }
   }

   /**
    Jumps the player to the previous clip in the playlist
    */
   func moveToPrevClip()
   {
      if let asset = allAssets!.findNext(currentAsset, isForward: false) where allAssets!.isEmpty == false
      {
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { self.moveToClip(asset) }
         dispatch_async(dispatch_get_main_queue()) { self.centerAvatarImageView(self.avatarImage) }

      }
   }
}

extension EditMyVideoVC: PlayerProtocol
{
   // MARK: - PlayerProtocol

   /**
    Called everytime the player changes to a new clip.

    - parameter millis: Int64 the current time in the player.
    */
   func playerWillChangeClip(millis: Int64)
   {
      if let currentAsset = self.currentAsset
      {
         let nextAsset: Asset? = allAssets!.findNext(currentAsset, isForward: true)
         self.currentAsset?.recordView(0.0, outPoint: 0.0)
         self.currentAsset = nextAsset

         if let currentAsset = self.currentAsset
         {
            playerWrapper?.changeAsset(currentAsset, jumpToAsset: false, startPlayback: false)
         }
      }
   }

   func playerDidLoadNewImage() { }
}

