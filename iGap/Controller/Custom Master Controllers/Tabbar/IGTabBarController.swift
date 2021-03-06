/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the Kianiranian STDG - www.kianiranian.com
 * All rights reserved.
 */

import UIKit

class IGTabBarController: UITabBarController {
    
    enum CurrentTab {
        case Recent
        case Chat
        case Group
        case Channel
        case Call
    }
    
    internal static var currentTabStatic: CurrentTab = .Recent
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.barTintColor = UIColor.iGapBars()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        selectedItemTitleMustbeBold()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        selectedItemTitleMustbeBold()
    }
    
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        selectedItemTitleMustbeBold()
    }
    
    func selectedItemTitleMustbeBold(){
        for item in tabBar.items!{
            if #available(iOS 10.0, *) {
                item.badgeColor = UIColor.unreadLable()
            }
            if tabBar.selectedItem == item {
                setCurrentTab(tag: (tabBar.selectedItem?.tag)!)
                let selectedTitleFont = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.bold)
                let selectedTitleColor = UIColor.black
                item.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): selectedTitleFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): selectedTitleColor]), for: UIControl.State.normal)
            } else {
                let normalTitleFont = UIFont.systemFont(ofSize: 9, weight: UIFont.Weight.regular)
                let normalTitleColor = UIColor(red: 176.0/255.0, green: 224.0/255.0, blue: 230.0/255.0, alpha: 1.0)
                item.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): normalTitleFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): normalTitleColor, convertFromNSAttributedStringKey(NSAttributedString.Key.backgroundColor): UIColor.black]), for: UIControl.State.normal)
            }
        }
        if #available(iOS 10.0, *) {
            self.tabBar.unselectedItemTintColor = UIColor.white
        }
    }
    
    private func setCurrentTab(tag: Int){
        switch tag {
            
        case 0:
            IGTabBarController.currentTabStatic = .Recent
            return
            
        case 1:
            IGTabBarController.currentTabStatic = .Chat
            return
            
        case 2:
            IGTabBarController.currentTabStatic = .Group
            return
            
        case 3:
            IGTabBarController.currentTabStatic = .Channel
            return
        
        case 4:
            IGTabBarController.currentTabStatic = .Call
            return
            
        default:
            IGTabBarController.currentTabStatic = .Recent
            return
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
