//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Jung Hwan Park on 2021/08/01.
//  Copyright © 2021 App Brewery. All rights reserved.
//

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
    var didLoadAfterChange = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.rowHeight = 80
        tableView.dataSource = self
        tableView.separatorStyle = .none
        self.title = "ㄷㅍ"
    //        view.backgroundColor = .lightGray
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        if #available(iOS 13.0, *)
        {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor(red: 0.31, green: 0.62, blue: 0.24, alpha: 1.00)
            appearance.titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        else
        {
           // Fallback on earlier versions
           navigationController?.navigationBar.barTintColor = .systemGreen
        }
        let selectedRow: IndexPath? = tableView.indexPathForSelectedRow
        if let selectedRowNotNill = selectedRow
        {
            tableView.deselectRow(at: selectedRowNotNill, animated: true)
        }
        AppUtility.lockOrientation(.portrait)
        loadEvents()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        AppUtility.lockOrientation(.all)
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
        self.didLoadAfterChange = false
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
    func loadEvents()
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
        
        if didLoadAfterChange == true
        {
            return
        }
        db.collection("events").order(by: "dateCreated").addSnapshotListener
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
                                print(newEvent)
                                self.paymentArray.append(newEvent)
                                
                                DispatchQueue.main.async
                                {
                                    self.tableView.reloadData()
                                }
                                
                                let manager = LocalNotificationManager()
                                
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
                                        manager.notifications = [SOMNotificationOwner]
                                    }
                                    else if eventDate == "EOM" || eventDate == "30" || eventDate == "31"
                                    {
                                        if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "30"
                                        {
                                            manager.notifications = [EOMNotificationOwner]
                                        }
                                        else if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "31"
                                        {
                                            var foo = EOMNotificationOwner
                                            foo.datetime.day =  foo.datetime.day!-1
                                            manager.notifications = [foo]
                                        }
                                        else
                                        {
                                            manager.notifications = [EOMNotificationOwner]
                                        }
                                    }
                                    else if eventDate != "EOM" && eventDate != "SOM"
                                    {
                                        manager.notifications = [SDMNotificationOwner]
                                    }
                                }
                                else
                                {
                                    if eventDate == "SOM"
                                    {
                                        manager.notifications = [SOMNotificationParticipants]
                                    }
                                    else if eventDate == "EOM" || eventDate == "30" || eventDate == "31"
                                    {
                                        if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "30"
                                        {
                                            manager.notifications = [EOMNotificationParticipants]
                                        }
                                        else if eventDate == "30" && dateFormatter.string(from: endOfMonth!) == "31"
                                        {
                                            var foo = EOMNotificationParticipants
                                            foo.datetime.day = foo.datetime.day!-1
                                            manager.notifications = [foo]
                                        }
                                        else
                                        {
                                            manager.notifications = [EOMNotificationParticipants]
                                        }
                                    }
                                    else if eventDate != "EOM" && eventDate != "SOM"
                                    {
                                        manager.notifications = [SDMNotificationParticipants]
                                    }
                                }
                                print(manager.notifications)
                                manager.schedule()
                                self.didLoadAfterChange = true
                            }
                        }
                    }
                }
            }
        }
    }
    //MARK: - Table View Datasource Methods
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        var content = cell.defaultContentConfiguration()

        content.attributedText = NSAttributedString(string: paymentArray[indexPath.row].eventName, attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.black ])
        content.secondaryAttributedText = NSAttributedString(string: "\(String(Int(paymentArray[indexPath.row].price/Double(paymentArray[indexPath.row].participants.count))))원", attributes: [ .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.black ])
        cell.backgroundColor = .clear
        cell.contentConfiguration = content
        
        let cellView = UIView(frame: CGRect(x: 5, y: 5, width: tableView.bounds.width-10, height: 80))
        cellView.backgroundColor = UIColor(red: 0.85, green: 0.91, blue: 0.66, alpha: 1.00)
        cellView.layer.cornerRadius = 25
        cellView.layer.borderWidth = 5
        cellView.layer.borderColor = UIColor(red: 0.12, green: 0.32, blue: 0.16, alpha: 1.00).cgColor
        cellView.layer.masksToBounds = true
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
        performSegue(withIdentifier: "goToEvent", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let destinationVC = segue.destination as! DetailViewController
        //current row that is selected
        if let indexPath = tableView.indexPathForSelectedRow
        {
            destinationVC.event = paymentArray[indexPath.row]
        }
    }
    
    //MARK: - Delete Data from swipe
    override func updateModel(at indexPath: IndexPath)
    {
        db.collection("events").document(paymentArray[indexPath.row].FIRDocID).delete()
        {   err in
            if let err = err
            {
                print("Error removing document: \(err)")
            }
            else
            {
                print("Document successfully removed!")
            }
        }
        paymentArray.remove(at: indexPath.row)
    }
}
    
