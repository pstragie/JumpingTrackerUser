//
//  LogoMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 23/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData

struct Logos: Codable {
    var logo: [Logo]?
    
    enum codingKeys: String, CodingKey {
        case logo = "field_organisation_logo"
    }
    
    init(logo: [Logos.Logo]? = nil) {
        self.logo = logo
    }
    
    
    struct Logo: Codable {
        var url: String
    }
    
}

