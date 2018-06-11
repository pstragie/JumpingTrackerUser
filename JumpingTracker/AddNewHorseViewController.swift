//
//  AddNewHorseViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 11/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit

class AddNewHorseViewController: UIViewController {

    var coatColors: [CoatColor]?
    var studbooks: [Studbook]?
    //var studbookDict: Dictionary<String, String> = [:]
    let userDefault = UserDefaults.standard
    
    @IBOutlet var labels: [UILabel]!
    @IBOutlet var textFields: [UITextField]!
    @IBOutlet weak var studbookPickerView: UIPickerView!
    @IBOutlet weak var coatColorPickerView: UIPickerView!
    @IBOutlet weak var GenderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var deceasedSwitch: UISwitch!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var horseNameField: UITextField!
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
        coatColors = userDefault.value(forKey: "coatcolors") as? [CoatColor]
        studbooks = userDefault.value(forKey: "studbooksStruct") as? [Studbook]
        //studbookDict = self.userDefault.value(forKey: "studbooks") as! Dictionary<String, String>
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AddNewHorseViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == coatColorPickerView {
            return self.coatColors!.count
        }
        return self.studbooks!.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == coatColorPickerView {
            return self.coatColors![row].name.first?.value
        }
        return self.studbooks![row].acro.first?.value
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
    }
}
