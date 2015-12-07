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
let OK = 200
let CONNECTION_ERROR = 403
let PRECONDITION_FAILED = 412
let FORBIDDEN = 500

var token = ""
var userName = ""

class product {
    var name: String
    var value: Int
    init(name:String, value: Int){
        self.name = name
        self.value = value
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate {
    
    var data = [product]()
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var loginTextbox: UITextField!
    @IBOutlet weak var passwordTextbox: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!

    
    
    func serverGetData(callback: ((status: Int)->Void)?){
        let parameters : [String: AnyObject] =  [
            "token": token
        ]
        Alamofire.request(.POST, productsURL, parameters: parameters, encoding: .JSON)
            .responseJSON { response in
                if response.response == nil{
                    callback!(status: CONNECTION_ERROR)
                } else {
                    let d = response.result.value as? [String: AnyObject]
                    for (n, k) in d!{
                        self.data.append(product(name: n, value: Int(String(k))!))
                    }
                    callback?(status: OK)
                }
        }
    }
    
    func serverAddProduct(name: String, callback: ((status: Int)->Void)?){
        
        let parameters : [String: AnyObject] = [
            "token": token,
            "name": name
        ]
        
        Alamofire.request(.POST, serverURL, parameters: parameters, encoding: .JSON)
            .responseString{ response in
                if response.response == nil{
                    callback!(status: CONNECTION_ERROR)
                } else {
                    callback?(status: (response.response?.statusCode)!)
                }
        }
    }
    
    func serverRemoveProduct(name: String, callback: ((status: Int)->Void)?){
        
        let parameters : [String: AnyObject] = [
            "token": token,
            "name": name
        ]
        
        Alamofire.request(.DELETE, serverURL, parameters: parameters, encoding: .JSON)
            .responseString{ response in
                if response.response == nil{
                    callback!(status: CONNECTION_ERROR)
                } else {
                    callback?(status: (response.response?.statusCode)!)
                }
        }
    }
    
    func serverChangeProduct(name: String, change: Int, callback: ((status: Int)->Void)?){
        
        let parameters : [String: AnyObject] = [
            "token": token,
            "name": name,
            "change": change
        ]
        
        Alamofire.request(.PUT, serverURL, parameters: parameters, encoding: .JSON)
            .responseString{ response in
                if response.response == nil{
                    callback!(status: CONNECTION_ERROR)
                } else {
                    callback?(status: (response.response?.statusCode)!)
                }
        }
    }
    func nameExists(name: String) -> Bool{
        for x in data{
            if x.name == name{
                return true
            }
        }
        return false
    }
    
    func changeValue(change: Int) {
        let selectedRow = tableView.indexPathForSelectedRow?.row
        if selectedRow == nil{
            showAlert("Select row")
        } else {
            serverChangeProduct(data[selectedRow!].name, change: change){ (status) -> Void in
                if status == OK {
                    self.data[selectedRow!].value += change
                    self.tableView.reloadData()
                } else {
                    self.showAlert("Error when changing quantity of product to server: \n" + String(status))
                }
            }
        }
    }
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style:UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func reload() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
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
                        //debugPrint(d["token"]!)
                        token = String(d["token"]!)
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
                        //debugPrint(d["token"]!)
                        token = String(d["token"]!)
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
    }
    
    func createHash(password: String) -> String {
        return String(password.hashValue)
    }
    
    @IBAction func removeButtonTouchUp(sender: AnyObject) {
        let selectedRow = tableView.indexPathForSelectedRow?.row
        if selectedRow == nil {
            showAlert("Select row")
        } else {
            serverRemoveProduct(data[selectedRow!].name){ (status) -> Void in
                if status == OK {
                    self.data.removeAtIndex(selectedRow!)
                    self.tableView.reloadData()
                } else {
                    self.showAlert("Error when deleting product from server: \n" + String(status))
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
            serverAddProduct(name){ (status) -> Void in
                if status == OK {
                    self.data.append(product(name: name, value:0))
                    self.tableView.reloadData()
                    self.nameTextField.text! = ""
                } else {
                    self.showAlert("Error when adding product to server: \n" + String(status))
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
        
        serverLogin(user!, hash: hash){ (status) -> Void in
            if status == OK {
                userName = user!
                self.switchButtons(true)
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
        
        serverRegister(user!, hash: hash){ (status) -> Void in
            if status == OK {
                userName = user!
                self.switchButtons(true)
            } else if status == PRECONDITION_FAILED {
                self.showAlert("User exists")
            } else {
                self.showAlert("Error when registering: \n" + String(status))
            }
        }
        
    }
    
    @IBAction func logoutButton(sender: AnyObject) {
        serverLogout(){ (status) -> Void in
            if status == OK {
                userName = ""
                token = ""
                self.switchButtons(false)
            } else {
                self.showAlert("Error when logging out: \n" + String(status))
            }
        }
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

            serverGetData(){ (status) -> Void in
                if status == OK {
                    self.tableView.reloadData()
                } else {
                    self.showAlert("Error when reading init data from server: \n" + String(status))
                }
            }
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
            
            data.removeAll()
            self.tableView.reloadData()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel!.font = UIFont(name:"Console", size:22)
        cell.textLabel?.text = data[indexPath.row].name + " - quantity: " + String(data[indexPath.row].value)
        
        return cell
    }
    
    override func viewDidLoad() {
        switchButtons(false)
        super.viewDidLoad()
        self.nameTextField.delegate = self
    }
}

