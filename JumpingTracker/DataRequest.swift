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
    
    func getCoatColors(completion: @escaping ([CoatColor]) -> ()) {
        if ConnectionCheck.isConnectedToNetwork() {
            print("Getting coat colors from server...")
            let username = "swift_username_request_data"
            let password = "JTIsabelle29?"
            let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            let headers: Dictionary<String, String> = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            let urlString = "https://jumpingtracker.com/rest/export/json/coatcolors?_format=json"
            Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
                .validate(statusCode: 200..<299)
                .validate(contentType: ["application/json"])
                .responseData { (response) in
                    
                    switch(response.result) {
                    case .success:
                        print("data: \(response.data!)")
                        if response.result.value != nil {
                            print("Response: \(response)")
                            
                            do {
                                let coatColor: [CoatColor] = try JSONDecoder().decode([CoatColor].self, from: response.data!)
                                
                                completion(coatColor)
                            } catch {
                                print("Could not decode")
                            }
                        }
                        break
                    case .failure(let error):
                        print("Request to authenticate failed with error: \(error)")
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
            
        } else {
            print("No internet connection")
        }
        
    }
    
    func getStudbooks(completion: @escaping ([Studbook]) -> ()) {
        if ConnectionCheck.isConnectedToNetwork() {
            print("Getting Studbooks from server...")
            let username = "swift_username_request_data"
            let password = "JTIsabelle29?"
            let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            let headers: Dictionary<String, String> = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            let urlString = "https://jumpingtracker.com/rest/export/json/studbooks?_format=json"
            Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: headers)
                .validate(statusCode: 200..<299)
                .validate(contentType: ["application/json"])
                .responseData { (response) in
                    
                    switch(response.result) {
                    case .success:
                        print("data: \(response.data!)")
                        if response.result.value != nil {
                            print("Response: \(response)")
                            
                            do {
                                let studbook: [Studbook] = try JSONDecoder().decode([Studbook].self, from: response.data!)
                                
                                completion(studbook)
                            } catch {
                                print("Could not decode")
                            }
                        }
                        break
                    case .failure(let error):
                        print("Request to authenticate failed with error: \(error)")
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
            
        } else {
            print("No internet connection")
        }
        
    }
}

