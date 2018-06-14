//
//  EventMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 29/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData

struct Events: Codable {
    var title: [Title]
    var address: [Address]
    var date: [Date]
    
    enum CodingKeys: String, CodingKey {
        case title
        case address = "field_event_address"
        case date = "field_event_date"
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
}

extension Event {
    
    var allAtributes: Events {
        get {
            let title = Events.Title(value: self.title!)
            let address = Events.Address(countryCode: self.countrycode!, locality: self.locality!)
            let date = Events.Date(value: self.date!)
            return Events(title: [title], address: [address], date: [date])
        }
        set {
            self.title = (newValue.title.first?.value)!
            self.countrycode = (newValue.address.first?.countryCode)!
            self.locality = (newValue.address.first?.locality)!
            self.date = (newValue.date.first?.value)!
        }
    }
}
