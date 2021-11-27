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

class CategoryViewController: SwipeTableViewController
{
//    let realm = try! Realm()
    var paymentArray: [PaymentEvent] = []
//    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let db = Firestore.firestore()
    
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
        let isDarkOn = UserDefaults.standard.bool(forKey: "prefs_is_dark_mode_on")
        if #available(iOS 13.0, *)
        {
            overrideUserInterfaceStyle = isDarkOn ? .dark : .light
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
           // Fallback on earlier versions
           view.backgroundColor = isDarkOn ? UIColor.black : UIColor.white
           navigationController?.navigationBar.barTintColor = .systemGreen
        }
        let selectedRow: IndexPath? = tableView.indexPathForSelectedRow
        if let selectedRowNotNill = selectedRow
        {
            tableView.deselectRow(at: selectedRowNotNill, animated: true)
        }
        AppUtility.lockOrientation(.portrait)
        self.view.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1)
        {
            self.loadEvents
            { success in
                self.view.isUserInteractionEnabled = true
            }
        }
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        AppUtility.lockOrientation(.portrait)
    }
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem)
    {
        var textField = UITextField()

        let alert = UIAlertController(title: "새로운 더치페이 이벤트", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "추가", style: .default) { (action) in
            //what will be happening once the user clicks the Add Item button on our UIAlert
            if  let event = textField.text, let userEmail = Auth.auth().currentUser?.email, let currentTime = Date().timeIntervalSince1970 as? Double
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
        if PaymentEvent.didChange == false && Notification.pushNotificationOn == true
        {
            completion(true)
            return
        }
        if Notification.pushNotificationOn == false
        {
            completion(true)
            return
        }
        db.collection("events").whereField("eventName", isNotEqualTo: false).getDocuments
        { querySnapShot, error in
            self.paymentArray = []
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
                        if (data["participants"] as! [String]).contains(Auth.auth().currentUser?.email ?? "nil")
                        {
                            if let eventName = data["eventName"] as? String, let price = data["price"] as? Double, let participants = data["participants"] as? [String]
                                , let owner = data["owner"] as? String, let eventDate = data["eventDate"] as? String, let dateCreated = data["dateCreated"] as? Double
                                , let FIRDocID = doc.documentID as? String
                            {
                                let newEvent = PaymentEvent(FIRDocID: FIRDocID, eventName: eventName, dateCreated: dateCreated, participants: participants, price: price, eventDate: eventDate, isOwner: owner == Auth.auth().currentUser?.email)
                                self.paymentArray.append(newEvent)
                                
                                if Notification.pushNotificationOn == false
                                {
                                    PaymentEvent.didChange = false
                                    break
                                }
                                let SOMNotificationOwner = Notification(id: FIRDocID, title: "DP 정산 알림", body: "오늘 \(eventName) 구독권으로 \(price)원이 지불됩니다!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(dateFormatter.string(from: startOfMonth)), hour: 12, minute: 0))

                                let EOMNotificationOwner = Notification(id: FIRDocID, title: "DP 정산 알림", body: "오늘 \(eventName) 구독권으로 \(price)원이 지불됩니다!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(dateFormatter.string(from: endOfMonth!)), hour: 12, minute: 0))

                                let SDMNotificationOwner = Notification(id: FIRDocID, title: "DP 정산 알림", body: "오늘 \(eventName) 구독권으로 \(price)원이 지불됩니다!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(eventDate), hour: 12, minute: 0))

                                let SOMNotificationParticipants = Notification(id: FIRDocID, title: "DP 정산 알림", body: "\(eventName) 구독권 정산날이에요!🙂 \(owner)님에게 \(Int(price/Double(participants.count)))원을 보내주세요!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(dateFormatter.string(from: startOfMonth)), hour: 12, minute: 0))

                                let EOMNotificationParticipants = Notification(id: FIRDocID, title: "DP 정산 알림", body: "\(eventName) 구독권 정산날이에요!🙂 \(owner)님에게 \(Int(price/Double(participants.count)))원을 보내주세요!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(dateFormatter.string(from: endOfMonth!)), hour: 12, minute: 0))

                                let SDMNotificationParticipants = Notification(id: FIRDocID, title: "DP 정산 알림", body: "\(eventName) 구독권 정산날이에요!🙂 \(owner)님에게 \(Int(price/Double(participants.count)))원을 보내주세요!", datetime: DateComponents(calendar: Calendar.current, year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Int(eventDate), hour: 12, minute: 0))
                                
                                if owner == Auth.auth().currentUser?.email
                                {
                                    if eventDate == "SOM"
                                    {
                                        Notification.manager.notifications = [SOMNotificationOwner]
                                    }
                                    else if eventDate == "EOM" || eventDate == "30" || eventDate == "31"
                                    {
                                        if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "30"
                                        {
                                            Notification.manager.notifications = [EOMNotificationOwner]
                                        }
                                        else if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "31"
                                        {
                                            var foo = EOMNotificationOwner
                                            foo.datetime.day =  foo.datetime.day!-1
                                            Notification.manager.notifications = [foo]
                                        }
                                        else
                                        {
                                            Notification.manager.notifications = [EOMNotificationOwner]
                                        }
                                    }
                                    else if eventDate != "EOM" && eventDate != "SOM" && eventDate != ""
                                    {
                                        Notification.manager.notifications = [SDMNotificationOwner]
                                    }
                                }
                                else
                                {
                                    if eventDate == "SOM"
                                    {
                                        Notification.manager.notifications = [SOMNotificationParticipants]
                                    }
                                    else if eventDate == "EOM" || eventDate == "30" || eventDate == "31"
                                    {
                                        if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "30"
                                        {
                                            Notification.manager.notifications = [EOMNotificationParticipants]
                                        }
                                        else if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "31"
                                        {
                                            var foo = EOMNotificationParticipants
                                            foo.datetime.day = foo.datetime.day!-1
                                            Notification.manager.notifications = [foo]
                                        }
                                        else
                                        {
                                            Notification.manager.notifications = [EOMNotificationParticipants]
                                        }
                                    }
                                    else if eventDate != "EOM" && eventDate != "SOM" && eventDate != ""
                                    {
                                        Notification.manager.notifications = [SDMNotificationParticipants]
                                    }
                                }
                                Notification.manager.schedule()
                                print(Notification.manager.notifications)
                                PaymentEvent.didChange = false
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async
            {
                self.tableView.reloadData()
                completion(true)
            }
        }
    }
    //MARK: - Table View Datasource Methods
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        for subview in cell.contentView.subviews
        {
            if subview.layer.shadowOpacity == 0.5
            {
                subview.removeFromSuperview()
            }
        }
        var content = cell.defaultContentConfiguration()

        let cellView = UIView(frame: CGRect(x: 5, y: 5, width: tableView.bounds.width-10, height: 80))
        cellView.layer.cornerRadius = 25
        cellView.layer.borderWidth = 5
        
        let isDarkOn = UserDefaults.standard.bool(forKey: "prefs_is_dark_mode_on")
        if isDarkOn == true
        {
            cellView.layer.shadowColor = UIColor.white.cgColor
            cellView.backgroundColor = UIColor(red: 0.12, green: 0.32, blue: 0.16, alpha: 1.00)
            cellView.layer.borderColor = UIColor(red: 0.85, green: 0.91, blue: 0.66, alpha: 1.00).cgColor
            content.attributedText = NSAttributedString(string: paymentArray[indexPath.row].eventName, attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.white ])
            content.secondaryAttributedText = NSAttributedString(string: "\(String(Int(paymentArray[indexPath.row].price/Double(paymentArray[indexPath.row].participants.count))))원", attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.white ])
        }
        else
        {
            cellView.layer.shadowColor = UIColor.black.cgColor
            cellView.backgroundColor = UIColor(red: 0.85, green: 0.91, blue: 0.66, alpha: 1.00)
            cellView.layer.borderColor = UIColor(red: 0.12, green: 0.32, blue: 0.16, alpha: 1.00).cgColor
            content.attributedText = NSAttributedString(string: paymentArray[indexPath.row].eventName, attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.black ])
            content.secondaryAttributedText = NSAttributedString(string: "\(String(Int(paymentArray[indexPath.row].price/Double(paymentArray[indexPath.row].participants.count))))원", attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.black ])
        }
    
        cell.backgroundColor = .clear
        cell.contentConfiguration = content
        
        
        cellView.layer.shadowOpacity = 0.5
        cellView.layer.shadowOffset = .zero
        cellView.layer.shadowRadius = 8
        
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
        return paymentArray.count
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 1
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        //self.tabBarController?.tabBar.isHidden = true
        performSegue(withIdentifier: "goToEvent", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "goToEvent"
        {
            let destinationVC = segue.destination as! DetailViewController
            //current row that is selected
            if let indexPath = tableView.indexPathForSelectedRow
            {
                destinationVC.event = paymentArray[indexPath.row]
            }
        }
    }
    
    //MARK: - Delete Data from swipe
    override func updateModel(at indexPath: IndexPath)
    {
        if paymentArray[indexPath.row].isOwner == true
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
        }
        else if paymentArray[indexPath.row].isOwner == false
        {
            db.collection("events").document(paymentArray[indexPath.row].FIRDocID).updateData(["participants" : FieldValue.arrayRemove([Auth.auth().currentUser?.email!])])
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
        }
        paymentArray.remove(at: indexPath.row)
    }
}

