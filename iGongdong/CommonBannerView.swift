//
//  MainView.swift
//  iMooojigae
//
//  Created by dykim on 2020/06/27.
//  Copyright © 2020 dykim. All rights reserved.
//

import UIKit
import os.log
import WebKit
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

class CommonBannerView : CommonView {
    
    //MARK: Properties
    @IBOutlet var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14.0, *) {
            requestIDFA()
        } else {
            loadAd()
        }
    }
    
    func requestIDFA() {
        if #available(iOS 14.0, *) {
          ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
            // Tracking authorization completed. Start loading ads here.
            self.loadAd()
          })
        }
    }
    
    func loadAd() {
        // GoogleMobileAds
        self.bannerView.adUnitID = GlobalConst.AdUnitID
        self.bannerView.rootViewController = self
        self.bannerView.load(GADRequest())
    }
}

