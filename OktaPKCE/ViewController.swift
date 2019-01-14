//
//  ViewController.swift
//  OktaPKCE
//
//  Created by Pedro Antonio González Laínez on 12/01/2019.
//  Copyright © 2019 Pedro Antonio González Laínez. All rights reserved.
//

import UIKit
import Alamofire
import WebKit
import CommonCrypto

class ViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    var codeChallenge = ""
    var codeVerifier = ""
    var state = ""
    var sessionToken = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        let parameters = ["username":"pedro_lainez@hotmail.com", "password":"eV3r1$2u","options":["multiOptionalFactorEnroll":true, "warnBeforePasswordExpired":true]] as [String : Any]
        
        makeRequest(urlRequest: "https://dev-948959.oktapreview.com/api/v1/authn",requestMethod: HTTPMethod.post, requestEncoding: JSONEncoding.default
            , requestHeaders: ["Accept":"application/json", "Content-Type":"Application/json"], requestParams: parameters, T: AuthnResponse.self, success: { (response) in
                self.codeVerifier = String.random(length: 43)
                let codeChallenge = self.codeVerifier.sha256 ?? ""
                self.codeChallenge = codeChallenge.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                self.state = String.random(length: 43)
                self.sessionToken = response.sessionToken
                if let url = URL(string: "https://dev-948959.oktapreview.com/oauth2/default/v1/authorize?sessionToken=\(response.sessionToken)&client_id=0oaiu05jqmEsQCDEs0h7&response_type=code&scope=openid&redirect_uri=https://com.oktapreview.dev-948959.redirect&state=\(self.state)&code_challenge_method=S256&code_challenge=\(self.codeChallenge)") {
                    let request = URLRequest(url: url)
                    self.webView.load(request)
                }
        }) { (error) in
            
        }
    }

    func makeRequest<T:Codable> (urlRequest: String, requestMethod: HTTPMethod = HTTPMethod.get, requestEncoding: ParameterEncoding = URLEncoding.default, requestHeaders: HTTPHeaders? = nil, requestParams: Parameters? = nil, T:T.Type, success: @escaping (T)->(), fail: @escaping (Error)->()){
        Alamofire.request(urlRequest, method: requestMethod, parameters: requestParams, encoding: requestEncoding, headers: requestHeaders).responseData { (responseData) in
            do {
                let response = try JSONSerialization.jsonObject(with: responseData.data!, options: [.allowFragments])
                let codable = try JSONDecoder().decode(T, from: responseData.data!)
                success(codable)
            }catch let error{
                fail(error)
            }
        }
    }

}

extension String {
    
    static func random(length: Int = 20) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }
    
    var sha256:String? {
        guard let stringData = self.data(using: String.Encoding.utf8) else { return nil }
        return digest(input: stringData as NSData).base64urlEncodedString()
    }
    
    private func digest(input : NSData) -> Data {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength) as Data
    }
}

extension URL {
    subscript(queryParam:String) -> String? {
        guard let url = URLComponents(string: self.relativeString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParam })?.value
    }
}

public extension Data {
    public init?(base64urlEncoded input: String) {
        var base64 = input
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 = base64.appending("=")
        }
        self.init(base64Encoded: base64)
    }
    
    public func base64urlEncodedString() -> String {
        var result = self.base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if webView.url?.relativeString.contains("https://com.oktapreview.dev-948959.redirect/") ?? false {
            let code = webView.url?["code"]
            let state = webView.url?["state"]
            let parameters = ["grant_type":"authorization_code", "client_id":"0oaiu05jqmEsQCDEs0h7","redirect_uri":"https://com.oktapreview.dev-948959.redirect","code":code!, "state":state!, "code_verifier":self.codeVerifier] as [String : Any]
            makeRequest(urlRequest: "https://dev-948959.oktapreview.com/oauth2/default/v1/token",requestMethod: HTTPMethod.post, requestEncoding: URLEncoding.queryString
                , requestHeaders: ["Accept":"application/json", "Content-Type":"application/x-www-form-urlencoded", "cache-control":"no-cache"], requestParams: parameters, T: TokenResponse.self, success: { (response) in
                    
            }) { (error) in
                
            }
        }
        decisionHandler(.allow)
    }
}
