//
//  UserMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 03/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import UIKit

struct User: Codable {
    var firstName: [FirstName]
    var surName: [SurName]
    var favHorses: [FavHorses]
    var perHorses: [PerHorses]
    
    enum CodingKeys: String, CodingKey {
        case firstName = "field_firstname"
        case surName = "field_surname"
        case favHorses = "field_favorite_horses"
        case perHorses = "field_your_horses"
    }
    
   
    struct FirstName: Codable {
        var value: String
    }
    
    struct SurName: Codable {
        var value: String
    }
    
    struct FavHorses: Codable {
        var id: Int
        var type: String
        var uuid: String
        var url: String
        
        enum CodingKeys: String, CodingKey {
            case id = "target_id"
            case type = "target_type"
            case uuid = "target_uuid"
            case url
        }
    }
    
    struct PerHorses: Codable {
        var id: Int
        var type: String
        var uuid: String
        var url: String
        
        enum CodingKeys: String, CodingKey {
            case id = "target_id"
            case type = "target_type"
            case uuid = "target_uuid"
            case url
        }
    }
}
