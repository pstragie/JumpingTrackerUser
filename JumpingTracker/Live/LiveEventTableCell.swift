//
//  LiveEventTableCell.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 04/07/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import Foundation
import UIKit

class LiveEventTableCell: UITableViewCell {
    
    // MARK: - Properties
    
    static let reuseIdentifier = "LiveEventTableCell"
    
    // MARK: -
    @IBOutlet weak var startPosition: UILabel!
    @IBOutlet weak var horseName: UILabel!
    @IBOutlet weak var equestrianName: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var penalty: UILabel!
    @IBOutlet weak var currentPosition: UILabel!
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
