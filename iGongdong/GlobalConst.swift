//
//  GlobalConst.swift
//  iMoojigae
//
//  Created by dykim on 2020/08/19.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation

class GlobalConst {
    static var userId = ""
    static var swPush = 0
    static var swNotice = 0
    
    static let CafeName = "http://cafe.gongdong.or.kr"
    static let ServerName = "http://www.gongdong.or.kr"
    static let PushName = "http://www.gongdong.or.kr"
    static let AdUnitID = "ca-app-pub-9032980304073628/7128082761"
    
    static let LOGIN_TO_SERVER = 1
    static let PUSH_REGISTER = 2
    static let PUSH_UPDATE = 3
    static let LOGOUT_TO_SERVER = 4
    
    static let FILE_TYPE_HTML = 0
    static let FILE_TYPE_IMAGE = 1
    
    static let WRITE_MODE = 0
    static let MODIFY_MODE = 1
    static let REPLY_MODE = 2
    
    static let POST_DATA = 1
    static let POST_NOTICE = 2
    static let GET_TOKEN = 3
    
    static let SCALE_SIZE = 600
    
    static let READ_ARTICLE = 1
    static let DELETE_ARTICLE = 2
    static let DELETE_COMMENT = 3
    static let DELETE_COMMENT_NOTICE = 4

    static let CENTER = 1
    static let COMMUNITY = 2
    
    static let CAFE_TYPE_NORMAL = 0
    static let CAFE_TYPE_LINK = 2
    static let CAFE_TYPE_TITLE = 1
    static let CAFE_TYPE_CENTER = 3
    static let CAFE_TYPE_NOTICE = 4
    static let CAFE_TYPE_APPLY = 5
    static let CAFE_TYPE_ING = 6
    static let CAFE_TYPE_CAL = 9
}
