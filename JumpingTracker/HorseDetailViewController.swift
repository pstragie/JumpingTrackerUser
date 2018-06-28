//
//  HorseDetailViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 05/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit
import CoreData

class HorseDetailViewController: UIViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let userDefault = UserDefaults.standard
    var horseEditing: Bool = false
    var detailHorse: Horses? {
        didSet {
            configureView()
        }
    }

    var idField: String = ""
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var popup: UIVisualEffectView!
    @IBOutlet weak var horseName: UILabel!
    @IBOutlet weak var studbook: UILabel!
    @IBOutlet weak var fatherLabel: UILabel!
    @IBOutlet weak var fatherName: UILabel!
    @IBOutlet weak var motherLabel: UILabel!
    @IBOutlet weak var motherName: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var ownerName: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var heightName: UILabel!
    @IBOutlet weak var birthLabel: UILabel!
    @IBOutlet weak var birthName: UILabel!
    @IBOutlet weak var studRegLabel: UILabel!
    @IBOutlet weak var studRegName: UILabel!
    @IBOutlet weak var coatColorLabel: UILabel!
    @IBOutlet weak var coatColorName: UILabel!
    @IBOutlet weak var horseImage: UIImageView!
    @IBOutlet weak var genderImage: UIImageView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adjustLargeTitleSize()
        setupPopupView()
        configureView()
        setupLayout()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        popup.alpha = 0.0
    }
    
    func setupPopupView() {
        popup.alpha = 0
        popup.layer.borderWidth = 1.5
        popup.layer.masksToBounds = true
        popup.layer.cornerRadius = 15
        popup.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        popup.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
        popupView.layer.borderWidth = 1.5
        popupView.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        popupView.layer.cornerRadius = 15
        popupView.layer.masksToBounds = true
        popupView.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
        idTextField.tintColor = UIColor.FlatColor.Gray.IronGray
        idTextField.becomeFirstResponder()
        okButton.setTitle("Verify", for: .normal)
        okButton.layer.borderWidth = 1.5
        okButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        okButton.layer.borderWidth = 1.5
        okButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        okButton.layer.cornerRadius = 5
        okButton.layer.masksToBounds = true
        okButton.tintColor = UIColor.white
        okButton.addTarget(self, action: #selector(verifyID), for: .touchUpInside)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.layer.borderWidth = 1.5
        cancelButton.layer.borderColor = UIColor.FlatColor.Gray.IronGray.cgColor
        cancelButton.layer.borderWidth = 1.5
        cancelButton.backgroundColor = UIColor.FlatColor.Gray.AlmondFrost
        cancelButton.layer.cornerRadius = 5
        cancelButton.layer.masksToBounds = true
        cancelButton.tintColor = UIColor.white
        cancelButton.addTarget(self, action: #selector(cancelID), for: .touchUpInside)
    }
    
    func configureView() {
        if let detailHorse = detailHorse {
            if #available(iOS 11.0, *) {
                self.navigationItem.largeTitleDisplayMode = .never
            } else {
                // Fallback on earlier versions
            }
            let rightBarButtonItems: [UIBarButtonItem]
            navigationController?.navigationItem.title = detailHorse.name.first?.value
            if userDefault.bool(forKey: "loginSuccessful") {
                rightBarButtonItems = [UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTapped))]
            } else {
                rightBarButtonItems = []
            }
            navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
            let logo = UIImage(named: "tab_horse_head_styled")
            let imageView = UIImageView(image: logo!)
            self.navigationItem.titleView = imageView
            print("Horse name: \(detailHorse)")
        }
    }

    @objc func verifyID() {
        self.idField = self.idTextField.text!
        if idIsCorrect(id: self.idField) {
            self.view.endEditing(true)
            self.horseEditing = true
            // Upon verification -> Go to AddNewHorseViewController with filled fields
            let storyboardSegue = UIStoryboardSegue(identifier: "AddNewHorse", source: HorseDetailViewController(), destination: AddNewHorseViewController())
            prepare(for: storyboardSegue, sender: okButton)
            popup.alpha = 0.0
        } else {
            popup.shake()
        }
    }

    @objc func cancelID() {
        self.view.endEditing(true)
        self.horseEditing = false
        UIView.animate(withDuration: 2.0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .curveLinear, animations: {
            self.popup.alpha = 0.0
        })
    }
        
    @objc func editTapped() {
        // popup to verify identification number
        self.horseEditing = true
        UIView.animate(withDuration: 2.0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.popup.alpha = 1.0
        })
    }

    func idIsCorrect(id: String) -> Bool {
        // fetch horse id
        let idnumber = detailHorse?.idnumber
        if idnumber![0].value == id {
            return true
        }
        return false
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
    
    
    func setupLayout() {
        horseName.text = detailHorse?.name.first?.value
        if detailHorse?.studbook?.first != nil {
            print("get acros")
            let idArray: Array<Int32> = (detailHorse?.studbook?.map { $0.id })!
            var acroArray: Array<String> = []
            if idArray.count > 0 {
                for id in idArray {
                    let acroString = getName("CoreStudbooks", Int(id), "acro")
                    acroArray.append(acroString)
                }
            } else {
                acroArray = [""]
            }
            studbook.text = acroArray.joined(separator: ", ")
        } else {
            studbook.text = ""
        }
        if detailHorse?.father?.first != nil {
            print("get father")
            fatherName.text = getName("CoreHorses", Int((detailHorse?.father?.first?.id)!), "name")
        } else {
            fatherName.text = "X"
        }
        if detailHorse?.mother?.first != nil {
            print("get mother")
            motherName.text = getName("CoreHorses", Int((detailHorse?.mother?.first?.id)!), "name")
        } else {
            motherName.text = "X"
        }
        if detailHorse?.owner?.first != nil {
            ownerName.text = detailHorse?.owner?.first?.owner
        }
        if detailHorse?.height?.first != nil {
            heightName.text = String((detailHorse?.height?.first?.value)!)
        }
        if detailHorse?.birthday?.first != nil {
            print("get birthday")
            birthName.text = getName("CoreJaartallen", Int((detailHorse?.birthday?.first?.id)!), "name")
        }
        if detailHorse?.studreg?.first != nil {
            studRegName.text = detailHorse?.studreg?.first?.value
        } else {
            studRegName.text = ""
        }
        if detailHorse?.coatcolor?.first != nil {
            print("get coatcolor")
            coatColorName.text = getName("CoreCoatColors", Int((detailHorse?.coatcolor?.first?.id)!), "name")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "segueToEdit":
            let controller = (segue.destination as! UINavigationController).topViewController as! AddNewHorseViewController
            let horse = detailHorse
            controller.detailHorse = horse
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.navigationController?.title = "Edit horse details"
            let rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))]
            controller.navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
            break
        default:
            break
        }
        
    }
 
    
    @objc func saveTapped() {
        if horseEditing {
            if AddNewHorseViewController().verifyRequiredFields() {
                let storyboardSegue: UIStoryboardSegue = UIStoryboardSegue(identifier: "horseDetail", source: AddNewHorseViewController(), destination: HorseDetailViewController())
                unwind(for: storyboardSegue, towardsViewController: HorseDetailViewController())
                // Patch changes to server
                print("patch to server")
            } else {
                print("Not all required fields have content")
            }
        } else {
            if AddNewHorseViewController().requiredFields {
                // Post new horse to server
                print("post to server")
            } else {
                print("Not all required fields for new horse are filled.")
            }
        }
        // Update coreHorses
    }
    @objc func textFieldIsNotEmpty(sender: UITextField) {
        sender.text = sender.text?.trimmingCharacters(in: .whitespaces)
        
        guard
            let idnumber = idTextField.text, !idnumber.isEmpty
            else
        {
            self.okButton.isEnabled = false
            self.okButton.alpha = 0.5
            return
        }
        okButton.isEnabled = true
        okButton.alpha = 1.0
    }
}

extension HorseDetailViewController {
    func adjustLargeTitleSize() {
        guard let title = title, #available(iOS 11.0, *) else { return }
        
        let maxWidth = UIScreen.main.bounds.size.width - 60
        var fontSize = UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
        var width = title.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: fontSize)]).width
        while width > maxWidth {
            fontSize -= 1
            width = title.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: fontSize)]).width
        }
        
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.FlatColor.Blue.BlueWhale, NSAttributedStringKey.font: UIFont(name: "Papyrus", size: fontSize) ?? UIFont.boldSystemFont(ofSize: fontSize)]
    }
}
