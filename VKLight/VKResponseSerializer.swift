//
//  VKResponseSerializer.swift
//  VKLight
//
//  Created by Admin on 18.12.16.
//  Copyright © 2016 ArtemyevSergey. All rights reserved.
//

import Foundation

//типы, указываемые в функции, возвращающей объект VK, означают непосредственно возвращаемый тип функции
typealias singleVKObject = VKObject
typealias arrayOfVKObjects = Array<VKObject>

//менеджер-парсер ответа от сервера VK
class VKResponseSerializer {
    //флаг процесса обработки ошибки в ответе от VK
    var errorHandlingInProcess = false
    //функция, которая парсит объект с ответом от VK, в зависимости от типа метода-запроса, на который пришел ответ, также нужно указать тип возращаемого объекта - один или массив, это значение зависит от метода ВК и требований кода, разные методы возвращают разные объекты, задача функции - залезть в словарь и вытащить оттуда непосредственно объект с данными,который описан в VKObject классе, для каждого метода ВК нужно описывать процедуру разбора для того, чтобы добраться до нужного объекта и вернуть его (структура ответа описана в документации ВК)
    func getVKObject<T> (methodName: String, responseObject: NSDictionary, returnType: T.Type) -> T? {
        //проверка на наличие ошибок в ответе
        guard responseObject["error"] == nil else{self.errorHandling("error"); return nil}
        var vkObjects: [VKObject] = []
        switch methodName {
        case "users.get":
            let usersObjects = responseObject["response"] as! NSArray
            for user in usersObjects {
                let vkUser = VKUser(responseObject: user as! NSDictionary)
                vkObjects.append(vkUser)
            }
        case "wall.get":
            let wallObjects = (responseObject["response"] as! NSDictionary)["items"] as! NSArray
            for wall in wallObjects {
                let vkWall = VKWall(responseObject: wall as! NSDictionary)
                vkObjects.append(vkWall)
            }
        default:
            return nil
        }
        if returnType == arrayOfVKObjects.self {
            return vkObjects as? T
        }else if returnType == singleVKObject.self {
            return vkObjects[0] as? T
        }else{
            return nil
        }
    }
    //функция обработки ошибок от VK, не запускается повторно, если уже находится в процессе работы
    func errorHandling (_ error:String) {
        guard self.errorHandlingInProcess != true else {return}
        self.errorHandlingInProcess = true
        print(error)
        (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController!.present(LoginController(), animated: true, completion: nil)
    }
}

//общий класс, описывающий объект ВК
class VKObject: NSObject {
    //словарь, полученный в ответе от ВК, описывающий объект, здесь хранятся все возможные значения объекта по документации ВК
    let responseObject: NSDictionary
    //общая функция, которая залазит в словарь объекта и вытаскивает оттуда нужное значение по ключу
    func valueFor (_ key: String) -> Any? {
        return self.responseObject[key]
    }
    init (responseObject: NSDictionary) {
        self.responseObject = responseObject
    }
}

//подклассы, описывающие разные объекты ВК (только нужные в программе, описание свойств (наименований и типов) можно делать по документации ВК)
class VKUser: VKObject {
    var id: Int {
        return self.valueFor(#keyPath(VKUser.id)) as! Int
    }
    var first_name: String {
        return self.valueFor(#keyPath(VKUser.first_name)) as! String
    }
    var last_name: String {
        return self.valueFor(#keyPath(VKUser.last_name)) as! String
    }
    var deactivated: String {
        return self.valueFor(#keyPath(VKUser.deactivated)) as! String
    }
    var hidden: Int {
        return self.valueFor(#keyPath(VKUser.hidden)) as! Int
    }
    var photo_100: String {
        return self.valueFor(#keyPath(VKUser.photo_100)) as! String
    }
}

class VKWall: VKObject {
    var id: Int {
        return self.valueFor(#keyPath(VKWall.id)) as! Int
    }
    var date: Int {
        return self.valueFor(#keyPath(VKWall.date)) as! Int
    }
    var text: String {
        return self.valueFor(#keyPath(VKWall.text)) as! String
    }
    var comments: NSDictionary {
        return self.valueFor(#keyPath(VKWall.comments)) as! NSDictionary
    }
    var likes: NSDictionary {
        return self.valueFor(#keyPath(VKWall.likes)) as! NSDictionary
    }
    var copy_history: [VKWall]? {
        var vkReposts: [VKWall] = []
        if let reposts = self.valueFor(#keyPath(VKWall.copy_history)) as? NSArray {
            for repost in reposts {
                let vkRepost = VKWall(responseObject: repost as! NSDictionary)
                vkReposts.append(vkRepost)
            }
            return vkReposts
        }else{
            return nil
        }
    }
}

