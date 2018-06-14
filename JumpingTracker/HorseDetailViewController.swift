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

    let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    var detailHorse: Horses? {
        didSet {
            configureView()
        }
    }
    
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
        configureView()
        setupLayout()
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
            
            navigationController?.navigationItem.title = detailHorse.name.first?.value
            
            print("Horse name: \(detailHorse)")
        }
    }

    func getName(_ entity: String, _ tid: Int, _ key: String) -> String {
        var result: NSManagedObject?
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.predicate = NSPredicate(format: "tid == %d", tid)
        do {
            let results = try context?.fetch(fetchRequest) as? [NSManagedObject]
            result = results?.first
        } catch {
            print("Could not fetch")
        }
        return result!.value(forKey: key) as! String
    }
    
    func setupLayout() {
        horseName.text = detailHorse?.name.first?.value
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
        fatherName.text = getName("CoreHorses", Int((detailHorse?.father?.first?.id)!), "name")
        motherName.text = getName("CoreHorses", Int((detailHorse?.mother?.first?.id)!), "name")
        ownerName.text = detailHorse?.owner?.first?.owner
        heightName.text = String((detailHorse?.height?.first?.value)!)
        
        birthName.text = getName("CoreJaartallen", Int((detailHorse?.birthday?.first?.id)!), "name")
        studRegName.text = detailHorse?.studreg?.first?.value
        coatColorName.text = ""
        
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
