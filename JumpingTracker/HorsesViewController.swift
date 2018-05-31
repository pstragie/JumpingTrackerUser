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
    
    var horses = Array<Dictionary<String, Any>>()
    var horseName: String = ""
    var studbooks: Array<Int> = []
    var horseOwner: String = ""
    var birthDay: String = ""
    
    var studbookDict: Dictionary<Int, String> = [:]
    var studid: Int?
    var studAcro: String = ""
    //var eventsData: [Events]?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var syncLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupLayout()
        configureTableView()
        // request all events
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
        titleLabel.layer.cornerRadius = 5
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
    func requestStudbookTaxonomy() {
        if ConnectionCheck.isConnectedToNetwork() {
            let urlString = "https://jumpingtracker.com/rest/export/json/studbooks?_format=json"
            guard let url = URL(string: urlString) else { return }
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data else { return }
                do {
                    //Decode retrieved data with JSONDecoder
                    print("Decoding studbooks json, data = \(data)")
                    let studData = try JSONDecoder().decode([Studbook].self, from: data)
                    
                    for stud in studData {
                        for id in stud.tid {
                            self.studid = id.value
                        }
                        for acro in stud.studbook {
                            self.studAcro = acro.acro
                        }
                        
                        
                        self.studbookDict[self.studid!] = self.studAcro
                        
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
        return self.horses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("reloading...")
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HorseTableCell", for: indexPath) as? HorseTableCell else {
            fatalError("Unexpected Index Path")
        }
        cell.selectionStyle = .gray
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        cell.layer.borderWidth = 0
        
        cell.horseName.text = self.horses[indexPath.row]["name"] as? String
        // studbook ids stored in Array<Int> in horses Array<Dictionary<String, Any>>
        let idArray = self.horses[indexPath.row]["studbook"] as! Array<Int>
        // convert ids to acros
        var acroArray: Array<String> = []
        for id in idArray {
            let acro = studbookDict[id]
            acroArray.append(acro!)
        }
        // map array to string and join
        let acroA = acroArray.map{ String($0) }
        let acroString = acroA.joined(separator: ", ")
        cell.studbook.text = acroString
        cell.horseOwner.text = self.horses[indexPath.row]["owner"] as? String
        cell.birthDay.text = self.horses[indexPath.row]["birthday"] as? String
            
        return cell
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
        
        do {
            //Decode retrieved data with JSONDecoder
            let horseData = try JSONDecoder().decode([Horses].self, from: data)
            
            for horse in horseData {
                for horseN in horse.name {
                    self.horseName = horseN.value
                }
                for studbook in horse.studbook {
                    self.studbooks.append(studbook.id)
                }
                for horseO in horse.owner! {
                    self.horseOwner = horseO.owner
                }
                for birthD in horse.birthday! {
                    self.birthDay = String(birthD.birthday)
                }
                var tempDict: Dictionary<String, Any> = [:]
                tempDict["name"] = self.horseName
                tempDict["studbook"] = self.studbooks
                tempDict["owner"] = self.horseOwner
                tempDict["birthday"] = self.birthDay
                
                self.horses.append(tempDict)
                
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
