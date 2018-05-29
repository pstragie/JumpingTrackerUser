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
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var BGView: UIView!
    
    
    // MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        BGView.layer.cornerRadius = 10
        BGView.layer.borderWidth = 1
        BGView.layer.borderColor = UIColor.darkGray.cgColor
    }
    
}
