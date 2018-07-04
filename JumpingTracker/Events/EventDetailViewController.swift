//
//  EventDetailViewController.swift
//  JumpingTracker
//
//  Created by Pieter Stragier on 17/06/2018.
//  Copyright © 2018 Pieter Stragier. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SwiftyJSON

class EventDetailViewController: UIViewController {
    
    // MARK: - Variables
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let userDefault = UserDefaults.standard
    let opQueue: OperationQueue = OperationQueue()
    var eventEditing: Bool = false
    var detailEvent: Events? {
        didSet {
            configureView()
        }
    }
    var idField: String = ""
    
    // MARK: - Outlets
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
    @IBOutlet weak var bodyLabel: UILabel!
    
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        adjustLargeTitleSize()
        setupPopupView()
        configureView()
        setupLayout()
        // Do any additional setup after loading the view.
        print("User organisator? \(isUserOrganisator())")

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        popup.alpha = 0.0
    }
    
    // MARK: - Layout
    func setupLayout() {
        eventName.text = detailEvent?.title.first?.value
        organisator.text = detailEvent?.organisator?.first?.value
        if detailEvent?.eventtype.first != nil {
            eventType.text = getName("CoreEventTypes", Int((detailEvent?.eventtype.first?.id)!), "name")
        }
        if detailEvent?.address?.first?.address_line1 != nil {
            streetName.text = detailEvent?.address?.first?.address_line1
        }
        if detailEvent?.address?.first?.locality != nil {
            localisation.text = detailEvent?.address?.first?.locality
        }
        if detailEvent?.address?.first?.postal_code != nil {
            postcode.text = detailEvent?.address?.first?.postal_code
        }
        if detailEvent?.address?.first?.country_code != nil {
            country.text = detailEvent?.address?.first?.country_code
        }
        if detailEvent?.body?.first != nil {
            bodyLabel.attributedText = detailEvent?.body?.first?.processed?.htmlToAttributedString
        }
        
        // Get logo from event or event creator (uid)
        if detailEvent?.logo?.first?.target_id != nil {
            let eventuid = detailEvent?.logo?.first?.target_id
            print("logo user id = \(eventuid!)")
            getLogoUrl(uid: eventuid!)
            // Request and load logo in the background
        }
        
        // url for poster comes with events REST
        if detailEvent?.poster?.first?.url != nil {
            self.eventImage.downloadedFrom(link: (detailEvent?.poster?.first?.url)!)
        }
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
                //navigationItem.largeTitleDisplayMode = .automatic
                navigationController?.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .never
            } else {
                // Fallback on earlier versions
            }
            let rightBarButtonItems: [UIBarButtonItem]
            navigationController?.navigationItem.title = detailEvent.title.first?.value
            if userDefault.bool(forKey: "loginSuccessful") && isUserOrganisator() {
                rightBarButtonItems = [UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTapped))]
            } else {
                rightBarButtonItems = []
            }
            navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
            let logo = UIImage(named: "jumping_horse")
            let imageView = UIImageView(image: logo!)
            self.navigationItem.titleView = imageView
            //print("Event name: \(detailEvent)")
        }
    }
    
    // MARK: - objc functions
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
    
    
    // MARK: - Additional functions
    func idIsCorrect(id: String) -> Bool {
        // fetch event id
        let idnumber = detailEvent?.idnumber
        if idnumber![0].value == id {
            return true
        }
        return false
    }
    
    func isUserOrganisator() -> Bool {
        let userID = self.userDefault.value(forKey: "UID") as? String
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoreCurrentUser")
        fetchRequest.predicate = NSPredicate(format: "organisationID == %@", userID!)
        var user: [CurrentUser] = []
        do {
            user = try self.appDelegate.getContext().fetch(fetchRequest) as! [CurrentUser]
        } catch {
            print("Could not fetch user")
        }
        
        if user.first?.organisationID != 0 {
            return true
        } else {
            return false
        }
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
    
    func getLogoUrl(uid: Int) {
        let logoRequestOperation = BlockOperation {
            print("request logo url...(\(uid))")
            Thread.printCurrent()
            let username = self.userDefault.value(forKey: "Username") as! String
            let password = self.getPasswordFromKeychain(username)
            let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            let headers = ["Authorization": "Basic \(base64Credentials)", "Accept": "application/json", "Content-Type": "application/json", "Cache-Control": "no-cache"]
            self.requestLogoURL(uid: uid, header: headers, completion: { (result) in
                DispatchQueue.main.async() {
                    print("logo result: \(result)")
                    self.eventLogo.downloadedFrom(link: result)
                }
            })
        }
        opQueue.addOperation(logoRequestOperation)
    }
    
    // MARK: get password from keychain
    func getPasswordFromKeychain(_ account: String) -> String {
        do {
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                                    account: account,
                                                    accessGroup: KeychainConfiguration.accessGroup)
            let keychainPassword = try passwordItem.readPassword()
            return keychainPassword
        } catch {
            //fatalError("Error reading password from keychain - \(error)")
            print("Error reading password from keychain - \(error)")
            return "blablabla"
        }
    }
    
    // MARK: - Data request functions
    func requestLogoURL(uid: Int, header: Dictionary<String, String>, completion: @escaping (String) -> ()) {
        print("logo request URL uid: \(uid)")
        let urlString = "https://jumpingtracker.com/rest/export/json/logos/\(uid)?_format=json"
        Alamofire.request(urlString, method: .get, encoding: JSONEncoding.default, headers: header)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON(completionHandler: { (response) in
                switch(response.result) {
                case .success(let value):
                    let swiftyJSON = JSON(value)
                    let logoURL = swiftyJSON[0]["field_organisation_logo"][0]["url"].stringValue
                    completion(logoURL)
                case .failure(let error):
                    print("logo failure with error: \(error)")
                }
            })
        
    }
    
    // MARK: - Prepare segue
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
    
    
    
}

// MARK: - Extensions
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

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
            let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
            let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
            let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                print("logo async image load")
                self.image = image
            }
        }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        print("logo downloading image: \(link)")
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
