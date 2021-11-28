//
//  LocalNotificationManager.swift
//  SplitBill
//
//  Created by Jung Hwan Park on 2021/11/17.
//

import Foundation
import UserNotifications

struct Notification
{
    var id: String
    var title: String
    var body: String
    var datetime: DateComponents
    static var pushNotificationOn: Bool = UserDefaults.standard.bool(forKey: "prefs_is_push_notification_on")
}

class LocalNotificationManager
{
    var notifications = [Notification]()

    func listScheduledNotifications()
    {
        UNUserNotificationCenter.current().getPendingNotificationRequests
        { notifications in

            for notification in notifications
            {
                print(notification)
            }
        }
    }

    private func requestAuthorization()
    {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        { granted, error in
            if granted == true && error == nil
            {
                self.scheduleNotifications()
            }
        }
    }

    func schedule()
    {
        UNUserNotificationCenter.current().getNotificationSettings
        { settings in

            switch settings.authorizationStatus
            {
                case .notDetermined:
                    self.requestAuthorization()
                case .authorized, .provisional:
                    self.scheduleNotifications()
                default:
                    break // Do nothing
            }
        }
    }

    private func scheduleNotifications()
    {
        for notification in notifications
        {
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: notification.datetime, repeats: true)

            let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
            { error in

                guard error == nil else { return }
                
                print("Notification scheduled! --- ID = \(notification.id)")
            }
        }
    }

}
