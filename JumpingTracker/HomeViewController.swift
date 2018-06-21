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
import CoreData
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
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var loginSuccess: Bool = false
    var passwordItems: [KeychainPasswordItem] = []
    let userDefault = UserDefaults.standard
    var firstName: String = ""
    let opQueue: OperationQueue = OperationQueue()
    var jtView: UIView!
    var jumpingTrackerLabel: UILabel!
    
    
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
    @IBOutlet var firstView: UIView!
    
    @IBAction func registerButtonTapped(_ sender: UIButton) {
    }
    @IBAction func notXButtonTapped(_ sender: UIButton) {
        userDefault.set(nil, forKey: "UID")
        userDefault.set(false, forKey: "loginSuccessful")
        loginSuccess = false
        perform(#selector(flip), with: nil, afterDelay: 1)
        
    }
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        activityIndicator.startAnimating()
        view.endEditing(true)
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
        print("view did load homeviewController")
        // Do any additional setup after loading the view, typically from a nib.
        setupAddTargetIsNotEmptyTextFields()
        setupLayout()
        getTaxonomies()
        
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
        jtView = UIView(frame: CGRect(x: (self.view.frame.width / 2) - 150, y: 70, width: 300, height: 50))
        jtView.center.x = self.view.center.x
        print("viewDidDisappear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppUtility.lockOrientation(.portrait)
        print("viewDidAppear")
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
    
    // MARK: - get taxonomies
    func getTaxonomies() {
        let taxRequestOperation = BlockOperation {
            print("request taxonomies...")
            Thread.printCurrent()
            let username = "swift_username_request_data"
            let password = "JTIsabelle29?"
            let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            
            print("Requesting Disciplines JSON")
            self.requestDisciplines(header: headers, completion: { (result) in
                print("Casting disciplines...")
                self.appDelegate.persistentContainer.performBackgroundTask { (context) in
                    Thread.printCurrent()
                    for items in result as [Disciplines] {
                        let disciplines: Discipline = NSEntityDescription.insertNewObject(forEntityName: "CoreDisciplines", into: context) as! Discipline
                        disciplines.allAtributes = items
                    }
                    do {
                        try context.save()
                    } catch {
                        print("Could not save disciplines")
                        
                    }
                }
            })
            
            print("Requesting Event types JSON")
            self.requestEventTypes(header: headers, completion: { (result) in
                print("Casting event types...")
                self.appDelegate.persistentContainer.performBackgroundTask { (context) in
                    Thread.printCurrent()
                    for items in result as [EventTypes] {
                        let eventtypes: EventType = NSEntityDescription.insertNewObject(forEntityName: "CoreEventTypes", into: context) as! EventType
                        eventtypes.allAtributes = items
                    }
                    do {
                        try context.save()
                    } catch {
                        print("Could not save disciplines")
                        
                    }
                }
            })
            self.requestCoatColors(header: headers, completion: { (result) in
                self.appDelegate.persistentContainer.performBackgroundTask { (context) in
                Thread.printCurrent()
                for items in result as [CoatColors] {
                    let coatcolors: CoatColor = NSEntityDescription.insertNewObject(forEntityName: "CoreCoatColors", into: context) as! CoatColor
                    coatcolors.allAtributes = items
                }
                do {
                    try context.save()
                } catch {
                    print("Could not save coat colors")
                    
                    }
                    
                }
            })
            
            self.requestGenders(header: headers, completion: { (result) in
                self.appDelegate.persistentContainer.performBackgroundTask { (context) in
                    Thread.printCurrent()
                    for items in result as [Genders] {
                        let genders: Gender = NSEntityDescription.insertNewObject(forEntityName: "CoreGender", into: context) as! Gender
                        genders.allAtributes = items
                    }
                    do {
                        try context.save()
                    } catch {
                        print("Could not save genders")
                    }
                }
            })
            
            self.requestYears(header: headers, completion: { (result) in
                self.appDelegate.persistentContainer.performBackgroundTask { (context) in
                    Thread.printCurrent()
                    for items in result as [Years] {
                        let years: Year = NSEntityDescription.insertNewObject(forEntityName: "CoreJaartallen", into: context) as! Year
                        years.allAtributes = items
                    }
                    do {
                        try context.save()
                    } catch {
                        print("Could not save years")
                        
                    }
                }
            })
            
            self.requestStudbooks(header: headers, completion: { (result) in
                // Store to core data
                self.appDelegate.persistentContainer.performBackgroundTask { (context) in
                    Thread.printCurrent()
                    for items in result as [Studbooks] {
                        let studbook: Studbook = NSEntityDescription.insertNewObject(forEntityName: "CoreStudbooks", into: context) as! Studbook
                        studbook.allAtributes = items
                    }
                    do {
                        try context.save()
                    } catch {
                        print("Could not save studbooks")
                        
                    }
                }
            })
            
            self.requestOrganisators(header: headers, completion: { (result) in
                // Store to core data
                self.appDelegate.persistentContainer.performBackgroundTask { (context) in
                    Thread.printCurrent()
                    for items in result as [Organisators] {
                        let organisator: Organisator = NSEntityDescription.insertNewObject(forEntityName: "CoreOrganisators", into: context) as! Organisator
                        organisator.allAtributes = items
                    }
                    do {
                        try context.save()
                    } catch {
                        print("Could not save studbooks")
                        
                    }
                }
            })
        }
        opQueue.addOperation(taxRequestOperation)
    }
    
    // MARK: - request functions
    func requestStudbooks(header: Dictionary<String, String>, completion: @escaping([Studbooks]) -> ()) {
        if ConnectionCheck.isConnectedToNetwork() {
            print("Getting Studbooks from server...")
            let urlString = "https://jumpingtracker.com/rest/export/json/studbooks?_format=json"
            Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
                .validate(statusCode: 200..<299)
                .validate(contentType: ["application/json"])
                .responseData(completionHandler: { (response) in
                    
                    switch(response.result) {
                    case .success:
                        if response.result.value != nil {
                            do {
                                let studbook: [Studbooks] = try JSONDecoder().decode([Studbooks].self, from: response.data!)
                                
                                completion(studbook)
                                print("studbook decoded")
                            } catch {
                                print("Could not decode studbook")
                            }
                        }
                        break
                    case .failure(let error):
                        print("Request to authenticate failed with error: \(error)")
                        print("error code: \(error)")
                        break
                    }
                    
                })
        } else {
            print("Not connected")
        }
    }
    
    
    func requestYears(header: Dictionary<String, String>, completion: @escaping ([Years]) -> ()) {
        let urlString = "https://jumpingtracker.com/rest/export/json/jaartallen?_format=json"
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData(completionHandler: { (response) in
                
                switch(response.result) {
                case .success:
                    if response.result.value != nil {
                        print("Response: \(response)")
                        
                        do {
                            let years: [Years] = try JSONDecoder().decode([Years].self, from: response.data!)
                            
                            completion(years)
                            print("years decoded")
                        } catch {
                            print("Could not decode years")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    break
                }
            })
    }
    
    func requestGenders(header: Dictionary<String, String>, completion: @escaping ([Genders]) -> ()) {
        let urlString = "https://jumpingtracker.com/rest/export/json/gender?_format=json"
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData(completionHandler: { (response) in
                
                switch(response.result) {
                case .success:
                    if response.result.value != nil {
                        print("Response: \(response)")
                        do {
                            let genders: [Genders] = try JSONDecoder().decode([Genders].self, from: response.data!)
                            
                            completion(genders)
                            print("genders decoded")
                        } catch {
                            print("Could not decode genders")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    break
                }
            })
    }
    
    func requestCoatColors(header: Dictionary<String, String>, completion: @escaping ([CoatColors]) -> ()) {
        let urlString = "https://jumpingtracker.com/rest/export/json/coatcolors?_format=json"
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData(completionHandler: { (response) in
                
                switch(response.result) {
                case .success:
                    if response.result.value != nil {
                        print("Response: \(response)")
                        do {
                            let coatcolors: [CoatColors] = try JSONDecoder().decode([CoatColors].self, from: response.data!)
                            
                            completion(coatcolors)
                            print("coatcolors decoded")
                        } catch {
                            print("Could not decode coatcolors")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    break
                }
            })
    }
    
    func requestDisciplines(header: Dictionary<String, String>, completion: @escaping ([Disciplines]) -> ()) {
        let urlString = "https://jumpingtracker.com/rest/export/json/disciplines?_format=json"
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData(completionHandler: { (response) in
                
                switch(response.result) {
                case .success:
                    if response.result.value != nil {
                        print("Response: \(response)")
                        do {
                            let disciplines: [Disciplines] = try JSONDecoder().decode([Disciplines].self, from: response.data!)
                            
                            completion(disciplines)
                            print("disciplines decoded")
                        } catch {
                            print("Could not decode disciplines")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    break
                }
            })
    }
    
    func requestOrganisators(header: Dictionary<String, String>, completion: @escaping ([Organisators]) -> ()) {
        let urlString = "https://jumpingtracker.com/rest/export/json/organisations?_format=json"
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData(completionHandler: { (response) in
                
                switch(response.result) {
                case .success:
                    if response.result.value != nil {
                        print("Response: \(response)")
                        do {
                            let organisators: [Organisators] = try JSONDecoder().decode([Organisators].self, from: response.data!)
                            
                            completion(organisators)
                            print("organisators decoded")
                        } catch {
                            print("Could not decode organisators")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    break
                }
            })
    }
    
    func requestEventTypes(header: Dictionary<String, String>, completion: @escaping ([EventTypes]) -> ()) {
        let urlString = "https://jumpingtracker.com/rest/export/json/event_types?_format=json"
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData(completionHandler: { (response) in
                
                switch(response.result) {
                case .success:
                    if response.result.value != nil {
                        print("Response: \(response)")
                        do {
                            let eventtypes: [EventTypes] = try JSONDecoder().decode([EventTypes].self, from: response.data!)
                            
                            completion(eventtypes)
                            print("disciplines decoded")
                        } catch {
                            print("Could not decode disciplines")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    break
                }
            })
    }
    // MARK: - verify account
    func verifyAccount() {
        print("verifying")
        if ConnectionCheck.isConnectedToNetwork() {
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
                
                self.requestJSON("https://jumpingtracker.com/user/\(uid!)?_format=json", headers: headers, completion: { (result) in
                    self.userDefault.set(true, forKey: "loginSuccessful")
                    self.loginSuccess = true
                    self.activityIndicator.stopAnimating()
                    self.showLogin()
                    
                    //let fetchRequest =
                    self.appDelegate.persistentContainer.performBackgroundTask({ (context) in
                        //let firstname: CurrentUser =
                        for items in result as [User] {
                            let userdata: CurrentUser = NSEntityDescription.insertNewObject(forEntityName: "CoreCurrentUser", into: context) as! CurrentUser
                            userdata.allAtributes = items
                            self.userDefault.set(userdata.firstname!, forKey: "firstname")
                        }
                        do {
                            try context.save()
                        } catch {
                            print("Could not save coat colors")
                            
                        }
                        
                    })
                
                }, failure: { (error) in
                    print("UID failure.")
                    self.userDefault.set(false, forKey: "loginSuccessful")
                    self.loginSuccess = false
                    // Try again automatically
                    print("Retrying firstname retrieval.")
                    self.requestJSON("https://jumpingtracker.com/user/\(uid!)?_format=json", headers: headers, completion: { (result) in
                        self.userDefault.set(true, forKey: "loginSuccessful")
                        self.loginSuccess = true
                        self.activityIndicator.stopAnimating()
                        self.showLogin()
                        
                        self.appDelegate.persistentContainer.performBackgroundTask({ (context) in
                            for items in result as [User] {
                                let userdata: CurrentUser = NSEntityDescription.insertNewObject(forEntityName: "CoreCurrentUser", into: context) as! CurrentUser
                                userdata.allAtributes = items
                                self.userDefault.set(userdata.firstname, forKey: "firstname")
                            }
                            do {
                                try context.save()
                            } catch {
                                print("Could not save coat colors")
                                
                            }
                            
                        })
                    }, failure: { (error) in
                        print("Repeat failure")
                        self.userDefault.set(false, forKey: "loginSuccessful")
                        self.loginSuccess = false
                        self.activityIndicator.stopAnimating()
                        self.loginView.shake()
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
                    //print("decoded: \(decoded)")
                    let uid = decoded["drupal"]["uid"].stringValue
                    print("UID = \(uid)")
                    self.userDefault.set(uid, forKey: "UID")
                    //let headerWithToken = ["Authorization": "Bearer: \(token)", "Cache-Control": "no-cache"]
                    success(uid, token)
                    break
                case .failure(let error):
                    print("Token request failed with error: \(error)")
                    failure(error)
                    //self.showLoginFailedAlert()
                    
                
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
                    break
                }
            
        }
    }
    
    func requestJSON(_ urlString: String, headers: Dictionary<String, String>, completion: @escaping (_ result: [User]) -> Void, failure: @escaping (_ error: Error?) -> Void)  {
        print("Requesting JSON...")
        
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<299)
            .validate(contentType: ["application/json"])
            .responseJSON(completionHandler: { (response) in
                if response.result.value == nil {
                    print("No response!")
                }
                print("response result = \(response.result)")
                switch(response.result) {
                case .success(let value):
                    let swiftyJSON = JSON(value)
                    let firstname = swiftyJSON["field_firstname"][0]["value"].stringValue
                    let surname = swiftyJSON["field_surname"][0]["value"].stringValue
                    
                    self.userDefault.set(firstname, forKey: "firstname")
                    self.userDefault.set(surname, forKey: "surname")
                case .failure(let error):
                    print("failed fetching firstname: \(error)")
                }
            })
            .responseData(completionHandler: { (response) in
                
                switch(response.result) {
                case .success:
                    //print("data: \(response.data!)")
                    if response.result.value != nil {
                        
                        do {
                            let userData: User = try JSONDecoder().decode(User.self, from: response.data!)
                            print("userdata decoded")
                            completion([userData])
                        } catch let error {
                            print("Could not decode userdata: \(error)")
                        }
                    }
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
            
            
        })
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
        // Create JumpingTracker View
        jtView = UIView(frame: CGRect(x: 20, y: 60, width: 300, height: 50))
        jtView.center.x = self.view.center.x
        jtView.layer.cornerRadius = 22
        jtView.sizeToFit()
        // Create JumpingTracker Label
        jumpingTrackerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
        jumpingTrackerLabel.text = "Jumping Tracker"
        jumpingTrackerLabel.font = UIFont.systemFont(ofSize: 36, weight: .semibold)
        //jumpingTrackerLabel.sizeToFit()
        jumpingTrackerLabel.layer.cornerRadius = 22
        jumpingTrackerLabel.layer.masksToBounds = true
        //jumpingTrackerLabel.center = self.view.center
        //jumpingTrackerLabel.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        jumpingTrackerLabel.textAlignment = .center
        jtView.addSubview(jumpingTrackerLabel)
        self.view.addSubview(jtView)
        
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
    func fetchFirstname() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreCurrentUser")
        //fetchRequest.predicate = NSPredicate(format: "uid == %@", self.userDefault.value(forKey: "UID") as! CVarArg)
        do {
            let results = try self.appDelegate.getContext().fetch(fetchRequest) as! [CurrentUser]
            for item in results {
                let firstname: String = item.firstname!
                self.userDefault.set(firstname, forKey: "firstname")
            }
        } catch {
            print("Could not catch firstname")
        }
    }
    
    func showLogin() {
        print("show Login?")
        print("userDefault: \(userDefault.bool(forKey: "loginSuccessful"))")
        print("loginSuccess: \(loginSuccess)")
        if userDefault.bool(forKey: "loginSuccessful") {
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
            jtView.frame = CGRect(x: (self.view.frame.width / 2) - 150, y: 70, width: 300, height: 50)
            //jtView = UIView(frame: CGRect(x: 20, y: 70, width: 300, height: 50))
            //jtView.center.x = self.view.center.x
            loginView.isHidden = false
            welcomeLabel.isHidden = true
            notXButton.isHidden = true
            usernameLabel.isHidden = true
        }
    }
    
    @objc func flip() {
        let transitionOptions: UIViewAnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        UIView.transition(with: self.view, duration: 1.0, options: transitionOptions, animations: {
            self.view.isHidden = true
        }, completion: { (finished: Bool) in
            self.showHide()
            
        })
        UIView.transition(with: self.view, duration: 1.0, options: transitionOptions, animations: {
            self.view.isHidden = false
        }, completion: nil)
    }
    
    func showHide() {
        jtView.frame = CGRect(x: (self.view.frame.width / 2) - 150, y: 70, width: 300, height: 50)
        //jtView = UIView(frame: CGRect(x: 20, y: 70, width: 300, height: 50))
        //jtView.center.x = self.view.center.x
        self.loginView.isHidden = false
        self.welcomeLabel.isHidden = true
        self.notXButton.isHidden = true
        self.usernameLabel.isHidden = true
        
    }

    func animateJumpingTracker() {
        print("animating jumping tracker")
        UIView.animate(withDuration: 2.0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .curveLinear, animations: {
            self.jtView.setGradientBackground()
            self.jtView.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height - 150)

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
    func shake() { // left to right
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 10, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 10, y: self.center.y))
        self.layer.add(animation, forKey: "position")
    }
    
    func pulsate() {
        let pulse = CASpringAnimation(keyPath: "transfrom.scale")
        pulse.duration = 0.6
        pulse.fromValue = 0.90
        pulse.toValue = 1.10
        pulse.autoreverses = true
        pulse.repeatCount = 1
        pulse.initialVelocity = 0.5
        pulse.damping = 0.6
        layer.add(pulse, forKey: "pulse")
    }
    func setGradientBackground() {
        let colorTop = UIColor.white.withAlphaComponent(0.0).cgColor
        let colorBottom = UIColor.white.cgColor
        let gradientLayer = CAGradientLayer()
        //gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        //gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.colors = [colorTop, colorBottom, colorBottom, colorTop]
        gradientLayer.locations = [0.0, 0.4, 0.6, 1.0]
        gradientLayer.frame = self.bounds
        gradientLayer.masksToBounds = true
        gradientLayer.cornerRadius = 22
        //self.layer.addSublayer(gradientLayer)
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
}

