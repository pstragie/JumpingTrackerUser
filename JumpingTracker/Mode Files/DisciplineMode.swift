//
//  DisciplineMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 03/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData

struct Disciplines: Codable {
    var tid: [NumberID]
    var uuid: [UUID]
    var name: [Name]
    
    enum CodingKeys: String, CodingKey {
        case tid
        case uuid
        case name
    }
    
    struct NumberID: Codable {
        var value: Int32
    }
    
    struct UUID: Codable {
        var value: String
    }
    
    struct Name: Codable {
        var value: String
    }
}

extension Discipline {
    
    var allAtributes: Disciplines {
        get {
            let tid = Disciplines.NumberID(value: self.tid)
            let uuid = Disciplines.UUID(value: self.uuid!)
            let name = Disciplines.Name(value: self.name!)
            
            return Disciplines(tid: [tid], uuid: [uuid], name: [name])
        }
        set {
            self.tid = (newValue.tid.first?.value)!
            self.uuid = (newValue.uuid.first?.value)!
            self.name = (newValue.name.first?.value)!
        }
    }
}
