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
    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.31, green: 0.62, blue: 0.24, alpha: 1.00)
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = NSAttributedString(string: "설정", attributes: [ .font: UIFont.systemFont(ofSize: 40, weight: .bold), .foregroundColor: UIColor.white ])
        let NVshadowView = UIView(frame: CGRect(x: -5, y: 0, width: pushNotificationsView.bounds.width+10, height: pushNotificationsView.bounds.height))
        NVshadowView.backgroundColor = .white
        NVshadowView.layer.cornerRadius = 25
        NVshadowView.layer.borderWidth = 1
        NVshadowView.layer.borderColor = UIColor.lightGray.cgColor
        NVshadowView.layer.shadowColor = UIColor.black.cgColor
        NVshadowView.layer.shadowOpacity = 0.1
        NVshadowView.layer.shadowOffset = .zero
        NVshadowView.layer.shadowRadius = 5
        let DMshadowView = UIView(frame: CGRect(x: -5, y: 0, width: darkModeView.bounds.width+10, height: darkModeView.bounds.height))
        DMshadowView.backgroundColor = .white
        DMshadowView.layer.cornerRadius = 25
        DMshadowView.layer.borderWidth = 1
        DMshadowView.layer.borderColor = UIColor.lightGray.cgColor
        DMshadowView.layer.shadowColor = UIColor.black.cgColor
        DMshadowView.layer.shadowOpacity = 0.1
        DMshadowView.layer.shadowOffset = .zero
        DMshadowView.layer.shadowRadius = 5
        pushNotificationsView.addSubview(NVshadowView)
        pushNotificationsView.sendSubviewToBack(NVshadowView)
        darkModeView.addSubview(DMshadowView)
        darkModeView.sendSubviewToBack(DMshadowView)
        
    }
}
