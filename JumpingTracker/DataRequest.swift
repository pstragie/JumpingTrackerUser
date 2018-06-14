//
//  DataRequest.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 04/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import UIKit
import CoreData

class RequestDataOperation: Operation {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    func requestTaxonomies() {
        print("request taxonomies...")
        Thread.printCurrent()
        let username = "swift_username_request_data"
        let password = "JTIsabelle29?"
        let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
        self.appDelegate.persistentContainer.performBackgroundTask { (context) in
            print("Requesting Disciplines JSON")
            self.requestDisciplines(header: headers, completion: { (result) in
                print("Casting disciplines...")
                Thread.printCurrent()
                for items in result as [Disciplines] {
                    let disciplines: Discipline = NSEntityDescription.insertNewObject(forEntityName: "CoreDisciplines", into: context) as! Discipline
                    disciplines.allAtributes = items
                }
                do {
                    try context.save()
                } catch {
                    print("Could not save disciplines")
                    
                }
            })
            self.requestCoatColors(header: headers, completion: { (result) in
                for items in result as [CoatColors] {
                    print("coatcolors items: \(items)")
                    let coatcolors: CoatColor = NSEntityDescription.insertNewObject(forEntityName: "CoreCoatColors", into: context) as! CoatColor
                    coatcolors.allAtributes = items
                }
                do {
                    try context.save()
                } catch {
                    print("Could not save coat colors")
                    
                }
            })
            self.requestGenders(header: headers, completion: { (result) in
                for items in result as [Genders] {
                    let genders: Gender = NSEntityDescription.insertNewObject(forEntityName: "CoreGenders", into: context) as! Gender
                    genders.allAtributes = items
                }
                do {
                    try context.save()
                } catch {
                    print("Could not save genders")
                    
                }
            })
            self.requestYears(header: headers, completion: { (result) in
                for items in result as [Years] {
                    let years: Year = NSEntityDescription.insertNewObject(forEntityName: "CoreYears", into: context) as! Year
                    years.allAtributes = items
                }
                do {
                    try context.save()
                } catch {
                    print("Could not save years")
                    
                }
            })
            self.requestStudbooks(header: headers, completion: { (result) in
                // Store to core data
                for items in result as [Studbooks] {
                    let studbook: Studbook = NSEntityDescription.insertNewObject(forEntityName: "CoreStudbooks", into: context) as! Studbook
                    studbook.allAtributes = items
                }
                do {
                    try context.save()
                } catch {
                    print("Could not save studbooks")
                    
                }
            })
        }
        
    }
    
    // MARK: - request functions
    func requestStudbooks(header: Dictionary<String, String>, completion: @escaping([Studbooks]) -> ()) {
        if ConnectionCheck.isConnectedToNetwork() {
            print("Getting Studbooks from server...")
            let urlString = "https://jumpingtracker.com/rest/export/json/studbooks?_format=json"
            Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
                .validate(statusCode: 200..<299)
                .validate(contentType: ["application/json"])
                .responseData(completionHandler: { (response) in
                    
                    switch(response.result) {
                    case .success:
                        if response.result.value != nil {
                            do {
                                let studbook: [Studbooks] = try JSONDecoder().decode([Studbooks].self, from: response.data!)
                                
                                completion(studbook)
                                print("studbook decoded")
                            } catch {
                                print("Could not decode studbook")
                            }
                        }
                        break
                    case .failure(let error):
                        print("Request to authenticate failed with error: \(error)")
                        print("error code: \(error)")
                        break
                    }
                    
                })
        } else {
            print("Not connected")
        }
    }
    
    
    func requestYears(header: Dictionary<String, String>, completion: @escaping ([Years]) -> ()) {
        let urlString = "https://jumpingtracker.com/rest/export/json/jaartallen?_format=json"
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData(completionHandler: { (response) in
                
                switch(response.result) {
                case .success:
                    if response.result.value != nil {
                        print("Response: \(response)")
                        
                        do {
                            let years: [Years] = try JSONDecoder().decode([Years].self, from: response.data!)
                            
                            completion(years)
                            print("years decoded")
                        } catch {
                            print("Could not decode years")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    break
                }
            })
    }
    
    func requestGenders(header: Dictionary<String, String>, completion: @escaping ([Genders]) -> ()) {
        let urlString = "https://jumpingtracker.com/rest/export/json/gender?_format=json"
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData(completionHandler: { (response) in
                
                switch(response.result) {
                case .success:
                    if response.result.value != nil {
                        print("Response: \(response)")
                        do {
                            let genders: [Genders] = try JSONDecoder().decode([Genders].self, from: response.data!)
                            
                            completion(genders)
                            print("genders decoded")
                        } catch {
                            print("Could not decode genders")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    break
                }
            })
    }
    
    func requestCoatColors(header: Dictionary<String, String>, completion: @escaping ([CoatColors]) -> ()) {
        let urlString = "https://jumpingtracker.com/rest/export/json/coatcolors?_format=json"
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData(completionHandler: { (response) in
                
                switch(response.result) {
                case .success:
                    if response.result.value != nil {
                        print("Response: \(response)")
                        do {
                            let coatcolors: [CoatColors] = try JSONDecoder().decode([CoatColors].self, from: response.data!)
                            
                            completion(coatcolors)
                            print("coatcolors decoded")
                        } catch {
                            print("Could not decode coatcolors")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    break
                }
            })
    }
    
    func requestDisciplines(header: Dictionary<String, String>, completion: @escaping ([Disciplines]) -> ()) {
        let urlString = "https://jumpingtracker.com/rest/export/json/disciplines?_format=json"
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData(completionHandler: { (response) in
                
                switch(response.result) {
                case .success:
                    if response.result.value != nil {
                        print("Response: \(response)")
                        do {
                            let disciplines: [Disciplines] = try JSONDecoder().decode([Disciplines].self, from: response.data!)
                            
                            completion(disciplines)
                            print("disciplines decoded")
                        } catch {
                            print("Could not decode disciplines")
                        }
                    }
                    break
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                    break
                }
            })
    }
}

