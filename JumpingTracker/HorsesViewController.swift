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

class HorsesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var horseDetailViewController: HorseDetailViewController? = nil
    let userDefault = UserDefaults.standard
    let searchController = UISearchController(searchResultsController: nil)
    var filteredHorses = [Horse]()
    var horses = [Horse]()
    var favoriteHorses = Array<Horse>()
    var personalHorses = Array<Horse>()
    var jumpingHorses = Array<Horse>()
    
    var studbookDict: Dictionary<String, String> = [:]
    var yearDict: Dictionary<String, String> = [:]
    var disciplineDict: Dictionary<String, String> = [:]
    
    @IBOutlet var searchFooter: SearchFooter!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var syncLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableViewButtons: [UIButton]!
    @IBOutlet weak var favoriteHorsesButton: UIButton!
    @IBOutlet weak var personalHorsesButton: UIButton!
    @IBOutlet weak var jumpingHorsesButton: UIButton!
    @IBOutlet weak var allHorsesButton: UIButton!
    @IBOutlet weak var noResultsLabel: UILabel!
    
    @IBAction func allHorses(_ sender: UIButton) {
        
        requestHorseData("https://jumpingtracker.com/rest/export/json/horses?_format=json", completion: { result in
            self.horses = result
            self.tableView.reloadData()
        })
    }
    @IBAction func favoriteHorses(_ sender: UIButton) {
        
        // Add user id to https string to personalize the favorites!!! e.g. .../favorite_horses/1?_format=json
        if userDefault.value(forKey: "UID") != nil {
            requestHorseData("https://jumpingtracker.com/rest/export/json/favorite_horses/\(self.userDefault.value(forKey: "UID")!)?_format=json", completion: { result in
                self.horses = result
                self.tableView.reloadData()
                self.progressView.isHidden = true
                self.syncLabel.isHidden = true
                self.activityIndicator.isHidden = true
                self.progressView.progress = 0.0
            })
            
            self.tableView.reloadData()
        } else {
            print("Login to view your favorite horses or register to add favorite horses.")
            // Show label over tableView
        }
    }
    
    @IBAction func personalHorses(_ sender: UIButton) {
        if userDefault.value(forKey: "UID") != nil {
            requestHorseData("https://jumpingtracker.com/rest/export/json/personal_horses/\(self.userDefault.value(forKey: "UID")!)?_format=json", completion: { result in
                self.horses = result
                self.tableView.reloadData()
                self.progressView.isHidden = true
                self.syncLabel.isHidden = true
                self.activityIndicator.isHidden = true
                self.progressView.progress = 0.0
            })
            
            
        } else {
            print("Login to view your favorite horses or register to add favorite horses.")
            // Show label over tableView
        }
    }
    
    @IBAction func filterHorses(_ sender: UIButton) {
        self.tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if let splitViewController = splitViewController {
            let controllers = splitViewController.viewControllers
            horseDetailViewController = (controllers[controllers.count - 1] as! UINavigationController).topViewController as? HorseDetailViewController
        }
        // Setup the scope bar
        searchController.searchBar.scopeButtonTitles = ["All", "Name", "Owner", "Studbook"]
        searchController.searchBar.delegate = self
        // Setup the search footer
        tableView.tableFooterView = searchFooter
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search horses"
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController // Add the searchbar to the navigationItem
        } else {
            // ???
        }
        definesPresentationContext = true
        
        // Do any additional setup after loading the view, typically from a nib.
        yearDict = self.userDefault.object(forKey: "jaartallen") as! Dictionary<String, String>
        studbookDict = self.userDefault.object(forKey: "studbooks") as! Dictionary<String, String>
        disciplineDict = self.userDefault.object(forKey: "disciplines") as! Dictionary<String, String>
        checkTaxDicts()
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
        
        requestHorseData("https://jumpingtracker.com/rest/export/json/horses?_format=json", completion: { (result) in
            self.horses = result
            print("First data: \(result)")
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
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkTaxDicts() {
        print("Checking taxonomy dictionaries...")
        let taxos = ["jaartallen", "studbooks", "disciplines"]
        for tax in taxos {
            if ((self.userDefault.object(forKey: tax) as? Dictionary<String, String>)?.isEmpty)! {
                DataRequest().getTaxonomy("https://jumpingtracker.com/rest/export/json/\(tax)?_format=json", tax: tax, completion: { result -> () in
                    // Update UI or store result
                    self.userDefault.set(result, forKey: tax)
                })
            }
        }
    }
    
    func setupNavBar() {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            // Fallback on earlier versions
        }
    }
    
    func setupLayout() {
        navigationItem.titleView?.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        navigationItem.titleView?.tintColor = UIColor.FlatColor.Gray.IronGray
        
        noResultsLabel.isHidden = true
        noResultsLabel.sizeToFit()
        noResultsLabel.layer.masksToBounds = true
        noResultsLabel.layer.borderWidth = 1.5
        noResultsLabel.layer.borderColor = UIColor.FlatColor.Blue.Denim.cgColor
        noResultsLabel.layer.cornerRadius = 5

        progressView.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
        progressView.progress = 0.0
        progressView.progressViewStyle = .bar
        progressView.progressTintColor = UIColor.FlatColor.Gray.Iron
        progressView.isHidden = true
        
        syncLabel.isHidden = true
        activityIndicator.isHidden = true
        
        for button in tableViewButtons {
            button.layer.cornerRadius = 5
            button.layer.borderWidth = 1.5
            button.layer.borderColor = UIColor.FlatColor.Blue.BlueWhale.cgColor
            button.layer.masksToBounds = true
            button.backgroundColor = UIColor.FlatColor.Blue.Denim
            button.tintColor = UIColor.white
        }
    }
    
    func configureTableView() {
        self.tableView.autoresizingMask = [.flexibleHeight]
    }
    
    func updateProgress(progress: Float) {
        print("progress: \(progress)")
        progressView.progress = progress
    }
    
    func requestHorseData(_ urlString: String, completion: @escaping (Array<Horse>) -> ()) {
        /// function to get taxonomies from CMS
        print("requesting horse data")
        if ConnectionCheck.isConnectedToNetwork() {
            activityIndicator.isHidden = false
            progressView.isHidden = false
            syncLabel.isHidden = false
            progressView.progress = 0.0
            let username = userDefault.string(forKey: "Username")
            let password = getPasswordFromKeychain(username!)
            
            let credentialData = "\(username!):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            let headers: Dictionary<String, String> = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            
            var result: [Horse] = []
            Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
                .downloadProgress { (progress) in
                    self.progressView.progress = Float(progress.fractionCompleted)
                }
                .responseJSON { (response) in
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
                    case .success(let value):
                        let swiftyJSON = JSON(value)
                        for item in swiftyJSON {
                            var studids: Array<String> = []
                            var discids: Array<String> = []
                            let (_, dict) = item
                            let horseN: String = String(dict["name"][0]["value"].stringValue)
                            let horseO: String = String(dict["field_current_owner"][0]["value"].stringValue)
                            let birthD: String = String(dict["field_birth_year"][0]["target_id"].intValue)
                            for arrayStuds in dict["field_studbook"] {
                                let (_, dictstud) = arrayStuds
                                let studid: String = String(dictstud["target_id"].intValue)
                                studids.append(studid)
                            }
                            for arrayDisc in dict["field_discipline"] {
                                let (_, dictdisc) = arrayDisc
                                let discid: String = String(dictdisc["target_id"].intValue)
                                discids.append(discid)
                            }
                            let H = Horse(name: horseN, owner: horseO, birthDay: birthD, studbook: studids, discipline: discids)
                            result.append(H)
                        }
                        // Store Date() latest synchronization
                        self.userDefault.set(Date(), forKey: "LastHorsesSynchronization")
                    case .failure(let error):
                        print("Request to authenticate failed with error: \(error)")
                    }
                    completion(result)
            }
            
        } else {
            print("No internet connection")
            // Show alertmessage
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
    
    func showNoResults(_ message: String) {
        noResultsLabel.isHidden = false
        tableView.isHidden = true
        noResultsLabel.text = message
    }
    
    func fillJumpingHorsesArray() {
        var jumpingTid: String = ""
        for (tid, disc) in self.disciplineDict {
            if disc == "Show jumping" {
                jumpingTid = tid
            }
        }
        for horse in horses {
            let d = horse.discipline
            
            if d.contains(jumpingTid) {
                jumpingHorses.append(horse)
            }
        }
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!searchBarIsEmpty() || searchBarScopeIsFiltering)
    }
    
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredHorses = horses.filter({( horse : Horse) -> Bool in
            let doesCategoryMatch = (scope == "All") || (horse.name == scope)
            
            if searchBarIsEmpty() {
                return doesCategoryMatch
            } else {
                return doesCategoryMatch && horse.name.lowercased().contains(searchText.lowercased())
            }
        })
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let horse: Horse
                if isFiltering() {
                    horse = filteredHorses[indexPath.row]
                } else {
                    horse = horses[indexPath.row]
                }
                let controller = (segue.destination as! UINavigationController).topViewController as! HorseDetailViewController
                controller.detailHorse = horse
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.navigationController?.title = horse.name
            }
        }
        
    }

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
        let horse: Horse
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
        cell.horseName.text = horse.name
        let idArray = horse.studbook
        if idArray.count > 0 {
            let acroString = convertIDtoName(idArray: idArray, dict: (self.userDefault.object(forKey: "studbooks") as? Dictionary<String, String>)!)
            cell.studbook.text = acroString
        } else {
            cell.studbook.text = ""
        }
        cell.horseOwner.text = horse.owner
        
        // Optional value birthday
        let yD = self.userDefault.object(forKey: "jaartallen") as? Dictionary<String, String>
        if (yD?.count)! > 0 {
            let yearid = horse.birthDay
            if yearid != "0" {
                let jaartal: String = yearDict[yearid]!
                cell.birthDay.text = jaartal
            } else {
                cell.birthDay.text = ""
            }
        } else {
            checkTaxDicts()
            cell.birthDay.text = ""
        }
        return cell
    }
}

extension HorsesViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
    }
}

extension HorsesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}
