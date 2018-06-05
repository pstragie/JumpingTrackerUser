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

class DataRequest: URLSession {
    /// Class to make data request
    let userDefault = UserDefaults.standard
    
    func getTaxonomy(_ urlString: String, tax: String, completion: @escaping (Dictionary<String, String>) -> ()) {
        /// function to get taxonomies from CMS
        print("requesting taxonomy")
        if ConnectionCheck.isConnectedToNetwork() {
            let username = "swift_username_request_data"
            let password = "JTIsabelle29?"
            let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            let headers: Dictionary<String, String> = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            
            var result: Dictionary<String, String> = [:]
            Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
                
                .responseJSON { (response) in
                if response.result.value == nil {
                    print("No response")
                }
                switch(response.result) {
                case .success(let value):
                    let swiftyJSON = JSON(value)
                    
                    for item in swiftyJSON {
                        let (_, dict) = item
                        let tid: String = String(dict["tid"][0]["value"].intValue)
                        var value: String = ""
                        if tax == "studbooks" {
                            value = dict["field_acronyme"][0]["value"].stringValue
                        } else {
                            value = dict["name"][0]["value"].stringValue
                        }
                        result[tid] = value
                    }
                case .failure(let error):
                    print("Request to authenticate failed with error: \(error)")
                }
                completion(result)
            }
            
        } else {
            print("No internet connection")
        }
        
    }
}

