//
//  HttpSessionRequest.swift
//  iMooojigae
//
//  Created by dykim on 2020/08/19.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation

protocol HttpSessionRequestDelegate {
    func httpSessionRequest(_ httpSessionRequest: HttpSessionRequest, didFinishLodingData data: Data)
    func httpSessionRequest(_ httpSessionRequest: HttpSessionRequest, withError error: Error?)
}

class HttpSessionRequest {
    var delegate: HttpSessionRequestDelegate?
    var tag = -1
    var httpMethod = "GET"
    var sharedCookies: Array<HTTPCookie>?

    func requestWithJson(httpMethod: String, resource: String, json: [String: Any], referer: String) {
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        return requestWithParam(httpMethod: httpMethod, resource: resource, param: jsonData, referer: referer)
    }
    
    func requestWithParam(httpMethod: String, resource: String, param: Data?, referer: String) {
        // 세션 생성, 환경설정
        let defaultSession = URLSession(configuration: .default)

        guard let url = URL(string: "\(resource)") else {
            print("URL is nil")
            return
        }

        // Request
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue(referer, forHTTPHeaderField: "Referer")

        if (param != nil) {
            request.httpBody = param
        }

        // dataTask
        let dataTask = defaultSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            self.dataTaskFinish(request: request, data: data, response: response, error: error)
        }
        dataTask.resume()
    }

    func requestWithMultiPart(resource: String, param: Data?, referer: String, boundary: String) {
        // 세션 생성, 환경설정
        let defaultSession = URLSession(configuration: .default)

        guard let url = URL(string: "\(resource)") else {
            print("URL is nil")
            return
        }

        let postLength = String(param!.count)
        let contentType = "multipart/form-data; boundary=\(boundary)"
        
        // Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(referer, forHTTPHeaderField: "Referer")

        if (param != nil) {
            request.httpBody = param
        }

        // dataTask
        let dataTask = defaultSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            self.dataTaskFinish(request: request, data: data, response: response, error: error)
        }
        dataTask.resume()
    }
    
    func requestWithParamString(httpMethod: String, resource: String, paramString: String?, referer: String) {
        // 세션 생성, 환경설정
        let defaultSession = URLSession(configuration: .default)

        var resource2 = resource
        if (paramString != nil) {
            if (httpMethod == "GET") {
                resource2 = resource2 + "?" + paramString!
            }
        }

        guard let url = URL(string: "\(resource2)") else {
            print("URL is nil")
            return
        }

        // Request
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue(referer, forHTTPHeaderField: "Referer")

        if (paramString != nil) {
            if (httpMethod != "GET") {
                let param = paramString?.data(using: String.Encoding.utf8)
                request.httpBody = param
            }
        }

        // dataTask
        let dataTask = defaultSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            self.dataTaskFinish(request: request, data: data, response: response, error: error)
        }
        dataTask.resume()
    }
    
    func dataTaskFinish(request: URLRequest?, data: Data?, response: URLResponse?, error: Error?) {
        // getting Data Error
        guard error == nil else {
            print("Error occur: \(String(describing: error))")
            self.delegate?.httpSessionRequest(self, withError: error)
            return
        }
        guard let data = data else {
            self.delegate?.httpSessionRequest(self, withError: error)
            return
        }
        guard let response = response as? HTTPURLResponse else {
            self.delegate?.httpSessionRequest(self, withError: error)
            return
        }
        guard response.statusCode == 200 else {
            print("Error response.statusCode=\(response.statusCode)")
            self.delegate?.httpSessionRequest(self, withError: error)
            return
        }
        self.sharedCookies = HTTPCookieStorage.shared.cookies(for: request!.url!) ?? []
        self.delegate?.httpSessionRequest(self, didFinishLodingData: data)

    }
}
