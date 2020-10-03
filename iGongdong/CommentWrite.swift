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

class CommentWrite: UIViewController, UITextViewDelegate, UINavigationControllerDelegate, HttpSessionRequestDelegate {
    
    //MARK: Properties
    
    @IBOutlet var viewBottom: NSLayoutConstraint!
    @IBOutlet var textField : UITextField!
    @IBOutlet var textView : UITextView!

    var boardId = ""
    var boardNo = ""
    var commentNo = ""
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

        NotificationCenter.default.addObserver(self, selector: #selector(self.contentSizeCategoryDidChangeNotification),
                                               name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        self.navigationItem.leftBarButtonItem = self.leftButton
        self.navigationItem.rightBarButtonItem = self.rightButton
        
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        
        textView.font = bodyFont
        
        self.title = "댓글쓰기"
        
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
    
    @objc func contentSizeCategoryDidChangeNotification() {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        textView.font = bodyFont
    }
    
    deinit {
        // perform the deinitialization
        NotificationCenter.default.removeObserver(self)
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
    
    func httpSessionRequest(_ httpSessionRequest: HttpSessionRequest, didFinishLodingData data: Data) {
        let str = String(data: data, encoding: .utf8) ?? ""
        if Utils.numberOfMatches(str, regex: "<b>시스템 메세지입니다</b>") > 0 {
            var errMsg = Utils.findStringRegex(str, regex: "(?<=<b>시스템 메세지입니다</b></font><br>).*?(?=<br>)")
            errMsg = "댓글 작성중 오류가 발생했습니다. 잠시후 다시 해보세요.[\(errMsg)]"
            
            let alert = UIAlertController(title: "댓글 작성 오류", message: errMsg, preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
            alert.addAction(confirm)
            DispatchQueue.main.sync {
                self.present(alert, animated: true, completion: nil)
            }
            return
        }
        DispatchQueue.main.sync {
            self.delegate?.commentWrite(self, didWrite: self)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func httpSessionRequest(_ httpSessionRequest: HttpSessionRequest, withError error: Error?) {

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
        postDo()
    }
    
    private func postDo() {
        
        var command = "MEMO_WRITE"
        var referer = "\(GlobalConst.ServerName)/board-api-read.do"
        if mode == GlobalConst.REPLY_MODE {
            command = "MEMO_REPLY"
            referer = "\(GlobalConst.ServerName)/board-api-read.do?boardId=\(boardId)&boardNo=\(boardNo)&command=READ&page=1&categoryId=-1"
        }
        
        var escContent: String = textView.text!
        escContent = escContent.replacingOccurrences(of: "\n", with: "<br />")
        
        let bodyString = "boardId=\(boardId)&page=1&categoryId=-1&time=&returnBoardNo=\(boardNo)&boardNo=\(boardNo)&command=\(command)&totalPage=0&totalRecords=0&serialBadNick=&serialBadContent=&htmlImage=%%2Fout&thumbnailSize=50&memoWriteable=true&list_yn=N&replyList_yn=N&defaultBoardSkin=default&boardWidth=690&multiView_yn=Y&titleCategory_yn=N&category_yn=N&titleNo_yn=Y&titleIcon_yn=N&titlePoint_yn=N&titleMemo_yn=Y&titleNew_yn=Y&titleThumbnail_yn=N&titleNick_yn=Y&titleTag_yn=Y&anonymity_yn=N&titleRead_yn=Y&boardModel_cd=A&titleDate_yn=Y&tag_yn=Y&thumbnailSize=50&readOver_color=%%23336699&boardSerialBadNick=&boardSerialBadContent=&userPw=&userNick=&memoContent=\(escContent)&memoSeq=\(commentNo)&pollSeq=&returnURI=&beforeCommand=&starPoint=&provenance=board-read.do&tagsName=&pageScale=&searchOrKey=&searchType=&tag=1"
        
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.POST_DATA
        httpSessionRequest.requestWithParamString(httpMethod: "POST", resource: "\(GlobalConst.ServerName)/memo-save.do", paramString: bodyString, referer: referer)
    }
}
