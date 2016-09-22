//
//  PlaybackControlAnimationsExtension.swift
//  eva
//
//  Created by Panayiotis Stylianou on 25/11/2015.
//  Copyright (c) 2015 Forbidden Technologies PLC. All rights reserved.
//

import UIKit

extension PlaybackControl
{
   // MARK: - EvaFeed start animations

   func animateEvaFeedStart(duration: NSTimeInterval = 0.7)
   {
      UIView.animateWithDuration(duration, animations: {
         self.view.alpha = 1.0
         var newFrame: CGRect = self.view.frame
         newFrame.origin.y = 0.0
         self.view.frame = newFrame
      })
   }
}

extension PlaybackControl
{
   // MARK: - Pause layer animations

   func showPauseLayer()
   {
      dispatch_async(dispatch_get_main_queue())
      {
         UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.pauseLayer.alpha = 1.0
            self.controlHolder.alpha = 0.0
            self.commentsTextField.alpha = 0.0
            self.closeButton.alpha = 0.0
            self.topVideoDescription.alpha = 0.0
            self.topScreenName.alpha = 0.0
         }, completion: nil)
      }
   }

   func hidePauseLayer()
   {
      dispatch_async(dispatch_get_main_queue())
      {
         UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.pauseLayer.alpha = 0.0
            self.controlHolder.alpha = 1.0
            self.commentsTextField.alpha = 1.0
            self.topVideoDescription.alpha = 1.0
            self.topScreenName.alpha = 1.0
            self.closeButton.alpha = 1.0
         }, completion: nil)
      }
   }
}

extension PlaybackControl
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
            self.commentsCountLabel.alpha = 0.0
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
            self.commentsCountLabel.alpha = 0.0
            self.dotsCollectionView.alpha = 0.0
            self.topScreenName.alpha = 0.0
            self.topVideoDescription.alpha = 0.0
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
            self.commentsCountLabel.alpha = 1.0
            self.dotsCollectionView.alpha = 1.0
            self.commentsListHolder.alpha = 0.0
            self.topScreenName.alpha = 1.0
            self.topVideoDescription.alpha = 1.0
            var auxHolderFrame = self.commentsListHolder.frame
            auxHolderFrame.size.height = self.view.bounds.height + self.calculatedKeyboardHeight
            self.commentsListHolder.frame = auxHolderFrame
            self.commentsTextField.frame = self.originalInputFrame!
         }, completion: nil)
      }
   }
}

extension PlaybackControl
{
   // MARK: - Avatar animations

   func centerAvatarImageView(imageView: UIImageView)
   {
      UIView.animateWithDuration(0.6, delay: 0.0, usingSpringWithDamping:0.4, initialSpringVelocity: 13.0, options: .CurveEaseInOut, animations: {
            imageView.center = self.centerSelf
         }, completion: nil)
   }

   func updateAvatarImageView(asset: Asset, animated: Bool)
   {
      dispatch_async(dispatch_get_main_queue()) {
         let visibleAvatarImageView = self.isActualAvatarVisible ? self.currentAvatarImageView : self.nextAvatarImageView
         var nonVisibleAvatarImageView = self.isActualAvatarVisible ? self.nextAvatarImageView : self.currentAvatarImageView

         nonVisibleAvatarImageView.frame = self.swipeForward ? self.nextAvatarFrame() : self.previousAvatarFrame()

         UIView.animateWithDuration(0.75, delay: 0, usingSpringWithDamping: 10, initialSpringVelocity: 3, options: .CurveEaseIn, animations: {
            let originX = visibleAvatarImageView.frame.origin.x
            let x = self.swipeForward ? originX - UIConstants.AVATARFADEOUTDISTANCE : originX + UIConstants.AVATARFADEOUTDISTANCE
            let frame = CGRectMake(x, self.middleYSelf, 0, 0)
            visibleAvatarImageView.frame = frame
            visibleAvatarImageView.alpha = 0
         }, completion: nil)

         UIView.animateWithDuration(0.75, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 10, options: .CurveEaseOut, animations: {
            let frame = self.centerAvatar()
            nonVisibleAvatarImageView.alpha = 1
            self.configureAvatarImageView(&nonVisibleAvatarImageView!)
            if let avatarId = asset.userAvatarId where avatarId.isEmpty == false
            {
               let imageURL: String = URLUtils.urlForAvatarImage(avatarId)
               if let userToken = SessionManager.sharedInstance.loggedInUser.userToken
               {
                  SDWebImageDownloader.sharedDownloader().setValue(userToken, forHTTPHeaderField: "X-Phoenix-Auth")
               }
               nonVisibleAvatarImageView.sd_setImageWithURL(NSURL(string: imageURL), placeholderImage: UIImage(named: "avatar"))
            }
            else
            {
               nonVisibleAvatarImageView.image = UIImage(named: "avatar")
            }
            nonVisibleAvatarImageView.frame = frame
            nonVisibleAvatarImageView.layer.cornerRadius = nonVisibleAvatarImageView.bounds.width / 2
         }, completion: nil)
         self.isActualAvatarVisible = !self.isActualAvatarVisible
         self.swipeForward = true
      }
   }
}

extension PlaybackControl
{
   // MARK: - Avatar functions

   func shrinkAvatarNext() -> CGRect
   {
      let referenceFrame = self.centerAvatar()
      let y = CGRectGetMinY(referenceFrame)
      var x = avatarHolder.bounds.width
      x = x - referenceFrame.width
      let avatarFrame = CGRectMake(x, y, 0, 0)
      return avatarFrame
   }

   func shrinkAvataPrevious() -> CGRect
   {
      let referenceFrame = self.centerAvatar()
      let y = CGRectGetMidY(referenceFrame)
      var x = CGRectGetMidX(referenceFrame)
      x = x - referenceFrame.size.width
      let avatarFrame = CGRectMake(x, y, 0, 0)

      return avatarFrame
   }

   func nextAvatarFrame() -> CGRect
   {
      let x = self.middleXSelf + self.avatarReferenceFrame.width
      let avatarFrame = CGRectMake(x, self.middleYSelf, 0, 0)

      return avatarFrame
   }

   func previousAvatarFrame() -> CGRect
   {
      let x = self.middleXSelf - self.avatarReferenceFrame.width
      let avatarFrame = CGRectMake(x, self.middleYSelf, 0, 0)

      return avatarFrame
   }

   func centerAvatar() -> CGRect
   {
      let width = self.height - (UIConstants.BOTTOMMARGIN * 4)
      let height = width
      let halfWidth = width / 2

      var x :CGFloat = self.view.frame.size.width / 2
      var y : CGFloat = self.minYSelf

      x = x - halfWidth
      y = y + (UIConstants.BOTTOMMARGIN * 2)

      return CGRectMake(x, y, width, height)
   }
}

extension PlaybackControl
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
