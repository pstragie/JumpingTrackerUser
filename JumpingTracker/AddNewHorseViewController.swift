//
//  AddNewHorseViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 11/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class AddNewHorseViewController: UIViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var requiredFields: Bool = false
    var coatColors: [CoatColors] = []
    var coatColorNames: Array<String> = []
    var studbooks: [Studbooks] = []
    //var studbookDict: Dictionary<String, String> = [:]
    let userDefault = UserDefaults.standard
    var detailHorse: Horses? {
        didSet {
            configureView()
        }
    }

    @IBOutlet var labels: [UILabel]!
    @IBOutlet var textFields: [UITextField]!
    @IBOutlet weak var studbookPickerView: UIPickerView!
    @IBOutlet weak var coatColorPickerView: UIPickerView!
    @IBOutlet weak var GenderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var deceasedSwitch: UISwitch!
    @IBOutlet weak var horseNameField: UITextField!
    @IBOutlet weak var identificationField: UITextField!
    @IBOutlet weak var birthYearField: UITextField!
    @IBOutlet weak var fatherField: UITextField!
    @IBOutlet weak var motherField: UITextField!
    @IBOutlet weak var ownerNameField: UITextField!
    @IBOutlet weak var heightField: UITextField!
    @IBOutlet weak var stubookRegistrationField: UITextField!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        coatColorPickerView.delegate = self
        coatColorPickerView.dataSource = self
        studbookPickerView.delegate = self
        studbookPickerView.dataSource = self
        coatColorNames = fetchCoatColors()
        setupLayout()
        getCoatColors()
        print("coat colors: \(String(describing: coatColors))")
        getStudbooks()
        print("studbooks: \(String(describing: studbooks))")
        setupPickerViews()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - setup pickerViews
    func setupPickerViews() {
        
    }
    
    func setupLayout() {
        
        if detailHorse != nil {
            horseNameField.isEnabled = false
            fillFields()
        }
    }
    
    func fillFields() {
        if detailHorse?.name.first != nil {
            self.horseNameField.text = detailHorse?.name[0].value
        }
        if detailHorse?.idnumber.first != nil {
            self.identificationField.text = detailHorse?.idnumber[0].value
        }
        if detailHorse?.gender?.first != nil {
            let g = getName("CoreGender", Int((detailHorse?.gender![0].id)!), "name")

            if g == "Gelding", GenderSegmentedControl.titleForSegment(at: 0) == g {
                self.GenderSegmentedControl.selectedSegmentIndex = 0
            } else if g == "Mare" {
                self.GenderSegmentedControl.selectedSegmentIndex = 1
            } else if g == "Stallion" {
                self.GenderSegmentedControl.selectedSegmentIndex = 2
            } else {
                self.GenderSegmentedControl.selectedSegmentIndex = -1
            }
        }
        if detailHorse?.father?.first != nil {
            self.fatherField.text = getName("CoreHorses", Int((detailHorse?.father![0].id)!), "name")
        } else {
            self.fatherField.text = ""
        }
        if detailHorse?.mother?.first != nil {
            self.motherField.text = getName("CoreHorses", Int((detailHorse?.mother![0].id)!), "name")
        } else {
            self.motherField.text = ""
        }
        if detailHorse?.birthday?.first != nil {
            self.birthYearField.text = getName("CoreJaartallen", Int((detailHorse?.birthday![0].id)!), "name")
        } else {
            self.birthYearField.text = ""
        }
        if detailHorse?.owner?.first != nil {
            self.ownerNameField.text = detailHorse?.owner![0].owner
        } else {
            self.ownerNameField.text = ""
        }
        if detailHorse?.height?.first != nil {
            self.heightField.text = String((detailHorse?.height![0].value)!)
        } else {
            self.heightField.text = ""
        }
        if detailHorse?.studreg?.first != nil {
            self.stubookRegistrationField.text = detailHorse?.studreg![0].value
        } else {
            self.stubookRegistrationField.text = ""
        }
        if detailHorse?.coatcolor?.first != nil {
            let row = coatColorNames.index(of: getName("CoreCoatColors", Int((detailHorse?.coatcolor![0].id)!), "name"))
            self.coatColorPickerView.selectRow(row!, inComponent: 0, animated: true)
        }
    }
    func fetchCoatColors() -> Array<String> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreCoatColors")
        var color: CoatColors
        var coatNames: Array<String> = []
        do {
            let results = try self.appDelegate.getContext().fetch(fetchRequest)
            for items in results as! [CoatColor] {
                color = items.allAtributes
                coatNames.append((color.name.first?.value)!)
            }
        } catch {
            print("Could not fetch coat colors!")
        }
        return coatNames
    }
    func getCoatColors() {
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreCoatColors")
        do {
            let results = try context.fetch(fetchRequest)
            for items in results as! [CoatColor] {
                let coatcolors = items.allAtributes
                coatColors.append(coatcolors)
            }
        } catch {
            print("Could not fetch Coat colors")
        }
        
    }
    func getStudbooks() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreStudbooks")
        fetchRequest.predicate = NSPredicate(format: "active == YES")
        do {
            let results = try self.appDelegate.getContext().fetch(fetchRequest)
            for items in results as! [Studbook] {
                let studbook = items.allAtributes
                studbooks.append(studbook)
            }
        } catch {
            print("Could not fetch Coat colors")
        }
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
    func configureView() {
        if let detailHorse = detailHorse {
            if #available(iOS 11.0, *) {
                navigationItem.largeTitleDisplayMode = .never
            } else {
                // Fallback on earlier versions
            }
            
            print("Horse name: \(detailHorse)")
        }
    }

    func verifyRequiredFields() -> Bool {
        guard
            //let horsename = horseNameField.text, !horsename.isEmpty,
            let identification = identificationField.text, !identification.isEmpty,
            let father = fatherField.text, !father.isEmpty,
            let mother = motherField.text, !mother.isEmpty,
            let birth = birthYearField.text, !birth.isEmpty
            else
        {
            requiredFields = false
            self.view.shake()
            return false
        }
        requiredFields = true
        return true
    }
}

extension AddNewHorseViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == coatColorPickerView {
            return self.coatColorNames.count
        }
        return self.studbooks.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == coatColorPickerView {
            return self.coatColorNames[row]
        }
        return self.studbooks[row].name[0].value
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
    }
}
