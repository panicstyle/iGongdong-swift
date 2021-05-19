//
//  CommonView.swift
//  iMooojigae
//
//  Created by dykim on 2020/06/27.
//  Copyright © 2020 dykim. All rights reserved.
//

import UIKit
import os.log
import WebKit
import GoogleMobileAds

class CommonView : UIViewController, HttpSessionRequestDelegate, LoginToServiceDelegate {
    
    //MARK: Properties
    var config: WKWebViewConfiguration?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.commonViews.updateValue(self, forKey: self.hashValue)
        
        if #available(iOS 13.0, *) {
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: GlobalConst.SYSTEM_SYNC) {
                overrideUserInterfaceStyle = .unspecified
            } else {
                if defaults.bool(forKey: GlobalConst.DARK_MODE) {
                    overrideUserInterfaceStyle = .dark
                } else {
                    overrideUserInterfaceStyle = .light
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.contentSizeCategoryDidChangeNotification),
                                               name: UIContentSizeCategory.didChangeNotification, object: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func contentSizeCategoryDidChangeNotification() {
    }

    deinit {
        // perform the deinitialization
        NotificationCenter.default.removeObserver(self)

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.commonViews.removeValue(forKey: self.hashValue)
    }
    
    //MARK: - Navigation

    //MARK: - HttpSessionRequestDelegate
    
    func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, didFinishLodingData data: Data) {
    }

    func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, withError error: Error?) {
    }

    //MARK: - LoginToServiceDelegate
    
    func loginToService(_ loginToService: LoginToService, loginWithSuccess result: String) {
    }
    
    func loginToService(_ loginToService: LoginToService, loginWithFail result: String) {
        
    }
    
    func loginToService(_ loginToService: LoginToService, logoutWithSuccess result: String) {
        
    }
    
    func loginToService(_ loginToService: LoginToService, logoutWithFail result: String) {
        
    }
    
    func loginToService(_ loginToService: LoginToService, pushWithSuccess result: String) {
        
    }
    
    func loginToService(_ loginToService: LoginToService, pushWithFail result: String) {
        
    }
    
    //MARK: - User function
    
    func refreshWindow() {
        if #available(iOS 13.0, *) {
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: GlobalConst.SYSTEM_SYNC) {
                overrideUserInterfaceStyle = .unspecified
            } else {
                if defaults.bool(forKey: GlobalConst.DARK_MODE) {
                    //Dark
                    overrideUserInterfaceStyle = .dark
                } else {
                    //Light
                    overrideUserInterfaceStyle = .light
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

