//
//  HorseDetailViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 05/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit

class HorseDetailViewController: UIViewController {

    var detailHorse: Horse? {
        didSet {
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        if let detailHorse = detailHorse {
            navigationController?.navigationItem.title = detailHorse.name
            print("... later...: \(detailHorse)")
        }
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
