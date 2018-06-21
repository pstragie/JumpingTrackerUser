//
//  EventDetailViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 17/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit
import CoreData

class EventDetailViewController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let userDefault = UserDefaults.standard
    var eventEditing: Bool = false
    var detailEvent: Events? {
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
    
    @IBOutlet weak var eventName: UILabel!
    @IBOutlet weak var organisator: UILabel!
    @IBOutlet weak var eventLogo: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var streetName: UILabel!
    @IBOutlet weak var postcode: UILabel!
    @IBOutlet weak var localisation: UILabel!
    @IBOutlet weak var country: UILabel!
    @IBOutlet weak var eventType: UILabel!
    @IBOutlet weak var eventLevel: UILabel!
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var className1: UILabel!
    @IBOutlet weak var eventImage: UIImageView!
    
    
    
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
        if let detailEvent = detailEvent {
            if #available(iOS 11.0, *) {
                navigationItem.largeTitleDisplayMode = .automatic
            } else {
                // Fallback on earlier versions
            }
            let rightBarButtonItems: [UIBarButtonItem]
            navigationController?.navigationItem.title = detailEvent.title.first?.value
            if userDefault.bool(forKey: "loginSuccessful") {
                rightBarButtonItems = [UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTapped))]
            } else {
                rightBarButtonItems = []
            }
            navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
            
            //print("Event name: \(detailEvent)")
        }
    }
    
    @objc func verifyID() {
        self.idField = self.idTextField.text!
        if idIsCorrect(id: self.idField) {
            self.view.endEditing(true)
            self.eventEditing = true
            // Upon verification -> Go to AddNewEventViewController with filled fields
            let storyboardSegue = UIStoryboardSegue(identifier: "AddNewEvent", source: EventDetailViewController(), destination: AddNewEventViewController())
            prepare(for: storyboardSegue, sender: okButton)
            popup.alpha = 0.0
        } else {
            popup.shake()
        }
    }
    
    @objc func cancelID() {
        self.view.endEditing(true)
        self.eventEditing = false
        UIView.animate(withDuration: 2.0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .curveLinear, animations: {
            self.popup.alpha = 0.0
        })
    }
    
    @objc func editTapped() {
        // popup to verify identification number
        self.eventEditing = true
        UIView.animate(withDuration: 2.0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.popup.alpha = 1.0
        })
    }
    
    func idIsCorrect(id: String) -> Bool {
        // fetch event id
        let idnumber = detailEvent?.idnumber
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
        if result!.value(forKey: key) == nil {
            // Re-request the taxonomy and try again
            if entity == "CoreEventTypes" {
                
            }
        }
        return result!.value(forKey: key) as! String
    }
    
    func setupLayout() {
        eventName.text = detailEvent?.title.first?.value
        if detailEvent?.eventtype.first != nil {
            eventType.text = getName("CoreEventTypes", Int((detailEvent?.eventtype.first?.id)!), "name")
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "segueToAddNewEvent":
            let controller = (segue.destination as! UINavigationController).topViewController as! AddNewEventViewController
            let event = detailEvent
            controller.detailEvent = event
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.navigationController?.title = "Edit event details"
            let rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))]
            controller.navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
            break
        default:
            break
        }
        
    }
    
    
    @objc func saveTapped() {
        if eventEditing {
            if AddNewEventViewController().verifyRequiredFields() {
                let storyboardSegue: UIStoryboardSegue = UIStoryboardSegue(identifier: "eventDetail", source: AddNewEventViewController(), destination: EventDetailViewController())
                unwind(for: storyboardSegue, towardsViewController: EventDetailViewController())
                // Patch changes to server
                print("patch to server")
            } else {
                print("Not all required fields have content")
            }
        } else {
            if AddNewEventViewController().requiredFields {
                // Post new event to server
                print("post to server")
            } else {
                print("Not all required fields for new event are filled.")
            }
        }
        // Update coreEvents
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

extension EventDetailViewController {
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
