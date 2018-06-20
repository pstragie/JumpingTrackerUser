//
//  EventsViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 29/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//


import UIKit
import Foundation
import Alamofire
import SwiftyJSON
import CoreData

class EventsViewController: UIViewController {
    
    // MARK: - Variables
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let opQueue: OperationQueue = OperationQueue()
    var eventDetailViewController: EventDetailViewController? = nil
    let userDefault = UserDefaults.standard
    let searchController = UISearchController(searchResultsController: nil)
    var splitFilteredEvents: Dictionary<String, [Events]> = ["passed":[], "upcoming":[]]
    var filteredEvents: [Events] = []
    var splitEvents: Dictionary<String, [Events]> = ["passed":[], "upcoming":[]]
    var events: [Events] = []
    var selected: Array<Bool> = [false, false, false]
    var disciplineDict: Dictionary<String, String> = [:]
    var originalCenter: CGPoint!
    var categoryAdd: String = ""
    var rightBarButtons: [UIBarButtonItem] = []
    private lazy var stackBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.FlatColor.Blue.Denim
        return view
    }()
    
    // MARK: - Outlets
    
    @IBOutlet weak var notLoggedInPopupView: UIView!
    @IBOutlet weak var noFavoritesPopupView: UIView!
    @IBOutlet weak var notLoggedInMessageTitleLabel: UILabel!
    @IBOutlet weak var eventKeyPopup: UIVisualEffectView!
    @IBOutlet weak var eventKeyPopupView: UIView!
    @IBOutlet weak var notLoggedInMessageLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var noFavoritesMessageTitleLabel: UILabel!
    @IBOutlet weak var noFavoritesMessageLabel: UILabel!
    @IBOutlet weak var eventKeyPopupMessageTitleLabel: UILabel!
    @IBOutlet weak var eventKeyCancelButton: UIButton!
    @IBOutlet weak var eventKeyPopupMessageLabel: UILabel!
    @IBOutlet weak var eventKeyVerifyButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var passphraseEventField: UITextField!
    
    @IBAction func passphraseSubmitButtonTapped(_ sender: UIButton) {
    }
    @IBOutlet var searchFooter: SearchFooter!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var syncLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableViewButtons: [UIButton]!
    @IBOutlet weak var favoriteEventsButton: UIButton!
    @IBOutlet weak var personalEventsButton: UIButton!
    @IBOutlet weak var notLoggedInPopup: UIVisualEffectView!
    @IBOutlet weak var noFavoritesPopup: UIVisualEffectView!
    
    @IBOutlet weak var stackViewButtons: UIStackView!
    @IBOutlet weak var allEventsButton: UIButton!
    
    @IBAction func passphraseCancelButtonTapped(_ sender: UIButton) {
        eventKeyPopup.alpha = 0
    }
    // MARK: - Outlet functions
    @IBAction func allEvents(_ sender: UIButton) {
        allEventsButtonClicked()
    }
    @IBAction func favoriteEvents(_ sender: UIButton) {
        favoriteEventsButtonClicked()
    }
    
    @IBAction func personalEvents(_ sender: UIButton) {
        personalEventsButtonClicked()
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        notLoggedInPopup.alpha = 0
        // Go to homeviewcontroller
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let to: UITabBarController = mainStoryboard.instantiateInitialViewController() as! UITabBarController
        to.selectedIndex = 0
        let from: UITabBarController = mainStoryboard.instantiateInitialViewController() as! UITabBarController
        from.selectedIndex = 2
        let transitionOptions: UIViewAnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        UIView.transition(with: self.view, duration: 1.0, options: transitionOptions, animations: {
            
        }, completion: { (finished: Bool) in
            
            
        })
        UIView.transition(with: self.view, duration: 1.0, options: transitionOptions, animations: {
            self.tabBarController?.selectedIndex = 0
        }, completion: nil)
        
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        noFavoritesPopup.alpha = 0
        allEventsButtonClicked()
    }
    @IBAction func unwindSegueCancel(_ sender: UIStoryboardSegue) {
        // Do nothing
    }
    
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load eventviewController")
        if let splitViewController = self.appDelegate.window?.rootViewController?.childViewControllers[1] as? UISplitViewController {
            let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count - 1] as! UINavigationController
            navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            splitViewController.preferredDisplayMode = .allVisible
            splitViewController.delegate = self
            let controllers = splitViewController.viewControllers
            eventDetailViewController = (controllers[controllers.count - 1] as! UINavigationController).topViewController as? EventDetailViewController
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        // Setup the scope bar
        setupSearchController()
        setupPopup()
        
        
        // Do any additional setup after loading the view, typically from a nib.
        
        setupNavBar()
        setupLayout()
        configureTableView()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("view will layout subviews")
        if selected[0] || selected[1] {
            let rightBarButtonItems = [UIBarButtonItem(title: "Sync", style: .plain, target: self, action: #selector(resyncTapped)), UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)), UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTapped))]
            navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
        } else {
            let rightBarButtonItems = [UIBarButtonItem(title: "Sync", style: .plain, target: self, action: #selector(resyncTapped)), UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))]
            navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if splitViewController!.isCollapsed {
            if let selectionIndexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRow(at: selectionIndexPath, animated: animated)
            }
        }
        super.viewWillAppear(animated)
        notLoggedInPopup.alpha = 0
        noFavoritesPopup.alpha = 0
        self.tableView.isUserInteractionEnabled = true
        if selected[0] {
            getEventData("favorite") // preload with existing events in CoreEvents
        } else if selected[1] {
            getEventData("personal")
        } else {
            getEventData("all")
            // Synchronize with online event data
            requestAnonymousEventData()
        }
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: - get data
    func getEventData(_ list: String) {
        if list == "favorite" {
            // request favorites
            favoriteEventsButtonClicked()
        } else if list == "personal" {
            // request personal
            personalEventsButtonClicked()
        } else {
            preloadCoreData()
        }
    }
    
    func requestAnonymousEventData() {
        print("requestAnonymousEventData")
        let blockOperation = BlockOperation {
            self.requestEventData("https://jumpingtracker.com/rest/export/json/events?_format=json", completion: { (result) in
                self.events = result
                
                print("Result from requestEventData arrived:")
                Thread.printCurrent()
                print("Update or save events")
                for items in result as [Events] {
                    print("items: \(items)")
                    for t in items.tid {
                        if self.doesEntityExist(tid: Int(t.value)) {
                            // update
                            let event: Events = items
                            self.updateAttributes(event)
                        } else { // insert new object
                            self.appDelegate.persistentContainer.performBackgroundTask({ (context) in
                                print("storing data in Core Data...")
                                // Store in core data
                                Thread.printCurrent()
                                let event: Event = NSEntityDescription.insertNewObject(forEntityName: "CoreEvents", into: context) as! Event
                                event.allAtributes = items
                                do {
                                    try context.save()
                                } catch {
                                    print("Could not save")
                                }
                            })
                        }
                    }
                    
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.progressView.isHidden = true
                    self.syncLabel.isHidden = true
                    self.activityIndicator.isHidden = true
                    self.progressView.progress = 0.0
                    if self.events.isEmpty {
                        self.tableView.isHidden = true
                    } else {
                        self.tableView.isHidden = false
                    }
                }
            })
            
        }
        
        opQueue.addOperation(blockOperation)
        
        
    }
    
    // MARK: request event data
    func requestEventData(_ urlString: String, completion: @escaping ([Events]) -> ()) {
        /// function to get taxonomies from CMS
        print("requesting event data")
        Thread.printCurrent()
        var username: String = ""
        var password: String = ""
        if ConnectionCheck.isConnectedToNetwork() {
            if self.userDefault.value(forKey: "UID") == nil {
                username = "swift_username_request_data"
                password = "JTIsabelle29?"
            } else {
                username = self.userDefault.value(forKey: "Username") as! String
                password = self.getPasswordFromKeychain(username)
            }
            let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            let headers: Dictionary<String, String> = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            
            Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
                .downloadProgress { (progress) in
                    self.progressView.progress = Float(progress.fractionCompleted)
                }
                .validate(statusCode: 200..<300)
                .validate(contentType: ["application/json"])
                
                .responseData(completionHandler: { (response) in
                    if response.result.value == nil {
                        print("No response")
                        // Show alertmessage
                        let alertController = UIAlertController(title: NSLocalizedString("No response from server", comment: ""), message: NSLocalizedString("You are probably not connected to the internet. Latest data will not be available.", comment: ""), preferredStyle: .alert)
                        let actionOK = UIAlertAction(title: NSLocalizedString("OK", comment: "OK in alert no internet"), style: .default, handler: nil)
                        let actionSettings = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings in alert no internet"), style: .default) { (_) -> Void in
                            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else { return }
                            if UIApplication.shared.canOpenURL(settingsUrl) {
                                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                    print("Settings opened: \(success)")
                                })
                            }
                        }
                        alertController.addAction(actionOK)
                        alertController.addAction(actionSettings)
                        
                        self.present(alertController, animated: true, completion: nil)
                        completion(self.events)
                    }
                    var events: [Events]?
                    switch(response.result) {
                    case .success:
                        if response.result.value != nil {
                            do {
                                events = try JSONDecoder().decode([Events].self, from: response.data!)
                                print("events decoded")
                            } catch {
                                print("Could not decode events: \(error)")
                                events = []
                            }
                        }
                        completion(events!)
                        break
                    case .failure(let error):
                        print("Request to authenticate failed with error: \(error)")
                        break
                    }
                })
            
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = false
                self.progressView.isHidden = false
                self.syncLabel.isHidden = false
                self.progressView.progress = 0.0
            }
            
        } else {
            print("No internet connection")
            // Show alertmessage
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: NSLocalizedString("No response from server", comment: ""), message: NSLocalizedString("You are probably not connected to the internet. Showing previous data.", comment: ""), preferredStyle: .alert)
                let actionOK = UIAlertAction(title: NSLocalizedString("OK", comment: "OK in alert no internet"), style: .default, handler: nil)
                let actionSettings = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings in alert no internet"), style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)")
                        })
                    }
                }
                alertController.addAction(actionOK)
                alertController.addAction(actionSettings)
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
    }
    
    // MARK: request favorite or personal event data
    func requestPersonalEventData(_ urlString: String, completion: @escaping (_ success: [Events]) -> ()) {
        /// function to get taxonomies from CMS
        print("requesting event data")
        Thread.printCurrent()
        if ConnectionCheck.isConnectedToNetwork() {
            
            let username = self.userDefault.value(forKey: "Username") as! String
            let password = self.getPasswordFromKeychain(username)
            let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            let headers: Dictionary<String, String> = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            
            Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
                .downloadProgress { (progress) in
                    self.progressView.progress = Float(progress.fractionCompleted)
                }
                .validate(statusCode: 200..<300)
                .validate(contentType: ["application/json"])
                
                .responseData(completionHandler: { (response) in
                    if response.result.value == nil {
                        print("No response")
                        // Show alertmessage
                        let alertController = UIAlertController(title: NSLocalizedString("No response from server", comment: ""), message: NSLocalizedString("You are probably not connected to the internet. Latest data will not be available.", comment: ""), preferredStyle: .alert)
                        let actionOK = UIAlertAction(title: NSLocalizedString("OK", comment: "OK in alert no internet"), style: .default, handler: nil)
                        let actionSettings = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings in alert no internet"), style: .default) { (_) -> Void in
                            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else { return }
                            if UIApplication.shared.canOpenURL(settingsUrl) {
                                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                    print("Settings opened: \(success)")
                                })
                            }
                        }
                        alertController.addAction(actionOK)
                        alertController.addAction(actionSettings)
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                    var events: [Events]?
                    switch(response.result) {
                    case .success:
                        if response.result.value != nil {
                            do {
                                events = try JSONDecoder().decode([Events].self, from: response.data!)
                            } catch {
                                print("Could not decode events: \(error)")
                                events = []
                            }
                        }
                        completion(events!)
                        break
                    case .failure(let error):
                        print("Request to authenticate failed with error: \(error)")
                        break
                    }
                })
            
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = false
                self.progressView.isHidden = false
                self.syncLabel.isHidden = false
                self.progressView.progress = 0.0
            }
            
        } else {
            print("No internet connection")
            // Show alertmessage
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: NSLocalizedString("No response from server", comment: ""), message: NSLocalizedString("You are probably not connected to the internet. Showing previous data.", comment: ""), preferredStyle: .alert)
                let actionOK = UIAlertAction(title: NSLocalizedString("OK", comment: "OK in alert no internet"), style: .default, handler: nil)
                let actionSettings = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings in alert no internet"), style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)")
                        })
                    }
                }
                alertController.addAction(actionOK)
                alertController.addAction(actionSettings)
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
    }
    // MARK: - setup Layout
    func setupLayout() {
        navigationItem.titleView?.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        navigationItem.titleView?.tintColor = UIColor.FlatColor.Gray.IronGray
        
        setupAddTargetIsNotEmptyTextFields()
        progressView.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
        progressView.progress = 0.0
        progressView.progressViewStyle = .bar
        progressView.progressTintColor = UIColor.FlatColor.Blue.CuriousBlue
        progressView.isHidden = true
        
        syncLabel.isHidden = true
        activityIndicator.isHidden = true
        
        pinBackground(stackBackgroundView, to: stackViewButtons)
        stackViewButtons.alpha = 1.0
        
        for button in tableViewButtons {
            button.tintColor = UIColor.white
            button.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
            
        }
        personalEventsButton.addLeftBorder(borderColor: UIColor.FlatColor.Gray.WhiteSmoke, borderWidth: 1.0)
        allEventsButton.addLeftBorder(borderColor: UIColor.FlatColor.Gray.WhiteSmoke, borderWidth: 1.0)
        let actBarButton = UIBarButtonItem(customView: activityIndicator)
        navigationItem.setLeftBarButton(actBarButton, animated: true)
        let rightBarButtonItems = [UIBarButtonItem(title: "Sync", style: .plain, target: self, action: #selector(resyncTapped)), UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))]
        navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
        
        self.noFavoritesPopup.center = self.originalCenter
    }
    
    // MARK: setup navigationbar
    func setupNavBar() {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            // Fallback on earlier versions
        }
    }
    
    // MARK: setup searchController
    func setupSearchController() {
        if #available(iOS 11.0, *) {
            searchController.searchBar.scopeButtonTitles = ["All", "Jumping", "Dressage", "Eventing"]
            searchController.searchBar.delegate = self
            // Setup the search footer
            tableView.tableFooterView = searchFooter
            searchController.searchResultsUpdater = self
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchBar.placeholder = "Search events"
            navigationItem.searchController = searchController // Add the searchbar to the navigationItem
        } else {
            // ???
        }
        definesPresentationContext = true
    }
    
    // MARK: configure tableview
    func configureTableView() {
        self.tableView.autoresizingMask = [.flexibleHeight]
    }
    
    // MARK: setup popup
    func setupPopup() {
        notLoggedInPopup.alpha = 0
        notLoggedInPopup.layer.cornerRadius = 15
        notLoggedInPopup.layer.masksToBounds = true
        
        notLoggedInPopupView.layer.borderWidth = 1.5
        notLoggedInPopupView.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        notLoggedInPopupView.layer.cornerRadius = 15
        notLoggedInPopupView.layer.masksToBounds = true
        notLoggedInPopupView.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
        notLoggedInMessageLabel.adjustsFontSizeToFitWidth = true
        notLoggedInMessageTitleLabel.adjustsFontSizeToFitWidth = true
        //notLoggedInPopupView.setGradientBackground()
        loginButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        loginButton.layer.borderWidth = 1.5
        loginButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        loginButton.layer.cornerRadius = 5
        loginButton.layer.masksToBounds = true
        loginButton.tintColor = UIColor.white
        
        noFavoritesPopup.alpha = 0
        originalCenter = noFavoritesPopup.center
        noFavoritesPopup.center = self.originalCenter
        noFavoritesPopup.layer.cornerRadius = 15
        noFavoritesPopup.layer.masksToBounds = true
        noFavoritesPopupView.layer.borderWidth = 1.5
        noFavoritesPopupView.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        noFavoritesPopupView.layer.cornerRadius = 15
        noFavoritesPopupView.layer.masksToBounds = true
        noFavoritesPopupView.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
        noFavoritesMessageLabel.adjustsFontSizeToFitWidth = true
        noFavoritesMessageTitleLabel.adjustsFontSizeToFitWidth = true
        //noFavoritesPopupView.setGradientBackground()
        addButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        addButton.layer.borderWidth = 1.5
        addButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        addButton.layer.cornerRadius = 5
        addButton.layer.masksToBounds = true
        addButton.tintColor = UIColor.white
        
        eventKeyPopup.alpha = 0
        originalCenter = eventKeyPopup.center
        eventKeyPopup.center = self.originalCenter
        eventKeyPopup.layer.cornerRadius = 15
        eventKeyPopup.layer.masksToBounds = true
        eventKeyPopup.layer.borderWidth = 1.5
        eventKeyPopupView.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        eventKeyPopupView.layer.cornerRadius = 15
        eventKeyPopupView.layer.masksToBounds = true
        eventKeyPopupView.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
        eventKeyPopupMessageLabel.adjustsFontSizeToFitWidth = true
        eventKeyPopupMessageTitleLabel.adjustsFontSizeToFitWidth = true

        eventKeyVerifyButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        eventKeyVerifyButton.layer.borderWidth = 1.5
        eventKeyVerifyButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        eventKeyVerifyButton.layer.cornerRadius = 5
        eventKeyVerifyButton.layer.masksToBounds = true
        eventKeyVerifyButton.tintColor = UIColor.white
        eventKeyCancelButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        eventKeyCancelButton.layer.borderWidth = 1.5
        eventKeyCancelButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        eventKeyCancelButton.layer.cornerRadius = 5
        eventKeyCancelButton.layer.masksToBounds = true
        eventKeyCancelButton.tintColor = UIColor.white
    }
    // MARK: - request data
    
    // MARK: request token
    func requestToken(parameters: Dictionary<String, Any>, headers: Dictionary<String, String>, success: @escaping (_ token: String?) -> Void, failure: @escaping (_ error: Error?) -> Void) {
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
                    success(token)
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
    
    // MARK: request user data
    func requestJSON(_ urlString: String, headers: Dictionary<String, String>, success: @escaping (_ result: [Events]) -> Void, failure: @escaping (_ error: Error?) -> Void)  {
        print("Requesting JSON...")
        
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<299)
            .validate(contentType: ["application/json"])
            .responseData { (response) in
                
                switch(response.result) {
                case .success:
                    print("data: \(response.data!)")
                    if response.result.value != nil {
                        var events: [Events] = []
                        do {
                            let eventData: [Events] = try [JSONDecoder().decode(Events.self, from: response.data!)]
                            if eventData.first != nil {
                                events = eventData
                            }
                            success(events)
                            print("userdata decoded")
                        } catch {
                            print("Could not decode userdata")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to obtain favorite/personal events failed with error: \(error)")
                    failure(error)
                    break
                }
        }
    }
    
    
    // MARK: - enable verify button when fields are filled
    func setupAddTargetIsNotEmptyTextFields() {
        eventKeyVerifyButton.isEnabled = false
        passphraseEventField.addTarget(self, action: #selector(textFieldIsNotEmpty), for: .editingChanged)
    }
    
    @objc func textFieldIsNotEmpty(sender: UITextField) {
        sender.text = sender.text?.trimmingCharacters(in: .whitespaces)
        
        guard
            let eventKey = passphraseEventField.text, !eventKey.isEmpty
            else
        {
            self.eventKeyVerifyButton.isEnabled = false
            self.eventKeyVerifyButton.alpha = 0.5
            return
        }
        eventKeyVerifyButton.isEnabled = true
        eventKeyVerifyButton.alpha = 1.0
    }
    
    // MARK: Patch favorites to User
    func patchFavoritesToEvents(_ add: Bool, _ newFavorites: [Events], _ list: String) {
        // Try to post only the event ID!!!
        if ConnectionCheck.isConnectedToNetwork() {
            // Run in operationQueue
            let patchToFavoritesCMS = BlockOperation {
                var newPatch: [Events] = []
                var newEventFav: [Events] = []
                let username = self.userDefault.string(forKey: "Username")
                let password = self.getPasswordFromKeychain(username!)
                let credentialData = "\(username!):\(password)".data(using: String.Encoding.utf8)!
                let base64Credentials = credentialData.base64EncodedString(options: [])
                let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
                
                // fetch new token
                
                let uid = self.userDefault.value(forKey: "UID")
                // fetch user data and collect existing favorite (and personal events)
                
                self.requestJSON("https://jumpingtracker.com/rest/export/json/\(list)_events/\(uid!)?_format=json", headers: headers, success: { (result) in
                    
                    if list == "favorite" {
                        if add {
                            newEventFav = result // Get current favorites
                        }
                        // add new favorites to existing favorites
                        if newFavorites.isEmpty {
                            newEventFav = []
                        } else {
                            for fav in newFavorites {
                                newEventFav.append(fav)
                            }
                        }
                        for event in newEventFav {
                            newPatch.append(event)
                        }
                        
                    }
                
                    

                    
                    
                    
                    // Encode array of dictionaries to JSON
                    let encodedDataUserPatch = try? JSONEncoder().encode(newPatch)
                    // patch user data with new favorite events to field_favorite_events
                    // Alamofire patch
                    let parameters = try? JSONSerialization.jsonObject(with: encodedDataUserPatch!) as? [String:Any]
                    // header with token for JWT_auth
                    //let headers = ["Authorization": "Bearer: \(self.userDefault.value(forKey: "token")!)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
                    // header with credentials for basic_auth
                    let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
                    Alamofire.request("https://jumpingtracker.com/rest/export/json/events/\(uid!)?_format=json", method: .patch, parameters: parameters!, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                        switch response.result {
                        case .success(let JSON):
                            print("Success with JSON: \(JSON)")
                            self.resyncTapped()
                            break
                        case .failure(let error):
                            print("Request failed with error: \(error)")
                            break
                        }
                    }
                }, failure: { (error) in
                    print("UID failure.")
                })
                
            }
            opQueue.addOperation(patchToFavoritesCMS)
        } else {
            print("No connection!")
        }
    }
    // MARK: - pin background stackview
    private func pinBackground(_ view: UIView, to stackView: UIStackView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        stackView.insertSubview(view, at: 0)
        view.pin(to: stackView)
    }
    
    
    // MARK: - Other functions
    // MARK: update progress view
    func updateProgress(progress: Float) {
        print("progress: \(progress)")
        progressView.progress = progress
    }
    
    // MARK: favorites button tapped
    func favoriteEventsButtonClicked() {
        selected = [true, false, false]
        allEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        favoriteEventsButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        personalEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        obtainPersonalEvents(list: "favorite")
    }
    
    
    
    // MARK: personal button tapped
    func personalEventsButtonClicked() {
        selected = [false, true, false]
        allEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        favoriteEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        personalEventsButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        obtainPersonalEvents(list: "personal")
    }
    
    // MARK: - obtain events from favorite or personal
    func obtainPersonalEvents(list: String) {
        notLoggedInPopup.alpha = 0
        noFavoritesPopup.alpha = 0
        eventKeyPopup.alpha = 0
        self.activityIndicator.isHidden = false
        preloadCoreData() // Fetch data from core. Filtered on button selection.
        self.tableView.reloadData()
        
        if userDefault.value(forKey: "UID") != nil {
            let uid = userDefault.value(forKey: "UID") as! String
            let favoriteEventBlockOperation = BlockOperation {
                self.requestPersonalEventData("https://jumpingtracker.com/rest/export/json/\(list)_events/\(uid)!)?_format=json", completion: { result in
                    
                    let eventdata: [Events] = result as [Events]
                    self.events = eventdata
                    if self.events.isEmpty {
                        DispatchQueue.main.async {
                            if list == "personal" {
                                self.showNoResults(title: "No \(list) events", message: "Click on the plus sign to create a new event.")
                            } else if list == "favorite" {
                                self.showNoResults(title: "No \(list) events", message: "Go to 'All' events and swipe left to make an event your favorite.")
                            }
                        }
                    } else {
                        self.resetFavorites(bool: false, list: list)
                        
                        var tids: Array<Int32> = []
                        for h in self.events {
                            tids.append(Int32(h.tid[0].value))
                        }
                        
                        self.fetchAndStoreAsFavorite(tid: tids, addToList: true, list: list)
                        
                        DispatchQueue.main.async {
                            self.noFavoritesPopup.alpha = 0
                            self.tableView.reloadData()
                        }
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.progressView.isHidden = true
                        self.syncLabel.isHidden = true
                        self.activityIndicator.isHidden = true
                        self.progressView.progress = 0.0
                    }
                })
            }
            opQueue.addOperation(favoriteEventBlockOperation)
        } else {
            print("Login to view your \(list) events or register to add \(list) events.")
            self.progressView.isHidden = true
            self.syncLabel.isHidden = true
            self.activityIndicator.isHidden = true
            self.progressView.progress = 0.0
            // Show label over tableView
            showNotLoggedInMessage("Login to view your \(list) events. Registered users can add \(list) events to their account.")
            
        }
    }
    
    
    
    // MARK: all button tapped
    func allEventsButtonClicked() {
        noFavoritesPopup.alpha = 0
        notLoggedInPopup.alpha = 0
        eventKeyPopup.alpha = 0
        selected = [false, false, true]
        preloadCoreData()
        self.tableView.reloadData()
        allEventsButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        favoriteEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        personalEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        let allEventsBlockOperation = BlockOperation {
            self.requestEventData("https://jumpingtracker.com/rest/export/json/events?_format=json", completion: { result in
                self.events = result
                var passedEvents: Array<Events> = []
                var upcomingEvents: Array<Events> = []
                for event in self.events {
                    if self.datepassed(event.date[0].value) {
                        passedEvents.append(event)
                    } else {
                        upcomingEvents.append(event)
                    }
                }
                self.splitEvents["passed"] = passedEvents
                self.splitEvents["upcoming"] = upcomingEvents
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.progressView.isHidden = true
                    self.syncLabel.isHidden = true
                    self.activityIndicator.isHidden = true
                    self.progressView.progress = 0.0
                    if self.events.isEmpty {
                        self.tableView.isHidden = true
                    } else {
                        self.tableView.isHidden = false
                    }
                }
            })
        }
        opQueue.addOperation(allEventsBlockOperation)
    }
    
    // MARK: get password from keychain
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
    
    // MARK: sanitize data from json
    func sanitizeDateFromJson(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'hh:mm:ss"
        let newFormat = DateFormatter()
        newFormat.dateFormat = "dd-MM-yyyy"
        if let date = dateFormatter.date(from: dateString) {
            return newFormat.string(from: date)
        } else {
            return ""
        }
    }
    func dateStringToDate(_ dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'hh:mm:ss"
        if let date = dateFormatter.date(from: dateString) {
            return date
        } else {
            print("could not convert datestring to date")
            return Date()
        }
        
    }
    func datepassed(_ dateString: String) -> Bool {
        if dateStringToDate(dateString) < Date() {
            return true
        } else {
            return false
        }
    }
    // MARK: sanitize time from json
    func sanitizeHourFromJson(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'hh:mm:ss"
        let newFormat = DateFormatter()
        newFormat.dateFormat = "hh:mm"
        if let date = dateFormatter.date(from: dateString) {
            return newFormat.string(from: date)
        } else {
            return ""
        }
    }
    
    // MARK: convert ID to name
    func convertIDtoName(idArray: Array<String>, dict: Dictionary<String, String>) -> String {
        var newArray: Array<String> = []
        var newString: String = ""
        for id in idArray {
            if let acro = dict[String(id)] {
                newArray.append(acro)
            }
        }
        // map array to string and join
        let flatArray = newArray.map{ String($0) }
        newString = flatArray.joined(separator: ", ")
        return newString
    }
    
    // MARK: show no results
    func showNoResults(title: String, message: String) {
        tableView.isHidden = true
        tableView.isUserInteractionEnabled = false
        noFavoritesMessageTitleLabel.text = title
        noFavoritesMessageLabel.text = message
        let pos = noFavoritesPopup.frame
        print("position: \(pos)")
        noFavoritesPopup.setAnchorPoint(CGPoint(x: 0.5, y: 0.1))
        noFavoritesPopup.transform = CGAffineTransform(rotationAngle: 1.8)
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            print("position: animation started: \(self.noFavoritesPopup.frame)")
            self.noFavoritesPopup.transform = .identity
            print("position: after .identity: \(self.noFavoritesPopup.frame)")
        }) { (success) in
            print("position: success: \(self.noFavoritesPopup.frame)")
            self.noFavoritesPopup.center = self.originalCenter
            self.noFavoritesPopup.setAnchorPoint(CGPoint(x: 0.5, y: 0.5))
            print("position: prepare for next showing: \(self.noFavoritesPopup.frame)")
        }
        print("position: end of function: \(noFavoritesPopup.frame)")
        noFavoritesPopup.alpha = 1
    }
    
    // MARK: not logged in
    func showNotLoggedInMessage(_ message: String) {
        tableView.isHidden = true
        tableView.isUserInteractionEnabled = false
        
        notLoggedInMessageLabel.text = message
        notLoggedInPopup.transform = CGAffineTransform(scaleX: 0.3, y: 2)
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            self.notLoggedInPopup.alpha = 1
            self.notLoggedInPopup.transform = .identity
        }) { (success) in
            
        }
        notLoggedInPopup.alpha = 1
        //tableView.isUserInteractionEnabled = true
    }
    
    
    // MARK: search bar empty?
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    // MARK: search is filtering?
    func isFiltering() -> Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!searchBarIsEmpty() || searchBarScopeIsFiltering)
    }
    
    // MARK: filter content for search text
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredEvents = events.filter({( event : Events) -> Bool in
            var newScope: String = ""
            if scope == "Jumping" {
                newScope = "Show jumping"
            } else {
                newScope = scope
            }
            var scopeID: String = ""
            for (key, value) in disciplineDict {
                if value == newScope {
                    scopeID = key
                }
            }
            var discNameArray: Array<String> = []
            for discID in (event.eventtype.map { $0.id }) {
                let discName = getName("CoreDisciplines", Int(discID), "name")
                discNameArray.append(discName)
            }
            let doesCategoryMatch = (newScope == "All") || discNameArray.contains(scopeID)
            
            if searchBarIsEmpty() {
                return doesCategoryMatch
            } else {
                return doesCategoryMatch && (event.title.first?.value.lowercased().contains(searchText.lowercased()))!
            }
        })
        var passedEvents: Array<Events> = []
        var upcomingEvents: Array<Events> = []
        for event in self.filteredEvents {
            if datepassed(event.date[0].value) {
                passedEvents.append(event)
            } else {
                upcomingEvents.append(event)
            }
        }
        splitFilteredEvents["passed"] = passedEvents
        splitFilteredEvents["upcoming"] = upcomingEvents
        print("splitfiltered: \(splitFilteredEvents)")
        tableView.reloadData()
    }
    
    // MARK: - Core Data
    func preloadCoreData() {
        print("preloading core data")
        self.events = []
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreEvents")
        if selected[0] {
            fetchRequest.predicate = NSPredicate(format: "favorite == YES")
        } else if selected[1] {
            fetchRequest.predicate = NSPredicate(format: "personal == YES")
        }
        fetchRequest.includesSubentities = false
        var entitiesCount = 0
        do {
            entitiesCount = try self.appDelegate.getContext().count(for: fetchRequest)
        } catch {
            print("error fetching count")
        }
        print("preloading: \(entitiesCount) events")
        if entitiesCount > 0 {
            do {
                let result = try appDelegate.getContext().fetch(fetchRequest)
                for data in result as! [Event] {
                    let event: Events = data.allAtributes
                    self.events.append(event)
                }
            } catch {
                print("error executing fetch request: \(error)")
            }
        } else {
            print("No attributes in entity")
        }
        var passedEvents: Array<Events> = []
        var upcomingEvents: Array<Events> = []
        for event in self.events {
            if datepassed(event.date[0].value) {
                passedEvents.append(event)
            } else {
                upcomingEvents.append(event)
            }
        }
        splitEvents["passed"] = passedEvents
        splitEvents["upcoming"] = upcomingEvents
        
    }
    
    
    func doesEntityExist(tid: Int) -> Bool {
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreEvents")
        fetchRequest.predicate = NSPredicate(format: "tid == %d", tid)
        fetchRequest.includesSubentities = false
        
        var entitiesCount = 0
        
        do {
            entitiesCount = try context.count(for: fetchRequest)
        } catch {
            print("error executing fetch request: \(error)")
        }
        
        return entitiesCount > 0
    }
    
    func fetchAndStoreAsFavorite(tid: [Int32], addToList: Bool, list: String) {
        for t in tid {
            if doesEntityExist(tid: Int(t)) {
                updateFavorite(Int(t), addToList, list)
            } else {
                print("Entity does not exist")
            }
        }
    }
    
    func fetchFavPerList(list: String) -> [Events] {
        var favPerEvents: [Events] = []
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreEvents")
        fetchRequest.predicate = NSPredicate(format: "\(list) == YES")
        fetchRequest.includesSubentities = false
        
        do {
            let results = try appDelegate.getContext().fetch(fetchRequest)
            for item in results as! [Event] {
                let event = item.allAtributes
                favPerEvents.append(event)
            }
        } catch {
            print("Could not update: \(error)")
        }
        return favPerEvents
    }
    
    func fetchFavorites(entity: String, value: String, key: String) -> [Events] {
        var allFavorites: [Events] = []
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.predicate = NSPredicate(format: "\(value) == \(key)")
        do {
            allFavorites = try appDelegate.getContext().fetch(fetchRequest) as! [Events]
        } catch {
            print("Could not fetch")
        }
        return allFavorites
    }
    
    func updateFavorite(_ tid: Int, _ favorite: Bool, _ list: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreEvents")
        fetchRequest.predicate = NSPredicate(format: "tid == %d", tid)
        fetchRequest.includesSubentities = false
        
        var results: [NSManagedObject] = []
        do {
            results = try appDelegate.getContext().fetch(fetchRequest) as! [NSManagedObject]
            for result in results {
                result.setValue(favorite, forKey: list)
            }
        } catch {
            print("Could not update: \(error)")
        }
        self.appDelegate.saveContext()
    }
    
    func resetFavorites(bool: Bool, list: String) {
        // Bewust op de main queue om geen conflicten te krijgen met de hierop volgende functie om favorieten toe te voegen!
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreEvents")
        let predicate = NSPredicate(format: "\(list) == YES")
        fetchRequest.predicate = predicate
        fetchRequest.includesSubentities = false
        
        var results: [NSManagedObject] = []
        do {
            results = try appDelegate.getContext().fetch(fetchRequest) as! [NSManagedObject]
            for result in results {
                result.setValue(bool, forKey: list)
            }
        } catch {
            print("Could not update: \(error)")
        }
        self.appDelegate.saveContext()
        
    }
    
    func updateAttributes(_ event: Events) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreEvents")
        fetchRequest.predicate = NSPredicate(format: "tid == %d", event.tid)
        fetchRequest.includesSubentities = false
        var results: [Events] = []
        do {
            results = try appDelegate.getContext().fetch(fetchRequest) as! [Events]
        } catch {
            print("error executing fetch request: \(error)")
        }
        self.appDelegate.persistentContainer.performBackgroundTask({ (context) in
            print("storing data in Core Data...")
            // Store in core data
            Thread.printCurrent()
            for items in results as [Events] {
                let event: Event = NSEntityDescription.insertNewObject(forEntityName: "CoreEvents", into: context) as! Event
                event.allAtributes = items
            }
            do {
                try context.save()
            } catch {
                print("Could not save context")
            }
        })
    }
    
    
    // MARK: - selector objects
    @objc func resyncTapped() {
        notLoggedInPopup.alpha = 0
        noFavoritesPopup.alpha = 0
        eventKeyPopup.alpha = 0
        // Synchronize events
        if selected[0] {
            favoriteEvents(favoriteEventsButton)
        } else if selected[1] {
            personalEvents(personalEventsButton)
        } else {
            allEvents(allEventsButton)
        }
    }
    
    @objc func editTapped() {
        if self.tableView.isEditing {
            self.tableView.setEditing(false, animated: true)
        } else {
            self.tableView.setEditing(true, animated: true)
        }
    }
    @objc func addTapped() {
        if selected[0] {
            // Add event to favo
            allEventsButtonClicked()
            UIView.animate(withDuration: 1, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                self.noFavoritesPopup.alpha = 1.0
            }) { (bool) in
                UIView.animate(withDuration: 1, delay: 1.5, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                    self.noFavoritesPopup.alpha = 0.0
                }, completion: nil )}
            
        } else if selected[1] {
            // Ask for event identification to add an existing(!) event to personal list
            UIView.animate(withDuration: 1, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
                self.eventKeyPopup.alpha = 1.0
            }, completion: nil)
        } else {
            // Add an event to the list
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "AddNewEvent") as! AddNewEventViewController
            let navController = UINavigationController(rootViewController: vc)
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - prepare segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToEventDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let event: Events
                if isFiltering() {
                    event = filteredEvents[indexPath.row]
                } else {
                    event = events[indexPath.row]
                }
                let controller = (segue.destination as! UINavigationController).topViewController as! EventDetailViewController
                controller.detailEvent = event
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.navigationController?.title = event.title.first?.value
            }
        }
    }
    
    func getName(_ entity: String, _ tid: Int, _ key: String) -> String {
        var result: NSManagedObject?
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.predicate = NSPredicate(format: "tid == %d", tid)
        do {
            let results = try appDelegate.getContext().fetch(fetchRequest) as? [NSManagedObject]
            result = results?.first
        } catch {
            print("Could not fetch")
        }
        return result!.value(forKey: key) as! String
    }
    
    func passedEventsExist(filter: Bool) -> Bool {
        let list = filter ? self.filteredEvents : self.events
        for event in (list) {
            if datepassed(event.date[0].value) {
                return true
            }
        }
        return false
    }
    
    func upcomingEventsExist(filter: Bool) -> Bool {
        let list = filter ? self.filteredEvents : self.events
        for event in list {
            if !datepassed(event.date[0].value) {
                return true
            }
        }
        return false
    }
}

// MARK: - Extensions
// MARK: tableView extension
extension EventsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberofSections: Int = 0
        var list = isFiltering() ? splitFilteredEvents : splitEvents
        if (list["passed"]?.count)! > 0 {
            numberofSections += 1
        }
        if (list["upcoming"]?.count)! > 0 {
            numberofSections += 1
        }
        return numberofSections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let list = isFiltering() ? splitFilteredEvents : splitEvents

        switch (section) {
        case 0:
            if list["upcoming"]?.count == 0 {
                if (list["passed"]?.count)! > 0 {
                    return "Passed events"
                } else {
                    return "No events"
                }
            } else {
                return "Upcoming events"
            }
            
        default:
            if (list["passed"]?.count)! > 0 {
                return "Passed events"
            } else {
                return "No passed events"
            }
        }
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let list = isFiltering() ? splitFilteredEvents : splitEvents
        switch (section) {
        case 0:
            if list["upcoming"]!.count == 0 {
                return list["passed"]!.count
            }
            return list["upcoming"]!.count
        default:
            return list["passed"]!.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EventsTableCell", for: indexPath) as? EventsTableCell else {
            fatalError("Unexpected Index Path")
        }
        
        var event: Events
        cell.selectionStyle = .gray
        cell.layer.cornerRadius = 0
        cell.layer.masksToBounds = true
        cell.layer.borderWidth = 0
        
        self.tableView.isHidden = false
        switch (indexPath.section) {
        case 0:
            if isFiltering() {
                if splitFilteredEvents["upcoming"]!.count == 0 {
                    event = splitFilteredEvents["passed"]![indexPath.row]
                } else {
                    event = splitFilteredEvents["upcoming"]![indexPath.row]
                }
            } else {
                event = splitEvents["upcoming"]![indexPath.row]
                if splitEvents["upcoming"]!.count == 0 {
                    event = splitEvents["passed"]![indexPath.row]
                }
            }
        default:
            if isFiltering() {
                event = splitFilteredEvents["passed"]![indexPath.row]
            } else {
                event = splitEvents["passed"]![indexPath.row]
            }
        }
        cell.event.text = event.title.first?.value
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if selected[0] || selected[1] {
            return .delete
        }
        return .none
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Quickly remove from tableview
            print("list of events before deleting: \(self.events.map { $0.tid })")
            let tid: Array<Int32> = self.events[indexPath.row].tid.map { $0.value }
            self.events.remove(at: indexPath.row)
            tableView.reloadData()
            
            
            if selected[0] {
                print("list of events: \(self.events.map { $0.tid })")
                // Patch userdata with new list of favorites
                self.resetFavorites(bool: false, list: "favorite") // Main queue
                self.patchFavoritesToEvents(false, self.events, "favorite") // OperationQueue
                // Adjust in Core Data
                fetchAndStoreAsFavorite(tid: tid, addToList: false, list: "favorite")
            } else if selected[1] {
                print("list of events: \(self.events.map { $0.tid })")
                // Patch userdata with new list of favorites
                self.resetFavorites(bool: false, list: "personal")
                self.patchFavoritesToEvents(false, self.events, "personal")
                // Adjust in Core Data
                fetchAndStoreAsFavorite(tid: tid, addToList: false, list: "personal")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // MARK: Add to Favorites
        let addToFavorites = UITableViewRowAction(style: .normal, title: "Favorite") { (action, indexPath) in
            // Fetch Event
            let tid: Array<Int32> = self.events[indexPath.row].tid.map { $0.value }
            
            // Adjust in Core Data
            self.fetchAndStoreAsFavorite(tid: tid, addToList: true, list: "favorite")
            // Fetch all favorites and patch to server
            let allFavorites: [Events] = self.fetchFavorites(entity: "CoreEvents", value: "favorite", key: "YES")
            self.patchFavoritesToEvents(true, allFavorites, "favorite") // OperationQueue
            let cell = tableView.cellForRow(at: indexPath)
            UIView.animate(withDuration: 1, delay: 0.0, options: [.curveEaseIn], animations: {cell?.layer.backgroundColor = UIColor.green.withAlphaComponent(0.6).cgColor}, completion: {_ in UIView.animate(withDuration: 0.1, animations: {cell?.layer.backgroundColor = UIColor.green.withAlphaComponent(0.0).cgColor; self.tableView.reloadRows(at: [indexPath], with: .none)}) }
            )
        }
        addToFavorites.backgroundColor = UIColor(red: 125/255, green: 0/255, blue:0/255, alpha:1)
        
        let deleteFromFavorite = UITableViewRowAction(style: .default, title: "Remove") { (action, indexPath) in
            // Fetch Event
            let tid: Array<Int32> = self.events[indexPath.row].tid.map { $0.value }
            self.events.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.patchFavoritesToEvents(false, self.events, "favorite")
            self.fetchAndStoreAsFavorite(tid: tid, addToList: false, list: "favorite")
        }
        let deleteFromPersonal = UITableViewRowAction(style: .default, title: "Remove") { (action, indexPath) in
            // Fetch Event
            let tid: Array<Int32> = self.events[indexPath.row].tid.map { $0.value }
            self.events.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.patchFavoritesToEvents(false, self.events, "personal")
            self.fetchAndStoreAsFavorite(tid: tid, addToList: false, list: "personal")
        }
        // Show when favorites or personal are not selected
        if selected[0] {
            return [deleteFromFavorite]
        } else if selected[1] {
            return [deleteFromPersonal]
        } else {
            return [addToFavorites]
        }
    }
}

// MARK: UISearchResultsUpdating delegate
extension EventsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
        if isFiltering() {
            print("filteredEvents.count: \(filteredEvents.count)")
            searchFooter.setIsFilteringToShow(filteredItemCount: filteredEvents.count, of: events.count)
        } else {
            searchFooter.setNotFiltering()
        }
    }
    
}

// MARK: UISearchBarDelegate extension
extension EventsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

// MARK: UIButton extension
extension UIButton {
    func addRightBorder(borderColor: UIColor, borderWidth: CGFloat) {
        let border = CALayer()
        border.backgroundColor = borderColor.cgColor
        border.frame = CGRect(x: self.frame.size.width - borderWidth, y: 3, width: borderWidth, height: self.frame.size.height - 6)
        self.layer.addSublayer(border)
    }
    
    func addLeftBorder(borderColor: UIColor, borderWidth: CGFloat) {
        let border = CALayer()
        border.backgroundColor = borderColor.cgColor
        border.frame = CGRect(x: 0, y: 3, width: borderWidth, height: self.frame.size.height - 6)
        self.layer.addSublayer(border)
    }
}

// MARK: UIView extension
public extension UIView {
    public func pin(to view: UIView) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
    
    func setAnchorPoint(_ point: CGPoint) {
        var newPoint = CGPoint(x: bounds.size.width * point.x, y: bounds.size.height * point.y)
        var oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y)
        newPoint = newPoint.applying(transform)
        oldPoint = oldPoint.applying(transform)
        
        var position = layer.position
        
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        layer.position = position
        layer.anchorPoint = point
    }
}

extension EventsViewController: UISplitViewControllerDelegate {
    // MARK: - Split view
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? EventDetailViewController else { return false }
        if topAsDetailController.detailEvent == nil {
            // Return true to indicate that we have handled the collapse by doing nothing
            return true
        }
        return false
    }
}
