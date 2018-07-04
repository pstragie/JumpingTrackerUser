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
    // General lists (filled with requested events)
    var splitEvents: Dictionary<String, [Events]> = ["passed":[], "upcoming":[]]
    var splitFilteredEvents: Dictionary<String, [Events]> = ["passed":[], "upcoming":[]]
    // Specific lists for quick loading
    var splitFilteredFavoriteEvents: Dictionary<String, [Events]> = ["passed": [], "upcoming": []]
    var splitFilteredPersonalEvents: Dictionary<String, [Events]> = ["passed": [], "upcoming": []]
    var splitFilteredAllEvents: Dictionary<String, [Events]> = ["passed": [], "upcoming": []]
    var splitFavoriteEvents: Dictionary<String, [Events]> = ["passed": [], "upcoming": []]
    var splitPersonalEvents: Dictionary<String, [Events]> = ["passed": [], "upcoming": []]
    var splitAllEvents: Dictionary<String, [Events]> = ["passed": [], "upcoming": []]
    
    var events: [Events] = []
    var filteredEvents: [Events] = []
    var selected: Array<Bool> = []
    
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
    
    @IBOutlet weak var notLoggedInMessageLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var noFavoritesMessageTitleLabel: UILabel!
    @IBOutlet weak var noFavoritesMessageLabel: UILabel!
    @IBOutlet weak var addEventPopup: UIVisualEffectView!
    @IBOutlet weak var addEventPopupView: UIView!
    @IBOutlet weak var addEventPopupMessageTitleLabel: UILabel!
    @IBOutlet weak var addEventPopupMessageLabel: UILabel!
    @IBOutlet weak var addEventPopupEditButton: UIButton!
    @IBOutlet weak var addEventPopupNewButton: UIButton!
    @IBOutlet weak var addEventPopupCancelButton: UIButton!
    @IBOutlet weak var eventKeyPopupMessageTitleLabel: UILabel!
    @IBOutlet weak var eventKeyPopup: UIVisualEffectView!
    @IBOutlet weak var eventKeyPopupView: UIView!
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
        UIView.animate(withDuration: 1, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            // Flip popup
            self.perform(#selector(self.flipBack), with: nil, afterDelay: 0.5)
            
        }, completion: nil)
    }
    // MARK: - Outlet functions
    @IBAction func allEvents(_ sender: UIButton) {
        self.tableView.isUserInteractionEnabled = true
        allEventsButtonClicked()
    }
    @IBAction func favoriteEvents(_ sender: UIButton) {
        self.tableView.isUserInteractionEnabled = true
        favoriteEventsButtonClicked()
    }
    
    @IBAction func personalEvents(_ sender: UIButton) {
        self.tableView.isUserInteractionEnabled = true
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
        addEventPopup.alpha = 0

        self.tableView.isUserInteractionEnabled = true
        self.tableView.isEditing = false
    }
    
    
    @IBAction func addEventPopupEditButtonTapped(_ sender: UIButton) {
        // flip popup -> show eventKeyPopup
        UIView.animate(withDuration: 1, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            // Flip popup
            self.perform(#selector(self.flipForward), with: nil, afterDelay: 0.5)
            
        }, completion: nil)
    }
    @IBAction func addEventPopupNewButtonTapped(_ sender: UIButton) {
        // navigate to addEventViewController
    }
    @IBAction func addEventPopupCancelButtonTapped(_ sender: UIButton) {
        // hide popup
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.addEventPopup.alpha = 0.0
        }, completion: {(bool) in
            self.addEventPopup.alpha = 0.0
        })
    }
    @IBAction func unwindSegueCancel(_ sender: UIStoryboardSegue) {
        // Do nothing
    }
    
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if isUserOrganisator() {
            selected = [false, false, false]
        } else {
            selected = [false, false]
        }
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
        if isUserOrganisator() {
            if selected[0] || selected[1] {
                let rightBarButtonItems = [UIBarButtonItem(title: "Sync", style: .plain, target: self, action: #selector(resyncTapped)), UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)), UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTapped))]
                navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
            } else {
                let rightBarButtonItems = [UIBarButtonItem(title: "Sync", style: .plain, target: self, action: #selector(resyncTapped)), UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))]
                navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
            }
        } else {
            let rightBarButtonItems = [UIBarButtonItem(title: "Sync", style: .plain, target: self, action: #selector(resyncTapped))]
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
        addEventPopup.alpha = 0
        eventKeyPopup.alpha = 0
        self.tableView.isUserInteractionEnabled = true
        if isUserOrganisator() {
            if selected[0] {
                favoriteEventsButtonClicked()
            } else if selected[1] {
                personalEventsButtonClicked()
            } else if selected[2] {
                allEventsButtonClicked()
            } else {
                // Synchronize with online event data
                print("requestAnonymousEventData")
                fetchEvents()
            }
        } else {
            if selected[0] {
                favoriteEventsButtonClicked()
            } else if selected[1] {
                allEventsButtonClicked()
            } else {
                // Synchronize with online event data
                print("requestAnonymousEventData")
                fetchEvents()
                
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK: - setup Layout
    func setupLayout() {
        if !isUserOrganisator() {
            self.personalEventsButton.isHidden = true
        }
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
            navigationController?.navigationItem.largeTitleDisplayMode = .automatic
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
        
        addEventPopup.alpha = 0
        originalCenter = eventKeyPopup.center
        addEventPopup.center = self.originalCenter
        addEventPopup.layer.cornerRadius = 15
        addEventPopup.layer.masksToBounds = true
        addEventPopup.layer.borderWidth = 1.5
        addEventPopupView.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        addEventPopupView.layer.cornerRadius = 15
        addEventPopupView.layer.masksToBounds = true
        addEventPopupView.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
        addEventPopupMessageLabel.adjustsFontSizeToFitWidth = true
        addEventPopupMessageTitleLabel.adjustsFontSizeToFitWidth = true
        
        
        addEventPopupEditButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        addEventPopupEditButton.layer.borderWidth = 1.5
        addEventPopupEditButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        addEventPopupEditButton.layer.cornerRadius = 5
        addEventPopupEditButton.layer.masksToBounds = true
        addEventPopupNewButton.tintColor = UIColor.white
        addEventPopupNewButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        addEventPopupNewButton.layer.borderWidth = 1.5
        addEventPopupNewButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        addEventPopupNewButton.layer.cornerRadius = 5
        addEventPopupNewButton.layer.masksToBounds = true
        addEventPopupNewButton.tintColor = UIColor.white
        addEventPopupCancelButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        addEventPopupCancelButton.layer.borderWidth = 1.5
        addEventPopupCancelButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        addEventPopupCancelButton.layer.cornerRadius = 5
        addEventPopupCancelButton.layer.masksToBounds = true
        addEventPopupCancelButton.tintColor = UIColor.white
        
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
    
    
    // MARK: - Essential data functions
   
    
    
    // MARK: request event data
    func requestEventData(_ urlString: String, completion: @escaping ([Events]) -> ()) {
        /// function to get taxonomies from CMS
        print("requesting event data")
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
        if ConnectionCheck.isConnectedToNetwork() {
            
            let username = self.userDefault.value(forKey: "Username") as! String
            let password = self.getPasswordFromKeychain(username)
            let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            let headers: Dictionary<String, String> = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            
            Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
                .downloadProgress { (progress) in
                    DispatchQueue.main.async {
                        self.progressView.progress = Float(progress.fractionCompleted)
                    }
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
                var events: [Events]?
                switch(response.result) {
                case .success:
                    //print("data: \(response.data!)")
                    if response.result.value != nil {
                        
                        do {
                            events = try JSONDecoder().decode([Events].self, from: response.data!)
                            
                            success(events!)
                            print("event data decoded")
                        } catch {
                            print("Could not decode event data")
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
    
    
    // MARK: - Additional Functions
    func isUserOrganisator() -> Bool {
        let userID = self.userDefault.value(forKey: "UID") as? String
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreCurrentUser")
        fetchRequest.predicate = NSPredicate(format: "organisationID == %@", userID!)
        var user: [CurrentUser] = []
        do {
            user = try self.appDelegate.getContext().fetch(fetchRequest) as! [CurrentUser]
        } catch {
            print("Could not fetch user")
        }
        
        if user.first?.organisationID != 0 {
            return true
        } else {
            return false
        }
    }
    
    // Add flagging to event
    func addFavoriteFlagging(tid: Int) {
        if ConnectionCheck.isConnectedToNetwork() {
            // Prep headers
            let username = self.userDefault.string(forKey: "Username")
            let password = self.getPasswordFromKeychain(username!)
            let credentialData = "\(username!):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            
            // Prep parameters for flagging
            let flag_name: String = "add_event_to_favorites"
            let action: String = "flag"
            let user_uid = self.userDefault.value(forKey: "UID") as! String
            let entity_id: String = String(tid)
            let parameters: [String: Any] = ["flag_id": [["target_id": flag_name, "target_type": action]], "entity_type": [["value": "node"]], "entity_id": [["value": entity_id]], "uid": [["target_id": Int(user_uid)]]]
            let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            
            Alamofire.request("https://jumpingtracker.com/entity/flagging?_format=json", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .responseJSON { response in
                    switch response.result {
                    case .success:
                        print("Success with adding favorite flag to event: \(String(describing: response.result.value))")
                        self.resyncTapped()
                        break
                    case .failure(let error):
                        print("Request failed with error: \(error)")
                        break
                    }
            }
        } else {
            print("No connection")
        }
    }
    
    // Cancel Event
    func cancelEvent(tid: Int) {
        if ConnectionCheck.isConnectedToNetwork() {
            // TODO: create drupal field: "canceled"
            // Patch cancel to server
            // TODO: drupal do something with the canceled message! (Email followers?, Image on event?)
            // TODO: Add image on row: Canceled (option to remove entirely?
            print("Event successfully canceled")
        } else {
            print("Not connected to the internet")
        }
    }
    
    // Patch favorites to User
    func deleteFavoriteFlagging(tid: Int) {
        // Try to post only the event ID!!!
        if ConnectionCheck.isConnectedToNetwork() {
            // Run in operationQueue
            var flaggingID: Int = 0
            let deleteFlaggingCMS = BlockOperation {
                let username = self.userDefault.string(forKey: "Username")
                let password = self.getPasswordFromKeychain(username!)
                let credentialData = "\(username!):\(password)".data(using: String.Encoding.utf8)!
                let base64Credentials = credentialData.base64EncodedString(options: [])
                let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
                
                // fetch flagging id from node ID (tid)
                print("Fetch flagging id for node ID: \(tid)")
                self.requestFlaggingID("https://jumpingtracker.com/rest/export/json/flagging/\(tid)?_format=json", headers: headers, success: { (result) in
                    flaggingID = result
                    print("Flagging ID obtained: \(flaggingID)")
                    // delete flagging
                    
                    
                    //let parameters = try? JSONSerialization.jsonObject(with: encodedDataUserPatch!) as? [String:Any]
                    // header with token for JWT_auth
                    //let headers = ["Authorization": "Bearer: \(self.userDefault.value(forKey: "token")!)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
                    // header with credentials for basic_auth
                    let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
                    Alamofire.request("https://jumpingtracker.com/entity/flagging/\(flaggingID)?_format=json", method: .delete,  encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                        print("delete response = \(String(describing: response.value))")
                        switch response.result {
                        case .success:
                            print("Success with delete")
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
            opQueue.addOperation(deleteFlaggingCMS)
        } else {
            print("No connection!")
        }
    }
    
    func requestFlaggingID(_ urlString: String, headers: Dictionary<String, String>, success: @escaping (_ result: Int) -> Void, failure: @escaping (_ error: Error?) -> Void)  {
        print("Requesting Flagging ID...")
        
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<299)
            .validate(contentType: ["application/json"])
            .responseData { (response) in
                switch(response.result) {
                case .success:
                    print("data: \(response.data!)")
                    if response.result.value != nil {
                        
                        do {
                            let flaggings = try JSONDecoder().decode([Flaggings].self, from: response.data!)
                            print("response: \(String(describing: flaggings.first))")
                            let flaggingID: Int = (flaggings.first?.id!.first?.value)!
                            success(flaggingID)
                            print("success: flaggingID = \(flaggingID)")
                            print("event data decoded")
                        } catch {
                            print("Could not decode event data")
                        }
                    } else {
                        print("response: \(String(describing: response.result.value))")
                    }
                    break
                case .failure(let error):
                    print("Request to obtain favorite/personal events failed with error: \(error)")
                    failure(error)
                    break
                }
        }
    }
    
    // Obtain events from favorite or personal
    func obtainPersonalEvents(list: String) {
        notLoggedInPopup.alpha = 0
        noFavoritesPopup.alpha = 0
        eventKeyPopup.alpha = 0
        self.activityIndicator.isHidden = false
        // Preload existing list
        if list == "favorite" {
            self.splitEvents = self.splitFavoriteEvents
            self.splitFilteredEvents = self.splitFilteredFavoriteEvents
            print("filtering = \(isFiltering())")
        } else if list == "personal" {
            self.splitEvents = self.splitPersonalEvents
            self.splitFilteredEvents = self.splitFilteredPersonalEvents
        }
        self.tableView.reloadData()
        
        if userDefault.bool(forKey: "loginSuccessful") { // User needs to be logged in
            let favoriteEventBlockOperation = BlockOperation {
                // No uid needed (internal function in Flag module!)
                self.requestPersonalEventData("https://jumpingtracker.com/rest/export/json/\(list)_events?_format=json", completion: { result in
                    
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
                        self.prepareSplitEventsArray(list)
                        if self.isFiltering() {
                            if list == "favorite" {
                                print("update search splitFilteredFavoriteEvents: \(self.splitFilteredFavoriteEvents)")
                                self.splitFilteredEvents = self.splitFilteredFavoriteEvents
                            } else if list == "personal" {
                                print("update search splitFilteredPersonalEvents: \(self.splitFilteredPersonalEvents)")
                                self.splitFilteredEvents = self.splitFilteredPersonalEvents
                            }
                            // Re-apply filtering!
                            self.updateSearchResults(for: self.searchController)
                            
                        }
                        DispatchQueue.main.async {
                            self.noFavoritesPopup.alpha = 0
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
    
    // Fetch all events
    func fetchEvents() {
        let allEventsBlockOperation = BlockOperation {
            self.requestEventData("https://jumpingtracker.com/rest/export/json/events?_format=json", completion: { result in
                self.events = result
                print("Result from requestEventData arrived:")
                
                self.prepareSplitEventsArray("All")
                
                DispatchQueue.main.async {
                    print("Queue async")
                    self.tableView.reloadData()
                    self.progressView.isHidden = true
                    self.syncLabel.isHidden = true
                    self.activityIndicator.isHidden = true
                    self.progressView.progress = 0.0
                    if self.events.isEmpty {
                        print("events is empty")
                        self.tableView.isHidden = true
                    } else {
                        print("events is not empty")
                        self.tableView.isHidden = false
                    }
                }
            })
        }
        let reloadOperation = BlockOperation {
            DispatchQueue.main.async() {
                self.tableView.reloadData()
            }
        }
        opQueue.addOperations([allEventsBlockOperation, reloadOperation], waitUntilFinished: true)
        //opQueue.addOperation(allEventsBlockOperation)
    }
    
    func fetchFavoritesAndPersonalInBackground() {
        var lists: Array<String> = []
        if isUserOrganisator() {
            lists = ["favorite", "personal"]
        } else {
            lists = ["favorite"]
        }
        for list in lists {
            if userDefault.bool(forKey: "loginSuccessful") { // User needs to be logged in
                let favoriteEventsBlockOperation = BlockOperation {
                    // No uid needed (internal function in Flag module!)
                    self.requestPersonalEventData("https://jumpingtracker.com/rest/export/json/\(list)_events?_format=json", completion: { result in
                        
                        let eventdata: [Events] = result as [Events]
                        if list == "favorite" {
                            self.prepareSplitFavoriteEventsArray(eventdata, "favorite")
                        } else if list == "personal" {
                            self.prepareSplitFavoriteEventsArray(eventdata, "personal")
                        }
                    })
                }
                opQueue.addOperation(favoriteEventsBlockOperation)
            }
        }
    }
    
    // search bar empty?
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    // search is filtering?
    func isFiltering() -> Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!searchBarIsEmpty() || searchBarScopeIsFiltering)
    }
    
    
    // get name from tid
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
    
    // filter content for search text
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
        prepareSplitEventsArray("favorite")
        prepareSplitEventsArray("personal")
        prepareSplitEventsArray("All")

        if isUserOrganisator() {
            if selected[0] {
                self.splitFilteredEvents = self.splitFilteredFavoriteEvents
            } else if selected[1] {
                self.splitFilteredEvents = self.splitFilteredPersonalEvents
            } else {
                self.splitFilteredEvents = self.splitFilteredAllEvents
            }
        } else {
            if selected[0] {
                self.splitFilteredEvents = self.splitFilteredFavoriteEvents
            } else {
                self.splitFilteredEvents = self.splitFilteredAllEvents
            }
        }
        self.tableView.reloadData()
    }
    
    // Split events into passed and upcoming
    func prepareSplitEventsArray(_ button: String) {
        var passedEvents: Array<Events> = []
        var upcomingEvents: Array<Events> = []
        let list = isFiltering() ? self.filteredEvents : self.events
        for event in list {
            if self.datepassed(event.date[0].value) {
                passedEvents.append(event)
            } else {
                upcomingEvents.append(event)
            }
        }
        
        if button == "All" {
            if isFiltering() {
                self.splitFilteredAllEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
                self.splitFilteredAllEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
            } else {
                self.splitAllEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
                self.splitAllEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
            }
        } else if button == "favorite" {
            if isFiltering() {
                self.splitFilteredFavoriteEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
                self.splitFilteredFavoriteEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
            } else {
                self.splitFavoriteEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
                self.splitFavoriteEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
            }
        } else if button == "personal" {
            if isFiltering() {
                self.splitFilteredPersonalEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
                self.splitFilteredPersonalEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
            } else {
                self.splitPersonalEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
                self.splitPersonalEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
            }
        }
        if isFiltering() {
            self.splitFilteredEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
            self.splitFilteredEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
        } else {
            self.splitEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
            self.splitEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
        }
        
    }
    
    // Split events into passed and upcoming
    func prepareSplitFavoriteEventsArray(_ list: [Events], _ button: String) {
        var passedEvents: Array<Events> = []
        var upcomingEvents: Array<Events> = []
        for event in list {
            if self.datepassed(event.date[0].value) {
                passedEvents.append(event)
            } else {
                upcomingEvents.append(event)
            }
        }
        
        if button == "favorite" {
            if isFiltering() {
                self.splitFilteredFavoriteEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
                self.splitFilteredFavoriteEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
            } else {
                self.splitFavoriteEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
                self.splitFavoriteEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
            }
        } else if button == "personal" {
            if isFiltering() {
                self.splitFilteredPersonalEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
                self.splitFilteredPersonalEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
            } else {
                self.splitPersonalEvents["passed"] = passedEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) > (self.dateStringToDate($1.date[0].value)) })
                self.splitPersonalEvents["upcoming"] = upcomingEvents.sorted(by: { (self.dateStringToDate($0.date[0].value)) < (self.dateStringToDate($1.date[0].value)) })
            }
        }
    }
    
    // MARK: - Supplementary functions
    // enable verify button when fields are filled
    func setupAddTargetIsNotEmptyTextFields() {
        eventKeyVerifyButton.isEnabled = false
        passphraseEventField.addTarget(self, action: #selector(textFieldIsNotEmpty), for: .editingChanged)
    }
    
    
    // MARK: pin background stackview
    private func pinBackground(_ view: UIView, to stackView: UIStackView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        stackView.insertSubview(view, at: 0)
        view.pin(to: stackView)
    }
    
    
    // update progress view
    func updateProgress(progress: Float) {
        print("progress: \(progress)")
        progressView.progress = progress
    }
    
    
    // favorites button tapped
    func favoriteEventsButtonClicked() {
        if isUserOrganisator() {
            selected = [true, false, false]
        } else {
            selected = [true, false]
        }
        allEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        favoriteEventsButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        personalEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        obtainPersonalEvents(list: "favorite")
    }
    
    
    
    // personal button tapped
    func personalEventsButtonClicked() {
        selected = [false, true, false] // Can only be clicked if user is organisator
        allEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        favoriteEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        personalEventsButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        obtainPersonalEvents(list: "personal")
    }
    

    // all button tapped
    func allEventsButtonClicked() {
        print("allEventsButtonClicked")
        noFavoritesPopup.alpha = 0
        notLoggedInPopup.alpha = 0
        eventKeyPopup.alpha = 0
        tableView.isEditing = false
        selected = [false, false, true]
        // Quickly load previously downloaded data
        self.splitEvents = self.splitAllEvents
        self.splitFilteredEvents = self.splitFilteredAllEvents
        self.tableView.reloadData()
        allEventsButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        favoriteEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        personalEventsButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        // Synchronize in background
        fetchEvents()
    }
    
    
    
    // get password from keychain
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
    
    // sanitize data from json
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
    
    // date string to date format
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
    
    // date passed boolean
    func datepassed(_ dateString: String) -> Bool {
        if dateStringToDate(dateString) < Date() {
            return true
        } else {
            return false
        }
    }
    // sanitize time from json
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
    
    // convert ID to name
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
    
    // Popup views
    // show no results
    func showNoResults(title: String, message: String) {
        tableView.isHidden = true
        tableView.isUserInteractionEnabled = false
        noFavoritesMessageTitleLabel.text = title
        noFavoritesMessageLabel.text = message
        noFavoritesPopup.transform = CGAffineTransform(scaleX: 0.3, y: 2)
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            self.noFavoritesPopup.alpha = 1
            self.noFavoritesPopup.transform = .identity
        }) { (success) in
            
        }
        noFavoritesPopup.alpha = 1
    }
    
    // not logged in
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
    }
    

    // MARK: - selector objects
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
    
    @objc func resyncTapped() {
        notLoggedInPopup.alpha = 0
        noFavoritesPopup.alpha = 0
        eventKeyPopup.alpha = 0
        addEventPopup.alpha = 0
        // Synchronize events
        if isUserOrganisator() {
            if selected[0] {
                favoriteEvents(favoriteEventsButton)
            } else if selected[1] {
                personalEvents(personalEventsButton)
            } else {
                allEvents(allEventsButton)
            }
        } else {
            if selected[0] {
                favoriteEvents(favoriteEventsButton)
            } else {
                allEvents(allEventsButton)
            }
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
            self.eventKeyPopup.alpha = 0.0
            self.notLoggedInPopup.alpha = 0.0
            addEventPopup.alpha = 0

            allEventsButtonClicked()
            UIView.animate(withDuration: 1, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                self.noFavoritesMessageTitleLabel.text = "Add favorite event"
                self.noFavoritesMessageLabel.text = "Swipe left to add an event to your favorites"
                self.noFavoritesPopup.alpha = 1.0
            }) { (bool) in
                UIView.animate(withDuration: 1, delay: 2.5, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                    self.noFavoritesPopup.alpha = 0.0
                }, completion: nil )}
            
        } else {
            self.notLoggedInPopup.alpha = 0.0
            self.noFavoritesPopup.alpha = 0.0
            addEventPopup.alpha = 0

            // Ask for event identification to add an existing(!) event to personal list
            UIView.animate(withDuration: 1, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
                self.addEventPopup.alpha = 1.0
            }, completion: nil)
        }
        
        
    }
    
    @objc func addNewEvent() {
        // Add an event to the list
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "AddNewEvent") as! AddNewEventViewController
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc func flipForward() {
        let transitionOptions: UIViewAnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        UIView.transition(with: self.addEventPopup, duration: 1.0, options: transitionOptions, animations: {
            self.addEventPopup.alpha = 0.0
        }, completion: nil)
        UIView.transition(with: self.eventKeyPopup, duration: 1.0, options: transitionOptions, animations: {
            self.eventKeyPopup.alpha = 1.0
        }, completion: nil)
    }
    
    @objc func flipBack() {
        let transitionOptions: UIViewAnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        UIView.transition(with: self.eventKeyPopup, duration: 1.0, options: transitionOptions, animations: {
            self.eventKeyPopup.alpha = 0.0
        }, completion: nil)
        UIView.transition(with: self.addEventPopup, duration: 1.0, options: transitionOptions, animations: {
            self.addEventPopup.alpha = 1.0
        }, completion: nil)
    }
    
    // MARK: - prepare segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToEventDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let event: Events
                var list: Array<Events>?
                switch (indexPath.section) {
                case 0:
                    list = isFiltering() ? splitFilteredEvents["upcoming"] : splitEvents["upcoming"]
                    if list!.isEmpty {
                        list = isFiltering() ? splitFilteredEvents["passed"] : splitEvents["passed"]
                    }
                default:
                    list = isFiltering() ? splitFilteredEvents["passed"] : splitEvents["passed"]
                }
                
                event = list![indexPath.row]
                
                let controller = (segue.destination as! UINavigationController).topViewController as! EventDetailViewController
                controller.detailEvent = event
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                if #available(iOS 11.0, *) {
                    controller.navigationController?.navigationBar.prefersLargeTitles = false
                    controller.navigationItem.largeTitleDisplayMode = .never
                    controller.navigationController?.navigationItem.largeTitleDisplayMode = .never
                } else {
                    // Fallback on earlier versions
                }
                controller.navigationItem.title = event.title.first?.value
            }
        }
    }
}

// MARK: - Extensions
// MARK: tableView extension
extension EventsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberofSections: Int = 0
        var list: [String: [Events]]
        if isUserOrganisator() {
            if selected[0] {
                list = isFiltering() ? splitFilteredFavoriteEvents : splitFavoriteEvents
            } else if selected[1] {
                list = isFiltering() ? splitFilteredPersonalEvents : splitPersonalEvents
            } else {
                list = isFiltering() ? splitFilteredEvents : splitEvents
            }
        } else {
            if selected[0] {
                list = isFiltering() ? splitFilteredFavoriteEvents : splitFavoriteEvents
            } else {
                list = isFiltering() ? splitFilteredEvents : splitEvents
            }
        }
        if (list["passed"]?.count)! > 0 {
            numberofSections += 1
        }
        if (list["upcoming"]?.count)! > 0 {
            numberofSections += 1
        }
        
        return numberofSections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var list: [String: [Events]]
        if isUserOrganisator() {
            if selected[0] {
                list = isFiltering() ? splitFilteredFavoriteEvents : splitFavoriteEvents
            } else if selected[1] {
                list = isFiltering() ? splitFilteredPersonalEvents : splitPersonalEvents
            } else {
                list = isFiltering() ? splitFilteredEvents : splitEvents
            }
        } else {
            if selected[0] {
                list = isFiltering() ? splitFilteredFavoriteEvents : splitFavoriteEvents
            } else {
                list = isFiltering() ? splitFilteredEvents : splitEvents
            }
        }
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
        
        var list: [String: [Events]]
        if isUserOrganisator() {
            if selected[0] {
                list = isFiltering() ? splitFilteredFavoriteEvents : splitFavoriteEvents
            } else if selected[1] {
                list = isFiltering() ? splitFilteredPersonalEvents : splitPersonalEvents
            } else {
                list = isFiltering() ? splitFilteredAllEvents : splitAllEvents
            }
        } else {
            if selected[0] {
                list = isFiltering() ? splitFilteredFavoriteEvents : splitFavoriteEvents
            } else {
                list = isFiltering() ? splitFilteredAllEvents : splitAllEvents
            }
        }
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
        print("reload tableview")
        var event: Events
        let list = isFiltering() ? splitFilteredEvents : splitEvents
        
        if (splitFavoriteEvents["upcoming"]?.contains(where: { $0.tid.first?.value == list["upcoming"]?.first?.tid.first?.value }))! || (splitFavoriteEvents["passed"]?.contains(where: { $0.tid.first?.value == list["passed"]?.first?.tid.first?.value }))! {
            cell.layer.borderColor = UIColor.FlatColor.Green.Fern.cgColor
        }
        cell.selectionStyle = .gray
        cell.layer.cornerRadius = 0
        cell.layer.masksToBounds = true
        cell.layer.borderWidth = 0
        
        self.tableView.isHidden = false
        switch (indexPath.section) {
        case 0:
            
            if list["upcoming"]!.count == 0 {
                event = list["passed"]![indexPath.row]
            } else {
                event = list["upcoming"]![indexPath.row]
            }
            
        default:
            event = list["passed"]![indexPath.row]
            
        }
        cell.event.text = event.title.first?.value
        
        cell.organisation.text = event.address?.first?.organization
         // return orgID from request
        
        
        cell.date.text = sanitizeDateFromJson((event.date.first?.value)!)
        cell.locality.text = event.address?.first?.locality
        cell.country.text = event.address?.first?.country_code
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if isUserOrganisator() {
            if selected[0] || selected[1] {
                return .delete
            }
        } else {
            if selected[0] {
                return .delete
            }
        }
        return .none
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // MARK: Add to Favorites
        var liveEventTitle: String = ""
        if isUserOrganisator() && String((self.events[indexPath.row].orguid.first?.id)!) == self.userDefault.value(forKey: "UID") as! String {
            liveEventTitle = "Setup or stream event"
        } else {
            liveEventTitle = "Live!"
        }
        let followLiveEvent = UITableViewRowAction(style: .default, title: liveEventTitle) { (action, indexPath) in
            // present live viewcontroller
            
        }
        followLiveEvent.backgroundColor = UIColor.FlatColor.Yellow.Turbo
        
        let addToFavorites = UITableViewRowAction(style: .normal, title: "Favorite") { (action, indexPath) in
            // Fetch Event
            switch (indexPath.section) {
            case 0:
                var list = self.isFiltering() ? self.splitFilteredEvents["upcoming"] : self.splitEvents["upcoming"]
                if (list?.isEmpty)! {
                    list = self.isFiltering() ? self.splitFilteredEvents["passed"] : self.splitEvents["passed"]
                }
                let tid: Int = (list![indexPath.row].tid.first?.value)!
                self.addFavoriteFlagging(tid: Int(tid)) // OperationQueue
                let cell = tableView.cellForRow(at: indexPath)
                UIView.animate(withDuration: 1, delay: 0.0, options: [.curveEaseIn], animations: {cell?.layer.backgroundColor = UIColor.green.withAlphaComponent(0.6).cgColor}, completion: {_ in UIView.animate(withDuration: 0.1, animations: {cell?.layer.backgroundColor = UIColor.green.withAlphaComponent(0.0).cgColor; self.tableView.reloadRows(at: [indexPath], with: .none)}) }
                )
            default:
                let list = self.isFiltering() ? self.splitFilteredEvents["passed"] : self.splitEvents["passed"]
                let tid: Int = (list![indexPath.row].tid.first?.value)!
                self.addFavoriteFlagging(tid: Int(tid)) // OperationQueue
                let cell = tableView.cellForRow(at: indexPath)
                UIView.animate(withDuration: 1, delay: 0.0, options: [.curveEaseIn], animations: {cell?.layer.backgroundColor = UIColor.green.withAlphaComponent(0.6).cgColor}, completion: {_ in UIView.animate(withDuration: 0.1, animations: {cell?.layer.backgroundColor = UIColor.green.withAlphaComponent(0.0).cgColor; self.tableView.reloadRows(at: [indexPath], with: .none)}) }
                )
            }
        }
        addToFavorites.backgroundColor = UIColor(red: 125/255, green: 0/255, blue:0/255, alpha:1)
        
        let isAlreadyFavorite = UITableViewRowAction(style: .normal, title: "Is already favorite") { (action, indexPath) in
            // Do nothing
        }
        isAlreadyFavorite.backgroundColor = UIColor.FlatColor.Green.ChateauGreen
        let deleteFromFavorite = UITableViewRowAction(style: .default, title: "Remove") { (action, indexPath) in
            // Fetch Event
            print("deleteFromFavorite")
            //self.tableView.deleteRows(at: [indexPath], with: .fade)
            switch (indexPath.section) {
            case 0:
                // Quickly remove from tableview
                var list = self.isFiltering() ? self.splitFilteredFavoriteEvents["upcoming"] : self.splitFavoriteEvents["upcoming"]
                if (list?.isEmpty)! {
                    list = self.isFiltering() ? self.splitFilteredFavoriteEvents["passed"] : self.splitFavoriteEvents["passed"]
                }
                let tid: Int = (list![indexPath.row].tid.first?.value)!
                list!.remove(at: indexPath.row)
                self.deleteFavoriteFlagging(tid: Int(tid))
                
            default:
                // Quickly remove from tableview
                //print("list of events before deleting: \(self.events.map { $0.tid })")
                var list = self.isFiltering() ? self.splitFilteredFavoriteEvents["passed"] : self.splitFavoriteEvents["passed"]
                let tid: Int = (list![indexPath.row].tid.first?.value)!
                list!.remove(at: indexPath.row)
                self.deleteFavoriteFlagging(tid: Int(tid))
            }
        }
        
        let deleteFromPersonal = UITableViewRowAction(style: .default, title: "Cancel event") { (action, indexPath) in
            // Fetch Event
            switch (indexPath.section) {
            case 0:
                // Quickly remove from tableview
                //print("list of events before deleting: \(self.events.map { $0.tid })")
                var list = self.isFiltering() ? self.splitFilteredPersonalEvents["upcoming"] : self.splitPersonalEvents["upcoming"]
                if (list?.isEmpty)! {
                    list = self.isFiltering() ? self.splitFilteredPersonalEvents["passed"] : self.splitPersonalEvents["passed"]
                }
                let tid: Int = list![indexPath.row].tid.first!.value
                list!.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.cancelEvent(tid: Int(tid))
            default:
                // Quickly remove from tableview
                //print("list of events before deleting: \(self.events.map { $0.tid })")
                var list = self.isFiltering() ? self.splitFilteredPersonalEvents["passed"] : self.splitPersonalEvents["passed"]
                let tid: Int = list![indexPath.row].tid.first!.value
                list!.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.cancelEvent(tid: Int(tid))
            }
        }
        // Show when favorites or personal are not selected
        if selected[0] {
            let list = self.isFiltering() ? self.splitFilteredEvents : self.splitEvents
            if dateStringToDate((list["upcoming"]?.first?.date.first?.value)!) == Date() {
                return [followLiveEvent, deleteFromFavorite]
            } else {
                if String((list["upcoming"]?.first?.orguid.first?.id)!) == self.userDefault.value(forKey: "UID") as! String {
                    return [followLiveEvent, deleteFromFavorite]
                }
            }
            return [deleteFromFavorite]
        } else if selected[1] && isUserOrganisator() {
            return [followLiveEvent, deleteFromPersonal]
        } else {
            let list = self.isFiltering() ? self.splitFilteredEvents : self.splitEvents
            var selectedTid: Int?
            if indexPath.section == 0 {
                if list["upcoming"]?.count != 0 {
                    selectedTid = (list["upcoming"]![indexPath.row].tid.first?.value)!
                } else {
                    selectedTid = (list["passed"]![indexPath.row].tid.first?.value)!
                }
            } else {
                selectedTid = (list["passed"]![indexPath.row].tid.first?.value)!
            }
            if isFiltering() {
                if (splitFilteredFavoriteEvents["upcoming"]?.contains(where: { $0.tid.first?.value == selectedTid }))! || (splitFilteredFavoriteEvents["passed"]?.contains(where: { $0.tid.first?.value == selectedTid }))! {
                    if dateStringToDate((list["upcoming"]?.first?.date.first?.value)!) == Date() {
                        return [followLiveEvent]
                    } else {
                        if String((list["upcoming"]?.first?.orguid.first?.id)!) == self.userDefault.value(forKey: "UID") as! String {
                            return [followLiveEvent]
                        }
                    }
                    return [isAlreadyFavorite]
                } else {
                    if dateStringToDate((list["upcoming"]?.first?.date.first?.value)!) == Date() {
                        return [addToFavorites, followLiveEvent]
                    } else {
                        if String((list["upcoming"]?.first?.orguid.first?.id)!) == self.userDefault.value(forKey: "UID") as! String {
                            return [addToFavorites, followLiveEvent]
                        }
                    }
                    return [addToFavorites]
                }
            } else {
                if (splitFavoriteEvents["upcoming"]?.contains(where: { $0.tid.first?.value == selectedTid }))! || (splitFavoriteEvents["passed"]?.contains(where: { $0.tid.first?.value == selectedTid }))! {
                    if dateStringToDate((list["upcoming"]?.first?.date.first?.value)!) == Date() {
                        return [followLiveEvent]
                    } else {
                        if String((list["upcoming"]?.first?.orguid.first?.id)!) == self.userDefault.value(forKey: "UID") as! String {
                            return [followLiveEvent]
                        }
                    }
                    return [isAlreadyFavorite]
                } else {
                    if dateStringToDate((list["upcoming"]?.first?.date.first?.value)!) == Date() {
                        return [addToFavorites, followLiveEvent]
                    } else {
                        if String((list["upcoming"]?.first?.orguid.first?.id)!) == self.userDefault.value(forKey: "UID") as! String {
                            return [addToFavorites, followLiveEvent]
                        }
                    }
                    return [addToFavorites]
                }
            }
        }
    }
}

// MARK: UISearchResultsUpdating delegate
extension EventsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        print("update search results...")
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
        if isFiltering() {
            if selected[0] {
                searchFooter.setIsFilteringEventsToShow(filteredItemCountUpcoming: splitFilteredFavoriteEvents["upcoming"]!.count, of: splitFavoriteEvents["upcoming"]!.count, filteredItemCountPassed: splitFilteredFavoriteEvents["passed"]!.count, of: splitFavoriteEvents["passed"]!.count)
            } else if selected[1] && isUserOrganisator() {
                searchFooter.setIsFilteringEventsToShow(filteredItemCountUpcoming: splitFilteredPersonalEvents["upcoming"]!.count, of: splitPersonalEvents["upcoming"]!.count, filteredItemCountPassed: splitFilteredPersonalEvents["passed"]!.count, of: splitPersonalEvents["passed"]!.count)
            } else {
                searchFooter.setIsFilteringEventsToShow(filteredItemCountUpcoming: splitFilteredEvents["upcoming"]!.count, of: splitEvents["upcoming"]!.count, filteredItemCountPassed: splitFilteredEvents["passed"]!.count, of: splitEvents["passed"]!.count)
            }
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
