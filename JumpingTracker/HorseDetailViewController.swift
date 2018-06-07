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
        adjustLargeTitleSize()
        configureView()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        if let detailHorse = detailHorse {
            if #available(iOS 11.0, *) {
                navigationItem.largeTitleDisplayMode = .automatic
            } else {
                // Fallback on earlier versions
            }
            
            navigationController?.navigationItem.title = detailHorse.name
            
            print("Horse name: \(detailHorse)")
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
