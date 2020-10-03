//
//  ReceviceData.swift
//  iMooojigae
//
//  Created by dykim on 2020/08/19.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation

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

//MARK: - ItemsData

struct  Item {
    var isPNotice: Int = 0
    var isNotice: Int = 0
    var commId: String = ""
    var boardId: String = ""
    var boardNo: String = ""
    var isNew: Int = 0
    var isRe: Int = 0
    var subject: String = ""
    var id: String = ""
    var name: String = ""
    var comment: String = ""
    var hit: String = ""
    var date: String = ""
    var read: Int = 0
}

struct ItemData {
    var itemList = [Item]()
    var error: String = ""

    init?() {
        return nil
    }
    
    init?(result: String) {
        var selectStr = Utils.findStringRegex(result, regex: "(<table cellSpacing=).*?(/table>)")
        selectStr = Utils.replaceStringRegex(selectStr, regex: "\r\n", replace: "\n")
        let matchs = Utils.matchStringRegex(selectStr, regex: "(id=\\\"board_list_line\\\").*?(</tr>)")
        let db = DBInterface()
        for match in matchs {
            let matchstr = selectStr[match.range]
            print("-----\n\(matchstr)\n-----")
            
            var isPNotice = 0
            if Utils.numberOfMatches(matchstr, regex: "\\[법인공지\\]") > 0 {
                isPNotice = 1
            }
            
            var isNotice = 0
            if Utils.numberOfMatches(matchstr, regex: "\\[공지\\]") > 0 {
                isNotice = 1
            }
            
            var subject = ""
            subject = Utils.findStringRegex(matchstr, regex: "(<td class=\"subject).*?(</a>)")
            subject = Utils.replaceOnlyHtmlTag(subject)
            
            let link = Utils.findStringRegex(matchstr, regex: "(?<=<a href=\\\").*?(?=\\\")")
            var commId = ""
            var boardId = ""
            var boardNo = ""
            if isPNotice > 0 {
                boardId = Utils.findStringRegex(link, regex: "(?<=bo_table=).*?(?=&)")
                boardNo = Utils.findStringRegex(link, regex: "(?<=&wr_id=).*?(?=$)")
            } else {
                commId = Utils.findStringRegex(link, regex: "(?<=p1=).*?(?=&)")
                boardId = Utils.findStringRegex(link, regex: "(?<=sort=).*?(?=&)")
                boardNo = Utils.findStringRegex(link, regex: "(?<=&number=).*?(?=&)")
            }
            
            var comment = Utils.findStringRegex(matchstr, regex: "(<td class=\"subject).*?(</td>)")
            comment = Utils.findStringRegex(comment, regex: "(</a>).*?(</td>)")
            comment = Utils.findStringRegex(comment, regex: "(?<=\\[).*?(?=\\])")
            
            var isNew = 0
            if Utils.numberOfMatches(matchstr, regex: "img src=images/new_s\\.gif") > 0 {
                isNew = 1
            }
            
            var id = ""
            var name = ""
            if isPNotice > 0 {
                id = "법인공지"
                name = "법인공지"
            } else if isNotice > 0 {
                id = "공지"
                name = "공지"
            } else {
                id = Utils.findStringRegex(matchstr, regex: "(?<=javascript:ui\\(').*?(?=')")
                name = Utils.findStringRegex(matchstr, regex: "(<!-- 사용자 이름 표시 부분-->).*?(</div>)")
                name = Utils.replaceOnlyHtmlTag(name)
            }
            
            var date = Utils.findStringRegex(matchstr, regex: "(<td class=\"date).*?(</td>)")
            date = Utils.replaceOnlyHtmlTag(date)
            
            let hit = Utils.findStringRegex(matchstr, regex: "(<td class=\"hit).*?(</td>)")
            
            var isRe = 0
            if Utils.numberOfMatches(matchstr, regex: "images/reply\\.gif") > 0 {
                isRe = 1
            }
            
            var read = 0
            if db.search(boardId: boardId, boardNo: boardNo) > 0 {
                read = 1
            }
            
            var item = Item()
            item.isPNotice = isPNotice
            item.isNotice = isNotice
            item.commId = commId
            item.boardId = boardId
            item.boardNo = boardNo
            item.isNew = isNew
            item.isRe = isRe
            item.subject = subject
            item.id = id
            item.name = name
            item.comment = comment
            item.hit = hit
            item.date = date
            item.read = read
            self.itemList.append(item)
        }
    }
}

//MARK: - RecentItemsData

struct  RecentItem {
    var boardNo: String = ""
    var isNew: Int = 0
    var isUpdated: Int = 0
    var boardId: String = ""
    var boardName: String = ""
    var subject: String = ""
    var name: String = ""
    var comment: String = ""
    var hit: String = ""
    var date: String = ""
    var read: Int = 0
}

struct RecentItemData {
    var itemList = [RecentItem]()

    init?() {
        return nil
    }
    
    init?(json: [String: Any]) {
        // The name must not be empty
        guard !json.isEmpty else {
            return nil
        }

        // Initialization should fail if there is no name or if the rating is negative.
        if json.isEmpty  {
            return nil
        }
        guard
            let items = json["item"] as? [[String: Any]]
        else {
            return nil
        }
        let db = DBInterface()
        for itemIndex in items {
            var item = RecentItem()
            item.boardNo = itemIndex["boardNo"] as! String
            let recentArticle = itemIndex["recentArticle"] as! String
            if recentArticle == "Y" {
                item.isNew = 1
            }
            let updatedArticle = itemIndex["updatedArticle"] as! String
            if updatedArticle == "Y" {
                item.isUpdated = 1
            }
            item.boardId = itemIndex["boardId"] as! String
            item.boardName = itemIndex["boardName"] as! String
            item.subject = itemIndex["boardTitle"] as! String
            item.name = itemIndex["userNick"] as! String
            item.comment = itemIndex["boardMemo_cnt"] as! String
            item.hit = itemIndex["boardRead_cnt"] as! String
            item.date = itemIndex["boardRegister_dt"] as! String
            
            item.read = 0
            if db.search(boardId: item.boardId, boardNo: item.boardNo) > 0 {
                item.read = 1
            }
            self.itemList.append(item)
        }
    }
}

struct  CommentItem {
    var isRe: String = ""
    var no: String = ""
    var name: String = ""
    var date: String = ""
    var comment: String = ""
}

struct  ImageItem {
    var fileName: String = ""
    var link: String = ""
}

struct  AttachItem {
    var fileName: String = ""
    var fileSeq: String = ""
    var link: String = ""
}

struct ArticleData {
    var subject: String = ""
    var name: String = ""
    var date: String = ""
    var hit: String = ""
    var content: String = ""
    var profile: String = ""
    var commentList = [CommentItem]()
    var imageList = [ImageItem]()
    var attachList = [AttachItem]()

    init?() {
        return nil
    }
    
    init?(json: [String: Any]) {
        // The name must not be empty
        guard !json.isEmpty else {
            return nil
        }

        // Initialization should fail if there is no name or if the rating is negative.
        if json.isEmpty  {
            return nil
        }
        guard
            let boardTitle = json["boardTitle"] as? String,
            let userNick = json["userNick"] as? String,
            let boardRegister_dt = json["boardRegister_dt"] as? String,
            let boardRead_cnt = json["boardRead_cnt"] as? String,
            let boardContent = json["boardContent"] as? String,
            let userComment = json["userComment"] as? String,
            let memo = json["memo"] as? [[String: Any]],
            let image = json["image"] as? [[String: Any]],
            let attachment = json["attachment"] as? [[String: Any]]
        else {
            return nil
        }
        self.subject = boardTitle
        self.name = userNick
        self.date = boardRegister_dt
        self.hit = boardRead_cnt
        self.content = boardContent
        self.profile = userComment
        for itemIndex in memo {
            var item = CommentItem()
            item.isRe = itemIndex["memoDep"] as! String
            item.no = itemIndex["memoSeq"] as! String
            item.name = itemIndex["userNick"] as! String
            item.date = itemIndex["memoRegister_dt"] as! String
            item.comment = itemIndex["memoContent"] as! String
            self.commentList.append(item)
        }
        for itemIndex in image {
            var item = ImageItem()
            item.fileName = itemIndex["fileName"] as! String
            item.link = itemIndex["link"] as! String
            self.imageList.append(item)
        }
        for itemIndex in attachment {
            var item = AttachItem()
            item.fileName = itemIndex["fileName"] as! String
            item.fileSeq = itemIndex["fileSeq"] as! String
            item.link = itemIndex["link"] as! String
            self.attachList.append(item)
        }
    }
}
