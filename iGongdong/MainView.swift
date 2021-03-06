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

class MainView : CommonBannerView, UITableViewDelegate, UITableViewDataSource, SetViewDelegate {
    
    //MARK: Properties
    
    @IBOutlet var tableView : UITableView!
    
    var mainData = MainData()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "공동육아와 공동체교육"
        
        let db = DBInterface()
        db.delete()
        
        let loginToService = LoginToService()
        loginToService.delegate = self
        loginToService.Login()
    }

    @objc override func contentSizeCategoryDidChangeNotification() {
        self.tableView.reloadData()
    }

    //MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return mainData?.mainList.count ?? 0
        default:
            return mainData?.menuList.count ?? 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return "공동육아와 공동체교육"
        default:
            return "내 커뮤니티"
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let titleFont = UIFont.preferredFont(forTextStyle: .body)
        let cellHeight: CGFloat = 30.0 - 17.0 + titleFont.pointSize
        return cellHeight
    }
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let titleFont = UIFont.preferredFont(forTextStyle: .body)
        let cellHeight: CGFloat = 44.0 - 17.0 + titleFont.pointSize
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIMenu = "Menu"

        // Fetches the appropriate meal for the data source layout.
        var cell: UITableViewCell
        cell = tableView.dequeueReusableCell(withIdentifier: cellIMenu, for: indexPath)

        switch indexPath.section {
        case 0:
            let menuData = mainData?.mainList[indexPath.row]
            cell.textLabel?.text = menuData?.title
        default:
            let menuData = mainData?.menuList[indexPath.row]
            cell.textLabel?.text = menuData?.title
        }
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        
        return cell
    }
    
    //MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "SetView":
            guard let setView = segue.destination as? SetView else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            setView.delegate = self
        case "Menu":
            guard let boardView = segue.destination as? BoardView else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let indexPath = tableView.indexPathForSelectedRow else {
                fatalError("The selected cell is not being displayed by the table")
            }
            let sec = indexPath.section
            let row = indexPath.row
            if sec == 0 {
                let menuData = mainData?.mainList[row]
                boardView.commTitle = menuData!.title
                boardView.commId = menuData!.code
                boardView.menuType = GlobalConst.CENTER
            } else {
                let menuData = mainData?.menuList[row]
                boardView.commTitle = menuData!.title
                boardView.commId = menuData!.code
                boardView.menuType = GlobalConst.COMMUNITY
            }
        case "About":
            guard segue.destination is AboutView else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    //MARK: - HttpSessionRequestDelegate
    
    override func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, didFinishLodingData data: Data) {
        let str = String(data: data, encoding: .utf8) ?? ""
        print("str = \(str.count)")
        mainData = MainData(result: str)
        print(mainData?.recent as Any)
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

    //MARK: - LoginToServiceDelegate
    
    override func loginToService(_ loginToService: LoginToService, loginWithSuccess result: String) {
        print("LoginToService Success")
        loadData()
    }
    
    override func loginToService(_ loginToService: LoginToService, loginWithFail result: String) {
        print("LoginToService fail")
        loadData()
    }
    
    //MARK: - SetViewDelegate

    func setView(_ setView: SetView, didSaved sender: Any) {
        print("setView success")
        loadData()
    }
    
    //MARK: - User Functions
    
    private func loadData() {
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.requestWithParam(httpMethod: "GET", resource: GlobalConst.ServerName + "/", param: nil, referer: "")
    }
}

