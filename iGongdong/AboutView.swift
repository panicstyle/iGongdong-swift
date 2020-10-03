//
//  AboutView.swift
//  iMoojigae
//
//  Created by dykim on 2020/09/23.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation
import UIKit

class AboutView : UIViewController {
    
    //MARK: Properties

    @IBOutlet var textView : UITextView!
    
    override func viewDidLoad() {
        self.title = "앱정보"
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.contentSizeCategoryDidChangeNotification),
                                               name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        textView.font = bodyFont
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let msg = "공동육아앱 for iOS\n버전 : \(version)\n개발자 : 호랑이(과천맨발어린이집 졸업조합원)\n문의메일 : panicstyle@gmail.com\n지원 페이지 : https://github.com/panicstyle/iGongdong/wiki"
            textView.text = msg
        }
    }
    
    @objc func contentSizeCategoryDidChangeNotification() {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        textView.font = bodyFont
    }
}
