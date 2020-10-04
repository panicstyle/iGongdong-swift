//
//  ItemData.swift
//  iGongdong
//
//  Created by dykim on 2020/10/04.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation

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
    var picLink: String = ""
    var read: Int = 0
}

struct ItemData {
    var itemList = [Item]()
    var mode: Int = 0

    init?() {
        return nil
    }
    
    init?(result: String, type: Int) {
        switch type {
        case GlobalConst.CAFE_TYPE_NOTICE:
            self.getNotice(result: result)
        case GlobalConst.CAFE_TYPE_CENTER, GlobalConst.CAFE_TYPE_APPLY:
            self.getCenter(result: result, type: type)
        case GlobalConst.CAFE_TYPE_ING:
            self.getIng(result: result)
        default:
            if Utils.numberOfMatches(result, regex: "<tr  id=\"board_list_title") > 0 {
                self.mode = 0
                self.getNormal(result: result)
            } else {
                self.mode = 1
                self.getPicture(result: result)
            }
        }
    }
    
    //MARK: - getNotice
    
    mutating func getNotice(result: String) {
        let selectStr = Utils.replaceStringRegex(result, regex: "\r\n", replace: "\n")
        let matchs = Utils.matchStringRegex(selectStr, regex: "(<tr class=).*?(</tr>)")
        let db = DBInterface()
        for match in matchs {
            let matchstr = selectStr[match.range]
            print("-----\n\(matchstr)\n-----")
            
            let isPNotice = 0
            var isNotice = 0
            if Utils.numberOfMatches(matchstr, regex: "<tr class=\\\"bo_notice") > 0 {
                isNotice = 1
            }
            
            let matchstr2 = Utils.replaceStringRegex(matchstr, regex: "(<!--).*?(-->)", replace: "")
            var subject = Utils.findStringRegex(matchstr2, regex: "(<td class=\\\"td_subject).*?(</a>)")
            let link = Utils.findStringRegex(subject, regex: "(?<=<a href=\\\").*?(?=\\\")")
            let commId = ""
            let boardId = Utils.findStringRegex(link, regex: "(?<=bo_table=).*?(?=&)")
            let boardNo = Utils.findStringRegex(link, regex: "(?<=wr_id=).*?(?=&)")
            let comment = Utils.findStringRegex(subject, regex: "(?<=<span class=\\\"cnt_cmt\\\">).*?(?=</span>)")
            
            subject = Utils.replaceStringRegex(subject, regex: "(<span class=\\\"sound).*?(개</span>)", replace: "")
            subject = Utils.replaceOnlyHtmlTag(subject)

            let isNew = 0
            
            var id = ""
            var name = ""
            if isNotice > 0 {
                id = "공지"
                name = "공지"
            }
            
            let date = Utils.findStringRegex(matchstr, regex: "(?<=<td class=\\\"td_date\\\">).*?(?=</td>)")
            let hit = Utils.findStringRegex(matchstr, regex: "(?<=<td class=\\\"td_num\\\">)[0-9.]+(?=</td>)")
            
            let isRe = 0
            
            var read = 0
            if db.search(commId: "center", boardId: boardId, boardNo: boardNo) > 0 {
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

    //MARK: - getCenter

    mutating func getCenter(result: String, type: Int) {
        let selectStr = Utils.replaceStringRegex(result, regex: "\r\n", replace: "\n")
        let matchs = Utils.matchStringRegex(selectStr, regex: "(<tr class=).*?(</tr>)")
        let db = DBInterface()
        for match in matchs {
            let matchstr = selectStr[match.range]
            print("-----\n\(matchstr)\n-----")
            
            let isPNotice = 0
            var isNotice = 0
            if Utils.numberOfMatches(matchstr, regex: "<tr class=\\\"bo_notice") > 0 {
                isNotice = 1
            }
            
            var matchstr2 = Utils.replaceStringRegex(matchstr, regex: "(<!--).*?(-->)", replace: "")
            if type == GlobalConst.CAFE_TYPE_APPLY {
                matchstr2 = Utils.replaceStringRegex(matchstr, regex: "(<a href=).*?(class=\\\"bo_cate_link\\\">.*?</a>)", replace: "")
            }
            var subject = Utils.findStringRegex(matchstr2, regex: "(<td class=\\\"td_subject).*?(</a>)")
            let link = Utils.findStringRegex(subject, regex: "(?<=<a href=\\\").*?(?=\\\")")
            let commId = ""
            let boardId = Utils.findStringRegex(link, regex: "(?<=bo_table=).*?(?=&)")
            let boardNo = Utils.findStringRegex(link, regex: "(?<=wr_id=).*?(?=&)")
            let comment = Utils.findStringRegex(subject, regex: "(?<=<span class=\\\"cnt_cmt\\\">).*?(?=</span>)")
            
            var status = ""
            if type == GlobalConst.CAFE_TYPE_APPLY {
                if Utils.numberOfMatches(matchstr2, regex: "<div class=\\\"edu_con\\\">") > 0 {
                    status = "[접수중]"
                } else {
                    status = "[신청마감]"
                }
            } else {
                if Utils.numberOfMatches(matchstr2, regex: "recruitment2.png") > 0 || Utils.numberOfMatches(matchstr2, regex: "recruitment.gif") > 0 {
                    status = "[모집중]"
                } else if Utils.numberOfMatches(matchstr2, regex: "rcrit_end.gif") > 0 {
                    status = "[완료]"
                } else {
                    status = ""
                }
            }
            
            subject = Utils.replaceStringRegex(subject, regex: "(<span class=\\\"sound).*?(개</span>)", replace: "")
            subject = Utils.replaceOnlyHtmlTag(subject)
            if type == GlobalConst.CAFE_TYPE_APPLY {
                subject = "\(status) \(subject)"
            } else {
                if status.count > 0 {
                    subject = "\(status) \(subject)"
                }
            }
            let isNew = 0
            
            let id = ""
            var name = ""
            var date = ""
            var hit = ""
            if type == GlobalConst.CAFE_TYPE_APPLY {
                name = Utils.findStringRegex(matchstr, regex: "(?<=<td class=\\\"td_name sv_use\\\">).*?(?=</td>)")
                name = Utils.replaceOnlyHtmlTag(name)
                date = Utils.findStringRegex(matchstr, regex: "(?<=<td class=\\\"td_name \\\">).*?(?=</td>)")
                hit = Utils.findStringRegex(matchstr, regex: "(?<=<td class=\\\"td_num\\\">).*?(?=</td>)")
            } else {
                name = Utils.findStringRegex(matchstr, regex: "(?<=<td class=\\\"td_name sv_use\\\">).*?(?=</td>)")
                name = Utils.replaceOnlyHtmlTag(name)
                date = Utils.findStringRegex(matchstr, regex: "(?<=<td class=\\\"td_date\\\">).*?(?=</td>)")
                hit = Utils.findStringRegex(matchstr, regex: "(?<=<td class=\\\"td_num\\\">).*?(?=</td>)")
            }
            
            let isRe = 0
            
            var read = 0
            if db.search(commId: "center", boardId: boardId, boardNo: boardNo) > 0 {
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

    //MARK: - getIng

    mutating func getIng(result: String) {
        let selectStr = Utils.replaceStringRegex(result, regex: "\r\n", replace: "\n")
        let matchs = Utils.matchStringRegex(selectStr, regex: "(<ul class=\\\"gall_con).*?(</ul>)")
        let db = DBInterface()
        for match in matchs {
            let matchstr = selectStr[match.range]
            print("-----\n\(matchstr)\n-----")
            
            let isPNotice = 0
            let isNotice = 0
            
            let picLink = Utils.findStringRegex(matchstr, regex: "(?<=<img src=\\\")(.|\\n)*?(?=\\\")")
            
            var subject = Utils.findStringRegex(matchstr, regex: "(<li class=\\\"gall_text_href).*?(</a>)")
            let boardId = Utils.findStringRegex(subject, regex: "(?<=bo_table=).*?(?=&)")
            let boardNo = Utils.findStringRegex(subject, regex: "(?<=wr_id=).*?(?=[&|\\\"])")
            let comment = Utils.findStringRegex(subject, regex: "(?<=<span class=\\\"cnt_cmt\\\">).*?(?=</span>)")
            let commId = ""
            
            subject = Utils.replaceStringRegex(subject, regex: "(<span class=\\\"sound).*?(개</span>)", replace: "")
            subject = Utils.replaceOnlyHtmlTag(subject)

            let isNew = 0
            
            let id = ""
            let name = ""
            
            let date = ""
            let hit = ""
            
            let isRe = 0
            
            var read = 0
            if db.search(commId: "center", boardId: boardId, boardNo: boardNo) > 0 {
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
            item.picLink = picLink
            item.read = read
            self.itemList.append(item)
        }
    }

    //MARK: - getNormal

    mutating func getNormal(result: String) {
        let selectStr = Utils.replaceStringRegex(result, regex: "\r\n", replace: "\n")
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
            if db.search(commId: commId, boardId: boardId, boardNo: boardNo) > 0 {
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
    
    //MARK: - getPicture

    mutating func getPicture(result: String) {
        let aResult = result as NSString
        let matchs = aResult.components(separatedBy: "<td width=\"25%\" valign=top>")
        let db = DBInterface()
        var i = 0
        for matchstr in matchs {
            print("-----\n\(matchstr)\n-----")
            i = i + 1
            if i == 1 {
                continue
            }
            let isPNotice = 0
            let isNotice = 0
            
            var subject = ""
            subject = Utils.findStringRegex(matchstr, regex: "(<span style=\\\"font-size:9pt;\\\">)(.|\\n)*?(</span>)")
            subject = Utils.replaceOnlyHtmlTag(subject)
            
            let link = Utils.findStringRegex(matchstr, regex: "(?<=<a href=\\\")(.|\\n)*?(?=\\\")")
            let commId = Utils.findStringRegex(link, regex: "(?<=&p1=).*?(?=&)")
            let boardId = Utils.findStringRegex(link, regex: "(?<=&sort=).*?(?=&)")
            let boardNo = Utils.findStringRegex(link, regex: "(?<=&number=).*?(?=&)")
            
            let comment = Utils.findStringRegex(matchstr, regex: "(?<=<b>\\[)(.|\\n)*?(?=\\]</b>)")
            
            let isNew = 0
            
            let id = ""
            var name = Utils.findStringRegex(matchstr, regex: "(?<=</span></a> \\[)(.|\\n)*?(?=\\]<span)")
            if name == "" {
                name = Utils.findStringRegex(matchstr, regex: "(?<=</span>\\[)(.|\\n)*?(?=\\]<span)")
            }
            
            let date = ""
            var hit = Utils.findStringRegex(matchstr, regex: "(?<=<font face=\"Tahoma\"><b>\\[)(.|\\n)*?(?=\\]</b>)")
            hit = Utils.replaceOnlyHtmlTag(hit)
            
            let picLink = Utils.findStringRegex(matchstr, regex: "(?<=background=\\\")(.|\\n)*?(?=\\\")")
            
            let isRe = 0
            
            var read = 0
            if db.search(commId: commId, boardId: boardId, boardNo: boardNo) > 0 {
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
            item.picLink = picLink
            item.read = read
            self.itemList.append(item)
        }
    }
}

