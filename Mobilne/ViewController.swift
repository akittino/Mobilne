//
//  ViewController.swift
//  Mobile
//
//  Created by Aleksander Kantak on 15.11.2015.
//  Copyright (c) 2015 Aleksander Kantak. All rights reserved.
//

import Alamofire
import UIKit

let productsURL: URLStringConvertible = "http://127.0.0.1:5678/product/all"
let serverURL: URLStringConvertible = "http://127.0.0.1:5678/product"
let userURL: URLStringConvertible = "http://127.0.0.1:5678/user"
let syncURL: URLStringConvertible = "http://127.0.0.1:5678/sync"

let tokenFile = "token.txt"
let userNameFile = "userName.txt"
let deviceDataFile = "device.txt"
let othersDataFile = "others.txt"

let OK = 200
let CONNECTION_ERROR = 403
let PRECONDITION_FAILED = 412
let FORBIDDEN = 500

class product {
    var name: String
    var value: Int
    init(name:String, value: Int){
        self.name = name
        self.value = value
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate {
    
    var globalData = [product]()
    var deviceData = [product]()
    var othersData = [product]()
    
    var syncOn = true
    var token = ""
    var userName = ""
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var loginTextbox: UITextField!
    @IBOutlet weak var passwordTextbox: UITextField!
    
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    
    @IBAction func saveButtonTouchUp(sender: AnyObject) {
        saveData()
    }
    
    func productArrayToString(data: [product]) -> String {
        var s = ""
        for p in data{
            s += p.name + " " + String(p.value) + "\n"
        }
        return s
    }
    
    func stringToProductArray(st: String) -> [product] {
        var data = [product]()
        let productsArray = st.characters.split {$0 == "\n"}.map(String.init)
        for p in productsArray{
            let vals = p.characters.split {$0 == " "}.map(String.init)
            let tmp = product(name: vals[0], value: Int(vals[1])!)
            data.append(tmp)
        }
        return data
    }
    
    func loadData() -> Void {
        if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
            
            let tokenPath = dir.stringByAppendingPathComponent(tokenFile)
            let userNamePath = dir.stringByAppendingPathComponent(userNameFile)
            let deviceDataPath = dir.stringByAppendingPathComponent(deviceDataFile)
            let othersDataPath = dir.stringByAppendingPathComponent(othersDataFile)

            
            do {
                token = try NSString(contentsOfFile: tokenPath,
                    encoding: NSUTF8StringEncoding) as String
                userName = try NSString(contentsOfFile: userNamePath,
                    encoding: NSUTF8StringEncoding) as String
                let deviceData2String = try NSString(contentsOfFile: deviceDataPath,
                    encoding: NSUTF8StringEncoding)
                let othersData2String = try NSString(contentsOfFile: othersDataPath,
                    encoding: NSUTF8StringEncoding)
                
                deviceData = stringToProductArray(deviceData2String as String)
                othersData = stringToProductArray(othersData2String as String)
            }
            catch {
                token = ""
                userName = ""
                deviceData = [product]()
                othersData = [product]()
                debugPrint("fail when loading data")
                debugPrint(error)
            }
        }
    }
    
    func saveData() -> Void {

        if let dir : NSString =
            NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.AllDomainsMask, true).first {
                
            let tokenPath = dir.stringByAppendingPathComponent(tokenFile)
            let userNamePath = dir.stringByAppendingPathComponent(userNameFile)
            let deviceDataPath = dir.stringByAppendingPathComponent(deviceDataFile)
            let othersDataPath = dir.stringByAppendingPathComponent(othersDataFile)
            
            let devData = productArrayToString(deviceData)
            let othData = productArrayToString(othersData)
                
            do {
                try token.writeToFile(tokenPath, atomically: false, encoding: NSUTF8StringEncoding)
                try userName.writeToFile(userNamePath, atomically: false, encoding: NSUTF8StringEncoding)
                try devData.writeToFile(deviceDataPath, atomically: false,
                    encoding: NSUTF8StringEncoding)
                try othData.writeToFile(othersDataPath, atomically: false,
                    encoding: NSUTF8StringEncoding)
            }
            catch {
                debugPrint("fail when saving data")
                debugPrint(error)
            }
        }
    }
    
    func jsonifyDeviceData() -> String {
        if deviceData.isEmpty{
            return "empty"
        }
        var data = "{"
        for d in deviceData{
            data += "\"" + d.name + "\":" + String(d.value) + ","
        }
        data.removeAtIndex(data.endIndex.predecessor())
        data += "}"
        return data
    }
    
    func syncWithServer(callback: ((status: Int)->Void)?) {
        if syncOn == false{
            callback?(status: OK)
            return
        }
        
        let parameters : [String:AnyObject] =  [
                "token": self.token,
                "product": jsonifyDeviceData()
            ]
        
        Alamofire.request(.POST, syncURL, parameters: parameters, encoding: .JSON)
            .responseJSON { response in
                if response.response == nil{
                    callback!(status: CONNECTION_ERROR)
                } else {
                    let d = response.result.value as? [String: AnyObject]
                    self.othersData.removeAll()
                    
                    if d != nil {
                        for (n, k) in d!{
                            self.othersData.append(product(name: n, value: Int(String(k))!))
                            var found = 0
                            for p in self.deviceData
                            {
                                if p.name == n{
                                    found = 1
                                    break
                                }
                            }
                            if found == 0{
                                self.deviceData.append(product(name: n, value: 0))
                            }
                        }
                    }
                    else{
                        debugPrint("Data was empty")
                    }
                    
                    for var i = 0; i < self.deviceData.count; ++i{
                        let d = self.deviceData[i]
                        var found = 0
                        for o in self.othersData{
                            if o.name == d.name{
                                found = 1
                                break
                            }
                        }
                        if found == 0{
                            self.deviceData.removeAtIndex(i)
                        }
                    }
                    
                    callback?(status: OK)
                }
        }
    }
    
    func reload() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    func evalGlobalData(){
        globalData.removeAll()
        for p in deviceData{
            let tmp = product(name: p.name, value: p.value)
            for q in othersData{
                if q.name == p.name{
                    tmp.value += q.value
                }
            }
            globalData.append(tmp)
        }
    }

    func nameExists(name: String) -> Bool{
        for x in globalData{
            if x.name == name{
                return true
            }
        }
        return false
    }

    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style:UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(userText: UITextField) -> Bool {
        nameTextField.resignFirstResponder()
        return true;
    }
    
    func serverLogin(login: String, hash: String, callback: ((status: Int)->Void)?){
        
        let parameters : [String: AnyObject] = [
            "userName": login,
            "pwd": hash
        ]
        
        Alamofire.request(.POST, userURL, parameters: parameters, encoding: .JSON)
            .responseJSON{ response in
                if response.response == nil{
                    callback!(status: CONNECTION_ERROR)
                } else {
                    if let d = response.result.value as? [String : AnyObject] {
                        self.token = String(d["token"]!)
                    }
                    callback?(status: (response.response?.statusCode)!)
                }
        }
    }
    
    func serverRegister(login: String, hash: String, callback: ((status: Int)->Void)?){
        
        let parameters : [String: AnyObject] = [
            "userName": login,
            "pwd": hash
        ]
        
        Alamofire.request(.PUT, userURL, parameters: parameters, encoding: .JSON)
            .responseJSON{ response in
                if response.response == nil{
                    callback!(status: CONNECTION_ERROR)
                } else {
                    if let d = response.result.value as? [String : AnyObject] {
                        self.token = String(d["token"]!)
                    }
                    callback?(status: (response.response?.statusCode)!)
                }
        }
    }
    
    func serverLogout(callback: ((status: Int)->Void)?){
        let parameters : [String: AnyObject] = [
            "token": token
        ]
        
        Alamofire.request(.DELETE, userURL, parameters: parameters, encoding: .JSON)
            .responseString{ response in
                if response.response == nil{
                    callback!(status: CONNECTION_ERROR)
                } else {
                    callback?(status: (response.response?.statusCode)!)
                }
        }
        globalData.removeAll()
        deviceData.removeAll()
        othersData.removeAll()
        // TODO save ???
    }
    
    func createHash(password: String) -> String {
        return String(password)
    }
    
    func syncButtonChange(s:Bool){
        if s == true{
            syncOn = true
            syncButton.setTitle("SyncOn", forState: UIControlState.Normal)
            syncButton.setTitleColor(UIColor.greenColor(), forState: UIControlState.Normal)
            if token == "" {
                return
            }
            syncWithServer(){ (status) -> Void in
                if status != OK {
                    self.showAlert("Error in sync")
                }
                else{
                    self.evalGlobalData()
                    self.tableView.reloadData()
                }
            }
        } else {
            syncOn = false
            syncButton.setTitle("SyncOff", forState: UIControlState.Normal)
            syncButton.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
        }
    }
    @IBAction func syncButtonTouchUp(sender: AnyObject) {
        syncButtonChange(!syncOn)
    }
    
    @IBAction func removeButtonTouchUp(sender: AnyObject) {
        let selectedRow = tableView.indexPathForSelectedRow?.row
        if selectedRow == nil {
            showAlert("Select row")
        } else {
            
            var i = 0
            for p in self.deviceData{
                if p.name == self.globalData[selectedRow!].name{
                    deviceData.removeAtIndex(i)
                    break
                }
                i += 1
            }
            
            i = 0
            for p in self.othersData{
                if p.name == self.globalData[selectedRow!].name{
                    othersData.removeAtIndex(i)
                    break
                }
                i += 1
            }
            
            syncWithServer(){ (status) -> Void in
                if status != OK {
                    self.showAlert("Error in sync")
                }
                else{
                    self.evalGlobalData()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @IBAction func addButtonTouchUp(sender: AnyObject) {
        let name :String = nameTextField.text!
        if name == ""{
            showAlert("Name cannot be empty")
        }
        else if nameExists(name){
            showAlert("Given name already exists")
        }
        else{
            self.deviceData.append(product(name: name, value:0))
            self.nameTextField.text! = ""
            
            syncWithServer(){ (status) -> Void in
                if status != OK {
                    self.showAlert("Error in sync")
                } else {
                    self.evalGlobalData()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func changeValue(change: Int) {
        let selectedRow = tableView.indexPathForSelectedRow?.row
        if selectedRow == nil{
            showAlert("Select row")
        } else {
            for p in self.deviceData{
                if p.name == self.globalData[selectedRow!].name{
                    p.value += change
                }
            }
        }
    }
    
    @IBAction func changeButtonTouchUp(sender: UIButton) {
        let val :String = nameTextField.text!
        if val == ""{
            showAlert("Name cannot be empty")
        }
        let change = Int(val)
        if change == nil{
            showAlert("Please enter a number")
        } else {
            if sender.tag == 1 {
                changeValue(-change!)
            } else if sender.tag == 2 {
                changeValue(change!)
            }
            else{
                showAlert("Unknown error")
            }
            nameTextField.text = ""
            
            syncWithServer(){ (status) -> Void in
                if status != OK {
                    self.showAlert("Error in sync")
                } else {
                    self.evalGlobalData()
                    self.tableView.reloadData()
                }
            }
        }
    }
    @IBAction func loginButton(sender: AnyObject) {
        let user = loginTextbox.text
        let password = passwordTextbox.text
        let hash = createHash(password!)
        
        if user == "" || password == "" {
            showAlert("Insert login and password first")
            return
        }
        
        if syncOn == false{
            syncButtonChange(true)
        }
        
        serverLogin(user!, hash: hash){ (status) -> Void in
            if status == OK {
                self.userName = user!
                self.switchButtons(true)
                self.syncWithServer(){ (status) -> Void in
                    if status != OK {
                        self.showAlert("Error in sync")
                    } else {
                        self.evalGlobalData()
                        self.tableView.reloadData()
                    }
                }
            } else if status == PRECONDITION_FAILED {
                self.showAlert("There's no such a user")
            } else if status == FORBIDDEN {
                self.showAlert("Invalid password")
            } else {
                self.showAlert("Error when logging in: \n" + String(status))
            }
        }
    }
    @IBAction func registerButton(sender: AnyObject) {
        let user = loginTextbox.text
        let password = passwordTextbox.text
        let hash = createHash(password!)
        
        if user == "" || password == "" {
            showAlert("Insert login and password first")
            return
        }
        
        if syncOn == false{
            syncButtonChange(true)
        }
        
        serverRegister(user!, hash: hash){ (status) -> Void in
            if status == OK {
                self.userName = user!
                self.switchButtons(true)
            } else if status == PRECONDITION_FAILED {
                self.showAlert("User exists")
            } else {
                self.showAlert("Error when registering: \n" + String(status))
            }
        }
        
        syncWithServer(){ (status) -> Void in
            if status != OK {
                self.showAlert("Error in sync")
            } else {
                self.evalGlobalData()
                self.tableView.reloadData()
            }
        }
        
    }
    
    @IBAction func logoutButton(sender: AnyObject) {
        if syncOn == false{
            syncButtonChange(true)
        }
        
        globalData.removeAll()
        deviceData.removeAll()
        othersData.removeAll()
        self.userName = ""
        self.token = ""
        self.switchButtons(false)
        self.evalGlobalData()
        self.tableView.reloadData()
    }
    
    func switchButtons(login: Bool){
        if login {
            label.text = userName
            logoutButton.enabled = true
            loginButton.enabled = false
            registerButton.enabled = false
            
            addButton.enabled = true
            removeButton.enabled = true
            plusButton.enabled = true
            minusButton.enabled = true
            
            self.evalGlobalData()
            self.tableView.reloadData()
        }
        else{
            label.text = "Please log in"
            logoutButton.enabled = false
            loginButton.enabled = true
            registerButton.enabled = true
            
            addButton.enabled = false
            removeButton.enabled = false
            plusButton.enabled = false
            minusButton.enabled = false
            
            globalData.removeAll()
            deviceData.removeAll()
            othersData.removeAll()
            
            self.evalGlobalData()
            self.tableView.reloadData()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return globalData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel!.font = UIFont(name:"Console", size:22)
        cell.textLabel?.text = globalData[indexPath.row].name + " - quantity: " + String(globalData[indexPath.row].value)
        
        return cell
    }
    
    override func viewDidLoad() {
        switchButtons(false)
        syncButton.setTitleColor(UIColor.greenColor(), forState: UIControlState.Normal)
        loadData()
        if userName != "" {
            switchButtons(true)
        }
        super.viewDidLoad()
        self.nameTextField.delegate = self
    }
}

