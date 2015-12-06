//
//  LogInViewController.swift
//  Mobilne
//
//  Created by Aleksander Kantak on 15.11.2015.
//  Copyright © 2015 Aleksander Kantak. All rights reserved.
//

import UIKit
import Alamofire

class LogInViewController: UIViewController {

    @IBOutlet weak var loginTextBox: UITextField!
    @IBOutlet weak var passwordTextBox: UITextField!
    
    func loginUser(login: String, hash: String, callback: ((status: Int)->Void)?){
        
        let parameters = [
            "login": login,
            "hash": hash,
            "value": 0
        ]
        
        Alamofire.request(.GET, serverURL, parameters: parameters as? [String : AnyObject], encoding: .JSON)
            .responseString{ response in
                if response.response == nil{
                    callback!(status: CONNECTION_ERROR)
                } else {
                    callback?(status: (response.response?.statusCode)!)
                }
        }
    }
    
    
    @IBAction func loginButton(sender: AnyObject) {
        let login = loginTextBox.text
        let pass = passwordTextBox.text
        let hash = pass
        userName = login!
        let vc = ViewController(nibName: "LogInViewController", bundle: nil)
        self.presentViewController(vc, animated: true, completion: nil)
        
    }
    
    @IBAction func registerButton(sender: AnyObject) {
    }
    
    @IBOutlet weak var registerButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
