//
//  SecondViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 29/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit
import Foundation


class EventsViewController: UIViewController {

    public var response: HTTPURLResponse?
    var completionHandler:((HTTPURLResponse) -> Void)?
    var buffer: NSMutableData = NSMutableData()
    var expectedContentLength = 0
    
    let sectionHeaders: Array<String> = ["Upcoming events", "Passed events"]
    var passedEvents = Array<Dictionary<String, String>>()
    var upcomingEvents = Array<Dictionary<String, String>>()
    var eventTitle: String = ""
    var eventOrganisation: String = ""
    var eventLocality: String = ""
    var eventCountry: String = ""
    var eventDate: String = ""
    var eventHour: String = ""
    
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
        requestData("https://jumpingtracker.com/rest/export/json/events?_format=json")
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

extension EventsViewController: UITableViewDataSource, UITableViewDelegate {
    
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionHeaders.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.upcomingEvents.count
        default:
            return self.passedEvents.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("reloading...")
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EventsTableCell", for: indexPath) as? EventsTableCell else {
            fatalError("Unexpected Index Path")
        }
        cell.selectionStyle = .gray
        cell.layer.cornerRadius = 0
        cell.layer.masksToBounds = true
        cell.layer.borderWidth = 0
        switch indexPath.section {
        case 0:
            cell.event.text = self.upcomingEvents[indexPath.row]["title"]
            cell.organisation.text = self.upcomingEvents[indexPath.row]["organisation"]
            cell.date.text = self.upcomingEvents[indexPath.row]["date"]
            cell.hour.text = self.upcomingEvents[indexPath.row]["hour"]
            cell.locality.text = self.upcomingEvents[indexPath.row]["locality"]
            cell.country.text = self.upcomingEvents[indexPath.row]["country"]
            cell.BGView.backgroundColor = UIColor.FlatColor.Blue.PictonBlue
        default:
            cell.event.text = self.passedEvents[indexPath.row]["title"]
            cell.organisation.text = self.passedEvents[indexPath.row]["organisation"]
            cell.date.text = self.passedEvents[indexPath.row]["date"]
            cell.hour.text = self.passedEvents[indexPath.row]["hour"]
            cell.locality.text = self.passedEvents[indexPath.row]["locality"]
            cell.country.text = self.passedEvents[indexPath.row]["country"]
            cell.BGView.backgroundColor = UIColor.FlatColor.Blue.CuriousBlue
        }
        return cell
    }
    
}

extension EventsViewController: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    
    
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
            let eventsData = try JSONDecoder().decode([Events].self, from: data)
            
            
            for event in eventsData {
                var tempDict: Dictionary<String, String> = [:]
                for eventT in event.title {
                    tempDict["title"] = eventT.value
                }
                for eventL in event.address {
                    tempDict["locality"] = eventL.locality
                }
                for eventC in event.address {
                    tempDict["country"] = eventC.countryCode
                }
                for eventD in event.date {
                    self.eventDate = self.sanitizeDateFromJson(eventD.value)
                    tempDict["date"] = self.sanitizeDateFromJson(eventD.value)
                    tempDict["hour"] = self.sanitizeHourFromJson(eventD.value)
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy"
                let date = dateFormatter.date(from: self.eventDate)
                
                if date! > Date() {
                    print("upcoming")
                    self.upcomingEvents.append(tempDict)
                } else {
                    print("passed")
                    self.passedEvents.append(tempDict)
                }
                print("upcoming events: \(self.upcomingEvents)")
                print("passed events: \(self.passedEvents)")
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
