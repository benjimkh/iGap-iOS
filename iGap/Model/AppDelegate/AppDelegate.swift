/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the Kianiranian STDG - www.kianiranian.com
 * All rights reserved.
 */

import UIKit
import Fabric
import Crashlytics
import RealmSwift
import FirebaseMessaging
import Firebase
import UserNotifications
import IGProtoBuff
import Intents
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
    var isNeedToSetNickname : Bool = true
    internal static var userIdRegister: Int64?
    internal static var usernameRegister: String?
    internal static var authorHashRegister: String?
    internal static var isFirstEnterToApp: Bool = true
    internal static var isUpdateAvailable : Bool = false
    internal static var isDeprecatedClient : Bool = false
    internal static var appIsInBackground : Bool = false
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        let config = Realm.Configuration(schemaVersion: try! schemaVersionAtURL(Realm.Configuration.defaultConfiguration.fileURL!) + 1)
//        Realm.Configuration.defaultConfiguration = config
//        
//        _ = try! Realm()
        
        // Share
        /*
        let fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.im.iGap")!
            .appendingPathComponent("default.realm")
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let defaultRealmPath = Realm.Configuration.defaultConfiguration.fileURL!
            if FileManager.default.fileExists(atPath: defaultRealmPath.path) {
                do {
                    try FileManager.default.copyItem(atPath: defaultRealmPath.path, toPath: fileURL.path)
                } catch let error as NSError {
                    print("error occurred, here are the details:\n \(error)")
                }
            }
        }
        */
        
        let config = Realm.Configuration (
            // Share
            // fileURL: fileURL,
            schemaVersion: 29,//HINT: change schemaVersion in 'ShareConfig'
            
            /**
             * Set the block which will be called automatically when opening a Realm with a schema version lower than the one set above
             **/
            migrationBlock: { migration, oldSchemaVersion in }
        )
        Realm.Configuration.defaultConfiguration = config
        compactRealm()
        _ = try! Realm()
        
        
        Fabric.with([Crashlytics.self])
        _ = IGDatabaseManager.shared
        _ = IGWebSocketManager.sharedManager
        _ = IGFactory.shared
        _ = IGCallEventListener.sharedManager // detect cellular call state
        
        UITabBar.appearance().tintColor = UIColor.white
        //UITabBar.appearance().barTintColor = UIColor(red: 0.0, green: 176.0/255.0, blue: 191.0/255.0, alpha: 1.0)
        
        let tabBarItemApperance = UITabBarItem.appearance()
        tabBarItemApperance.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor):UIColor.red]), for: UIControl.State.normal)
        tabBarItemApperance.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor):UIColor.white]), for: UIControl.State.selected)
        
        UserDefaults.standard.setValue(false, forKey:"_UIConstraintBasedLayoutLogUnsatisfiable")

        pushNotification(application)
        detectBackground()
        
        return true
    }
    
    func compactRealm() {
        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
        let defaultParentURL = defaultURL.deletingLastPathComponent()
        let compactedURL = defaultParentURL.appendingPathComponent("default-compact.realm")
        autoreleasepool {
            let realm = try! Realm()
            try! realm.writeCopy(toFile: compactedURL)
        }
        try! FileManager.default.removeItem(at: defaultURL)
        try! FileManager.default.moveItem(at: compactedURL, to: defaultURL)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AppDelegate.appIsInBackground = true
        IGAppManager.sharedManager.setUserUpdateStatus(status: .exactly)
        
        /* change this values for import contact after than contact changed in phone contact */
        IGContactManager.syncedPhoneBookContact = false
        IGContactManager.importedContact = false
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        AppDelegate.appIsInBackground = false
        if IGAppManager.sharedManager.isUserLoggiedIn() {
            IGHelperGetShareData.manageShareDate()
            IGAppManager.sharedManager.setUserUpdateStatus(status: .online)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if !IGAppManager.sharedManager.isUserPreviouslyLoggedIn() {
            logoutAndShowRegisterViewController()
        } 
    }

    func applicationWillTerminate(_ application: UIApplication) {
    
    }
    
    /******************* Notificaton Start *******************/
    
    func pushNotification(_ application: UIApplication){
        FirebaseApp.configure()
        Messaging.messaging().isAutoInitEnabled = true
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        
        if #available(iOS 10.0, *) { // For iOS 10 display notification (sent via APNS)
            /**
             * execute following code in "IGRecentsTableViewController" and don't execute here,
             * for avoid from show permission alert in start of app when user not registered yet
             **/
            //UNUserNotificationCenter.current().delegate = self
            //let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .carPlay]
            //UNUserNotificationCenter.current().requestAuthorization(options: authOptions,completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        if let roomId = userInfo["roomId"] as? String {
            let unreadCount = IGRoom.updateUnreadCount(roomId: Int64(roomId)!)
            application.applicationIconBadgeNumber = unreadCount
        }
    }
    /******************* Notificaton End *******************/
    
    private func detectBackground() {
        
        if IGWallpaperPreview.chatSolidColor == nil {
            if let wallpaper = try! Realm().objects(IGRealmWallpaper.self).first {
                if let color = wallpaper.selectedColor {
                    IGWallpaperPreview.chatSolidColor = color
                    return
                }
            }
        }
        
        if IGWallpaperPreview.chatWallpaper == nil {
            if let wallpaper = try! Realm().objects(IGRealmWallpaper.self).first {
                IGWallpaperPreview.chatWallpaper = wallpaper.selectedFile
            }
        }
    }
    
    
    func logoutAndShowRegisterViewController(mainRoot: Bool = false) {
        UIApplication.shared.unregisterForRemoteNotifications()
        
        if mainRoot {
            self.window?.rootViewController = UIStoryboard(name: "Main", bundle:nil).instantiateInitialViewController()
        }
        
        IGAppManager.sharedManager.clearDataOnLogout()
        let storyboard : UIStoryboard = UIStoryboard(name: "Register", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "IGSplashNavigationController")
        self.window?.rootViewController?.present(vc, animated: true, completion: nil)
    }
    
    func showRegistrationSetpProfileInfo() {
        let storyboard : UIStoryboard = UIStoryboard(name: "Register", bundle: nil)
        let setNicknameVC = storyboard.instantiateViewController(withIdentifier: "RegistrationStepProfileInfo")
        let navigationBar = UINavigationController(rootViewController: setNicknameVC)
        self.window?.rootViewController?.present(navigationBar, animated: true, completion: {
            self.isNeedToSetNickname = false
        })
    }
    
    func showCallPage(userId: Int64 , isIncommmingCall: Bool = true, sdp: String? = nil, type:IGPSignalingOffer.IGPType = .voiceCalling, showAlert: Bool = true){
        
        if isIncommmingCall || !showAlert {
            let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let callPage = storyboard.instantiateViewController(withIdentifier: "IGCall") as! IGCall
            callPage.userId = userId
            callPage.isIncommingCall = isIncommmingCall
            callPage.callType = type
            callPage.callSdp = sdp
            
            var currentController = self.window?.rootViewController
            if let presentedController = currentController!.presentedViewController {
                currentController = presentedController
            }
            currentController!.present(callPage, animated: true, completion: nil)
            
        } else {
            let callAlert = UIAlertController(title: nil, message: "Select the type of call", preferredStyle: IGGlobal.detectAlertStyle())
            let voiceCall = UIAlertAction(title: "Voice Call", style: .default, handler: { (action) in
                self.showCallPage(userId: userId, isIncommmingCall: isIncommmingCall, sdp: sdp, type: IGPSignalingOffer.IGPType.voiceCalling, showAlert: false)
            })
            let videoCall = UIAlertAction(title: "Video Call", style: .default, handler: { (action) in
                self.showCallPage(userId: userId, isIncommmingCall: isIncommmingCall, sdp: sdp, type: IGPSignalingOffer.IGPType.videoCalling, showAlert: false)
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            callAlert.addAction(voiceCall)
            callAlert.addAction(videoCall)
            callAlert.addAction(cancel)
            
            self.window?.rootViewController?.present(callAlert, animated: true, completion: nil)
        }
    }
    
    func showCallQualityPage(rateId: Int64){
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let callQualityPage = storyboard.instantiateViewController(withIdentifier: "IGCallQualityShowing") as! IGCallQuality
        callQualityPage.rateId = rateId
        self.window?.rootViewController?.present(callQualityPage, animated: true, completion: nil)
    }
    
    func showLoginFaieldAlert(title: String = "Login Failed", message: String = "There was a problem logging you in. Please login again") {
        let badLoginAC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.logoutAndShowRegisterViewController()
        })
        badLoginAC.addAction(ok)
        self.window?.rootViewController?.present(badLoginAC, animated: true, completion: nil)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        let statusBarRect = UIApplication.shared.statusBarFrame
        guard let touchPoint = event?.allTouches?.first?.location(in: self.window) else { return }
        
        if statusBarRect.contains(touchPoint) {
            NotificationCenter.default.post(IGNotificationStatusBarTapped)
        }
    }
    
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let rootViewController = self.topViewControllerWithRootViewController(rootViewController: window?.rootViewController) {
            if (rootViewController.responds(to: (#selector(IGCall.canRotate)))) {
                // Unlock landscape view orientations for this view controller
                return .allButUpsideDown;
            }
        }
        // Only allow portrait (standard behaviour)
        return .portrait;
    }
    
    private func topViewControllerWithRootViewController(rootViewController: UIViewController!) -> UIViewController? {
        if (rootViewController == nil) { return nil }
        if (rootViewController.isKind(of: UITabBarController.self)) {
            return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UITabBarController).selectedViewController)
        } else if (rootViewController.isKind(of: UINavigationController.self)) {
            return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UINavigationController).visibleViewController)
        } else if (rootViewController.presentedViewController != nil) {
            return topViewControllerWithRootViewController(rootViewController: rootViewController.presentedViewController)
        }
        return rootViewController
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if #available(iOS 10.0, *) {
            if let interaction = userActivity.interaction {
                var personHandle: INPersonHandle?
                if let startVideoCallIntent = interaction.intent as? INStartVideoCallIntent {
                    personHandle = startVideoCallIntent.contacts?[0].personHandle
                } else if let startAudioCallIntent = interaction.intent as? INStartAudioCallIntent {
                    personHandle = startAudioCallIntent.contacts?[0].personHandle
                }
                CallManager.waitingPhoneCall = personHandle?.value
                CallManager.nativeCallManager()
            }
        }
        return true
    }

    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
