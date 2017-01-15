//
//  UserWallTableViewController.swift
//  VKLight
//
//  Created by Admin on 27.11.16.
//  Copyright © 2016 ArtemyevSergey. All rights reserved.
//

import UIKit
import WebKit

// MARK: - Расширение для VKRequestSerializer
//более удобный способ составлять объекты для запроса, здесь описаны те методы VK API, которые нужны в работе данного VC
//позволяет быстро создать объект с требуемыми параметрами
enum VKMethodName {
    case usersget(user_ids: String, fields: String, accessToken: String?, v: String?)
    case wallget(owner_id: String, count: String, accessToken: String?, v: String?)
}
extension VKMethod{
    init(_ method: VKMethodName) {
        switch method {
        case let .usersget(user_ids, fields, accessToken, v):
            self.methodName = "users.get"
            self.accessToken = accessToken
            self.version = v
            var parameters = Dictionary(dictionaryLiteral: ("user_ids",user_ids))
            parameters.updateValue(fields, forKey: "fields")
            self.parameters = parameters
        case let .wallget(owner_id, count, accessToken, v):
            self.methodName = "wall.get"
            self.accessToken = accessToken
            self.version = v
            var parameters = Dictionary(dictionaryLiteral: ("owner_id",owner_id))
            parameters.updateValue(count, forKey: "count")
            self.parameters = parameters
        }
    }
}

// MARK: - User Wall Controller
class UserWallTableViewController: UITableViewController {
    
    struct DefaultStrings {
        static let loginScreenSegue = "LoginScreen"
        static let user_id = "user_id"
        static let access_token = "access_token"
        static let methodName = "methodName"
        static let requestID = "requestID"
    }
        
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var userName: UILabel!
    
    var data: arrayOfVKObjects = []
    //попытка найти ID активного пользователя
    var userID: String? {
        if let user_id = UserDefaults.standard.value(forKey: DefaultStrings.user_id) as? String {
            return user_id
        }else {
            return nil
        }
    }
    //токен
    var currentUserAccessToken: String? {
        let token = UserDefaults.standard.value(forKey: DefaultStrings.access_token) as? String ?? nil
        return token
    }
    let requestsManager = (UIApplication.shared.delegate as! AppDelegate).vkRequestsManager
    let responseManager = (UIApplication.shared.delegate as! AppDelegate).vkResponseManager
    
    func printResult (result: Notification) {
        
        //print(result.name)
        //print(result.object ?? "no object")
        //print(result.userInfo ?? "no user info")
        
        switch result.userInfo![DefaultStrings.requestID] as! Int {
        case 1:
            if let user = responseManager.getVKObject(methodName: result.userInfo?[DefaultStrings.methodName] as! String,
                                                      responseObject: result.object as! NSDictionary,
                                                      returnType: singleVKObject.self) as? VKUser {
                self.userName.text = user.first_name + " " + user.last_name
                let url = URL(string: user.photo_100)
                if let photoData = try? Data(contentsOf: url!) {
                    self.userAvatar.image = UIImage(data: photoData)
                }
            }
        case 2:
            if let userWall = responseManager.getVKObject(methodName: result.userInfo?[DefaultStrings.methodName] as! String,
                                                          responseObject: result.object as! NSDictionary,
                                                          returnType: arrayOfVKObjects.self) {
                self.data = userWall
                self.tableView.reloadData()
            }
        default: break
        }
    }
    
    func loadData () {
        let user = VKMethod(VKMethodName.usersget(user_ids: self.userID!,
                                                 fields: "photo_100",
                                                 accessToken: self.currentUserAccessToken,
                                                 v: nil))
        let userWall = VKMethod(.wallget(owner_id: self.userID!,
                                         count: "10",
                                         accessToken: self.currentUserAccessToken,
                                         v: "5.60"))
        requestsManager.getResponseObjectWithNotification(method: user, requestID: 1)
        requestsManager.getResponseObjectWithNotification(method: userWall, requestID: 2)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //если активного пользователя нет - экран логина в ВК
        if self.userID == nil {
            print("no active user")
            self.navigationController?.present(LoginController(), animated: true, completion: nil)
        }else{
            print(self.userID!)
            self.loadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UserDefaults.standard.set("access_token=", forKey: "access_token")
        //подписка на получение уведомлений от менеджера VK запросов
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(printResult(result:)),
                                               name: .objectHasBeenReceived,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(printResult(result:)),
                                               name: .pointerHasBeenRedirected,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(printResult(result:)),
                                               name: .failureInRequest,
                                               object: nil)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.data.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wallCell", for: indexPath)
        
        // Configure the cell...
        let dateText = (self.data[indexPath.row] as! VKWall).date
        let date = Date(timeIntervalSince1970: TimeInterval(dateText))
        let text = (self.data[indexPath.row] as? VKWall)?.copy_history?[0].text
        (cell.contentView.subviews[0] as! UILabel).text = text ?? "\(date)"
        
        
        
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //выполнение логаута - происходит чистка куки в браузере (иначе пользователь останется старый) и удаляется активный пользователь
        if segue.identifier == DefaultStrings.loginScreenSegue {
            UserDefaults.standard.removeObject(forKey:DefaultStrings.user_id)
            UserDefaults.standard.removeObject(forKey: DefaultStrings.access_token)
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: [WKWebsiteDataTypeCookies]) {
                dataRecords in
                for dataRecord in dataRecords {
                    if dataRecord.displayName == "vk.com" {
                        WKWebsiteDataStore.default().removeData(ofTypes: [WKWebsiteDataTypeCookies], for: [dataRecord]) {
                            print("userHasLoggedOut")
                        }
                    }
                }
            }
            self.data = []
            self.userName.text = ""
            self.userAvatar.image = nil
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
