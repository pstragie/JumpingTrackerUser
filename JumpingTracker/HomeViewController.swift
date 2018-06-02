//
//  FirstViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 29/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
import SwiftyJSON

class HomeViewController: UIViewController {

    var token: String = ""
    let userDefault = UserDefaults.standard
    let opQueue = OperationQueue()
    var response: URLResponse?
    var session: URLSession?
    
    var time: DispatchTime! {
        return DispatchTime.now() + 1.0 // seconds
    }
    // MARK: - Outlets
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var notXButton: UIButton!
    @IBOutlet weak var JumpingTracker: UILabel!
    @IBOutlet weak var JumpingTrackerLabelConstraintY: NSLayoutConstraint!
    @IBOutlet weak var loginTitle: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginView: UIView!
    
    @IBAction func registerButtonTapped(_ sender: UIButton) {
    }
    @IBAction func notXButtonTapped(_ sender: UIButton) {
        loginView.isHidden = false
        welcomeLabel.isHidden = true
        notXButton.isHidden = true
        usernameLabel.isHidden = true
    }
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        userDefault.set(usernameField.text, forKey: "Username")
        userDefault.set(passwordField.text, forKey: "Password")
        verifyAccount()
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupAddTargetIsNotEmptyTextFields()
        setupLayout()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.JumpingTracker.center.y = 40
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 2.0, delay: 0.5, usingSpringWithDamping: 0.1, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.JumpingTracker.center.y = self.view.bounds.height - 200
        }, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - enable login button when fields are filled
    func setupAddTargetIsNotEmptyTextFields() {
        loginButton.isEnabled = false
        usernameField.addTarget(self, action: #selector(textFieldIsNotEmpty), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(textFieldIsNotEmpty), for: .editingChanged)
    }
    
    @objc func textFieldIsNotEmpty(sender: UITextField) {
        sender.text = sender.text?.trimmingCharacters(in: .whitespaces)
        
        guard
            let username = usernameField.text, !username.isEmpty,
            let password = passwordField.text, !password.isEmpty
            else
        {
                self.loginButton.isEnabled = false
                self.loginButton.alpha = 0.5
                return
        }
        loginButton.isEnabled = true
        loginButton.alpha = 1.0
    }
    
    
    // MARK: - verify account
    func verifyAccount() {
        print("verifying")
        if ConnectionCheck.isConnectedToNetwork() {
            self.opQueue.isSuspended = true
            // Authenticate with server (OAuth 2.0?)
            // Communicate with server to get user id etc.
            // Store Name, user id, etc. in userDefault
            let username = userDefault.string(forKey: "Username") as Any
            let password = userDefault.string(forKey: "Password") as Any
            //let loginString = String(format: "%@:%@", username as! String, password as! String)
            //let loginData = loginString.data(using: String.Encoding.utf8)!
            let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            //let base64LoginString = loginData.base64EncodedString()
            //let headers = ["Authorization": "Basic \(base64Credentials)"]
            // create the request
            let urlString = "https://jumpingtracker.com/rest/export/json/userinfo"
            //guard let url = URL(string: urlString) else { return }
            let loginRequest = ["user": username, "password": password]
            Alamofire.request(urlString, method: .get).authenticate(user: username as! String, password: password as! String).responseJSON { (response) in
                if response.result.value != nil {
                    print("response: \(response)")
                }
                switch(response.result) {
                case .success(let value):
                    print("authenticate value: \(value)")
                    let swiftyJSON = JSON(value)
                    print(swiftyJSON)
                    let name = swiftyJSON["uid"].stringValue
                    print("UID = \(name)")
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    break
                }
            }
            Alamofire.request("https://jumpingtracker.com/rest/session/token", method: .get, parameters: loginRequest, encoding: JSONEncoding.default, headers: nil).validate().responseString { (response) in
                if response.result.value != nil {
                    print("response: \(response)")
                }
                switch(response.result) {
                case .success(let value):
                    print("get value: \(value)")
                    self.token = value
                    break
                case .failure(let error):
                    print("Request to get failed with error: \(error)")
                    break
                }
            }
        
            Alamofire.request(urlString, method: .post, parameters: loginRequest, encoding: JSONEncoding.default, headers: nil).validate().responseJSON { (response) in
                if response.result.value != nil {
                    print("response: \(response)")
                }
                switch(response.result) {
                case .success(let value):
                    print("post value: \(value)")
                    let swiftyJSON = JSON(value)
                    print(swiftyJSON)
                    let name = swiftyJSON["uid"].stringValue
                    print("UID = \(name)")
                    break
                case .failure(let error):
                    print("Request to post failed with error: \(error)")
                    break
                }
            }
            // Open the operations queue after 1 second
            DispatchQueue.main.asyncAfter(deadline: self.time, execute: {[weak self] in
                print("Opening the OperationQueue")
                self?.opQueue.isSuspended = false
            })
        } else {
            print("No internet Connection")
        }
    }
    
    
    // MARK: - setup layout
    func setupLayout() {
        usernameField.layer.borderColor = UIColor.FlatColor.Blue.Denim.cgColor
        usernameField.layer.borderWidth = 1.5
        usernameField.layer.cornerRadius = 10
        usernameField.layer.masksToBounds = true
        usernameField.tintColor = UIColor.FlatColor.Gray.Iron
        
        passwordField.layer.borderColor = UIColor.FlatColor.Blue.Denim.cgColor
        passwordField.layer.borderWidth = 1.5
        passwordField.layer.cornerRadius = 10
        passwordField.layer.masksToBounds = true
        passwordField.tintColor = UIColor.FlatColor.Gray.IronGray
        
        loginButton.layer.cornerRadius = 10
        loginButton.layer.borderWidth = 1.5
        loginButton.layer.borderColor = UIColor.FlatColor.Blue.PictonBlue.cgColor
        loginButton.backgroundColor = UIColor.FlatColor.Blue.Denim
        loginButton.layer.masksToBounds = true
        loginButton.tintColor = UIColor.white
        loginButton.isEnabled = false
        loginButton.alpha = 0.5
        
        registerButton.layer.cornerRadius = 10
        registerButton.layer.borderWidth = 1.5
        registerButton.layer.borderColor = UIColor.FlatColor.Blue.PictonBlue.cgColor
        registerButton.backgroundColor = UIColor.FlatColor.Blue.Denim
        registerButton.layer.masksToBounds = true
        registerButton.tintColor = UIColor.white
        
        // Check if previously logged in
        if userDefault.string(forKey: "Username") != nil && userDefault.string(forKey: "Password") != nil {
            loginView.isHidden = true
            let username = userDefault.string(forKey: "Username")!
            usernameLabel.text = username
            welcomeLabel.isHidden = false
            notXButton.setTitle("not \(username)?", for: .normal)
            notXButton.isHidden = false
            usernameLabel.isHidden = false
        } else {
            loginView.isHidden = false
            welcomeLabel.isHidden = true
            notXButton.isHidden = true
            usernameLabel.isHidden = true
        }
    }
}



