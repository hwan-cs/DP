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
    @IBOutlet var titleLabel: UILabel!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.31, green: 0.62, blue: 0.24, alpha: 1.00)
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = NSAttributedString(string: "설정", attributes: [ .font: UIFont.systemFont(ofSize: 40, weight: .bold), .foregroundColor: UIColor.white ])
    }
}
