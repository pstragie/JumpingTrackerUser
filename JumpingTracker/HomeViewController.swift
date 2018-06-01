//
//  FirstViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 29/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    let userDefault = UserDefaults.standard
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
        // Authenticate with server (OAuth 2.0?)
        // Communicate with server to get user id etc.
        // Store Name, user id, etc. in userDefault
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

