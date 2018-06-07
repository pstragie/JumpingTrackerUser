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
        BGView.layer.cornerRadius = 5
        BGView.layer.masksToBounds = true
        BGView.backgroundColor = UIColor.white
        BGView.addBottomBorder(borderColor: UIColor.FlatColor.Blue.BlueWhale, borderWidth: 1.5)
        
        horseName.textColor = UIColor.FlatColor.Blue.BlueWhale
    }
    
}
extension UIView {
    func addBottomBorder(borderColor: UIColor, borderWidth: CGFloat) {
        let border = CALayer()
        border.backgroundColor = borderColor.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - borderWidth, width: self.frame.size.width, height: borderWidth)
    }
}
