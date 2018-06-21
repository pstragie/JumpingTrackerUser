//
//  FlaggingMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 21/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData

struct Flaggings: Codable {
    var id: [FlaggingID]?
    var uuid: [UUID]?
    var flag_id: [FlagID]
    var entity_id: [EntityID]
    var entity_type: [EntityType]
    var uid: [UID]
    
    init(id: [Flaggings.FlaggingID]? = nil, uuid: [Flaggings.UUID]? = nil, flag_id: [Flaggings.FlagID], entity_id: [Flaggings.EntityID], entity_type: [Flaggings.EntityType], uid: [Flaggings.UID]) {
        self.id = id
        self.uuid = uuid
        self.flag_id = flag_id
        self.entity_id = entity_id
        self.entity_type = entity_type
        self.uid = uid
    }
    
    enum CodingKeys: String, CodingKey {
        case id, uuid, flag_id, entity_id, entity_type, uid
        
    }
    struct EntityType: Codable {
        var value: String
    }
    
    struct UID: Codable {
        var uid: Int
        var type: String
        var uuid: String
        var url: String
        
        enum CodingKeys: String, CodingKey {
            case uid = "target_id"
            case type = "target_type"
            case uuid = "target_uuid"
            case url
        }
    }
    struct FlaggingID: Codable {
        var value: Int
    }
    
    struct UUID: Codable {
        var value: String
    }
    
    struct FlagID: Codable {
        var id: String
        var type: String
        var uuid: String?
        
        init(id: String, type: String, uuid: String? = nil) {
            self.id = id
            self.type = type
            self.uuid = uuid
        }
        enum CodingKeys: String, CodingKey {
            case id = "target_id"
            case type = "target_type"
            case uuid = "target_uuid"
        }
    }
    
    struct EntityID: Codable, Equatable {
        var value: String
    }
}
