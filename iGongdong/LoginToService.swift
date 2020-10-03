//
//  LoginToService.swift
//  iMoojigae
//
//  Created by dykim on 2020/09/11.
//  Copyright © 2020 dykim. All rights reserved.
//

import UIKit

protocol LoginToServiceDelegate: AnyObject {
    func loginToService(_ loginToService: LoginToService, loginWithSuccess result: String)
    func loginToService(_ loginToService: LoginToService, loginWithFail result: String)
    func loginToService(_ loginToService: LoginToService, logoutWithSuccess result: String)
    func loginToService(_ loginToService: LoginToService, logoutWithFail result: String)
    func loginToService(_ loginToService: LoginToService, pushWithSuccess result: String)
    func loginToService(_ loginToService: LoginToService, pushWithFail result: String)
}

class LoginToService: NSObject, HttpSessionRequestDelegate {
    var delegate: LoginToServiceDelegate?
    var userId : String = ""
    var userPwd : String = ""
    var swPush : NSNumber = 1
    
    func Login() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fullPath = paths[0].appendingPathComponent("set.dat")
        do {
            let fileData = try Data(contentsOf: fullPath)
            let setStorage = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(fileData) as! SetStorage
            userId = String(setStorage.userId)
            userPwd = String(setStorage.userPwd)
            swPush = setStorage.swPush
        } catch {
            print("Couldn't read set.dat file")
        }
        
        let escUserId = String(userId.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed) ?? "")
        
        let paramString = "url=%252F&mb_id=\(escUserId)&mb_password=\(userPwd)"

        let urlResource = GlobalConst.ServerName + "/bbs/login_check.php"
        let referer = GlobalConst.ServerName + "/bbs/login.php?url=%2F"
        
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.LOGIN_TO_SERVER
        httpSessionRequest.requestWithParamString(httpMethod: "POST", resource: urlResource, paramString: paramString, referer: referer)
    }
    
    func Logout() {
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.LOGOUT_TO_SERVER
        httpSessionRequest.requestWithParamString(httpMethod: "GET", resource: GlobalConst.ServerName + "/index.php?mid=front&act=dispMemberLogout", paramString: "", referer: "")
    }

    func PushRegister() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fullPath = paths[0].appendingPathComponent("token.dat")
        var token = ""
        do {
            let fileData = try Data(contentsOf: fullPath)
            let setTokenStorage = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(fileData) as! SetTokenStorage
            token = String(setTokenStorage.token)
        } catch {
            print("Couldn't read token.dat file")
        }
        
        if token == "" {
            self.delegate?.loginToService(self, pushWithFail: "")
            return
        }
        
        if GlobalConst.userId == "" {
            self.delegate?.loginToService(self, pushWithFail: "")
            return
        }
        
        var pushYN = "Y"
        if GlobalConst.swPush == 0 {
            pushYN = "N"
        }
        
        var noticeYN = "Y"
        if GlobalConst.swNotice == 0 {
            noticeYN = "N"
        }
        let jsonObject = ["type": "iOS", "push_yn": pushYN, "push_notice": noticeYN, "uuid": token, "userid": GlobalConst.userId]
        
        let httpSessionRequest = HttpSessionRequest()
        httpSessionRequest.delegate = self
        httpSessionRequest.tag = GlobalConst.PUSH_REGISTER
        httpSessionRequest.requestWithJson(httpMethod: "POST", resource: GlobalConst.PushName + "/push/PushRegister", json: jsonObject, referer: "")
    }
    
    //MARK: - HttpSessionRequestDelegate
    
    func httpSessionRequest(_ httpSessionRequest:HttpSessionRequest, didFinishLodingData data: Data) {
        if httpSessionRequest.tag == GlobalConst.LOGIN_TO_SERVER {
            let returnString = String(decoding: data, as: UTF8.self)
//            print (returnString)
            if !returnString.contains("<title>오류안내 페이지") {
                GlobalConst.userId = userId
                GlobalConst.swPush = 1
                self.delegate?.loginToService(self, loginWithSuccess: "")
            } else {
                self.delegate?.loginToService(self, loginWithFail: "")
            }
        } else if httpSessionRequest.tag == GlobalConst.LOGOUT_TO_SERVER {
            self.delegate?.loginToService(self, logoutWithSuccess: "")
        } else {
            self.delegate?.loginToService(self, pushWithSuccess: "")
        }
    }
    
    func httpSessionRequest(_ httpSessionRequest: HttpSessionRequest, withError error: Error?) {
        if httpSessionRequest.tag == GlobalConst.LOGIN_TO_SERVER {
            self.delegate?.loginToService(self, loginWithFail: "")
        } else if httpSessionRequest.tag == GlobalConst.LOGOUT_TO_SERVER {
            self.delegate?.loginToService(self, logoutWithFail: "")
        } else {
            self.delegate?.loginToService(self, pushWithFail: "")
        }
    }
 
    //MARK: - User Functions
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
