//
//  ArticleWrite.swift
//  iMoojigae
//
//  Created by dykim on 2020/09/16.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation
import UIKit

protocol ArticleWriteDelegate {
    func articleWrite(_ articleWrite: ArticleWrite, didWrite sender: Any)
}

class ArticleWrite: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, HttpSessionRequestDelegate {
    
    //MARK: Properties
    
    @IBOutlet var viewBottom: NSLayoutConstraint!
    @IBOutlet var textField : UITextField!
    @IBOutlet var textView : UITextView!
    @IBOutlet var imageView0 : UIImageView!
    @IBOutlet var imageView1 : UIImageView!
    @IBOutlet var imageView2 : UIImageView!
    @IBOutlet var imageView3 : UIImageView!
    @IBOutlet var imageView4 : UIImageView!
    
    var commId = ""
    var boardId = ""
    var boardNo = ""
    var strTitle = ""
    var strContent = ""
    var delegate: ArticleWriteDelegate?
    var boardType: Int = 0
        
    var imageFileName = ["", "", "", "", "", ""]
    var fileName = ["", "", "", "", "", ""]
    var fileMask = ["", "", "", "", "", ""]
    var fileSize = ["", "", "", "", "", ""]
    var imageStatus = [0, 0, 0, 0, 0]
    var selectedImage = -1
    var mode = GlobalConst.WRITE_MODE
    var attachCount = 0

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
        
        textField.font = bodyFont
        textView.font = bodyFont
        
        if mode == GlobalConst.WRITE_MODE {
            self.title = "글쓰기"
        } else {
            self.title = "글수정"
            textField.text = strTitle
            textView.text = strContent
        }
        
        textView.delegate = self
        textViewSetupView()
        
        textField.becomeFirstResponder()
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
        
        textField.font = bodyFont
        textView.font = bodyFont
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                      with event: UIEvent?) {
        print("touchesBegan")
        if touches.count > 0 {
//            self.view.endEditing(true)
            let touch: UITouch = touches.first!
            var imageStatus = 0
            if touch.view == imageView0 {
                print("touch imageView0")
                selectedImage = 0
                imageStatus = self.imageStatus[0]
            } else if touch.view == imageView1 {
                print("touch imageView1")
                selectedImage = 1
                imageStatus = self.imageStatus[1]
            } else if touch.view == imageView2 {
                print("touch imageView2")
                selectedImage = 2
                imageStatus = self.imageStatus[2]
            } else if touch.view == imageView3 {
                print("touch imageView3")
                selectedImage = 3
                imageStatus = self.imageStatus[3]
            } else if touch.view == imageView4 {
                print("touch imageView4")
                selectedImage = 4
                imageStatus = self.imageStatus[4]
            }
            if imageStatus == 0 {
                // ImagePicker
                let imagePicker = UIImagePickerController()
                imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                imagePicker.delegate = self
                self.present(imagePicker, animated: true, completion:nil)
            } else {
                // remove image
                let alert: UIAlertController = UIAlertController(title: "이미지를 삭제하시겠습니까?", message: nil, preferredStyle: .alert)
                let okAction: UIAlertAction = UIAlertAction(title: "삭제", style: .default, handler: { (alert: UIAlertAction!) in
                    self.deleteImage()
                })
                let cancelAction: UIAlertAction = UIAlertAction(title: "취소", style: .default, handler: { (alert: UIAlertAction!) in
                    print("modify")
                })
                alert.addAction(okAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        if selectedImage == 0 {
            imageView0.image = image
            imageStatus[0] = 1
            imageFileName[0] = "0000.PNG"
        } else if selectedImage == 1 {
            imageView1.image = image
            imageStatus[1] = 1
            imageFileName[1] = "0001.PNG"
        } else if selectedImage == 2 {
            imageView2.image = image
            imageStatus[2] = 1
            imageFileName[2] = "0002.PNG"
        } else if selectedImage == 3 {
            imageView3.image = image
            imageStatus[3] = 1
            imageFileName[3] = "0003.PNG"
        } else if selectedImage == 4 {
            imageView4.image = image
            imageStatus[4] = 1
            imageFileName[4] = "0004.PNG"
        }
        
        picker.dismiss(animated: true, completion: nil)
    }

    // MARK: - HttpSessionRequestDelegate

    func httpSessionRequest(_ httpSessionRequest: HttpSessionRequest, didFinishLodingData data: Data) {
        if httpSessionRequest.tag == GlobalConst.POST_FILE {
            let str = String(data: data, encoding: .utf8) ?? ""
            
            if Utils.numberOfMatches(str, regex: "fileNameArray\\[0\\] =") <= 0 {
                var errMsg = Utils.findStringRegex(str, regex: "(?<=var message = ').*?(?=';)")
                errMsg = Utils.replaceStringHtmlTag(str)
                
                let alert = UIAlertController(title: "입력된 내용이 없습니다.", message: errMsg, preferredStyle: .alert)
                let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
                alert.addAction(confirm)
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            if !parseAttachResult(str) {
                let alert = UIAlertController(title: "글 작성 오류", message: "첨부파일에서 오류가 발생했습니다.", preferredStyle: .alert)
                let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
                alert.addAction(confirm)
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            DispatchQueue.main.sync {
                postDo()
            }
        } else {        // httpSessionRequest.tag == GlobalConst.POST_DATA
            let str = String(data: data, encoding: .utf8) ?? ""
            if Utils.numberOfMatches(str, regex: "<b>시스템 메세지입니다</b>") > 0 {
                var errMsg = Utils.findStringRegex(str, regex: "(?<=<b>시스템 메세지입니다</b></font><br>).*?(?=<br>)")
                errMsg = "글 작성중 오류가 발생했습니다. 잠시후 다시 해보세요.[\(errMsg)]"
                
                let alert = UIAlertController(title: "글 작성 오류", message: errMsg, preferredStyle: .alert)
                let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
                alert.addAction(confirm)
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            DispatchQueue.main.sync {
                self.delegate?.articleWrite(self, didWrite: self)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func httpSessionRequest(_ httpSessionRequest: HttpSessionRequest, withError error: Error?) {
        
    }
    
    // MARK: - User functions
    
    func parseAttachResult(_ str: String) -> Bool {
        for i in 0...attachCount {
            fileName[i] = Utils.findStringRegex(str, regex: "(?<=fileNameArray\\[.\\] = ').*?(?=';)")
            fileMask[i] = Utils.findStringRegex(str, regex: "(?<=fileMaskArray\\[.\\] = ').*?(?=';)")
            fileSize[i] = Utils.findStringRegex(str, regex: "(?<=fileSizeArray\\[.\\] = ).*?(?=;)")
            
            if fileName[i] == "" || fileMask[i] == "" || fileSize[i] == "" {
                return false
            }
        }
        
        return true
    }
    
    func textViewSetupView() {
        if textView.text == "내용을 입력하세요." {
            textView.text = ""
//            textView.textColor = UIColor.black
        } else if textView.text == "" {
            textView.text = "내용을 입력하세요."
//            textView.textColor = UIColor.lightGray
        }
    }
    
    func deleteImage() {
        if selectedImage == 0 {
            imageView0.image = UIImage.init(named: "ic_image")
            imageStatus[0] = 0
            imageFileName[0] = ""
        } else if selectedImage == 1 {
            imageView1.image = UIImage.init(named: "ic_image")
            imageStatus[1] = 0
            imageFileName[1] = ""
        } else if selectedImage == 2 {
            imageView2.image = UIImage.init(named: "ic_image")
            imageStatus[2] = 0
            imageFileName[2] = ""
        } else if selectedImage == 3 {
            imageView3.image = UIImage.init(named: "ic_image")
            imageStatus[3] = 0
            imageFileName[3] = ""
        } else if selectedImage == 4 {
            imageView4.image = UIImage.init(named: "ic_image")
            imageStatus[4] = 0
            imageFileName[4] = ""
        }
    }
    
    @objc private func doCancel() {
        let alert = UIAlertController(title: "취소하시겠습니까? 취소하시면 작성된 내용이 삭제됩니다.", message: nil, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "취소", style: .default) { (action) in
            self.navigationController?.popViewController(animated: true)
        }
        let cancel = UIAlertAction(title: "계속작성", style: .default) { (action) in }
        alert.addAction(confirm)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func doSave() {
        if textField.text == "" || textView.text == "" || textView.text == "내용을 입력하세요." {
            let alert = UIAlertController(title: "입력된 내용이 없습니다.", message: nil, preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
            alert.addAction(confirm)
            self.present(alert, animated: true, completion: nil)
            return
        }
        if (imageStatus[0] == 1 || imageStatus[1] == 1 || imageStatus[2] == 1 || imageStatus[3] == 1 || imageStatus[4] == 1) {
            postWithAttach()
        } else {
            postDo()
        }
    }
    
    private func postWithAttach() {
        let boundary = "0xKhTmLbOuNdArY"
        var body: Data = Data()
        
        // userEmail
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userEmail\"\r\n\r\n".data(using:.utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // userHomepage
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userHomepage\"\r\n\r\n".data(using:.utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // boardTitle
        let boardTitle = textField.text
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"boardTitle\"\r\n\r\n".data(using:.utf8)!)
        body.append("\(boardTitle!)\r\n".data(using: .utf8)!)

        // whatmode_uEdit
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"whatmode_uEdit\"\r\n\r\n".data(using:.utf8)!)
        body.append("on\r\n".data(using: .utf8)!)

        // editContent
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"editContent\"\r\n\r\n".data(using:.utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // tagsName
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"tagsName\"\r\n\r\n".data(using:.utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        attachCount = 0
        for i in 0...4 {
            if imageStatus[i] == 1 {
                var image: UIImage?
                if (i == 0) {
                    image = scaleToFitWidth(imageView0.image!)
                } else if (i == 1) {
                    image = scaleToFitWidth(imageView1.image!)
                } else if (i == 2) {
                    image = scaleToFitWidth(imageView2.image!)
                } else if (i == 3) {
                    image = scaleToFitWidth(imageView3.image!)
                } else if (i == 4) {
                    image = scaleToFitWidth(imageView4.image!)
                }
                let imageData = image!.pngData()

                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"file\(attachCount)\"; filename=\"\(imageFileName[i])\"\r\n".data(using:.utf8)!)
                body.append("Content-Type: application/octet-stream\r\n\r\n".data(using:.utf8)!)
                body.append(imageData!)
                body.append("\r\n".data(using: .utf8)!)
                
                attachCount += 1
            }
        }
        
        // subId
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"subId\"\r\n\r\n".data(using:.utf8)!)
        body.append("sub01\r\n".data(using: .utf8)!)
        
        // mode
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"mode\"\r\n\r\n".data(using:.utf8)!)
        body.append("attach\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.POST_FILE
        httpSessionRequest.requestWithMultiPart(resource: "\(GlobalConst.ServerName)/uploadManager", param: body, referer: "\(GlobalConst.ServerName)/board-edit.do", boundary: boundary)
    }

    private func postDo() {
        
        var command = "WRITE"
        if mode == GlobalConst.MODIFY_MODE {
            command = "MODIFY"
        }
        
        var escContent: String = textView.text!
        let escTitle: String  = textField.text!
        
        escContent = escContent.replacingOccurrences(of: "\n", with: "<br />")
        
        var strFileName = ""
        var strFileMask = ""
        var strFileSize = ""
        
        for i in 0..<attachCount {
            if i > 0 {
                strFileName += "|"
                strFileMask += "|"
                strFileSize += "|"
            }
            strFileName += fileName[i]
            strFileMask += fileMask[i]
            strFileSize += fileMask[i]
        }
    
        let bodyString = "boardId=\(boardId)&page=1&categoryId=-1&boardNo=\(boardNo)&command=\(command)&htmlImage=%%2Fout&file_cnt=5&tag_yn=Y&thumbnailSize=50&boardWidth=710&defaultBoardSkin=default&boardBackGround_color=&boardBackGround_picture=&boardSerialBadNick=&boardSerialBadContent=&totalSize=20&serialBadNick=&serialBadContent=&fileTotalSize=0&simpleFileTotalSize=0+Bytes&serialFileName=&serialFileMask=&serialFileSize=&userPoint=2530&userEmail=&userHomepage=&boardPollFrom_time=&boardPollTo_time=&boardContent=\(escContent)&boardTitle=\(escTitle)&boardSecret_fg=N&boardEdit_fg=M&userNick=&userPw=&fileName=\(strFileName)&fileMask=\(strFileMask)&fileSize=\(strFileSize)&pollContent=&boardPoint=0&boardTop_fg=&totalsize=0&tag=0&tagsName="
        
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.POST_DATA
        httpSessionRequest.requestWithParamString(httpMethod: "POST", resource: "\(GlobalConst.ServerName)/board-save.do", paramString: bodyString, referer: "\(GlobalConst.ServerName)/board-edit.do")
    }
    
    func scaleToFitWidth(_ image: UIImage) -> UIImage {
        if image.size.width <= CGFloat(GlobalConst.SCALE_SIZE) {
            return image
        }
        
        let ratio = CGFloat(GlobalConst.SCALE_SIZE) / image.size.width
        let height = image.size.height * ratio
        
        UIGraphicsBeginImageContext(CGSize(width: CGFloat(GlobalConst.SCALE_SIZE), height: height))
        image.draw(in: CGRect(x: 0, y: 0, width: CGFloat(GlobalConst.SCALE_SIZE), height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
