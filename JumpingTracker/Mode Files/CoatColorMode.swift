//
//  CoatColorMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 11/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation

struct CoatColor: Decodable {
    var tid: [NumberID]
    var uuid: [UUID]
    var name: [Name]
    
    enum CodingKeys: String, CodingKey {
        case tid
        case uuid
        case name
    }
    
    struct NumberID: Codable {
        var value: Int
    }
    
    struct UUID: Codable {
        var value: String
        
        enum CodingKeys: String, CodingKey {
            case value
        }
    }
    
    struct Name: Codable {
        var value: String
        
        enum CodingKeys: String, CodingKey {
            case value
        }
    }
}
