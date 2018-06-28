//
//  OrganisatorMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 20/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData

struct Organisators: Codable {
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
    }
    
    struct Name: Codable {
        var value: String
    }
}

extension Organisator {
    
    var allAtributes: Organisators {
        get {
            let tid = Organisators.NumberID(value: Int(self.tid))
            let uuid = Organisators.UUID(value: self.uuid!)
            let name = Organisators.Name(value: self.name!)
            
            return Organisators(tid: [tid], uuid: [uuid], name: [name])
        }
        set {
            self.tid = Int32((newValue.tid.first?.value)!)
            self.uuid = (newValue.uuid.first?.value)!
            self.name = (newValue.name.first?.value)!
        }
    }
}
