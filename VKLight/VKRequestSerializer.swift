//
//  VKRequestSerializer.swift
//  VKLight
//
//  Created by Admin on 05.12.16.
//  Copyright © 2016 ArtemyevSergey. All rights reserved.
//

import Foundation

//имя для уведомления, которое отсылает менеджер запросов ВК после получения объекта с ответом
extension NSNotification.Name {
    static let objectHasBeenReceived = Notification.Name("objectHasBeenRecieved")
    static let pointerHasBeenRedirected = Notification.Name("pointerHasBeenRedirected")
    static let failureInRequest = Notification.Name("failureInRequest")
}

//протокол для объекта, описывающий запрос - метод VK API
protocol VKMethodSerializer {
    var methodName: String {get}
    var parameters: Dictionary<String,String> {get}
    var accessToken: String? {get}
    var version: String? {get}
}

//менеджер запросов к VK API
class VKRequestSerializer {
    private static let baseHTTP = "https://api.vk.com/method/"
    //базовая версия API, используется, если при составлении запроса явно не указана другая версия
    private static let version = "5.60"
    private let afNetworkingManager: AFHTTPRequestOperationManager!
    //объект с методом запроса может заполняться после инициализации класса, может многократно меняться
    var method: VKMethodSerializer?
    private var methodHTTP: String {
        return VKRequestSerializer.baseHTTP + method!.methodName
    }
    //заполнение словаря с параметрами для запроса
    private var methodParameters: Dictionary<String,String> {
        var parameters = self.method!.parameters
        //токен в словарь ставится из запроса, либо никакой(результат многих методов в этом случае не гарантируется)
        if let accessToken = self.method!.accessToken {
            parameters.updateValue(accessToken, forKey: "access_token")
        }
        //Версия API из запроса, либо базовая
        let version = self.method!.version ?? type(of: self).version
        parameters.updateValue(version, forKey: "v")
        return parameters
    }
    //выполнение запроса к VK API c помощью AFNetworking, для получения результата запроса передается указатель на словарь,
    //который после выполнения запроса будет указывать на готовый объект
    func getResponseObject (method: VKMethodSerializer?, responseF: UnsafeMutablePointer<NSDictionary>) {
        //проверка наличия объекта с запросом
        if let method = method {
            self.method = method
        }
        guard self.method != nil else{print("nothing to request"); return}
        let response = responseF
        self.afNetworkingManager.get(self.methodHTTP,
                                     parameters: self.methodParameters,
                                     success: {
                                        (operation, responseObject) in
                                        response.pointee = responseObject as! NSDictionary
                                        NotificationCenter.default.post(name: .pointerHasBeenRedirected,
                                                                        object: nil,
                                                                        userInfo: ["OperationState": "Success",
                                                                                   "methodName": self.method!.methodName])
                                     },
                                     failure: {
                                        (operation, error) in
                                        print("failure")
                                        NotificationCenter.default.post(name: .failureInRequest,
                                                                        object: nil,
                                                                        userInfo: ["OperationState": "Failure"])
                                     })
    }
    //метод для запроса, объект с ответом в котором возвращается в уведомлении, для его получения нужно
    //загестрироваться на получение уведомлений с именем "objectHasBeenReceived"
    //requestID - идентификатор запроса
    func getResponseObjectWithNotification (method: VKMethodSerializer?, requestID: Int) {
        if let method = method {
            self.method = method
        }
        let methodName = self.method!.methodName
        guard self.method != nil else{print("nothing to request"); return}
        self.afNetworkingManager.get(self.methodHTTP,
                                     parameters: self.methodParameters,
                                     success: {
                                        (operation, responseObject) in
                                        NotificationCenter.default.post(name: .objectHasBeenReceived,
                                                                        object: responseObject,
                                                                        userInfo: ["requestID": requestID,
                                                                                   "methodName": methodName])
                                     },
                                     failure: {
                                        (operation, error) in
                                        print("failure")
                                        NotificationCenter.default.post(name: .failureInRequest,
                                                                        object: error,
                                                                        userInfo: ["requestID": requestID])
                                     })
    }
    //более гибкий метод для составления запросов, позволяет выполнять те действия, которые требуются по ситуации, а не просто
    //получать объект с результатом
    func makeRequest (method: VKMethodSerializer?,
                      success:@escaping (AFHTTPRequestOperation?, Any?) -> (),
                      failure:@escaping (AFHTTPRequestOperation?, Error?) -> ()) {
        if let method = method {
            self.method = method
        }
        guard self.method != nil else{print("nothing to request"); return}
        self.afNetworkingManager.get(self.methodHTTP,
                                     parameters: self.methodParameters,
                                     success: success,
                                     failure: failure)
    }
    init(manager:AFHTTPRequestOperationManager) {
        self.afNetworkingManager = manager
    }
    convenience init(manager:AFHTTPRequestOperationManager, method:VKMethodSerializer) {
        self.init(manager: manager)
        self.method = method
    }
}

//базовая структура для составляния объекта с запросом, инициализирует все требуемые параметры простым подставлением значений
struct VKMethod: VKMethodSerializer {
    let methodName: String
    let parameters: Dictionary<String,String>
    let accessToken: String?
    let version: String?
    init(methodName: String, parameters: Dictionary<String,String>, accessToken: String?, version: String?) {
        self.methodName = methodName
        self.parameters = parameters
        self.accessToken = accessToken
        self.version = version
    }
}

