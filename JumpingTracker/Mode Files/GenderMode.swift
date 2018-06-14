//
//  GenderMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 13/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData

struct Genders: Decodable {
    var tid: [NumberID]
    var uuid: [UUID]
    var name: [Name]
    
    enum CodingKeys: String, CodingKey {
        case tid, uuid, name
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

extension Gender {
    var allAtributes: Genders {
        get {
            let tid = Genders.NumberID(value: self.tid)
            let uuid = Genders.UUID(value: self.uuid!)
            let name = Genders.Name(value: self.name!)
            
            return Genders(tid: [tid], uuid: [uuid], name: [name])
        }
        set {
            self.tid = (newValue.tid.first?.value)!
            self.uuid = (newValue.uuid.first?.value)!
            self.name = (newValue.name.first?.value)!
        }
    }
}
