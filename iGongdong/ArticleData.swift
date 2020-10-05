//
//  File.swift
//  iGongdong
//
//  Created by dykim on 2020/10/05.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation
import UIKit

//MARK: - CommentItem

struct  CommentItem {
    var isRe: Int = 0
    var no: String = ""
    var name: String = ""
    var date: String = ""
    var comment: String = ""
    var deleteLink: String = ""
}

//MARK: - ImageItem

struct  ImageItem {
    var fileName: String = ""
    var link: String = ""
}

//MARK: - AttachItem

struct  AttachItem {
    var key: String = ""
    var value: String = ""
}

//MARK: - ArticleData

struct ArticleData {
    var subject: String = ""
    var name: String = ""
    var date: String = ""
    var hit: String = ""
    var content: String = ""
    var profile: String = ""
    var commentList = [CommentItem]()
//    var imageList = [ImageItem]()
    var attachList = [AttachItem]()
    var imageStr: String = ""
    var attachStr: String = ""

    init?() {
        return nil
    }
    
    init?(result: String, type: Int, isPNotice: Int) {
        switch type {
        case GlobalConst.CAFE_TYPE_NORMAL:
            if isPNotice == 0 {
                parseNormal(result: result)
            } else {
                parsePNotice(result: result)
            }
        default:
            parsePNotice(result: result)
        }
    }
    
    mutating func parseNormal(result: String) {
        let result2 = Utils.replaceStringRegex(result, regex: "\r\n", replace: "\n")
        
        var subject = Utils.findStringRegex(result2, regex: "(?<=<div style=\"margin-right:10; margin-left:10;\"><B>).*?(?=</div>)")
        subject = Utils.replaceOnlyHtmlTag(subject)
        
        var name = Utils.findStringRegex(result2, regex: "(<div align=\"right\"><b>작성자 : <a).*?(</a>)")
        name = Utils.replaceOnlyHtmlTag(name)
        
        var date = Utils.findStringRegex(result2, regex: "(입력 : <span title=).*?(</span>)")
        date = Utils.replaceOnlyHtmlTag(date)
        date = Utils.replaceStringRegex(date, regex: "입력 : ", replace: "")
        date = Utils.replaceStringRegex(date, regex: "(\\().*?(\\))", replace: "")
        
        let hit = Utils.findStringRegex(result2, regex: "(?<=</span>, &nbsp;조회 : ).*?(?=</div>)")
        
        var content = Utils.findStringRegex(result2, regex: "(?<=<!---- contents start 본문 표시 부분 DJ ---->).*?(?=<!---- contents end ---->)")
        
        var attach = Utils.findStringRegex(result2, regex: "(?<=<!-- view image file -->).*?(?=<tr><td  height=1  ></td></tr>)")
        if attach.count < 140 {
            attach = ""
        }
        attach = Utils.replaceStringRegex(attach, regex: "height=30", replace: "")
        attach = Utils.replaceStringRegex(attach, regex: "(style=\\\").*?(\\\")", replace: "")

        var image = Utils.findStringRegex(result2, regex: "(<p align=center><img onload=\\\"resizeImage2).*?(</td>)")
        if image.count > 0 {
            image = Utils.replaceStringRegex(image, regex: "</td>", replace: "")
        }
        
        content = Utils.replaceStringRegex(content, regex: "onload=\\\"resizeImage2\\(this\\)\\\"", replace: "")
        image = Utils.replaceStringRegex(image, regex: "onload=\\\"resizeImage2\\(this\\)\\\"", replace: "")
        
        content = Utils.replaceStringRegex(content, regex: "<img ", replace: "<img width=300 ")
        image = Utils.replaceStringRegex(image, regex: "<img ", replace: "<img width=300 ")

        self.subject = subject
        self.name = name
        self.date = date
        self.hit = hit
        self.content = content
        self.attachStr = attach
        self.imageStr = image
        
        let comments = Utils.findStringRegex(result2, regex: "(<!-- 댓글 시작 -->).*?(<!-- 댓글 끝 -->)")
        let matchs = comments.components(separatedBy: "<tr><td bgcolor=\"#DDDDDD\" height=\"1\" ></td></tr>")
        for i in 0 ..< matchs.count {
            if i == 0 {
                continue
            }
            let matchstr = matchs[i]
            print("-----\n\(matchstr)\n-----")
            
            var isRe = 0
            if Utils.numberOfMatches(matchstr, regex: "<img src=\\\"images/reply.gif\\\" border=\\\"0\\\" vspace=\\\"0\\\" hspace=\\\"2\\\" />") > 0 {
                isRe = 1
            }
            
            let no = Utils.findStringRegex(matchstr, regex: "(?<=&number=).*?(?=')")
            
            var name = Utils.findStringRegex(matchstr, regex: "(<font color=\"black\"><a href=\"javascript:ui).*?(</a>)")
            name = Utils.replaceOnlyHtmlTag(name)
            
            var date = Utils.findStringRegex(matchstr, regex: "(<span title=\").*?(</span>)")
            date = Utils.replaceOnlyHtmlTag(date)
            date = Utils.replaceStringRegex(date, regex: "/ ", replace: "")
            
            var comment = ""
            if isRe == 0 {
                comment = Utils.findStringRegex(matchstr, regex: "(?<=<td style=\"padding:7pt;\">).*?(?=<div id=\"reply_)")
            } else {
                comment = Utils.findStringRegex(matchstr, regex: "(?<=<td colspan=\"2\">).*?(?=</td>)")
            }
            
            var commentItem = CommentItem()
            commentItem.isRe = isRe
            commentItem.no = no
            commentItem.name = name
            commentItem.date = date
            commentItem.comment = comment
            self.commentList.append(commentItem)
        }
    }

    mutating func parsePNotice(result: String) {
        let result2 = Utils.replaceStringRegex(result, regex: "\r\n", replace: "\n")
        
        var subject = Utils.findStringRegex(result2, regex: "(?<=<h1 id=\\\"bo_v_title\\\">).*?(?=</h1>)")
        subject = Utils.replaceOnlyHtmlTag(subject)
        
        var name = Utils.findStringRegex(result2, regex: "(?<=<span class=\\\"sv_member\\\">).*?(?=</span>)")
        name = Utils.replaceOnlyHtmlTag(name)
        
        let date = Utils.findStringRegex(result2, regex: "(?<=작성일</span><strong>).*?(?=</strong>)")
        let hit = Utils.findStringRegex(result2, regex: "(?<=조회<strong>).*?(?=회</strong>)")
        
        var content = Utils.findStringRegex(result2, regex: "(<!-- 본문 내용 시작).*?(본문 내용 끝 -->)")
        
        var attach = Utils.findStringRegex(result2, regex: "(<!-- 첨부파일 시작).*?(첨부파일 끝 -->)")
        attach = Utils.replaceStringRegex(attach, regex: "<h2>첨부파일</h2>", replace: "")
        parseAttach(result: attach)
        
        var image = Utils.findStringRegex(result2, regex: "(<div id=\\\"bo_v_img\\\">).*?(</div>)")

        content = Utils.replaceStringRegex(content, regex: "onload=\\\"resizeImage2\\(this\\)\\\"", replace: "")
        image = Utils.replaceStringRegex(image, regex: "onload=\\\"resizeImage2\\(this\\)\\\"", replace: "")
        
        content = Utils.replaceStringRegex(content, regex: "<img ", replace: "<img onclick=\"myapp_clickImg(this)\" width=300 ")
        image = Utils.replaceStringRegex(image, regex: "<img ", replace: "<img onclick=\"myapp_clickImg(this)\" width=300 ")

        self.subject = subject
        self.name = name
        self.date = date
        self.hit = hit
        self.content = content
        self.attachStr = attach
        self.imageStr = image
        
        let comments = Utils.findStringRegex(result2, regex: "(<!-- 댓글 시작).*?(댓글 끝 -->)")
        let matchs = comments.components(separatedBy: "<article id=")
        for i in 0 ..< matchs.count {
            if i == 0 {
                continue
            }
            let matchstr = matchs[i]
            print("-----\n\(matchstr)\n-----")
            
            var isRe = 0
            if Utils.numberOfMatches(matchstr, regex: "icon_reply.gif") > 0 {
                isRe = 1
            }
            
            let no = Utils.findStringRegex(matchstr, regex: "(?<=span id=\\\"edit_).*?(?=\\\")")
            
            let name = Utils.findStringRegex(matchstr, regex: "(?<=<span class=\\\"member\\\">).*?(?=</span>)")
            
            var date = Utils.findStringRegex(matchstr, regex: "(<time datetime=).*?(</time>)")
            date = Utils.replaceOnlyHtmlTag(date)
            date = Utils.replaceStringRegex(date, regex: "/ ", replace: "")
            
            var comment =  Utils.findStringRegex(matchstr, regex: "(<!-- 댓글 출력 -->).*?(<!-- 수정 -->)")
            comment = Utils.replaceOnlyHtmlTag(comment)
            
            var deleteLink = Utils.findStringRegex(matchstr, regex: "(./delete_comment.php).*?(page=)")
            deleteLink = Utils.replaceStringRegex(deleteLink, regex: "&amp;", replace: "&")
            
            var commentItem = CommentItem()
            commentItem.isRe = isRe
            commentItem.no = no
            commentItem.name = name
            commentItem.date = date
            commentItem.comment = comment
            commentItem.deleteLink = deleteLink
            self.commentList.append(commentItem)
        }
    }
    
    mutating func parseAttach(result: String) {
        let matchs = Utils.matchStringRegex(result, regex: "(<li).*?(</li>)")
        for match  in matchs {
            let matchstr = result[match.range]
            
            var key = Utils.findStringRegex(matchstr, regex: "(?<=href=\").*?(?=\">)")
            key = Utils.replaceStringRegex(key, regex: "&amp;", replace: "&")
            
            var value = Utils.findStringRegex(matchstr, regex: "(?<=\">).*?(?=<span class)")
            value = value.trimmingCharacters(in: .whitespaces)
            
            var attachItem = AttachItem()
            attachItem.key = key
            attachItem.value = value
            self.attachList.append(attachItem)
        }
    }
}
