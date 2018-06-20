//
//  AddNewEventViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 18/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit

class AddNewEventViewController: UIViewController {

    var detailEvent: Events? {
        didSet {
            configureView()
        }
    }
    var requiredFields: Bool = false
    
    @IBOutlet weak var eventNameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        if let detailEvent = detailEvent {
            if #available(iOS 11.0, *) {
                navigationItem.largeTitleDisplayMode = .never
            } else {
                // Fallback on earlier versions
            }
            
            print("Event name: \(detailEvent)")
        }
    }
    
    func verifyRequiredFields() -> Bool {
        guard
            let eventname = eventNameField.text, !eventname.isEmpty
            //let identification = identificationField.text, !identification.isEmpty,
            //let father = fatherField.text, !father.isEmpty,
            //let mother = motherField.text, !mother.isEmpty,
            //let birth = birthYearField.text, !birth.isEmpty
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
