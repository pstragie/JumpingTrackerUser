//
//  CoatColorMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 11/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData

struct CoatColors: Codable {
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

extension CoatColor {
    var allAtributes: CoatColors {
        get {
            let tid = CoatColors.NumberID(value: self.tid)
            let uuid = CoatColors.UUID(value: self.uuid!)
            let name = CoatColors.Name(value: self.name!)
            
            return CoatColors(tid: [tid], uuid: [uuid], name: [name])
        }
        set {
            self.tid = (newValue.tid.first?.value)!
            self.uuid = (newValue.uuid.first?.value)!
            self.name = (newValue.name.first?.value)!
        }
    }
}
