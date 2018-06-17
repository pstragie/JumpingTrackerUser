//
//  StudbookMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 31/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData

struct Studbooks: Codable {
    var tid: [NumberID]
    var uuid: [UUID]
    var name: [Name]
    var acro: [Acro]?
    
    init(tid: [Studbooks.NumberID], uuid: [Studbooks.UUID], name: [Studbooks.Name], acro: [Studbooks.Acro]? = nil) {
        self.tid = tid
        self.uuid = uuid
        self.name = name
        self.acro = acro ?? []
    }
    enum CodingKeys: String, CodingKey {
        case tid
        case uuid
        case name
        case acro = "field_acronyme"
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

    struct Acro: Codable {
        var value: String
    }
}

extension Studbook {
    var allAtributes: Studbooks {
        get {
            let tid = Studbooks.NumberID(value: self.tid)
            let uuid = Studbooks.UUID(value: self.uuid!)
            let name = Studbooks.Name(value: self.name!)
            var acro: [Studbooks.Acro] = []
            if self.acro != nil {
                acro = [Studbooks.Acro(value: self.acro!)]
            } else {
                acro = []
            }
            return Studbooks(tid: [tid], uuid: [uuid], name: [name], acro: acro)
        }
        set {
            self.tid = (newValue.tid.first?.value)!
            self.uuid = (newValue.uuid.first?.value)!
            self.name = (newValue.name.first?.value)!
            if newValue.acro?.first != nil {
                self.acro = (newValue.acro?.first?.value)!
            }
        }
    }
}
