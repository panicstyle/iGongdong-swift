//
//  SceneDelegate.swift
//  AAA
//
//  Created by dykim on 2020/06/28.
//  Copyright © 2020 dykim. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate, ArticleViewDelegate  {

    var window: UIWindow?
    var dUserInfo: [AnyHashable: Any]?

    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        //create the notificationCenter
        let center = UNUserNotificationCenter.current()
        var options: UNAuthorizationOptions = [.alert, .sound]
        options.insert(.providesAppNotificationSettings)
        center.delegate = self
        center.requestAuthorization(options: options) { (granted, error) in
            // Enable or disable features based on authorization
            if error != nil {
                print("Push registration FAILED")
                print("Error: \(error?.localizedDescription ?? "")")
            }
        }
    }

    @available(iOS 13.0, *)
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        print("sceneDidBecomeActive")        
        if self.dUserInfo != nil {
            moveToViewController()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
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

