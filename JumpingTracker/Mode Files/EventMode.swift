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

struct Events: Codable, Equatable {
    var tid: [Tid]
    var uuid: [UUID]
    var title: [Title]
    var date: [Date]
    var eventtype: [EventType]
    var level: [Level]?
    var organisator: [Organisator]? // Chosen organisator name of the event
    var registerwithJT: [RegisterwithJT]
    var idnumber: [IDNumber]?
    var orguid: [OrgUID] // Creator of the event
    var body: [Body]?
    var poster: [Poster]?
    var address: [Address]?
    var logo: [Logo]?
    
    enum CodingKeys: String, CodingKey {
        case title, uuid, body
        case tid = "nid"
        case date = "field_event_date"
        case eventtype = "field_event_type"
        case level = "field_level"
        case organisator = "field_organisator_event"
        case address = "field_event_address"
        case registerwithJT = "field_allow_registration_via_jum"
        case idnumber = "field_private_event_key"
        case orguid = "uid"
        case poster = "field_event_image_poster_"
        case logo = "field_organisation_logo_user_ref"
    }
    
    init(tid: [Events.Tid], uuid: [Events.UUID], title: [Events.Title], date: [Events.Date], eventtype: [Events.EventType], level: [Events.Level]? = nil, organisator: [Events.Organisator]? = nil, registerwithJT: [Events.RegisterwithJT], idnumber: [Events.IDNumber]? = nil, orguid: [Events.OrgUID], body: [Events.Body]? = nil, poster: [Events.Poster]? = nil, address: [Events.Address]? = nil, logo: [Events.Logo]? = nil) {
        self.tid = tid
        self.uuid = uuid
        self.title = title
        self.date = date
        self.eventtype = eventtype
        self.level = level
        self.organisator = organisator
        self.registerwithJT = registerwithJT
        self.idnumber = idnumber
        self.orguid = orguid
        self.body = body
        self.poster = poster
        self.address = address
        self.logo = logo
    }
    
    struct Logo: Codable, Equatable {
        var target_id: Int
    }
    struct IDNumber: Codable, Equatable {
        var value: String
    }
    struct Tid: Codable, Equatable {
        var value: Int
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
    
    struct Address: Codable, Equatable {
        var country_code: String?
        var administrative_area: String?
        var locality: String?
        var dependent_locality: String?
        var postal_code: String?
        var sorting_code: String?
        var address_line1: String
        var address_line2: String?
        var organization: String?
        
        enum CodingKeys: String, CodingKey {
            case country_code, administrative_area, locality, dependent_locality, postal_code, sorting_code, address_line1, address_line2, organization
        }
        
    }
    
    struct Title: Codable, Equatable {
        var value: String
    }
    
    struct Body: Codable, Equatable {
        var value: String?
        var format: String?
        var processed: String?
        var summary: String?
    }
    
    struct Poster: Codable, Equatable {
        var url: String?
    }
    
    struct Date: Codable, Equatable {
        var value: String
    }
    
    struct RegisterwithJT: Codable, Equatable {
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
        var id: Int?
        var type: String?
        var uuid: String?
        var url: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "target_id"
            case type = "target_type"
            case uuid = "target_uuid"
            case url
        }
    }
    
    struct Organisator: Codable, Equatable {
        var value: String
        enum CodingKeys: String, CodingKey {
            case value
        }
    }
}

extension Event {
    
    var allAtributes: Events {
        get {
            let tid = Events.Tid(value: Int(self.tid))
            let uuid = Events.UUID(value: self.uuid!)
            let title = Events.Title(value: self.title!)
            let date = Events.Date(value: self.date!)
            let eventtype = Events.EventType(id: Int(self.eventtype), type: "taxonomy_term", uuid: "\(convertTid("CoreEventTypes", Int(self.eventtype), "uuid"))", url: "/taxonomy/term/\(self.eventtype)")
            var level: Events.Level?
            if self.level > 0 {
                level = Events.Level(id: Int(self.level), type: "taxonomy_term", uuid: "\(convertTid("CoreEventTypes", Int(self.level), "uuid"))", url: "/taxonomy/term/\(self.level)")
            }
            var organisator: Events.Organisator = Events.Organisator(value: "")
            if self.organisator != nil {
                organisator = Events.Organisator(value: self.organisator!)
            }
            let registerwithJT = Events.RegisterwithJT(value: self.registerwithJT)
            var idnumber: Events.IDNumber = Events.IDNumber(value: "jt2018_pws")
            if self.idnumber != nil {
                idnumber = Events.IDNumber(value: self.idnumber!)
            } 
            let orguid = Events.OrgUID(id: Int(self.orguid), type: "user", uuid: "\(convertTid("CoreOrganisators", Int(self.orguid), "uuid"))", url: "/user/\(self.orguid)")
            var body: Events.Body = Events.Body(value: "", format: "", processed: "", summary: "")
            if self.bodyvalue != nil {
                bodyvalue = self.bodyvalue!
            }
            if self.bodyformat != nil {
                bodyformat = self.bodyformat!
            }
            if self.bodyprocessed != nil {
                bodyprocessed = self.bodyprocessed!
            }
            if self.bodysummary != nil {
                bodysummary = self.bodysummary!
            }
            body = Events.Body(value: bodyvalue, format: bodyformat, processed: bodyprocessed, summary: bodysummary)
            
            var poster: Events.Poster = Events.Poster(url: "")
            if self.poster != nil {
                poster = Events.Poster(url: self.poster!)
            }
            var country_code: String = ""
            if self.country_code != nil {
                country_code = self.country_code!
            }
            var administrative_area: String = ""
            if self.administrative_area != nil {
                administrative_area = self.administrative_area!
            }
            var locality: String = ""
            if self.locality != nil {
                locality = self.locality!
            }
            var dependent_locality: String = ""
            if self.dependent_locality != nil {
                dependent_locality = self.dependent_locality!
            }
            var postal_code: String = ""
            if self.postal_code != nil {
                postal_code = self.postal_code!
            }
            var sorting_code: String = ""
            if self.sorting_code != nil {
                sorting_code = self.sorting_code!
            }
            var address_line1: String = ""
            if self.address_line1 != nil {
                address_line1 = self.address_line1!
            }
            var address_line2: String = ""
            if self.address_line2 != nil {
                address_line2 = self.address_line2!
            }
            var organization: String = ""
            if self.organization != nil {
                organization = self.organization!
            }
            
            let address = Events.Address(country_code: country_code, administrative_area: administrative_area, locality: locality, dependent_locality: dependent_locality, postal_code: postal_code, sorting_code: sorting_code, address_line1: address_line1, address_line2: address_line2, organization: organization)
            
            var logoid: Int = 0
            if self.logo_user_id != 0 {
                logoid = Int(self.logo_user_id)
            }
            let logo = Events.Logo(target_id: logoid)
            
            
            return Events(tid: [tid], uuid: [uuid], title: [title], date: [date], eventtype: [eventtype], level: [level!], organisator: [organisator], registerwithJT: [registerwithJT], idnumber: [idnumber], orguid: [orguid], body: [body], poster: [poster], address: [address], logo: [logo])
        }
        set {
            self.tid = Int32((newValue.tid.first?.value)!)
            self.uuid = (newValue.uuid.first?.value)!
            self.title = (newValue.title.first?.value)!
            self.date = (newValue.date.first?.value)!
            self.eventtype = Int32((newValue.eventtype.first?.id)!)
            if newValue.level?.first != nil {
                self.level = Int32((newValue.level?.first?.id)!)
            }
            if newValue.organisator?.first != nil {
                self.organisator = (newValue.organisator?.first?.value)!
            }
            self.registerwithJT = (newValue.registerwithJT.first?.value)!
            if newValue.idnumber?.first != nil {
                self.idnumber = (newValue.idnumber?.first?.value)
            }
            self.orguid = Int32((newValue.orguid.first?.id)!)
            if newValue.body?.first?.value != nil {
                self.bodyvalue = newValue.body?.first?.value
            }
            if newValue.body?.first?.format != nil {
                self.bodyformat = newValue.body?.first?.format
            }
            if newValue.body?.first?.processed != nil {
                self.bodyprocessed = newValue.body?.first?.processed
            }
            if newValue.body?.first?.summary != nil {
                self.bodysummary = newValue.body?.first?.summary
            }
            if newValue.address?.first?.country_code != nil {
                self.country_code = newValue.address?.first?.country_code
            }
            if newValue.address?.first?.administrative_area != nil {
                self.administrative_area = newValue.address?.first?.administrative_area
            }
            if newValue.address?.first?.locality != nil {
                self.locality = newValue.address?.first?.locality
            }
            if newValue.address?.first?.dependent_locality != nil {
                self.dependent_locality = newValue.address?.first?.dependent_locality
            }
            if newValue.address?.first?.postal_code != nil {
                self.postal_code = newValue.address?.first?.postal_code
            }
            if newValue.address?.first?.sorting_code != nil {
                self.sorting_code = newValue.address?.first?.sorting_code
            }
            if newValue.address?.first?.address_line1 != nil {
                self.address_line1 = newValue.address?.first?.address_line1
            }
            if newValue.address?.first?.address_line2 != nil {
                self.address_line2 = newValue.address?.first?.address_line2
            }
            if newValue.address?.first?.organization != nil {
                self.organization = newValue.address?.first?.organization
            }
            if newValue.logo?.first != nil {
                self.logo_user_id = Int32((newValue.logo?.first?.target_id)!)
            }
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
