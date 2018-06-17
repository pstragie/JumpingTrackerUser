//
//  HorseMode.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 31/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import CoreData
import UIKit

let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext

struct Horses: Codable {
    var tid: [ID]
    var uuid: [UUID]
    var name: [Name]
    var studbook: [Studbook]?
    var owner: [Owner]?
    var birthday: [Birthday]?
    var discipline: [Discipline]?
    var gender: [Gender]?
    var father: [Father]?
    var mother: [Mother]?
    var deceased: [Deceased]?
    var coatcolor: [Coatcolor]?
    var studreg: [Studreg]?
    var height: [Height]?
    var idnumber: [IDNumber]
    
    var studbookOptional: [Horses.Studbook] {
        get {
            return (self.studbook ?? [])
        }
    }
    var studregOptional: [Horses.Studreg] {
        get {
            return (self.studreg ?? [])
        }
    }
    init(tid: [Horses.ID], uuid: [Horses.UUID], name: [Horses.Name], studbook: [Horses.Studbook]? = nil, owner: [Horses.Owner]? = nil, birthday: [Horses.Birthday]? = nil, discipline: [Horses.Discipline]? = nil, gender: [Horses.Gender]? = nil, father: [Horses.Father]? = nil, mother: [Horses.Mother]? = nil, deceased: [Horses.Deceased], coatcolor: [Horses.Coatcolor]? = nil, studreg: [Horses.Studreg]? = nil, height: [Horses.Height]? = nil, idnumber: [Horses.IDNumber]) {
        self.tid = tid
        self.uuid = uuid
        self.name = name
        self.idnumber = idnumber
        self.studbook = studbook ?? []
        self.owner = owner ?? []
        self.birthday = birthday ?? []
        self.discipline = discipline ?? []
        self.gender = gender ?? []
        self.father = father ?? []
        self.mother = mother ?? []
        self.deceased = deceased
        self.coatcolor = coatcolor ?? []
        self.studreg = studreg ?? []
        self.height = height ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case tid, uuid, name
        case idnumber = "field_identification_ndeg"
        case studbook = "field_studbook"
        case owner = "field_current_owner"
        case birthday = "field_birth_year"
        case discipline = "field_discipline"
        case gender = "field_gender"
        case father = "field_father"
        case mother = "field_mother"
        case deceased = "field_deceased"
        case coatcolor = "field_coat_color"
        case studreg = "field_studbook_registration_numb"
        case height = "field_horse_height"
    }
    
    struct ID: Codable, Equatable {
        var value: Int32
    }
    
    struct UUID: Codable {
        var value: String
    }
    
    struct Name: Codable, Equatable {
        var value: String
    }
    
    struct Studbook: Codable {
        var id: Int32
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
    
    struct Owner: Codable {
        var owner: String
        
        enum CodingKeys: String, CodingKey {
            case owner = "value"
        }
    }
    
    struct IDNumber: Codable, Equatable {
        var value: String
    }
    
    struct Birthday: Codable, Equatable {
        var id: Int32
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
    
    struct Discipline: Codable, Equatable {
        var id: Int32
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
    
    struct Father: Codable {
        var id: Int32
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
    
    struct Mother: Codable {
        var id: Int32
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
    struct Height: Codable {
        var value: Int
    }
    struct Gender: Codable {
        var id: Int32
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
    
    struct Deceased: Codable {
        var value: Bool
    }
    
    struct Coatcolor: Codable {
        var id: Int32
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
    
    struct Studreg: Codable {
        var value: String
    }
}
/*
struct Horse {
    let name: String
    let tid: Int
    let father: Int
    let mother: Int
    let uuid: String
    let height: Int
    let birthday: Int
    let deceased: Bool
    let studreg: String
    let studbooks: Array<Int>
    let coatcolors: Array<Int>
    let disciplines: Array<Int>
    let owner: String
    let gender: Int
}
*/

extension Horse {
    
    
    var allAtributes: Horses {
        get {
            let tid = Horses.ID(value: self.tid)
            let uuid = Horses.UUID(value: self.uuid!)
            let name = Horses.Name(value: self.name!)
            let idnumber = Horses.IDNumber(value: self.identification!)
            let owner = Horses.Owner(owner: self.owner ?? "")
            
            let father = Horses.Father(id: self.father , type: "taxonomy_term", uuid: "\(convertTid("CoreHorses", Int(self.father), "uuid"))", url: "/taxonomy/term/\(self.father)")
            let mother = Horses.Mother(id: self.father, type: "taxonomy_term", uuid: "\(convertTid("CoreHorses", Int(self.mother), "uuid"))", url: "/taxonomy/term/\(self.mother)")
            let gender = Horses.Gender(id: self.gender, type: "taxonomy_term", uuid: "\(convertTid("CoreGender", Int(self.gender), "uuid"))", url: "/taxonomy/term/\(self.gender)")
            let birthDay = Horses.Birthday(id: self.birthday, type: "taxonomy_term", uuid: "\(convertTid("CoreJaartallen", Int(self.birthday), "uuid"))", url: "/taxonomy/term/\(self.birthday)")
            let height = Horses.Height(value: Int(self.height))
            let deceased = Horses.Deceased(value: self.deceased)
            let studreg = Horses.Studreg(value: self.studreg ?? "")
            var studArray: Array<Horses.Studbook> = []
            if self.studbooks != nil {
                for studbookid in (self.studbooks as! Array<Int>) {
                    let resultUuid: String = convertTid("CoreStudbooks", Int(studbookid), "uuid")
                    studArray.append(Horses.Studbook(id: Int32(studbookid), type: "taxonomy_term", uuid: resultUuid, url: "taxonomy/term/\(studbookid)"))
                }
            } else {
                studArray = []
            }
            var discArray: Array<Horses.Discipline> = []
            if self.disciplines != nil {
                for discid in self.disciplines as! Array<Int>{
                    let resultUuid: String = convertTid("CoreDisciplines", discid, "uuid")
                    discArray.append(Horses.Discipline(id: Int32(discid), type: "taxonomy_term", uuid: resultUuid, url: "taxonomy/term/\(discid)"))
                }
            } else {
                discArray = []
            }
            var coatArray: Array<Horses.Coatcolor> = []
            if self.coatcolors != nil {
                for coatid in self.coatcolors as! Array<Int> {
                    let resultUuid: String = convertTid("CoreCoatColors", coatid, "uuid")
                    coatArray.append(Horses.Coatcolor(id: Int32(coatid), type: "taxonomy_term", uuid: resultUuid, url: "taxonomy/term/\(coatid)"))
                }
            } else {
                coatArray = []
            }
            return Horses(tid: [tid], uuid: [uuid], name: [name], studbook: studArray, owner: [owner], birthday: [birthDay], discipline: discArray, gender: [gender], father: [father], mother: [mother], deceased: [deceased], coatcolor: coatArray, studreg: [studreg], height: [height], idnumber: [idnumber])
        }
        set {
            self.tid = Int32((newValue.tid.first?.value)!)
            self.uuid = (newValue.uuid.first?.value)!
            self.name = (newValue.name.first?.value)!
            self.identification = (newValue.name.first?.value)!
            if newValue.father?.first?.id != nil {
                self.father = Int32((newValue.father?.first?.id)!)
            }
            if newValue.mother?.first?.id != nil {
                self.mother = Int32((newValue.mother?.first?.id)!)
            }
            if newValue.height?.first?.value != nil {
                self.height = Int32((newValue.height?.first?.value)!)
            }
            if newValue.birthday?.first?.id != nil {
                self.birthday = Int32((newValue.birthday?.first?.id)!)
            }
            self.deceased = (newValue.deceased?.first?.value)!
            if newValue.studreg?.first?.value != nil {
                self.studreg = (newValue.studreg?.first?.value)!
            }
            if newValue.owner?.first?.owner != nil {
                self.owner = (newValue.owner?.first?.owner)!
            }
            if newValue.gender?.first?.id != nil {
                self.gender = Int32((newValue.gender?.first?.id)!)
            }
            if newValue.studbook?.first != nil {
                self.studbooks = [(newValue.studbook?.first.map { $0.id })!] as NSObject
            }
            if newValue.coatcolor?.first != nil {
                self.coatcolors = [(newValue.coatcolor?.first.map { $0.id })!] as NSObject
            }
            if newValue.discipline?.first != nil {
                self.disciplines = [(newValue.discipline?.first.map { $0.id })!] as NSObject
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
    
    
    func convertGender(_ tid: Int) -> Dictionary<String, String> {
        let uuid = convertTid("CoreGender", tid, "uuid")
        let name = convertTid("CoreGender", tid, "name")
        return ["name": name, "uuid": uuid]
    }
}
