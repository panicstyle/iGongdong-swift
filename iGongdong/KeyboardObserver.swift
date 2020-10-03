//
//  KeyboardObserver.swift
//  iMoojigae
//
//  Created by dykim on 2020/09/17.
//  Copyright © 2020 dykim. All rights reserved.
//

import UIKit

final class KeyboardObserver {
    enum Event {
        case willShow, didShow, willHide, didHide, willChangeFrame, didChangeFrame
    }

    struct Info {
        let animationCurve: UIView.AnimationCurve
        let animationDuration: TimeInterval
        let isLocal: Bool
        let beginFrame: CGRect
        let endFrame: CGRect
        let event: Event
    }
    
    let changeHandler: (Info) -> ()
    init(changeHandler: @escaping (Info) -> ()) {
        self.changeHandler = changeHandler
        let notifications: [Notification.Name] = [UIResponder.keyboardWillShowNotification,
                                                  UIResponder.keyboardDidShowNotification,
                                                  UIResponder.keyboardWillHideNotification,
                                                  UIResponder.keyboardDidHideNotification,
                                                  UIResponder.keyboardWillChangeFrameNotification,
                                                  UIResponder.keyboardDidChangeFrameNotification]
        notifications.forEach { (notification) in
            NotificationCenter.default.addObserver(self, selector: #selector(KeyboardObserver.keyboardChanged(_:)), name: notification, object: nil)
        }
    }
    
    @objc private func keyboardChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { fatalError() }
        let event: Event = {
            switch notification.name {
            case UIResponder.keyboardWillShowNotification: return .willShow
            case UIResponder.keyboardDidShowNotification: return .didShow
            case UIResponder.keyboardWillHideNotification: return .willHide
            case UIResponder.keyboardDidHideNotification: return .didHide
            case UIResponder.keyboardWillChangeFrameNotification: return .willChangeFrame
            case UIResponder.keyboardDidChangeFrameNotification: return .didChangeFrame
            default:
                fatalError("Unknown change notification \(notification).")
            }
        }()
        changeHandler(Info(event: event, userInfo: userInfo))
    }
}

fileprivate extension KeyboardObserver.Info {
    init(event: KeyboardObserver.Event, userInfo: [AnyHashable: Any]) {
        self.event = event
        animationCurve = {
            let rawValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int
            return UIView.AnimationCurve(rawValue: rawValue)!
        }()
        animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        isLocal = userInfo[UIResponder.keyboardIsLocalUserInfoKey] as! Bool
        beginFrame = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect
        endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
    }
}
