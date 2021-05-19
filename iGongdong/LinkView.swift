//
//  LinkView.swift
//  iMoojigae
//
//  Created by dykim on 2020/09/14.
//  Copyright © 2020 dykim. All rights reserved.
//

import UIKit
import WebKit

class LinkView: CommonView, UIScrollViewDelegate, WKUIDelegate, WKNavigationDelegate {
    
    //MARK: Properties
    @IBOutlet var mainView : UIScrollView!
    @IBOutlet var btnMenu: UIBarButtonItem!
    var linkName: String = ""
    var type: Int = 0
    var link: String = ""
    
    var imageView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = linkName
        
        self.btnMenu.target = self
        self.btnMenu.action = #selector(self.linkMenu)
        
        if self.type == GlobalConst.FILE_TYPE_HTML {
            guard let url = URL(string: "\(link)") else {
                print("URL is nil")
                return
            }
            let request = URLRequest(url: url)
            
            let opWebView: WKWebView? = WKWebView.init(frame: self.view.frame, configuration: config!)
            guard let webView = opWebView else {
                return
            }
            mainView.addSubview(webView)
            webView.uiDelegate = self
            webView.navigationDelegate = self
            webView.backgroundColor = .clear
            webView.isOpaque = false
            webView.load(request)
        } else {
            let httpSessionRequest = HttpSessionRequest()
            httpSessionRequest.delegate = self
            httpSessionRequest.requestWithParam(httpMethod: "GET", resource: self.link, param: nil, referer: "")
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    //MARK: - HttpSessionRequestDelegate
    
    override func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, didFinishLodingData data: Data) {
        DispatchQueue.main.sync {
            imageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: mainView.bounds.size.width, height: mainView.bounds.size.height))
            guard let uImageView = imageView else {
                return
            }
            
            uImageView.image = UIImage.init(data: data)
            uImageView.contentMode = UIView.ContentMode.scaleAspectFit
            
            mainView.maximumZoomScale = 3.0
            mainView.minimumZoomScale = 0.6
            mainView.clipsToBounds = true
            mainView.delegate = self
            mainView.addSubview(uImageView)
        }
    }

    //MARK: - User functions
    
    @objc func linkMenu() {
        let alert: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let saveImage: UIAlertAction = UIAlertAction(title: "저장", style: .default, handler: { (alert: UIAlertAction!) in
            print("saveImage")
            let snapshot = self.imageView?.image
            guard let uSnapshop = snapshot else {
                return
            }
            self.writeToPhotoAlbum(image: uSnapshop)
        })
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
        if type == GlobalConst.FILE_TYPE_IMAGE {
            alert.addAction(saveImage)
        } else {
            alert.addAction(showOneBrowser)
        }
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }

    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            print("Save finished!")
            let alert = UIAlertController(title: "성공", message: "이미지가 사진보관함에 저장되었습니다.", preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
            alert.addAction(confirm)
            self.present(alert, animated: true, completion: nil)
        } else {
            print("Save failed!")
            let alert = UIAlertController(title: "저장 오류", message: error?.localizedDescription, preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
            alert.addAction(confirm)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
