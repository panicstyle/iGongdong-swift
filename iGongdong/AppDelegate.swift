//
//  AppDelegate.swift
//  FoodTracker
//
//  Created by Jane Appleseed on 10/17/16.
//  Copyright © 2016 Apple Inc. All rights reserved.
//

import UIKit
import UserNotifications
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, ArticleViewDelegate {

    var window: UIWindow?
    var dUserInfo: [AnyHashable: Any]?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        application.applicationIconBadgeNumber = 0
        
        //create the notificationCenter
        let center = UNUserNotificationCenter.current()
        var options: UNAuthorizationOptions = [.alert, .sound]
        if #available(iOS 12.0, *) {
            options.insert(.providesAppNotificationSettings)
        }
        center.delegate = self
        center.requestAuthorization(options: options) { (granted, error) in
            // Enable or disable features based on authorization
            if error != nil {
                print("Push registration FAILED")
                print("Error: \(error?.localizedDescription ?? "")")
            }
        }
        application.registerForRemoteNotifications()

        GADMobileAds.sharedInstance().start(completionHandler: nil)

        dUserInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable : Any]
        if dUserInfo != nil {
            moveToViewController()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationWillEnterForeground")
        if self.dUserInfo != nil {
            moveToViewController()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // let chars = UnsafePointer<CChar>((deviceToken as NSData).bytes)
        var token = ""

        for i in 0..<deviceToken.count {
            //token += String(format: "%02.2hhx", arguments: [chars[i]])
            token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }

        print("Registration succeeded!")
        print("Token: ", token)
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fullPath = paths[0].appendingPathComponent("token.dat")
        let setTokenStorage = SetTokenStorage.init(token: token)
        // Archive
        if let dataToBeArchived = try? NSKeyedArchiver.archivedData(withRootObject: setTokenStorage, requiringSecureCoding: false) {
            try? dataToBeArchived.write(to: fullPath)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Registration failed! error=\(error.localizedDescription)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,  willPresent notification: UNNotification, withCompletionHandler   completionHandler: @escaping (_ options:   UNNotificationPresentationOptions) -> Void) {
        print("Handle push from foreground")
        // custom code to handle push while app is in the foreground
        print("\(notification.request.content.userInfo)")
     }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Handle push from background or closed")
        // if you set a member variable in didReceiveRemoteNotification, you  will know if this is from closed or background
        print("\(response.notification.request.content.userInfo)")
        self.dUserInfo = response.notification.request.content.userInfo
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
    }
    
    func moveToViewController() {
        guard let userInfo = dUserInfo else {
            dUserInfo = nil
            return
        }
        let boardId = userInfo["boardId"] as! String
        let boardNo = userInfo["boardNo"] as! String

        if boardId == "" || boardNo == "" {
            dUserInfo = nil
            return
        }
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let articleView = storyboard.instantiateViewController(withIdentifier: "ArticleView") as! ArticleView
        articleView.boardId = boardId
        articleView.boardNo = boardNo
        articleView.delegate = self;
        articleView.selectedRow = -1
        let navigationController = self.window?.rootViewController as! UINavigationController
        navigationController.pushViewController(articleView, animated: true)
        
        dUserInfo = nil
    }
    
    func articleView(_ articleView: ArticleView, didDelete row: Int) {
    }
}

