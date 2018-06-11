//
//  StudbookMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 31/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import UIKit

struct Studbook: Decodable {
    var tid: [NumberID]
    var uuid: [UUID]
    var acro: [Acro]
    
    enum CodingKeys: String, CodingKey {
        case tid
        case uuid
        case acro = "field_acronyme"
    }
    
    struct NumberID: Codable {
        var value: Int
    }
    
    struct UUID: Codable {
        var value: String
    }

    struct Acro: Codable {
        var value: String
        
        enum CodingKeys: String, CodingKey {
            case value
        }
    }
}
