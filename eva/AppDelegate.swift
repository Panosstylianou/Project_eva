//
//  AppDelegate.swift
//  eva
//
//  Created by Jens Wikholm on 03/10/2014.
//  Copyright (c) 2014 Forbidden Technologies PLC. All rights reserved.
//

import UIKit
import Crashlytics
import CoreData
import CoreSpotlight


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate , NSURLSessionTaskDelegate, NSURLSessionDelegate, ServerResponseProtocol, DataSourceProtocol, DevicesManagerProtocol
{
   // MARK: - Constants

   @nonobjc static let kValidServerActions: Set<String> = ["u", "v", "c", "q"]
   @nonobjc static let kValidServerDeepLinksDomain = "my.eva.co"
   @nonobjc static let kUURLStartUpDelay = Int64(3 * Int64(NSEC_PER_SEC))
   /// Change it to true if a PhoenixDB migration is needed
   @nonobjc static let kShouldMigratePhoenixDB = false

   // MARK: - Properties

   var window: UIWindow?

   lazy var coreDataStack = CoreDataStack()

   // MARK: - Private Properties

   private lazy var serverResponse: ServerResponse = ServerResponse(delegate: self)
   private var networkDelegate: UnsafeMutablePointer<Void> { return self.serverResponse.networkDelegate }
   private lazy var feedDataSource: FeedDataSource! = FeedDataSource(delegate: self)
   private var reach: Reachability = Reachability(hostName: "google.com")
   private var isDeepLinking: Bool = false

   private let _queue = dispatch_queue_create("ConnectionQueue", nil)
   private  var _evaConnectionReferencesStorage: Bool = true

   var evaConnectionReference: Bool {
      get {
         var reference: Bool!
         dispatch_sync(_queue, { reference = self._evaConnectionReferencesStorage })

         return reference
      }
      set {
         dispatch_sync(_queue, { self._evaConnectionReferencesStorage = newValue })
      }
   }

   // MARK: - Enums

   enum NotificationType: String
   {
      case Follow = "follow"
      case FollowRequest = "follow:requested"
      case Comment = "comment"
      case Like = "like"
      case Tagged = "tagged"
      case Mentioned = "mentioned"
   }

   enum DeepLinkingCases: String
   {
      case AssetLink = "video"
      case UserLink = "user"
      case UserFeed = "userfeed"
   }

   // MARK: - UIApplication

   func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
   {
      checkDatabaseValid()
      configurePhoenixAPI()
      configureOutsideStartup(launchOptions)
      SetStoragePath(SessionManager.sharedInstance.storagePath())
      SessionManager.sharedInstance.markDataFolderAsCloudExcluded()

      dispatch_async(dispatch_get_main_queue())
      {
         VidLibManager.sharedInstance.initialStartUp()
         SessionManager.sharedInstance.startupLogin()
      }

      Tune.setDelegate(self)
      Tune.initializeWithTuneAdvertiserId(SessionManager.sharedInstance.matAdvertiserId, tuneConversionKey: SessionManager.sharedInstance.matConversionKey)

      Localytics.autoIntegrate(SessionManager.sharedInstance.localyticsKey, launchOptions: launchOptions)
      if application.applicationState != .Background
      {
         Analytics.startTrackingServices(Analytics.TaggingServices.Localytics)
      }
      Analytics.tagEvent("App_Launched")

      let types: UIUserNotificationType = [UIUserNotificationType.Badge, UIUserNotificationType.Alert, UIUserNotificationType.Sound]
      let settings: UIUserNotificationSettings = UIUserNotificationSettings( forTypes: types, categories: nil )
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()

      self.registerDevice()

      self.loadUserDefaultPreferences()
      self.loadSimonFilters()

      if SessionManager.sharedInstance.isAppUsed == false
      {
         SettingsManager.sharedInstance.setValueForKey(UserDefaultSettings.APP_FIRST_START, value: true)
         SessionManager.sharedInstance.setAppUsed()
      }
      else
      {
         SettingsManager.sharedInstance.setValueForKey(UserDefaultSettings.APP_FIRST_START, value: false)
      }

      SessionManager.sharedInstance.isUserLoggedIn ? EvaLogger.sharedInstance.logMessage("User is logged in") : EvaLogger.sharedInstance.logMessage("User is not logged in")

      self.customApperance()

      Crashlytics.startWithAPIKey("39d89e00646453a0a151501b3428b11f2415840c")

      UploadManager.sharedInstance.managedContext = coreDataStack.context
      CaptureManager.sharedInstance.managedContext = coreDataStack.context
      LandingPageManager.sharedInstance.managedContext = coreDataStack.context
      SetUploadCompleteDelegate(BridgeObjC.giveMeUploadDelegate(UploadManager.sharedInstance))

      if #available(iOS 9, *)
      {
         NSNotificationCenter.defaultCenter().addObserver(self, selector: "powerModeChanged:", name: NSProcessInfoPowerStateDidChangeNotification, object: nil)
      }

      configureReachability()

      FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
      return true
   }

   func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject])
   {
      Localytics.handlePushNotificationOpened(userInfo)
      EvaLogger.sharedInstance.logMessage("Push notification received")

      isDeepLinking = false

      if !(userInfo["notificationType"] != nil)
      {
         EvaLogger.sharedInstance.logMessage("Push notification, no special action, normal push notification")
      }
      else
      {
         dispatch_async(dispatch_get_main_queue())
         {
            let notificationType: AppDelegate.NotificationType? = AppDelegate.NotificationType(rawValue: userInfo["notificationType"] as! String)
            let notificationAssetId: String? = userInfo["assetId"] as? String
            let notificationUserId: String? = userInfo["userId"] as? String

            switch notificationType
            {
            case .Some(.Like) where notificationUserId != nil:
               EvaNotification.addNotification(.Like, ctx: self.coreDataStack.context)
               if application.applicationState == UIApplicationState.Active
               {
                  Analytics.tagEvent("AppAlreadyStarted_PushLike")
               }
               else
               {
                  self.showModalUserHistoryPage(notificationUserId!)
                  Analytics.tagEvent("AppStarted_PushLike")
               }

            case .Some(.Comment) where notificationAssetId != nil:
               EvaNotification.addNotification(.Comment, ctx: self.coreDataStack.context)
               if application.applicationState == UIApplicationState.Active
               {
                  Analytics.tagEvent("AppAlreadyStarted_PushComment")
               }
               else
               {
                  self.showModalUserHistoryPage(notificationUserId!)
                  Analytics.tagEvent("AppStarted_PushComment")
               }

            case .Some(.Follow), .Some(.FollowRequest) where notificationUserId != nil:
               EvaNotification.addNotification(.Follow, ctx: self.coreDataStack.context)
               if application.applicationState == UIApplicationState.Active
               {
                  Analytics.tagEvent("AppAlreadyStarted_PushFollower")
               }
               else
               {
                  self.showModalUserHistoryPage(notificationUserId!)
                  Analytics.tagEvent("AppStarted_PushFollower")
               }

            case .Some(.Tagged) where notificationUserId != nil:
               EvaNotification.addNotification(.Tagged, ctx: self.coreDataStack.context)
               if application.applicationState == UIApplicationState.Active
               {
                  Analytics.tagEvent("AppAlreadyStarted_Tagged")
               }
               else
               {
                  self.showModalUserHistoryPage(notificationUserId!)
                  Analytics.tagEvent("AppStarted_Tagged")
               }

            case .Some(.Mentioned) where notificationUserId != nil:
               EvaNotification.addNotification(.Mentioned, ctx: self.coreDataStack.context)
               if application.applicationState == UIApplicationState.Active
               {
                  Analytics.tagEvent("AppAlreadyStarted_Mentioned")
               }
               else
               {
                  self.showModalUserHistoryPage(notificationUserId!)
                  Analytics.tagEvent("AppStarted_Mentioned")
               }

            default:
               EvaLogger.sharedInstance.logMessage("Open page, show UserHistory", .Custom)
            }
         }
      }
   }

   func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool
   {
      Tune.applicationDidOpenURL(url.absoluteString, sourceApplication: sourceApplication)

      let cleanedUrl = NSURL(string: url.absoluteString.stringByReplacingOccurrencesOfString("evaapplication://", withString:""))
      isDeepLinking = true

      if let url = cleanedUrl, components = url.pathComponents where components.isEmpty == false
      {
         let action: AppDelegate.DeepLinkingCases? = AppDelegate.DeepLinkingCases(rawValue: components.first!)
         let actionId =  url.lastPathComponent as String!

         switch action
         {
         case .Some(.UserFeed):
            feedDataSource.searchForUserIdFeed(actionId, firstLoad: true, limit: Constants.EVA_FEED_STARTUP_LOAD)
            Analytics.tagEvent("AppStarted_UrlUserFeed")

         case .Some(.UserLink):
            GetProfile(actionId, self.networkDelegate)
            Analytics.tagEvent("AppStarted_UrlUserProfile")

         case .Some(.AssetLink):
            GetAsset(actionId!, self.networkDelegate);
            Analytics.tagEvent("AppStarted_UrlSingleVideo")

         default:
            print("Default deep link used by Facebook Messanger")
         }
      }
      else
      {
         EvaLogger.sharedInstance.logMessage("No deep url parameters included, just opening the app")
      }
      FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)

      return false
   }

   func applicationWillResignActive(application: UIApplication)
   {
      if VidLibManager.sharedInstance.isRoboVMStarted { VidLibManager.sharedInstance.stopAllPlayers() }
      SettingsManager.sharedInstance.setValueForKey(UserDefaultSettings.APP_ALREADY_STARTED, value: false)
      NSUserDefaults.standardUserDefaults().synchronize()
      SessionManager.sharedInstance.saveLoggedInUser()
      NSNotificationCenter.defaultCenter().postNotificationName(NotificationsConstants.EVA_PLAYER_PAUSE, object: nil)
   }

   func applicationDidBecomeActive(application: UIApplication)
   {
      Tune.measureSession()
      dispatch_async(dispatch_get_main_queue())
      { [weak self]() in
         guard let strongSelf = self else { fatalError("ApplicationDidBecomeActive not able to capture AppDelegate") }
         if strongSelf.evaConnectionReference == true {
            strongSelf.restartNetwork()
         }
         if strongSelf.checkMediaTokenNeedsRenewal()
         {
            SessionManager.sharedInstance.needsFeedRefresh = true
            SessionManager.sharedInstance.startupLogin()
            if SessionManager.sharedInstance.loggedInUser.isAbleToPlay && VidLibManager.sharedInstance.startVidlib(SessionManager.sharedInstance.loggedInUser) == false
            {
               VidLibManager.sharedInstance.login(SessionManager.sharedInstance.loggedInUser)
            }
         }
         if SessionManager.sharedInstance.recording
         {
            NSNotificationCenter.defaultCenter().postNotificationName("stopRecording", object: nil)
         }
      }
   }

   func applicationDidEnterBackground(application: UIApplication) { coreDataStack.saveContext() }

   func applicationWillTerminate(application: UIApplication)
   {
      coreDataStack.saveContext()
      NSNotificationCenter.defaultCenter().postNotificationName(NotificationsConstants.EVA_PLAYER_STOP, object:nil)
      SessionManager.sharedInstance.saveLoggedInUser()
      if VidLibManager.sharedInstance.isRoboVMStarted
      {
         VidLibManager.sharedInstance.destroyVidLib()
      }
      TerminateCThreads()
   }

   func applicationDidReceiveMemoryWarning(application: UIApplication)
   {
      EvaLogger.sharedInstance.logMessage("Memory warning message received", .Error)
   }

   // MARK: Private methods

   private func getModalFeedVC() -> ModalFeedVC
   {
      return UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PlayUserProfile") as! ModalFeedVC
   }

   private func setUpModalNotification()
   {
      let config: ModalNotificationView.Config = ModalNotificationView.Config()
      ModalNotificationView.setConfig(config)
   }

   private func showModalFeedVC(inout modalVC: ModalFeedVC)
   {
      window?.rootViewController?.dismissViewControllerAnimated(false, completion: nil)
      window?.rootViewController?.presentViewController(modalVC, animated: true, completion: nil)
   }

   func showModalViewForUserProfile(evaUserSearched: EvaUserSearched?)
   {
      let storyboard = UIStoryboard(name: "Main", bundle: nil)
      let userProfileVC = storyboard.instantiateViewControllerWithIdentifier("OpenUserProfile") as! UserProfileVC
      userProfileVC.evaUserSearched = evaUserSearched
      let navController = UINavigationController(rootViewController: userProfileVC)
      navController.setNeedsStatusBarAppearanceUpdate()
      self.window?.rootViewController?.dismissViewControllerAnimated(false, completion: nil)
      self.window?.rootViewController?.presentViewController(navController, animated: true, completion: nil)
   }

   func showModalViewForPlayUserProfile()
   {
      setUpModalNotification()
      ModalNotificationView.show(title: NSLocalizedString("loading user's feed...", comment: "load feed"), image: UIImage(named: "evayellow"), animated: true)
      var modalVC = getModalFeedVC()
      modalVC.currentPlaybackMode = .OWNFEED
      showModalFeedVC(&modalVC)
   }

   func showModalViewForPlayOtherUserProfile(userId: String)
   {
      setUpModalNotification()
      ModalNotificationView.show(title: NSLocalizedString("loading user's feed...", comment: "load feed"), image: UIImage(named: "evayellow"), animated: true)
      var modalVC = getModalFeedVC()
      modalVC.currentPlaybackMode = .USERFEED
      modalVC.currentUserId = userId
      showModalFeedVC(&modalVC)
   }

   func showModalViewForPlayChannel(channelId: String)
   {
      setUpModalNotification()
      ModalNotificationView.show(title: NSLocalizedString("loading channel...", comment: "load channel"), image: UIImage(named: "evayellow"), animated: true)
      var modalVC = getModalFeedVC()
      modalVC.currentPlaybackMode = .CHANNELID
      modalVC.currentChannelId = channelId
      showModalFeedVC(&modalVC)
   }

   func showModalViewForPlaySearch(searchString: String)
   {
      setUpModalNotification()
      ModalNotificationView.show(title: NSLocalizedString("loading search's result...", comment: "load feed"), image: UIImage(named: "evayellow"), animated: true)
      var modalVC = getModalFeedVC()
      modalVC.currentPlaybackMode = .SEARCHFEED
      modalVC.searchTerms = searchString
      showModalFeedVC(&modalVC)
   }

   func showModalViewForAsset(asset: Asset)
   {
      setUpModalNotification()
      ModalNotificationView.show(title: NSLocalizedString("loading search's result...", comment: "load feed"), image: UIImage(named: "evayellow"), animated: true)
      var modalVC = getModalFeedVC()
      modalVC.currentPlaybackMode = isDeepLinking ? .SINGLEASSET : .SINGLEASSETCOMMENT
      modalVC.currentAsset = asset
      showModalFeedVC(&modalVC)
   }

   func showModalUserHistoryPage(userId: String)
   {
      let storyboard = UIStoryboard(name: "Main", bundle: nil)
      let historyVC = storyboard.instantiateViewControllerWithIdentifier("UserHistoryViewController") as! HistoryVC
      let navController = UINavigationController(rootViewController: historyVC)
      navController.setNeedsStatusBarAppearanceUpdate()
      window?.rootViewController?.dismissViewControllerAnimated(false, completion: nil)
      window?.rootViewController?.presentViewController(navController, animated: true, completion: nil)
   }

   private func customApperance()
   {
      if IOS_VERSION >= "8"
      {
         UISegmentedControl.appearance().tintColor = SEGMENT_CONTROLL_COLOR
         UIBarButtonItem.appearance().tintColor = UIBAR_BUTTON_COLOR
         UINavigationBar.appearance().shadowImage = UIImage()
         UINavigationBar.appearance().translucent = true
         UINavigationBar.appearance().barTintColor = UIColor.blackColor(0.1)
         UINavigationBar.appearance().tintColor = NAVIGATIONBAR_BUTTON_TITLE_COLOUR
         let barbuttonFont = UIFont(name: "Ubuntu-Bold", size: 15.0) ?? UIFont.systemFontOfSize(15)
         UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: barbuttonFont, NSForegroundColorAttributeName:UIColor.whiteColor()], forState: UIControlState.Normal)
         UINavigationBar.appearance().barStyle = UIBarStyle.Default
         UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: NAVIGATIONBAR_TITLE_COLOUR, NSFontAttributeName: UIFont(name: "Ubuntu-Bold", size: 15.0)!]
         UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: NAVIGATIONBAR_BUTTON_TITLE_COLOUR, NSFontAttributeName: UIFont(name: "Ubuntu-Bold", size: 15.0)!], forState: UIControlState.Normal)
      }
   }

   private func loadUserDefaultPreferences()
   {
      let defaultPreferencesFile = NSBundle.mainBundle().pathForResource("DefaultPreferences", ofType: "plist")
      if defaultPreferencesFile != nil
      {
         if let defaultPreferences = NSDictionary(contentsOfFile:defaultPreferencesFile!)
         {
            NSUserDefaults.standardUserDefaults().registerDefaults(defaultPreferences as! [String : AnyObject])
         }
      }
   }

   private func loadSimonFilters()
   {
      if JsonParserFilters.sharedInstance.simonFilterIsLoaded == false
      {
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
         {
            let JsonParser = JsonParserFilters.sharedInstance
            JsonParser.generateSimonFilters()
            EvaLogger.sharedInstance.logMessage("Loading Simon Filters finished")
         }
      }
   }

   private func registerDevice()
   {
      DevicesManager.sharedInstance.delegate = self
      DevicesManager.sharedInstance.fetchUserDevices()
   }

   // MARK: - ServerResponseProtocol

   func errorResponse(networkError: ServerErrorType?, extraData: [String:AnyObject]?) { EvaLogger.sharedInstance.logMessage("Network Error: \(networkError?.description)", .Error) }

   func serverResponse(responseFrom: ServerResponseType, jsonString: String)
   {
      if jsonString == "ok"
      {
         CLSLogv("Phoenix reachable with ping", getVaList([]))
      }
   }

   func serverResponse(responseFrom:ServerResponseType, jsonDictionary: JsonDictionary)
   {
      if responseFrom == .GetProfile
      {
         let evaUserSearched = EvaUserSearched(jsonDictionary: jsonDictionary)
         dispatch_async(dispatch_get_main_queue()) { self.showModalViewForUserProfile(evaUserSearched) }
      }
      else if responseFrom == .GetAsset
      {
         let asset = Asset(possibleAsset: jsonDictionary)
         dispatch_async(dispatch_get_main_queue()) { self.showModalViewForAsset(asset) }
      }
   }

   func serverResponse(responseFrom:ServerResponseType, nextObject: String?, jsonDictionaryArray: [JsonDictionary]) { EvaLogger.sharedInstance.logMessage("ServerResponse jsonDictionaryArray not implemented", .Error) }

   // MARK: - DataSourceProtocol

   func refreshData() { dispatch_async(dispatch_get_main_queue()) { self.showModalViewForPlayUserProfile() }}

   // MARK: - DevicesManagerProtocol

   func didReceiveDevicesCollection(devices: Devices)
   {
      let deviceIdentifier: String = UIDevice.currentDevice().identifierForVendor!.UUIDString
      let deviceName: String = UIDevice.currentDevice().name

      if devices.isEmpty == true
      {
         DevicesManager.sharedInstance.addDevice(deviceName, deviceIdentifier: deviceIdentifier)
      }
      else
      {
         if (devices.filter { $0.deviceName == deviceName && $0.deviceIdentifier == deviceIdentifier }.isEmpty)
         {
            DevicesManager.sharedInstance.addDevice(deviceName, deviceIdentifier: deviceIdentifier)
         }
      }
   }

   func didAddNewDevice(device: DeviceModel)
   {
      EvaLogger.sharedInstance.logMessage("New device with name: \(device.deviceName) and identifier: \(device.deviceIdentifier) was added to the user's list")
   }

   func powerModeChanged(sender: AnyObject?)
   {
      if #available(iOS 9, *)
      {
         NSProcessInfo.processInfo().lowPowerModeEnabled ? EvaLogger.sharedInstance.logMessage("Low power mode enabled") : EvaLogger.sharedInstance.logMessage("Low power mode disabled")
      }
   }
}

extension AppDelegate
{
   private func restartNetwork()
   {
      NetworkReconnected()
      ProxyNetworkReconnected()
      EvaLogger.sharedInstance.logMessage("Network operations restarted", .Custom)
   }

   private func configureReachability()
   {
      reach.reachableBlock = { [weak self](_) in
         guard let strongSelf = self else { fatalError("Reachable Block. Not able to capture AppDelegate") }
         if strongSelf.evaConnectionReference == false {
            EvaLogger.sharedInstance.logMessage("Network connection is back")
            CLSLogv("Phoenix reachable", getVaList([]))
            SessionManager.sharedInstance.isConnected = true
            strongSelf.restartNetwork()
            strongSelf.evaConnectionReference = true
         }
      }

      reach.unreachableBlock = { [weak self](_) in
         guard let strongSelf = self else { fatalError("Unreachable Block. Not able to capture AppDelegate") }
         if strongSelf.evaConnectionReference == true {
            strongSelf.evaConnectionReference = false
            SessionManager.sharedInstance.isConnected = false
            strongSelf.showNoNetworkMessage()
            EvaLogger.sharedInstance.logMessage("Network connection is away", .Error)
            CLSLogv("Phoenix unreachable", getVaList([]))
         }
      }
      reach.startNotifier()
   }

   func configurePhoenixAPI()
   {
      EvaLogger.sharedInstance.logMessage("Setting PhoenixAPI base url to \(SessionManager.sharedInstance.baseUrl)", .Custom)
      SetPhoenixApiUrl(SessionManager.sharedInstance.baseUrl)
   }

   private func configureOutsideStartup(launchOptions: [NSObject:AnyObject]?)
   {
      let pushNotificationStart: Bool =
      {
         guard ((launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey]) != nil) else { return false }

         return true
      }()

      let deepLinkUrlStart: Bool =
      {
         guard ((launchOptions?[UIApplicationLaunchOptionsURLKey]) != nil) else { return false }

         return true
      }()
      SessionManager.sharedInstance.outsideStarted = pushNotificationStart || deepLinkUrlStart
   }

   private func checkMediaTokenNeedsRenewal() -> Bool
   {
      assert(VidLibManager.sharedInstance.isRoboVMStarted, "Can't check media token without robovm starting, logic error here")
      let lastMediaTokenUpdate: NSDate? = SettingsManager.sharedInstance.getDateValueForKey(UserDefaultSettings.MEDIATOKEN_LAST_DATE)

      if let lastUpdate = lastMediaTokenUpdate
      {
         if isBeyondTreshold(lastUpdate) == false
         {
            EvaLogger.sharedInstance.logMessage("Media token still between ranges, no need to update")
            return false
         }
         else
         {
            EvaLogger.sharedInstance.logMessage("Media token beyond ranges, needs update")
            return true
         }
      }
         return false
   }

   private func isBeyondTreshold(date: NSDate) -> Bool { return abs(date.timeIntervalSinceNow) >= Constants.MEDIATOKEN_VALID_INTERVAL }

   /**
   Checks if the stored app version is the same as the actual one. In case
   it's a different app version, it directly wipe out the application
   data folder and database so it's generated again from scratch. Very
   rudimentary database migration system.
   */
   private func checkDatabaseValid()
   {
      let currentVersion: String = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as! String
      let previousVersion: String? = SettingsManager.sharedInstance.getStringValueForKey(UserDefaultSettings.APP_VERSION_KEY)

      if let previousVersion = previousVersion where previousVersion == currentVersion
      {
         EvaLogger.sharedInstance.logMessage("Actual app version is: \(currentVersion) and previous version is: \(previousVersion), no need to update")
      }
      else if AppDelegate.kShouldMigratePhoenixDB
      {
         EvaLogger.sharedInstance.logMessage("Actual app version is: \(currentVersion) and previous version is: \(previousVersion), the app needs to update it's DB")
         SessionManager.sharedInstance.clearDataFolder()
         SettingsManager.sharedInstance.setStringValueForKey(UserDefaultSettings.APP_VERSION_KEY, value: currentVersion)
         CLSLogv("PhoenixDB and files migrated", getVaList([]))
      } else {
         EvaLogger.sharedInstance.logMessage("Actual app version is: \(currentVersion) and previous version is: \(previousVersion), but migration flag is set to false")
      }
   }
}

extension AppDelegate
{
   func showNoNetworkMessage()
   {
      dispatch_async(dispatch_get_main_queue())
      {
         let topMostViewController: UIViewController? = UIApplication.topViewController()
         if let topMostViewController = topMostViewController
         {
            TSMessage.setDefaultViewController(topMostViewController)
         }
         TSMessage.showNotificationWithTitle(NSLocalizedString("Can't connect to the server", comment: "Can't connect to the server"), type: TSMessageNotificationType.Error)
      }
   }
}

extension AppDelegate
{
   func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool
   {
      if userActivity.activityType == NSUserActivityTypeBrowsingWeb
      {
         if shouldHandleUniversalLink(userActivity.webpageURL!) == false
         {
            UIApplication.sharedApplication().openURL(userActivity.webpageURL!)
         }
         else
         {
            handleUniversalLinks(userActivity.webpageURL!)
         }
      }

      if #available(iOS 9.0, *)
      {
         if userActivity.activityType == CSSearchableItemActionType
         {
            if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String
            {
               let webpageURL = NSURL(string: "\(CoreSpotlightService.kChannelUURLBase)\(uniqueIdentifier)")
               handleUniversalLinks(webpageURL!)
            }
         }
      }

      return true
   }

   private func shouldHandleUniversalLink(URL: NSURL) -> Bool
   {
      guard let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: true),
            let host = components.host,
            let pathComponents = URL.pathComponents
         else { return false }

      switch host
      {
      case AppDelegate.kValidServerDeepLinksDomain:
         return areValidComponents(pathComponents)

      default:
         return false
      }
   }

   private func areValidComponents(components: [String]) -> Bool
   {
      guard components.count >= 1 else { return false }
      guard AppDelegate.kValidServerActions.contains(components[1]) && components.count >= 3 else { return false }

      return true
   }

   private func handleUniversalLinks(components: [String])
   {
      switch components[1]
      {
      case "u":
         showModalViewForPlayOtherUserProfile(components[2])
         Analytics.tagEvent("AppStarted_UrlUserFeed")

      case "v":
         let videoId = components[2]
         isDeepLinking = true
         GetAsset(videoId, self.networkDelegate);
         Analytics.tagEvent("AppStarted_UrlSingleVideo")

      case "c":
         showModalViewForPlayChannel(components[2])
         Analytics.tagEvent("AppStarted_UrlChannel")

      case "q":
         showModalViewForPlaySearch("#\(components[2])")
         Analytics.tagEvent("AppStarted_UrlSearch")

      default:
         fatalError("\(components[1]) is not a valid action or user's screenname")
      }
   }

   private func handleUniversalLinks(URL: NSURL)
   {
      guard let components = URL.pathComponents else { return }
      if VidLibManager.sharedInstance.isRoboVMStarted
      {
         dispatch_async(dispatch_get_main_queue()) { [components]() in self.handleUniversalLinks(components) }
      }
      else
      {
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, AppDelegate.kUURLStartUpDelay), dispatch_get_main_queue()) { [components]() in self.handleUniversalLinks(components) }
      }
   }
}

extension UIApplication
{
   class func topViewController(base: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) -> UIViewController?
   {
      if let navigationVC = base as? UINavigationController
      {
         return topViewController(navigationVC.visibleViewController)
      }

      if let tabVC = base as? UITabBarController, selectedVC = tabVC.selectedViewController
      {
         return topViewController(selectedVC)
      }

      if let presentedVC = base?.presentedViewController
      {
         return topViewController(presentedVC)
      }

      return base
   }
}
