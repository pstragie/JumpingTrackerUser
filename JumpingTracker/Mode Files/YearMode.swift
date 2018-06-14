//
//  YearMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 31/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData

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
        var value: Int32
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


extension Year {
    var allAtributes: Years {
        get {
            let tid = Years.NumberID(value: self.tid)
            let uuid = Years.UUID(value: self.uuid!)
            let year = Years.Year(year: self.name!)
            
            return Years(tid: [tid], uuid: [uuid], year: [year])
        }
        set {
            self.tid = (newValue.tid.first?.value)!
            self.uuid = (newValue.uuid.first?.value)!
            self.name = (newValue.year.first?.year)!
        }
    }
}
