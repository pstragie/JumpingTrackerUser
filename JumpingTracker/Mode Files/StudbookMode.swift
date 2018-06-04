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
    var studbook: [Studbook]
    
    enum CodingKeys: String, CodingKey {
        case tid
        case studbook = "field_acronyme"
    }
    
    struct NumberID: Codable {
        var value: Int
    }
    
    struct Studbook: Codable {
        var acro: String
        
        enum CodingKeys: String, CodingKey {
            case acro = "value"
        }
    }
}
