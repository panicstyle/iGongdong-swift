//
//  Utils.swift
//  iMoojigae
//
//  Created by dykim on 2020/09/19.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation
import UIKit

class Utils {
    static func numberOfMatches(_ str: String, regex: String) -> Int {
        let range = NSRange(str.startIndex..., in: str)
        let regex = try! NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
        return regex.numberOfMatches(in: str, options: [], range: range)
    }
    
    static func findStringRegex(_ str: String, regex: String) -> String {
        let range = NSRange(str.startIndex..., in: str)
        let regex = try! NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
        let findRange = regex.rangeOfFirstMatch(in: str, options: [], range: range)
        if findRange.location == NSNotFound {
            return ""
        }
        let r2 = Range(findRange, in: str)
        return String(str[r2!])
    }

    static func matchStringRegex(_ str: String, regex: String) -> [NSTextCheckingResult] {
        let range = NSRange(str.startIndex..., in: str)
        let regex = try! NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
        let matchs = regex.matches(in: str, options: [], range: range)
        return matchs
    }
    
    static func replaceStringRegex(_ str: String, regex: String, replace: String) -> String {
        let range = NSRange(str.startIndex..., in: str)
        let regex = try! NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
        let str2 = regex.stringByReplacingMatches(in: str, options: [], range: range, withTemplate: replace)
        return String(str2)
    }

    static func replaceHtmlTag(_ str: String) -> String {
        var str2 = self.replaceStringRegex(str, regex: "</p>", replace: "\n")
        str2 = self.replaceStringRegex(str2, regex: "</div>", replace: "\n")
        str2 = self.replaceStringRegex(str2, regex: "<br>", replace: "\n")
        str2 = self.replaceStringRegex(str2, regex: "</br>", replace: "\n")
        str2 = self.replaceStringRegex(str2, regex: "<br />", replace: "\n")
        return str2
    }
    
    static func removeHtmlTag(_ str: String) -> String {
        var str2 = self.replaceStringRegex(str, regex: "<!--.*?-->", replace: "")
        str2 = self.replaceStringRegex(str2, regex: "<.*?>", replace: "")
        str2 = str2.trimmingCharacters(in: .whitespacesAndNewlines)
        return str2
    }
    
    static func replaceStringHtmlTag(_ str: String) -> String {
        return str
    }

    static func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    static func addBoldText(fullString: String, boldPartOfString: String, baseFont: UIFont, boldFont: UIFont) -> NSAttributedString {

        let baseFontAttribute = [NSAttributedString.Key.font : baseFont]
        let boldFontAttribute = [NSAttributedString.Key.font : boldFont]

        let attributedString = NSMutableAttributedString(string: fullString, attributes: baseFontAttribute)

        attributedString.addAttributes(boldFontAttribute, range: NSRange(fullString.range(of: boldPartOfString) ?? fullString.startIndex..<fullString.endIndex, in: fullString))

        return attributedString
    }
    
    static func addBoldText(fullString: String, boldFont: UIFont) -> NSAttributedString {
        let boldFontAttribute = [NSAttributedString.Key.font : boldFont]
        let attributedString = NSMutableAttributedString(string: fullString, attributes: boldFontAttribute)
        return attributedString
    }

}
