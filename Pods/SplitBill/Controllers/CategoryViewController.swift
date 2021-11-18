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
            appearance.backgroundColor = .systemGreen
            appearance.titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            //navigationController?.navigationBar.compactAppearance = appearance
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

        let alert = UIAlertController(title: "Add New Event", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add payment", style: .default) { (action) in
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
            alertTextField.placeholder = "Create New Payment"
            textField = alertTextField
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func signOutButtonPressed(_ sender: UIBarButtonItem)
    {
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
        
        cell.textLabel?.text = paymentArray[indexPath.section].eventName
        cell.textLabel?.font = UIFont(name: "Apple Color Emoji", size: 20.0)
        cell.detailTextLabel?.text = String(paymentArray[indexPath.section].price/Double(paymentArray[indexPath.section].participants.count))
        cell.detailTextLabel?.font = UIFont(name: "System", size: 15.0)
        cell.backgroundColor = UIColor.white
        
//        cell.layer.borderColor = UIColor.black.cgColor
//        cell.layer.borderWidth = 1
//        cell.layer.cornerRadius = 8
//
//        cell.clipsToBounds = true

        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80
    }
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return paymentArray.count
    }
    //spacing between cells
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    //make background color show through
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let header = UIView(frame: .init(x: 0, y: 0, width: tableView.bounds.width-20, height: 80))
        header.backgroundColor = .white
        
        let innerView = UIView(frame: .init(x: 10, y: 0, width: header.bounds.width, height: 80))
        header.addSubview(innerView)
    
        innerView.backgroundColor = .clear
        innerView.layer.cornerRadius = 12
        innerView.layer.borderColor = UIColor.black.cgColor
        innerView.layer.borderWidth = 2
        return header
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
            destinationVC.event = paymentArray[indexPath.section]
        }
    }
    
    //MARK: - Delete Data from swipe
    //MARK: -  11/19 버그발생, 못고치겠음, 머리카락빠지는중
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
        self.tableView.deleteSections(IndexSet(arrayLiteral: indexPath.section), with: .fade)
    }
}
    
