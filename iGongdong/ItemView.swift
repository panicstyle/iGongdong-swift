//
//  ItemsView.swift
//  iMoojigae
//
//  Created by dykim on 2020/09/12.
//  Copyright © 2020 dykim. All rights reserved.
//

import UIKit
import GoogleMobileAds

class ItemView: UIViewController, UITableViewDelegate, UITableViewDataSource, HttpSessionRequestDelegate, ArticleViewDelegate, ArticleWriteDelegate, LoginToServiceDelegate {

    //MARK: Properties
    
    @IBOutlet var tableView : UITableView!
    @IBOutlet var bannerView: GADBannerView!
    @IBOutlet var newArticle: UIBarButtonItem!
    var boardTitle: String = ""
    var boardType = 0
    var commId: String = ""
    var boardId: String = ""
    
    var mode = 0
    var itemList = [Item]()
    var nPage: Int = 1
    var isEndPage = false
    var isLoginRetry = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.contentSizeCategoryDidChangeNotification),
                                               name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        self.title = boardTitle
        
        if boardType != GlobalConst.CAFE_TYPE_NORMAL {
            newArticle.isEnabled = false
        }
        
        // GoogleMobileAds
        self.bannerView.adUnitID = GlobalConst.AdUnitID
        self.bannerView.rootViewController = self
        self.bannerView.load(GADRequest())
        
        // Load the data.
        loadData()
    }
    
    @objc func contentSizeCategoryDidChangeNotification() {
        self.tableView.reloadData()
    }

    deinit {
        // perform the deinitialization
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return itemList.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellItem = "Item"
        let cellReItem = "ReItem"
        let cellPicItem = "PicItem"

        var cell: UITableViewCell
        let item = itemList[indexPath.row]
        let isRe = item.isRe
        
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let footnoteFont = UIFont.preferredFont(forTextStyle: .footnote)

        if mode == 1 || boardType == GlobalConst.CAFE_TYPE_ING {
            cell = tableView.dequeueReusableCell(withIdentifier: cellPicItem, for: indexPath)

            // Fetches the appropriate meal for the data source layout.
            let imageNew: UIImageView = cell.viewWithTag(210) as! UIImageView
            let textSubject: UITextView = cell.viewWithTag(201) as! UITextView
            let labelName: UILabel = cell.viewWithTag(202) as! UILabel
            let labelComment: UILabel = cell.viewWithTag(203) as! UILabel
            let imageView: UIImageView = cell.viewWithTag(200) as! UIImageView

            imageView.downloaded(from: item.picLink)
            
            if (item.isNew == 1) {
                imageNew.image = UIImage.init(named: "circle")
            } else {
                imageNew.image = UIImage.init(named: "circle-black")
            }
            
            if item.comment == "" || item.comment == "0" {
                labelComment.isHidden = true
            } else {
                labelComment.isHidden = false
                labelComment.layer.cornerRadius = 8
                labelComment.layer.borderWidth = 2.0;
                let cnt = Int(item.comment) ?? 1
                if cnt < 10 {
                    labelComment.textColor = Utils.hexStringToUIColor(hex: "0B84FF")
                } else {
                    labelComment.textColor = Utils.hexStringToUIColor(hex: "30D158")
                }
                labelComment.layer.borderColor = labelComment.textColor.cgColor;
            }
            
            let subject = String(htmlEncodedString: item.subject)
            textSubject.text = subject
            labelName.text = item.name + " " + item.date
            labelComment.text = item.comment
            
            if item.read == 1 {
                textSubject.textColor = .gray
            } else {
                if #available(iOS 13.0, *) {
                    textSubject.textColor = .label
                } else {
                    textSubject.textColor = .black
                }
            }

            textSubject.font = bodyFont
            labelName.font = footnoteFont
            labelComment.font = footnoteFont
        } else {
            if isRe == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: cellItem, for: indexPath)
                // Fetches the appropriate meal for the data source layout.
                let imageView: UIImageView = cell.viewWithTag(110) as! UIImageView
                let textSubject: UITextView = cell.viewWithTag(101) as! UITextView
                let labelName: UILabel = cell.viewWithTag(100) as! UILabel
                let labelComment: UILabel = cell.viewWithTag(103) as! UILabel
                
                if (item.isNew == 1) {
                    imageView.image = UIImage.init(named: "circle")
                } else {
                    imageView.image = UIImage.init(named: "circle-black")
                }
                
                if item.comment == "" || item.comment == "0" {
                    labelComment.isHidden = true
                } else {
                    labelComment.isHidden = false
                    labelComment.layer.cornerRadius = 8
                    labelComment.layer.borderWidth = 2.0;
                    let cnt = Int(item.comment) ?? 1
                    if cnt < 10 {
                        labelComment.textColor = Utils.hexStringToUIColor(hex: "0B84FF")
                    } else {
                        labelComment.textColor = Utils.hexStringToUIColor(hex: "30D158")
                    }
                    labelComment.layer.borderColor = labelComment.textColor.cgColor;
                }
                
                let subject = String(htmlEncodedString: item.subject)
                textSubject.text = subject
                labelName.text = item.name + " " + item.date
                labelComment.text = item.comment
                
                if item.read == 1 {
                    textSubject.textColor = .gray
                } else {
                    if #available(iOS 13.0, *) {
                        textSubject.textColor = .label
                    } else {
                        textSubject.textColor = .black
                    }
                }

                textSubject.font = bodyFont
                labelName.font = footnoteFont
                labelComment.font = footnoteFont
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: cellReItem, for: indexPath)
                // Fetches the appropriate meal for the data source layout.
                let imageView: UIImageView = cell.viewWithTag(310) as! UIImageView
                let textSubject: UITextView = cell.viewWithTag(301) as! UITextView
                let labelName: UILabel = cell.viewWithTag(300) as! UILabel
                let labelComment: UILabel = cell.viewWithTag(303) as! UILabel

                if (item.isNew == 1) {
                    imageView.image = UIImage.init(named: "circle")
                } else {
                    imageView.image = UIImage.init(named: "circle-black")
                }

                if item.comment == "" || item.comment == "0" {
                    labelComment.isHidden = true
                } else {
                    labelComment.isHidden = false
                    labelComment.layer.cornerRadius = 8
                    labelComment.layer.borderWidth = 2.0;
                    let cnt = Int(item.comment) ?? 1
                    if cnt < 10 {
                        labelComment.textColor = Utils.hexStringToUIColor(hex: "0B84FF")
                    } else {
                        labelComment.textColor = Utils.hexStringToUIColor(hex: "30D158")
                    }
                    labelComment.layer.borderColor = labelComment.textColor.cgColor;
                }
                
                let subject = String(htmlEncodedString: item.subject)
                textSubject.text = subject
                labelName.text = item.name + " " + item.date
                labelComment.text = item.comment

                if item.read == 1 {
                    textSubject.textColor = .gray
                } else {
                    if #available(iOS 13.0, *) {
                        textSubject.textColor = .label
                    } else {
                        textSubject.textColor = .black
                    }
                }
                
                textSubject.font = bodyFont
                labelName.font = footnoteFont
                labelComment.font = footnoteFont
            }
        }

        // 마지막 row 가 표시되면 다음 페이지를 load 한다.
        if indexPath.row  == (itemList.count - 1) {
            if !isEndPage {
                nPage = nPage + 1
                loadData()
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var item = itemList[indexPath.row]
        item.read = 1
        itemList[indexPath.row] = item
        
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        tableView.endUpdates()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "Article":
            guard let articleView = segue.destination as? ArticleView else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let indexPath = tableView.indexPathForSelectedRow else {
                fatalError("The selected cell is not being displayed by the table")
            }
            let item = self.itemList[indexPath.row]
            articleView.isPNotice = item.isPNotice
            if item.isPNotice == 0 {
                articleView.commId = commId
                articleView.boardId = boardId
            } else {
                articleView.commId = item.commId
                articleView.boardId = item.boardId
            }
            articleView.boardNo = item.boardNo
            articleView.boardType = boardType
            articleView.delegate = self;
            articleView.selectedRow = indexPath.row
        case "ArticleWrite":
            guard let articleWrite = segue.destination as? ArticleWrite else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            articleWrite.commId = commId
            articleWrite.boardId = self.boardId
            articleWrite.boardNo = ""
            articleWrite.strTitle = ""
            articleWrite.strContent = ""
            articleWrite.boardType = boardType
            articleWrite.delegate = self
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    //MARK: - HttpSessionRequestDelegate
    
    func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, didFinishLodingData data: Data) {
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
            let itemData = ItemData(result: str, type: boardType)
            self.mode = itemData!.mode
            if itemData!.itemList.count > 0 {
                if nPage == 1 {
                    itemList = itemData!.itemList
                } else {
                    itemList.append(contentsOf: itemData!.itemList)
                }
                DispatchQueue.main.sync {
                    self.tableView.reloadData()
                }
            } else {
                isEndPage = true
            }
        }
    }

    func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, withError error: Error?) {
        let msg = "권한이 없거나 로그인 정보를 확인하세요."
        let alert = UIAlertController(title: "오류", message: msg, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
        alert.addAction(confirm)
        DispatchQueue.main.sync {
            self.present(alert, animated: true, completion: nil)
        }
    }

    //MARK: - Private Methods

    func articleView(_ articleView: ArticleView, didDelete row: Int) {
        itemList.remove(at: row)
        tableView.reloadData()
    }

    //MARK: - Private Methods

    func articleWrite(_ articleWrite: ArticleWrite, didWrite sender: Any) {
        itemList.removeAll()
        nPage = 1
        tableView.reloadData()
        loadData()
    }
    
    //MARK: - LoginToServiceDelegate
    
    func loginToService(_ loginToService: LoginToService, loginWithSuccess result: String) {
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
        let httpSessionRequest = HttpSessionRequest()
        var resource = ""
        if boardType == GlobalConst.CAFE_TYPE_NORMAL {
            resource = "\(GlobalConst.CafeName)/cafe.php?sort=\(boardId)&sub_sort=&keyfield=&key_bs=&p1=\(commId)&p2=&p3=&page=\(nPage)"
        } else if boardType == GlobalConst.CAFE_TYPE_APPLY {
            let escBoardId = String(boardId.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed) ?? "")
            resource = "\(GlobalConst.ServerName)/bbs/board.php?bo_table=B691&sca=\(escBoardId)&page=\(nPage)"
        } else {
            resource = "\(GlobalConst.ServerName)/bbs/board.php?bo_table=\(boardId)&page=\(nPage)"
        }
        httpSessionRequest.delegate = self
        httpSessionRequest.requestWithParam(httpMethod: "GET", resource: resource, param: nil, referer: "")
    }
}
