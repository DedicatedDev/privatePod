//
//  BrowserController.swift
//  GravityXR
//
//  Created by Avinash Shetty on 5/9/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import UIKit
import WebKit

protocol BrowserDelegate {
    func didCloseBrowser()
}


class BrowserController: UIViewController, WKUIDelegate {

    var delegate : BrowserDelegate?
    @IBOutlet weak var handleArea:UIView!
    @IBOutlet weak var webBrowserView:WKWebView!
    
    var url:URL = URL(string:"http://www.cisco.com")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func setupUI(url: URL) {
        
//        let webConfiguration = WKWebViewConfiguration()
//        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
//        webView.uiDelegate = self
//        webView.translatesAutoresizingMaskIntoConstraints = false
        let myRequest = URLRequest(url: url)
        self.webBrowserView.load(myRequest)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
        
    @IBAction func closeAction() {
        webBrowserView.stopLoading()
        self.delegate?.didCloseBrowser()
    }
        
    @IBAction func backAction() {
        if webBrowserView.canGoBack {
            webBrowserView.goBack()
        }
    }
    
    @IBAction func forwardAction() {
        if webBrowserView.canGoBack {
            webBrowserView.goBack()
        }
    }


}
