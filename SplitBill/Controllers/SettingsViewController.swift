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
    @IBOutlet var darkModeLabel: UILabel!
    @IBOutlet var pushNotificationSwitch: UISwitch!
    @IBOutlet var pushNotificationsLabel: UILabel!
    
    var madeByLabel = UILabel()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.31, green: 0.62, blue: 0.24, alpha: 1.00)
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = NSAttributedString(string: "설정", attributes: [ .font: UIFont.systemFont(ofSize: 40, weight: .bold), .foregroundColor: UIColor.white ])
        madeByLabel.numberOfLines = 0
        madeByLabel.frame = CGRect(x: 12, y: UIScreen.main.bounds.height-(self.tabBarController?.tabBar.frame.size.height)!-120, width: UIScreen.main.bounds.width-12, height: 120)
        let labelText = NSMutableAttributedString()
        let titleString = NSAttributedString(string: "Developed By\n\n", attributes: [ .font: UIFont.systemFont(ofSize: 18, weight: .medium), .foregroundColor: UIColor.black ])
        let nameString = NSAttributedString(string: "박정환\n", attributes: [ .font: UIFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: UIColor.black ])
        let majorString = NSAttributedString(string: "컴퓨터공학부\n", attributes: [ .font: UIFont.systemFont(ofSize: 14, weight: .regular), .foregroundColor: UIColor.black ])
        labelText.append(titleString)
        labelText.append(nameString)
        labelText.append(majorString)
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "envelope.circle")?.withTintColor(UIColor(red: 0.31, green: 0.62, blue: 0.24, alpha: 1.00))
        imageAttachment.image?.withTintColor(.green)
        imageAttachment.bounds = CGRect(x: 0, y: -10.0, width: imageAttachment.image!.size.width+10, height: imageAttachment.image!.size.height+10)
        let attachmentString = NSAttributedString(attachment: imageAttachment)
        labelText.append(attachmentString)
        let textAfterIcon = NSAttributedString(string: "hwan333@konkuk.ac.kr", attributes: [ .font: UIFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: UIColor.black ])
        labelText.append(textAfterIcon)
        madeByLabel.attributedText = labelText
        view.addSubview(madeByLabel)
    }
    override func viewWillAppear(_ animated: Bool)
    {
        let isDarkOn = UserDefaults.standard.bool(forKey: "prefs_is_dark_mode_on")
        let isPNOn = UserDefaults.standard.bool(forKey: "prefs_is_push_notification_on")
        initView(isDarkOn, isPNOn)
        darkModeLabel.attributedText = NSAttributedString(string: "다크 모드", attributes: [ .font: UIFont.systemFont(ofSize: 18, weight: .medium), .foregroundColor: UIColor.black ])
        pushNotificationsLabel.attributedText = NSAttributedString(string: "알림 허용", attributes: [ .font: UIFont.systemFont(ofSize: 18, weight: .medium), .foregroundColor: UIColor.black ])
    }
    func initView(_ isDarkOn: Bool, _ isPushNotificationOn: Bool)
    {
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
            madeByLabel.textColor = .white
            darkModeSwitch.isOn = true
        }
        else
        {
            madeByLabel.textColor = .black
            darkModeSwitch.isOn = false
        }
        if isPushNotificationOn == true
        {
            pushNotificationSwitch.isOn = true
        }
        else
        {
            pushNotificationSwitch.isOn = false
        }
        NVshadowView.backgroundColor = .white
        NVshadowView.layer.borderColor = UIColor.lightGray.cgColor
        DMshadowView.backgroundColor = .white
        DMshadowView.layer.borderColor = UIColor.lightGray.cgColor
        NVshadowView.layer.shadowColor = UIColor.black.cgColor
        DMshadowView.layer.shadowColor = UIColor.black.cgColor
        
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
        UserDefaults.standard.set(sender.isOn, forKey: "prefs_is_push_notification_on")
        if sender.isOn == false
        {
            Notification.pushNotificationOn = false
        }
        else
        {
            PaymentEvent.didChange = true
            Notification.pushNotificationOn = true
        }
        if let tabbarC = self.tabBarController
        {
            tabbarC.selectedIndex = 0
            let home = tabbarC.tabBar.selectedItem
            self.tabBarController?.tabBar(tabbarC.tabBar, didSelect: home!)
        }
        
    }
    @IBAction func darkModeSwitchDidChange(_ sender: UISwitch)
    {
        UserDefaults.standard.set(darkModeSwitch.isOn, forKey: "prefs_is_dark_mode_on")
        initView(sender.isOn, pushNotificationSwitch.isOn)
    }
    
}
