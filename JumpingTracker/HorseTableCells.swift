//
//  HorseTableCells.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 31/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit

class HorseTableCell: UITableViewCell {
    
    // MARK: - Properties
    
    static let reuseIdentifier = "HorseTableCell"
    
    // MARK: -
    
    @IBOutlet weak var BGView: UIView!
    @IBOutlet weak var horseName: UILabel!
    @IBOutlet weak var studbook: UILabel!
    @IBOutlet weak var horseOwner: UILabel!
    @IBOutlet weak var birthDay: UILabel!
    
    // MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        BGView.layer.cornerRadius = 10
        BGView.layer.masksToBounds = true
        BGView.layer.borderWidth = 1
        BGView.layer.borderColor = UIColor.FlatColor.Blue.Denim.cgColor
        BGView.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
    }
    
}

