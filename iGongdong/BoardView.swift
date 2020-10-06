//
//  BoardView.swift
//  iMoojigae
//
//  Created by dykim on 2020/08/27.
//  Copyright © 2020 dykim. All rights reserved.
//

import UIKit
import os.log
import WebKit
import GoogleMobileAds

class BoardView : UIViewController, UITableViewDelegate, UITableViewDataSource, HttpSessionRequestDelegate {

    //MARK: Properties

    @IBOutlet var tableView : UITableView!
    @IBOutlet var bannerView: GADBannerView!
    var commTitle: String = ""
    var commId: String = ""
    var menuType = GlobalConst.CENTER
    
    var boardData = BoardData()
    var config: WKWebViewConfiguration?

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.contentSizeCategoryDidChangeNotification),
                                               name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        self.title = commTitle
        
        // GoogleMobileAds
        self.bannerView.adUnitID = GlobalConst.AdUnitID
        self.bannerView.rootViewController = self
        self.bannerView.load(GADRequest())

        // Load the data.
        if menuType == GlobalConst.CENTER {
            loadCenterData()
        } else {
            loadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func contentSizeCategoryDidChangeNotification() {
        self.tableView.reloadData()
    }
    
    deinit {
        // perform the deinitialization
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return boardData?.boardList.count ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let titleFont = UIFont.preferredFont(forTextStyle: .body)
        let board = self.boardData?.boardList[indexPath.row]
        var cellHeight: CGFloat = 0.0
        if board!.type == GlobalConst.CAFE_TYPE_TITLE {
            cellHeight = 25.0 - 17.0 + titleFont.pointSize
        } else {
            cellHeight = 44.0 - 17.0 + titleFont.pointSize
        }
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIBoard = "Board"
        let cellICal = "Cal"
        let cellITitle = "Title"

        let cell: UITableViewCell
        let board = boardData?.boardList[indexPath.row]
        if board!.type == GlobalConst.CAFE_TYPE_TITLE {
            cell = tableView.dequeueReusableCell(withIdentifier: cellITitle, for: indexPath)

            cell.textLabel?.text = board?.title
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        } else {
            if board!.isCal == 1 {
                cell = tableView.dequeueReusableCell(withIdentifier: cellICal, for: indexPath)
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: cellIBoard, for: indexPath)
            }
            if board!.isNew == 0 {
                cell.imageView?.image = UIImage.init(named: "circle-blank")
            } else {
                cell.imageView?.image = UIImage.init(named: "circle")
            }
            cell.textLabel?.text = board?.title
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        }
        
        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    //MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "Board":
            guard let itemView = segue.destination as? ItemView else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let indexPath = tableView.indexPathForSelectedRow else {
                fatalError("The selected cell is not being displayed by the table")
            }
            let board = self.boardData?.boardList[indexPath.row]
            itemView.commId = commId
            itemView.boardId = board!.boardId
            itemView.boardTitle = board!.title
            itemView.boardType = board!.type
        case "Cal":
            guard let calView = segue.destination as? CalView else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let indexPath = tableView.indexPathForSelectedRow else {
                fatalError("The selected cell is not being displayed by the table")
            }
            let board = self.boardData?.boardList[indexPath.row]
            calView.boardTitle = board!.title
            calView.commId = commId
            calView.boardId = board!.boardId
            calView.config = config
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    //MARK: - HttpSessionRequestDelegate
    
    func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, didFinishLodingData data: Data) {
        let str = String(data: data, encoding: .utf8) ?? ""
        boardData = BoardData(result: str)
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
            
            self.tableView.reloadData()
        }
    }

    func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, withError error: Error?) {
        print("httpSessionRequest Error")
    }

    //MARK: Private Methods
    
    private func loadData() {
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.requestWithParam(httpMethod: "GET", resource: "\(GlobalConst.CafeName)/cafe.php?code=\(commId)", param: nil, referer: "")
    }
    
    private func loadCenterData() {
        var boardList = [Board]()
        if commId == "ing" {
            var board = Board.init(title: "공지사항", boardId: "B211", type: GlobalConst.CAFE_TYPE_NOTICE, isNew: 0, isCal: 0)
            boardList.append(board!)
            board = Board.init(title: "공동육아ing", boardId: "B231", type: GlobalConst.CAFE_TYPE_ING, isNew: 0, isCal: 0)
            boardList.append(board!)
            board = Board.init(title: "무엇이든 물어보세요", boardId: "B271", type: GlobalConst.CAFE_TYPE_CENTER, isNew: 0, isCal: 0)
            boardList.append(board!)
            board = Board.init(title: "터전 소식", boardId: "B301", type: GlobalConst.CAFE_TYPE_CENTER, isNew: 0, isCal: 0)
            boardList.append(board!)
            board = Board.init(title: "교사모집/교사구직", boardId: "B251", type: GlobalConst.CAFE_TYPE_CENTER, isNew: 0, isCal: 0)
            boardList.append(board!)
            board = Board.init(title: "조합원모집", boardId: "B261", type: GlobalConst.CAFE_TYPE_CENTER, isNew: 0, isCal: 0)
            boardList.append(board!)
            board = Board.init(title: "알리고싶어요", boardId: "B281", type: GlobalConst.CAFE_TYPE_CENTER, isNew: 0, isCal: 0)
            boardList.append(board!)
        } else {
            var board = Board.init(title: "교사교육", boardId: "교사교육", type: GlobalConst.CAFE_TYPE_APPLY, isNew: 0, isCal: 0)
            boardList.append(board!)
            board = Board.init(title: "부모교육", boardId: "부모교육", type: GlobalConst.CAFE_TYPE_APPLY, isNew: 0, isCal: 0)
            boardList.append(board!)
            board = Board.init(title: "운영진교육", boardId: "운영진교육", type: GlobalConst.CAFE_TYPE_APPLY, isNew: 0, isCal: 0)
            boardList.append(board!)
            board = Board.init(title: "시민교육", boardId: "시민교육", type: GlobalConst.CAFE_TYPE_APPLY, isNew: 0, isCal: 0)
            boardList.append(board!)
        }
        boardData = BoardData.init(boardList: boardList)
        self.tableView.reloadData()
    }
}
