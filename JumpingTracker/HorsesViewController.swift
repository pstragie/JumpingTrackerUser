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
    var filteredHorses = [Horses]()
    var horses: [Horses] = []
    var allHorses = [Horses]()
    var favoriteHorses = Array<Horses>()
    var personalHorses = Array<Horses>()
    var jumpingHorses = Array<Horses>()
    var selected: Array<Bool> = [false, false, false]
    var studbookDict: Dictionary<String, String> = [:]
    var yearDict: Dictionary<String, String> = [:]
    var disciplineDict: Dictionary<String, String> = [:]
    var originalCenter: CGPoint!
    var categoryAdd: String = ""
    var rightBarButtons: [UIBarButtonItem] = []
    private lazy var stackBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.FlatColor.Blue.Denim
        return view
    }()
    
    var allCoatColors = [CoatColors]()
    var allStudbooks = [Studbooks]()
    // MARK: - Outlets

    @IBOutlet weak var notLoggedInPopupView: UIView!
    @IBOutlet weak var noFavoritesPopupView: UIView!
    @IBOutlet weak var notLoggedInMessageTitleLabel: UILabel!
    @IBOutlet weak var notLoggedInMessageLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var noFavoritesMessageTitleLabel: UILabel!
    @IBOutlet weak var noFavoritesMessageLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
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
        let vc: UITabBarController = mainStoryboard.instantiateInitialViewController() as! UITabBarController
        vc.selectedIndex = 0
        self.present(vc, animated: true, completion: nil)
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
                fetchAndStoreAsFavorite(tid: newFavorites.map { ($0.tid.first?.value)! } , addToList: true, list: "favorite")
                tableView.reloadData()
                patchFavoritesToUser(true, newFavorites, "favorite")
            }
            if !newPersonal.isEmpty {
                fetchAndStoreAsFavorite(tid: newPersonal.map { ($0.tid.first?.value)! }, addToList: true, list: "personal")
                tableView.reloadData()
                patchFavoritesToUser(true, newPersonal, "personal")
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
        getHorseData() // preload with existing horses in CoreHorses
        // Synchronize with online horse data
        requestHorseData()
    
        // Do any additional setup after loading the view, typically from a nib.
        
        setupNavBar()
        setupLayout()
        configureTableView()
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
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - get data
    func getHorseData() {
        if selected[0] {
            // request favorites
            favoriteHorsesButtonClicked()
        } else if selected[1] {
            // request personal
            personalHorsesButtonClicked()
        } else {
            preloadCoreData()
        }
    }
    
    func requestHorseData() {
        let blockOperation = BlockOperation {
            self.requestHorseData("https://jumpingtracker.com/rest/export/json/horses?_format=json", completion: { (result) in
                self.horses = result
                print("Result from requestHorseData arrived:")
                Thread.printCurrent()
                self.appDelegate.persistentContainer.performBackgroundTask({ (context) in
                    print("storing data in Core Data...")
                    // Store in core data
                    Thread.printCurrent()
                    for items in result {
                        
                        let horse: Horse = NSEntityDescription.insertNewObject(forEntityName: "CoreHorses", into: context) as! Horse
                        horse.allAtributes = items
                    }
                    do {
                        try context.save()
                        print("finished storing data in Core Data!")
                    } catch {
                        print("Could not save in privateQueue!")
                    }
                })
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.progressView.isHidden = true
                    self.syncLabel.isHidden = true
                    self.activityIndicator.isHidden = true
                    self.progressView.progress = 0.0
                    if self.horses.isEmpty {
                        self.tableView.isHidden = true
                    } else {
                        self.tableView.isHidden = false
                    }
                }
            })
                
        }
        
        opQueue.addOperation(blockOperation)
        
        
    }

    // MARK: request horse data
    func requestHorseData(_ urlString: String, completion: @escaping ([Horses]) -> ()) {
        /// function to get taxonomies from CMS
        print("requesting horse data")
        Thread.printCurrent()
        if ConnectionCheck.isConnectedToNetwork() {
            
            let username = "swift_username_request_data"
            let password = "JTIsabelle29?"
            
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
                    switch(response.result) {
                    case .success:
                        if response.result.value != nil {
                            do {
                                let horses: [Horses] = try JSONDecoder().decode([Horses].self, from: response.data!)
                                
                                completion(horses)
                                print("horses decoded")
                            } catch {
                                print("Could not decode horses: \(error)")
                            }
                        }
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
        self.noFavoritesPopup.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
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
        noFavoritesMessageTitleLabel.adjustsFontSizeToFitWidth = true

        //noFavoritesPopupView.setGradientBackground()
        addButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        addButton.layer.borderWidth = 1.5
        addButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        addButton.layer.cornerRadius = 5
        addButton.layer.masksToBounds = true
        addButton.tintColor = UIColor.white
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
    func requestJSON(_ urlString: String, headers: Dictionary<String, String>, success: @escaping (_ favoriteHorses: [User.FavHorses], _ personalHorses: [User.PerHorses]) -> Void, failure: @escaping (_ error: Error?) -> Void)  {
        print("Requesting JSON...")
        
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<299)
            .validate(contentType: ["application/json"])
            .responseData { (response) in
                
                switch(response.result) {
                case .success:
                    print("data: \(response.data!)")
                    if response.result.value != nil {
                    
                        do {
                            let userData: User = try JSONDecoder().decode(User.self, from: response.data!)
                            let favoriteHorses = userData.favHorses
                            let personalHorses = userData.perHorses
                            success(favoriteHorses!, personalHorses!)
                            print("userdata decoded")
                        } catch {
                            print("Could not decode userdata")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    failure(error)
                    break
                }
        }
    }
    
    
    
    
    // MARK: Patch favorites to User
    func patchFavoritesToUser(_ add: Bool, _ newFavorites: [Horses], _ list: String) {
        // Try to post only the horse ID!!!
        if ConnectionCheck.isConnectedToNetwork() {
            var newPatch: User?
            var newUserFav: [User.FavHorses] = []
            var newUserPer: [User.PerHorses] = []
            let username = userDefault.string(forKey: "Username")
            let password = getPasswordFromKeychain(username!)
            let credentialData = "\(username!):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            let loginRequest = ["username": username!, "password": password as Any]
            let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            
            // fetch new token
            requestToken(parameters: loginRequest, headers: headers, success: { (token) in
                self.userDefault.set(token, forKey: "token")
                print("Token successfully received!")
                let uid = self.userDefault.value(forKey: "UID")
                // fetch user data and collect existing favorite (and personal horses)
                self.requestJSON("https://jumpingtracker.com/user/\(uid!)?_format=json", headers: headers, success: { (favoriteHorses, personalHorses) in
                    
                    let firstname: [User.FirstName] = [User.FirstName(value: self.userDefault.value(forKey: "firstname") as! String)]
                    let surname: [User.SurName] = [User.SurName(value: self.userDefault.value(forKey: "surname") as! String)]
                    if list == "favorite" {
                        if add {
                            newUserFav = favoriteHorses
                        }
                        // add new favorites to existing favorites
                        if newFavorites.isEmpty {
                            newUserFav = []
                        } else {
                            for fav in newFavorites {
                                newUserFav.append(User.FavHorses(id: Int((fav.tid.first?.value)!), type: "taxonomy_term", uuid: (fav.uuid.first?.value)!, url: "/taxonomy/term/\((fav.tid.first?.value)!)"))
                            }
                        }
                        newPatch = User(firstName: firstname, surName: surname, favHorses: newUserFav, perHorses: nil)
                    } else if list == "personal" {
                        if add {
                            newUserPer = personalHorses
                        }
                        if newFavorites.isEmpty {
                            newUserPer = []
                        } else {
                            for per in newFavorites {
                                newUserPer.append(User.PerHorses(id: Int((per.tid.first?.value)!), type: "taxonomy_term", uuid: (per.uuid.first?.value)!, url: "/taxonomy/term/\((per.tid.first?.value)!)"))
                            }
                        }
                        newPatch = User(firstName: firstname, surName: surname, favHorses: nil, perHorses: newUserPer)
                    }
                    
                    
                    
                    // Encode array of dictionaries to JSON
                    let encodedDataUserPatch = try? JSONEncoder().encode(newPatch)
                    // patch user data with new favorite horses to field_favorite_horses
                    // Alamofire patch
                    let parameters = try? JSONSerialization.jsonObject(with: encodedDataUserPatch!) as? [String:Any]
                    // header with token for JWT_auth
                    //let headers = ["Authorization": "Bearer: \(self.userDefault.value(forKey: "token")!)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
                    // header with credentials for basic_auth
                    let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
                    Alamofire.request("https://jumpingtracker.com/user/\(uid!)?_format=json", method: .patch, parameters: parameters!, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
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
            }, failure: { (error) in
                print("Token failure")
            })
            
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
    func favoriteHorsesButtonClicked() {
        selected = [true, false, false]
        notLoggedInPopup.alpha = 0
        noFavoritesPopup.alpha = 0
        preloadCoreData()
        self.tableView.reloadData()
        allHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        favoriteHorsesButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        personalHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        if userDefault.value(forKey: "UID") != nil {
            
            requestHorseData("https://jumpingtracker.com/rest/export/json/favorite_horses/\(self.userDefault.value(forKey: "UID")!)?_format=json", completion: { result in
                self.horses = result
                if self.horses.isEmpty {
                    self.showNoResults(title: "No favorite horses", message: "You have not added any favorite horses yet.")
                } else {
                    self.resetFavorites(bool: false, list: "favorite")
                    
                    var tids: Array<Int32> = []
                    for h in self.horses {
                        tids.append(Int32(h.tid[0].value))
                    }
                    self.fetchAndStoreAsFavorite(tid: tids, addToList: true, list: "favorite")
                    
                    self.noFavoritesPopup.alpha = 0
                    self.tableView.reloadData()
                }
                self.progressView.isHidden = true
                self.syncLabel.isHidden = true
                self.activityIndicator.isHidden = true
                self.progressView.progress = 0.0
            })
            
        } else {
            print("Login to view your favorite horses or register to add favorite horses.")
            // Show label over tableView
            showNotLoggedInMessage("Login to view your favorite horses. Registered users can add favorite horses to their list of favorites.")
        }
    }
    
    // MARK: personal button tapped
    func personalHorsesButtonClicked() {
        selected = [false, true, false]
        notLoggedInPopup.alpha = 0
        noFavoritesPopup.alpha = 0
        preloadCoreData()
        self.tableView.reloadData()
        allHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        favoriteHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        personalHorsesButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        if userDefault.value(forKey: "UID") != nil {
            requestHorseData("https://jumpingtracker.com/rest/export/json/personal_horses/\(self.userDefault.value(forKey: "UID")!)?_format=json", completion: { result in
                self.horses = result
                if self.horses.isEmpty {
                    self.showNoResults(title: "No personal horses", message: "You have not added any personal horses yet.")
                } else {
                    self.resetFavorites(bool: false, list: "favorite")
                    var tids: Array<Int32> = []
                    for h in self.horses {
                        tids.append(h.tid[0].value)
                    }
                    self.fetchAndStoreAsFavorite(tid: tids, addToList: true, list: "personal")
                    
                    self.noFavoritesPopup.alpha = 0
                    self.tableView.reloadData()
                }
                self.progressView.isHidden = true
                self.syncLabel.isHidden = true
                self.activityIndicator.isHidden = true
                self.progressView.progress = 0.0
            })
            
        } else {
            print("Login to view your favorite horses or register to add favorite horses.")
            // Show label over tableView
            showNotLoggedInMessage("Login to view your personal horses. Registered users can add personal horses to their personal list.")
        }
    }
    
    // MARK: all button tapped
    func allHorsesButtonClicked() {
        noFavoritesPopup.alpha = 0
        notLoggedInPopup.alpha = 0
        selected = [false, false, true]
        preloadCoreData()
        self.tableView.reloadData()
        allHorsesButton.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        favoriteHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        personalHorsesButton.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        requestHorseData("https://jumpingtracker.com/rest/export/json/horses?_format=json", completion: { result in
            self.horses = result
            self.tableView.reloadData()
            self.progressView.isHidden = true
            self.syncLabel.isHidden = true
            self.activityIndicator.isHidden = true
            self.progressView.progress = 0.0
            if self.horses.isEmpty {
                self.tableView.isHidden = true
            } else {
                self.tableView.isHidden = false
            }
        })
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
        
        noFavoritesPopup.layer.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        noFavoritesPopup.center.y = noFavoritesPopup.center.y - (noFavoritesPopup.frame.height / 2)
        noFavoritesPopup.transform = CGAffineTransform(rotationAngle: 1.8)
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            self.noFavoritesPopup.transform = .identity
        }) { (success) in
            self.noFavoritesPopup.center = self.originalCenter
            self.noFavoritesPopup.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        }
        noFavoritesPopup.alpha = 1
        tableView.isUserInteractionEnabled = true
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
        tableView.isUserInteractionEnabled = true
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
        tableView.reloadData()
    }
    
    // MARK: - Core Data
    func preloadCoreData() {
        print("preloading core data")
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreHorses")
        if selected[0] {
            fetchRequest.predicate = NSPredicate(format: "favorite == YES")
        } else if selected[1] {
            fetchRequest.predicate = NSPredicate(format: "personal == YES")
        }
        fetchRequest.includesSubentities = false
        
        do {
            let result = try context.fetch(fetchRequest)
            for data in result as! [Horse] {
                let horse: Horses = data.allAtributes
                self.horses.append(horse)
            }
        } catch {
            print("error executing fetch request: \(error)")
        }
    }
    
    
    func doesEntityExist(tid: Int) -> Bool {
        let context = appDelegate.persistentContainer.viewContext

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreHorses")
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
    
    func fetchFavPerList(list: String) -> [Horses] {
        var favPerHorses: [Horses] = []
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreHorses")
        fetchRequest.predicate = NSPredicate(format: "\(list) == YES")
        fetchRequest.includesSubentities = false
        
        do {
            let results = try context.fetch(fetchRequest)
            for horse in results as! [Horses] {
                favPerHorses.append(horse)
            }
        } catch {
            print("Could not update: \(error)")
        }
        return favPerHorses
    }
    
    
    
    func updateFavorite(_ tid: Int, _ favorite: Bool, _ list: String) {
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreHorses")
        fetchRequest.predicate = NSPredicate(format: "tid == %d", tid)
        fetchRequest.includesSubentities = false
        
        var results: [NSManagedObject] = []
        do {
            results = try context.fetch(fetchRequest) as! [NSManagedObject]
            for result in results {
                result.setValue(favorite, forKey: list)
            }
        } catch {
            print("Could not update: \(error)")
        }
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
    }
    
    func resetFavorites(bool: Bool, list: String) {
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreHorses")
        let predicate = NSPredicate(format: "\(list) == YES")
        fetchRequest.predicate = predicate
        fetchRequest.includesSubentities = false
        
        var results: [NSManagedObject] = []
        do {
            results = try context.fetch(fetchRequest) as! [NSManagedObject]
            for result in results {
                result.setValue(bool, forKey: list)
            }
        } catch {
            print("Could not update: \(error)")
        }
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
    }
    
    func updateAttributes(_ horse: Horses) {
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreHorses")
        fetchRequest.predicate = NSPredicate(format: "tid == %d", horse.tid)
        fetchRequest.includesSubentities = false
        
        var results: [NSManagedObject] = []
        do {
            results = try context.fetch(fetchRequest) as! [NSManagedObject]
            let result = results.first
            result?.setValue(horse.name, forKey: "name")
            result?.setValue(horse.birthday, forKey: "birthday")
            result?.setValue(horse.owner, forKey: "owner")
            result?.setValue(horse.discipline, forKey: "discipline")
            result?.setValue(horse.studbook, forKey: "studbook")
        } catch {
            print("error executing fetch request: \(error)")
        }
        
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
    }
    
    
    // MARK: - selector objects
    @objc func resyncTapped() {
        notLoggedInPopup.alpha = 0
        noFavoritesPopup.alpha = 0
        // Synchronize horses
        if selected[0] {
            favoriteHorses(favoriteHorsesButton)
        } else if selected[1] {
            personalHorses(personalHorsesButton)
        } else {
            allHorses(allHorsesButton)
        }
    }
    
    @objc func addTapped() {
        if selected[0] || selected[1] {
            // Add horse to favo or personal
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "AddFavorite") as! AddFavoriteHorseViewController
            let navController = UINavigationController(rootViewController: vc)
            self.present(navController, animated: true, completion: nil)
            //present(AddFavoriteHorseViewController(), animated: true, completion: nil)
        } else {
            // Add a horse to the list
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "AddNewHorse") as! AddNewHorseViewController
            let navController = UINavigationController(rootViewController: vc)
            self.present(navController, animated: true, completion: nil)
        }
     }
    
    
    // MARK: - prepare segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let horse: Horses
                if isFiltering() {
                    horse = filteredHorses[indexPath.row]
                } else {
                    horse = horses[indexPath.row]
                }
                let controller = (segue.destination as! UINavigationController).topViewController as! HorseDetailViewController
                controller.detailHorse = horse
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.navigationController?.title = horse.name.first?.value
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
}

// MARK: - Extensions
// MARK: tableView extension
extension HorsesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            searchFooter.setIsFilteringToShow(filteredItemCount: filteredHorses.count, of: horses.count)
            return filteredHorses.count
        }
        
        searchFooter.setNotFiltering()
        return horses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HorseTableCell", for: indexPath) as? HorseTableCell else {
            fatalError("Unexpected Index Path")
        }
        let horse: Horses
        if isFiltering() {
            horse = filteredHorses[indexPath.row]
        } else {
            horse = horses[indexPath.row]
        }
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
        
        // Optional value birthday
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreJaartallen")
        fetchRequest.predicate = NSPredicate(format: "tid == %d", (horse.birthday?.first?.id)!)
        var jaartal: String = ""
        do {
            let result = try self.appDelegate.getContext().fetch(fetchRequest)
            for r in result as! [Years] {
                jaartal = (r.year.first?.year)!
            }
            cell.birthDay.text = jaartal
        } catch {
            cell.birthDay.text = ""
        }
        
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
            print("list of horses before deleting: \(self.horses.map { $0.tid })")
            let tid: Array<Int32> = self.horses[indexPath.row].tid.map { $0.value }
            self.horses.remove(at: indexPath.row)
            tableView.reloadData()
            
            
            if selected[0] {
                print("list of horses: \(self.horses.map { $0.tid })")
                // Patch userdata with new list of favorites
                self.resetFavorites(bool: false, list: "favorite")
                self.patchFavoritesToUser(false, self.horses, "favorite")
                // Adjust in Core Data
                fetchAndStoreAsFavorite(tid: tid, addToList: false, list: "favorite")
            } else if selected[1] {
                print("list of horses: \(self.horses.map { $0.tid })")
                // Patch userdata with new list of favorites
                self.resetFavorites(bool: false, list: "personal")
                self.patchFavoritesToUser(false, self.horses, "personal")
                // Adjust in Core Data
                fetchAndStoreAsFavorite(tid: tid, addToList: false, list: "personal")
            }
            
        }
    }
}

// MARK: UISearchResultsUpdating delegate
extension HorsesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
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
}
