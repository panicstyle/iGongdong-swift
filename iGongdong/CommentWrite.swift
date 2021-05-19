//
//  CommentWrite.swift
//  iMoojigae
//
//  Created by dykim on 2020/09/21.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation
import UIKit

protocol CommentWriteDelegate {
    func commentWrite(_ commentWrite: CommentWrite, didWrite sender: Any)
}

class CommentWrite: CommonView, UITextViewDelegate, UINavigationControllerDelegate {
    
    //MARK: Properties
    
    @IBOutlet var viewBottom: NSLayoutConstraint!
    @IBOutlet var textField : UITextField!
    @IBOutlet var textView : UITextView!

    var isPNotice = 0
    var boardType = 0
    var commId = ""
    var boardId = ""
    var boardNo = ""
    var commentNo = ""
    var content = ""
    var delegate: CommentWriteDelegate?
    
    var mode = GlobalConst.WRITE_MODE
    
    private var keyboardObserver: KeyboardObserver?
    
    // Create left UIBarButtonItem.
    lazy var leftButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(doCancel))
        return button
    }()
    // Create right UIBarButtonItem.
    lazy var rightButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "저장", style: .plain, target: self, action: #selector(doSave))
        return button
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = self.leftButton
        self.navigationItem.rightBarButtonItem = self.rightButton
        
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        
        textView.font = bodyFont
        
        if mode == GlobalConst.WRITE_MODE {
            self.title = "댓글쓰기"
        } else if mode == GlobalConst.MODIFY_MODE {
            self.title = "댓글수정"
            textView.text = String(htmlEncodedString: content)
        } else {
            self.title = "댓글답변쓰기"
        }
        
        textView.delegate = self
        textViewSetupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardObserver = KeyboardObserver(changeHandler: { [weak self] (info) in
            guard let self = self else { return }
            switch info.event {
            case .willShow:
                print("willShow")
                self.viewBottom.constant = info.endFrame.height
            case .willHide:
                print("willHide")
                self.viewBottom.constant = 0
            default:
                break
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardObserver = nil
    }
    
    @objc override func contentSizeCategoryDidChangeNotification() {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        textView.font = bodyFont
    }
    
    // MARK: - TextViewDelegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textViewSetupView()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textViewSetupView()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        if text == "\n" {
//            textView.resignFirstResponder()
//        }
        return true
    }
    
    // MARK: - HttpSessionRequestDelegate
    
    override func httpSessionRequest(_ httpSessionRequest: HttpSessionRequest, didFinishLodingData data: Data) {
        if httpSessionRequest.tag == GlobalConst.POST_DATA {
            let str = String(data: data, encoding: .utf8) ?? ""
            if Utils.numberOfMatches(str, regex: "<meta http-equiv=\"refresh\" content=\"0;") <= 0 {
                var errMsg = Utils.findStringRegex(str, regex: "(?<=window.alert\\(\\\").*?(?=\\\")")
                errMsg = "댓글 작성중 오류가 발생했습니다. 잠시후 다시 해보세요.[\(errMsg)]"
                
                let alert = UIAlertController(title: "댓글 작성 오류", message: errMsg, preferredStyle: .alert)
                let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
                alert.addAction(confirm)
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
        } else if httpSessionRequest.tag == GlobalConst.POST_NOTICE {
            let str = String(data: data, encoding: .utf8) ?? ""
            if Utils.numberOfMatches(str, regex: "<title>오류안내 페이지") > 0 {
                var errMsg = Utils.findStringRegex(str, regex: "(<p class=\\\"cbg\\\">).*?(</p>)")
                errMsg = "댓글 작성중 오류가 발생했습니다. 잠시후 다시 해보세요.[\(errMsg)]"
                
                let alert = UIAlertController(title: "댓글 작성 오류", message: errMsg, preferredStyle: .alert)
                let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
                alert.addAction(confirm)
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
        } else {    // GET_TOKEN
            let str = String(data: data, encoding: .utf8) ?? ""
            let token = Utils.findStringRegex(str, regex: "(?<=\\\":\\\").*?(?=\\\")")
            if token == "" {
                var errMsg = "토큰 오류"
                errMsg = "댓글 작성중 오류가 발생했습니다. 잠시후 다시 해보세요.[\(errMsg)]"
                
                let alert = UIAlertController(title: "댓글 작성 오류", message: errMsg, preferredStyle: .alert)
                let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
                alert.addAction(confirm)
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            self.postDoNotice(token: token)
            return
        }
        DispatchQueue.main.sync {
            self.delegate?.commentWrite(self, didWrite: self)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - User functions
    
    func textViewSetupView() {
        if textView.text == "내용을 입력하세요." {
            textView.text = ""
//            textView.textColor = UIColor.black
        } else if textView.text == "" {
            textView.text = "내용을 입력하세요."
//            textView.textColor = UIColor.lightGray
        }
    }
    
    @objc func doCancel() {
        let alert = UIAlertController(title: "취소하시겠습니까? 취소하시면 작성된 내용이 삭제됩니다.", message: nil, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "취소", style: .default) { (action) in
            self.navigationController?.popViewController(animated: true)
        }
        let cancel = UIAlertAction(title: "계속작성", style: .default) { (action) in }
        alert.addAction(confirm)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func doSave() {
        if textView.text == "" || textView.text == "내용을 입력하세요." {
            let alert = UIAlertController(title: "입력된 내용이 없습니다.", message: nil, preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
            alert.addAction(confirm)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if boardType == GlobalConst.CAFE_TYPE_NORMAL {
            if isPNotice == 0 {
                postDoNormal()
            } else {
                getToken()
            }
        } else {
            getToken()
        }
    }
    
    private func postDoNormal() {
        var resource = ""
        if mode == GlobalConst.WRITE_MODE || mode == GlobalConst.REPLY_MODE {
            resource = "\(GlobalConst.CafeName)/cafe.php?mode=up_add&sort=\(boardId)&sub_sort=&p1=\(commId)&p2="
        } else {
            resource = "\(GlobalConst.CafeName)/cafe.php?mode=edit_reply&sort=\(boardId)&sub_sort=&p1=\(commId)&p2="
        }
        
        let escContent: String = textView.text!
        
        var bodyString = ""
        switch mode {
        case GlobalConst.WRITE_MODE:
            bodyString = "number=\(boardNo)&content=\(escContent)"
        case GlobalConst.MODIFY_MODE:
            bodyString = "number=\(commentNo)&content=\(escContent)"
        default: // REPLY_MODE
            bodyString = "number=\(boardNo)&number_re=\(commentNo)&content=\(escContent)"
        }
        
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.POST_DATA
        httpSessionRequest.requestWithParamString(httpMethod: "POST", resource: resource, paramString: bodyString, referer: resource)
    }

    private func getToken() {
        let timeInMS = floor(Date.timeIntervalBetween1970AndReferenceDate * 1000)
        let resource = "http://www.gongdong.or.kr/bbs/ajax.comment_token.php?_=\(timeInMS)"
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.GET_TOKEN
        httpSessionRequest.requestWithParamString(httpMethod: "GET", resource: resource, paramString: "", referer: resource)
    }

    private func postDoNotice(token: String) {
        var wMode = ""
        switch mode {
        case GlobalConst.WRITE_MODE:
            wMode = "c"
            commentNo = ""
        case GlobalConst.MODIFY_MODE:
            wMode = "cu"
        default: // REPLY_MODE
            wMode = "c"
        }
        
        let escContent: String = textView.text!
        
        let bodyString = "token=\(token)&w=\(wMode)&bo_table=\(boardId)&wr_id=\(boardNo)&comment_id=\(commentNo)&sca=&sfl=&stx=&spt=&page=&is_good=0&wr_content=\(escContent)"
        
        let referer = "\(GlobalConst.ServerName)/bbs/board.php?bo_table=\(boardId)&wr_id=\(boardNo)"
        
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.POST_NOTICE
        httpSessionRequest.requestWithParamString(httpMethod: "POST", resource: "\(GlobalConst.ServerName)/bbs/write_comment_update.php", paramString: bodyString, referer: referer)
    }

}
