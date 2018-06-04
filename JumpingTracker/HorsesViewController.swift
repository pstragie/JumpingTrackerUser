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

class HorsesViewController: UIViewController {
    
    let userDefault = UserDefaults.standard
    public var response: HTTPURLResponse?
    var completionHandler:((HTTPURLResponse) -> Void)?
    var buffer: NSMutableData = NSMutableData()
    var expectedContentLength = 0
    
    var horsesArray = Array<Dictionary<String, Any>>()
    var favoriteHorsesArray = Array<Dictionary<String, Any>>()
    var personalHorsesArray = Array<Dictionary<String, Any>>()
    var jumpingHorsesArray = Array<Dictionary<String, Any>>()
    var horseName: String = ""
    var studbooks: Array<Int> = []
    var horseOwner: String = ""
    var birthDay: String = ""
    
    var studbookDict: Dictionary<String, String> = [:]
    var yearDict: Dictionary<String, String> = [:]
    var disciplineDict: Dictionary<String, String> = [:]
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
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
            self.horsesArray = result
            self.tableView.reloadData()
        })
        
        self.tableView.reloadData()
    }
    @IBAction func favoriteHorses(_ sender: UIButton) {
        
        // Add user id to https string to personalize the favorites!!! e.g. .../favorite_horses/1?_format=json
        if userDefault.value(forKey: "UID") != nil {
            requestHorseData("https://jumpingtracker.com/rest/export/json/favorite_horses/\(self.userDefault.value(forKey: "UID")!)?_format=json", completion: { result in
                self.horsesArray = result
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
        self.tableView.reloadData()
    }
    @IBAction func personalHorses(_ sender: UIButton) {
        if userDefault.value(forKey: "UID") != nil {
            requestHorseData("https://jumpingtracker.com/rest/export/json/personal_horses/\(self.userDefault.value(forKey: "UID")!)?_format=json", completion: { result in
                self.horsesArray = result
                self.tableView.reloadData()
            })
            
            self.tableView.reloadData()
            self.progressView.isHidden = true
            self.syncLabel.isHidden = true
            self.activityIndicator.isHidden = true
            self.progressView.progress = 0.0
        } else {
            print("Login to view your favorite horses or register to add favorite horses.")
            // Show label over tableView
        }
        self.tableView.reloadData()
    }
    @IBAction func filterHorses(_ sender: UIButton) {
        self.tableView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        yearDict = self.userDefault.object(forKey: "jaartallen") as! Dictionary<String, String>
        studbookDict = self.userDefault.object(forKey: "studbooks") as! Dictionary<String, String>
        disciplineDict = self.userDefault.object(forKey: "disciplines") as! Dictionary<String, String>
        setupLayout()
        configureTableView()
        // request all events
        //requestData("https://jumpingtracker.com/rest/export/json/horses?_format=json")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestHorseData("https://jumpingtracker.com/rest/export/json/horses?_format=json", completion: { (result) in
            self.horsesArray = result
            print("First data: \(result)")
            self.tableView.reloadData()
            self.progressView.isHidden = true
            self.syncLabel.isHidden = true
            self.activityIndicator.isHidden = true
            self.progressView.progress = 0.0
        })
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupLayout() {
        titleLabel.layer.cornerRadius = 0
        titleLabel.layer.masksToBounds = true
        titleLabel.layer.borderWidth = 2
        titleLabel.layer.borderColor = UIColor.FlatColor.Blue.Denim.cgColor
        titleLabel.backgroundColor = UIColor.FlatColor.Blue.Chambray.withAlphaComponent(0.3)
        
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
        self.tableView.dataSource = self
    }
    
    func updateProgress(progress: Float) {
        print("progress: \(progress)")
        progressView.progress = progress
    }
}

extension HorsesViewController: UITableViewDataSource, UITableViewDelegate {
    func requestHorseData(_ urlString: String, completion: @escaping (Array<Dictionary<String, Any>>) -> ()) {
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
            
            var result: Array<Dictionary<String, Any>> = []
            Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
                .downloadProgress { (progress) in
                    self.progressView.progress = Float(progress.fractionCompleted)
                }
                .responseJSON { (response) in
                    if response.result.value == nil {
                        print("No response")
                    }
                    switch(response.result) {
                    case .success(let value):
                        let swiftyJSON = JSON(value)
                        for item in swiftyJSON {
                            var tempDict: Dictionary<String, Any> = [:]
                            var studids: Array<String> = []
                            var discids: Array<String> = []
                            let (_, dict) = item
                            let horseN: String = String(dict["name"][0]["value"].stringValue)
                            tempDict["name"] = horseN
                            let horseO: String = String(dict["field_current_owner"][0]["value"].stringValue)
                            tempDict["owner"] = horseO
                            let birthD: String = String(dict["field_birth_year"][0]["target_id"].intValue)
                            tempDict["birthday"] = birthD
                            
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
                            tempDict["studbook"] = studids
                            tempDict["disciplines"] = discids
                            result.append(tempDict)
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
    func requestData(_ urlString: String) {
        if ConnectionCheck.isConnectedToNetwork() {
            activityIndicator.isHidden = false
            progressView.isHidden = false
            syncLabel.isHidden = false
            progressView.progress = 0.0
            //let urlString = "https://jumpingtracker.com/rest/export/json/horses?_format=json"
            guard let url = URL(string: urlString) else { return }
            
            let request = URLRequest.init(url: url)
            
            //let userName = "pstragier"
            //let password = "hateandwar"
            //let toEncode = "\(userName):\(password)"
            //let encoded = toEncode.data(using: .utf8)?.base64EncodedString()
            //request.addValue("Basic \(encoded!)", forHTTPHeaderField: "Authorization")
            //URLSession.shared.dataTask(with: request) {(data, response, error) in
            
            let configuration = URLSessionConfiguration.default
            //let sessionDelegate = self
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let sessionTask = session.dataTask(with: request)
            //sessionTask.cancel()
            sessionTask.resume()
            //let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
        } else {
            print("No internet Connection")
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
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.horsesArray.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("reloading...")
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HorseTableCell", for: indexPath) as? HorseTableCell else {
            fatalError("Unexpected Index Path")
        }
        cell.selectionStyle = .gray
        cell.layer.cornerRadius = 0
        cell.layer.masksToBounds = true
        cell.layer.borderWidth = 0
        
        self.tableView.isHidden = false
        cell.horseName.text = self.horsesArray[indexPath.row]["name"] as? String
        // studbook ids stored in Array<Int> in horses Array<Dictionary<String, Any>>
        let idArray = self.horsesArray[indexPath.row]["studbook"] as! Array<String>
        // convert ids to acros
        if idArray.count > 0 {
            let acroString = convertIDtoName(idArray: idArray, dict: studbookDict)
            cell.studbook.text = acroString
        } else {
            cell.studbook.text = ""
        }
        cell.horseOwner.text = self.horsesArray[indexPath.row]["owner"] as? String
        
        // Optional value birthday
        if let yearid = self.horsesArray[indexPath.row]["birthday"] {
            print("yearid: \(yearid)")
            if yearid as? String != "0" {
                let jaartal: String = yearDict[(yearid as? String)!]!
                cell.birthDay.text = jaartal
            } else {
                cell.birthDay.text = ""
            }
        } else {
            cell.birthDay.text = ""
        }
        
        return cell
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
}

extension HorsesViewController: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("did receive response")
        expectedContentLength = Int(response.expectedContentLength)
        guard let response = response as? HTTPURLResponse,
            (200...299).contains(response.statusCode),
            let mimeType = response.mimeType,
            mimeType == "application/json" else {
                completionHandler(.cancel)
                return
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("urlSession did receive data")
        progressView.progress = 0.0
        buffer.append(data)
        let percentageDownloaded = Float(buffer.length) / Float(expectedContentLength)
        updateProgress(progress: percentageDownloaded)
        //Implement JSON decoding and parsing
        if favoriteHorsesButton.isSelected {
            self.favoriteHorsesArray = []
        } else if personalHorsesButton.isSelected {
            self.personalHorsesArray = []
        } else if jumpingHorsesButton.isSelected {
            self.jumpingHorsesArray = []
        } else {
            self.horsesArray = []
        }
        do {
            //Decode retrieved data with JSONDecoder
            let horseData = try JSONDecoder().decode([Horses].self, from: data)
            
            for horse in horseData {
                var tempDict: Dictionary<String, Any> = [:]
                var studids: Array<Int> = []
                var disciplines: Array<Int> = []
                for horseN in horse.name {
                    tempDict["name"] = horseN.value
                }
                for studbook in horse.studbook {
                    studids.append(studbook.id)
                    
                    //self.studbooks.append(studbook.id)
                }
                for horseO in horse.owner! {
                    tempDict["owner"] = horseO.owner
                }
                for birthD in horse.birthday! {
                    tempDict["birthday"] = birthD.birthday
                }
                for discP in horse.discipline! {
                    disciplines.append(discP.id)
                }
                tempDict["studbook"] = studids
                tempDict["discipline"] = disciplines
                
                if favoriteHorsesButton.isSelected {
                    self.favoriteHorsesArray.append(tempDict)
                } else if personalHorsesButton.isSelected {
                    self.personalHorsesArray.append(tempDict)
                } else if jumpingHorsesButton.isSelected {
                    self.jumpingHorsesArray.append(tempDict)
                } else {
                    self.horsesArray.append(tempDict)
                }
                
            }
            
            //Get back to the main queue
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = true
                self.syncLabel.isHidden = true
                self.progressView.isHidden = true
                self.tableView.reloadData()
            }
        } catch let jsonError {
            print(jsonError)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("URLSession error: \(String(describing: error))")
        progressView.progress = 1.0
        if let errorInfo = error {
            print("Session error: \(errorInfo.localizedDescription)")
            
        } else {
            print("Request - complete!")
            self.activityIndicator.isHidden = true
        }
        if let compHandler = completionHandler {
            compHandler(self.response!)
        }
    }
    
    private func urlSession(_ session: URLSession, task: URLSessionTask, didReceive: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("URLAuthenticationChallenge")
    }
    
    internal func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("urlSession did finish events")
        // Calls background session completion in AppDelegate
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let completionHandler = appDelegate.backgroundSessionCompletionHandler {
            appDelegate.backgroundSessionCompletionHandler = nil
            DispatchQueue.main.async {
                completionHandler()
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpextedToWrite: Int64) {
        print("totalBytesExpectedToWrite: \(totalBytesExpextedToWrite)")
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpextedToWrite)
        DispatchQueue.main.async {
            print("updating progress: \(progress)")
            self.updateProgress(progress: progress)
        }
    }
    
    func fillJumpingHorsesArray() {
        var jumpingTid: String = ""
        for (tid, disc) in self.disciplineDict {
            if disc == "Show jumping" {
                jumpingTid = tid
            }
        }
        for horse in horsesArray {
            for (key, value) in horse {
                if key == "discipline" {
                    if ((value as? Array<String>)?.contains(jumpingTid))! {
                        jumpingHorsesArray.append(horse)
                    }
                }

            }
        }
    }
}
