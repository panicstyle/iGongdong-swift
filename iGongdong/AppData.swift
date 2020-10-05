//
//  ReceviceData.swift
//  iMooojigae
//
//  Created by dykim on 2020/08/19.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation
import UIKit

extension String {

    func fileName() -> String {
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }

    func fileExtension() -> String {
        return URL(fileURLWithPath: self).pathExtension
    }
    
    public subscript(aRange: NSRange) -> String {
      let start = index(startIndex, offsetBy: aRange.location)
      let end = index(start, offsetBy: aRange.length)
      return String(self[start..<end])
    }
    
    func removeSuffix() -> String {
        if self.count > 0 {
            let start = index(startIndex, offsetBy: 0)
            let end = index(start, offsetBy: self.count - 1)
            return String(self[start..<end])
        } else {
            return self
        }
    }
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}

//MARK: - SetStorage

@objc(SetStorage) class SetStorage: NSObject, NSCoding {
    var userId: NSString
    var userPwd: NSString
    var swPush: NSNumber
    var swNotice: NSNumber

    init(userId: String, userPwd: String, swPush: NSNumber, swNotice: NSNumber) {
        self.userId = userId as NSString
        self.userPwd = userPwd as NSString
        self.swPush = swPush
        self.swNotice = swNotice
        super.init()
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(userId, forKey: "id")
        aCoder.encode(userPwd, forKey: "pwd")
        aCoder.encode(swPush, forKey: "push")
        aCoder.encode(swPush, forKey: "push-notice")
    }

    required init?(coder aDecoder: NSCoder) {
        userId = aDecoder.decodeObject(forKey: "id") as! NSString
        userPwd = aDecoder.decodeObject(forKey: "pwd") as! NSString
        swPush = aDecoder.decodeObject(forKey: "push") as! NSNumber
        swNotice = aDecoder.decodeObject(forKey: "push-notice") as! NSNumber
        super.init()
    }
}

//MARK: - SetTokenStorage

@objc(SetTokenStorage) class SetTokenStorage: NSObject, NSCoding {
    var token: NSString

    init(token: String) {
        self.token = token as NSString
        super.init()
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(token, forKey: "token")
    }

    required init?(coder aDecoder: NSCoder) {
        token = aDecoder.decodeObject(forKey: "token") as! NSString
        super.init()
    }
}

//MARK: - MainData

struct  MenuData {
    var title: String = ""
    var code: String = ""
}

struct MainData {
    var mainList = [MenuData]()
    var menuList = [MenuData]()
    var recent: String = ""
    
    init?() {
        return nil
    }
    
    init?(result: String) {
        
        var menuData = MenuData()
        menuData.title = "소통과참여"
        menuData.code = "ing"
        self.mainList.append(menuData)
        
        menuData = MenuData()
        menuData.title = "교육신청"
        menuData.code = "edu"
        self.mainList.append(menuData)

        print("result=[\(result)]")
        let selectStr = Utils.findStringRegex(result, regex: "(<select name=\"select_community).*?(</select>)")
        let matchs = Utils.matchStringRegex(selectStr, regex: "(<option value=).*?(</option>)")
        
        for match in matchs {
            let matchstr = selectStr[match.range]
            print("-----\n\(matchstr)\n-----")
            
            let code = Utils.findStringRegex(matchstr, regex: "(?<=value=\\\").*?(?=\\\")")
            let title = Utils.replaceOnlyHtmlTag(matchstr)
            
            if code == "" {
                continue
            }
            
            var menuData = MenuData()
            menuData.title = title
            menuData.code = code
            self.menuList.append(menuData)
        }
    }
}

//MARK: - BoardData

struct  Board {
    var title: String = ""
    var type: Int = 0
    var boardId: String = ""
    var isNew = 0
    var isCal = 0
    
    init?(title: String, boardId: String, type: Int, isNew: Int, isCal: Int) {
        self.title = title
        self.boardId = boardId
        self.type = type
        self.isNew = isNew
        self.isCal = isCal
    }
}

struct BoardData {
    var boardList = [Board]()
    var recent: String = ""
    var new: String = ""

    init?() {
        return nil
    }
    
    init?(boardList: [Board]) {
        self.boardList = boardList
    }
    
    init?(result: String) {
        var selectStr = Utils.findStringRegex(result, regex: "(<div id=\"cafe_sub_menu_box2).*?(/div>)")
        selectStr = Utils.replaceStringRegex(selectStr, regex: "\r\n", replace: "\n")
        let matchs = Utils.matchStringRegex(selectStr, regex: "(<li id=\"cafe_sub_menu).*?(</li>)")
        for match in matchs {
            let matchstr = selectStr[match.range]
            print("-----\n\(matchstr)\n-----")
            
            var type = 0
            if Utils.numberOfMatches(matchstr, regex: "cafe_sub_menu_line") > 0 {
                continue
            } else if Utils.numberOfMatches(matchstr, regex: "cafe_sub_menu_title") > 0 {
                type = GlobalConst.CAFE_TYPE_TITLE
            } else if Utils.numberOfMatches(matchstr, regex: "cafe_sub_menu_link") > 0 {
                continue
            } else {
                type = GlobalConst.CAFE_TYPE_NORMAL
            }

            let link = Utils.findStringRegex(matchstr, regex: "(?<=<a href=\\\").*?(?=\\\")")
            let boardId = Utils.findStringRegex(link, regex: "(?<=&sort=).*?(?=$)")
                        
            let title = Utils.replaceOnlyHtmlTag(matchstr)
            print("title=\(title)")
            var isNew = 0
            if Utils.numberOfMatches(matchstr, regex: "images/new_s.gif") > 0 {
                isNew = 1
            }

            var isCal = 0
            if Utils.numberOfMatches(link, regex: "sort=cal") > 0 {
                isCal = 1
            }

            let boardData = Board.init(title: title, boardId: boardId, type: type, isNew: isNew, isCal: isCal)
            self.boardList.append(boardData!)
        }
    }
}
