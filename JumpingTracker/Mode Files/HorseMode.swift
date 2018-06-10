//
//  HorseMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 31/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import UIKit

struct Horses: Codable {
    var tid: [ID]
    var uuid: [UUID]
    var name: [Name]
    var studbook: [Studbook]
    var owner: [Owner]?
    var birthday: [Birthday]?
    var discipline: [Discipline]?
    
    enum CodingKeys: String, CodingKey {
        case tid
        case uuid
        case name
        case studbook = "field_studbook"
        case owner = "field_current_owner"
        case birthday = "field_birth_year"
        case discipline = "field_discipline"
    }
    
    struct ID: Codable {
        var value: Int
    }
    
    struct UUID: Codable {
        var value: String
    }
    
    struct Name: Codable {
        var value: String
    }
    
    struct Studbook: Codable {
        var id: Int
        
        enum CodingKeys: String, CodingKey {
            case id = "target_id"
        }
    }
    
    struct Owner: Codable {
        var owner: String
        
        enum CodingKeys: String, CodingKey {
            case owner = "value"
        }
    }
    
    struct Birthday: Codable {
        var birthday: Int
        
        enum CodingKeys: String, CodingKey {
            case birthday = "target_id"
        }
        
    }
    
    struct Discipline: Codable {
        var id: Int
        
        enum CodingKeys: String, CodingKey {
            case id = "target_id"
        }
    }
}

