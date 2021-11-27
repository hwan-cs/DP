//
//  SettingsViewController.swift
//  SplitBill
//
//  Created by Jung Hwan Park on 2021/11/22.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController
{
    @IBOutlet var mainView: UIView!
    @IBOutlet var pushNotificationsView: UIView!
    @IBOutlet var darkModeView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var darkModeSwitch: UISwitch!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.31, green: 0.62, blue: 0.24, alpha: 1.00)
        titleLabel.numberOfLines = 0
    }
    override func viewWillAppear(_ animated: Bool)
    {
        let isDarkOn = UserDefaults.standard.bool(forKey: "prefs_is_dark_mode_on")
        initView(isDarkOn)
    }
    func initView(_ isDarkOn: Bool)
    {
        titleLabel.attributedText = NSAttributedString(string: "설정", attributes: [ .font: UIFont.systemFont(ofSize: 40, weight: .bold), .foregroundColor: UIColor.white ])
        for subview in pushNotificationsView.subviews
        {
            if subview.layer.shadowOpacity == 0.2
            {
                subview.removeFromSuperview()
            }
        }
        for subview in darkModeView.subviews
        {
            if subview.layer.shadowOpacity == 0.2
            {
                subview.removeFromSuperview()
            }
        }
        let NVshadowView = UIView(frame: CGRect(x: -5, y: 0, width: pushNotificationsView.bounds.width+10, height: pushNotificationsView.bounds.height))
        let DMshadowView = UIView(frame: CGRect(x: -5, y: 0, width: darkModeView.bounds.width+10, height: darkModeView.bounds.height))
        let isDarkOn = UserDefaults.standard.bool(forKey: "prefs_is_dark_mode_on")
        if #available(iOS 13.0, *)
        {
            overrideUserInterfaceStyle = isDarkOn ? .dark : .light
        }
        else
        {
            view.backgroundColor = isDarkOn ? UIColor.black : UIColor.white
        }
        if isDarkOn == true
        {
            darkModeSwitch.isOn = true
            NVshadowView.backgroundColor = .lightGray
            NVshadowView.layer.borderColor = UIColor.black.cgColor
            DMshadowView.backgroundColor = .lightGray
            DMshadowView.layer.borderColor = UIColor.black.cgColor
            NVshadowView.layer.shadowColor = UIColor.white.cgColor
            DMshadowView.layer.shadowColor = UIColor.white.cgColor
        }
        else
        {
            darkModeSwitch.isOn = false
            NVshadowView.backgroundColor = .white
            NVshadowView.layer.borderColor = UIColor.lightGray.cgColor
            DMshadowView.backgroundColor = .white
            DMshadowView.layer.borderColor = UIColor.lightGray.cgColor
            NVshadowView.layer.shadowColor = UIColor.black.cgColor
            DMshadowView.layer.shadowColor = UIColor.black.cgColor
        }
        NVshadowView.layer.cornerRadius = 25
        NVshadowView.layer.borderWidth = 1
        NVshadowView.layer.shadowOpacity = 0.2
        NVshadowView.layer.shadowOffset = .zero
        NVshadowView.layer.shadowRadius = 5

        DMshadowView.layer.cornerRadius = 25
        DMshadowView.layer.borderWidth = 1
        DMshadowView.layer.shadowOpacity = 0.2
        DMshadowView.layer.shadowOffset = .zero
        DMshadowView.layer.shadowRadius = 5
        pushNotificationsView.addSubview(NVshadowView)
        pushNotificationsView.sendSubviewToBack(NVshadowView)
        darkModeView.addSubview(DMshadowView)
        darkModeView.sendSubviewToBack(DMshadowView)
    }
    @IBAction func pushNotificationSwitchDidChange(_ sender: UISwitch)
    {
        if sender.isOn == false
        {
            Notification.pushNotificationOn = false
            Notification.manager.notifications.removeAll()
            print(Notification.manager.notifications)
        }
        else
        {
            Notification.pushNotificationOn = true
        }
    }
    @IBAction func darkModeSwitchDidChange(_ sender: UISwitch)
    {
        UserDefaults.standard.set(darkModeSwitch.isOn, forKey: "prefs_is_dark_mode_on")
        initView(sender.isOn)
    }
    
}
