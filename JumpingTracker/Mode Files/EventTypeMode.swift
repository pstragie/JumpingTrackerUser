//
//  EventTypeMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 13/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData

struct EventTypes: Codable {
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

extension EventType {
    var allAtributes: EventTypes {
        get {
            let tid = EventTypes.NumberID(value: self.tid)
            let uuid = EventTypes.UUID(value: self.uuid!)
            let name = EventTypes.Name(value: self.name!)
            
            return EventTypes(tid: [tid], uuid: [uuid], name: [name])
        }
        set {
            self.tid = (newValue.tid.first?.value)!
            self.uuid = (newValue.uuid.first?.value)!
            self.name = (newValue.name.first?.value)!
        }
    }
}
