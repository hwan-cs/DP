//
//  CategoryViewController.swift
//  DP
//
//  Created by Jung Hwan Park on 2021/11/04.

import UIKit
import AuthenticationServices
import GoogleSignIn
import Firebase
import SwiftUI
import FirebaseFirestore
import SwipeCellKit

class MySwipeCell:SwipeTableViewCell, SwipeTableViewCellDelegate
{
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
//            // handle action by updating model with deletion
            self.updateModel(at: indexPath)
        }

        // customize the action appearance
        deleteAction.image = UIImage(named: "delete")
        return [deleteAction]
    }
    func updateModel(at indexPath: IndexPath)
    {
        //update our data model
        
    }
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .destructive
        return options
    }
    @IBOutlet weak var cellTitleLabel: UILabel!
    @IBOutlet var cellTitleLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var cellSecondaryTextLabel: UILabel!
    @IBOutlet var cellSecondaryTextLabelWidthConstraint: NSLayoutConstraint!
}

class CategoryViewController: SwipeTableViewController
{
//    let realm = try! Realm()
    var paymentArray: [PaymentEvent] = []
    var participantEventArray: [PaymentEvent] = []
//    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let db = Firestore.firestore()
    var manager = LocalNotificationManager()
    var currentUser = ""
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.rowHeight = 80
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        self.navigationController?.navigationBar.topItem?.title = "ㄷㅍ"
        self.tabBarController?.tabBar.items?[0].title = "홈"
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        print("viewwillappear")

        let isDarkOn = UserDefaults.standard.bool(forKey: "prefs_is_dark_mode_on")
        view.backgroundColor = isDarkOn ? UIColor.black : UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.00)
        if #available(iOS 13.0, *)
        {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor(red: 0.31, green: 0.62, blue: 0.24, alpha: 1.00)
            appearance.titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
            self.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
            self.navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor.white
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        else
        {
           navigationController?.navigationBar.barTintColor = .systemGreen
        }
        let selectedRow: IndexPath? = tableView.indexPathForSelectedRow
        if let selectedRowNotNill = selectedRow
        {
            tableView.deselectRow(at: selectedRowNotNill, animated: true)
        }
        getCurrentUser { result in
            print("got back \(self.currentUser)")
            self.view.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now()+0.1)
            {
                self.loadEvents
                { success in
                    self.view.isUserInteractionEnabled = true
                }
            }
        }
        
        tableView.reloadData()
    }
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem)
    {
        var textField = UITextField()

        let alert = UIAlertController(title: "새로운 더치페이 이벤트", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "추가", style: .default) { (action) in
            //what will be happening once the user clicks the Add Item button on our UIAlert
            if  let event = textField.text, let userEmail = self.currentUser as? String, let currentTime = Date().timeIntervalSince1970 as? Double
            {
                let ref = self.db.collection("events").document()
                ref.setData(["dateCreated": currentTime, "eventDate":"", "eventName": event, "owner":userEmail,"participants":[userEmail],"price":0])
                { error in
                    if let e = error
                        {
                            print("There was an issue sending data to Firestore: \(e)")
                        }
                        else
                        {
                            print("Successfully saved data.")
                        }
                }
                self.paymentArray.append(PaymentEvent(FIRDocID: ref.documentID, eventName: event, dateCreated: currentTime, participants: [userEmail], price: 0, eventDate: "", isOwner: true))
            }
            self.tableView.reloadData()
        }
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "이벤트 이름을 입력하세요..."
            textField = alertTextField
        }
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { (action: UIAlertAction!) in
              print("Alert dismissed")
        }))
        present(alert, animated: true, completion: nil)
    }
    @objc func dismissOnTapOutside()
    {
       self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signOutButtonPressed(_ sender: UIBarButtonItem)
    {
        PaymentEvent.didChange = true
        KeychainItem.deleteUserIdentifierFromKeychain()
        // Display the login controller again.
        DispatchQueue.main.async
        {
            GIDSignIn.sharedInstance.signOut()
            let firebaseAuth = Auth.auth()
            do
            {
                try firebaseAuth.signOut()
            }
            catch let signOutError as NSError
            {
                print("Error signing out: %@", signOutError)
            }
            self.showLoginViewController()
        }
    }
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
                            DispatchQueue.main.async
                            {
                                self.currentUser = data["name"] as! String
                                completion(self.currentUser)
                            }
                        }
                    }
                }
            }
        }
        completion(self.currentUser)
    }
    func loadEvents(completion: @escaping (_ success: Bool) -> Void)
    {
        //date formatter
        let dateFormatter = DateFormatter()
        let date = Date()
        dateFormatter.dateFormat = "dd"
        
        //start of the month
        let SOM: DateComponents = Calendar.current.dateComponents([.year, .month], from: date)
        let startOfMonth = Calendar.current.date(from: SOM)!
        print(dateFormatter.string(from: startOfMonth))
        
        //end of the month
        var EOM = DateComponents()
        EOM.month = 1
        EOM.day = -1
        let endOfMonth = Calendar.current.date(byAdding: EOM, to: startOfMonth)
        print(dateFormatter.string(from: endOfMonth!))
        print(PaymentEvent.didChange)
        if PaymentEvent.didChange == false && Notification.pushNotificationOn == true
        {
            completion(true)
            return
        }
            
        print("currentuser: ", currentUser)
        db.collection("events").whereField("eventName", isNotEqualTo: false).getDocuments
        { [self] querySnapShot, error in
            self.paymentArray = []
            self.participantEventArray = []
            self.manager.notifications.removeAll()
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
                        if (data["participants"] as! [String]).contains(self.currentUser ?? "nil")
                        {
                            if let eventName = data["eventName"] as? String, let price = data["price"] as? Double, let participants = data["participants"] as? [String]
                                , let owner = data["owner"] as? String, let eventDate = data["eventDate"] as? String, let dateCreated = data["dateCreated"] as? Double
                                , let FIRDocID = doc.documentID as? String
                            {
                                let newEvent = PaymentEvent(FIRDocID: FIRDocID, eventName: eventName, dateCreated: dateCreated, participants: participants, price: price, eventDate: eventDate, isOwner: owner == self.currentUser)
                                if newEvent.isOwner == true
                                {
                                    self.paymentArray.append(newEvent)
                                }
                                else
                                {
                                    self.participantEventArray.append(newEvent)
                                }
                                
                                if Notification.pushNotificationOn == true
                                {
                                    let SOMNotificationOwner = Notification(id: FIRDocID, title: "DP 정산 알림", body: "오늘 \(eventName) 구독권으로 \(Int(price))원이 지불됩니다!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(dateFormatter.string(from: startOfMonth)), hour: 12, minute: 0))

                                    let EOMNotificationOwner = Notification(id: FIRDocID, title: "DP 정산 알림", body: "오늘 \(eventName) 구독권으로 \(Int(price))원이 지불됩니다!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(dateFormatter.string(from: endOfMonth!)), hour: 12, minute: 0))

                                    let SDMNotificationOwner = Notification(id: FIRDocID, title: "DP 정산 알림", body: "오늘 \(eventName) 구독권으로 \(Int(price))원이 지불됩니다!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(eventDate), hour: 12, minute: 0))

                                    let SOMNotificationParticipants = Notification(id: FIRDocID, title: "DP 정산 알림", body: "\(eventName) 구독권 정산날이에요!🙂 \(owner)님에게 \(Int(price/Double(participants.count)))원을 보내주세요!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(dateFormatter.string(from: startOfMonth)), hour: 12, minute: 0))

                                    let EOMNotificationParticipants = Notification(id: FIRDocID, title: "DP 정산 알림", body: "\(eventName) 구독권 정산날이에요!🙂 \(owner)님에게 \(Int(price/Double(participants.count)))원을 보내주세요!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(dateFormatter.string(from: endOfMonth!)), hour: 12, minute: 0))

                                    let SDMNotificationParticipants = Notification(id: FIRDocID, title: "DP 정산 알림", body: "\(eventName) 구독권 정산날이에요!🙂 \(owner)님에게 \(Int(price/Double(participants.count)))원을 보내주세요!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(eventDate), hour: 12, minute: 0))
                                    
                                    if owner == self.currentUser
                                    {
                                        if eventDate == "SOM"
                                        {
                                            self.manager.notifications.append(SOMNotificationOwner)
                                        }
                                        else if eventDate == "EOM" || eventDate == "30" || eventDate == "31"
                                        {
                                            if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "30"
                                            {
                                                self.manager.notifications = [EOMNotificationOwner]
                                            }
                                            else if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "31"
                                            {
                                                var foo = EOMNotificationOwner
                                                foo.datetime.day =  foo.datetime.day!-1
                                                self.manager.notifications.append(foo)
                                            }
                                            else
                                            {
                                                self.manager.notifications.append(EOMNotificationOwner)
                                            }
                                        }
                                        else if eventDate != "EOM" && eventDate != "SOM" && eventDate != ""
                                        {
                                            self.manager.notifications.append(SDMNotificationOwner)
                                        }
                                    }
                                    else
                                    {
                                        if eventDate == "SOM"
                                        {
                                            self.manager.notifications.append(SOMNotificationParticipants)
                                        }
                                        else if eventDate == "EOM" || eventDate == "30" || eventDate == "31"
                                        {
                                            if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "30"
                                            {
                                                self.manager.notifications.append(EOMNotificationParticipants)
                                            }
                                            else if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "31"
                                            {
                                                var foo = EOMNotificationParticipants
                                                foo.datetime.day = foo.datetime.day!-1
                                                self.manager.notifications.append(foo)
                                            }
                                            else
                                            {
                                                self.manager.notifications.append(EOMNotificationParticipants)
                                            }
                                        }
                                        else if eventDate != "EOM" && eventDate != "SOM" && eventDate != ""
                                        {
                                            self.manager.notifications.append(SDMNotificationParticipants)
                                        }
                                    }
                                    PaymentEvent.didChange = false
                                }
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async
            {
                if Notification.pushNotificationOn == true
                {
                    self.manager.schedule()
                }
                else
                {
                    self.manager.notifications.removeAll()
                    self.manager.schedule()
                }
                self.tableView.reloadData()
                completion(true)
            }
        }
    }
    //MARK: - Table View Datasource Methods
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MySwipeCell
        cell.delegate = self
        cell.cellTitleLabelWidthConstraint.constant = (tableView.bounds.width - 16)*0.75
        cell.cellSecondaryTextLabelWidthConstraint.constant = (tableView.bounds.width - 16)*0.25
        cell.cellSecondaryTextLabel.adjustsFontSizeToFitWidth = true
        for subview in cell.contentView.subviews
        {
            if subview.layer.shadowOpacity == 0.5
            {
                subview.removeFromSuperview()
            }
        }
        
        var cellView = UIView(frame: CGRect(x: 8, y: 6, width: tableView.bounds.width-16, height: 78))
        cellView.layer.cornerRadius = 25
        cellView.layer.borderWidth = 1
        cell.cellTitleLabel.numberOfLines = 1
        
        let isDarkOn = UserDefaults.standard.bool(forKey: "prefs_is_dark_mode_on")
        if indexPath.section == 0 && self.paymentArray.count != 0
        {
            if isDarkOn == true
            {
                cellView.layer.shadowColor = UIColor.white.cgColor
                cellView.backgroundColor = UIColor(red: 0.12, green: 0.32, blue: 0.16, alpha: 1.00)
                cellView.layer.borderColor = UIColor(red: 0.85, green: 0.91, blue: 0.66, alpha: 1.00).cgColor
                
                cell.cellTitleLabel.attributedText = NSAttributedString(string: self.paymentArray[indexPath.row].eventName, attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.white ])
                cell.cellSecondaryTextLabel.attributedText = NSAttributedString(string: "\(String(Int(self.paymentArray[indexPath.row].price)))원", attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.white ])
            }
            else
            {
                cellView.layer.shadowColor = UIColor.black.cgColor
                cellView.backgroundColor = UIColor(red: 0.85, green: 0.91, blue: 0.66, alpha: 1.00)
                cellView.layer.borderColor = UIColor(red: 0.12, green: 0.32, blue: 0.16, alpha: 1.00).cgColor
 
                cell.cellTitleLabel.attributedText = NSAttributedString(string: self.paymentArray[indexPath.row].eventName, attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.black ])
                cell.cellSecondaryTextLabel.attributedText = NSAttributedString(string: "\(String(Int(self.paymentArray[indexPath.row].price)))원", attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.black ])
            }
        }
        else if indexPath.section == 1 && self.participantEventArray.count != 0
        {
            if isDarkOn == true
            {
                cellView.layer.shadowColor = UIColor.white.cgColor
                cellView.backgroundColor = UIColor(red: 0.12, green: 0.32, blue: 0.16, alpha: 1.00)
                cellView.layer.borderColor = UIColor(red: 0.85, green: 0.91, blue: 0.66, alpha: 1.00).cgColor
                cell.cellTitleLabel.attributedText = NSAttributedString(string: self.participantEventArray[indexPath.row].eventName, attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.white ])
                cell.cellSecondaryTextLabel.attributedText = NSAttributedString(string: "\(String(Int(self.participantEventArray[indexPath.row].price/Double(self.participantEventArray[indexPath.row].participants.count))))원", attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.white ])
            }
            else
            {
                cellView.layer.shadowColor = UIColor.black.cgColor
                cellView.backgroundColor = UIColor(red: 0.85, green: 0.91, blue: 0.66, alpha: 1.00)
                cellView.layer.borderColor = UIColor(red: 0.12, green: 0.32, blue: 0.16, alpha: 1.00).cgColor
                cell.cellTitleLabel.attributedText = NSAttributedString(string: self.participantEventArray[indexPath.row].eventName, attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.black ])
                cell.cellSecondaryTextLabel.attributedText = NSAttributedString(string: "\(String(Int(self.participantEventArray[indexPath.row].price/Double(self.participantEventArray[indexPath.row].participants.count))))원", attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.black ])
            }
        }
        cell.backgroundColor = .clear
        cellView.layer.shadowOpacity = 0.5
        cellView.layer.shadowOffset = .zero
        cellView.layer.shadowRadius = 3.5
        cellView.layer.masksToBounds = false
        
        cell.contentView.addSubview(cellView)
        cell.contentView.sendSubviewToBack(cellView)
        
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 90
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return paymentArray.count
        }
        else if section == 1
        {
            return participantEventArray.count
        }
        return 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 3
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))

        let isDarkOn = UserDefaults.standard.bool(forKey: "prefs_is_dark_mode_on")
        let label = UILabel()
        label.backgroundColor = .clear
        label.frame = CGRect.init(x: 12, y: 5, width: headerView.frame.width-12, height: headerView.frame.height)
        
        var total = 0.0
        for el in paymentArray
        {
            total = total + el.price
        }
        for el in participantEventArray
        {
            total = total + el.price/Double(el.participants.count)
        }
        if section == 0
        {
            label.attributedText = NSAttributedString(string: "내가 내는 구독권", attributes: [ .font: UIFont.systemFont(ofSize: 24, weight: .bold), .foregroundColor: UIColor.black ])
        }
        else if section == 1
        {
            label.attributedText = NSAttributedString(string: "보내야 하는 구독권", attributes: [ .font: UIFont.systemFont(ofSize: 24, weight: .bold), .foregroundColor: UIColor.black ])
        }
        else if section == 2
        {
            label.attributedText = NSAttributedString(string: "매달 지불 금액: \(String(Int(total)))원", attributes: [ .font: UIFont.systemFont(ofSize: 24, weight: .bold), .foregroundColor: UIColor.black ])
        }
        if isDarkOn == true
        {
            label.textColor = .white
        }
        headerView.addSubview(label)
        
        return headerView
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 50
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        performSegue(withIdentifier: "goToEvent", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
    {
        if indexPath.section == 2
        {
            return nil
        }
        return indexPath
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "goToEvent"
        {
            let destinationVC = segue.destination as! DetailViewController
            //current row that is selected
            if let indexPath = tableView.indexPathForSelectedRow
            {
                if indexPath.section == 0
                {
                    destinationVC.event = paymentArray[indexPath.row]
                }
                else if indexPath.section == 1
                {
                    destinationVC.event = participantEventArray[indexPath.row]
                }
            }
        }
    }
    
    //MARK: - Delete Data from swipe
    override func updateModel(at indexPath: IndexPath)
    {
        if indexPath.section == 0
        {
            db.collection("events").document(paymentArray[indexPath.row].FIRDocID).delete()
            {   err in
                if let err = err
                {
                    print("Error removing document as owner: \(err)")
                }
                else
                {
                    print("Document successfully removed!")
                }
            }
            for (index, element) in self.manager.notifications.enumerated()
            {
                print(index)
                if self.manager.notifications[index].id == paymentArray[indexPath.row].FIRDocID
                {
                    self.manager.notifications.remove(at: index)
                    self.manager.schedule()
                    break
                }
            }
            paymentArray.remove(at: indexPath.row)
        }
        else if indexPath.section == 1
        {
            db.collection("events").document(participantEventArray[indexPath.row].FIRDocID).updateData(["participants" : FieldValue.arrayRemove([Auth.auth().currentUser!.email!])])
            { err in
                if let err = err
                {
                    print("Error removing document as participant: \(err)")
                }
                else
                {
                    print("Document successfully removed!")
                }
            }
            for (index, element) in self.manager.notifications.enumerated()
            {
                if self.manager.notifications[index].id == participantEventArray[indexPath.row].FIRDocID
                {
                    self.manager.notifications.remove(at: index)
                    self.manager.schedule()
                    break
                }
            }
            participantEventArray.remove(at: indexPath.row)
        }
    }
}

