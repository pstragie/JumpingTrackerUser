//
//  RequestHorsesOperation.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 14/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import UIKit
import CoreData

class RequestHorsesOperation: Operation {
    func requestHorses() {
        requestHorseData("https://jumpingtracker.com/rest/export/json/horses?_format=json", completion: { (result) in
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
            
            
        })
    }
    
    // MARK: request horse data
    func requestHorseData(_ urlString: String, completion: @escaping ([Horses]) -> ()) {
        /// function to get taxonomies from CMS
        print("requesting horse data")
        if ConnectionCheck.isConnectedToNetwork() {
            activityIndicator.isHidden = false
            progressView.isHidden = false
            syncLabel.isHidden = false
            progressView.progress = 0.0
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
}
