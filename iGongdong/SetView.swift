//
//  SetView.swift
//  iMoojigae
//
//  Created by dykim on 2020/09/11.
//  Copyright © 2020 dykim. All rights reserved.
//

import UIKit
import os.log

protocol SetViewDelegate {
    func setView(_ setView: SetView, didSaved sender: Any)
}

class SetView : UIViewController, LoginToServiceDelegate {

    //MARK: Properties

    @IBOutlet var idLabel : UILabel!
    @IBOutlet var pwLabel : UILabel!
    @IBOutlet var titleLabel : UILabel!
    @IBOutlet var swNoticeLabel : UILabel!
    @IBOutlet var swPushLabel : UILabel!

    @IBOutlet var idField : UITextField!
    @IBOutlet var pwField : UITextField!
    @IBOutlet var swPush : UISwitch!
    @IBOutlet var swNotice : UISwitch!

    var delegate: SetViewDelegate?
    
    override func viewDidLoad() {
        self.title = "설정"
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.contentSizeCategoryDidChangeNotification),
                                               name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        idLabel.font = bodyFont
        pwLabel.font = bodyFont
        titleLabel.font = bodyFont
        swNoticeLabel.font = bodyFont
        swPushLabel.font = bodyFont

        idField.font = bodyFont
        pwField.font = bodyFont
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fullPath = paths[0].appendingPathComponent("set.dat")
        do {
            let fileData = try Data(contentsOf: fullPath)
            let setStorage = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(fileData) as! SetStorage
            idField.text = String(setStorage.userId)
            pwField.text = String(setStorage.userPwd)
            if setStorage.swPush == 1 {
                swPush.setOn(true, animated: true);
            } else {
                swPush.setOn(false, animated: true);
            }
        } catch {
            print("Couldn't read set.dat file")
        }
        
        super.viewDidLoad()
    }
    
    @objc func contentSizeCategoryDidChangeNotification() {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        idLabel.font = bodyFont
        pwLabel.font = bodyFont
        titleLabel.font = bodyFont
        swNoticeLabel.font = bodyFont
        swPushLabel.font = bodyFont

        idField.font = bodyFont
        pwField.font = bodyFont
    }
    
    deinit {
        // perform the deinitialization
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - LoginToServiceDelegate
    
    func loginToService(_ loginToService: LoginToService, loginWithSuccess result: String) {
        print("login success")
        let loginToService = LoginToService()
        loginToService.delegate = self
        loginToService.PushRegister()
    }
    
    func loginToService(_ loginToService: LoginToService, loginWithFail result: String) {
        print("login fail")
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "로그인 오류", message: "아이디 혹은 비밀번호를 다시 확인하세요.", preferredStyle: .alert)
            let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
            alert.addAction(confirm)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func loginToService(_ loginToService: LoginToService, logoutWithSuccess result: String) {
        print("logout success")
        let loginToService = LoginToService()
        loginToService.delegate = self
        loginToService.Login()
    }
    
    func loginToService(_ loginToService: LoginToService, logoutWithFail result: String) {
        print("logout fail")
        let loginToService = LoginToService()
        loginToService.delegate = self
        loginToService.Login()
    }
    
    func loginToService(_ loginToService: LoginToService, pushWithSuccess result: String) {
        print("push success")
        DispatchQueue.main.async {
            self.delegate?.setView(self, didSaved: self)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func loginToService(_ loginToService: LoginToService, pushWithFail result: String) {
        print("push fail")
        DispatchQueue.main.async {
            self.delegate?.setView(self, didSaved: self)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - User Functions
    
    func showAlert() {
        let alert = UIAlertController(title: "로그인 오류", message: "아이디 혹은 비밀번호를 다시 확인하세요.", preferredStyle: .alert)
        let confirm = UIAlertAction(title: "확인", style: .default) { (action) in }
        alert.addAction(confirm)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func actionSave(_ sender: UIBarButtonItem) {
        if idField.text == "" || pwField.text == "" {
            showAlert()
            return
        }
        
        var swPushValue = 0
        if swPush.isOn {
            swPushValue = 1
        }

        var swNoticeValue = 0
        if swNotice.isOn {
            swNoticeValue = 1
        }
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fullPath = paths[0].appendingPathComponent("set.dat")
        let setStorage = SetStorage.init(userId: idField.text ?? "", userPwd: pwField.text ?? "", swPush: NSNumber(value: swPushValue), swNotice: NSNumber(value: swNoticeValue))
        // Archive
        if let dataToBeArchived = try? NSKeyedArchiver.archivedData(withRootObject: setStorage, requiringSecureCoding: false) {
            try? dataToBeArchived.write(to: fullPath)
        }
        
        let loginToService = LoginToService()
        loginToService.delegate = self
        loginToService.Logout()
    }
    

}
