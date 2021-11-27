//
//  MyTabBarController.swift
//  SplitBill
//
//  Created by Jung Hwan Park on 2021/11/28.
//

import Foundation
import UIKit

class MyTabBarController: UITabBarController
{
    var indicatorImage: UIImageView?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let numberOfItems = CGFloat(tabBar.items!.count)
        let tabBarItemSize = CGSize(width: (UIScreen.main.bounds.width / numberOfItems), height: tabBar.frame.height)
        indicatorImage = UIImageView(image: createSelectionIndicator(color: UIColor.black, size: tabBarItemSize, lineHeight: 8))
        indicatorImage?.center.x =  tabBar.frame.width/4
        indicatorImage?.center.y =  tabBar.frame.height-10
        
        tabBar.addSubview(indicatorImage!)
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem)
    {
        let index = CGFloat(integerLiteral: tabBar.items!.index(of: item)!)
        let itemWidth = indicatorImage?.frame.width
        let newCenterX = (itemWidth! / 2) + (itemWidth! * index)

        UIView.animate(withDuration: 0.3)
        {
            self.indicatorImage?.center.x = newCenterX
        }
    }

    func createSelectionIndicator(color: UIColor, size: CGSize, lineHeight: CGFloat) -> UIImage
    {
        let rect: CGRect = CGRect(x: 0, y: size.height - lineHeight, width: size.width, height: lineHeight )
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
