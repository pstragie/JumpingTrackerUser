//
//  HorsesViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 31/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit
import Foundation


class HorsesViewController: UIViewController {
    
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
    
    var studbookDict: Dictionary<Int, String> = [:]
    var yearDict: Dictionary<Int, String> = [:]
    
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
    
    @IBAction func allHorses(_ sender: UIButton) {
        self.tableView.reloadData()
        requestData("https://jumpingtracker.com/rest/export/json/horses?_format=json")
    }
    @IBAction func favoriteHorses(_ sender: UIButton) {
        self.tableView.reloadData()
        // Add user id to https string to personalize the favorites!!! e.g. .../favorite_horses/1?_format=json
        requestData("https://jumpingtracker.com/rest/export/json/favorite_horses?_format=json")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupLayout()
        configureTableView()
        // request all events
        requestYearTaxonomy()
        requestStudbookTaxonomy()
        requestData("https://jumpingtracker.com/rest/export/json/horses?_format=json")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
            button.layer.borderColor = UIColor.FlatColor.Blue.PictonBlue.cgColor
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
    
    func  requestYearTaxonomy() {
        if ConnectionCheck.isConnectedToNetwork() {
            let urlString = "https://jumpingtracker.com/rest/export/json/jaartallen?_format=json"
            guard let url = URL(string: urlString) else { return }
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 200 {
                        print("response was not 200!")
                        return
                    }
                }
                
                if (error != nil) {
                    print("error request:\n \(String(describing: error?.localizedDescription))")
                    return
                }
                guard let data = data else { return }
                do {
                    //Decode retrieved data with JSONDecoder
                    print("Decoding years json, data = \(data)")
                    let yearData = try JSONDecoder().decode([Years].self, from: data)
                    
                    
                    for year in yearData {
                        var yearid: Int?
                        var jaartal: String = ""
                        
                        for id in year.tid {
                            yearid = id.value
                        }
                        for jaar in year.year {
                            jaartal = jaar.year
                        }
                        self.yearDict[yearid!] = jaartal
                    }
                    
                    //Get back to the main queue
                    DispatchQueue.main.async {
                        self.yearDict = self.yearDict
                    }
                } catch let jsonError {
                    print(jsonError)
                }
                }.resume()
        } else {
            print("No internet connection")
        }
    }
    func requestStudbookTaxonomy() {
        if ConnectionCheck.isConnectedToNetwork() {
            let urlString = "https://jumpingtracker.com/rest/export/json/studbooks?_format=json"
            guard let url = URL(string: urlString) else { return }
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 200 {
                        print("response was not 200!")
                        return
                    }
                }
                if (error != nil) {
                    print("error request:\n \(String(describing: error?.localizedDescription))")
                    return
                }
                guard let data = data else { return }
                do {
                    //Decode retrieved data with JSONDecoder
                    print("Decoding studbooks json, data = \(data)")
                    let studData = try JSONDecoder().decode([Studbook].self, from: data)
                    
                    for stud in studData {
                        var studid: Int?
                        var studAcro: String = ""
                        
                        for id in stud.tid {
                            studid = id.value
                        }
                        for acro in stud.studbook {
                            studAcro = acro.acro
                        }
                        self.studbookDict[studid!] = studAcro
                    }
                    
                    //Get back to the main queue
                    DispatchQueue.main.async {
                        self.studbookDict = self.studbookDict
                    }
                } catch let jsonError {
                    print(jsonError)
                }
            }.resume()
        } else {
            print("No internet connection")
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
        if favoriteHorsesButton.isSelected {
            return self.favoriteHorsesArray.count
        } else if personalHorsesButton.isSelected {
            return self.personalHorsesArray.count
        } else if jumpingHorsesButton.isSelected {
            return self.personalHorsesArray.count
        } else {
            return self.horsesArray.count
        }
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
        
        if favoriteHorsesButton.isSelected {
            print("horses = \(self.favoriteHorsesArray)")
            cell.horseName.text = self.favoriteHorsesArray[indexPath.row]["name"] as? String
            // studbook ids stored in Array<Int> in horses Array<Dictionary<String, Any>>
            let idArray = self.favoriteHorsesArray[indexPath.row]["studbook"] as! Array<Int>
            // convert ids to acros
            let acroString = convertIDtoName(idArray: idArray, dict: studbookDict)
            cell.studbook.text = acroString
            cell.horseOwner.text = self.favoriteHorsesArray[indexPath.row]["owner"] as? String
            
            // Optional value birthday
            if let yearid = self.favoriteHorsesArray[indexPath.row]["birthday"] {
                let jaartal: String = yearDict[yearid as! Int]!
                cell.birthDay.text = jaartal
            } else {
                cell.birthDay.text = ""
            }
        } else if personalHorsesButton.isSelected {
            print("horses = \(self.personalHorsesArray)")
            cell.horseName.text = self.personalHorsesArray[indexPath.row]["name"] as? String
            // studbook ids stored in Array<Int> in horses Array<Dictionary<String, Any>>
            let idArray = self.personalHorsesArray[indexPath.row]["studbook"] as! Array<Int>
            // convert ids to acros
            let acroString = convertIDtoName(idArray: idArray, dict: studbookDict)
            cell.studbook.text = acroString
            cell.horseOwner.text = self.personalHorsesArray[indexPath.row]["owner"] as? String
            
            // Optional value birthday
            if let yearid = self.personalHorsesArray[indexPath.row]["birthday"] {
                let jaartal: String = yearDict[yearid as! Int]!
                cell.birthDay.text = jaartal
            } else {
                cell.birthDay.text = ""
            }
        } else if jumpingHorsesButton.isSelected {
            print("horses = \(self.jumpingHorsesArray)")
            cell.horseName.text = self.jumpingHorsesArray[indexPath.row]["name"] as? String
            // studbook ids stored in Array<Int> in horses Array<Dictionary<String, Any>>
            let idArray = self.jumpingHorsesArray[indexPath.row]["studbook"] as! Array<Int>
            // convert ids to acros
            let acroString = convertIDtoName(idArray: idArray, dict: studbookDict)
            cell.studbook.text = acroString
            cell.horseOwner.text = self.jumpingHorsesArray[indexPath.row]["owner"] as? String
            
            // Optional value birthday
            if let yearid = self.jumpingHorsesArray[indexPath.row]["birthday"] {
                let jaartal: String = yearDict[yearid as! Int]!
                cell.birthDay.text = jaartal
            } else {
                cell.birthDay.text = ""
            }
        } else {
            print("horses = \(self.horsesArray)")
            cell.horseName.text = self.horsesArray[indexPath.row]["name"] as? String
            // studbook ids stored in Array<Int> in horses Array<Dictionary<String, Any>>
            let idArray = self.horsesArray[indexPath.row]["studbook"] as! Array<Int>
            // convert ids to acros
            let acroString = convertIDtoName(idArray: idArray, dict: studbookDict)
            cell.studbook.text = acroString
            cell.horseOwner.text = self.horsesArray[indexPath.row]["owner"] as? String
            
            // Optional value birthday
            if let yearid = self.horsesArray[indexPath.row]["birthday"] {
                let jaartal: String = yearDict[yearid as! Int]!
                cell.birthDay.text = jaartal
            } else {
                cell.birthDay.text = ""
            }
        }
        return cell
    }
    
    func convertIDtoName(idArray: Array<Int>, dict: Dictionary<Int, String>) -> String {
        var newArray: Array<String> = []
        var newString: String = ""
        for id in idArray {
            if let acro = dict[id] {
                newArray.append(acro)
            }
        }
        // map array to string and join
        let flatArray = newArray.map{ String($0) }
        newString = flatArray.joined(separator: ", ")
        return newString
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
                tempDict["studbook"] = studids
                
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
}
