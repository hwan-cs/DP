//
//  DetailViewController.swift
//  SplitBill
//
//  Created by Jung Hwan Park on 2021/11/04.
//

import Foundation
import UIKit
import Firebase
import DropDown
import FirebaseDynamicLinks
import FirebaseFirestore

class DetailViewController: UIViewController
{
    @IBOutlet var listOfParticipants: UILabel!
    @IBOutlet var participantsLabel: UILabel!
    @IBOutlet var separatorLine_1: UIView!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var dropDownView: UIView!
    @IBOutlet var textField: UITextField!
    @IBOutlet var button: UIButton!
    @IBOutlet var dateTextField: UITextField!
    @IBOutlet var selectDateButton: UIButton!
    @IBOutlet var selectDateDropDownView: UIView!
    @IBOutlet var inviteParticipantsButton: UIButton!
    @IBOutlet var priceTextField: UITextField!
    @IBOutlet var contentView: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentViewHeight: NSLayoutConstraint!
    @IBOutlet var contentViewWidth: NSLayoutConstraint!
    @IBOutlet var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet var inviteMessageLabel: UILabel!
    @IBOutlet var inviteView: UIView!
    @IBOutlet var inviteViewHeightConstraint: NSLayoutConstraint!
    
    let db = Firestore.firestore()
    var event: PaymentEvent?
    var didChange: PaymentEvent?
    //MARK: - Dropdown 1
    let dropDown = DropDown()
    let dropDownItems = ["월초","월말","사용자 지정"]
    var isOther: Bool = false
    var didMakeChange = false
    //MARK: - Dropdown 2
    let selectDateDropDown = DropDown()
    let selectDateDropDownItems = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"]
    
    var saveButtonView = UIView()
    var saveButton = UIButton()
    
    var currentUser = ""
    
    //MARK: - Share ViewController
    lazy private var shareController: UIActivityViewController =
    {
      let activities: [Any] = [
        "Join my DP event!",
        URL(string: "https://dpsubscription.page.link/invitation")!
      ]
      let controller = UIActivityViewController(activityItems: activities,
                                                applicationActivities: nil)
      return controller
    }()
    
    var invalidInvitation = false
    let KaturiMedium:UIFont = UIFont(name: "KaturiOTF", size: 20)!
    let KaturiLarge: UIFont = UIFont(name: "KaturiOTF", size: 24)!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.hideKeyboard()
        
        listOfParticipants.numberOfLines = 0
        button.setTitle("", for: .normal)
        selectDateButton.setTitle("", for: .normal)
        contentViewHeight.constant = UIScreen.main.bounds.height-150
        contentViewWidth.constant = UIScreen.main.bounds.width
        scrollViewWidth.constant = UIScreen.main.bounds.width
        
        self.inviteViewHeightConstraint.isActive = true
        
        //options dropdown initialization
        dropDown.anchorView = dropDownView
        dropDown.dataSource = dropDownItems
        //select date dropdown initialization
        selectDateDropDown.anchorView = selectDateDropDownView
        selectDateDropDown.dataSource = selectDateDropDownItems
        
        dateTextField.isUserInteractionEnabled = false
        dateTextField.backgroundColor = .gray
        dateTextField.attributedPlaceholder = NSAttributedString(
            string: "날짜를 선택하세요...",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
        )

        //customizing options dropdown
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
        dropDown.textColor = UIColor.black
        dropDown.selectedTextColor = UIColor.green
        dropDown.selectionBackgroundColor = UIColor.white
        dropDown.cornerRadius = 15
        //customizing select date dropdown
        selectDateDropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
        selectDateDropDown.textColor = UIColor.black
        selectDateDropDown.selectedTextColor = UIColor.green
        selectDateDropDown.selectionBackgroundColor = UIColor.white
        selectDateDropDown.cornerRadius = 15
        selectDateDropDown.direction = .bottom
        
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            textField.placeholder = item
            if item == "사용자 지정"
            {
                dateTextField.backgroundColor = .white
                dateTextField.attributedPlaceholder = NSAttributedString(
                    string: "날짜를 선택하세요...",
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]
                )
                isOther = true
            }
            else
            {
                dateTextField.backgroundColor = .gray
                dateTextField.attributedPlaceholder = NSAttributedString(
                    string: "날짜를 선택하세요...",
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
                )
                isOther = false
            }
        }
        selectDateDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            dateTextField.placeholder = item
        }
    }

    //MARK: - Get current user depending on appleid or googleid
    func getCurrentUser(completion: @escaping (_ result: String) -> Void)
    {
        currentUser = Auth.auth().currentUser?.email as! String
        db.collection("appleID").whereField("email", isNotEqualTo: false).getDocuments
        { querySnapShot, error in
            if let e = error
            {
                print("There was an issue retrieving data from Firestore \(e)")
            }
            else
            {
                if let snapshotDocuments = querySnapShot?.documents
                {
                    for doc in snapshotDocuments
                    {
                        let data = doc.data()
                        if (data["email"] as! String) == Auth.auth().currentUser?.email
                        {
                            self.currentUser = data["name"] as! String
                        }
                    }
                }
            }
            completion(self.currentUser)
        }
    }
    
    //MARK: - Load from invitation, check if invitation is valid or not
    func loadFromInvitation(completion: @escaping (_ success: Bool) -> Void)
    {
        print("loadfrominvitation")
        var found = false
        db.collection("events").whereField("eventName", isNotEqualTo: false).getDocuments { querySnapshot, err in
            if let err = err
            {
                print("error getting documents! \(err)")
            }
            else
            {
                for doc in querySnapshot!.documents
                {
                    let data = doc.data()
                    if doc.documentID == self.event?.FIRDocID
                    {
                        found = true
                        if let eventName = data["eventName"] as? String, let price = data["price"] as? Double, var participants = data["participants"] as? [String]
                            , let owner = data["owner"] as? String, let eventDate = data["eventDate"] as? String, let dateCreated = data["dateCreated"] as? Double
                            , let FIRDocID = self.event?.FIRDocID as? String
                        {
                            if !participants.contains(self.currentUser)
                            {
                                participants.append(self.currentUser)
                                doc.reference.updateData(["participants" : participants])
                            }
                            self.event = PaymentEvent(FIRDocID: FIRDocID, eventName: eventName, dateCreated: dateCreated, participants: participants, price: price, eventDate: eventDate, isOwner: owner == self.currentUser)
                            print(self.event)
                            PaymentEvent.didChange = true
                            completion(true)
                        }
                    }
                }
            }
            if found == false
            {
                completion(false)
            }
        }
    }
    
    //MARK: - Alert for if the invitation event no longer exists
    func showAlert(completion: @escaping (_ success: Bool) -> Void)
    {
        let alert = UIAlertController(title: "더이상 존재하지 않는 이벤트 입니다!", message: "", preferredStyle: .alert)
        let imageView = UIImageView(frame: CGRect(x: 65, y: 70, width: 75, height: 70))
        imageView.image = UIImage(systemName: "xmark.octagon.fill")
        alert.view.addSubview(imageView)
        let height = NSLayoutConstraint(item: alert.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150)
        let width = NSLayoutConstraint(item: alert.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200)
        alert.view.addConstraint(height)
        alert.view.addConstraint(width)
        self.present(alert, animated: true, completion: nil)
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in alert.dismiss(animated: true) {
            completion(true)
        }} )
    }
    
    //MARK: - Save button IBAction
    @objc func saveButtonPressed(_ sender: UIButton)
    {
        let alert = UIAlertController(title: "저장하시겠습니까?", message: "한번 저장하면 다시 날짜를 바꿀 수 없습니다.", preferredStyle: .alert)
        let action = UIAlertAction(title: "예", style: .default)
        { (action) in
            self.db.collection("events").whereField("owner", isEqualTo: self.currentUser).getDocuments
            { querySnapshot, err in
                if let err = err
                {
                    print("error getting documents! \(err)")
                }
                else
                {
                    for document in querySnapshot!.documents
                    {
                        if document.documentID == self.event?.FIRDocID
                        {
                            if self.priceTextField.text!.isDouble == true
                            {
                                if document.data()["price"] as? Double != Double(self.priceTextField.text!)
                                {
                                    document.reference.updateData(["price" : Double(self.priceTextField.text!)])
                                }
                            }
                            if self.textField.placeholder! == "월초"
                            {
                                if document.data()["eventDate"] as? String != "SOM"
                                {
                                    document.reference.updateData(["eventDate" : "SOM"])
                                }
                            }
                            else if self.textField.placeholder! == "월말"
                            {
                                if document.data()["eventDate"] as? String != "EOM"
                                {
                                    document.reference.updateData(["eventDate" : "EOM"])
                                }
                            }
                            else if self.textField.placeholder! == "사용자 지정"
                            {
                                if document.data()["eventDate"] as? String != self.dateTextField.placeholder!
                                {
                                    document.reference.updateData(["eventDate" : self.dateTextField.placeholder!])
                                }
                            }
                        }
                    }
                    if self.textField.placeholder! != "날짜를 설정하세요"
                    {
                        self.dropDownView.isUserInteractionEnabled = false
                        self.textField.backgroundColor = .gray
                        self.textField.attributedPlaceholder = NSAttributedString(
                            string: self.textField.placeholder!,
                            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
                        )
                        self.selectDateDropDownView.isUserInteractionEnabled = false
                        self.dateTextField.backgroundColor = .gray
                        self.dateTextField.attributedPlaceholder = NSAttributedString(
                            string: self.dateTextField.placeholder!,
                            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
                        )
       
                        self.saveButtonView.removeFromSuperview()
                        self.saveButton.removeFromSuperview()
                    }
                }
            }
        }
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: "아니오", style: .cancel, handler: { (action: UIAlertAction!) in
              print("Alert dismissed")
        }))
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool)
    {
        let isDarkOn = UserDefaults.standard.bool(forKey: "prefs_is_dark_mode_on")
        contentView.backgroundColor = isDarkOn ? UIColor.black : UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.00)
        inviteView.backgroundColor = isDarkOn ? UIColor.black : UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.00)
        view.backgroundColor = isDarkOn ? UIColor.black : UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.00)
        let color = isDarkOn ? UIColor.white : UIColor.black
        if event?.eventName == ""
        {
            getCurrentUser { result in
                print("currentUser: \(self.currentUser)")
                self.loadFromInvitation { success in
                    if success
                    {
                        self.title = self.event!.eventName
                        var tempList = ""
                        let participantsArray = self.event!.participants
                        for (index, people) in participantsArray.enumerated()
                        {
                            if index == 1
                            {
                                tempList.append("\n\(people)\n")
                            }
                            else if index > 1 && index != participantsArray.count-1
                            {
                                tempList.append("\(people)\n")
                            }
                            else if index > 1 && index == participantsArray.count-1
                            {
                                tempList.append("\(people)")
                            }
                        }
                        let labelText = NSMutableAttributedString()
                        let ownerText = NSAttributedString(string: "\(self.event!.participants[0])", attributes: [ .font: self.KaturiMedium, .foregroundColor: UIColor(red: 0.31, green: 0.62, blue: 0.24, alpha: 1.00) ])
                        let participantText = NSAttributedString(string: tempList, attributes: [ .font: self.KaturiMedium, .foregroundColor: color ])
                        labelText.append(ownerText)
                        labelText.append(participantText)
                        self.listOfParticipants.attributedText = labelText
                        self.didChange = self.event
                        self.initView(self.event!.isOwner)
                    }
                    else
                    {
                        var background = UIView(frame: UIScreen.main.bounds)
                        background.backgroundColor = .black
                        background.alpha = 0.66
                        self.view.addSubview(background)
                        self.view.isUserInteractionEnabled = false
                        self.showAlert
                        { success in
                            self.invalidInvitation = true
                            self.performSegue(withIdentifier: "unwindToTableView", sender: self)
                        }
                    }
                }
            }
        }
        else
        {
            self.currentUser = self.event?.participants[0] as! String
            self.title = self.event!.eventName
            var tempList = ""
            let participantsArray = self.event!.participants
            for (index, people) in participantsArray.enumerated()
            {
                if index == 1
                {
                    tempList.append("\n\(people)\n")
                }
                else if index > 1 && index != participantsArray.count-1
                {
                    tempList.append("\(people)\n")
                }
                else if index > 1 && index == participantsArray.count-1
                {
                    tempList.append("\(people)")
                }
            }
            let labelText = NSMutableAttributedString()
            let ownerText = NSAttributedString(string: "\(self.event!.participants[0])", attributes: [ .font: self.KaturiMedium, .foregroundColor: UIColor(red: 0.31, green: 0.62, blue: 0.24, alpha: 1.00) ])
            let participantText = NSAttributedString(string: tempList, attributes: [ .font: self.KaturiMedium, .foregroundColor: color ])
            labelText.append(ownerText)
            labelText.append(participantText)
            self.listOfParticipants.attributedText = labelText
            self.didChange = self.event
            self.initView(self.event!.isOwner)
        }
    }
    
    //MARK: - viewWillDisappear, save changes to event if change has been made
    override func viewWillDisappear(_ animated: Bool)
    {
        if invalidInvitation == true
        {
            return
        }
        var price = self.event!.price
        if self.priceTextField.text!.isDouble == true
        {
            price = Double(self.priceTextField.text!)!
        }

        if self.textField.placeholder! == "월초"
        {
            self.didChange = PaymentEvent(FIRDocID: self.event!.FIRDocID, eventName: self.event!.eventName, dateCreated: self.event!.dateCreated, participants: self.event!.participants, price: price, eventDate: "SOM", isOwner: self.event!.isOwner)
        }
        else if self.textField.placeholder! == "월말"
        {
            self.didChange = PaymentEvent(FIRDocID: self.event!.FIRDocID, eventName: self.event!.eventName, dateCreated: self.event!.dateCreated, participants: self.event!.participants, price: price, eventDate: "EOM", isOwner: self.event!.isOwner)
        }
        else if self.textField.placeholder! == "사용자 지정"
        {
            self.didChange = PaymentEvent(FIRDocID: self.event!.FIRDocID, eventName: self.event!.eventName, dateCreated: self.event!.dateCreated, participants: self.event!.participants, price: price, eventDate: self.dateTextField.placeholder!, isOwner: self.event!.isOwner)
        }
        if self.didChange != self.event
        {
            PaymentEvent.didChange = true
        }
        db.collection("events").whereField("owner", isEqualTo: currentUser).getDocuments
        { querySnapshot, err in
            if let err = err
            {
                print("error getting documents! \(err)")
            }
            else
            {
                for document in querySnapshot!.documents
                {
                    if document.documentID == self.event?.FIRDocID
                    {
                        if self.priceTextField.text!.isDouble == true
                        {
                            if document.data()["price"] as? Double != Double(self.priceTextField.text!)
                            {
                                document.reference.updateData(["price" : Double(self.priceTextField.text!)])
                            }
                        }
                    }
                }
            }
        }
        self.saveButtonView.removeFromSuperview()
        self.saveButton.removeFromSuperview()
    }
    override func viewDidDisappear(_ animated: Bool)
    {
        self.saveButtonView.removeFromSuperview()
        self.saveButton.removeFromSuperview()
    }
    
    //MARK: - Initialize view
    func initView(_ isOwner: Bool)
    {
        if event?.eventName != "" && event?.eventDate == "" && event?.isOwner == true
        {
            saveButtonView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height-(self.tabBarController?.tabBar.frame.size.height)!, width: UIScreen.main.bounds.width, height: (self.tabBarController?.tabBar.frame.size.height)!)
            saveButtonView.backgroundColor = UIColor(red: 0.31, green: 0.62, blue: 0.24, alpha: 1.00)
            saveButton.frame = CGRect(x: 0, y: UIScreen.main.bounds.height-(self.tabBarController?.tabBar.frame.size.height)!-10, width: UIScreen.main.bounds.width, height: (self.tabBarController?.tabBar.frame.size.height)!)
            saveButton.setAttributedTitle( NSAttributedString(string: "저장하기", attributes: [ .font: self.KaturiMedium, .foregroundColor: UIColor.black ]), for: .normal)
            saveButton.setAttributedTitle( NSAttributedString(string: "저장하기", attributes: [ .font: self.KaturiMedium, .foregroundColor: UIColor.blue ]), for: .selected)
            saveButton.addTarget(self, action: #selector(saveButtonPressed(_:)), for: .touchUpInside)
            
            self.tabBarController?.view.addSubview(saveButtonView)
            self.tabBarController?.view.bringSubviewToFront(saveButtonView)
            self.tabBarController?.view.addSubview(saveButton)
            self.tabBarController?.view.bringSubviewToFront(saveButton)
        }
        let isDarkOn = UserDefaults.standard.bool(forKey: "prefs_is_dark_mode_on")
        if #available(iOS 13.0, *)
        {
            overrideUserInterfaceStyle = isDarkOn ? .dark : .light
        }
        else
        {
            view.backgroundColor = isDarkOn ? UIColor.black : UIColor.white
        }
        
        var str: String?
        if self.event?.eventDate == "SOM"
        {
            str = dropDownItems[0]
            dropDown.selectRow(at: 0)
        }
        else if self.event?.eventDate == "EOM"
        {
            str = dropDownItems[1]
            dropDown.selectRow(at: 1)
        }
        else if self.event?.eventDate == ""
        {
            str = "날짜를 설정하세요"
        }
        else
        {
            str = dropDownItems[2]
            dropDown.selectRow(at: 2)
        }
        if isOwner == false
        {
            self.inviteMessageLabel.isHidden = true
            self.inviteParticipantsButton.isHidden = true
            self.inviteView.isHidden = true
            self.inviteViewHeightConstraint.constant = 0

            self.priceTextField.isUserInteractionEnabled = false
            self.priceTextField.backgroundColor = .gray
            self.priceTextField.attributedPlaceholder = NSAttributedString(
                string: String(self.event?.price ?? 0.0),
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
            )
            self.dropDownView.isUserInteractionEnabled = false
            self.textField.backgroundColor = .gray
            self.textField.attributedPlaceholder = NSAttributedString(
                string: str!,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
            )
            if str! == dropDownItems[2]
            {
                dateTextField.backgroundColor = .gray
                dateTextField.attributedPlaceholder = NSAttributedString(
                    string: self.event?.eventDate ?? "",
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
                )
                isOther = true
                selectDateDropDown.selectRow(at: Int(self.event!.eventDate)!-1)
                selectDateDropDownView.isUserInteractionEnabled = false
            }
        }
        else if isOwner == true && self.event?.eventDate != ""
        {
            self.inviteMessageLabel.isHidden = false
            if isDarkOn == true
            {
                self.inviteParticipantsButton.backgroundColor = .white
                self.inviteParticipantsButton.setTitleColor(.black, for: .normal)
                self.inviteMessageLabel.textColor = UIColor.white
            }
            else
            {
                self.inviteParticipantsButton.backgroundColor = .black
                self.inviteParticipantsButton.setTitleColor(.white, for: .normal)
                self.inviteMessageLabel.textColor = UIColor.black
            }
            self.inviteParticipantsButton.setTitleColor(.blue, for: .selected)
            self.inviteParticipantsButton.layer.cornerRadius = 10
            self.inviteViewHeightConstraint.constant = 88
            
            self.inviteParticipantsButton.isHidden = false
            self.priceTextField.backgroundColor = .white
            self.priceTextField.attributedPlaceholder = NSAttributedString(
                string: String(self.event?.price ?? 0.0),
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]
            )
            self.dropDownView.isUserInteractionEnabled = false
            self.textField.backgroundColor = .gray
            self.textField.attributedPlaceholder = NSAttributedString(
                string: str!,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
            )
            if str! == dropDownItems[2]
            {
                dateTextField.backgroundColor = .gray
                dateTextField.attributedPlaceholder = NSAttributedString(
                    string: self.event?.eventDate ?? "",
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
                )
                isOther = true
                selectDateDropDown.selectRow(at: Int(self.event!.eventDate)!-1)
                selectDateDropDownView.isUserInteractionEnabled = false
            }
        }
        else
        {
            self.inviteMessageLabel.isHidden = false
            if isDarkOn == true
            {
                self.inviteParticipantsButton.backgroundColor = .white
                self.inviteParticipantsButton.setTitleColor(.black, for: .normal)
                self.inviteMessageLabel.textColor = UIColor.white
            }
            else
            {
                self.inviteParticipantsButton.backgroundColor = .black
                self.inviteParticipantsButton.setTitleColor(.white, for: .normal)
                self.inviteMessageLabel.textColor = UIColor.black
            }
            self.inviteParticipantsButton.setTitleColor(.blue, for: .selected)
            self.inviteParticipantsButton.layer.cornerRadius = 10
            self.inviteViewHeightConstraint.constant = 88
            
            self.inviteParticipantsButton.isHidden = false
            
            self.priceTextField.backgroundColor = .white
            self.priceTextField.attributedPlaceholder = NSAttributedString(
                string: String(self.event?.price ?? 0.0),
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]
            )
            self.textField.backgroundColor = .white
            self.textField.attributedPlaceholder = NSAttributedString(
                string: str!,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]
            )
            if str! == dropDownItems[2]
            {
                dateTextField.backgroundColor = .white
                dateTextField.attributedPlaceholder = NSAttributedString(
                    string: self.event?.eventDate ?? "",
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]
                )
                isOther = true
                selectDateDropDown.selectRow(at: Int(self.event!.eventDate)!-1)
            }
        }
        if #available(iOS 13.0, *)
        {
            self.priceTextField.overrideUserInterfaceStyle = .light
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
          self.view.endEditing(true)
    }
    //MARK: - show dropdown list
    @IBAction func showDropDown(_ sender: UIButton)
    {
        dropDown.show()
    }
    @IBAction func showSelectDateDropDown(_ sender: UIButton)
    {
        if isOther
        {
            selectDateDropDown.show()
        }
    }
    
    //MARK: - Invite button IBAction
    @IBAction func sendInvitation(_ sender: UIButton)
    {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.example.com"
        components.path = "/events"
        
        let eventIDQueryItem = URLQueryItem(name: "FIRDocID", value: event?.FIRDocID)
        components.queryItems = [eventIDQueryItem]
        
        guard let linkParameter = components.url else { return }
        print("I am sharing \(linkParameter.absoluteString)")
        
        //create the big dynamic link
        guard let shareLink = DynamicLinkComponents.init(link: linkParameter, domainURIPrefix: "https://dpsubscription.page.link")
        else
        {
            print("couldn't create FDL components")
            return
        }
        
        if let myBundleID = Bundle.main.bundleIdentifier
        {
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: myBundleID)
        }
        
        //temporary appstore id
        shareLink.iOSParameters?.appStoreID = "320606217"
        shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        shareLink.socialMetaTagParameters?.title = "\(event!.eventName) from DP"
        shareLink.socialMetaTagParameters?.descriptionText = "Manage your subscriptions with DP!"
        shareLink.socialMetaTagParameters?.imageURL = URL(string: "https://www.louisianafcu.org/hs-fs/hubfs/Blog_The%20polite%20persons%20guide%20to%20splitting%20the%20bill%20(2).png?width=640&name=Blog_The%20polite%20persons%20guide%20to%20splitting%20the%20bill%20(2).png")
        
        guard let longURL = shareLink.url else { return }
        
        print("long dynamic link url is \(longURL.absoluteString)")
        
        shareLink.shorten { url, warnings, error in
            if let error = error
            {
                print("An error has occured! \(error)")
                return
            }
            if let warnings = warnings
            {
                for warning in warnings
                {
                    print("FDL warning: \(warning)")
                }
            }
            guard let url = url else { return }
            print("I have a short url to share! \(url.absoluteString)")
            
            let promoText = "같이 \(self.event!.eventName) 더치페이 해요!"
            let controller = UIActivityViewController(activityItems: [promoText, url],
                                                      applicationActivities: nil)
            if let popoverController = controller.popoverPresentationController {
                popoverController.sourceView = sender
                popoverController.sourceRect = sender.bounds
            }
            self.present(controller, animated: true)
        }
    }
    //MARK: - Dynamic Links
    func generateContentLink() -> URL
    {
        let baseURL = URL(string: "https://dpsubscription.page.link")!
        let domain = "https://dpsubscription.page.link"
        let linkBuilder = DynamicLinkComponents(link: baseURL, domainURIPrefix: domain)
        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "konkuk.jhpark.SplitBill")
        linkBuilder?.androidParameters = DynamicLinkAndroidParameters(packageName: "SplitBill")
        // Fall back to the base url if we can't generate a dynamic link.
        return linkBuilder?.link ?? baseURL
    }
}
extension UIViewController
{
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
}
extension String
{
    var isDouble: Bool
    {
        guard self.count > 0 else { return false }
        if self.components(separatedBy: ".").count > 1 { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }
}
