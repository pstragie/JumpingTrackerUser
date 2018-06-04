//
//  DisciplineMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 03/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import UIKit

struct Disciplines: Decodable {
    var tid: [NumberID]
    var discipline: [Discipline]
    
    enum CodingKeys: String, CodingKey {
        case tid
        case discipline = "name"
    }
    
    struct NumberID: Codable {
        var value: Int
    }
    
    struct Discipline: Codable {
        var name: String
        
        enum CodingKeys: String, CodingKey {
            case name = "value"
        }
    }
}
