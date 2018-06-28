//
//  HorsesViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 31/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
import SwiftyJSON
import CoreData

class HorsesViewController: UIViewController {
    
    // MARK: - Variables
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let opQueue: OperationQueue = OperationQueue()
    var horseDetailViewController: HorseDetailViewController? = nil
    let userDefault = UserDefaults.standard
    let searchController = UISearchController(searchResultsController: nil)
    
    var horses: [Horses] = []
    var allHorses: [Horses] = []
    var favoriteHorses: [Horses] = []
    var personalHorses: [Horses] = []
    var filteredHorses: [Horses] = []
    var filteredAllHorses: [Horses] = []
    var filteredFavoriteHorses: [Horses] = []
    var filteredPersonalHorses: [Horses] = []
    var selected: Array<Bool> = [false, false, false]
    
    var studbookDict: Dictionary<String, String> = [:]
    var yearDict: Dictionary<String, String> = [:]
    var allCoatColors = [CoatColors]()
    var allStudbooks = [Studbooks]()
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
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addHorsePopup: UIVisualEffectView!
    @IBOutlet weak var addHorsePopupView: UIView!
    @IBOutlet weak var addHorsePopupMessageTitleLabel: UILabel!
    @IBOutlet weak var addHorsePopupMessageLabel: UILabel!
    @IBOutlet weak var addHorsePopupEditButton: UIButton!
    @IBOutlet weak var addHorsePopupNewButton: UIButton!
    @IBOutlet weak var addHorsePopupCancelButton: UIButton!
    @IBOutlet weak var horseKeyPopupMessageTitleLabel: UILabel!
    @IBOutlet weak var horseKeyPopup: UIVisualEffectView!
    @IBOutlet weak var horseKeyPopupView: UIView!
    @IBOutlet weak var horseKeyCancelButton: UIButton!
    @IBOutlet weak var horseKeyPopupMessageLabel: UILabel!
    @IBOutlet weak var horseKeyVerifyButton: UIButton!
    @IBOutlet weak var passphraseHorseField: UITextField!
    
    @IBAction func passphraseSubmitButtonTapped(_ sender: UIButton) {
        // Verify identification number
        
    }
    
    @IBAction func passphraseCancelButtonTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 1, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            // Flip popup
            self.perform(#selector(self.flipBack), with: nil, afterDelay: 0.5)
            
        }, completion: nil)
    }
    @IBAction func editHorseButtonTapped(_ sender: UIButton) {
        // flip popup -> show eventKeyPopup
        UIView.animate(withDuration: 1, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            // Flip popup
            self.perform(#selector(self.flipForward), with: nil, afterDelay: 0.5)
            
        }, completion: nil)
    }
    @IBAction func addHorseButtonPopupTapped(_ sender: UIButton) {
        // navigate to addHorseViewController
    }
    @IBAction func addHorsePopupCancelButtonTapped(_ sender: UIButton) {
        // hide popup
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.addHorsePopup.alpha = 0.0
        }, completion: {(bool) in
            self.addHorsePopup.alpha = 0.0
        })
    }
    @IBOutlet var searchFooter: SearchFooter!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var syncLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableViewButtons: [UIButton]!
    @IBOutlet weak var favoriteHorsesButton: UIButton!
    @IBOutlet weak var personalHorsesButton: UIButton!
    @IBOutlet weak var notLoggedInPopup: UIVisualEffectView!
    @IBOutlet weak var noFavoritesPopup: UIVisualEffectView!
    
    @IBOutlet weak var stackViewButtons: UIStackView!
    @IBOutlet weak var allHorsesButton: UIButton!
    
    // MARK: - Outlet functions
    @IBAction func allHorses(_ sender: UIButton) {
        allHorsesButtonClicked()
    }
    @IBAction func favoriteHorses(_ sender: UIButton) {
        favoriteHorsesButtonClicked()
    }
    
    @IBAction func personalHorses(_ sender: UIButton) {
        personalHorsesButtonClicked()
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
    
    @IBAction func unwindSegueCancel(_ sender: UIStoryboardSegue) {
        // Do nothing
    }
    
    @IBAction func unwindSegueSave(_ sender: UIStoryboardSegue) {
        // Post and request new data
        if let sVC = sender.source as? AddFavoriteHorseViewController {
            let newFavorites: [Horses] = sVC.favorites
            let newPersonal: [Horses] = sVC.personal
            if !newFavorites.isEmpty {
                tableView.reloadData()
                // Save to server
            }
            if !newPersonal.isEmpty {
                tableView.reloadData()
                // Save to server
            }
        }
    }
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load horseviewController")
        if let splitViewController = splitViewController {
            let controllers = splitViewController.viewControllers
            horseDetailViewController = (controllers[controllers.count - 1] as! UINavigationController).topViewController as? HorseDetailViewController
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
            favoriteHorsesButtonClicked()
        } else if selected[1] {
            personalHorsesButtonClicked()
        } else if selected[2] {
            allHorsesButtonClicked()
        } else {
            // Synchronize with online horse data
            print("requestAnonymousHorseData")
            fetchHorses()
            
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK: - setup Layout
    func setupLayout() {
        navigationItem.titleView?.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        navigationItem.titleView?.tintColor = UIColor.FlatColor.Gray.IronGray
        
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
        personalHorsesButton.addLeftBorder(borderColor: UIColor.FlatColor.Gray.WhiteSmoke, borderWidth: 1.0)
        allHorsesButton.addLeftBorder(borderColor: UIColor.FlatColor.Gray.WhiteSmoke, borderWidth: 1.0)
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
            searchController.searchBar.placeholder = "Search horses"
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
        
        addHorsePopup.alpha = 0
        originalCenter = horseKeyPopup.center
        addHorsePopup.center = self.originalCenter
        addHorsePopup.layer.cornerRadius = 15
        addHorsePopup.layer.masksToBounds = true
        addHorsePopup.layer.borderWidth = 1.5
        addHorsePopupView.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        addHorsePopupView.layer.cornerRadius = 15
        addHorsePopupView.layer.masksToBounds = true
        addHorsePopupView.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
        addHorsePopupMessageLabel.adjustsFontSizeToFitWidth = true
        addHorsePopupMessageTitleLabel.adjustsFontSizeToFitWidth = true
        
        
        addHorsePopupEditButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        addHorsePopupEditButton.layer.borderWidth = 1.5
        addHorsePopupEditButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        addHorsePopupEditButton.layer.cornerRadius = 5
        addHorsePopupEditButton.layer.masksToBounds = true
        addHorsePopupNewButton.tintColor = UIColor.white
        addHorsePopupNewButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        addHorsePopupNewButton.layer.borderWidth = 1.5
        addHorsePopupNewButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        addHorsePopupNewButton.layer.cornerRadius = 5
        addHorsePopupNewButton.layer.masksToBounds = true
        addHorsePopupNewButton.tintColor = UIColor.white
        addHorsePopupCancelButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        addHorsePopupCancelButton.layer.borderWidth = 1.5
        addHorsePopupCancelButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        addHorsePopupCancelButton.layer.cornerRadius = 5
        addHorsePopupCancelButton.layer.masksToBounds = true
        addHorsePopupCancelButton.tintColor = UIColor.white
        
        horseKeyPopup.alpha = 0
        originalCenter = horseKeyPopup.center
        horseKeyPopup.center = self.originalCenter
        horseKeyPopup.layer.cornerRadius = 15
        horseKeyPopup.layer.masksToBounds = true
        horseKeyPopup.layer.borderWidth = 1.5
        horseKeyPopupView.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        horseKeyPopupView.layer.cornerRadius = 15
        horseKeyPopupView.layer.masksToBounds = true
        horseKeyPopupView.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
        horseKeyPopupMessageLabel.adjustsFontSizeToFitWidth = true
        horseKeyPopupMessageTitleLabel.adjustsFontSizeToFitWidth = true
        
        horseKeyVerifyButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        horseKeyVerifyButton.layer.borderWidth = 1.5
        horseKeyVerifyButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        horseKeyVerifyButton.layer.cornerRadius = 5
        horseKeyVerifyButton.layer.masksToBounds = true
        horseKeyVerifyButton.tintColor = UIColor.white
        horseKeyCancelButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        horseKeyCancelButton.layer.borderWidth = 1.5
        horseKeyCancelButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        horseKeyCancelButton.layer.cornerRadius = 5
        horseKeyCancelButton.layer.masksToBounds = true
        horseKeyCancelButton.tintColor = UIColor.white
    }
    
    
    // MARK: - Essential data functions
    
    
    
    // MARK: request horse data
    func requestHorseData(_ urlString: String, completion: @escaping ([Horses]) -> ()) {
        /// function to get taxonomies from CMS
        print("requesting horse data")
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
                        completion(self.horses)
                    }
                    var horses: [Horses]?
                    switch(response.result) {
                    case .success:
                        if response.result.value != nil {
                            do {
                                horses = try JSONDecoder().decode([Horses].self, from: response.data!)
                                print("horses decoded")
                            } catch {
                                print("Could not decode horses: \(error)")
                                horses = []
                            }
                        }
                        completion(horses!)
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
    
    // MARK: request favorite or personal horse data
    func requestPersonalHorseData(_ urlString: String, completion: @escaping (_ success: [Horses]) -> ()) {
        /// function to get taxonomies from CMS
        print("requesting horse data")
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
                    var horses: [Horses]?
                    switch(response.result) {
                    case .success:
                        if response.result.value != nil {
                            do {
                                horses = try JSONDecoder().decode([Horses].self, from: response.data!)
                            } catch {
                                print("Could not decode horses: \(error)")
                                horses = []
                            }
                        }
                        completion(horses!)
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
    func requestJSON(_ urlString: String, headers: Dictionary<String, String>, success: @escaping (_ result: [Horses]) -> Void, failure: @escaping (_ error: Error?) -> Void)  {
        print("Requesting JSON...")
        
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<299)
            .validate(contentType: ["application/json"])
            .responseData { (response) in
                var horses: [Horses]?
                switch(response.result) {
                case .success:
                    //print("data: \(response.data!)")
                    if response.result.value != nil {
                        
                        do {
                            horses = try JSONDecoder().decode([Horses].self, from: response.data!)
                            
                            success(horses!)
                            print("horse data decoded")
                        } catch {
                            print("Could not decode horse data")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to obtain favorite/personal horses failed with error: \(error)")
                    failure(error)
                    break
                }
        }
    }
    
    // MARK: Add flagging to horse
    func addFavoriteFlagging(tid: Int) {
        if ConnectionCheck.isConnectedToNetwork() {
            // Prep headers
            let username = self.userDefault.string(forKey: "Username")
            let password = self.getPasswordFromKeychain(username!)
            let credentialData = "\(username!):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            
            // Prep parameters for flagging
            let flag_name: String = "add_horse_to_favorites"
            let action: String = "flag"
            let user_uid = self.userDefault.value(forKey: "UID") as! String
            let entity_id: String = String(tid)
            let parameters: [String: Any] = ["flag_id": [["target_id": flag_name, "target_type": action]], "entity_type": [["value": "node"]], "entity_id": [["value": entity_id]], "uid": [["target_id": Int(user_uid)]]]
            let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            
            Alamofire.request("https://jumpingtracker.com/entity/flagging?_format=json", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .responseJSON { response in
                    switch response.result {
                    case .success:
                        print("Success with adding favorite flag to horse: \(String(describing: response.result.value))")
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
    // MARK: Patch favorites to User
    func deleteFavoriteFlagging(tid: Int) {
        // Try to post only the horse ID!!!
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
                            print("horse data decoded")
                        } catch {
                            print("Could not decode horse data")
                        }
                    } else {
                        print("response: \(String(describing: response.result.value))")
                    }
                    break
                case .failure(let error):
                    print("Request to obtain favorite/personal horses failed with error: \(error)")
                    failure(error)
                    break
                }
        }
    }
    
    // MARK: obtain horses from favorite or personal
    func obtainPersonalHorses(list: String) {
        notLoggedInPopup.alpha = 0
        noFavoritesPopup.alpha = 0
        self.activityIndicator.isHidden = false
        // Preload existing list
        if list == "favorite" {
            self.horses = self.favoriteHorses
            self.filteredHorses = self.filteredFavoriteHorses
            print("filtering = \(isFiltering())")
        } else if list == "personal" {
            self.horses = self.personalHorses
            self.filteredHorses = self.filteredPersonalHorses
        }
        self.tableView.reloadData()
        
        if userDefault.bool(forKey: "loginSuccessful") { // User needs to be logged in
            let favoriteHorseBlockOperation = BlockOperation {
                // No uid needed (internal function in Flag module!)
                self.requestPersonalHorseData("https://jumpingtracker.com/rest/export/json/\(list)_horses2?_format=json", completion: { result in
                    
                    let horsedata: [Horses] = result as [Horses]
                    self.horses = horsedata
                    if list == "favorite" {
                        self.favoriteHorses = horsedata
                    } else if list == "personal" {
                        self.personalHorses = horsedata
                    }
                    if self.horses.isEmpty {
                        DispatchQueue.main.async {
                            if list == "personal" {
                                self.showNoResults(title: "No \(list) horses", message: "Click on the plus sign to create a new horse.")
                            } else if list == "favorite" {
                                self.showNoResults(title: "No \(list) horses", message: "Go to 'All' horses and swipe left to make a horse your favorite, or tap 'Add'.")
                            }
                        }
                    } else {
                        if self.isFiltering() {
                            if list == "favorite" {
                                self.filteredHorses = self.filteredFavoriteHorses
                            } else if list == "personal" {
                                self.filteredHorses = self.filteredPersonalHorses
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
            opQueue.addOperation(favoriteHorseBlockOperation)
        } else {
            print("Login to view your \(list) horses or register to add \(list) horses.")
            self.progressView.isHidden = true
            self.syncLabel.isHidden = true
            self.activityIndicator.isHidden = true
            self.progressView.progress = 0.0
            // Show label over tableView
            showNotLoggedInMessage("Login to view your \(list) horses. Registered users can add \(list) horses to their account.")
            
        }
    }
    
    // MARK: Fetch all horses
    func fetchHorses() {
        let allHorsesBlockOperation = BlockOperation {
            self.requestHorseData("https://jumpingtracker.com/rest/export/json/horses?_format=json", completion: { result in
                self.horses = result
                self.allHorses = result
                print("Result from requestHorseData arrived:")
                
                // Store horses in core data to retrieve name of father and mother
                self.appDelegate.persistentContainer.performBackgroundTask({ (context) in
                    for item in result {
                        let horse: Horse = NSEntityDescription.insertNewObject(forEntityName: "CoreHorses", into: context) as! Horse
                        horse.allAtributes = item
                        
                    }
                    do {
                        try context.save()
                    } catch {
                        print("Could not save horse to core data")
                    }
                })
                
                DispatchQueue.main.async {
                    print("Queue async")
                    self.tableView.reloadData()
                    self.progressView.isHidden = true
                    self.syncLabel.isHidden = true
                    self.activityIndicator.isHidden = true
                    self.progressView.progress = 0.0
                    if self.horses.isEmpty {
                        print("horses is empty")
                        self.tableView.isHidden = true
                    } else {
                        print("horses is not empty")
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
        opQueue.addOperations([allHorsesBlockOperation, reloadOperation], waitUntilFinished: true)
        //opQueue.addOperation(allHorsesBlockOperation)
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
    
    
    // MARK: get name from tid
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
    
    // MARK: filter content for search text
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredHorses = horses.filter({( horse : Horses) -> Bool in
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
            for discID in (horse.discipline?.map { $0.id })! {
                let discName = getName("CoreDisciplines", Int(discID), "name")
                discNameArray.append(discName)
            }
            let doesCategoryMatch = (newScope == "All") || discNameArray.contains(scopeID)
            
            if searchBarIsEmpty() {
                return doesCategoryMatch
            } else {
                return doesCategoryMatch && (horse.name.first?.value.lowercased().contains(searchText.lowercased()))!
            }
        })
        self.tableView.reloadData()
    }
    
    
    
    // MARK: - Supplementary functions
    // MARK: enable verify button when fields are filled
    func setupAddTargetIsNotEmptyTextFields() {
        horseKeyVerifyButton.isEnabled = false
        passphraseHorseField.addTarget(self, action: #selector(textFieldIsNotEmpty), for: .editingChanged)
    }
    
    
    // MARK: pin background stackview
    private func pinBackground(_ view: UIView, to stackView: UIStackView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        stackView.insertSubview(view, at: 0)
        view.pin(to: stackView)
    }
    
    
    // MARK: update progress view
    func updateProgress(progress: Float) {
        print("progress: \(progress)")
        progressView.progress = progress
    }
    
    
    // MARK: favorites button tapped
    func favoriteHorsesButtonClicked() {
        selected = [true, false, false]
        allHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        favoriteHorsesButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        personalHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        obtainPersonalHorses(list: "favorite")
    }
    
    
    
    // MARK: personal button tapped
    func personalHorsesButtonClicked() {
        selected = [false, true, false]
        allHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        favoriteHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        personalHorsesButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        obtainPersonalHorses(list: "personal")
    }
    
    
    // MARK: all button tapped
    func allHorsesButtonClicked() {
        print("allHorsesButtonClicked")
        noFavoritesPopup.alpha = 0
        notLoggedInPopup.alpha = 0
        horseKeyPopup.alpha = 0
        tableView.isEditing = false
        selected = [false, false, true]
        // Quickly load previously downloaded data
        self.horses = self.allHorses
        self.filteredHorses = self.filteredAllHorses
        self.tableView.reloadData()
        allHorsesButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        favoriteHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        personalHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        // Synchronize in background
        fetchHorses()
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
    // MARK: date string to date format
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
    
    // MARK: - date passed boolean
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
    
    // MARK: - Popup views
    // MARK: show no results
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
    
    
    // MARK: - selector objects
    @objc func textFieldIsNotEmpty(sender: UITextField) {
        sender.text = sender.text?.trimmingCharacters(in: .whitespaces)
        
        guard
            let horseKey = passphraseHorseField.text, !horseKey.isEmpty
            else
        {
            self.horseKeyVerifyButton.isEnabled = false
            self.horseKeyVerifyButton.alpha = 0.5
            return
        }
        horseKeyVerifyButton.isEnabled = true
        horseKeyVerifyButton.alpha = 1.0
    }
    
    @objc func resyncTapped() {
        notLoggedInPopup.alpha = 0
        noFavoritesPopup.alpha = 0
        horseKeyPopup.alpha = 0
        addHorsePopup.alpha = 0
        // Synchronize horses
        if selected[0] {
            favoriteHorses(favoriteHorsesButton)
        } else if selected[1] {
            personalHorses(personalHorsesButton)
        } else {
            allHorses(allHorsesButton)
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
            // Add horse to favo
            self.horseKeyPopup.alpha = 0.0
            self.notLoggedInPopup.alpha = 0.0
            addHorsePopup.alpha = 0
            
            allHorsesButtonClicked()
            UIView.animate(withDuration: 1, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                self.noFavoritesMessageTitleLabel.text = "Add favorite horse"
                self.noFavoritesMessageLabel.text = "Swipe left to add a horse to your favorites"
                self.noFavoritesPopup.alpha = 1.0
            }) { (bool) in
                UIView.animate(withDuration: 1, delay: 2.5, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                    self.noFavoritesPopup.alpha = 0.0
                }, completion: nil )}
            
        } else {
            self.notLoggedInPopup.alpha = 0.0
            self.noFavoritesPopup.alpha = 0.0
            addHorsePopup.alpha = 0
            
            // Ask for horse identification to add an existing(!) horse to personal list
            UIView.animate(withDuration: 1, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
                self.addHorsePopup.alpha = 1.0
            }, completion: nil)
        }
        
        
    }
    
    @objc func addNewHorse() {
        // Add a horse to the list
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "AddNewHorse") as! AddNewHorseViewController
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc func flipForward() {
        let transitionOptions: UIViewAnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        UIView.transition(with: self.addHorsePopup, duration: 1.0, options: transitionOptions, animations: {
            self.addHorsePopup.alpha = 0.0
        }, completion: nil)
        UIView.transition(with: self.horseKeyPopup, duration: 1.0, options: transitionOptions, animations: {
            self.horseKeyPopup.alpha = 1.0
        }, completion: nil)
    }
    
    @objc func flipBack() {
        let transitionOptions: UIViewAnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        UIView.transition(with: self.horseKeyPopup, duration: 1.0, options: transitionOptions, animations: {
            self.horseKeyPopup.alpha = 0.0
        }, completion: nil)
        UIView.transition(with: self.addHorsePopup, duration: 1.0, options: transitionOptions, animations: {
            self.addHorsePopup.alpha = 1.0
        }, completion: nil)
    }
    // MARK: - prepare segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToHorseDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                var horse: Horses
                var list: [Horses]
                if selected[0] {
                    list = isFiltering() ? filteredFavoriteHorses : favoriteHorses
                } else if selected[1] {
                    list = isFiltering() ? filteredPersonalHorses: personalHorses
                } else {
                    list = isFiltering() ? filteredHorses : horses
                }
                horse = list[indexPath.row]
                if horse.father != nil {
                    let father = list.filter { $0.tid == Int(horse.father?.first?.id)! }
                }
                let controller = (segue.destination as! UINavigationController).topViewController as! HorseDetailViewController
                controller.detailHorse = horse
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                if #available(iOS 11.0, *) {
                    controller.navigationController?.navigationBar.prefersLargeTitles = false
                    controller.navigationItem.largeTitleDisplayMode = .never
                    controller.navigationController?.navigationItem.largeTitleDisplayMode = .never
                } else {
                    // Fallback on earlier versions
                }
                controller.navigationItem.title = horse.name.first?.value
            }
        }
    }
}

// MARK: - Extensions
// MARK: tableView extension
extension HorsesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let list = isFiltering() ? filteredHorses : horses
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HorseTableCell", for: indexPath) as? HorseTableCell else {
            fatalError("Unexpected Index Path")
        }
        let horse: Horses
        let list = isFiltering() ? filteredHorses : horses
        
        horse = list[indexPath.row]
        
        cell.selectionStyle = .gray
        cell.layer.cornerRadius = 0
        cell.layer.masksToBounds = true
        cell.layer.borderWidth = 0
        
        self.tableView.isHidden = false
        cell.horseName.text = horse.name.first?.value
        let idArray: Array<Int32> = (horse.studbook?.map { $0.id })!
        var acroArray: Array<String> = []
        if idArray.count > 0 {
            for id in idArray {
                let acroString = getName("CoreStudbooks", Int(id), "acro")
                acroArray.append(acroString)
            }
        } else {
            acroArray = [""]
        }
        cell.studbook.text = acroArray.joined(separator: ", ")
        cell.horseOwner.text = horse.owner?.first?.owner
        
        if horse.birthday?.first != nil {
            // Optional value birthday
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreJaartallen")
            fetchRequest.predicate = NSPredicate(format: "tid == %d", (horse.birthday?.first?.id)!)
            var jaartal: String = ""
            do {
                let result = try self.appDelegate.getContext().fetch(fetchRequest)
                for r in result as! [Year] {
                    let jaar = r.allAtributes
                    jaartal = (jaar.year.first?.year)!
                }
                cell.birthDay.text = jaartal
            } catch {
                cell.birthDay.text = ""
            }
        } else {
            cell.birthDay.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if selected[0] {
            return .delete
        }
        return .none
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // MARK: Add to Favorites
        let addToFavorites = UITableViewRowAction(style: .normal, title: "Favorite") { (action, indexPath) in
            // Fetch Horse
            let list = self.isFiltering() ? self.filteredHorses : self.horses
            let tid: Int = (list[indexPath.row].tid.first?.value)!
            self.addFavoriteFlagging(tid: Int(tid)) // OperationQueue
            let cell = tableView.cellForRow(at: indexPath)
            UIView.animate(withDuration: 1, delay: 0.0, options: [.curveEaseIn], animations: {cell?.layer.backgroundColor = UIColor.green.withAlphaComponent(0.6).cgColor}, completion: {_ in UIView.animate(withDuration: 0.1, animations: {cell?.layer.backgroundColor = UIColor.green.withAlphaComponent(0.0).cgColor; self.tableView.reloadRows(at: [indexPath], with: .none)}) }
            )
        }
        addToFavorites.backgroundColor = UIColor(red: 125/255, green: 0/255, blue:0/255, alpha:1)
        
        // MARK: Add to Personal
        // TODO: Add identification popup!
        let addToPersonals = UITableViewRowAction(style: .normal, title: "Personal") { (action, indexPath) in
            // Fetch Horse
            let list = self.isFiltering() ? self.filteredHorses : self.horses
            let tid: Int = (list[indexPath.row].tid.first?.value)!
            self.addFavoriteFlagging(tid: Int(tid)) // OperationQueue
            // Adjust in Core Data
            let cell = tableView.cellForRow(at: indexPath)
            UIView.animate(withDuration: 1, delay: 0.0, options: [.curveEaseIn], animations: {cell?.layer.backgroundColor = UIColor.green.withAlphaComponent(0.6).cgColor}, completion: {_ in UIView.animate(withDuration: 0.1, animations: {cell?.layer.backgroundColor = UIColor.green.withAlphaComponent(0.0).cgColor; self.tableView.reloadRows(at: [indexPath], with: .none)}) }
            )
        }
        addToPersonals.backgroundColor = UIColor(red: 85/255, green: 0/255, blue:0/255, alpha:1)
        
        let deleteFromFavorite = UITableViewRowAction(style: .default, title: "Remove") { (action, indexPath) in
            // Fetch Horse
            let list = self.isFiltering() ? self.filteredFavoriteHorses : self.favoriteHorses
            let tid: Int = (list[indexPath.row].tid.first?.value)!
            self.addFavoriteFlagging(tid: Int(tid)) // OperationQueue
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        let deleteFromPersonal = UITableViewRowAction(style: .default, title: "Remove") { (action, indexPath) in
            // Fetch Horse
            let list = self.isFiltering() ? self.filteredPersonalHorses : self.personalHorses
            let tid: Int = (list[indexPath.row].tid.first?.value)!
            self.addFavoriteFlagging(tid: Int(tid)) // OperationQueue
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        // Show when favorites or personal are not selected
        if selected[0] {
            return [deleteFromFavorite]
        } else if selected[1] {
            return [deleteFromPersonal]
        } else {
            return [addToPersonals, addToFavorites]
        }
    }
}

// MARK: UISearchResultsUpdating delegate
extension HorsesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        print("update search results...")
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
        if isFiltering() {
            if selected[0] {
                searchFooter.setIsFilteringToShow(filteredItemCount: filteredFavoriteHorses.count, of: favoriteHorses.count)
            } else if selected[1] {
                searchFooter.setIsFilteringToShow(filteredItemCount: filteredPersonalHorses.count, of: personalHorses.count)
            } else {
                searchFooter.setIsFilteringToShow(filteredItemCount: filteredHorses.count, of: horses.count)
            }
        } else {
            searchFooter.setNotFiltering()
        }
    }
    
}

// MARK: UISearchBarDelegate extension
extension HorsesViewController: UISearchBarDelegate {
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

extension HorsesViewController: UISplitViewControllerDelegate {
    // MARK: - Split view
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? HorseDetailViewController else { return false }
        if topAsDetailController.detailHorse == nil {
            // Return true to indicate that we have handled the collapse by doing nothing
            return true
        }
        return false
    }
}
