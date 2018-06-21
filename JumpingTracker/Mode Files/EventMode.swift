//
//  EventMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 29/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData
import UIKit

struct Events: Codable {
    var tid: [Tid]
    var uuid: [UUID]
    var title: [Title]
    var address: [Address]
    var date: [Date]
    var eventtype: [EventType]
    var level: [Level]?
    var organisator: [Organisator] // Chosen organisator name of the event
    var registerwithJT: [RegisterwithJT]
    var idnumber: [IDNumber]?
    var orguid: [OrgUID] // Creator of the event
    
    enum CodingKeys: String, CodingKey {
        case title, uuid
        case tid = "nid"
        case address = "field_event_address"
        case date = "field_event_date"
        case eventtype = "field_event_type"
        case level = "field_level"
        case organisator = "field_organisator"
        case registerwithJT = "field_allow_registration_via_jum"
        case idnumber = "field_private_event_key"
        case orguid = "uid"
    }
    
    init(tid: [Events.Tid], uuid: [Events.UUID], title: [Events.Title], address: [Events.Address], date: [Events.Date], eventtype: [Events.EventType], level: [Events.Level]? = nil, organisator: [Events.Organisator], registerwithJT: [Events.RegisterwithJT], idnumber: [Events.IDNumber]? = nil, orguid: [Events.OrgUID]) {
        self.tid = tid
        self.uuid = uuid
        self.title = title
        self.address = address
        self.date = date
        self.eventtype = eventtype
        self.level = level
        self.organisator = organisator
        self.registerwithJT = registerwithJT
        self.idnumber = idnumber
        self.orguid = orguid
    }
    
    struct IDNumber: Codable, Equatable {
        var value: String
    }
    struct Tid: Codable, Equatable {
        var value: Int32
    }
    struct UUID: Codable, Equatable {
        var value: String
    }
    struct OrgUID: Codable, Equatable {
        var id: Int
        var type: String
        var uuid: String
        var url: String
        
        enum CodingKeys: String, CodingKey {
            case id = "target_id"
            case type = "target_type"
            case uuid = "target_uuid"
            case url
        }
    }
    
    struct Title: Codable {
        var value: String
    }
    
    struct Address: Codable {
        var countryCode: String
        var locality: String
        
        enum CodingKeys: String, CodingKey {
            case countryCode = "country_code"
            case locality
        }
    }
    
    struct Date: Codable {
        var value: String
    }
    
    struct RegisterwithJT: Codable {
        var value: Bool
    }
    struct EventType: Codable, Equatable {
        var id: Int
        var type: String
        var uuid: String
        var url: String
        
        enum CodingKeys: String, CodingKey {
            case id = "target_id"
            case type = "target_type"
            case uuid = "target_uuid"
            case url
        }
    }
    
    struct Level: Codable, Equatable {
        var id: Int
        var type: String
        var uuid: String
        var url: String
        
        enum CodingKeys: String, CodingKey {
            case id = "target_id"
            case type = "target_type"
            case uuid = "target_uuid"
            case url
        }
    }
    
    struct Organisator: Codable, Equatable {
        var id: Int
        var type: String
        var uuid: String
        var url: String
        
        enum CodingKeys: String, CodingKey {
            case id = "target_id"
            case type = "target_type"
            case uuid = "target_uuid"
            case url
        }
    }
}

extension Event {
    
    var allAtributes: Events {
        get {
            let tid = Events.Tid(value: self.tid)
            let uuid = Events.UUID(value: self.uuid!)
            let title = Events.Title(value: self.title!)
            let address = Events.Address(countryCode: self.countrycode!, locality: self.locality!)
            let date = Events.Date(value: self.date!)
            let eventtype = Events.EventType(id: Int(self.eventtype), type: "taxonomy_term", uuid: "\(convertTid("CoreEventTypes", Int(self.eventtype), "uuid"))", url: "/taxonomy/term/\(self.eventtype)")
            let level = Events.Level(id: Int(self.eventtype), type: "taxonomy_term", uuid: "\(convertTid("CoreEventTypes", Int(self.level), "uuid"))", url: "/taxonomy/term/\(self.level)")
            let organisator = Events.Organisator(id: Int(self.organisator), type: "taxonomy_term", uuid: "\(convertTid("CoreOrganisators", Int(self.organisator), "uuid"))", url: "/taxonomy/term/\(self.organisator)")
            let registerwithJT = Events.RegisterwithJT(value: self.registerwithJT)
            var idnumber: Events.IDNumber = Events.IDNumber(value: "jt2018_pws")
            if self.idnumber != nil {
                idnumber = Events.IDNumber(value: self.idnumber!)
            } 
            let orguid = Events.OrgUID(id: Int(self.orguid), type: "user", uuid: "\(convertTid("CoreOrganisators", Int(self.orguid), "uuid"))", url: "/user/\(self.orguid)")
            return Events(tid: [tid], uuid: [uuid], title: [title], address: [address], date: [date], eventtype: [eventtype], level: [level], organisator: [organisator], registerwithJT: [registerwithJT], idnumber: [idnumber], orguid: [orguid])
        }
        set {
            self.tid = (newValue.tid.first?.value)!
            self.uuid = (newValue.uuid.first?.value)
            self.title = (newValue.title.first?.value)!
            self.countrycode = (newValue.address.first?.countryCode)!
            self.locality = (newValue.address.first?.locality)!
            self.date = (newValue.date.first?.value)!
            self.eventtype = Int32((newValue.eventtype.first?.id)!)
            if newValue.level?.first != nil {
                self.level = Int32((newValue.level?.first?.id)!)
            }
            self.organisator = Int32((newValue.organisator.first?.id)!)
            self.registerwithJT = (newValue.registerwithJT.first?.value)!
            if newValue.idnumber?.first != nil {
                self.idnumber = (newValue.idnumber?.first?.value)
            }
            self.orguid = Int32((newValue.orguid.first?.id)!)
        }
    }
    
    func convertTid(_ entity: String, _ tid: Int, _ key: String) -> String {
        //var result: NSManagedObject?
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.predicate = NSPredicate(format: "tid == %d", tid)
        do {
            let results = try context?.fetch(fetchRequest) as? [NSManagedObject]
            for result in results! {
                return result.value(forKey: key) as! String
            }
        } catch {
            print("Could not fetch")
        }
        return "Unknown"
    }
}
