//
//  LoginController.swift
//  VKLight
//
//  Created by Admin on 23.11.16.
//  Copyright © 2016 ArtemyevSergey. All rights reserved.
//

import UIKit
import WebKit

class LoginController: UIViewController, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate {
    
    //структуры со значениями параметров для входа в VK и получения Access Token
    struct DefaultStrings {
        static let loginURL = "https://oauth.vk.com/authorize" //http для авторизации
        static let loginParameters = [
            "client_id":"5743714", //приложение VKLight
            "redirect_uri":"https://oauth.vk.com/blank.html", //пустая страница - редирект после получения токена
            "display":"mobile", //тип устройства
            "scope":"status", 
            "response_type":"token",
            "v":"5.60",
            "revoke":"1"
        ]
        //структура ответа от сервера с полученным токеном
        static let grantedAccessData = [
            "access_token=":"",
            "expires_in=":"",
            "user_id=":"",
        ]
    }
    
    var webView: WKWebView!
    
    override func loadView() {
        //создание webView в качестве root view для этого VC
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect.zero, configuration: webConfiguration)
        //настройка отступа сверху для ScrollView, чтобы status bar не перекрывал содержимое
        webView.scrollView.contentInset = UIEdgeInsets(top: 20.0, left: 0.0, bottom: 0.0, right: 0.0)
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 20.0, left: 0.0, bottom: 0.0, right: 0.0)
        webView.scrollView.delegate = self
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //создание запроса с адресом и параметрами для получения токена
        let requestSerializer = AFHTTPRequestSerializer()
        let loginURL = URL(string: DefaultStrings.loginURL)
        let request = URLRequest(url:loginURL!)
        //добавление параметров к запросу (метод бросает exception)
        if let request = try? requestSerializer.request(bySerializingRequest: request, withParameters: DefaultStrings.loginParameters){
            //print(request as URLRequest)
            self.webView.load(request as URLRequest)
        }
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        //проверка редиректа от сервера VK,если в адресе браузера содержится access_token - токен получен
        if webView.url?.absoluteString.contains("access_token") == true {
            //получение параметров адреса, в которых содержатся требуемые значения
            let successResponseURL = NSURLComponents(string: webView.url!.absoluteString)?.fragment
            let successResponse = successResponseURL?.components(separatedBy: "&") //массив с элементами вида: "access_token=123"
            var responseDictionary = DefaultStrings.grantedAccessData
            for key in responseDictionary.keys {
                //индекс для подходящего элемента в массиве successResponse
                let index = successResponse!.index(where:{$0.contains(key)})
                //значение для этого индекса из массива
                let value = successResponse![index!].replacingOccurrences(of: key, with: "") //остается только значение
                responseDictionary.updateValue(value, forKey: key)
            }
            //print(responseDictionary)
            //пользователь становится активным
            UserDefaults.standard.set(responseDictionary["user_id="], forKey: "user_id")
            UserDefaults.standard.set(responseDictionary["access_token="], forKey: "access_token")
            self.presentingViewController?.dismiss(animated: true) {
                (UIApplication.shared.delegate as! AppDelegate).vkResponseManager.errorHandlingInProcess = false
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
