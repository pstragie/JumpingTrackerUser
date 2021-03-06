//
//  UserMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 03/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import UIKit
import CoreData

struct User: Codable {
    var firstName: [FirstName]?
    var surName: [SurName]?
    var name: [Name]?
    var uid: [UID]
    var uuid: [UUID]?
    var mail: [Mail]?
    var organisation: [Organisation]?
    var logo: [Logo]?
    var eventAddress: [EventAddress]?
    var favHorses: [FavHorses]?
    var perHorses: [PerHorses]?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "field_firstname"
        case surName = "field_surname"
        case name = "name"
        case uid = "uid"
        case uuid = "uuid"
        case mail = "mail"
        case organisation = "field_organisation_name"
        case logo = "field_organisation_logo"
        case eventAddress = "field_event_address"
        case favHorses = "field_favorite_horses"
        case perHorses = "field_your_horses"
    }
    
    init(firstName: [FirstName]? = nil, surName: [SurName]? = nil, name: [Name]? = nil, uid: [UID], uuid: [UUID]? = nil, mail: [Mail]? = nil, organisation: [Organisation]? = nil, logo: [Logo]? = nil, eventAddress: [EventAddress]? = nil, favHorses: [FavHorses]? = nil, perHorses: [PerHorses]? = nil) {
        self.firstName = firstName
        self.surName = surName
        self.name = name
        self.uid = uid
        self.uuid = uuid
        self.mail = mail
        self.organisation = organisation
        self.logo = logo
        self.eventAddress = eventAddress
        self.favHorses = favHorses
        self.perHorses = perHorses
    }
   
    struct FirstName: Codable {
        var value: String
    }
    
    struct SurName: Codable {
        var value: String
    }
    
    struct EventAddress: Codable {
        var country_code: String
        var locality: String
        var postal_code: String
        var address_line1: String
    }
    
    struct Logo: Codable {
        var url: String
    }
    
    struct Name: Codable {
        var value: String
    }
    struct UID: Codable, Equatable {
        var value: Int
    }
    struct UUID: Codable {
        var value: String
    }
    struct Mail: Codable {
        var value: String
    }
    
    struct Organisation: Codable {
        var orgid: Int
        
        
        enum CodingKeys: String, CodingKey {
            case orgid = "target_id"
            
        }
        
    
    }
    struct FavHorses: Codable {
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
    
    struct PerHorses: Codable {
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

extension CurrentUser {
    var allAtributes: User {
            get {
                let uid = User.UID(value: Int(self.uid))
                let firstname = User.FirstName(value: self.firstname!)
                let surname = User.SurName(value: self.surname!)
                let mail = User.Mail(value: self.mail!)
                let uuid = User.UUID(value: self.uuid!)
                let name = User.Name(value: self.name!)
                var favArray: [User.FavHorses]? = []
                if self.favHorses != nil {
                    for fav in self.favHorses as! Array<Int> {
                        let fuuid: String = convertTid("CoreHorses", fav, "uuid")
                        let favy: User.FavHorses = User.FavHorses(id: fav, type: "taxonomy_term", uuid: fuuid, url: "/taxonomy/term/\(fav)")
                        favArray?.append(favy)
                    }
                }
                var perArray: [User.PerHorses]? = []
                if self.perHorses != nil {
                    for pers in self.perHorses as! Array<Int> {
                        let puuid: String = convertTid("CoreHorses", pers, "uuid")
                        let pery: User.PerHorses = User.PerHorses(id: pers, type: "taxonomy_term", uuid: puuid, url: "/taxonomy/term/\(pers)")
                        perArray?.append(pery)
                    }
                }
                var organisation: [User.Organisation] = []
                if self.organisationID != 0 {
                    organisation =  [User.Organisation(orgid: Int(self.organisationID))]
                }
                var logo: [User.Logo] = []
                if self.logo != nil {
                    logo = [User.Logo(url: self.logo!)]
                }
                
                let eventAddress: User.EventAddress = User.EventAddress(country_code: self.eventCountryCode!, locality: self.eventLocality!, postal_code: self.eventPostalCode!, address_line1: self.eventAddressLine1!)
        return User(firstName: [firstname], surName: [surname], name: [name], uid: [uid], uuid: [uuid], mail: [mail], organisation: organisation, logo: logo, eventAddress: [eventAddress], favHorses: favArray, perHorses: perArray)
            }
            set {
                self.name = newValue.name?.first?.value
                self.uid = Int32((newValue.uid.first?.value)!)
                self.uuid = (newValue.uuid?.first?.value)!
                self.firstname = (newValue.firstName?.first?.value)!
                self.surname = (newValue.surName?.first?.value)!
                self.mail = (newValue.mail?.first?.value)!
                self.organisationID = Int32((newValue.organisation?.first?.orgid)!)
                self.logo = newValue.logo?.first?.url
                self.eventCountryCode = (newValue.eventAddress?.first?.country_code)
                self.eventLocality = newValue.eventAddress?.first?.locality
                self.eventPostalCode = newValue.eventAddress?.first?.postal_code
                self.eventAddressLine1 = newValue.eventAddress?.first?.address_line1
                self.favHorses = [(newValue.favHorses?.first.map { $0.id })!] as NSObject
                self.perHorses = [(newValue.perHorses?.first.map { $0.id })!] as NSObject
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
