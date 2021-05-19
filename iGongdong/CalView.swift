//
//  CalView.swift
//  iGongdong
//
//  Created by dykim on 2020/10/06.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation
import WebKit

class CalView: CommonView, UIScrollViewDelegate, WKUIDelegate, WKNavigationDelegate {

    //MARK: Properties
    @IBOutlet var mainView : UIScrollView!
    @IBOutlet var btnMenu: UIBarButtonItem!
    var commId: String = ""
    var boardId: String = ""
    var boardTitle: String = ""
    var link: String = ""
    
    var imageView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = boardTitle
        
        self.btnMenu.target = self
        self.btnMenu.action = #selector(self.linkMenu)
        
        if commId == "center" {
            link = "\(GlobalConst.ServerName)/bbs/board.php?bo_table=\(boardId)"
        } else {
            link = "\(GlobalConst.CafeName)/cafe.php?p1=\(commId)&sort=\(boardId)"
        }
        
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.requestWithParam(httpMethod: "GET", resource: link, param: nil, referer: "")
    }
    
    //MARK: - HttpSessionRequestDelegate
    
    override func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, didFinishLodingData data: Data) {
        let str = String(data: data, encoding: .utf8) ?? ""
        var content = ""
        if self.commId == "center" {
            content = Utils.findStringRegex(str, regex: "(<!-- board contents -->).*?(<!-- } 콘텐츠 끝 -->)")
        } else {
            content = Utils.findStringRegex(str, regex: "(<!-- 풍선 도움말 끝 -->).*?(<!-- content 끝 -->)")
        }
        DispatchQueue.main.sync {
            let opWebView: WKWebView? = WKWebView.init(frame: self.view.frame, configuration: config!)
            guard let webView = opWebView else {
                return
            }
            mainView.addSubview(webView)
            webView.uiDelegate = self
            webView.navigationDelegate = self
            webView.backgroundColor = .clear
            webView.isOpaque = false
            if self.commId == "center" {
                webView.loadHTMLString(content, baseURL: URL(string: GlobalConst.ServerName))
            } else {
                webView.loadHTMLString(content, baseURL: URL(string: GlobalConst.CafeName))
            }
        }
    }

    //MARK: - User functions
    
    @objc func linkMenu() {
        let alert: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let showOneBrowser: UIAlertAction = UIAlertAction(title: "웹브라우저로 보기", style: .default, handler: { (alert: UIAlertAction!) in
            print("showOneBrowser")
            guard let url = URL(string: "\(self.link)") else {
                print("URL is nil")
                return
            }
            UIApplication.shared.open(url, options: [:])
        })
        let cancelAction: UIAlertAction = UIAlertAction(title: "취소", style: .default, handler: { (alert: UIAlertAction!) in
            print("cancelAction")
        })
        alert.addAction(showOneBrowser)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }

}
