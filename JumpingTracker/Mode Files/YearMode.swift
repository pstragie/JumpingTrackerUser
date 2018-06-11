//
//  YearMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 31/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import UIKit

struct Years: Decodable {
    var tid: [NumberID]
    var uuid: [UUID]
    var year: [Year]
    
    enum CodingKeys: String, CodingKey {
        case tid
        case uuid
        case year = "name"
    }
    
    struct NumberID: Codable {
        var value: Int
    }
    
    struct UUID: Codable {
        var value: String
    }
    
    struct Year: Codable {
        var year: String
        
        enum CodingKeys: String, CodingKey {
            case year = "value"
        }
    }
}

