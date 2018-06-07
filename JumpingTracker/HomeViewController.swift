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

struct KeychainConfiguration {
    static let serviceName = "GetMeLive"
    static let accessGroup: String? = nil
}

struct AppUtility {
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientationMask) {
        self.lockOrientation(orientation)
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
    }
}
class HomeViewController: UIViewController {
    let dataRequest = DataRequest()
    var loginSuccess: Bool = false
    var passwordItems: [KeychainPasswordItem] = []
    let userDefault = UserDefaults.standard
    var firstName: String = ""
    let opQueue = OperationQueue()
    var response: URLResponse?
    var session: URLSession?
    var jumpingTrackerLabel: UILabel!
    //var headers: HTTPHeaders = ["Content-Type": "application/json"]
    
    var time: DispatchTime! {
        return DispatchTime.now() + 1.0 // seconds
    }
    // MARK: - Outlets
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var notXButton: UIButton!
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
        activityIndicator.startAnimating()
        userDefault.set(usernameField.text, forKey: "Username")
        do {
            // This is a new account, create a new keychain item with the account name.
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                                    account: usernameField.text!,
                                                    accessGroup: KeychainConfiguration.accessGroup)
            
            // Save the password for the new item.
            try passwordItem.savePassword(passwordField.text!)
        } catch {
            fatalError("Error updating keychain - \(error)")
        }
        
        // remove next line when keychain works
        //userDefault.set(passwordField.text, forKey: "Password")
        
        verifyAccount()
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupAddTargetIsNotEmptyTextFields()
        setupLayout()
        usernameField.text = "iverelst"
        passwordField.text = "hateandwar"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppUtility.lockOrientation(.all)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        jumpingTrackerLabel.center = CGPoint(x: self.view.frame.width / 2, y: 70)
        print("viewDidDisappear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppUtility.lockOrientation(.portrait)
        print("viewDidAppear")
        print(self.view.bounds.size.height)
        showLogin()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Check if previously logged in
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
    
    
    func requestTaxonomies() {
        print("requesting taxonomies")
        if ConnectionCheck.isConnectedToNetwork() {
            self.opQueue.isSuspended = true
            
            let taxonomies: Array<String> = ["jaartallen", "studbooks", "disciplines"]
            for tax in taxonomies {
                print("get tax for \(tax)")
                dataRequest.getTaxonomy("https://jumpingtracker.com/rest/export/json/\(tax)?_format=json", tax: tax, completion: { result -> () in
                    // Update UI or store result
                    
                    self.userDefault.set(result, forKey: tax)
                })
            }
            
            DispatchQueue.main.asyncAfter(deadline: self.time, execute: {[weak self] in
                print("Opening the OperationQueue")
                self?.opQueue.isSuspended = false
            })
        } else {
            print("Not connected")
        }
    }
    // MARK: - verify account
    func verifyAccount() {
        print("verifying")
        if ConnectionCheck.isConnectedToNetwork() {
            self.opQueue.isSuspended = true
            // Authenticate with server (OAuth 2.0?)
            // Communicate with server to get user id etc.
            // Store Name, user id, etc. in userDefault
            let username = userDefault.string(forKey: "Username")
            let password = getPasswordFromKeychain(username!)

            let credentialData = "\(username!):\(password)".data(using: String.Encoding.utf8)!
            //let userCredential = URLCredential(user: username!, password: password!, persistence: .permanent)
            //let protectionSpace = URLProtectionSpace.init(host: "jumpingtracker.com", port: 80, protocol: "http", realm: "Restricted", authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
            let base64Credentials = credentialData.base64EncodedString(options: [])
            //URLCredentialStorage.shared.setDefaultCredential(userCredential, for: protectionSpace)
            
            // 1. Client logs in (or requests a JWT directly from the provider)
            // 2. A digitally-signed JWT is created with the secret key
            // 3. A JWT is returned that contains information about the client. Store the token
            
            let loginRequest = ["username": username!, "password": password as Any]
            let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            /*
            if let authorizationHeader = Request.authorizationHeader(user: username!, password: password!) {
                headers[authorizationHeader.key] = authorizationHeader.value
            }
            */
            requestToken(parameters: loginRequest, headers: headers, success: { (uid, token) in
                self.userDefault.set(token, forKey: "token")
                print("Token successfully received!")
                print("Token: \(token!)")
                print("uid: \(uid!)")
                self.requestTaxonomies()
                self.requestJSON("https://jumpingtracker.com/user/\(uid!)?_format=json", headers: headers, success: { (firstname) in
                    print("firstname: \(firstname!)")
                    self.userDefault.set(firstname, forKey: "firstname")
                    self.userDefault.set(true, forKey: "loginSuccessful")
                    self.loginSuccess = true
                    self.activityIndicator.stopAnimating()
                    self.showLogin()
                }, failure: { (error) in
                    print("UID failure.")
                    self.userDefault.set(false, forKey: "loginSuccessful")
                    self.loginSuccess = false
                    // Try again automatically
                    print("Retrying firstname retrieval.")
                    self.requestJSON("https://jumpingtracker.com/user/\(uid!)?_format=json", headers: headers, success: { (firstname) in
                        print("firstname: \(firstname!)")
                        self.userDefault.set(firstname, forKey: "firstname")
                        self.userDefault.set(true, forKey: "loginSuccessful")
                        self.loginSuccess = true
                        self.activityIndicator.stopAnimating()
                        self.showLogin()
                    }, failure: { (error) in
                        print("UID failure.")
                        self.userDefault.set(false, forKey: "loginSuccessful")
                        self.loginSuccess = false
                        self.activityIndicator.stopAnimating()
                        self.showLoginFailedAlert("Login successful, but could not retreive user data.\nTry again later.")
                        
                    })
                })
            }, failure: { (error) in
                print("Token failure")
                self.userDefault.set(false, forKey: "loginSuccessful")
                self.loginSuccess = false
                self.activityIndicator.stopAnimating()
                self.loginView.shake()
            })
            
            //requestTokenWithBasicAuth()
            // 4. On each request, the JWT should be sent in the "Authorization" header
            // Authorization: Bearer <token>
            
            // 5. The JWT is verified and validated. If the JWT has expired, a new one should be requested
            // 6. If validated, the response gets returned to the client.
            //let headerWithToken = ["Authorization": "Bearer: \(self.token)", "Cache-Control": "no-cache"]
            

            // Open the operations queue after 1 second
            DispatchQueue.main.asyncAfter(deadline: self.time, execute: {[weak self] in
                print("Opening the OperationQueue")
                self?.opQueue.isSuspended = false
            })
        } else {
            print("No internet Connection")
        }
    }
    
    
    // MARK: - Data requests
    func requestToken(parameters: Dictionary<String, Any>, headers: Dictionary<String, String>, success: @escaping (_ uid: String?, _ token: String?) -> Void, failure: @escaping (_ error: Error?) -> Void) {
        // Working! Do not touch!
        print("Requesting token...")
        Alamofire.request("https://jumpingtracker.com/jwt/token", method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<299)
            .responseJSON { (response) in
                if response.result.value == nil {
                    print("No response!")
                }
                print("response result = \(response.result)")
                switch(response.result) {
                case .success(let value):
                    let swiftyJSON = JSON(value)
                    let token = swiftyJSON["token"].stringValue
                    self.userDefault.set(token, forKey: "JWT_token")
                    let decoded = JSON(self.decode(jwtToken: token))
                    let uid = decoded["drupal"]["uid"].stringValue
                    print("UID = \(uid)")
                    self.userDefault.set(uid, forKey: "UID")
                    //let headerWithToken = ["Authorization": "Bearer: \(token)", "Cache-Control": "no-cache"]
                    success(uid, token)
                    break
                case .failure(let error):
                    print("Request failed with error: \(error)")
                    failure(error)
                    //self.showLoginFailedAlert()
                    break
                }
                guard case let .failure(error) = response.result else { return }
            
            if let error = error as? AFError {
                switch error {
                case .invalidURL(let url):
                    print("Invalid URL: \(url) - \(error.localizedDescription)")
                case .parameterEncodingFailed(let reason):
                    print("Parameter encoding failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                case .multipartEncodingFailed(let reason):
                    print("Multipart encoding failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                case .responseValidationFailed(let reason):
                    self.loginView.shake()

                    print("Response validation failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                    
                    switch reason {
                    case .dataFileNil, .dataFileReadFailed:
                        print("Downlaoded file could not be read")
                    case .missingContentType(let acceptableContentTypes):
                        print("Content Type Missing: \(acceptableContentTypes)")
                    case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                        print("Response content type: \(responseContentType) was uncacceptable: \(acceptableContentTypes)")
                    case .unacceptableStatusCode(let code):
                        print("Response status code was unacceptable: \(code)")
                    }
                case .responseSerializationFailed(let reason):
                    print("Response serialization failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                }
                print("Underlying error: \(String(describing: error.underlyingError))")
            } else if let error = error as? URLError {
                print("URLError occurred: \(error)")
            } else {
                print("Unknown error: \(error)")
            }
            
            
        }
    }
    
    func requestJSON(_ urlString: String, headers: Dictionary<String, String>, success: @escaping (_ firstname: String?) -> Void, failure: @escaping (_ error: Error?) -> Void)  {
        print("Requesting JSON...")
        
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<299)
            .validate(contentType: ["application/json"])
            .responseJSON { (response) in
                if response.result.value == nil {
                    print("No response")
                }
                switch(response.result) {
                case .success(let value):
                    let swiftyJSON = JSON(value)
                    let firstname = swiftyJSON["field_firstname"][0]["value"].stringValue
                    let surname = swiftyJSON["field_surname"][0]["value"].stringValue
                    
                    self.userDefault.set(firstname, forKey: "firstname")
                    self.userDefault.set(surname, forKey: "surname")
                    success(firstname)
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    failure(error)
                    break
                }
            guard case let .failure(error) = response.result else { return }
            
            if let error = error as? AFError {
                switch error {
                case .invalidURL(let url):
                    print("Invalid URL: \(url) - \(error.localizedDescription)")
                case .parameterEncodingFailed(let reason):
                    print("Parameter encoding failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                case .multipartEncodingFailed(let reason):
                    print("Multipart encoding failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                case .responseValidationFailed(let reason):
                    print("Response validation failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                    self.loginView.shake()

                    switch reason {
                    case .dataFileNil, .dataFileReadFailed:
                        print("Downlaoded file could not be read")
                    case .missingContentType(let acceptableContentTypes):
                        print("Content Type Missing: \(acceptableContentTypes)")
                    case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                        print("Response content type: \(responseContentType) was uncacceptable: \(acceptableContentTypes)")
                    case .unacceptableStatusCode(let code):
                        print("Response status code was unacceptable: \(code)")
                    }
                case .responseSerializationFailed(let reason):
                    print("Response serialization failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                }
                print("Underlying error: \(String(describing: error.underlyingError))")
            } else if let error = error as? URLError {
                print("URLError occurred: \(error)")
            } else {
                print("Unknown error: \(error)")
            }
            
            
        }
    }
    
    // MARK: - Decode JWT
    func decode(jwtToken jwt: String) -> [String: Any] {
        let segments = jwt.components(separatedBy: ".")
        return decodeJWTPart(segments[1]) ?? [:]
    }
    
    func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 = base64 + padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
    
    func decodeJWTPart(_ value: String) -> [String: Any]? {
        guard let bodyData = base64UrlDecode(value), let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
                return nil
        }
        
        return payload
    }
    
    // MARK: - login failed alert
    private func showLoginFailedAlert(_ message: String) {
        let alertView = UIAlertController(title: "Login Problem",
                                          message: message,
                                          preferredStyle:. alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertView.addAction(okAction)
        present(alertView, animated: true)
    }
    
    func getPasswordFromKeychain(_ account: String) -> String {
        do {
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                                    account: account,
                                                    accessGroup: KeychainConfiguration.accessGroup)
            let keychainPassword = try passwordItem.readPassword()
            return keychainPassword
        } catch {
            //fatalError("Error reading password from keychain - \(error)")
            print("Error reading password from keychain - \(error)")
            return "blablabla"
        }
    }
    
    
    // MARK: - setup layout
    func setupLayout() {
        // Create JumpingTracker Label
        jumpingTrackerLabel = UILabel()
        jumpingTrackerLabel.text = "Jumping Tracker"
        jumpingTrackerLabel.font = UIFont.systemFont(ofSize: 36, weight: .semibold)
        jumpingTrackerLabel.sizeToFit()
        jumpingTrackerLabel.layer.cornerRadius = 5
        jumpingTrackerLabel.layer.masksToBounds = true
        jumpingTrackerLabel.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        jumpingTrackerLabel.center = CGPoint(x: self.view.frame.width / 2, y: 70)
        view.addSubview(jumpingTrackerLabel)
        
        welcomeLabel.isHidden = true
        notXButton.isHidden = true
        usernameLabel.isHidden = true
        loginTitle.layer.masksToBounds = true
        loginTitle.layer.cornerRadius = 5
        loginView.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        
        usernameField.layer.borderColor = UIColor.FlatColor.Blue.BlueWhale.cgColor
        usernameField.layer.borderWidth = 1.5
        usernameField.layer.cornerRadius = 10
        usernameField.layer.masksToBounds = true
        usernameField.tintColor = UIColor.FlatColor.Gray.Iron
        
        passwordField.layer.borderColor = UIColor.FlatColor.Blue.BlueWhale.cgColor
        passwordField.layer.borderWidth = 1.5
        passwordField.layer.cornerRadius = 10
        passwordField.layer.masksToBounds = true
        passwordField.tintColor = UIColor.FlatColor.Gray.IronGray
        
        loginButton.layer.cornerRadius = 10
        loginButton.layer.borderWidth = 1.5
        loginButton.layer.borderColor = UIColor.FlatColor.Blue.BlueWhale.cgColor
        loginButton.backgroundColor = UIColor.FlatColor.Blue.Denim
        loginButton.layer.masksToBounds = true
        loginButton.tintColor = UIColor.white
        loginButton.isEnabled = false
        loginButton.alpha = 0.5
        
        registerButton.layer.cornerRadius = 10
        registerButton.layer.borderWidth = 1.5
        registerButton.layer.borderColor = UIColor.FlatColor.Blue.BlueWhale.cgColor
        registerButton.backgroundColor = UIColor.FlatColor.Blue.Denim
        registerButton.layer.masksToBounds = true
        registerButton.tintColor = UIColor.white
        
        activityIndicator.stopAnimating()
    }
    
    func showLogin() {
        print("show Login?")
        print("userDefault: \(userDefault.bool(forKey: "loginSuccessful"))")
        print("loginSuccess: \(loginSuccess)")
        if loginSuccess {
            loginView.isHidden = true
            print("user previously logged in!")
            if userDefault.string(forKey: "firstname") != nil && userDefault.string(forKey: "firstname") != "" {
                let username = userDefault.string(forKey: "firstname")!
                usernameLabel.text = username.lowercased()
                notXButton.setTitle("not \(username)?", for: .normal)
            } else {
                usernameLabel.text = ""
                notXButton.setTitle("Login", for: .normal)
            }
            animateJumpingTracker()
        } else {
            
            loginView.isHidden = false
            welcomeLabel.isHidden = true
            notXButton.isHidden = true
            usernameLabel.isHidden = true
        }
    }
    

    func animateJumpingTracker() {
        print("animating jumping tracker")
        UIView.animate(withDuration: 2.0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .curveLinear, animations: {
            self.jumpingTrackerLabel.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height - 150)

        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.5, options: .showHideTransitionViews, animations: {
                self.welcomeLabel.isHidden = false
                self.usernameLabel.isHidden = false
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 2.0, options: .showHideTransitionViews, animations: {
                    self.notXButton.isHidden = false
                }, completion: nil)
            
            })
        })
    }
}

extension UIView {
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 10, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 10, y: self.center.y))
        self.layer.add(animation, forKey: "position")
    }
}
