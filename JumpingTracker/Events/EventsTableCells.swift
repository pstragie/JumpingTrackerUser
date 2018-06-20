//
//  EventsTableCells.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 29/05/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit

class EventsTableCell: UITableViewCell {
    
    // MARK: - Properties
    
    static let reuseIdentifier = "EventsTableCell"
    
    // MARK: -
    
    @IBOutlet weak var event: UILabel!
    @IBOutlet weak var organisation: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var hour: UILabel!
    @IBOutlet weak var locality: UILabel!
    @IBOutlet weak var country: UILabel!
    @IBOutlet weak var BGView: UIView!
    
    
    // MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        BGView.layer.cornerRadius = 5
        BGView.layer.masksToBounds = true
        BGView.layer.borderWidth = 1
        BGView.layer.borderColor = UIColor.FlatColor.Blue.Denim.cgColor
        BGView.backgroundColor = UIColor.FlatColor.Gray.WhiteSmoke
    }
    
}
