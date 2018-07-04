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
    var horsedata: [Horses] = []
    var horses = [Horses]()
    var filteredHorses = [Horses]()
    var selectedHorse: Horses?
    var favorites: [Horses] = []
    var personal: [Horses] = []
    
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
        
        // Show horseKeyPopup and ask for identification number
        if !exists {  // TODO: if identification is correct and !exists -> Add to table
            personal.append(selectedHorse!)
            tableView.reloadData()
        }
    }
    
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Get horses from CoreData first to quickload        
        searchBar.delegate = self
        pickerView.delegate = self
        pickerView.dataSource = self
        tableView.delegate = self
        tableView.dataSource = self
        filteredHorses = horses.sorted { ($0.name.first?.value)! < ($1.name.first?.value)! }
        selectedHorse = filteredHorses.first
        setupLayout()
        setupNavBar()
        // Do any additional setup after loading the view.
        
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //print("viewWillLayoutSubviews")
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
        return !searchBarIsEmpty()
    }

    
    // MARK: filter content for search text
    func filterContentForSearchText(_ searchText: String) {
        horses = horsedata
        filteredHorses = horses.sorted { ($0.name.first?.value)! < ($1.name.first?.value)! }
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
    
    func getName(_ entity: String, _ tid: Int, _ key: String) -> String {
        var result: NSManagedObject?
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.predicate = NSPredicate(format: "tid == %d", tid)
        do {
            let results = try self.appDelegate.getContext().fetch(fetchRequest) as? [NSManagedObject]
            result = results?.first
        } catch {
            print("Could not fetch")
        }
        return result!.value(forKey: key) as! String
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
        return filteredHorses[row].name.first?.value
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("selected horse = \(filteredHorses[row])")
        selectedHorse = filteredHorses[row]
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
        var chosenHorses: [Horses]?
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
        cell.horseName.text = chosenHorses![indexPath.row].name.first?.value
        let idArray: Array<Int32> = (chosenHorses![indexPath.row].studbook?.map { $0.id })!
        var acroArray: Array<String> = []
        if idArray.count > 0 {
            for id in idArray {
                let acroString = getName("CoreStudbooks", Int(id), "acro")
                acroArray.append(acroString)
            }
        } else {
            acroArray = [""]
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
                // Delete the row from the data source
                favorites.remove(at: indexPath.row)
                // Delete the row from the tableview
                tableView.deleteRows(at: [indexPath], with: .fade)
            } else {
                // Delete the row from the data source
                personal.remove(at: indexPath.row)
                // Delete the row from the tableview
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            //tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.section == 0 && destinationIndexPath.section == 1 {
            let rowToMove = favorites[sourceIndexPath.row]
            
            if !personal.contains(where: {$0.tid == rowToMove.tid}) {
                favorites.remove(at: sourceIndexPath.row)
                personal.insert(rowToMove, at: destinationIndexPath.row)
            } else {
                tableView.reloadData()
            }
            
        } else if sourceIndexPath.section == 1 && destinationIndexPath.section == 0 {
            let rowToMove = personal[sourceIndexPath.row]
            if !favorites.contains(where: {$0.tid == rowToMove.tid}) {
                personal.remove(at: sourceIndexPath.row)
                favorites.insert(rowToMove, at: destinationIndexPath.row)
            } else {
                tableView.reloadData()
            }
            
        } else {
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
