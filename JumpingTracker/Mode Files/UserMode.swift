//
//  UserMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 03/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import UIKit

struct User: Decodable {
    var firstName: [FirstName]
    var surName: [SurName]
    
    enum CodingKeys: String, CodingKey {
        case firstName = "field_firstname"
        case surName = "field_surname"
    }
    
    struct FirstName: Codable {
        var value: String
    }
    
    struct SurName: Codable {
        var value: String

    }
}
