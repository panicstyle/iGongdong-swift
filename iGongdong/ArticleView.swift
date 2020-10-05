//
//  ArticleView.swift
//  iMoojigae
//
//  Created by dykim on 2020/09/14.
//  Copyright © 2020 dykim. All rights reserved.
//

import UIKit
import WebKit
import GoogleMobileAds

protocol ArticleViewDelegate {
    func articleView(_ articleView: ArticleView, didDelete row: Int)
}

class ArticleView: UIViewController, UITableViewDelegate, UITableViewDataSource, HttpSessionRequestDelegate, WKUIDelegate, WKNavigationDelegate, UIDocumentInteractionControllerDelegate, ArticleWriteDelegate, CommentWriteDelegate, LoginToServiceDelegate {

    //MARK: Properties
    
    @IBOutlet var tableView : UITableView!
    @IBOutlet var bannerView: GADBannerView!
    @IBOutlet var btnMenu: UIBarButtonItem!
    var commId: String = ""
    var boardId: String = ""
    var boardNo: String = ""
    var delegate: ArticleViewDelegate?
    var selectedRow = -1
    var boardType: Int = 0
    var isPNotice: Int = 0
    
    var articleData = ArticleData()
    var cellContent: UITableViewCell?
    var webView: WKWebView?
    var dicAttach: Dictionary = [String: String]()
    var contentHeight: CGFloat = 0
    var isDarkMode: Bool = false
    var strHtml: String = ""
    var webLinkType: Int = 0
    var webLink: String = ""
    var doic: UIDocumentInteractionController?
    var config: WKWebViewConfiguration?
    var editableSubject = ""
    var editableContent = ""
    var selectedCommentRow = -1
    var isLoginRetry = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.contentSizeCategoryDidChangeNotification),
                                               name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .light {
                print("Light mode")
                self.isDarkMode = false
            } else {
                print("Dark mode")
                self.isDarkMode = true
            }
        } else {
            // Fallback on earlier versions
            self.isDarkMode = false
        }
        
        self.cellContent = UITableViewCell()
        self.webView = WKWebView()
        
        self.btnMenu.target = self
        self.btnMenu.action = #selector(self.articleMenu)
        
        // GoogleMobileAds
        self.bannerView.adUnitID = GlobalConst.AdUnitID
        self.bannerView.rootViewController = self
        self.bannerView.load(GADRequest())
        
        // Load the data.
        self.loadData()
        
        let db = DBInterface()
        db.insert(commId: commId, boardId: boardId, boardNo: boardNo)
    }

    @objc func contentSizeCategoryDidChangeNotification() {
        let baseUrl = URL(string: GlobalConst.ServerName)
        self.webView?.loadHTMLString(strHtml, baseURL: baseUrl)
        self.tableView.reloadData()
    }
    
    deinit {
        // perform the deinitialization
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return 2
        default:
            return self.articleData?.commentList.count ?? 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return ""
        default:
            return String(self.articleData?.commentList.count ?? 0) + "개의 댓글"
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return UITableView.automaticDimension
            } else if indexPath.row == 1 {
                return self.contentHeight
            } else {
                return UITableView.automaticDimension
            }
        } else {
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellTitle = "Title"
        let cellContent = "Content"
        let cellReplay = "Reply"
        let cellReReply = "ReReply"

        var cell: UITableViewCell
        
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let footnoteFont = UIFont.preferredFont(forTextStyle: .footnote)
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: cellTitle, for: indexPath)
                let textSubject = cell.viewWithTag(101) as! UITextView
                let labelName = cell.viewWithTag(100) as! UILabel
                
                var subject = self.articleData?.subject ?? ""
                subject = String(htmlEncodedString: subject) ?? ""
                textSubject.text = subject
                let name: String = self.articleData?.name ?? ""
                let date: String = self.articleData?.date ?? ""
                let hit: String = self.articleData?.hit ?? ""
                labelName.text = name + " " + date + " " + hit + "명 읽음"
                
                textSubject.font = bodyFont
                labelName.font = footnoteFont
            } else {
                self.cellContent = tableView.dequeueReusableCell(withIdentifier: cellContent, for: indexPath)
                cell = self.cellContent!
                cell.addSubview(self.webView!)
            }
        default:
            let commentList = self.articleData!.commentList
            let item = commentList[indexPath.row]
            if item.isRe == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: cellReplay, for: indexPath)
                let labelName = cell.viewWithTag(200) as! UILabel
                let viewComment = cell.viewWithTag(202) as! UITextView
                labelName.text = item.name + " " + item.date

                var comment = String(htmlEncodedString: item.comment)
                if comment!.hasSuffix("\n") {
                    comment = comment!.removeSuffix()
                }
                viewComment.text = comment
                
                labelName.font = footnoteFont
                viewComment.font = bodyFont
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: cellReReply, for: indexPath)
                let labelName = cell.viewWithTag(300) as! UILabel
                let viewComment = cell.viewWithTag(302) as! UITextView
                labelName.text = item.name + " " + item.date

                let comment = String(htmlEncodedString: item.comment)
                viewComment.text = comment

                labelName.font = footnoteFont
                viewComment.font = bodyFont
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section < 1 {
            return
        }
        let commentList = self.articleData!.commentList
        selectedCommentRow = indexPath.row
        let item = commentList[indexPath.row]
        let alertTitle = "\(item.name)님의 댓글"
        
        let alert: UIAlertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)
        let delete: UIAlertAction = UIAlertAction(title: "댓글삭제", style: .default, handler: { (alert: UIAlertAction!) in
            print("delete")
            self.deleteCommentConfirm(item)
        })
        let reply: UIAlertAction = UIAlertAction(title: "댓글답변", style: .default, handler: { (alert: UIAlertAction!) in
            print("reply")
            self.writeReComment(item)
        })
        let copy: UIAlertAction = UIAlertAction(title: "댓글복사", style: .default, handler: { (alert: UIAlertAction!) in
            print("copy")
            self.copyComment(item)
        })
        let share: UIAlertAction = UIAlertAction(title: "댓글공유", style: .default, handler: { (alert: UIAlertAction!) in
            print("share")
            self.shareComment(item)
        })
        let cancelAction: UIAlertAction = UIAlertAction(title: "취소", style: .default, handler: { (alert: UIAlertAction!) in
            print("cancelAction")
        })
        alert.addAction(delete)
        alert.addAction(reply)
        alert.addAction(copy)
        alert.addAction(share)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - WKWebViewDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        let titleFont = UIFont.preferredFont(forTextStyle: .body)
//        let pointSize: Int = Int(Double(titleFont.pointSize / 17.0) * 100);
//        let fontSize = "document.getElementsByTagName(\"body\")[0].style.webkitTextSizeAdjust=\"\(pointSize)%%\";"
        let padding = "document.body.style.padding=\"0px 8px 0px 8px\";"
        let calcSize = "document.body.scrollHeight;"
        self.webView?.evaluateJavaScript(padding, completionHandler: nil)
//        self.webView?.evaluateJavaScript(fontSize, completionHandler: nil)
        self.webView?.evaluateJavaScript(calcSize, completionHandler: { (object, error) in
            let result = object as? NSNumber ?? 0
            if result == 0 {
                return
            }
            if (self.cellContent == nil) {
                return
            }
            
            self.contentHeight = CGFloat(truncating: result)
            
            var webRect: CGRect = self.webView!.frame
            webRect.size.height = self.contentHeight
            self.webView!.frame = webRect
            
            var contentRect: CGRect = self.cellContent!.frame
            contentRect.size.height = self.contentHeight
            self.cellContent!.frame = contentRect
            
            self.tableView.reloadData()
        })
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url: URL? = navigationAction.request.url
        var urlString: String? = url?.absoluteString ?? ""
        urlString = urlString?.removingPercentEncoding ?? ""
        var fileName = ""
        if boardType == GlobalConst.CAFE_TYPE_NORMAL {
            fileName = Utils.findStringRegex(urlString!, regex: "(?<=&name=).*?(?=$)")
            fileName = String(htmlEncodedString: fileName) ?? ""
        } else {
            fileName = self.dicAttach[urlString!] ?? ""
        }

        let loweredExt = fileName.fileExtension().lowercased()
        let validImageExt: Set<String> = ["tif", "tiff", "jpg", "jpeg", "gif", "png", "bmp", "bmpf", "ico", "cur", "xbm"]
        
        if (navigationAction.navigationType == WKNavigationType.linkActivated) {
            if validImageExt.contains(loweredExt) {
                self.webLinkType = GlobalConst.FILE_TYPE_IMAGE
                self.webLink = urlString ?? ""
                self.performSegue(withIdentifier: "Link", sender: self)
            } else if loweredExt.count > 0 {    // 확장자가 있으면
                let tempData = NSData.init(contentsOf: url!)
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let documentDir = paths[0]
                let filePath = documentDir.appendingPathComponent(fileName)
                let isWrite = tempData?.write(to: filePath, atomically: true)
                if isWrite != nil && isWrite! {
                    self.doic = UIDocumentInteractionController.init(url: filePath)
                    self.doic?.delegate = self
                    self.doic?.presentOpenInMenu(from: self.view.frame, in: self.view, animated: true)
                }
                decisionHandler(WKNavigationActionPolicy.cancel)
                return
            } else {
                UIApplication.shared.open(url!, options: [:])
            }
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        } else if (navigationAction.navigationType == WKNavigationType.other) {
            if urlString!.hasPrefix("jscall:") {
                let url: URL? = navigationAction.request.url
                let urlString: String? = url?.absoluteString ?? ""
                let componets = urlString!.components(separatedBy: "://")
                if componets.count > 0 {
                    let functionName = componets[1]
                    let fileName = functionName.removingPercentEncoding ?? ""
                    self.webLinkType = GlobalConst.FILE_TYPE_IMAGE
                    self.webLink = fileName
                    self.performSegue(withIdentifier: "Link", sender: self)
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
            } else if validImageExt.contains(loweredExt) {
                self.webLinkType = GlobalConst.FILE_TYPE_IMAGE
                self.webLink = urlString ?? ""
                self.performSegue(withIdentifier: "Link", sender: self)
                decisionHandler(WKNavigationActionPolicy.cancel)
                return
            } else if loweredExt.count > 0 {
                let tempData = NSData.init(contentsOf: url!)
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let documentDir = paths[0]
                let filePath = documentDir.appendingPathComponent(fileName)
                let isWrite = tempData?.write(to: filePath, atomically: true)
                if isWrite != nil && isWrite! {
                    self.doic = UIDocumentInteractionController.init(url: filePath)
                    self.doic?.delegate = self
                    self.doic?.presentOpenInMenu(from: self.view.frame, in: self.view, animated: true)
                }
                decisionHandler(WKNavigationActionPolicy.cancel)
                return
            } else {
                decisionHandler(WKNavigationActionPolicy.allow)
                return
            }
        }
        decisionHandler(WKNavigationActionPolicy.allow)
        return
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "Link":
            guard let linkView = segue.destination as? LinkView else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            linkView.linkName = ""
            linkView.type = self.webLinkType
            linkView.link = self.webLink
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }

    //MARK: - HttpSessionRequestDelegate
    
    func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, didFinishLodingData data: Data) {
        if httpSessionRequest.tag == GlobalConst.READ_ARTICLE {
            readArticleFinish(httpSessionRequest, data)
        } else if httpSessionRequest.tag == GlobalConst.DELETE_ARTICLE {
            deleteArticleFinish(httpSessionRequest, data)
        } else {
            deleteCommentFinish(httpSessionRequest, data)
        }
    }

    func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, withError error: Error?) {
    }

    //MARK: - ArticleWriteDelegate
    
    func articleWrite(_ articleWrite: ArticleWrite, didWrite sender: Any) {
        articleData = ArticleData()
        tableView.reloadData()
        loadData()
    }
        
    //MARK: - CommentWriteDelegate

    func commentWrite(_ commentWrite: CommentWrite, didWrite sender: Any) {
        articleData = ArticleData()
        tableView.reloadData()
        loadData()
    }
    
    //MARK: - LoginToServiceDelegate
    
    func loginToService(_ loginToService: LoginToService, loginWithSuccess result: String) {
        // Load the data.
        loadData()
    }
    
    func loginToService(_ loginToService: LoginToService, loginWithFail result: String) {
        let alert = UIAlertController(title: "로그인 오류", message: "설정에서 로그인 정보를 확인하세요.", preferredStyle: .alert)
        let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
        alert.addAction(confirm)
        self.present(alert, animated: true, completion: nil)
    }
    
    func loginToService(_ loginToService: LoginToService, logoutWithSuccess result: String) {
    }
    
    func loginToService(_ loginToService: LoginToService, logoutWithFail result: String) {
    }
    
    func loginToService(_ loginToService: LoginToService, pushWithSuccess result: String) {
    }
    
    func loginToService(_ loginToService: LoginToService, pushWithFail result: String) {        
    }
    
    //MARK: - Private Methods
    
    private func loadData() {
        
        var resource = ""
        if boardType == GlobalConst.CAFE_TYPE_NORMAL {
            if isPNotice == 0 {
                resource = "\(GlobalConst.CafeName)/cafe.php?sort=\(boardId)&sub_sort=&page=1&startpage=1&keyfield=&key_bs=&p1=\(commId)&p2=&p3=&number=\(boardNo)&mode=view"
            } else {
                resource = "\(GlobalConst.ServerName)/bbs/board.php?bo_table=\(boardId)&wr_id=\(boardNo)"

            }
        } else if boardType == GlobalConst.CAFE_TYPE_APPLY {
            let escBoardId = String(boardId.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed) ?? "")
            resource = "\(GlobalConst.ServerName)/bbs/board.php?bo_table=B691&sca=\(escBoardId)&wr_id=\(boardNo)"
        } else {
            resource = "\(GlobalConst.ServerName)/bbs/board.php?bo_table=\(boardId)&wr_id=\(boardNo)"
        }
        
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.READ_ARTICLE
        httpSessionRequest.requestWithParam(httpMethod: "GET", resource: resource, param: nil, referer: "")
    }
    
    func makeWebContent(_ httpSessionRequest:HttpSessionRequest) {
/*        var strImage: String = ""
        let imageList = self.articleData?.imageList
        for item in imageList! {
            let fileName = item.fileName.lowercased()
            if fileName.contains(".jpg") || fileName.contains(".jpeg")
            || fileName.contains(".png") || fileName.contains(".gif") {
                strImage = strImage + item.link
            }
        }
        strImage = strImage.replacingOccurrences(of: "<img ", with: "<img onclick=\"myapp_clickImg(this)\" width=300 ")

        var strAttach: String = ""
        let attachList = self.articleData?.attachList
        if attachList!.count > 0 {
            strAttach = strAttach + "<table boader=1><tr><th>첨부파일</th></tr>"
        }
        for item in attachList! {
            strAttach = strAttach + "<tr><td>" + item.link + "</td></tr>"
            self.dicAttach.updateValue(item.fileName, forKey: item.fileSeq)
        }
        if attachList!.count > 0 {
            strAttach = strAttach + "</table>"
        }
        
        var strProfile: String = ""
        strProfile = strProfile + "<div class='profile'>" + self.articleData!.profile + "</div>"
*/
        let attachList = self.articleData?.attachList
        for item in attachList! {
            self.dicAttach.updateValue(item.value, forKey: item.key)
        }
        
        let strContent: String = self.articleData!.content
//        strContent = strContent.replacingOccurrences(of: "<img ", with: "<img onclick=\"myapp_clickImg(this)\" width=300 ")

        let strDarkModeCss: String = """
        <style type="text/css">
        @media (prefers-color-scheme: dark) { \
            body { \
                background-color: rgb(38,38,41);
                color: white;
            }
            a:link {
                color: #0096e2;
            }
            a:visited {
                color: #9d57df;
            }
        }
        </style>
        """

        let titleFont = UIFont.preferredFont(forTextStyle: .body)
        
        var strContent2 = Utils.replaceStringRegex(strContent, regex: "(font-size).*?(;)", replace: "")
        strContent2 = Utils.replaceStringRegex(strContent2, regex: "(background-color).*?(;)", replace: "")
        
        strHtml = ""
//        strHtml += "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">"
        strHtml += "<html><head>"
        strHtml += "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
        strHtml += "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, target-densitydpi=medium-dpi\">"
        strHtml += "<script>function image_open(src, obj){window.location=\"jscall://\"+encodeURIComponent(obj.src);} function myapp_clickImg(obj){window.location=\"jscall://\"+encodeURIComponent(obj.src);}</script>"

        if self.isDarkMode {
            strHtml += strDarkModeCss
        }

        //        strHtml += "<style> html, body, table { font-size: \(pointSize)% !important; } </style>"
        strHtml += "<style> html, body, table { font-size: \(titleFont.pointSize) !important; } </style>"
        strHtml += "</head>"
        strHtml += "<body>"
        strHtml += strContent2
        strHtml += self.articleData!.imageStr
        strHtml += self.articleData!.attachStr
        strHtml += "</body></html>"
        
        editableSubject = String(htmlEncodedString: self.articleData!.subject) ?? ""
        editableContent = String(htmlEncodedString: strContent) ?? ""
        
        let wkDataStore = WKWebsiteDataStore.nonPersistent()
        //쿠키를 담을 배열 sharedCookies
        if httpSessionRequest.sharedCookies!.count > 0 {
            //sharedCookies에서 쿠키들을 뽑아내서 wkDataStore에 넣는다.
            for cookie in httpSessionRequest.sharedCookies! {
                wkDataStore.httpCookieStore.setCookie(cookie){}
            }
        }
        
        config = WKWebViewConfiguration()
        config!.websiteDataStore = wkDataStore
        
        self.webView = WKWebView.init(frame: CGRect(x: 0, y: 0, width: (self.view.frame.size.width), height: (self.cellContent?.frame.size.height)!), configuration: config!)
        self.webView?.uiDelegate = self
        self.webView?.navigationDelegate = self

        if self.isDarkMode {
            self.webView?.backgroundColor = UIColor(red: 38, green: 38, blue: 41, alpha: 1)
        } else {
            self.webView?.backgroundColor = .white
        }

        self.webView?.backgroundColor = .white
        self.webView?.isOpaque = false
        if boardType == GlobalConst.CAFE_TYPE_NORMAL {
            self.webView?.loadHTMLString(strHtml, baseURL: URL(string: GlobalConst.CafeName))
        } else {
            self.webView?.loadHTMLString(strHtml, baseURL: URL(string: GlobalConst.ServerName))
        }

        self.tableView.reloadData()
    }
    
    @objc func articleMenu() {
        let alert: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let writeComment: UIAlertAction = UIAlertAction(title: "댓글쓰기", style: .default, handler: { (alert: UIAlertAction!) in
            print("writeComment")
            self.writeComment()
        })
        let modify: UIAlertAction = UIAlertAction(title: "글수정", style: .default, handler: { (alert: UIAlertAction!) in
            print("modify")
            self.modifyArticle()
        })
        let delete: UIAlertAction = UIAlertAction(title: "글삭제", style: .default, handler: { (alert: UIAlertAction!) in
            print("delete")
            self.deleteArticleConfirm()
        })
        let showOneBrowser: UIAlertAction = UIAlertAction(title: "웹브라우저로 보기", style: .default, handler: { (alert: UIAlertAction!) in
            print("showOneBrowser")
            let link = GlobalConst.ServerName + "/board-read.do?boardId=" + self.boardId + "&boardNo=" + self.boardNo + "&command=READ&page=1&categoryId=-1&rid=20"
            guard let url = URL(string: "\(link)") else {
                print("URL is nil")
                return
            }
            UIApplication.shared.open(url, options: [:])
        })
        let cancelAction: UIAlertAction = UIAlertAction(title: "취소", style: .default, handler: { (alert: UIAlertAction!) in
            print("cancelAction")
        })
        alert.addAction(writeComment)
        alert.addAction(modify)
        alert.addAction(delete)
        alert.addAction(showOneBrowser)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func deleteArticleConfirm() {
        let alert = UIAlertController(title: "삭제하시곘습니까?", message: nil, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "확인", style: .default) { (action) in
            self.deleteArticle()
        }
        let cancel = UIAlertAction(title: "취소", style: .default) { (action) in }
        alert.addAction(confirm)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    func deleteArticle() {
        let bodyString = "boardId=\(boardId)&page=1&categoryId=-1&time=1334217622773&returnBoardNo=\(boardNo)&boardNo=\(boardNo)&command=DELETE&totalPage=0&totalRecords=0&serialBadNick=&serialBadContent=&htmlImage=%%2Fout&thumbnailSize=50&memoWriteable=true&list_yn=N&replyList_yn=N&defaultBoardSkin=default&boardWidth=710&multiView_yn=Y&titleCategory_yn=N&category_yn=N&titleNo_yn=Y&titleIcon_yn=N&titlePoint_yn=N&titleMemo_yn=Y&titleNew_yn=Y&titleThumbnail_yn=N&titleNick_yn=Y&titleTag_yn=Y&anonymity_yn=N&titleRead_yn=Y&boardModel_cd=A&titleDate_yn=Y&tag_yn=Y&thumbnailSize=50&readOver_color=%%23336699&boardSerialBadNick=&boardSerialBadContent=&userPw=&userNick=&memoContent=&memoSeq=&pollSeq=&returnURI=&beforeCommand=&starPoint=&provenance=board-read.do&tagsName=&pageScale=&searchOrKey=&searchType=&tag=1"
        
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.DELETE_ARTICLE
        httpSessionRequest.requestWithParamString(httpMethod: "POST", resource: "\(GlobalConst.ServerName)/board-save.do", paramString: bodyString, referer: "\(GlobalConst.ServerName)/board-read.do")
        
    }
    
    func readArticleFinish(_ httpSessionRequest: HttpSessionRequest, _ data: Data) {
        let str = String(data: data, encoding: .utf8) ?? ""
        if Utils.numberOfMatches(str, regex: "window.alert\\(\\\"권한이 없습니다") > 0 || Utils.numberOfMatches(str, regex: "window.alert\\(\\\"로그인 하세요") > 0 {
            print("권한오류")
            if isLoginRetry == 0 {
                isLoginRetry = 1
                // 재로그인 한다.
                let loginToService = LoginToService()
                loginToService.delegate = self
                loginToService.Login()
            } else {
                var msg = "권한이 없거나 로그인 정보를 확인하세요."
                if Utils.numberOfMatches(str, regex: "window.alert\\(\\\"권한이 없습니다") > 0 {
                   msg = "권한이 없습니다."
                }
                if Utils.numberOfMatches(str, regex: "window.alert\\(\\\"로그인 하세요") > 0 {
                    msg = "로그인 하세요."
                }
                let alert = UIAlertController(title: "오류", message: msg, preferredStyle: .alert)
                let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
                alert.addAction(confirm)
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
            }
            return
        } else {
            self.articleData = ArticleData(result: str, type: boardType, isPNotice: isPNotice)
            DispatchQueue.main.sync {
                // Cookie 처리
                let wkDataStore = WKWebsiteDataStore.nonPersistent()
                //쿠키를 담을 배열 sharedCookies
                if httpSessionRequest.sharedCookies!.count > 0 {
                    //sharedCookies에서 쿠키들을 뽑아내서 wkDataStore에 넣는다.
                    for cookie in httpSessionRequest.sharedCookies! {
                        wkDataStore.httpCookieStore.setCookie(cookie){}
                    }
                }
                config = WKWebViewConfiguration()
                config!.websiteDataStore = wkDataStore
                
                self.makeWebContent(httpSessionRequest)
                self.tableView.reloadData()
            }
        }
    }
    
    func deleteArticleFinish(_ httpSessionRequest: HttpSessionRequest, _ data: Data) {
        let str = String(data: data, encoding: .utf8) ?? ""
        
        if Utils.numberOfMatches(str, regex: "<b>시스템 메세지입니다</b>") > 0 {
            let alert = UIAlertController(title: "글 삭제 오류", message: "글을 삭제할 수 없습니다. 잠시후 다시 해보세요.", preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
            alert.addAction(confirm)
            DispatchQueue.main.sync {
                self.present(alert, animated: true, completion: nil)
            }
            return
        }
        DispatchQueue.main.sync {
            self.delegate?.articleView(self, didDelete: selectedRow)
            self.navigationController?.popViewController(animated: true)
        }
    }

    func modifyArticle() {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let articleWrite = storyboard.instantiateViewController(withIdentifier: "ArticleWrite") as! ArticleWrite
        articleWrite.boardId = self.boardId
        articleWrite.boardNo = self.boardNo
        articleWrite.strTitle = editableSubject
        articleWrite.strContent = editableContent
        articleWrite.delegate = self
        articleWrite.mode = GlobalConst.MODIFY_MODE
        self.navigationController?.pushViewController(articleWrite, animated: true)
    }
    
    func writeComment() {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let commentWrite = storyboard.instantiateViewController(withIdentifier: "CommentWrite") as! CommentWrite
        commentWrite.boardId = self.boardId
        commentWrite.boardNo = self.boardNo
        commentWrite.delegate = self
        commentWrite.mode = GlobalConst.WRITE_MODE
        self.navigationController?.pushViewController(commentWrite, animated: true)
    }
    
    func deleteCommentConfirm(_ item: CommentItem) {
        let alert = UIAlertController(title: "삭제하시곘습니까?", message: nil, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "확인", style: .default) { (action) in
            self.deleteComment(item)
        }
        let cancel = UIAlertAction(title: "취소", style: .default) { (action) in }
        alert.addAction(confirm)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    func deleteComment(_ item: CommentItem) {
        let bodyString = "boardId=\(boardId)&page=1&categoryId=-1&time=&returnBoardNo=\(boardNo)&boardNo=\(boardNo)&command=MEMO_DELETE&totalPage=0&totalRecords=0&serialBadNick=&serialBadContent=&htmlImage=%%2Fout&thumbnailSize=50&memoWriteable=true&list_yn=N&replyList_yn=N&defaultBoardSkin=default&boardWidth=710&multiView_yn=Y&titleCategory_yn=N&category_yn=N&titleNo_yn=Y&titleIcon_yn=N&titlePoint_yn=N&titleMemo_yn=Y&titleNew_yn=Y&titleThumbnail_yn=N&titleNick_yn=Y&titleTag_yn=Y&anonymity_yn=N&titleRead_yn=Y&boardModel_cd=A&titleDate_yn=Y&tag_yn=Y&thumbnailSize=50&readOver_color=%%23336699&boardSerialBadNick=&boardSerialBadContent=&userPw=&userNick=&memoContent=&memoSeq=\(item.no)&pollSeq=&returnURI=&beforeCommand=&starPoint=&provenance=board-read.do&tagsName=&pageScale=&searchOrKey=&searchType=&tag=1"
        
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.DELETE_COMMENT
        httpSessionRequest.requestWithParamString(httpMethod: "POST", resource: "\(GlobalConst.ServerName)/memo-save.do", paramString: bodyString, referer: "\(GlobalConst.ServerName)/board-read.do")
    }
    
    func deleteCommentFinish(_ httpSessionRequest: HttpSessionRequest, _ data: Data) {
        let str = String(data: data, encoding: .utf8) ?? ""
        
        if Utils.numberOfMatches(str, regex: "<b>시스템 메세지입니다</b>") > 0 {
            let alert = UIAlertController(title: "댓글 삭제 오류", message: "댓글을 삭제할 수 없습니다. 잠시후 다시 해보세요.", preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
            alert.addAction(confirm)
            DispatchQueue.main.sync {
                self.present(alert, animated: true, completion: nil)
            }
            return
        }
        DispatchQueue.main.sync {
            if selectedCommentRow >= 0 {
                var commentList = self.articleData!.commentList
                commentList.remove(at: selectedCommentRow)
                selectedCommentRow = -1
                self.articleData!.commentList = commentList
                tableView.reloadData()
            }
        }
    }
    
    func writeReComment(_ item: CommentItem) {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let commentWrite = storyboard.instantiateViewController(withIdentifier: "CommentWrite") as! CommentWrite
        commentWrite.boardId = self.boardId
        commentWrite.boardNo = self.boardNo
        commentWrite.commentNo = item.no
        commentWrite.delegate = self
        commentWrite.mode = GlobalConst.REPLY_MODE
        self.navigationController?.pushViewController(commentWrite, animated: true)
    }
    
    func copyComment(_ item: CommentItem) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = String(htmlEncodedString: item.comment)
        let alert = UIAlertController(title: nil, message: "댓글이 복사되었습니다.", preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)

        // duration in seconds
        let duration: Double = 1
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
            alert.dismiss(animated: true)
        }
        return
    }
    
    func shareComment(_ item: CommentItem) {
        let comment = String(htmlEncodedString: item.comment) ?? ""
        let activityVC = UIActivityViewController.init(activityItems: [comment], applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop,
                                            UIActivity.ActivityType.copyToPasteboard,
                                            UIActivity.ActivityType.mail,
                                            UIActivity.ActivityType.message,
                                            UIActivity.ActivityType.print]
        activityVC.completionWithItemsHandler = { activity, success, items, error in
         if success {
          // Success handling here
         }
        }
        self.present(activityVC, animated: true, completion: nil)
    }
}
