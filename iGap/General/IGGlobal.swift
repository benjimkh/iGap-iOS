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
import SwiftProtobuf
import MBProgressHUD
import Foundation
import SwiftyRSA
import SDWebImage
import RxSwift

let kIGUserLoggedInNotificationName = "im.igap.ios.user.logged.in"
let kIGNotificationNameDidCreateARoom = "im.igap.ios.room.created"
let kIGNoticationForPushUserExpire = "im.igap.ios.user.expire"

let IGNotificationStatusBarTapped         = Notification(name: Notification.Name(rawValue: "im.igap.statusbarTapped"))
let IGNotificationPushLoginToken          = Notification(name: Notification.Name(rawValue: "im.igap.ios.user.push.token"))
let IGNotificationPushTwoStepVerification = Notification(name: Notification.Name(rawValue: "im.igap.ios.user.push.two.step"))


class IGGlobal {
    
    static var imgDic : [String: IGImageView] = [:]
    static var heroTabIndex : Int = -1
    static var dispoasDic: [Int64:Disposable] = [:]
    
    /**********************************************/
    /****************** Progress ******************/
    private static var progressHUD = MBProgressHUD()
    
    internal static func prgShow(_ view: UIView){
        DispatchQueue.main.async {
            if let superView = view.superview {
                IGGlobal.progressHUD = MBProgressHUD.showAdded(to: superView, animated: true)
                IGGlobal.progressHUD.mode = .indeterminate
            }
        }
    }
    
    internal static func prgHide(){
        DispatchQueue.main.async {
            IGGlobal.progressHUD.hide(animated: true)
        }
    }
    /****************** Progress ******************/
    /**********************************************/
    
    
    /**********************************************/
    /******************** File ********************/
    
    internal static func makePath(filename: String?) -> URL? {
        if filename != nil {
            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            return NSURL(fileURLWithPath: documents).appendingPathComponent(filename!)
        }
        return nil
    }

    /*
     * check file exist in path or no. also if 'fileSize' is set to the input of the method,
     * size of file that exist in path and 'fileSize' which is set, will be compared.
     * finally if there are two equal values,the output is true otherwise the output will be false.
     */
    
    internal static func isFileExist(path: String?, fileSize: Int = -1) -> Bool {
        if path != nil && FileManager.default.fileExists(atPath: path!) {
            if fileSize == -1 || fileSize == FileManager.default.contents(atPath: path!)?.count {
                return true
            }
        }
        return false
    }
    
    internal static func isFileExist(path: URL?, fileSize: Int = -1) -> Bool {
        if path != nil {
            return isFileExist(path: path?.path, fileSize: fileSize)
        }
        return false
    }
    
    internal static func removeFile(path: String?) {
        do {
            if path != nil {
                try FileManager.default.removeItem(atPath: path!)
            }
        } catch {
            print("file not removed")
        }
    }
    
    internal static func removeFile(path: URL?) {
        do {
            if path != nil {
                try FileManager.default.removeItem(at: path!)
            }
        } catch {
            print("file not removed")
        }
    }
    
    internal static func getFileSize(path: URL?) -> Int64{
        if path == nil {
            return 0
        }
        
        return getFileSize(path: path?.path)
    }
    
    internal static func getFileSize(path: String?) -> Int64{
        if path == nil || !isFileExist(path: path) {
            return 0
        }
        
        return Int64(FileManager.default.contents(atPath: (path)!)!.count)
    }
    /******************** File ********************/
    /**********************************************/
    
    
    //MARK: RegEx
    public class func matches(for regex: String, in text: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.count > 0
        } catch {
            return false
        }
    }
    
    //MARK: Random String
    public class func randomString(length : Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString = ""
        for _ in 0..<length {
            let rand = Int(arc4random_uniform(UInt32(letters.count)))
            randomString.append(letters[rand])
        }
        return randomString
    }
    
    public class func randomId() -> Int64 {
        return Int64(arc4random()) + (Int64(arc4random()) << 32)
    }
    
    /* if device is iPad return "alert" style otherwise will be returned "actionSheet" style */
    public class func detectAlertStyle() -> UIAlertController.Style{
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .actionSheet
        }
        return .alert
    }
    
    public class func hasBigScreen() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return false
        }
        
        return true
    }
    
    public class func fetchUIScreen() -> CGRect {
        return UIScreen.main.bounds
    }
    
    public class func getCurrentMillis()->Int64{
        return  Int64(NSDate().timeIntervalSince1970 * 1000)
    }
}

extension UIViewController {
    class var storyboardID : String {
        return "\(self)"
    }
    
    static func instantiateFromAppStroryboard(appStoryboard: AppStoryboard) -> Self {
        return appStoryboard.viewController(viewControllerClass: self)
    }
}

extension UICollectionView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.font = UIFont(name: "Avenir-Light", size: 18)
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel;
    }
    
    func restore() {
        self.backgroundView = nil
    }
}

//MARK: -
extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
    public class func hexStringToUIColor(hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    //iGap Theme
    class func iGapMainColor() -> UIColor {
        return UIColor(red:157/255.0, green:199/255.0, blue:86/255.0, alpha:1.0)
    }
    
    class func iGapBars() -> UIColor { // navigation bar color
        return UIColor(red:157/255.0, green:199/255.0, blue:86/255.0, alpha:1.0)
    }
    
    class func iGapBarsInfo() -> UIColor { // text & icons color on navigation bar
        return UIColor(red:255.0/255.0, green:255.0/255.0, blue:255.0/255.0, alpha:1.0)
    }
    
    class func dialogueBoxOutgoing() -> UIColor {
        return UIColor(red: 209/255.0, green: 221/255.0, blue: 138/255.0, alpha: 0.9)
    }
    
    class func dialogueBoxIncomming() -> UIColor {
        return UIColor(red: 229/255.0, green: 225/255.0, blue: 220/255.0, alpha: 0.9)
    }
    
    class func forwardBoxIncomming() -> UIColor {
        return UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 0.9)
    }
    
    class func forwardBoxOutgoign() -> UIColor {
        return UIColor(red:157/255.0, green:199/255.0, blue:86/255.0, alpha:1.0)
    }
    
    class func forwardBoxTitleIncomming() -> UIColor {
        return UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
    
    class func forwardBoxTitleOutgoign() -> UIColor {
        return UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
    
    class func replyBoxIncomming() -> UIColor {
        return UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 0.9)
    }
    
    class func replyBoxOutgoing() -> UIColor {
        return UIColor(red:157/255.0, green:199/255.0, blue:86/255.0, alpha:1.0)
    }
    
    class func replyBoxTitleIncomming() -> UIColor {
        return UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
    
    class func replyBoxTitleOutgoign() -> UIColor {
        return UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
    
    class func replyBoxMessageIncomming() -> UIColor {
        return UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
    
    class func replyBoxMessageOutgoign() -> UIColor {
        return UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
    
    class func messageText() -> UIColor {
        return UIColor(red: 44/255.0, green: 54/255.0, blue: 63/255.0, alpha: 1.0)
    }
    
    class func dialogueBoxInfo() -> UIColor { // filename, contact, ...
        return UIColor.messageText()
    }
    
    class func pinnedChats() -> UIColor {
        return UIColor(red:157/255.0, green:199/255.0, blue:86/255.0, alpha:0.2)
    }
    
    class func chatListMessageType() -> UIColor {
        return UIColor(red:157/255.0, green:199/255.0, blue:86/255.0, alpha:1.0)
    }
    
    class func unreadLable() -> UIColor {
        return UIColor(red:224/255.0, green:83/255.0, blue:83/255.0, alpha:1.0)
    }
    
    class func iGapLink() -> UIColor {
        return UIColor(red:123/255.0, green:165/255.0, blue:52/255.0, alpha:1.0)
    }
    
    class func sticker() -> UIColor {
        return UIColor(red: 242/255.0, green: 242/255.0, blue: 255/255.0, alpha: 1.0)
    }
    
    class func stickerToolbar() -> UIColor {
        return UIColor(red: 249/255.0, green: 249/255.0, blue: 255/255.0, alpha: 1.0)
    }
    
    class func stickerToolbarSelected() -> UIColor {
        return UIColor(red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1.0)
    }
    
    //MARK: MGSwipeTableCell
    class func swipeDarkBlue() -> UIColor {
        return UIColor(red:42/255.0, green:61/255.0, blue:61/255.0, alpha:1.0)
    }
    
    class func swipeBlueGray() -> UIColor {
        return UIColor(red:93/255.0, green:111/255.0, blue:111/255.0, alpha:1.0)
    }
    
    class func swipeGray() -> UIColor {
        return UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 1.0)
    }
    
    class func swipeRed() -> UIColor {
        return UIColor(red:224/255.0, green:83/255.0, blue:83/255.0, alpha:1.0)
    }
    
    //MARK: General Colors
    class func organizationalColor() -> UIColor { // iGap Color
        return iGapMainColor()
        // iGap Old Color
        //return UIColor(red:0/255.0, green:176.0/255.0, blue:191.0/255.0, alpha:1.0)
    }
    
    class func customKeyboardButton() -> UIColor {
        return UIColor(red:125/255.0, green:125/255.0, blue:125/255.0, alpha:1.0)
    }
    
    //MARK: General Colors
    class func doctorBotPinColor() -> UIColor {
        return UIColor(red:0/255.0, green:176.0/255.0, blue:191.0/255.0, alpha:0.2)
    }
    
    class func organizationalColorLight() -> UIColor {
        return UIColor(red:180.0/255.0, green:255.0/255.0, blue:255.0/255.0, alpha:1.0)
    }
    
    class func returnToCall() -> UIColor {
        return UIColor(red:254.0/255.0, green:193.0/255.0, blue:7.0/255.0, alpha:1.0)
    }
    
    class func callRatingView() -> UIColor {
        return UIColor(red: 44.0/255.0, green: 170/255.0, blue: 163.0/255.0, alpha: 1.0)
    }
    
    class func iGapColor() -> UIColor {
        return UIColor(red: 44.0/255.0, green: 170/255.0, blue: 163.0/255.0, alpha: 1.0)
    }
    
    //MARK: Call State Colors
    class func callStatusColor(status: Int) -> UIColor {
        
        switch status {
            
        case 0: //MISSED
            return UIColor(red: 242.0/255.0, green: 49.0/255.0, blue: 49.0/255.0, alpha: 1.0)
            
        case 1: //CANCELED
            return UIColor(red: 0.0/255.0, green: 176/255.0, blue: 191.0/255.0, alpha: 1.0)
            
        case 2: //INCOMING
            return UIColor(red: 63.0/255.0, green: 81.0/255.0, blue: 181.0/255.0, alpha: 1.0)
            
        case 3: //OUTGOING
            return UIColor(red: 0.0/255.0, green: 176/255.0, blue: 191.0/255.0, alpha: 1.0)
            
        default:
            return UIColor(red: 0.0/255.0, green: 176/255.0, blue: 191.0/255.0, alpha: 1.0)
        }
        
    }
    
    class func senderNameColor() -> UIColor {
        return UIColor(red: 0.0/255.0, green: 188.0/255.0, blue: 202.0/255.0, alpha: 1.0)
    }
    
    class func senderNameColorDark() -> UIColor {
        return UIColor(red: 0.0/255.0, green: 100.0/255.0, blue: 120.0/255.0, alpha: 1.0)
    }
    
    class func chatBubbleBackground(isIncommingMessage: Bool) -> UIColor {
        if isIncommingMessage {
            return UIColor.dialogueBoxIncomming()
        } else {
            return UIColor.dialogueBoxOutgoing()
        }
    }
    
    class func chatBubbleBorderColor() -> UIColor {
        return UIColor(red: 179.0/255.0, green: 179.0/255.0, blue: 179.0/255.0, alpha: 1.0)
    }
    
    class func chatBubbleTextColor(isIncommingMessage: Bool) -> UIColor {
        return UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0)
    }
    
    //MARK: MessageCVCell Time
    class func chatTimeTextColor(isIncommingMessage: Bool) -> UIColor {
        return UIColor(red: 105.0/255.0, green: 123.0/255.0, blue: 135.0/255.0, alpha: 1.0)
    }
    
    //MARK: MessageCVCell Forward
    class func chatForwardedFromViewBackgroundColor(isIncommingMessage: Bool) -> UIColor {
        if isIncommingMessage {
            return UIColor.forwardBoxIncomming()
        } else {
            return UIColor.forwardBoxOutgoign()
        }
    }
    
    class func chatForwardedFromUsernameLabelColor(isIncommingMessage: Bool) -> UIColor {
        if isIncommingMessage {
            return UIColor.forwardBoxTitleIncomming()
        } else {
            return UIColor.forwardBoxTitleOutgoign()
        }
    }
    
    class func chatForwardedFromMediaContainerViewBackgroundColor(isIncommingMessage: Bool) -> UIColor {
        if isIncommingMessage {
            return UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
        } else {
            return UIColor(red: 44.0/255.0, green: 170/255.0, blue: 163.0/255.0, alpha: 1.0)
        }
    }
    
    class func chatForwardedFromBodyContainerViewBackgroundColor(isIncommingMessage: Bool) -> UIColor {
        if isIncommingMessage {
            return UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
        } else {
            return UIColor(red: 44.0/255.0, green: 170/255.0, blue: 163.0/255.0, alpha: 1.0)
        }
    }
    
    class func chatForwardedFromBodyLabelTextColor(isIncommingMessage: Bool) -> UIColor {
        if isIncommingMessage {
            return UIColor.chatBubbleTextColor(isIncommingMessage: isIncommingMessage)
        } else {
            return UIColor(red: 42.0/255.0, green: 42.0/255.0, blue: 42.0/255.0, alpha: 1.0)
        }
    }
    
    
    //MARK: MessageCVCell Reply
    class func chatReplyToBackgroundColor(isIncommingMessage: Bool) -> UIColor {
        if isIncommingMessage {
            return UIColor.replyBoxIncomming()
        } else {
            return UIColor.replyBoxOutgoing()
        }
    }
    
    class func chatReplyToIndicatorViewColor(isIncommingMessage: Bool) -> UIColor {
        if isIncommingMessage {
            return UIColor.replyBoxTitleIncomming()
        } else {
            return UIColor.replyBoxTitleOutgoign()
        }
    }
    
    class func chatReplyToUsernameLabelTextColor(isIncommingMessage: Bool) -> UIColor {
        if isIncommingMessage {
            return UIColor.replyBoxTitleIncomming()
        } else {
            return UIColor.replyBoxTitleOutgoign()
        }
    }
    
    class func chatReplyToMessageBodyLabelTextColor(isIncommingMessage: Bool) -> UIColor {
        if isIncommingMessage {
            return UIColor.replyBoxMessageIncomming()
        } else {
            return UIColor.replyBoxMessageOutgoign()
        }
    }
}

//MARK: -
extension Date {
    func convertToHumanReadable(onlyTimeIfToday: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        
        let calendar = NSCalendar.current
        if onlyTimeIfToday && !calendar.isDateInToday(self) {
            dateFormatter.dateFormat = "MMM, dd"
            return dateFormatter.string(from: self)
        }
        dateFormatter.dateFormat = "HH:mm"
        let hour = calendar.component(Calendar.Component.hour, from: self)
        let min = calendar.component(Calendar.Component.minute, from: self)
        return "\(String(format: "%02d", hour)):\(String(format: "%02d", min))"
    }
    
    func completeHumanReadableTime() -> String {
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "dd MMM YYYY - HH:mm"
        let dateString = dayTimePeriodFormatter.string(from: self)
        return dateString
    }
    
    func humanReadableForLastSeen() -> String {
        let differenctToNow = Date().timeIntervalSince1970 - self.timeIntervalSince1970
        if differenctToNow < 10 {
            return "just now"
        } else if differenctToNow < 120 {
            return "in a minute"
        } else if differenctToNow < 3600 {
            let minutes = Int(differenctToNow / 60)
            return "\(minutes) minutes ago"
        } else if differenctToNow < 3600 * 2 {
            return "an hour ago"
        } else if differenctToNow < 3600 * 24 {
            let hours = Int(differenctToNow / 3600)
            return "\(hours) hours ago"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        let dateString = dateFormatter.string(from: self)
        dateFormatter.dateFormat = "h:mm a"
        let timeString = dateFormatter.string(from: self)
        return dateString + " at " + timeString
        
    }
}

//MARK: -
extension Data {
    func igSHA256() -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(self.count), &hash)
        }
        return Data(bytes: hash)
    }
}
//MARK: -
extension UIViewController {
    func setTabbarHidden(_ hide: Bool, animated: Bool) {
        if (self.isTabbarHidden() == hide ){
            return
        }
        // get a frame calculation ready
        let height = self.tabBarController?.tabBar.frame.size.height
        let offsetY = hide ? height! : -(height!)
        
        // zero duration means no animation
        let duration = animated ? 0.3 : 0.0
        
        UIView.animate(withDuration: duration, animations: {
            let frame = self.tabBarController?.tabBar.frame;
            self.tabBarController?.tabBar.frame = frame!.offsetBy(dx: 0, dy: offsetY)
        }, completion: {completed in
            
        })
    }
    
    func isTabbarHidden() -> Bool {
        return (self.tabBarController?.tabBar.frame.origin.y)! >= self.view.frame.maxY
    }
    
    func showAlert(title: String, message: String, action: (()->())? = nil, completion: (() -> Swift.Void)? = nil) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (alertAction) in
            if let action = action {
                action()
            }
        }
        alertVC.addAction(okAction)
        self.present(alertVC, animated: true, completion: completion)
    }
}

//MARK: -
extension NSCache {
    subscript (key: AnyObject) -> AnyObject? {
        get {
            return (self as! NSCache<AnyObject,AnyObject>).object(forKey: key)
        }
        set {
            if let value: AnyObject = newValue {
                (self as! NSCache<AnyObject,AnyObject>).setObject(value, forKey: key)
            } else {
                (self as! NSCache<AnyObject,AnyObject>).removeObject(forKey: key)
            }
        }
    }
}

var imagesMap = [String : UIImageView]()

//MARK: -
extension UIImageView {
    func setThumbnail(for attachment:IGFile) {
        if attachment.type == .voice {
            self.image = UIImage(named:"IG_Message_Cell_Voice")
        } else if attachment.type == .file {
            let filename: NSString = attachment.name! as NSString
            let fileExtension = filename.pathExtension
            
            if fileExtension != "" {
                if fileExtension == "doc" {
                    self.image = UIImage(named:"IG_Message_Cell_File_Doc")
                    
                } else if fileExtension == "exe" {
                    self.image = UIImage(named:"IG_Message_Cell_File_Exe")
                    
                } else if fileExtension == "pdf" {
                    self.image = UIImage(named:"IG_Message_Cell_File_Pdf")
                    
                } else if fileExtension == "txt" {
                    self.image = UIImage(named:"IG_Message_Cell_File_Txt")
                    
                } else {
                    self.image = UIImage(named:"IG_Message_Cell_File_Generic")
                }
                
            } else {
                self.image = UIImage(named:"IG_Message_Cell_File_Generic")
            }
            
        } else if attachment.type == .audio {
            self.image = UIImage(named:"IG_Message_Cell_Player_Default_Cover")
        } else {
            if let _ = UIImage.originalImage(for: attachment) {
                //self.image = image
                self.sd_setImage(with: attachment.path(), completed: nil)
            } else if let thumbnail = attachment.smallThumbnail {
                do {
                    var path = URL(string: "")
                    if attachment.attachedImage != nil {
                        self.image = attachment.attachedImage
                    } else {
                        var image: UIImage?
                        path = thumbnail.path()
                        if IGGlobal.isFileExist(path: path) {
                            image = UIImage(contentsOfFile: path!.path)
                        }
                        
                        if image != nil {
                            //self.image = image
                            self.sd_setImage(with: path, completed: nil)
                        } else {
                            throw NSError(domain: "asa", code: 1234, userInfo: nil)
                        }
                    }
                } catch {
                    imagesMap[attachment.token!] = self
                    IGDownloadManager.sharedManager.download(file: thumbnail, previewType: .smallThumbnail, completion: { (attachment) -> Void in
                        DispatchQueue.main.async {
                            if let image = imagesMap[attachment.token!] {
                                image.sd_setImage(with: attachment.path(), completed: nil)
                            }
                        }
                    }, failure: {
                        
                    })
                }
            } else {
                switch attachment.type {
                case .image:
                    self.image = nil
                    break
                case .gif:
                    break
                case .video:
                    break
                case .audio:
                    self.image = UIImage(named:"IG_Message_Cell_Player_Default_Cover")
                    break
                default:
                    break
                }
            }
        }
    }
    
    func setSticker(for attachment:IGFile) {
        do {
            //var image: UIImage?
            let path = attachment.path()
            if IGGlobal.isFileExist(path: path) {
                //image = UIImage(contentsOfFile: path!.path)
                self.sd_setImage(with: path, completed: nil)
            } else {
                throw NSError(domain: "asa", code: 1234, userInfo: nil)
            }
        } catch {
            imagesMap[attachment.token!] = self
            IGDownloadManager.sharedManager.download(file: attachment, previewType: .originalFile, completion: { (attachment) -> Void in
                DispatchQueue.main.async {
                    if let image = imagesMap[attachment.token!] {
                        image.setSticker(for: attachment)
                    }
                }
            }, failure: {
                
            })
        }
    }
    
    func setImage(for attachment:IGFile) {
        if attachment.attachedImage != nil {
            self.image = attachment.attachedImage
        } else {
            let path = attachment.path()
            let data = try! Data(contentsOf: path!)
            if let image = UIImage(data: data) {
                self.image = image
            }
        }
    }
    
    func setImage(avatar: IGAvatar, showMain: Bool = false) {
        
        var file : IGFile!
        var previewType : IGFile.PreviewType!
        
        if showMain {
            
            file = avatar.file
            previewType = IGFile.PreviewType.originalFile
            
        } else {
            
            if let largeThumbnail = avatar.file?.largeThumbnail {
                file = largeThumbnail
                previewType = IGFile.PreviewType.largeThumbnail
            } else {
                file = avatar.file?.smallThumbnail
                previewType = IGFile.PreviewType.smallThumbnail
            }
        }
        
        if file != nil {
            do {
                if file.attachedImage != nil {
                    self.image = file.attachedImage
                } else {
                    
                    var image: UIImage?
                    let path = file.path()
                    if IGGlobal.isFileExist(path: path, fileSize: file.size) {
                        image = UIImage(contentsOfFile: path!.path)
                    }
                    
                    if image != nil {
                        self.image = image
                    } else {
                        if showMain {
                            setImage(avatar: avatar) // call this method again for load thumbnail before load main image
                        }
                        throw NSError(domain: "asa", code: 1234, userInfo: nil)
                    }
                }
            } catch {
                imagesMap[file.token!] = self
                IGDownloadManager.sharedManager.download(file: file, previewType: previewType, completion: { (attachment) -> Void in
                    DispatchQueue.main.async {
                        if let imageMain = imagesMap[attachment.token!] {
                            let path = attachment.path()
                            if let data = try? Data(contentsOf: path!) {
                                if let image = UIImage(data: data) {
                                    imageMain.image = image
                                }
                            }
                        }
                    }
                }, failure: {
                    
                })
            }
        }
    }
    
    func setImage(url: URL) {
        
        if let filepath = IGGlobal.makePath(filename: url.lastPathComponent), IGGlobal.isFileExist(path: filepath) {
            self.image = UIImage(contentsOfFile: filepath.path)
            return
        }
        
        imagesMap[(url.absoluteString)] = self
        IGDownloadManager.sharedManager.downloadImage(url: url, completion: { (data) -> Void in
            DispatchQueue.main.async {
                if let imageMain = imagesMap[url.absoluteString] {
                    IGHelperBot.shared.data = data
                    imageMain.image = UIImage(data: data)
                }
            }
        })
    }
}

//MARK: -
extension UIImage {
    class func thumbnail(for attachment: IGFile) -> UIImage? {
        if let thumbnail = attachment.smallThumbnail {
            return self.originalImage(for: thumbnail)
        }
        return nil
    }
    
    class func originalImage(for attachment: IGFile) -> UIImage? {
        if let path = attachment.path() {
            if IGGlobal.isFileExist(path: path, fileSize: attachment.size) {
                if let image = UIImage(contentsOfFile: path.path) {
                    return image
                }
            }
        }
        if let attachedImage = attachment.attachedImage {
            return attachedImage
        }
        return nil
    }
    
    /****** Gif ******/
    public class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("image doesn't exist")
            return nil
        }
        
        return UIImage.animatedImageWithSource(source)
    }
    
    public class func gifImageWithURL(_ gifUrl:String) -> UIImage? {
        guard let bundleURL:URL = URL(string: gifUrl) else {
            return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            return nil
        }
        return gifImageWithData(imageData)
    }
    
    public class func gifImageWithName(_ name: String) -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
                print("SwiftGif: This image named \"\(name)\" does not exist")
                return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        
        return gifImageWithData(imageData)
    }
    
    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
        
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as! Double
        
        if delay < 0.1 {
            delay = 0.1
        }
        
        return delay
    }
    
    class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        
        if a < b {
            let c = a
            a = b
            b = c
        }
        
        var rest: Int
        while true {
            rest = a! % b!
            
            if rest == 0 {
                return b!
            } else {
                a = b
                b = rest
            }
        }
    }
    
    class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            
            let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                                                            source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }
        
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        let animation = UIImage.animatedImage(with: frames,
                                              duration: Double(duration) / 1000.0)
        
        return animation
    }
}

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}


//MARK: -
extension UIFont {
    
    enum FontWeight {
        case ultraLight
        case light
        case regular
        case medium
        case bold
    }
    
    class func igFont(ofSize fontSize: CGFloat, weight: FontWeight = .regular) -> UIFont {
        switch weight {
        case .ultraLight:
            return UIFont(name: "IRANSans-UltraLight", size: fontSize)!
        case .light:
            return UIFont(name: "IRANSans-Light", size: fontSize)!
        case .regular:
            return UIFont(name: "IRANSans", size: fontSize)!
        case .medium:
            return UIFont(name: "IRANSans-Medium", size: fontSize)!
        case .bold:
            return UIFont(name: "IRANSans-Bold", size: fontSize)!
        }
    }
    
    class func iGapFontico(ofSize fontSize: CGFloat) -> UIFont {
        return UIFont(name: "iGap-Fontico", size: fontSize)!
    }
    
    //    func bold() -> UIFont {
    //        return withTraits(traits: .traitBold)
    //    }
    
    //    func italic() -> UIFont {
    //        return withTraits(traits: .traitItalic)
    //    }
    
    //    func withTraits(traits:UIFontDescriptorSymbolicTraits...) -> UIFont {
    //
    //        if let result = CTFontCreateCopyWithSymbolicTraits(self as CTFont, 0, nil, .traitItalic, .traitItalic) {
    //            return result as UIFont
    //        }
    //
    //        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))!
    //        return UIFont(descriptor: descriptor, size: 0)
    //    }
}

extension String {
    
    func aesEncrypt(publicKey: String) -> String {
        var encryptedMsg : String = ""
        let dataKey = Data(self.utf8)
        do {
            let publicKey = try PublicKey(pemEncoded: publicKey)
            let clear = ClearMessage(data: dataKey)
            let encrypted = try clear.encrypted(with: publicKey, padding: .PKCS1)
            encryptedMsg = encrypted.base64String
        } catch  {
            print(error)
        }
        return encryptedMsg
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font]), context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): font]), context: nil)
        
        return ceil(boundingBox.width)
    }
    
    public func getExtension() -> String? {
        let ext = (self as NSString).pathExtension
        if ext.isEmpty {
            return nil
        }
        return ext
    }
    
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    
    func substring(offset: Int) -> String{
        if self.count < offset {
            return self
        }
        let index = self.index(self.startIndex, offsetBy: offset)
        return String(self.prefix(upTo: index))
    }
    
    func split(limit: Int) -> [String]{
        var stringArray : [String] = []
        if self.count <= limit {
            stringArray = [self]
        } else {
            var countInt : Int = self.count / limit
            let countDouble : Double = Double(self.count) / Double(limit)
            
            if Double(countDouble) - Double(countInt) > 0 {
                countInt += 1
            }
            
            for i in 0..<countInt {
                let startIndex = i * limit
                var endIndex = startIndex + limit
                
                if i == (count - 1) {
                    endIndex = self.count - startIndex
                }
                
                stringArray.append(self[startIndex..<endIndex])
            }
        }
        return stringArray
    }
    
    /* detect first character should be write RTL or LTR */
    func isRTL() -> Bool {
        if self.count > 0, let first = self.removeEmoji().trimmingCharacters(in: .whitespacesAndNewlines).first, IGGlobal.matches(for: "[\\u0591-\\u07FF]", in: String(first)) {
            return true
        }
        return false
    }

    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }
    
    func removeEmoji() -> String {
        return String(self.filter { !$0.isEmoji() })
    }
    
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    var lines: [String] {
        var result: [String] = []
        enumerateLines { line, _ in result.append(line) }
        return result
    }
}

extension Character {
    fileprivate func isEmoji() -> Bool {
        return Character(UnicodeScalar(UInt32(0x1d000))!) <= self && self <= Character(UnicodeScalar(UInt32(0x1f77f))!)
            || Character(UnicodeScalar(UInt32(0x2100))!) <= self && self <= Character(UnicodeScalar(UInt32(0x26ff))!)
    }
}
        
extension Float {
    var cleanDecimal: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

extension Array {
    func chunks(_ chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

extension UIButton {
    
    func removeUnderline(){
        if let text = self.titleLabel?.text {
            let attrs = [ convertFromNSAttributedStringKey(NSAttributedString.Key.font) : self.titleLabel?.font as Any,
                          convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor) : self.titleLabel?.textColor as Any,
                          convertFromNSAttributedStringKey(NSAttributedString.Key.underlineStyle) : 0 ] as [String : Any]
            
            self.setAttributedTitle(NSMutableAttributedString(string: text, attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs)), for: self.state)
        }
    }
}

extension URLRequest {
    private static let alloweCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_.*")
    
    public mutating func setURLEncodedFormData(parameters: [String: String?]) {
        
        var encodedParameters = ""
        
        for (key, value) in parameters {
            
            if !encodedParameters.isEmpty {
                encodedParameters += "&"
            }
            
            encodedParameters += URLRequest.urlEncoded(value: key)
            encodedParameters += "="
            if let value = value {
                encodedParameters += URLRequest.urlEncoded(value: value)
            }
        }
        
        self.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        self.httpBody = encodedParameters.data(using: .utf8)
    }
    
    private static func urlEncoded(value: String) -> String {
        return value.addingPercentEncoding(withAllowedCharacters: alloweCharacters)!.replacingOccurrences(of: " ", with: "+")
    }
    
}
extension UIView {
    
    func fadeIn(_ duration: TimeInterval = 1.0, _ alpha: CGFloat = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = alpha
        })
    }
    
    func fadeOut(_ duration: TimeInterval = 1.0, _ alpha: CGFloat = 0.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = alpha
        })
    }
}

extension UIApplication {
    
    static func topViewController(base: UIViewController? = UIApplication.shared.delegate?.window??.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        
        return base
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
