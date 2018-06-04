//
//  EventMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 29/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import UIKit

struct Events: Decodable {
    var title: [Title]
    var address: [Address]
    var date: [Date]
    
    enum CodingKeys: String, CodingKey {
        case title
        case address = "field_event_address"
        case date = "field_event_date"
    }
    
    struct Title: Codable {
        var value: String
    }
    
    struct Address: Codable {
        var countryCode: String
        var locality: String
        
        enum CodingKeys: String, CodingKey {
            case countryCode = "country_code"
            case locality
        }
    }
    
    struct Date: Codable {
        var value: String
    }
}
