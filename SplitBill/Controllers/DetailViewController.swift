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
    
    let db = Firestore.firestore()
    var event: PaymentEvent?
    //MARK: - Dropdown 1
    let dropDown = DropDown()
    let dropDownItems = ["월초","월말","사용자 지정"]
    var isOther: Bool = false
    var didMakeChange = false
    //MARK: - Dropdown 2
    let selectDateDropDown = DropDown()
    let selectDateDropDownItems = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"]
    
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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        self.hideKeyboard()
        listOfParticipants.numberOfLines = 0
        button.setTitle("", for: .normal)
        selectDateButton.setTitle("", for: .normal)
        contentViewHeight.constant = UIScreen.main.bounds.height-150
        contentViewWidth.constant = UIScreen.main.bounds.width
        scrollViewWidth.constant = UIScreen.main.bounds.width
//        inviteParticipantsViewWidth.constant = UIScreen.main.bounds.width
        
        //options dropdown initialization
        dropDown.anchorView = dropDownView
        dropDown.dataSource = dropDownItems
        //select date dropdown initialization
        selectDateDropDown.anchorView = selectDateDropDownView
        selectDateDropDown.dataSource = selectDateDropDownItems
        
//        textField.placeholder = "Select date of payment..."
//        textField.isUserInteractionEnabled = false
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
//        dropDown.textFont = UIFont(name: "Apple Color Emoji", size: 14.0) ?? UIFont.systemFont(ofSize: 14)
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
    func loadFromInvitation(completion: @escaping (_ success: Bool) -> Void)
    {
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
                        if let eventName = data["eventName"] as? String, let price = data["price"] as? Double, var participants = data["participants"] as? [String]
                            , let owner = data["owner"] as? String, let eventDate = data["eventDate"] as? String, let dateCreated = data["dateCreated"] as? Double
                            , let FIRDocID = self.event?.FIRDocID as? String
                        {
                            if !participants.contains(Auth.auth().currentUser?.email! ?? "")
                            {
                                participants.append(Auth.auth().currentUser?.email! ?? "")
                                doc.reference.updateData(["participants" : participants])
                            }
                            self.event = PaymentEvent(FIRDocID: FIRDocID, eventName: eventName, dateCreated: dateCreated, participants: participants, price: price, eventDate: eventDate, isOwner: owner == Auth.auth().currentUser?.email)
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        if event?.eventName == ""
        {
            loadFromInvitation { success in
                if success
                {
                    self.title = self.event!.eventName
                    var tempList = ""
                    let participantsArray = self.event!.participants
                    for people in participantsArray
                    {
                        if participantsArray.count == 1
                        {
                            tempList.append("\(people)")
                        }
                        else
                        {
                            tempList.append("\(people)\n")
                        }
                    }
                    self.listOfParticipants.text = tempList
                    self.initView(self.event!.isOwner)
                }
            }
        }
        else
        {
            self.title = self.event!.eventName
            var tempList = ""
            let participantsArray = self.event!.participants
            for people in participantsArray
            {
                if participantsArray.count == 1
                {
                    tempList.append("\(people)")
                }
                else
                {
                    tempList.append("\(people)\n")
                }
            }
            self.listOfParticipants.text = tempList
            self.initView(self.event!.isOwner)
        }
        AppUtility.lockOrientation(.portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        db.collection("events").whereField("owner", isEqualTo: Auth.auth().currentUser?.email).getDocuments
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
                                self.didMakeChange = true
                                document.reference.updateData(["price" : Double(self.priceTextField.text!)])
                            }
                        }
                        if self.textField.placeholder! == "월초"
                        {
                            if document.data()["eventDate"] as? String != "SOM"
                            {
                                self.didMakeChange = true
                                document.reference.updateData(["eventDate" : "SOM"])
                            }
                        }
                        else if self.textField.placeholder! == "월말"
                        {
                            if document.data()["eventDate"] as? String != "EOM"
                            {
                                self.didMakeChange = true
                                document.reference.updateData(["eventDate" : "EOM"])
                            }
                        }
                        else if self.textField.placeholder! == "사용자 지정"
                        {
                            if document.data()["eventDate"] as? String != "self.dateTextField.placeholder!"
                            {
                                self.didMakeChange = true
                                document.reference.updateData(["eventDate" : self.dateTextField.placeholder!])
                            }
                        }
                    }
                }
            }
        }
        var CVC: CategoryViewController?
        CVC?.didLoadAfterChange = false
        AppUtility.lockOrientation(.all)
    }
    
    func initView(_ isOwner: Bool)
    {
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
            self.inviteParticipantsButton.isHidden = true
            self.view.backgroundColor = .white
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
        else
        {
            self.inviteParticipantsButton.isHidden = false
            self.view.backgroundColor = .lightGray
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
        shareLink.socialMetaTagParameters?.imageURL = URL(string: "https://www.streamscheme.com/wp-content/uploads/2020/04/pepega.png")
        
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
            
            let promoText = "Join me in my DP event, \(self.event!.eventName)"
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
