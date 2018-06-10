//
//  AddFavoriteHorseViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 09/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit
import CoreData

class AddFavoriteHorseViewController: UIViewController {

    // MARK: - variables
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let userDefault = UserDefaults.standard
    var category: String?
    var horses = [Horse]()
    var filteredHorses = [Horse]()
    var selectedHorse: Horse?
    var favorites = [Horse]()
    var personal = [Horse]()
    
    // MARK: - outlets
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBAction func AddToFavorites(_ sender: UIButton) {
        let exists: Bool = favorites.contains { (horse) -> Bool in
            horse.name == selectedHorse!.name
        }
        if !exists {
            favorites.append(selectedHorse!)
            tableView.reloadData()
        }
    }
    @IBAction func addToPersonal(_ sender: UIButton) {
        let exists: Bool = personal.contains { (horse) -> Bool in
            horse.name == selectedHorse!.name
        }
        if !exists {
            personal.append(selectedHorse!)
            tableView.reloadData()
        }
    }
    
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        horses = requestFromCoreData("")
        searchBar.delegate = self
        pickerView.delegate = self
        pickerView.dataSource = self
        tableView.delegate = self
        tableView.dataSource = self
        filteredHorses = horses.sorted { $0.name < $1.name }
        selectedHorse = filteredHorses.first
        setupLayout()
        setupNavBar()
        // Do any additional setup after loading the view.
        
    }

    override func viewWillLayoutSubviews() {
        print("viewWillLayoutSubviews")
        if filteredHorses.count == 0 {
            for button in buttons {
                button.isEnabled = false
            }
        } else {
            for button in buttons {
                button.isEnabled = true
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - setup Layout
    func setupLayout() {
        for button in buttons {
            button.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
            button.layer.borderWidth = 1.5
            button.layer.cornerRadius = 5
            button.layer.masksToBounds = true
            button.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
            button.tintColor = UIColor.white
        }
        tableView.setEditing(true, animated: true)
    }

    // MARK: setup navigationbar
    func setupNavBar() {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        } else {
            // Fallback on earlier versions
        }
        //navigationController?.title = category!
    }
    // MARK: search bar empty?
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchBar.text?.isEmpty ?? true
    }
    // MARK: search is filtering?
    func isFiltering() -> Bool {
        print("filtering: \(!searchBarIsEmpty())")
        return !searchBarIsEmpty()
    }
    // MARK: - Fetch request from Core Data
    func requestFromCoreData(_ searchText: String) -> [Horse] {
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreHorses")
        var h = [Horse]()
        if isFiltering() {
            request.predicate = NSPredicate(format: "name CONTAINS[c] %@", searchText)
        }
        request.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                h.append(Horse(tid: data.value(forKey: "tid") as! Int, uuid: data.value(forKey: "uuid") as! String, name: data.value(forKey: "name") as! String, owner: data.value(forKey: "owner") as! String, birthDay: data.value(forKey: "birthday") as! String, studbook: (data.value(forKey: "studbook") as? Array<String>)!, discipline: (data.value(forKey: "discipline") as? Array<String>)!))
                print(data.value(forKey: "name") as! String)
            }
        } catch {
            print("Failed")
        }
        return h
    }
    
    // MARK: filter content for search text
    func filterContentForSearchText(_ searchText: String) {
        horses = requestFromCoreData(searchText)
        filteredHorses = horses.sorted { $0.name < $1.name }
        selectedHorse = filteredHorses.first
        pickerView.reloadAllComponents()
    }
    
    // MARK: convert ID to name
    func convertIDtoName(idArray: Array<String>, dict: Dictionary<String, String>) -> String {
        var newArray: Array<String> = []
        var newString: String = ""
        for id in idArray {
            if let acro = dict[String(id)] {
                newArray.append(acro)
            }
        }
        // map array to string and join
        let flatArray = newArray.map{ String($0) }
        newString = flatArray.joined(separator: ", ")
        return newString
    }
}


// MARK: UISearchBarDelegate extension
extension AddFavoriteHorseViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterContentForSearchText(searchText)
        if filteredHorses.count == 0 {
            for button in buttons {
                button.isEnabled = false
            }
        } else {
            for button in buttons {
                button.isEnabled = true
            }
        }
    }
}

extension AddFavoriteHorseViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        print("number of rows: \(filteredHorses.count)")
        return filteredHorses.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filteredHorses[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("selected horse = \(filteredHorses[row])")
        let tid = filteredHorses[row].tid
        let uuid = filteredHorses[row].uuid
        let name = filteredHorses[row].name
        let owner = filteredHorses[row].owner
        let birthday = filteredHorses[row].birthDay
        let studbook: Array<String> = filteredHorses[row].studbook
        let discipline: Array<String> = filteredHorses[row].discipline
        //let deceased: Bool = filteredHorses[row].deceased
        selectedHorse = Horse(tid: tid, uuid: uuid, name: name, owner: owner, birthDay: birthday, studbook: studbook, discipline: discipline)
    }
}

extension AddFavoriteHorseViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionName: String
        switch (section) {
        case 0:
            sectionName = NSLocalizedString("Favorite horses", comment: "")
        case 1:
            sectionName = NSLocalizedString("Personal horses", comment: "")
        default:
            sectionName = ""
        }
        return sectionName
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return favorites.count
        } else {
            return personal.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HorseTableCell", for: indexPath) as? HorseTableCell else {
            fatalError("Unexpected Index Path")
        }
        var chosenHorses: [Horse]?
        cell.selectionStyle = .gray
        cell.layer.cornerRadius = 0
        cell.layer.masksToBounds = true
        cell.layer.borderWidth = 0
        if indexPath.section == 0 {
            chosenHorses = favorites
        } else {
            chosenHorses = personal
        }
        self.tableView.isHidden = false
        cell.horseName.text = chosenHorses![indexPath.row].name
        let idArray = chosenHorses![indexPath.row].studbook
        if (idArray.count) > 0 {
            let acroString = convertIDtoName(idArray: idArray, dict: (self.userDefault.object(forKey: "studbooks") as? Dictionary<String, String>)!)
            cell.studbook.text = acroString
        } else {
            cell.studbook.text = ""
        }
        
        
        return cell
    
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 10
    }
    
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 {
                favorites.remove(at: indexPath.row)
            } else {
                personal.remove(at: indexPath.row)
            }
            tableView.reloadData()
        }
    }
}
