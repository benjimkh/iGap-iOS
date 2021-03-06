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
import IGProtoBuff
import SwiftProtobuf
import GrowingTextView
import pop
import SnapKit
import AVFoundation
import DBAttachmentPickerControllerLibrary
import INSPhotoGalleryFramework
import AVKit
import RealmSwift
import RxRealm
import RxSwift
import RxCocoa
import MBProgressHUD
import ContactsUI
import MobileCoreServices
import MarkdownKit

class IGHeader: UICollectionReusableView {
    
    override var reuseIdentifier: String? {
        get {
            return "IGHeader"
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.red
        
        let label = UILabel(frame: frame)
        label.text = "sdasdasdasd"
        self.addSubview(label)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

class IGMessageViewController: UIViewController, DidSelectLocationDelegate, UIGestureRecognizerDelegate, UIDocumentInteractionControllerDelegate, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CNContactPickerDelegate, EPPickerDelegate, UIDocumentPickerDelegate, AdditionalObserver, MessageViewControllerObserver, UIWebViewDelegate, StickerTapListener {
    

    @IBOutlet weak var pinnedMessageView: UIView!
    @IBOutlet weak var txtPinnedMessage: UILabel!
    @IBOutlet weak var collectionView: IGMessageCollectionView!
    @IBOutlet weak var inputBarContainerView: UIView!
    @IBOutlet weak var inputTextView: GrowingTextView!
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var inputTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputBarHeightContainerConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputBarView: UIView!
    @IBOutlet weak var inputBarBackgroundView: UIView!
    @IBOutlet weak var inputBarLeftView: UIView!
    @IBOutlet weak var inputBarRightiew: UIView!
    @IBOutlet weak var inputBarViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var inputBarRecordButton: UIButton!
    @IBOutlet weak var btnScrollToBottom: UIButton!
    @IBOutlet weak var inputBarSendButton: UIButton!
    @IBOutlet weak var btnCancelReplyOrForward: UIButton!
    @IBOutlet weak var btnDeleteSelectedAttachment: UIButton!
    @IBOutlet weak var btnClosePin: UIButton!
    @IBOutlet weak var btnAttachment: UIButton!
    @IBOutlet weak var inputBarRecordTimeLabel: UILabel!
    @IBOutlet weak var inputBarRecordView: UIView!
    @IBOutlet weak var inputBarRecodingBlinkingView: UIView!
    @IBOutlet weak var inputBarRecordRightView: UIView!
    @IBOutlet weak var inputBarRecordViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputBarAttachmentView: UIView!
    @IBOutlet weak var inputBarAttachmentViewThumnailImageView: UIImageView!
    @IBOutlet weak var inputBarAttachmentViewFileNameLabel: UILabel!
    @IBOutlet weak var inputBarAttachmentViewFileSizeLabel: UILabel!
    @IBOutlet weak var inputBarAttachmentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputBarOriginalMessageView: UIView!
    @IBOutlet weak var inputBarOriginalMessageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputBarOriginalMessageViewSenderNameLabel: UILabel!
    @IBOutlet weak var inputBarOriginalMessageViewBodyTextLabel: UILabel!
    @IBOutlet weak var scrollToBottomContainerView: UIView!
    @IBOutlet weak var scrollToBottomContainerViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatBackground: UIImageView!
    @IBOutlet weak var txtSticker: UILabel!
    @IBOutlet weak var floatingDateView: UIView!
    @IBOutlet weak var txtFloatingDate: UILabel!
    
    var webView: UIWebView!
    var webViewProgressbar: UIActivityIndicatorView!
    var btnChangeKeyboard : UIButton!
    var doctorBotScrollView : UIScrollView!
    private let disposeBag = DisposeBag()
    var latestTypeTime : Int64 = IGGlobal.getCurrentMillis()
    var allowForGetHistory: Bool = true
    var recorder: AVAudioRecorder?
    var isRecordingVoice = false
    var voiceRecorderTimer: Timer?
    var recordedTime: Int = 0
    var inputTextViewHeight: CGFloat = 0.0
    var inputBarRecordRightBigViewWidthConstraintInitialValue: CGFloat = 0.0
    var inputBarRecordRightBigViewInitialFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
    var bouncingViewWhileRecord: UIView?
    var initialLongTapOnRecordButtonPosition: CGPoint?
    var collectionViewTopInsetOffset: CGFloat = 0.0
    var connectionStatus : IGAppManager.ConnectionStatus?
    var reportMessageId: Int64?
    var sendAsFile: Bool = false
    
    let documentPickerIdentifiers = [String(kUTTypeURL), String(kUTTypeFileURL), String(kUTTypePDF), // file start
        String(kUTTypeGNUZipArchive), String(kUTTypeBzip2Archive), String(kUTTypeZipArchive),
        String(kUTTypeWebArchive), String(kUTTypeTXNTextAndMultimediaData), String(kUTTypeFlatRTFD),
        String(kUTTypeRTFD), // file end
        String(kUTTypeGIF), // gif
        String(kUTTypeText), String(kUTTypePlainText), String(kUTTypeUTF8PlainText), // text start
        String(kUTTypeUTF16ExternalPlainText), String(kUTTypeUTF16PlainText),
        String(kUTTypeDelimitedText), String(kUTTypeRTF), // text end
        String(kUTTypeImage), String(kUTTypeJPEG), String(kUTTypeJPEG2000), // image start
        String(kUTTypeTIFF), String(kUTTypePICT), String(kUTTypePNG), String(kUTTypeQuickTimeImage),
        String(kUTTypeAppleICNS), String(kUTTypeBMP), String(kUTTypeICO), String(kUTTypeRawImage),
        String(kUTTypeScalableVectorGraphics), // image end
        String(kUTTypeMovie), String(kUTTypeVideo), String(kUTTypeQuickTimeMovie), // video start
        String(kUTTypeMPEG), String(kUTTypeMPEG2Video), String(kUTTypeMPEG2TransportStream),
        String(kUTTypeMPEG4), String(kUTTypeAppleProtectedMPEG4Video), String(kUTTypeAVIMovie),
        String(kUTTypeMPEG2Video),// video end
        String(kUTTypeAudiovisualContent), String(kUTTypeAudio), String(kUTTypeMP3), // audio start
        String(kUTTypeMPEG4Audio), String(kUTTypeAppleProtectedMPEG4Audio), String(kUTTypeAudioInterchangeFileFormat),
        String(kUTTypeWaveformAudio), String(kUTTypeMIDIAudio)] // audio end
    
    
    
    //var messages = [IGRoomMessage]()
    let sortProperties = [SortDescriptor(keyPath: "creationTime", ascending: false),
                          SortDescriptor(keyPath: "id", ascending: false)]
    let sortPropertiesForMedia = [SortDescriptor(keyPath: "creationTime", ascending: true),
                                  SortDescriptor(keyPath: "id", ascending: true)]
    var messages: Results<IGRoomMessage>! //try! Realm().objects(IGRoomMessage.self)
    var messagesWithMedia = try! Realm().objects(IGRoomMessage.self)
    var messagesWithForwardedMedia = try! Realm().objects(IGRoomMessage.self)
    var notificationToken: NotificationToken?
    
    var logMessageCellIdentifer = IGMessageLogCollectionViewCell.cellReuseIdentifier()
    var room : IGRoom?
    var privateRoom : IGRoom?
    var openChatFromLink: Bool = false // set true this param when user not joined to this room
    var customizeBackItem: Bool = false
    //let currentLoggedInUserID = IGAppManager.sharedManager.userID()
    let currentLoggedInUserAuthorHash = IGAppManager.sharedManager.authorHash()
    
    var selectedMessageToEdit: IGRoomMessage?
    var selectedMessageToReply: IGRoomMessage?
    static var selectedMessageToForwardToThisRoom: IGRoomMessage?
    static var selectedMessageToForwardFromThisRoom: IGRoomMessage?
    var currentAttachment: IGFile?
    var selectedUserToSeeTheirInfo: IGRegisteredUser?
    var selectedChannelToSeeTheirInfo: IGChannelRoom?
    var selectedGroupToSeeTheirInfo: IGGroupRoom?
    var hud = MBProgressHUD()
    let locationManager = CLLocationManager()
    
    let MAX_TEXT_LENGHT = 4096
    let MAX_TEXT_ATTACHMENT_LENGHT = 1024
    
    var botCommandsDictionary : [String:String] = [:]
    var botCommandsArray : [String] = []
    let BUTTON_HEIGHT = 50
    let BUTTON_SPACE = 10
    let BUTTON_ROW_SPACE : CGFloat = 5
    let screenWidth = UIScreen.main.bounds.width
    var isCustomKeyboard = false
    var isKeyboardButtonCreated = false
    let KEYBOARD_CUSTOM_ICON = ""
    let KEYBOARD_MAIN_ICON = ""
    let returnText = "/back"
    
    let ANIMATE_TIME = 0.2
    
    let DOCTOR_BOT_HEIGHT = 50 // height size for main doctor bot view (Hint: size of custom button is lower than this size -> (DOCTOR_BOT_HEIGHT - (2 * DOCTOR_BUTTON_VERTICAL_SPACE)) )
    let DOCTOR_BUTTON_VERTICAL_SPACE = 6 // space between top & bottom of a custom button with doctor bot parent view
    let DOCTOR_BUTTON_SPACE : CGFloat = 10 // space between each button
    let DOCOTR_IN_BUTTON_SPACE : CGFloat = 10 // space between button and image and mainView in a custom button
    let DOCTOR_IMAGE_SIZE : CGFloat = 25 // width and height size for image
    var leftSpace : CGFloat = 0 // space each button from start of scroll view (Hint: this value will be changed programatically)
    var apiStructArray : [IGPFavorite] = []
    
    /* variables for fetch message */
    var allMessages:Results<IGRoomMessage>!
    var getMessageLimit = 25
    var scrollToTopLimit:CGFloat = 20
    var messageSize = 0
    var page = 0
    var firstId:Int64 = 0
    var lastId:Int64 = 0
    
    var isEndOfScroll = false
    var lowerAllow = true
    var allowForGetHistoryLocal = true
    var isFirstHistory = true
    var hasLocal = true
    var isStickerKeyboard = false
    var isSendLocation : Bool!
    var receivedLocation : CLLocation!
    var stickerPageType = StickerPageType.MAIN
    var stickerGroupId: String!
    var latestIndexPath: IndexPath!
    
    var latestKeyboardAdditionalView: UIView!
    
    private var cellSizeLimit: CellSizeLimit!
    
    fileprivate var typingStatusExpiryTimer = Timer() //use this to send cancel for typing status
    internal static var additionalObserver: AdditionalObserver!
    internal static var messageViewControllerObserver: MessageViewControllerObserver!
    
    
    func onMessageViewControllerDetection() -> UIViewController {
        return self
    }
    
    func onNavigationControllerDetection() -> UINavigationController {
        return self.navigationController!
    }
    
    //MARK: - Initilizers
    override func viewDidLoad() {
        super.viewDidLoad()
        
        removeButtonsUnderline(buttons: [inputBarRecordButton, btnScrollToBottom, inputBarSendButton, btnCancelReplyOrForward, btnDeleteSelectedAttachment, btnClosePin, btnAttachment])
        
        IGAppManager.sharedManager.connectionStatus.asObservable().subscribe(onNext: { (connectionStatus) in
            DispatchQueue.main.async {
                self.updateConnectionStatus(connectionStatus)
                
            }
        }, onError: { (error) in
            
        }, onCompleted: {
            
        }, onDisposed: {
            
        }).disposed(by: disposeBag)
        
        /*
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.tapOnMainView))
        mainView.addGestureRecognizer(gesture)
        */
        
        self.addNotificationObserverForTapOnStatusBar()
        var canBecomeFirstResponder: Bool { return true }
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.setNavigationBarForRoom(room!)
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self
        navigationItem.rightViewContainer?.addAction {
            if self.room?.type == .chat {
                self.selectedUserToSeeTheirInfo = (self.room?.chatRoom?.peer)!
                self.openUserProfile()
            }
            if self.room?.type == .channel {
                self.selectedChannelToSeeTheirInfo = self.room?.channelRoom
                //self.performSegue(withIdentifier: "showChannelinfo", sender: self)
                
                let profile = IGChannelInfoTableViewController.instantiateFromAppStroryboard(appStoryboard: .Profile)
                profile.selectedChannel = self.selectedChannelToSeeTheirInfo
                profile.room = self.room
                self.navigationController!.pushViewController(profile, animated: true)
            }
            if self.room?.type == .group {
                self.selectedGroupToSeeTheirInfo = self.room?.groupRoom
                //self.performSegue(withIdentifier: "showGroupInfo", sender: self)
                
                let profile = IGGroupInfoTableViewController.instantiateFromAppStroryboard(appStoryboard: .Profile)
                profile.selectedGroup = self.selectedGroupToSeeTheirInfo
                profile.room = self.room
                self.navigationController!.pushViewController(profile, animated: true)
            }
            
        }
        navigationItem.centerViewContainer?.addAction {
            if self.room?.type == .chat {
                self.selectedUserToSeeTheirInfo = (self.room?.chatRoom?.peer)!
                self.openUserProfile()
            } else {
                
            }
        }
        
        if customizeBackItem {
            navigationItem.backViewContainer?.addAction {
                // if call page is enable set "isFirstEnterToApp" true for open "IGRecentsTableViewController" automatically
                AppDelegate.isFirstEnterToApp = true
                self.performSegue(withIdentifier: "showRoomList", sender: self)
            }
        }
        
        if room!.isReadOnly {
            if room!.isParticipant == false {
                inputBarContainerView.isHidden = true
                joinButton.isHidden = false
            } else {
                inputBarContainerView.isHidden = true
                collectionViewTopInsetOffset = -54.0 + 8.0
            }
        }
        
        if isBotRoom() {
            txtSticker.isHidden = true
            if IGHelperDoctoriGap.isDoctoriGapRoom(room: room!) {
                self.getFavoriteMenu()
            }
            
            let predicate = NSPredicate(format: "roomId = %lld AND (id >= %lld OR statusRaw == %d OR statusRaw == %d) AND isDeleted == false AND id != %lld" , self.room!.id, lastId ,0 ,1 ,0)
            let messagesCount = try! Realm().objects(IGRoomMessage.self).filter(predicate).count
            if messagesCount == 0 {
                inputBarContainerView.isHidden = true
                joinButton.isHidden = false
                joinButton.setTitle("Start", for: UIControl.State.normal)
                joinButton.layer.cornerRadius = 5
                joinButton.layer.masksToBounds = false
                joinButton.layer.shadowColor = UIColor.black.cgColor
                joinButton.layer.shadowOffset = CGSize(width: 0, height: 0)
                joinButton.layer.shadowRadius = 4.0
                joinButton.layer.shadowOpacity = 0.15
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.manageKeyboard(firstEnter: true)
                }
            }
        }
        
        let messagesWithMediaPredicate = NSPredicate(format: "roomId = %lld AND isDeleted == false AND (typeRaw = %d OR typeRaw = %d OR forwardedFrom.typeRaw = %d OR forwardedFrom.typeRaw = %d)", self.room!.id, IGRoomMessageType.image.rawValue, IGRoomMessageType.imageAndText.rawValue, IGRoomMessageType.image.rawValue, IGRoomMessageType.imageAndText.rawValue)
        messagesWithMedia = try! Realm().objects(IGRoomMessage.self).filter(messagesWithMediaPredicate).sorted(by: sortPropertiesForMedia)
        
        let messagesWithForwardedMediaPredicate = NSPredicate(format: "roomId = %lld AND isDeleted == false AND (forwardedFrom.typeRaw == 1 OR forwardedFrom.typeRaw == 2 OR forwardedFrom.typeRaw == 3 OR forwardedFrom.typeRaw == 4)", self.room!.id)
        messagesWithForwardedMedia = try! Realm().objects(IGRoomMessage.self).filter(messagesWithForwardedMediaPredicate).sorted(by: sortPropertiesForMedia)
        
        self.collectionView.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
        self.collectionView.delaysContentTouches = false
        self.collectionView.keyboardDismissMode = .none
        self.collectionView.dataSource = self
        self.collectionView.delegate = self


        let bgColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        
        self.view.backgroundColor = bgColor
        self.view.superview?.backgroundColor = bgColor
        self.view.superview?.superview?.backgroundColor = bgColor
        self.view.superview?.superview?.superview?.backgroundColor = bgColor
        self.view.superview?.superview?.superview?.superview?.backgroundColor = bgColor

        
        let inputTextViewInitialHeight:CGFloat = 22.0 //initial without reply || forward || attachment || text
        self.inputTextViewHeight = inputTextViewInitialHeight
        self.setInputBarHeight()
        self.managePinnedMessage()
        
        inputTextView.delegate = self
        inputTextView.placeholder = "Message"
        inputTextView.placeholderColor = UIColor(red: 173.0/255.0, green: 173.0/255.0, blue: 173.0/255.0, alpha: 1.0)
        inputTextView.maxHeight = 166.0 // almost 8 lines
        inputTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        inputTextView.layer.borderColor = UIColor.gray.cgColor
        inputTextView.layer.borderWidth = 0.4
        inputTextView.layer.cornerRadius = 6.0
        inputTextView.layer.masksToBounds = true
        
        inputBarLeftView.layer.cornerRadius = 6.0//19.0
        inputBarLeftView.layer.masksToBounds = true
        inputBarRightiew.layer.cornerRadius = 6.0//19.0
        inputBarRightiew.layer.masksToBounds = true
        
        
        inputBarBackgroundView.layer.cornerRadius = 6.0//19.0
        inputBarBackgroundView.layer.masksToBounds = false
        inputBarBackgroundView.layer.shadowColor = UIColor.black.cgColor
        inputBarBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 0)
        inputBarBackgroundView.layer.shadowRadius = 4.0
        inputBarBackgroundView.layer.shadowOpacity = 0.15
        inputBarBackgroundView.layer.borderColor = UIColor(red: 209.0/255.0, green: 209.0/255.0, blue: 209.0/255.0, alpha: 1.0).cgColor
        inputBarBackgroundView.layer.borderWidth  = 1.0
        
        inputBarView.layer.cornerRadius = 6.0//19.0
        inputBarView.layer.masksToBounds = true
        inputBarView.layer.backgroundColor = inputBarLeftView.backgroundColor?.cgColor
        
        inputBarRecordView.layer.cornerRadius = 6.0//19.0
        inputBarRecordView.layer.masksToBounds = false
        inputBarRecodingBlinkingView.layer.cornerRadius = 8.0
        inputBarRecodingBlinkingView.layer.masksToBounds = false
        inputBarRecordRightView.layer.cornerRadius = 6.0//19.0
        inputBarRecordRightView.layer.masksToBounds = false
        
        inputBarRecordView.isHidden = true
        inputBarRecodingBlinkingView.isHidden = true
        inputBarRecordRightView.isHidden = true
        inputBarRecordTimeLabel.isHidden = true
        inputBarRecordTimeLabel.alpha = 0.0
        inputBarRecordViewLeftConstraint.constant = 200
        
        
        scrollToBottomContainerView.layer.cornerRadius = 20.0
        scrollToBottomContainerView.layer.masksToBounds = false
        scrollToBottomContainerView.layer.shadowColor = UIColor.black.cgColor
        scrollToBottomContainerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        scrollToBottomContainerView.layer.shadowRadius = 4.0
        scrollToBottomContainerView.layer.shadowOpacity = 0.15
        scrollToBottomContainerView.backgroundColor = UIColor.white
        scrollToBottomContainerView.isHidden = true
        
        floatingDateView.layer.cornerRadius = 12.0
        floatingDateView.alpha = 0.0
        txtFloatingDate.alpha = 0.0
        
        txtPinnedMessage.lineBreakMode = .byTruncatingTail
        txtPinnedMessage.numberOfLines = 1
        
        self.setCollectionViewInset()
        //Keyboard Notification
        
        notification(register: true)
        //sendMessageState(enable: false)

        let tapInputTextView = UITapGestureRecognizer(target: self, action: #selector(didTapOnInputTextView))
        inputTextView.addGestureRecognizer(tapInputTextView)
        inputTextView.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapOnStickerButton))
        txtSticker.addGestureRecognizer(tap)
        txtSticker.isUserInteractionEnabled = true
        
        let tapAndHoldOnRecord = UILongPressGestureRecognizer(target: self, action: #selector(didTapAndHoldOnRecord(_:)))
        tapAndHoldOnRecord.minimumPressDuration = 0.5
        inputBarRecordButton.addGestureRecognizer(tapAndHoldOnRecord)
        
        messages = findAllMessages()
        updateObserver()
        
        if messages.count == 0 {
            fetchRoomHistoryWhenDbIsClear()
        }
    }
    
    @objc @available(iOS 10.0, *)
    private func openStickerView(){
        let viewController:UIViewController
        viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: IGStickerViewController.self)) as! IGStickerViewController
        
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        addChild(viewController)
        
        viewController.view.frame = view.bounds
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.inputTextView.inputView = viewController.view
        
        let viewCustom = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        viewCustom.backgroundColor = UIColor.dialogueBoxOutgoing()
        
        let stickerToolbar = IGStickerToolbar()
        let scrollView = stickerToolbar.toolbarMaker()//view
        self.inputTextView.inputAccessoryView = scrollView
        
        self.inputTextView.reloadInputViews()
        if !self.inputTextView.isFirstResponder {
            self.inputTextView.becomeFirstResponder()
        }
        
        viewController.view.snp.makeConstraints { (make) in
            make.left.equalTo((self.inputTextView.inputView?.snp.left)!)
            make.right.equalTo((self.inputTextView.inputView?.snp.right)!)
            make.bottom.equalTo((self.inputTextView.inputView?.snp.bottom)!)
            make.top.equalTo((self.inputTextView.inputView?.snp.top)!)
        }
        
        viewController.didMove(toParent: self)
    }
    
    @objc func tapOnStickerToolbar(sender: UIButton) {
        if #available(iOS 10.0, *) {
            if let observer = IGStickerViewController.stickerToolbarObserver {
                
                switch sender.tag {
                case IGStickerToolbar.shared.STICKER_ADD:
                    stickerPageType = StickerPageType.ADD_REMOVE
                    if let observer = IGStickerViewController.stickerCurrentGroupIdObserver {
                        IGStickerViewController.currentStickerGroupId = observer.fetchCurrentStickerGroupId()
                    }
                    performSegue(withIdentifier: "showSticker", sender: self)
                    break
                    
                case IGStickerToolbar.shared.STICKER_SETTING:
                    disableStickerView(delay: 0.0)
                    break
                    
                default:
                    observer.onToolbarClick(index: sender.tag)
                    break
                }
            }
        }
    }
    
    func onStickerTap(stickerItem: IGRealmStickerItem) {
        
        if let attachment = IGAttachmentManager.sharedManager.getFileInfo(token: stickerItem.token!) {
            let message = IGRoomMessage(body: stickerItem.name!)
            message.type = .sticker
            message.roomId = self.room!.id
            message.attachment = attachment
            message.additional = IGRealmAdditional(additionalData: IGHelperJson.convertRealmToJson(stickerItem: stickerItem)!, additionalType: AdditionalType.STICKER.rawValue)
            IGAttachmentManager.sharedManager.add(attachment: attachment)
            
            let detachedMessage = message.detach()
            IGFactory.shared.saveNewlyWriitenMessageToDatabase(detachedMessage)
            message.repliedTo = self.selectedMessageToReply // Hint: if use this line before "saveNewlyWriitenMessageToDatabase" app will be crashed
            IGMessageSender.defaultSender.sendSticker(message: message, to: self.room!)
            
            self.sendMessageState(enable: false)
            self.inputTextView.text = ""
            self.currentAttachment = nil
            IGMessageViewController.selectedMessageToForwardToThisRoom = nil
            self.selectedMessageToReply = nil
            self.setInputBarHeight()
        } else {
            IGAttachmentManager.sharedManager.getStickerFileInfo(token: stickerItem.token!, completion: { (attachment) -> Void in })
        }
    }
    
    @objc func keyboardWillAppear() {
        //Do something here
    }
    
    @objc func keyboardWillDisappear() {
        disableStickerView(delay: 0.4)
        if isBotRoom() {
            self.collectionView.reloadData()
        }
    }
    
    @objc func tapOnMainView(sender : UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    private func getFavoriteMenu(){
        IGClientGetFavoriteMenuRequest.Generator.generate().success ({ (responseProtoMessage) in
            if let favoriteResponse = responseProtoMessage as? IGPClientGetFavoriteMenuResponse {
                DispatchQueue.main.async {
                    let results = favoriteResponse.igpFavorites
                    if results.count == 0 {
                        return
                    }
                    
                    if self.room!.isReadOnly {
                        self.collectionViewTopInsetOffset = 0
                    } else {
                        self.collectionViewTopInsetOffset = CGFloat(self.DOCTOR_BOT_HEIGHT)
                    }
                    
                    self.apiStructArray = results
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                        self.doctorBotView(results: results)
                    }
                    
                    self.setCollectionViewInset(withDuration: 0.9)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                        self.collectionView.setContentOffset(CGPoint(x: 0, y: -self.collectionView.contentInset.top) , animated: true)
                    }
                }
            }
        }).error({ (errorCode, waitTime) in
            switch errorCode {
            case .timeout:
                self.getFavoriteMenu()
            default:
                break
            }
        }).send()
    }
    
    private func doctorBotView(results: [IGPFavorite]){
        
        doctorBotScrollView = UIScrollView()
        let child = UIView()
        
        doctorBotScrollView.showsHorizontalScrollIndicator = false
        doctorBotScrollView.backgroundColor = UIColor.clear
        doctorBotScrollView.frame = CGRect(x: 0, y: 0, width: Int(screenWidth), height: DOCTOR_BOT_HEIGHT)
        doctorBotScrollView.layer.cornerRadius = 8
        
        self.view.addSubview(doctorBotScrollView)
        doctorBotScrollView.addSubview(child)
        
        doctorBotScrollView.snp.makeConstraints { (make) in
            make.left.equalTo(self.view.snp.left).offset(7)
            make.right.equalTo(self.view.snp.right).offset(-7)
            if (room?.isReadOnly)! {
                make.bottom.equalTo(self.view.snp.bottom).offset(-5)
            } else {
                make.bottom.equalTo(inputBarContainerView.snp.top)
            }
            make.height.equalTo(DOCTOR_BOT_HEIGHT)
        }
        
        leftSpace = DOCTOR_BUTTON_SPACE
        
        for result in results {
            makeDoctorBotButtonView(parent: doctorBotScrollView, result: result)
        }
        
        child.snp.makeConstraints { (make) in
            make.top.equalTo(doctorBotScrollView.snp.top)
            make.left.equalTo(doctorBotScrollView.snp.left)
            make.right.equalTo(doctorBotScrollView.snp.right)
            make.bottom.equalTo(doctorBotScrollView.snp.bottom)
            make.width.equalTo(leftSpace)
        }
    }
    
    private func makeDoctorBotButtonView(parent: UIView, result: IGPFavorite){
        let text : String = result.igpName
        let textColor : UIColor = UIColor(hexString: "#\(result.igpTextcolor)")
        let backgroundColor : UIColor = UIColor(hexString: "#\(result.igpBgcolor)")
        let imageData = Data(base64Encoded: result.igpImage)
        var hasImage = true
        
        if result.igpImage.isEmpty {
            hasImage = false
        }
        
        let font = UIFont.igFont(ofSize: 17.0)
        let textWidth = text.width(withConstrainedHeight: CGFloat(DOCTOR_BOT_HEIGHT), font: font)
        var mainViewWith : CGFloat = 0
        
        let mainView = UIView()
        mainView.alpha = 0.0
        parent.addSubview(mainView)
        
        let btn = UIButton()
        mainView.addSubview(btn)
        
        var img : UIImageView!
        if hasImage {
            img = UIImageView()
            mainView.addSubview(img)
            
            mainViewWith = DOCTOR_IMAGE_SIZE + (3 * DOCOTR_IN_BUTTON_SPACE) + textWidth
        } else {
            mainViewWith = (2 * DOCOTR_IN_BUTTON_SPACE) + textWidth
        }
        
        /***** Main View *****/
        mainView.backgroundColor = backgroundColor
        mainView.layer.masksToBounds = false
        mainView.layer.cornerRadius = 20.0
        mainView.layer.shadowOffset = CGSize(width: -2, height: 3)
        mainView.layer.shadowRadius = 3.0
        mainView.layer.shadowOpacity = 0.3
        mainView.snp.makeConstraints { (make) in
            make.top.equalTo(parent.snp.top).offset(DOCTOR_BUTTON_VERTICAL_SPACE)
            make.bottom.equalTo(parent.snp.bottom).offset(DOCTOR_BUTTON_VERTICAL_SPACE)
            make.centerY.equalTo(parent.snp.centerY)
            make.left.equalTo(leftSpace)
            make.width.equalTo(mainViewWith)
        }

        
        /***** Button View *****/
        btn.addTarget(self, action: #selector(onDoctorBotClick), for: .touchUpInside)
        btn.titleLabel?.font = font
        btn.setTitle(text, for: UIControl.State.normal)
        btn.setTitleColor(textColor, for: UIControl.State.normal)
        btn.removeUnderline()
        
        btn.snp.makeConstraints { (make) in
            make.top.equalTo(mainView.snp.top)
            make.bottom.equalTo(mainView.snp.bottom)
            make.right.equalTo(mainView.snp.right).offset(-DOCOTR_IN_BUTTON_SPACE)
            make.centerY.equalTo(mainView.snp.centerY)
            if hasImage {
                make.left.equalTo(img.snp.right).offset(DOCOTR_IN_BUTTON_SPACE)
            } else {
                make.left.equalTo(mainView.snp.left).offset(DOCOTR_IN_BUTTON_SPACE)
            }
        }
        
        
        /***** Image View *****/
        if hasImage && imageData != nil {
            if let image = UIImage(data: imageData!) {
                img.image = image
            }
            
            img.snp.makeConstraints { (make) in
                make.left.equalTo(mainView.snp.left).offset(DOCOTR_IN_BUTTON_SPACE)
                make.centerY.equalTo(mainView.snp.centerY)
                make.width.equalTo(DOCTOR_IMAGE_SIZE)
                make.height.equalTo(DOCTOR_IMAGE_SIZE)
            }
        }
        
        mainView.fadeIn(1)
        
        leftSpace += DOCTOR_BUTTON_SPACE + mainViewWith
    }
    
    @objc func onDoctorBotClick(sender: UIButton!) {
        let value : String! = detectBotValue(name: sender.titleLabel?.text!)
        
        if value.starts(with: "$financial") {
            IGHelperFinancial.getInstance(viewController: self).manageFinancialServiceChoose()
        } else if value.starts(with: "@") {
            if let username = IGRoom.fetchUsername(room: room!) { // if username is for current room don't open this room again
                if username == value.dropFirst() {
                    return
                }
            }
            IGHelperChatOpener.checkUsernameAndOpenRoom(viewController: self, username: value)
        } else {
            inputTextView.text = value
            self.didTapOnSendButton(self.inputBarSendButton)
        }
    }
    
    func detectBotValue(name: String?) -> String? {
        if name != nil {
            for apiStruct in apiStructArray {
                if apiStruct.igpName == name {
                    return apiStruct.igpValue
                }
            }
        }
        
        return nil
    }
    
    func isBotRoom() -> Bool{
        if !(room?.isInvalidated)!, let chatRoom = room?.chatRoom {
            return (chatRoom.peer?.isBot)!
        }
        return false
    }
    
    private func makeKeyboardButton(){
        
        if btnChangeKeyboard != nil {
            return
        }
        
        btnChangeKeyboard = UIButton()
        btnChangeKeyboard.isHidden = false
        btnChangeKeyboard.addTarget(self, action: #selector(onKeyboardChangeClick), for: .touchUpInside)
        btnChangeKeyboard.titleLabel?.font = UIFont.iGapFontico(ofSize: 18.0)
        btnChangeKeyboard.setTitleColor(UIColor.iGapColor(), for: UIControl.State.normal)
        btnChangeKeyboard.backgroundColor = inputBarLeftView.backgroundColor
        btnChangeKeyboard.layer.masksToBounds = false
        btnChangeKeyboard.layer.cornerRadius = 5.0
        self.view.addSubview(btnChangeKeyboard)
        
        btnChangeKeyboard.snp.makeConstraints { (make) in
            make.right.equalTo(inputBarRightiew.snp.left)
            make.centerY.equalTo(inputBarRightiew.snp.centerY)
            make.width.equalTo(33)
            make.height.equalTo(33)
        }
        
        inputTextView.snp.makeConstraints { (make) in
            make.right.equalTo(btnChangeKeyboard.snp.left)
            make.left.equalTo(inputBarLeftView.snp.right)
        }
    }
    
    private func removeKeyboardButton(){
        
        if btnChangeKeyboard == nil {
            return
        }
        
        btnChangeKeyboard.removeFromSuperview()
        btnChangeKeyboard.isHidden = true
        btnChangeKeyboard = nil
        inputTextView.snp.makeConstraints { (make) in
            make.right.equalTo(inputBarRightiew.snp.left)
            make.left.equalTo(inputBarLeftView.snp.right)
        }
    }
    
    private func manageKeyboard(firstEnter: Bool = false){
        if !isBotRoom() {return}
        
        if !self.joinButton.isHidden {
            self.joinButton.isHidden = true
            self.inputBarContainerView.isHidden = false
        }
        
        if let chatRoom = self.room?.chatRoom {
            if (chatRoom.peer?.isBot)! {
                let predicate = NSPredicate(format: "roomId = %lld AND isDeleted == false AND id != %lld", self.room!.id, 0)
                let latestMessage = try! Realm().objects(IGRoomMessage.self).filter(predicate).last
                
                let additionalData = getAdditional(roomMessage: latestMessage)
                
                if !self.inputTextView.isFirstResponder {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.collectionView.reloadData()
                    }
                }
                
                if additionalData != nil {
                    self.makeKeyboardButton()
                    isCustomKeyboard = true
                    btnChangeKeyboard.setTitle(KEYBOARD_MAIN_ICON, for: UIControl.State.normal)
                    latestKeyboardAdditionalView = IGHelperBot.shared.makeBotView(additionalArrayMain: additionalData!, isKeyboard: true)
                    self.inputTextView.inputView = latestKeyboardAdditionalView
                    self.inputTextView.reloadInputViews()
                    if !self.inputTextView.isFirstResponder {
                        self.inputTextView.becomeFirstResponder()
                    }
                } else {
                    if additionalData == nil {
                        self.removeKeyboardButton()
                    }
                    isCustomKeyboard = false
                    if btnChangeKeyboard != nil {
                        btnChangeKeyboard.setTitle(KEYBOARD_CUSTOM_ICON, for: UIControl.State.normal)
                    }
                    inputTextView.inputView = nil
                    inputTextView.reloadInputViews()
                }
            }
        }
    }
    
    private func getAdditional(roomMessage: IGRoomMessage?) -> [[IGStructAdditionalButton]]? {
        if roomMessage != nil && roomMessage!.authorUser?.id != IGAppManager.sharedManager.userID(),
            let data = roomMessage?.additional?.data,
            roomMessage?.additional?.dataType == AdditionalType.UNDER_KEYBOARD_BUTTON.rawValue,
            let additionalData = IGHelperJson.parseAdditionalButton(data: data) {
            return additionalData
        }
        return nil
    }

    /* overrided method */
    func onAdditionalSendMessage(structAdditional: IGStructAdditionalButton) {
        let message = IGRoomMessage(body: structAdditional.label)
        message.additional = IGRealmAdditional(additionalData: structAdditional.json, additionalType: 3)
        let detachedMessage = message.detach()
        IGFactory.shared.saveNewlyWriitenMessageToDatabase(detachedMessage)
        IGMessageSender.defaultSender.send(message: message, to: room!)
    }
    
    func onAdditionalLinkClick(structAdditional: IGStructAdditionalButton) {
       openWebView(url: structAdditional.value)
    }
    
    func onAdditionalRequestPhone(structAdditional :IGStructAdditionalButton){
        manageRequestPhone()
    }
    
    func onAdditionalRequestLocation(structAdditional :IGStructAdditionalButton){
        openLocation()
    }
    
    func onBotClick(){
        self.collectionView.setContentOffset(CGPoint(x: 0, y: -self.collectionView.contentInset.top) , animated: false)
    }
    
    private func manageRequestPhone(){
        self.view.endEditing(true)
        if let roomTitle = self.room?.title {
            let alert = UIAlertController(title: nil, message: "there is a request to access your phone number from \(roomTitle) . do you allow?", preferredStyle: IGGlobal.detectAlertStyle())
            
            let sendPhone = UIAlertAction(title: "Send Phone", style: .default, handler: { (action) in
                if let userId = IGAppManager.sharedManager.userID(), let userInfo = IGRegisteredUser.getUserInfo(id: userId) {
                    self.inputTextView.text = String(describing: userInfo.phone)
                    self.didTapOnSendButton(self.inputBarSendButton)
                }
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(sendPhone)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func onKeyboardChangeClick(){
        guard let additionalView = latestKeyboardAdditionalView else {
            return
        }
        
        if !isCustomKeyboard {
            isCustomKeyboard = true
            btnChangeKeyboard.setTitle(KEYBOARD_MAIN_ICON, for: UIControl.State.normal)
            self.inputTextView.inputView = additionalView
        } else {
            isCustomKeyboard = false
            btnChangeKeyboard.setTitle(KEYBOARD_CUSTOM_ICON, for: UIControl.State.normal)
            inputTextView.inputView = nil
        }
        
        self.inputTextView.reloadInputViews()
        if !self.inputTextView.isFirstResponder {
            self.inputTextView.becomeFirstResponder()
        }
    }
    
    private func myLastMessage() -> IGRoomMessage? {
        if let authorHash = IGAppManager.sharedManager.authorHash() {
            let predicate = NSPredicate(format: "roomId = %lld AND isDeleted == false AND authorHash CONTAINS[cd] %@ AND id != %lld", self.room!.id, authorHash,0)
            return try! Realm().objects(IGRoomMessage.self).filter(predicate).last
        }
        return nil
    }
    
    private func setBackground() {
        
        if let color = IGWallpaperPreview.chatSolidColor {
            chatBackground.image = nil
            chatBackground.backgroundColor = UIColor.hexStringToUIColor(hex: color)
        } else if let wallpaper = IGWallpaperPreview.chatWallpaper {
            chatBackground.image = UIImage(data: wallpaper as Data)
        } else {
            if IGGlobal.hasBigScreen() {
                chatBackground.image = UIImage(named: "iGap-Chat-BG-H")
            } else {
                chatBackground.image = UIImage(named: "iGap-Chat-BG-V")
            }
        }
    }
    
    private func removeButtonsUnderline(buttons: [UIButton]){
        for btn in buttons {
            btn.removeUnderline()
        }
    }
    
    func openUserProfile(){
        let profile = IGRegistredUserInfoTableViewController.instantiateFromAppStroryboard(appStoryboard: .Profile)
        profile.user = self.selectedUserToSeeTheirInfo
        profile.previousRoomId = self.room?.id
        profile.room = self.room
        self.navigationController!.pushViewController(profile, animated: true)
    }
    
    func updateObserver(){
        self.notificationToken = messages?.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                break
            case .update(_, let deletions, let insertions, let modifications):
                
                for cellsPosition in modifications {
                    if self.collectionView.indexPathsForVisibleItems.contains(IndexPath(row: 0, section: cellsPosition)) {
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                        break
                    }
                }
                
                if insertions.count > 0 || deletions.count > 0 {
                    
                    if self.isEndOfScroll && self.collectionView.numberOfSections > 100 {
                        self.resetGetHistoryValues()
                        self.messages = self.findAllMessages()
                    } else {
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                    }
                    
                    self.manageKeyboard()
                }
                
                break
            case .error(let err):
                fatalError("\(err)")
                break
            }
        }
    }
    
    func findAllMessages(isHistory: Bool = false) -> Results<IGRoomMessage>!{
        
        if lastId == 0 {
            let predicate = NSPredicate(format: "roomId = %lld AND isDeleted == false AND id != %lld", self.room!.id, 0)
            allMessages = try! Realm().objects(IGRoomMessage.self).filter(predicate).sorted(by: sortProperties)
            
            let messageCount = allMessages.count
            if messageCount == 0 {
                return allMessages
            }
            
            firstId = allMessages.toArray()[0].id
            
            if messageCount <= getMessageLimit {
                hasLocal = false
                scrollToTopLimit = 500
                lastId = allMessages.toArray()[allMessages.count-1].id
            } else {
                lastId = allMessages.toArray()[getMessageLimit].id
            }
            
        } else {
            page += 1
            
            if page > 1 {
                getMessageLimit = 100
            }
            
            let messageLimit = page * getMessageLimit
            let messageCount = allMessages.count
            
            if messageCount <= messageLimit {
                hasLocal = false
                scrollToTopLimit = 500
                lastId = allMessages.toArray()[allMessages.count-1].id
            } else {
                lastId = allMessages.toArray()[messageLimit].id
            }
        }
        
        let predicate = NSPredicate(format: "roomId = %lld AND (id >= %lld OR statusRaw == %d OR statusRaw == %d) AND isDeleted == false AND id != %lld" , self.room!.id, lastId ,0 ,1 ,0)
        let messages = try! Realm().objects(IGRoomMessage.self).filter(predicate).sorted(by: sortProperties)
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
        return messages
    }
    
    /* reset values for get history from first */
    func resetGetHistoryValues(){
        lastId = 0
        page = 0
        getMessageLimit = 50
        scrollToTopLimit = 20
        hasLocal = true
    }
    
    
    /* delete all local messages before first message that have shouldFetchBefore==true */
    func deleteUnusedLocalMessage(){
        let predicate = NSPredicate(format: "roomId = %lld AND shouldFetchBefore == true", self.room!.id)
        let message = try! Realm().objects(IGRoomMessage.self).filter(predicate).sorted(by: sortProperties).last
        
        var deleteId:Int64 = 0
        if let id = message?.id {
            deleteId = id
        }
        
        let predicateDelete = NSPredicate(format: "roomId = %lld AND id <= %lld", self.room!.id , deleteId)
        let messageDelete = try! Realm().objects(IGRoomMessage.self).filter(predicateDelete).sorted(by: sortProperties)
        
        let realm = try! Realm()
        try! realm.write {
            realm.delete(messageDelete)
        }
    }
    
    private func getUserInfo(){
        guard !(room?.isInvalidated)!, let userId = self.room?.chatRoom?.peer?.id else {
            return
        }
        
        IGUserInfoRequest.Generator.generate(userID: userId).success({ (protoResponse) in
            if let userInfoResponse = protoResponse as? IGPUserInfoResponse {
                IGUserInfoRequest.Handler.interpret(response: userInfoResponse)
            }
        }).error({ (errorCode, waitTime) in
            switch errorCode {
            case .timeout:
                self.getUserInfo()
            default:
                break
            }
        }).send()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        CellSizeLimit.updateValues(roomId: (self.room?.id)!)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        getUserInfo()
        setBackground()
        
        if let forwardMsg = IGMessageViewController.selectedMessageToForwardToThisRoom {
            self.forwardOrReplyMessage(forwardMsg, isReply: false)
        }
        
        if let draft = self.room!.draft {
            if draft.message != "" || draft.replyTo != -1 {
                inputTextView.text = draft.message
                inputTextView.placeholder = "Message"
                if draft.replyTo != -1 {
                    let predicate = NSPredicate(format: "id = %lld AND roomId = %lld", draft.replyTo, self.room!.id)
                    if let replyToMessage = try! Realm().objects(IGRoomMessage.self).filter(predicate).first {
                        forwardOrReplyMessage(replyToMessage)
                    }
                }
                setSendAndRecordButtonStates()
            }
        }
        notification(register: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        IGMessageViewController.messageViewControllerObserver = self
        IGMessageViewController.additionalObserver = self
        if #available(iOS 10.0, *) {
            IGStickerViewController.stickerTapListener = self
        }
        IGRecentsTableViewController.visibleChat[(room?.id)!] = true
        IGAppManager.sharedManager.currentMessagesNotificationToekn = self.notificationToken
        let navigationItem = self.navigationItem as! IGNavigationItem
        if let roomVariable = IGRoomManager.shared.varible(for: room!) {
            roomVariable.asObservable().subscribe({ (event) in
                if event.element == self.room! {
                    DispatchQueue.main.async {
                        navigationItem.updateNavigationBarForRoom(event.element!)
                        
                    }
                }
            }).disposed(by: disposeBag)
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) in }
        
        setMessagesRead()
        manageStickerPosition()
        IGHelperGetMessageState.shared.clearMessageViews()
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        if !inputBarOriginalMessageView.isHidden { // maybe has forward
            IGMessageViewController.selectedMessageToForwardToThisRoom = nil
        }
        self.view.endEditing(true)
        super.viewWillDisappear(animated)
        IGRecentsTableViewController.visibleChat[(room?.id)!] = false
        IGAppManager.sharedManager.currentMessagesNotificationToekn = nil
        self.sendCancelTyping()
        self.sendCancelRecoringVoice()
        if let room = self.room, !room.isInvalidated {
            room.saveDraft(inputTextView.text, replyToMessage: selectedMessageToReply)
            IGFactory.shared.markAllMessagesAsRead(roomId: room.id)
            if openChatFromLink { // TODO - also check if user before joined to this room don't send this request
                sendUnsubscribForRoom(roomId: room.id)
                IGFactory.shared.updateRoomParticipant(roomId: room.id, isParticipant: false)
            }
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        if notificationToken != nil {
            notificationToken?.invalidate()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.collectionView!.collectionViewLayout.invalidateLayout()
    }
    
    private func sendUnsubscribForRoom(roomId: Int64){
        IGClientUnsubscribeFromRoomRequest.Generator.generate(roomId: roomId).success { (responseProtoMessage) in
            }.error({ (errorCode, waitTime) in
                switch errorCode {
                case .timeout:
                    self.sendUnsubscribForRoom(roomId: roomId)
                default:
                    break
                }
            }).send()
    }
    
    //MARK - Send Seen Status
    private func setMessagesRead() {
        if let room = self.room {
            IGFactory.shared.markAllMessagesAsRead(roomId: room.id)
        }
        self.messages!.forEach{
            if let authorHash = $0.authorHash {
                if authorHash != self.currentLoggedInUserAuthorHash! {
                    self.sendSeenForMessage($0)
                }
            }
        }
    }
    
    private func sendSeenForMessage(_ message: IGRoomMessage) {
        if message.authorHash == IGAppManager.sharedManager.authorHash() || message.status == .seen {
            return
        }
        switch self.room!.type {
        case .chat:
            if IGRecentsTableViewController.visibleChat[(room?.id)!]! {
                IGChatUpdateStatusRequest.Generator.generate(roomID: self.room!.id, messageID: message.id, status: .seen).success({ (responseProto) in
                    switch responseProto {
                    case let response as IGPChatUpdateStatusResponse:
                        IGChatUpdateStatusRequest.Handler.interpret(response: response)
                    default:
                        break
                    }
                }).error({ (errorCode, waitTime) in
                    
                }).send()
            }
        case .group:
            if IGRecentsTableViewController.visibleChat[(room?.id)!]! {
                IGGroupUpdateStatusRequest.Generator.generate(roomID: self.room!.id, messageID: message.id, status: .seen).success({ (responseProto) in
                    switch responseProto {
                    case let response as IGPGroupUpdateStatusResponse:
                        IGGroupUpdateStatusRequest.Handler.interpret(response: response)
                    default:
                        break
                    }
                }).error({ (errorCode, waitTime) in
                    
                }).send()
            }
            break
        case .channel:
            /*
            if IGRecentsTableViewController.visibleChat[(room?.id)!]! {
                if let message = self.messages?.last {
                    IGChannelGetMessagesStatsRequest.Generator.generate(messages: [message], room: self.room!).success({ (responseProto) in
                        
                    }).error({ (errorCode, waitTime) in
                        
                    }).send()
                }
            }
            */
            break
        }
    }
    
    /* if send message state is enable show send button and hide sticker & record button */
    private func sendMessageState(enable: Bool){
        
        if enable {
            
            if inputBarRecordButton.isHidden {
                return
            }
            
            UIView.transition(with: self.inputBarRecordButton, duration: ANIMATE_TIME, options: .transitionFlipFromBottom, animations: {
                self.inputBarRecordButton.isHidden = true
            }, completion: { (completed) in
                
                UIView.transition(with: self.inputBarSendButton, duration: self.ANIMATE_TIME, options: .transitionFlipFromTop, animations: {
                    self.inputBarSendButton.isHidden = false
                }, completion: nil)
            })
            
            
            UIView.transition(with: self.txtSticker, duration: ANIMATE_TIME, options: .transitionFlipFromBottom, animations: {
                self.txtSticker.isHidden = true
            }, completion: nil)

        } else {
            
            UIView.transition(with: self.inputBarSendButton, duration: ANIMATE_TIME, options: .transitionFlipFromBottom, animations: {
                self.inputBarSendButton.isHidden = true
            }, completion: { (completed) in
                
                UIView.transition(with: self.inputBarRecordButton, duration: self.ANIMATE_TIME, options: .transitionFlipFromTop, animations: {
                    self.inputBarRecordButton.isHidden = false
                }, completion: nil)
                
                UIView.transition(with: self.txtSticker, duration: self.ANIMATE_TIME, options: .transitionFlipFromTop, animations: {
                    if self.isBotRoom() {
                        self.txtSticker.isHidden = true
                    } else {
                        self.txtSticker.isHidden = false
                    }
                }, completion: nil)
                
            })
        }
    }
    
    /* if sticker view is enable show keyboard button otherwise show sticker button */
    private func stickerViewState(enable: Bool) {
       
        isStickerKeyboard = enable
        
        UIView.transition(with: self.txtSticker, duration: ANIMATE_TIME, options: .transitionFlipFromBottom, animations: {
            self.txtSticker.isHidden = true
            
            if self.isStickerKeyboard {
                self.txtSticker.text = ""
                if #available(iOS 10.0, *) {
                    DispatchQueue.main.async {
                        self.openStickerView()
                    }
                }
            } else {
                self.txtSticker.text = ""
                if self.inputTextView.inputAccessoryView != nil {
                    UIView.transition(with: self.inputTextView.inputAccessoryView!, duration: 0.5, options: .transitionFlipFromBottom, animations: {
                        self.inputTextView.inputAccessoryView!.isHidden = true
                        self.inputTextView.inputAccessoryView = nil
                    }, completion: nil)
                }
                self.inputTextView.inputView = nil
                self.inputTextView.reloadInputViews()
            }
            
        }, completion: { (completed) in
            
            UIView.transition(with: self.txtSticker, duration: self.ANIMATE_TIME, options: .transitionFlipFromTop, animations: {
                self.txtSticker.isHidden = false
            }, completion: nil)
        })
    }
    
    /* open sticker view in chat and go to saved position */
    private func manageStickerPosition() {
        if #available(iOS 10.0, *) {
            if IGStickerViewController.currentStickerGroupId != nil {
                self.stickerViewState(enable: true)
            }
        }
    }
    
    private func disableStickerView(delay: Double, openKeyboard: Bool = false){
        isStickerKeyboard = false
        DispatchQueue.main.asyncAfter(deadline: .now() + delay){
            self.txtSticker.text = ""
            self.inputTextView.inputAccessoryView = nil
            self.inputTextView.inputView = nil
            self.inputTextView.reloadInputViews()
            if openKeyboard && !self.inputTextView.isFirstResponder {
                self.inputTextView.becomeFirstResponder()
            }
        }
    }
    
    /***** user send location callback *****/
    func userWasSelectedLocation(location: CLLocation) {
        
        let message = IGRoomMessage(body: "")
        let locationMessage = IGRoomMessageLocation(location: location, for: message)
        message.location = locationMessage.detach()
        message.roomId = self.room!.id
        message.type = .location
        
        let detachedMessage = message.detach()
        
        IGFactory.shared.saveNewlyWriitenMessageToDatabase(detachedMessage)
        message.forwardedFrom = IGMessageViewController.selectedMessageToForwardToThisRoom // Hint: if use this line before "saveNewlyWriitenMessageToDatabase" app will be crashed
        message.repliedTo = selectedMessageToReply // Hint: if use this line before "saveNewlyWriitenMessageToDatabase" app will be crashed
        IGMessageSender.defaultSender.send(message: message, to: room!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.sendMessageState(enable: false)
            self.inputTextView.text = ""
            IGMessageViewController.selectedMessageToForwardToThisRoom = nil
            self.selectedMessageToReply = nil
            self.currentAttachment = nil
            self.setInputBarHeight()
        }
    }

    //MARK: - Scroll
    func updateScrollPosition(forceToLastMessage: Bool, wasAddedMessagesNewer: Bool?, initialContentOffset: CGPoint?, initialContentSize: CGSize?, animated: Bool) {
//        if forceToBottom {
//            scrollToLastMessage(animated: animated)
//        } else {
//            let initalContentBottomPadding = (initialContentSize!.height + self.collectionView.contentInset.bottom) - (initialContentOffset!.y + self.collectionView.frame.height)
//            
//            //100 is an arbitrary number can be anything that makes sense. 100, 150, ...
//            //we used this to see if user is near the bottom of scroll view and 
//            //we should scrolll to bottom
//            if initalContentBottomPadding < 100 {
//                scrollToLastMessage(animated: animated)
//            } else {
//                if didMessagesAddedToBottom != nil {
//                    keepScrollPosition(didMessagesAddedToBottom: didMessagesAddedToBottom!, initialContentOffset: initialContentOffset!, initialContentSize: initialContentSize!, animated: animated)
//                }
//            }
//        }
    }
    
//    private func scrollToLastMessage(animated: Bool) {
//        if self.collectionView.numberOfItems(inSection: 0) > 0  {
////            let indexPath = IndexPath(row: self.collectionView.numberOfItems(inSection: 0)-1, section: 0)
//            let indexPath = IndexPath(row: 0, section: self.collectionView.numberOfItems(inSection: 0)-1)
//            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
//        }
//    }
    
    private func keepScrollPosition(didMessagesAddedToBottom: Bool, initialContentOffset: CGPoint, initialContentSize: CGSize, animated: Bool) {
        if didMessagesAddedToBottom {
            self.collectionView.contentOffset = initialContentOffset
        } else {
            let contentOffsetY = self.collectionView.contentSize.height - (initialContentSize.height - initialContentOffset.y)
            // + self.collectionView.contentOffset.y - initialContentSize.height
            self.collectionView.contentOffset = CGPoint(x: self.collectionView.contentOffset.x, y: contentOffsetY)
        }
    }
    
    
    //MARK: -
    private func notification(register: Bool) {
        let center = NotificationCenter.default
        if register {
            center.addObserver(self,
                               selector: #selector(didReceiveKeyboardWillChangeFrameNotification(_:)),
                               name: UIResponder.keyboardWillHideNotification,
                               object: nil)
            center.addObserver(self,
                               selector: #selector(didReceiveKeyboardWillChangeFrameNotification(_:)),
                               name: UIResponder.keyboardWillChangeFrameNotification,
                               object: nil)
            
            center.addObserver(self,
                               selector: #selector(dodd),
                               name: UIMenuController.willShowMenuNotification,
                               object: nil)
            center.addObserver(self,
                               selector: #selector(dodd),
                               name: UIMenuController.willHideMenuNotification,
                               object: nil)
            center.addObserver(self,
                               selector: #selector(dodd),
                               name: UIContentSizeCategory.didChangeNotification,
                               object: nil)
        } else {
            center.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
            center.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
            center.removeObserver(self, name: UIMenuController.willShowMenuNotification, object: nil)
            center.removeObserver(self, name: UIMenuController.willHideMenuNotification, object: nil)
            center.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)
        }
    }
    
    @objc func dodd() {
    
    }
    
    @objc func didReceiveKeyboardWillChangeFrameNotification(_ notification:Notification) {
        
        let userInfo = (notification.userInfo)!
        if let keyboardEndFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            
            let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int
            let animationCurveOption = (animationCurve << 16)
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            let keyboardBeginFrame = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect
            
            var bottomConstraint: CGFloat
            if keyboardEndFrame.origin.y == keyboardBeginFrame.origin.y {
                return
            } else if notification.name == UIResponder.keyboardWillHideNotification  {
                //hidding keyboard
                bottomConstraint = 0.0
            } else {
                //showing keyboard
                bottomConstraint = keyboardEndFrame.size.height
            }
            
            UIView.animate(withDuration: animationDuration, delay: 0.0, options: UIView.AnimationOptions(rawValue: UInt(animationCurveOption)), animations: {
                self.inputBarViewBottomConstraint.constant = bottomConstraint
                self.view.layoutIfNeeded()
            }, completion: { (completed) in
                
            })
        }
    }
        
    func setCollectionViewInset(withDuration: TimeInterval = 0.2) {
        let value = inputBarHeightContainerConstraint.constant + collectionViewTopInsetOffset// + inputBarViewBottomConstraint.constant
        UIView.animate(withDuration: withDuration, animations: {
            self.collectionView.contentInset = UIEdgeInsets.init(top: value, left: 0, bottom: 20, right: 0)
        }, completion: { (completed) in
            
        })
    }
    
    func updateConnectionStatus(_ status: IGAppManager.ConnectionStatus) {
        
        switch status {
        case .connected:
            connectionStatus = .connected
            break
        case .connecting:
            connectionStatus = .connecting
            break
        case .waitingForNetwork:
            connectionStatus = .waitingForNetwork
            break
        case .iGap:
            connectionStatus = .iGap
            break
        }
    }
    
    func groupPin(messageId: Int64 = 0){
        
        var message = "Are you sure unpin this message?"
        var title = "Unpin For All Users"
        let titleMe = "Unpin Just For Me"
        if messageId != 0 {
            message = "Are you sure pin this message?"
            title = "Pin"
        }
        
        let alertC = UIAlertController(title: nil, message: message, preferredStyle: IGGlobal.detectAlertStyle())
        let unpin = UIAlertAction(title: title, style: .default, handler: { (action) in
            IGGroupPinMessageRequest.Generator.generate(roomId: (self.room?.id)!, messageId: messageId).success({ (protoResponse) in
                DispatchQueue.main.async {
                    if let groupPinMessage = protoResponse as? IGPGroupPinMessageResponse {
                        if groupPinMessage.hasIgpPinnedMessage {
                            self.txtPinnedMessage.text = IGRoomMessage.detectPinMessageProto(message: groupPinMessage.igpPinnedMessage)
                            self.pinnedMessageView.isHidden = false
                        } else {
                            self.pinnedMessageView.isHidden = true
                        }
                        IGGroupPinMessageRequest.Handler.interpret(response: groupPinMessage)
                    }
                }
            }).error({ (errorCode, waitTime) in
                switch errorCode {
                case .timeout:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Timeout", message: "Please try again later for unpin message", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                default:
                    break
                }
                
            }).send()
        })
        
        let unpinJustForMe = UIAlertAction(title: titleMe, style: .default, handler: { (action) in
            self.pinnedMessageView.isHidden = true
            IGFactory.shared.roomPinMessage(roomId: (self.room?.id)!)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertC.addAction(unpin)
        if messageId == 0 {
            alertC.addAction(unpinJustForMe)
        }
        alertC.addAction(cancel)
        self.present(alertC, animated: true, completion: nil)
    }
    
    func channelPin(messageId: Int64 = 0){
        
        var message = "Are you sure unpin this message?"
        var title = "Unpin"
        let titleMe = "Unpin Just For Me"
        if messageId != 0 {
            message = "Are you sure pin this message?"
            title = "Pin"
        }
        
        let alertC = UIAlertController(title: nil, message: message, preferredStyle: IGGlobal.detectAlertStyle())
        let unpin = UIAlertAction(title: title, style: .default, handler: { (action) in
            IGChannelPinMessageRequest.Generator.generate(roomId: (self.room?.id)!, messageId: messageId).success({ (protoResponse) in
                DispatchQueue.main.async {
                    if let channelPinMessage = protoResponse as? IGPChannelPinMessageResponse {
                        if channelPinMessage.hasIgpPinnedMessage {
                            self.txtPinnedMessage.text = IGRoomMessage.detectPinMessageProto(message: channelPinMessage.igpPinnedMessage)
                            self.pinnedMessageView.isHidden = false
                        } else {
                            self.pinnedMessageView.isHidden = true
                        }
                        IGChannelPinMessageRequest.Handler.interpret(response: channelPinMessage)
                    }
                }
            }).error({ (errorCode, waitTime) in
                switch errorCode {
                case .timeout:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Timeout", message: "Please try again later for unpin message", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                default:
                    break
                }
                
            }).send()
        })
        
        let unpinJustForMe = UIAlertAction(title: titleMe, style: .default, handler: { (action) in
            self.pinnedMessageView.isHidden = true
            IGFactory.shared.roomPinMessage(roomId: (self.room?.id)!)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertC.addAction(unpin)
        if messageId == 0 {
            alertC.addAction(unpinJustForMe)
        }
        alertC.addAction(cancel)
        self.present(alertC, animated: true, completion: nil)
    }
    
    func groupPinGranted() -> Bool{
        if room?.type == .group && room?.groupRoom?.role != .member {
            return true
        }
        return false
    }
    
    func channelPinGranted() -> Bool{
        if room?.type == .channel && room?.channelRoom?.role != .member {
            return true
        }
        return false
    }
    
    /************************** Alert Action Permissions **************************/
    func allowCopy(_ message: IGRoomMessage) -> Bool{
        var finalMessage = message
        if let forward = message.forwardedFrom {
            finalMessage = forward
        }
        if (finalMessage.type == .text) ||
            finalMessage.type == .gifAndText ||
            finalMessage.type == .fileAndText ||
            finalMessage.type == .audioAndText ||
            finalMessage.type == .videoAndText ||
            finalMessage.type == .imageAndText {
            return true
        }
        return false
    }
    
    func allowPin() -> Bool{
        return groupPinGranted() || channelPinGranted()
    }
    
    func allowReply() -> Bool{
        if !(room!.isReadOnly){
            return true
        }
        return false
    }
    
    func allowEdit(_ message: IGRoomMessage) -> Bool{
        if  (message.forwardedFrom == nil) && message.type != .sticker && message.authorHash == currentLoggedInUserAuthorHash && message.type != .contact && message.type != .location &&
            ((self.room!.type == .chat) || (self.room!.type == .channel && self.room!.channelRoom!.role != .member) || (self.room!.type == .group && self.room!.groupRoom!.role != .member)) {
            return true
        }
        return false
    }
    
    func allowDelete(_ message: IGRoomMessage) -> (singleDelete: Bool, bothDelete: Bool){
        var singleDelete = false
        var bothDelete = false
        if (message.authorHash == currentLoggedInUserAuthorHash) || (self.room!.type == .chat) ||
            (self.room!.type == .channel && self.room!.channelRoom!.role == .owner) ||
            (self.room!.type == .group && self.room!.groupRoom!.role == .owner) {
            if (self.room!.type == .chat) && (message.authorHash == currentLoggedInUserAuthorHash) && (message.creationTime != nil) && (Date().timeIntervalSince1970 - message.creationTime!.timeIntervalSince1970 < 2 * 3600) {
                bothDelete = true
            }
            singleDelete = true
        }
        return (singleDelete,bothDelete)
    }
    
    func allowShare(_ cellMessage: IGRoomMessage) -> Bool {
        
        var message = cellMessage
        if let forward = cellMessage.forwardedFrom {
            message = forward
        }
        
        if (message.type == .file || message.type == .fileAndText ||
            message.type == .image || message.type == .imageAndText ||
            message.type == .video || message.type == .videoAndText ||
            message.type == .gif) && IGGlobal.isFileExist(path: message.attachment!.path(), fileSize: message.attachment!.size) {
            return true
        }
        return false
    }
    
    @objc func didTapOnInputTextView() {
        disableStickerView(delay: 0.0, openKeyboard: true)
    }
    
    @objc func didTapOnStickerButton() {
        if isStickerKeyboard {
            isStickerKeyboard = false
        } else {
            isStickerKeyboard = true
        }
        
        stickerViewState(enable: isStickerKeyboard)
    }
    
    @IBAction func didTapOnPinClose(_ sender: UIButton) {
        if groupPinGranted() {
            self.groupPin()
            return
        } else if channelPinGranted() {
            self.channelPin()
            return
        }
    }
    
    @IBAction func didTapOnPinView(_ sender: UIButton) {
        if let pinMessage = room?.pinMessage {
            goToPosition(cellMessage: pinMessage)
        }
    }
    
    //MARK: IBActions
    @IBAction func didTapOnSendButton(_ sender: UIButton) {
        if currentAttachment == nil && inputTextView.text == "" && IGMessageViewController.selectedMessageToForwardToThisRoom == nil {
            return
        }
        
        inputTextView.text = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if selectedMessageToEdit != nil {
            switch room!.type {
            case .chat:
                IGChatEditMessageRequest.Generator.generate(message: selectedMessageToEdit!, newText: inputTextView.text,  room: room!).success({ (protoResponse) in
                    IGChatEditMessageRequest.Handler.interpret(response: protoResponse)
                }).error({ (errorCode, waitTime) in
                    
                }).send()
            case .group:
                IGGroupEditMessageRequest.Generator.generate(message: selectedMessageToEdit!, newText: inputTextView.text, room: room!).success({ (protoResponse) in
                    switch protoResponse {
                    case let response as IGPGroupEditMessageResponse:
                        IGGroupEditMessageRequest.Handler.interpret(response: response)
                    default:
                        break
                    }
                }).error({ (errorCode, waitTime) in
                    
                }).send()
            case .channel:
                IGChannelEditMessageRequest.Generator.generate(message: selectedMessageToEdit!, newText: inputTextView.text, room: room!).success({ (protoResponse) in
                    switch protoResponse {
                    case let response as IGPChannelEditMessageResponse:
                        IGChannelEditMessageRequest.Handler.interpret(response: response)
                    default:
                        break
                    }
                }).error({ (errorCode, waitTime) in
                    
                }).send()
            }
            
            selectedMessageToEdit = nil
            self.inputTextView.text = ""
            self.setInputBarHeight()
            self.sendCancelTyping()
            return
        }
        
        if currentAttachment != nil {
            
            let messageText = inputTextView.text.substring(offset: MAX_TEXT_ATTACHMENT_LENGHT)
            
            let message = IGRoomMessage(body: messageText)
            currentAttachment?.status = .processingForUpload
            message.attachment = currentAttachment?.detach()
            IGAttachmentManager.sharedManager.add(attachment: currentAttachment!)
            switch currentAttachment!.type {
            case .image:
                if messageText == "" {
                    message.type = .image
                } else {
                    message.type = .imageAndText
                }
            case .video:
                if messageText == "" {
                    message.type = .video
                } else {
                    message.type = .videoAndText
                }
            case .audio:
                if messageText == "" {
                    message.type = .audio
                } else {
                    message.type = .audioAndText
                }
            case .voice:
                message.type = .voice
            case .file:
                if messageText == "" {
                    message.type = .file
                } else {
                    message.type = .fileAndText
                }
            default:
                break
            }
            
            message.roomId = self.room!.id
            
            let detachedMessage = message.detach()
            
            IGFactory.shared.saveNewlyWriitenMessageToDatabase(detachedMessage)
            message.forwardedFrom = IGMessageViewController.selectedMessageToForwardToThisRoom // Hint: if use this line before "saveNewlyWriitenMessageToDatabase" app will be crashed
            message.repliedTo = selectedMessageToReply // Hint: if use this line before "saveNewlyWriitenMessageToDatabase" app will be crashed
            IGMessageSender.defaultSender.send(message: message, to: room!)
            
            self.sendMessageState(enable: false)
            self.inputTextView.text = ""
            self.currentAttachment = nil
            IGMessageViewController.selectedMessageToForwardToThisRoom = nil
            self.selectedMessageToReply = nil
            self.setInputBarHeight()
            
        } else {
            
            let messages = inputTextView.text.split(limit: MAX_TEXT_LENGHT)
            for i in 0..<messages.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * 0.5)) {
                    let message = IGRoomMessage(body: messages[i])
                    if (self.selectedMessageToReply == nil && IGMessageViewController.selectedMessageToForwardToThisRoom == nil && messages[i].isEmpty) {
                        self.inputTextView.text = ""
                        return
                    }
                    
                    message.type = .text
                    message.roomId = self.room!.id
                    
                    let detachedMessage = message.detach()
                    
                    IGFactory.shared.saveNewlyWriitenMessageToDatabase(detachedMessage)
                    message.forwardedFrom = IGMessageViewController.selectedMessageToForwardToThisRoom // Hint: if use this line before "saveNewlyWriitenMessageToDatabase" app will be crashed
                    message.repliedTo = self.selectedMessageToReply // Hint: if use this line before "saveNewlyWriitenMessageToDatabase" app will be crashed
                    IGMessageSender.defaultSender.send(message: message, to: self.room!)
                    
                    self.sendMessageState(enable: false)
                    self.inputTextView.text = ""
                    self.currentAttachment = nil
                    IGMessageViewController.selectedMessageToForwardToThisRoom = nil
                    self.selectedMessageToReply = nil
                    self.setInputBarHeight()
                }
            }
        }
    }
    
    /************************************************************************/
    /*********************** Attachment Manager Start ***********************/
    /************************************************************************/
    @IBAction func didTapOnAddAttachmentButton(_ sender: UIButton) {
        self.inputTextView.resignFirstResponder()
        
        let alertC = UIAlertController(title: nil, message: nil, preferredStyle: IGGlobal.detectAlertStyle())
        let camera = UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            self.attachmentPicker(sourceType: .camera)
        })
        
        let galley = UIAlertAction(title: "Gallery", style: .default, handler: { (action) in
            self.attachmentPicker()
        })
        
        let document = UIAlertAction(title: "File", style: .default, handler: { (action) in
            self.sendAsFileAlert()
        })
        
        let contact = UIAlertAction(title: "Contact", style: .default, handler: { (action) in
            self.openContact()
        })
        
        let location = UIAlertAction(title: "Location", style: .default, handler: { (action) in
            self.openLocation()
        })
        //location.setValue(UIImage(named: "Location_Marker"), forKey: "image")
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertC.addAction(camera)
        alertC.addAction(galley)
        alertC.addAction(document)
        alertC.addAction(contact)
        alertC.addAction(location)
        alertC.addAction(cancel)
        
        self.present(alertC, animated: true, completion: nil)
    }
    
    private func sendAsFileAlert(){
        let alertC = UIAlertController(title: nil, message: nil, preferredStyle: IGGlobal.detectAlertStyle())
        let photoOrVideo = UIAlertAction(title: "Photo or Video", style: .default, handler: { (action) in
            self.sendAsFile = true
            self.attachmentPicker()
        })
        let document = UIAlertAction(title: "Document", style: .default, handler: { (action) in
            self.sendAsFile = true
            self.documentPicker()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertC.addAction(photoOrVideo)
        alertC.addAction(document)
        alertC.addAction(cancel)
        
        self.present(alertC, animated: true, completion: nil)
    }
    
    func attachmentPicker(sourceType: UIImagePickerController.SourceType = .photoLibrary){
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.sourceType = sourceType
        if self.sendAsFile {
            if #available(iOS 11.0, *) {
                mediaPicker.videoExportPreset = AVAssetExportPresetPassthrough
            }
        }
        mediaPicker.mediaTypes = ["public.image", "public.movie"]
        self.present(mediaPicker, animated: true, completion: nil)
    }
    
    func documentPicker(){
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: documentPickerIdentifiers, in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    /***** overrided method for pick media *****/
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        self.dismiss(animated: true, completion: nil);

        var mediaType : String! = ""
        if let type = info["UIImagePickerControllerMediaType"] {
            mediaType = String(describing: type)
        }
        switch mediaType! {
        case "public.image": // image
            manageImage(imageInfo: info)
            break
            
        case "public.movie" : // video
            manageVideo(mediaInfo: info)
            break
            
        default: // manage file?
            break
        }
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let myURL = url as URL
        if let data = try? Data(contentsOf: myURL) {
            let filename = myURL.lastPathComponent
            manageFile(fileData: data, filename: filename)
        }
    }
    
    func manageVideo(mediaInfo: [String : Any]){
        guard let mediaUrl = mediaInfo["UIImagePickerControllerMediaURL"] as? URL else {
            return
        }
        
        if self.sendAsFile {
            self.sendAsFile = false
            let myURL = mediaUrl as URL
            if let data = try? Data(contentsOf: myURL) {
                let filename = myURL.lastPathComponent
                manageFile(fileData: data, filename: filename)
            }
            return
        }
        
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filename = mediaUrl.lastPathComponent
        let fileSize = Int(IGGlobal.getFileSize(path: mediaUrl))
        let randomString = IGGlobal.randomString(length: 16) + "_"
        
        /*** get thumbnail from video ***/
        let asset = AVURLAsset(url: mediaUrl)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        let cgImage = try!imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
        let uiImage = UIImage(cgImage: cgImage)
        
        let attachment = IGFile(name: filename)
        attachment.size = fileSize
        attachment.duration = asset.duration.seconds
        attachment.fileNameOnDisk = randomString + filename
        attachment.name = filename
        attachment.attachedImage = uiImage
        attachment.type = .video
        attachment.height = Double(cgImage.height)
        attachment.width = Double(cgImage.width)
        
        let pathOnDisk = documents + "/" + randomString + filename
        try! FileManager.default.copyItem(atPath: mediaUrl.path, toPath: pathOnDisk)
        
        self.inputBarAttachmentViewThumnailImageView.image = uiImage
        self.inputBarAttachmentViewThumnailImageView.layer.cornerRadius = 6.0
        self.inputBarAttachmentViewThumnailImageView.layer.masksToBounds = true
        self.didSelectAttachment(attachment)
    }
    
    func manageImage(imageInfo: [String : Any]){
        let imageUrl = imageInfo["UIImagePickerControllerImageURL"] as? URL
        let originalImage = imageInfo["UIImagePickerControllerOriginalImage"] as! UIImage
        
        var filename : String!
        var fileSize : Int!
        
        if imageUrl != nil {
            filename = imageUrl?.lastPathComponent
            fileSize = Int(IGGlobal.getFileSize(path: imageUrl))
            
            if self.sendAsFile {
                self.sendAsFile = false
                if let data = try? Data(contentsOf: imageUrl!) {
                    let filename = imageUrl!.lastPathComponent
                    manageFile(fileData: data, filename: filename)
                }
                return
            }
            
        } else {
            filename = "IMAGE_" + IGGlobal.randomString(length: 16)
            let imageData = (originalImage).jpegData(compressionQuality: 1)!
            fileSize = NSData(data: imageData).length
            
            if self.sendAsFile {
                self.sendAsFile = false
                let filename = imageUrl!.lastPathComponent
                manageFile(fileData: imageData, filename: filename)
                return
            }
        }
        let randomString = IGGlobal.randomString(length: 16) + "_"
   
        var scaledImage = originalImage
        let imgData = scaledImage.jpegData(compressionQuality: 0.7)
        if imgData != nil {
            fileSize = NSData(data: imgData!).length
        }
        let fileNameOnDisk = randomString + filename
        
        if (originalImage.size.width) > CGFloat(2000.0) || (originalImage.size.height) >= CGFloat(2000) {
            scaledImage = IGUploadManager.compress(image: originalImage)
        }
        
        let attachment = IGFile(name: filename)
        attachment.size = fileSize
        attachment.attachedImage = scaledImage
        attachment.fileNameOnDisk = fileNameOnDisk
        attachment.height = Double((scaledImage.size.height))
        attachment.width = Double((scaledImage.size.width))
        attachment.size = (imgData?.count)!
        attachment.data = imgData
        attachment.type = .image
        
        DispatchQueue.main.async {
            self.saveAttachmentToLocalStorage(data: imgData!, fileNameOnDisk: fileNameOnDisk)
        }
        
        self.inputBarAttachmentViewThumnailImageView.image = attachment.attachedImage
        self.inputBarAttachmentViewThumnailImageView.layer.cornerRadius = 6.0
        self.inputBarAttachmentViewThumnailImageView.layer.masksToBounds = true
        
        self.didSelectAttachment(attachment)
    }
    
    func manageFile(fileData: Data, filename: String) {
        
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let randomString = IGGlobal.randomString(length: 16) + "_"
        let pathOnDisk = documents + "/" + randomString + filename
        
        let fileUrl : URL = NSURL(fileURLWithPath: pathOnDisk) as URL
        let fileSize = Int(fileData.count)
        
        // write data to my fileUrl
        try! fileData.write(to: fileUrl)
        
        let attachment = IGFile(name: filename)
        attachment.size = fileSize
        attachment.fileNameOnDisk = randomString + filename
        attachment.name = filename
        attachment.type = .file
        
        let randomStringFinal = IGGlobal.randomString(length: 16) + "_"
        let pathOnDiskFinal = documents + "/" + randomStringFinal + filename
        try! FileManager.default.copyItem(atPath: fileUrl.path, toPath: pathOnDiskFinal)

        self.inputBarAttachmentViewThumnailImageView.image = UIImage(named: "IG_Message_Cell_File_Generic")
        self.inputBarAttachmentViewThumnailImageView.frame = CGRect(x: 0, y: 0, width: 30, height: 34)
        self.inputBarAttachmentViewThumnailImageView.layer.cornerRadius = 6.0
        self.inputBarAttachmentViewThumnailImageView.layer.masksToBounds = true
        
        self.didSelectAttachment(attachment)
    }
    
    private func openLocation(){
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            isSendLocation = true
            self.performSegue(withIdentifier: "showLocationViewController", sender: self)
        }
    }
    
    /*************** web view manager ***************/
    private func openWebView(url:String)  {
        
        makeWebView()
        
        if doctorBotScrollView != nil {
            doctorBotScrollView.isHidden = true
        }
        if btnChangeKeyboard != nil {
            btnChangeKeyboard.isHidden = true
        }
        
        scrollToBottomContainerView.isHidden = true
        collectionView.isHidden = true
        chatBackground.isHidden = true
        self.inputBarContainerView.isHidden = true
        self.webView.isHidden = false
        self.view.endEditing(true)
        
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.backViewContainer?.addAction {
            self.back()
        }
        
        let url = URL(string: url)
        if let unwrappedURL = url {
            
            let request = URLRequest(url: unwrappedURL)
            let session = URLSession.shared
            
            
            let task = session.dataTask(with: request) { (data, response, error) in
                
                if error == nil {
                    DispatchQueue.main.async {
                        self.webView?.loadRequest(request)
                    }
                } else {
                    print("ERROR: \(String(describing: error))")
                }
            }
            task.resume()
        }
    }
    
    func closeWebView()  {
        collectionView.isHidden = false
        chatBackground.isHidden = false
        self.inputBarContainerView.isHidden = false
        self.webView.stopLoading()
        self.webView.isHidden = true
        
        if doctorBotScrollView != nil {
            doctorBotScrollView.isHidden = false
        }
        if btnChangeKeyboard != nil {
            btnChangeKeyboard.isHidden = false
        }
        removeWebView()
    }
    
    private func makeWebView(){
        if self.webView == nil {
            self.webView = UIWebView()
        }
        mainView.addSubview(self.webView)
        self.webView.snp.makeConstraints { (make) in
            make.top.equalTo(mainView.snp.top)
            make.bottom.equalTo(mainView.snp.bottom)
            make.right.equalTo(mainView.snp.right)
            make.left.equalTo(mainView.snp.left)
        }
        self.webView.delegate = self
    }
    
    private func removeWebView(){
        if self.webView != nil {
            self.webView.removeFromSuperview()
            self.webView = nil
        }
    }
    
    private func makeWebViewProgress(){
        if webViewProgressbar == nil {
           webViewProgressbar = UIActivityIndicatorView()
           webViewProgressbar.hidesWhenStopped = true
           webViewProgressbar.color = UIColor.darkGray
        }
        webView.addSubview(webViewProgressbar)
        
        webViewProgressbar.snp.makeConstraints { (make) in
            make.height.equalTo(40)
            make.width.equalTo(40)
            make.centerX.equalTo(webView.snp.centerX)
            make.centerY.equalTo(webView.snp.centerY)
        }
    }
    
    private func removeWebViewProgress(){
        if self.webViewProgressbar != nil {
            self.webViewProgressbar.removeFromSuperview()
            self.webViewProgressbar = nil
        }
    }
    
    
    func back() { // this back  when work that webview is working
        if webView == nil || webView.isHidden {
            let navigationItem = self.navigationItem as! IGNavigationItem
            navigationItem.backViewContainer?.isUserInteractionEnabled = false
            _ = self.navigationController?.popViewController(animated: true)
        } else if webView.canGoBack {
            webView.goBack()
        } else {
            closeWebView()
        }
    }
    
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        removeWebViewProgress()
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {

    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        removeWebViewProgress()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        if request.url?.description == "igap://close" {
            closeWebView()
        } else {
            makeWebViewProgress()
            webViewProgressbar.startAnimating()
        }
        return true
    }
    
    /***** overrided method for location manager *****/
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.authorizedWhenInUse) {
            openLocation()
        }
    }
    
    private func openContact(){
        IGClientActionManager.shared.sendChoosingContact(for: self.room!)
        let contactPickerScene = EPContactsPicker(delegate: self, multiSelection:false, subtitleCellType: SubtitleCellValue.email)
        let navigationController = UINavigationController(rootViewController: contactPickerScene)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func epContactPicker(_: EPContactsPicker, didCancel error: NSError) {
        IGClientActionManager.shared.cancelChoosingContact(for: self.room!)
    }
    
    func epContactPicker(_: EPContactsPicker, didSelectContact contact : EPContact){
        IGClientActionManager.shared.cancelChoosingContact(for: self.room!)
        var phones : [String] = []
        var emails : [String] = []
        for phone in contact.phoneNumbers {
            phones.append(phone.phoneNumber)
        }
        for email in contact.emails {
            emails.append(email.email)
        }
        
        let message = IGRoomMessage(body: "")
        let contact = IGRoomMessageContact(message:message, firstName:contact.firstName, lastName:contact.lastName, phones:phones, emails:emails)
        message.contact = contact.detach()
        message.type = .contact
        message.roomId = self.room!.id
        let detachedMessage = message.detach()
        IGFactory.shared.saveNewlyWriitenMessageToDatabase(detachedMessage)
        message.forwardedFrom = IGMessageViewController.selectedMessageToForwardToThisRoom // Hint: if use this line before "saveNewlyWriitenMessageToDatabase" app will be crashed
        message.repliedTo = self.selectedMessageToReply // Hint: if use this line before "saveNewlyWriitenMessageToDatabase" app will be crashed
        IGMessageSender.defaultSender.send(message: message, to: self.room!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.sendMessageState(enable: false)
            self.inputTextView.text = ""
            IGMessageViewController.selectedMessageToForwardToThisRoom = nil
            self.selectedMessageToReply = nil
            self.currentAttachment = nil
            self.setInputBarHeight()
        }
    }
    /**********************************************************************/
    /*********************** Attachment Manager End ***********************/
    /**********************************************************************/
   
    
    @IBAction func didTapOnDeleteSelectedAttachment(_ sender: UIButton) {
        self.currentAttachment = nil
        self.setInputBarHeight()
        let text = inputTextView.text as NSString
        if text.length > 0 {
            self.sendMessageState(enable: true)
        } else {
            self.sendMessageState(enable: false)
        }
    }
    
    @IBAction func didTapOnCancelReplyOrForwardButton(_ sender: UIButton) {
        IGMessageViewController.selectedMessageToForwardToThisRoom = nil
        self.selectedMessageToReply = nil
        if self.selectedMessageToEdit != nil {
            self.selectedMessageToEdit = nil
            self.inputTextView.text = ""
        }
        self.setInputBarHeight()
        self.setSendAndRecordButtonStates()
    }
    
    @IBAction func didTapOnScrollToBottomButton(_ sender: UIButton) {
        self.collectionView.setContentOffset(CGPoint(x: 0, y: -self.collectionView.contentInset.top) , animated: false)
    }
    
    @IBAction func didTapOnJoinButton(_ sender: UIButton) {
        
        if isBotRoom() {
            inputTextView.text = "/Start"
            self.didTapOnSendButton(self.inputBarSendButton)
            
            self.joinButton.isHidden = true
            self.inputBarContainerView.isHidden = false
            return
        }
        
        var username: String?
        if room?.channelRoom != nil {
            if let channelRoom = room?.channelRoom {
                if channelRoom.type == .publicRoom {
                    username = channelRoom.publicExtra?.username
                }
            }
        }
        if room?.groupRoom != nil {
            if let groupRoom = room?.groupRoom {
                if groupRoom.type == .publicRoom {
                    username = groupRoom.publicExtra?.username
                }
            }
        }
        if let publicRooomUserName = username {
            self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.hud.mode = .indeterminate
            IGClientJoinByUsernameRequest.Generator.generate(userName: publicRooomUserName).success({ (protoResponse) in
                self.openChatFromLink = false
                DispatchQueue.main.async {
                    switch protoResponse {
                    case let clientJoinbyUsernameResponse as IGPClientJoinByUsernameResponse:
                        if let roomId = self.room?.id {
                            IGClientJoinByUsernameRequest.Handler.interpret(response: clientJoinbyUsernameResponse, roomId: roomId)
                        }
                        self.joinButton.isHidden = true
                        self.hud.hide(animated: true)
                        self.collectionViewTopInsetOffset = -54.0 + 8.0
                    default:
                        break
                    }
                }
            }).error ({ (errorCode, waitTime) in
                switch errorCode {
                case .timeout:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.hud.hide(animated: true)
                        self.present(alert, animated: true, completion: nil)
                    }
                case .clinetJoinByUsernameForbidden:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Error", message: "You don't have permission to join this room", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.hud.hide(animated: true)
                        self.present(alert, animated: true, completion: nil)
                    }

                default:
                    break
                }
                
            }).send()
        }
    }
    

    //MARK: AudioRecorder
    @objc func didTapAndHoldOnRecord(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            startRecording()
            initialLongTapOnRecordButtonPosition = gestureRecognizer.location(in: self.view)
        case .cancelled:
            print("cancelled")
        case .changed:
            let point = gestureRecognizer.location(in: self.view)
            let difX = (initialLongTapOnRecordButtonPosition?.x)! - point.x
            
            var newConstant:CGFloat = 0.0
            if difX > 10 {
                newConstant = 74 - difX
            } else {
                newConstant = 74
            }
            
            if newConstant > 0{
                inputBarRecordViewLeftConstraint.constant = newConstant
                UIView.animate(withDuration: 0.1, animations: {
                    self.view.layoutIfNeeded()
                })
            } else {
                cancelRecording()
            }
            
        case .ended:
            finishRecording()
        case .failed:
            print("failed")
        case .possible:
            print("possible")
        }
    }
    
    func startRecording() {
        prepareViewForRecord()
        recordVoice()
    }
    
    func cancelRecording() {
        cleanViewAfterRecord()
        recorder?.stop()
        isRecordingVoice = false
        voiceRecorderTimer?.invalidate()
        recordedTime = 0
    }
    
    func finishRecording() {
        cleanViewAfterRecord()
        recorder?.stop()
        voiceRecorderTimer?.invalidate()
        recordedTime = 0
    }
    
    func prepareViewForRecord() {
        //disable rotation
        self.isRecordingVoice = true
        
        inputBarRecordView.isHidden = false
        inputBarRecodingBlinkingView.isHidden = false
        inputBarRecordRightView.isHidden = false
        inputBarRecordTimeLabel.isHidden = false
        
        inputTextView.isHidden = true
        inputBarLeftView.isHidden = true
        
        inputBarRecordViewLeftConstraint.constant = 74
        UIView.animate(withDuration: 0.5) {
            self.inputBarRecordTimeLabel.alpha = 1.0
            self.view.layoutIfNeeded()
        }
        
        if bouncingViewWhileRecord != nil {
            bouncingViewWhileRecord?.removeFromSuperview()
        }
        
        let frame = self.inputBarView.convert(inputBarRecordRightView.frame, from: inputBarRecordRightView)
        let width = frame.size.width
        //let bouncingViewFrame = CGRect(x: frame.origin.x - 2*width, y: frame.origin.y - 2*width, width: 3*width, height: 3*width)
        let bouncingViewFrame = CGRect(x: 0, y: 0, width: 3*width, height: 3*width)
        bouncingViewWhileRecord = UIView(frame: bouncingViewFrame)
        bouncingViewWhileRecord?.layer.cornerRadius = width * 3/2
        bouncingViewWhileRecord?.backgroundColor = UIColor.organizationalColor()
        bouncingViewWhileRecord?.alpha = 0.2
        self.view.addSubview(bouncingViewWhileRecord!)
        bouncingViewWhileRecord?.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(3*width)
            make.center.equalTo(self.inputBarRecordRightView)
        }
        
        
        let alpha = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        alpha?.toValue = 0.0
        alpha?.repeatForever = true
        alpha?.autoreverses = true
        alpha?.duration = 1.0
        inputBarRecodingBlinkingView.pop_add(alpha, forKey: "alphaBlinking")
        
        let size = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
        size?.toValue = NSValue(cgPoint: CGPoint(x: 0.8, y: 0.8))
        size?.velocity = NSValue(cgPoint: CGPoint(x: 2, y: 2))
        size?.springBounciness = 20.0
        size?.repeatForever = true
        size?.autoreverses = true
        bouncingViewWhileRecord?.pop_add(size, forKey: "size")
        
        
        voiceRecorderTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimerLabel), userInfo: nil, repeats: true)
        voiceRecorderTimer?.fire()
    }
    
    func cleanViewAfterRecord() {
        inputBarRecordViewLeftConstraint.constant = 200
        UIView.animate(withDuration: 0.5) {
            self.inputBarRecordTimeLabel.text = "00:00"
            self.inputBarRecordTimeLabel.alpha = 0.0
            self.view.layoutIfNeeded()
        }
        
        
        UIView.animate(withDuration: 0.3, animations: {
            self.inputBarRecordView.alpha = 0.0
            self.inputBarRecodingBlinkingView.alpha = 0.0
            self.inputBarRecordRightView.alpha = 0.0
            self.inputBarRecordTimeLabel.alpha = 0.0
        }, completion: { (success) -> Void in
            //TODO: enable rotation
            self.inputBarRecordView.isHidden = true
            self.inputBarRecodingBlinkingView.isHidden = true
            self.inputBarRecordRightView.isHidden = true
            self.inputBarRecordTimeLabel.isHidden = true
            
            self.inputBarRecordView.alpha = 1.0
            self.inputBarRecodingBlinkingView.alpha = 1.0
            self.inputBarRecordRightView.alpha = 1.0
            self.inputBarRecordTimeLabel.alpha = 1.0
            
            self.inputTextView.isHidden = false
            self.inputBarLeftView.isHidden = false
            
            //animation
            self.inputBarRecodingBlinkingView.pop_removeAllAnimations()
            self.inputBarRecodingBlinkingView.alpha = 1.0
            self.bouncingViewWhileRecord?.removeFromSuperview()
            self.bouncingViewWhileRecord = nil
        })
        
        
    }
    
    @objc func updateTimerLabel() {
        recordedTime += 1
        let minute = String(format: "%02d", Int(recordedTime/60))
        let seconds = String(format: "%02d", Int(recordedTime%60))
        inputBarRecordTimeLabel.text = minute + ":" + seconds
    }
    
    func recordVoice() {
        do {
            self.sendRecordingVoice()
            let fileName = "Recording - \(NSDate.timeIntervalSinceReferenceDate)"
            
            let writePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)?.appendingPathExtension("m4a")
            
            var audioRecorderSetting = Dictionary<String, Any>()
            audioRecorderSetting[AVFormatIDKey] = NSNumber(value: kAudioFormatMPEG4AAC)
            audioRecorderSetting[AVSampleRateKey] = NSNumber(value: 44100.0)
            audioRecorderSetting[AVNumberOfChannelsKey] = NSNumber(value: 2)
            
            let session = AVAudioSession.sharedInstance()
            if #available(iOS 10.0, *) {
                try session.setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playAndRecord)), mode: AVAudioSession.Mode.default)
            } else {
                // Fallback on earlier versions
            }
            
            recorder = try AVAudioRecorder(url: writePath!, settings: audioRecorderSetting)
            if recorder == nil {
                didFinishRecording(success: false)
                return
            }
            recorder?.isMeteringEnabled = true
            recorder?.delegate = self
            recorder?.prepareToRecord()
            recorder?.record()
        } catch {
            didFinishRecording(success: false)
        }
    }
    
    func didFinishRecording(success: Bool) {
        recorder = nil
    }
    
    //MARK: Attachment Handlers
    func didSelectAttachment(_ attachment: IGFile) {
        self.currentAttachment = attachment
        self.setInputBarHeight()
        self.sendMessageState(enable: true)
        self.inputBarAttachmentViewFileNameLabel.text  = currentAttachment?.name
        self.inputBarAttachmentViewFileNameLabel.lineBreakMode = .byTruncatingMiddle
        self.inputBarAttachmentViewFileSizeLabel.text = IGAttachmentManager.sharedManager.convertFileSize(sizeInByte: currentAttachment!.size)
    }

    func saveAttachmentToLocalStorage(data: Data, fileNameOnDisk: String) {
        let path = IGFile.path(fileNameOnDisk: fileNameOnDisk)
        FileManager.default.createFile(atPath: path.path, contents: data, attributes: nil)
    }
    
    //MARK: Actions for tap and hold on messages
    fileprivate func copyMessage(_ message: IGRoomMessage) {
        if let text = message.getFinalMessage().message {
            UIPasteboard.general.string = text
        }
    }
    
    fileprivate func editMessage(_ message: IGRoomMessage) {
        self.selectedMessageToEdit = message
        self.selectedMessageToReply = nil
        IGMessageViewController.selectedMessageToForwardToThisRoom = nil
        
        self.inputTextView.text = message.message
        inputTextView.placeholder = "Message"
        self.inputTextView.becomeFirstResponder()
        self.inputBarOriginalMessageViewSenderNameLabel.text = "Edit Message"
        self.inputBarOriginalMessageViewBodyTextLabel.text = message.message
        self.setInputBarHeight()
    }
    
    fileprivate func forwardOrReplyMessage(_ message: IGRoomMessage, isReply: Bool = true) {
        
        var finalMessage = message
        if let forwardMessage = message.forwardedFrom {
            finalMessage = forwardMessage
        }
        
        var prefix = ""
        
        self.selectedMessageToEdit = nil
        if isReply {
            prefix = "reply"
            IGMessageViewController.selectedMessageToForwardToThisRoom = nil
            self.selectedMessageToReply = message
        } else {
            prefix = "forward"
            self.selectedMessageToReply = nil
            IGMessageViewController.selectedMessageToForwardFromThisRoom = message
            self.setSendAndRecordButtonStates()
        }
        
        if let user = finalMessage.authorUser {
            self.inputBarOriginalMessageViewSenderNameLabel.text = user.displayName
        } else if let room = finalMessage.authorRoom {
            self.inputBarOriginalMessageViewSenderNameLabel.text = room.title
        }
        
        let textMessage = finalMessage.message
        if textMessage != nil && !(textMessage?.isEmpty)! {
            
            if message.type == .sticker {
                self.inputBarOriginalMessageViewBodyTextLabel.text = textMessage! + " Sticker"
            } else {
                self.inputBarOriginalMessageViewBodyTextLabel.text = textMessage
                
                let markdown = MarkdownParser()
                markdown.enabledElements = MarkdownParser.EnabledElements.bold
                self.inputBarOriginalMessageViewBodyTextLabel.attributedText = markdown.parse(textMessage!)
                self.inputBarOriginalMessageViewBodyTextLabel.textColor = UIColor.darkGray
                self.inputBarOriginalMessageViewBodyTextLabel.font = UIFont.igFont(ofSize: 11.0)
            }
            
        } else if finalMessage.contact != nil {
            self.inputBarOriginalMessageViewBodyTextLabel.text = "\(prefix) contact message"
        } else if finalMessage.location != nil {
            self.inputBarOriginalMessageViewBodyTextLabel.text = "\(prefix) location message"
        } else if let file = finalMessage.attachment {
            self.inputBarOriginalMessageViewBodyTextLabel.text = "\(prefix) '\(IGFile.convertFileTypeToString(fileType: file.type))' message"
        }
        
        self.setInputBarHeight()
    }
    
    func reportRoom(roomId: Int64, messageId: Int64, reason: IGPClientRoomReport.IGPReason) {
        self.hud = MBProgressHUD.showAdded(to: self.view.superview!, animated: true)
        self.hud.mode = .indeterminate
        IGClientRoomReportRequest.Generator.generate(roomId: roomId, messageId: messageId, reason: reason).success({ (protoResponse) in
            DispatchQueue.main.async {
                switch protoResponse {
                case _ as IGPClientRoomReportResponse:
                    let alert = UIAlertController(title: "Success", message: "Your report has been successfully submitted", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                default:
                    break
                }
                self.hud.hide(animated: true)
            }
        }).error({ (errorCode , waitTime) in
            DispatchQueue.main.async {
                switch errorCode {
                case .timeout:
                    let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                    break
                    
                case .clientRoomReportReportedBefore:
                    let alert = UIAlertController(title: "Error", message: "This Room Reported Before", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                    break
                    
                case .clientRoomReportForbidden:
                    let alert = UIAlertController(title: "Error", message: "Room Report Fobidden", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                    break
                    
                default:
                    break
                }
                self.hud.hide(animated: true)
            }
        }).send()
    }
    
    func report(room: IGRoom, message: IGRoomMessage){
        let roomId = room.id
        let messageId = message.id
        
        let alertC = UIAlertController(title: title, message: nil, preferredStyle: IGGlobal.detectAlertStyle())
        let abuse = UIAlertAction(title: "Abuse", style: .default, handler: { (action) in
            self.reportRoom(roomId: roomId, messageId: messageId, reason: IGPClientRoomReport.IGPReason.abuse)
        })
        
        let spam = UIAlertAction(title: "Spam", style: .default, handler: { (action) in
            self.reportRoom(roomId: roomId, messageId: messageId, reason: IGPClientRoomReport.IGPReason.spam)
        })
        
        let violence = UIAlertAction(title: "Violence", style: .default, handler: { (action) in
            self.reportRoom(roomId: roomId, messageId: messageId, reason: IGPClientRoomReport.IGPReason.violence)
        })
        
        let pornography = UIAlertAction(title: "Pornography", style: .default, handler: { (action) in
            self.reportRoom(roomId: roomId, messageId: messageId, reason: IGPClientRoomReport.IGPReason.pornography)
        })
        
        let other = UIAlertAction(title: "Other ", style: .default, handler: { (action) in
            self.reportMessageId = messageId
            self.performSegue(withIdentifier: "showReportPage", sender: self)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            
        })
        
        alertC.addAction(abuse)
        alertC.addAction(spam)
        alertC.addAction(violence)
        alertC.addAction(pornography)
        alertC.addAction(other)
        alertC.addAction(cancel)
        
        self.present(alertC, animated: true, completion: {
            
        })
    }
    
    
    fileprivate func deleteMessage(_ message: IGRoomMessage, both: Bool = false) {
        
        if self.connectionStatus == .waitingForNetwork || self.connectionStatus == .connecting {
            let alert = UIAlertController(title: "Error", message: "No Network Connection", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        switch room!.type {
        case .chat:
            IGChatDeleteMessageRequest.Generator.generate(message: message, room: self.room!, both: both).success { (responseProto) in
                switch responseProto {
                case let response as IGPChatDeleteMessageResponse:
                    IGChatDeleteMessageRequest.Handler.interpret(response: response)
                default:
                    break
                }
            }.error({ (errorCode, waitTime) in
                
            }).send()
        case .group:
            IGGroupDeleteMessageRequest.Generator.generate(message: message, room: room!).success({ (responseProto) in
                switch responseProto {
                case let response as IGPGroupDeleteMessageResponse:
                    IGGroupDeleteMessageRequest.Handler.interpret(response: response)
                default:
                    break
                }
            }).error({ (errorCode, waitTime) in
                
            }).send()
        case .channel:
            IGChannelDeleteMessageRequest.Generator.generate(message: message, room: room!).success({ (responseProto) in
                switch responseProto {
                case let response as IGPChannelDeleteMessageResponse:
                    IGChannelDeleteMessageRequest.Handler.interpret(response: response)
                default:
                    break
                }
            }).error({ (errorCode, waitTime) in
                
            }).send()
        }

        if let attachment = message.attachment {
            IGDownloadManager.sharedManager.pauseDownload(attachment: attachment)
        }
    }
    
    
    //MARK: UI states
    func setSendAndRecordButtonStates() {
        if IGMessageViewController.selectedMessageToForwardToThisRoom != nil {
            self.sendMessageState(enable: true)
        } else {
            let text = self.inputTextView.text as NSString
            if text.length == 0 && currentAttachment == nil {
                //empty -> show recored
                self.sendMessageState(enable: false)
            } else {
                //show send
                self.sendMessageState(enable: true)
            }
        }
    }
    
    //MARK: Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showSticker" {
            if #available(iOS 10.0, *) {
                let stickerViewController = segue.destination as! IGStickerViewController
                stickerViewController.stickerPageType = self.stickerPageType
                stickerViewController.stickerGroupId = self.stickerGroupId
            }
        } else if segue.identifier == "showForwardMessageTable" {
            IGForwardMessageTableViewController.forwardMessageDelegate = self
        } else if segue.identifier == "showReportPage" {
            let destinationTv = segue.destination as! IGReport
            destinationTv.room = self.room
            destinationTv.messageId = self.reportMessageId!
        } else if segue.identifier == "showLocationViewController" {
            let destinationTv = segue.destination as! IGMessageAttachmentLocation
            let modalStyle: UIModalTransitionStyle = UIModalTransitionStyle.coverVertical
            destinationTv.modalTransitionStyle = modalStyle
            destinationTv.isSendLocation = isSendLocation
            if !isSendLocation {
                destinationTv.currentLocation = receivedLocation
            } else {
                IGClientActionManager.shared.sendSendingLocation(for: self.room!)
            }
            destinationTv.room = self.room!
            destinationTv.locationDelegate = self
        }
    }
}

////MARK: - UICollectionView
//extension UICollectionView {
//    func applyChangeset(_ changes: RealmChangeset) {
//        performBatchUpdates({
//            self.insertItems(at: changes.inserted.map { IndexPath(row: 0, section: $0) })
//            self.deleteItems(at: changes.updated.map { IndexPath(row: 0, section: $0) })
//            self.reloadItems(at: changes.deleted.map { IndexPath(row: 0, section: $0) })
//        }, completion: { (completed) in
//            
//        })
//    }
//}


//MARK: - IGMessageCollectionViewDataSource
extension IGMessageViewController: IGMessageCollectionViewDataSource {
    
    private func getMessageType(message: IGRoomMessage) -> IGRoomMessageType {
        var finalMessage = message
        if let forward = message.forwardedFrom {
            finalMessage = forward
        }
        return finalMessage.type
    }
    
    func collectionView(_ collectionView: IGMessageCollectionView, messageAt indexpath: IndexPath) -> IGRoomMessage {
        return messages![indexpath.section]
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if messages != nil {
            return messages!.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        /* if room was deleted close chat room */
        if (self.room?.isInvalidated)! {
            self.navigationController?.popViewController(animated: true)
            
            let cell: IGMessageLogCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: logMessageCellIdentifer, for: indexPath) as! IGMessageLogCollectionViewCell
            cell.setUnknownMessage()
            return cell
        }
        
        self.collectionView = collectionView as? IGMessageCollectionView
        let message = messages![indexPath.section]
        var isIncommingMessage = true
        var shouldShowAvatar = false
        var isPreviousMessageFromSameSender = false
        let isNextMessageFromSameSender = false
        
        let messageType = getMessageType(message: message)
        
        if message.type != .log {
            if messages!.indices.contains(indexPath.section + 1){
                let previousMessage = messages![(indexPath.section + 1)]
                if previousMessage.type != .log && message.authorHash == previousMessage.authorHash {
                    isPreviousMessageFromSameSender = true
                }
            }
            
            //Hint: comment following code because corrently we don't use from 'isNextMessageFromSameSender' variable
            /*
            if messages!.indices.contains(indexPath.section - 1){
                let nextMessage = messages![(indexPath.section - 1)]
                if message.authorHash == nextMessage.authorHash {
                    isNextMessageFromSameSender = true
                }
            }
            */
        }
        
        if self.room?.type == .channel { // isIncommingMessage means that show message left side
            isIncommingMessage = true
        } else if let senderHash = message.authorHash, senderHash == IGAppManager.sharedManager.authorHash() {
            isIncommingMessage = false
        }
        
        if room?.groupRoom != nil {
            shouldShowAvatar = true
        }
        if !isIncommingMessage {
            shouldShowAvatar = false
        }
        
        if messageType == .text {
            let cell: TextCell = collectionView.dequeueReusableCell(withReuseIdentifier: TextCell.cellReuseIdentifier(), for: indexPath) as! TextCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!, isIncommingMessage: isIncommingMessage,shouldShowAvatar: shouldShowAvatar,messageSizes: bubbleSize,isPreviousMessageFromSameSender: isPreviousMessageFromSameSender,isNextMessageFromSameSender: isNextMessageFromSameSender)
            cell.delegate = self
            return cell
            
        } else if messageType == .sticker {
            let cell: StickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCell.cellReuseIdentifier(), for: indexPath) as! StickerCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!, isIncommingMessage: isIncommingMessage,shouldShowAvatar: shouldShowAvatar,messageSizes: bubbleSize,isPreviousMessageFromSameSender: isPreviousMessageFromSameSender,isNextMessageFromSameSender: isNextMessageFromSameSender)
            cell.delegate = self
            return cell
            
        } else if messageType == .wallet {
            let cell: WalletCell = collectionView.dequeueReusableCell(withReuseIdentifier: WalletCell.cellReuseIdentifier(), for: indexPath) as! WalletCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!, isIncommingMessage: isIncommingMessage,shouldShowAvatar: shouldShowAvatar,messageSizes: bubbleSize,isPreviousMessageFromSameSender: isPreviousMessageFromSameSender,isNextMessageFromSameSender: isNextMessageFromSameSender)
            cell.delegate = self
            return cell
            
        } else if messageType == .location {
            let cell: LocationCell = collectionView.dequeueReusableCell(withReuseIdentifier: LocationCell.cellReuseIdentifier(), for: indexPath) as! LocationCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!, isIncommingMessage: isIncommingMessage,shouldShowAvatar: shouldShowAvatar,messageSizes: bubbleSize,isPreviousMessageFromSameSender: isPreviousMessageFromSameSender,isNextMessageFromSameSender: isNextMessageFromSameSender)
            cell.delegate = self
            return cell
            
        } else if messageType == .image ||  messageType == .imageAndText {
            let cell: ImageCell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.cellReuseIdentifier(), for: indexPath) as! ImageCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!, isIncommingMessage: isIncommingMessage,shouldShowAvatar: shouldShowAvatar,messageSizes: bubbleSize,isPreviousMessageFromSameSender: isPreviousMessageFromSameSender,isNextMessageFromSameSender: isNextMessageFromSameSender)
            cell.delegate = self
            return cell
            
        } else if messageType == .video || messageType == .videoAndText {
            let cell: VideoCell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.cellReuseIdentifier(), for: indexPath) as! VideoCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!, isIncommingMessage: isIncommingMessage,shouldShowAvatar: shouldShowAvatar,messageSizes: bubbleSize,isPreviousMessageFromSameSender: isPreviousMessageFromSameSender,isNextMessageFromSameSender: isNextMessageFromSameSender)
            cell.delegate = self
            return cell
            
        } else if messageType == .gif || messageType == .gifAndText {
            let cell: GifCell = collectionView.dequeueReusableCell(withReuseIdentifier: GifCell.cellReuseIdentifier(), for: indexPath) as! GifCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!, isIncommingMessage: isIncommingMessage,shouldShowAvatar: shouldShowAvatar,messageSizes: bubbleSize,isPreviousMessageFromSameSender: isPreviousMessageFromSameSender,isNextMessageFromSameSender: isNextMessageFromSameSender)
            cell.delegate = self
            return cell
            
        } else if messageType == .contact {
            let cell: ContactCell = collectionView.dequeueReusableCell(withReuseIdentifier: ContactCell.cellReuseIdentifier(), for: indexPath) as! ContactCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!, isIncommingMessage: isIncommingMessage,shouldShowAvatar: shouldShowAvatar,messageSizes: bubbleSize,isPreviousMessageFromSameSender: isPreviousMessageFromSameSender,isNextMessageFromSameSender: isNextMessageFromSameSender)
            cell.delegate = self
            return cell
            
        } else if messageType == .file || messageType == .fileAndText {
            let cell: FileCell = collectionView.dequeueReusableCell(withReuseIdentifier: FileCell.cellReuseIdentifier(), for: indexPath) as! FileCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!, isIncommingMessage: isIncommingMessage,shouldShowAvatar: shouldShowAvatar,messageSizes: bubbleSize,isPreviousMessageFromSameSender: isPreviousMessageFromSameSender,isNextMessageFromSameSender: isNextMessageFromSameSender)
            cell.delegate = self
            return cell
            
        } else if messageType == .voice  {
            let cell: VoiceCell = collectionView.dequeueReusableCell(withReuseIdentifier: VoiceCell.cellReuseIdentifier(), for: indexPath) as! VoiceCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!, isIncommingMessage: isIncommingMessage,shouldShowAvatar: shouldShowAvatar,messageSizes: bubbleSize,isPreviousMessageFromSameSender: isPreviousMessageFromSameSender,isNextMessageFromSameSender: isNextMessageFromSameSender)
            cell.delegate = self
            return cell
            
        } else if messageType == .audio || messageType == .audioAndText {
            let cell: AudioCell = collectionView.dequeueReusableCell(withReuseIdentifier: AudioCell.cellReuseIdentifier(), for: indexPath) as! AudioCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!, isIncommingMessage: isIncommingMessage,shouldShowAvatar: shouldShowAvatar,messageSizes: bubbleSize,isPreviousMessageFromSameSender: isPreviousMessageFromSameSender,isNextMessageFromSameSender: isNextMessageFromSameSender)
            cell.delegate = self
            return cell
            
        } else if message.type == .log {
            let cell: IGMessageLogCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: logMessageCellIdentifer, for: indexPath) as! IGMessageLogCollectionViewCell
            let bubbleSize = CellSizeCalculator.sharedCalculator.mainBubbleCountainerSize(room: self.room!, for: message)
            cell.setMessage(message, room: self.room!,isIncommingMessage: true,shouldShowAvatar: false,messageSizes:bubbleSize,isPreviousMessageFromSameSender: false,isNextMessageFromSameSender: false)
            return cell
            
        } else {
            let cell: IGMessageLogCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: logMessageCellIdentifer, for: indexPath) as! IGMessageLogCollectionViewCell
            cell.setUnknownMessage()
            return cell
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        var shouldShowFooter = false
        
        if let message = messages?[section] {
            if message.shouldFetchBefore {
                shouldShowFooter = true
            } else if section < messages!.count - 1, let previousMessage =  messages?[section + 1] {
                let thisMessageDateComponents     = Calendar.current.dateComponents([.year, .month, .day], from: message.creationTime!)
                let previousMessageDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: previousMessage.creationTime!)
                
                if thisMessageDateComponents.year == previousMessageDateComponents.year &&
                    thisMessageDateComponents.month == previousMessageDateComponents.month &&
                    thisMessageDateComponents.day == previousMessageDateComponents.day
                {
                    
                } else {
                    shouldShowFooter = true
                }
            } else {
                //first message in room -> always show time
                shouldShowFooter = true
            }
        }
        
        if shouldShowFooter {
            return CGSize(width: 35, height: 50.0)
        } else {
            return CGSize(width: 0.001, height: 0.001)//CGSize.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableview = UICollectionReusableView()
        if kind == UICollectionView.elementKindSectionFooter {
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: IGMessageLogCollectionViewCell.cellReuseIdentifier(), for: indexPath) as! IGMessageLogCollectionViewCell
            
            if indexPath.section < messages.count {
                if let message = messages?[indexPath.section] {
                    if message.shouldFetchBefore {
                        header.setText("Loading ...")
                    } else {
                        
                        let dayTimePeriodFormatter = DateFormatter()
                        dayTimePeriodFormatter.dateFormat = "MMMM dd"
                        dayTimePeriodFormatter.calendar = Calendar.current
                        let dateString = dayTimePeriodFormatter.string(from: message.creationTime!)
                        header.setText(dateString)
                    }
                }
            }
            reusableview = header
        }
        return reusableview
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension IGMessageViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let message = messages![indexPath.section]
        let size = self.collectionView.layout.sizeCell(room: self.room!, for: message)
        let frame = size.bubbleSize
        
        return CGSize(width: self.collectionView.frame.width, height: frame.height + size.additionalHeight + 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.inputTextView.resignFirstResponder()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let message = messages![indexPath.section]
        if (messages!.count < 20 && lowerAllow) { // HINT: this number(20) should set lower than getMessageLimit(25) for work correct
            lowerAllow = false
            
            let predicate = NSPredicate(format: "roomId = %lld AND isDeleted == false AND id != %lld", self.room!.id, 0)
            messages = try! Realm().objects(IGRoomMessage.self).filter(predicate).sorted(by: sortProperties)
            updateObserver()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.fetchRoomHistoryIfPossibleBefore(message: message)
            }
        } else if (messages!.count < 20 || messages!.indices.contains(indexPath.section + 1)) && message.shouldFetchBefore {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.fetchRoomHistoryIfPossibleBefore(message: message, forceGetHistory: true)
            }
        }
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if self.collectionView.numberOfSections == 0 {
            return
        }
        
        setFloatingDate()
        
        let spaceToTop = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.height
        if spaceToTop < self.scrollToTopLimit {
            
            if hasLocal {
                if allowForGetHistoryLocal {
                    allowForGetHistoryLocal = false
                    messages = findAllMessages()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.allowForGetHistoryLocal = true
                    }
                }
            } else {
                let predicate = NSPredicate(format: "roomId = %lld AND isDeleted == false AND id != %lld", self.room!.id, 0)
                if let message = try! Realm().objects(IGRoomMessage.self).filter(predicate).sorted(by: sortProperties).last {
                    if isFirstHistory {
                        isFirstHistory = false
                        messages = try! Realm().objects(IGRoomMessage.self).filter(predicate).sorted(by: sortProperties)
                        updateObserver()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.fetchRoomHistoryIfPossibleBefore(message: message)
                        }
                    } else {
                        self.fetchRoomHistoryIfPossibleBefore(message: message)
                    }
                }
            }
        }
        
        //100 is an arbitrary number. can be anything
        if scrollView.contentOffset.y > 100 {
            self.scrollToBottomContainerView.isHidden = false
        } else {
            if isBotRoom() && IGHelperDoctoriGap.isDoctoriGapRoom(room: room!) {
                scrollToBottomContainerViewConstraint.constant = CGFloat(DOCTOR_BOT_HEIGHT)
            } else {
                if room!.isReadOnly {
                    scrollToBottomContainerViewConstraint.constant = -40
                }
            }
            self.scrollToBottomContainerView.isHidden = true
        }
        
        let scrollOffset = scrollView.contentOffset.y;
        if (scrollOffset <= 300){ // reach end of scroll
            isEndOfScroll = true
        } else {
            isEndOfScroll = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.5, animations: {
            self.floatingDateView.alpha = 0.0
        })
        UIView.animate(withDuration: 0.5, animations: {
            self.txtFloatingDate.alpha = 0.0
        })
    }
    
    private func setFloatingDate(){
        let arrayOfVisibleItems = collectionView.indexPathsForVisibleItems.sorted()
        if let lastIndexPath = arrayOfVisibleItems.last {
            if latestIndexPath != lastIndexPath {
                latestIndexPath = lastIndexPath
            } else {
                return
            }
            
            if latestIndexPath.section < messages.count {
                if let message = messages?[latestIndexPath.section] {
                    let dayTimePeriodFormatter = DateFormatter()
                    dayTimePeriodFormatter.dateFormat = "MMMM dd"
                    dayTimePeriodFormatter.calendar = Calendar.current
                    let dateString = dayTimePeriodFormatter.string(from: message.creationTime!)
                    txtFloatingDate.text = dateString
                    UIView.animate(withDuration: 0.5, animations: {
                        self.floatingDateView.alpha = 1.0
                    })
                    UIView.animate(withDuration: 0.5, animations: {
                        self.txtFloatingDate.alpha = 1.0
                    })
                }
            }
        }
    }
    
    public func fetchRoomHistoryWhenDbIsClear(){
        IGClientGetRoomHistoryRequest.Generator.generate(roomID: self.room!.id, firstMessageID: 0).success({ (responseProto) in
            DispatchQueue.main.async {
                if let roomHistoryReponse = responseProto as? IGPClientGetRoomHistoryResponse {
                    IGClientGetRoomHistoryRequest.Handler.interpret(response: roomHistoryReponse, roomId: self.room!.id)
                }
            }
        }).error({ (errorCode, waitTime) in
            DispatchQueue.main.async {
                switch errorCode {
                case .clinetGetRoomHistoryNoMoreMessage:
                    self.allowForGetHistory = false
                    break
                case .timeout:
                    self.allowForGetHistory = true
                    self.fetchRoomHistoryWhenDbIsClear()
                    break
                default:
                    self.allowForGetHistory = true
                    break
                }
            }
        }).send()
    }
    
    private func fetchRoomHistoryIfPossibleBefore(message: IGRoomMessage, forceGetHistory: Bool = false) {
        if !message.isLastMessage {
            
            if allowForGetHistory || forceGetHistory {
                allowForGetHistory = false
            
                IGClientGetRoomHistoryRequest.Generator.generate(roomID: self.room!.id, firstMessageID: message.id).success({ (responseProto) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.allowForGetHistory = true
                    }
                    
                    DispatchQueue.main.async {
                        IGFactory.shared.setMessageNeedsToFetchBefore(false, messageId: message.id, roomId: message.roomId)
                        switch responseProto {
                        case let roomHistoryReponse as IGPClientGetRoomHistoryResponse:
                            IGClientGetRoomHistoryRequest.Handler.interpret(response: roomHistoryReponse, roomId: self.room!.id)
                        default:
                            break
                        }
                    }
                }).error({ (errorCode, waitTime) in
                    DispatchQueue.main.async {
                        switch errorCode {
                        case .clinetGetRoomHistoryNoMoreMessage:
                            self.allowForGetHistory = false
                            IGFactory.shared.setMessageIsLastMesssageInRoom(messageId: message.id, roomId: message.roomId)
                            break
                        case .timeout:
                            self.allowForGetHistory = true
                            break
                        default:
                            self.allowForGetHistory = true
                            break
                        }
                    }
                }).send()
            }
        }
    }
}


//MARK: - GrowingTextViewDelegate
extension IGMessageViewController: GrowingTextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.setSendAndRecordButtonStates()
        if allowSendTyping() {
            self.sendTyping()
            typingStatusExpiryTimer.invalidate()
            typingStatusExpiryTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                           target:   self,
                                                           selector: #selector(sendCancelTyping),
                                                           userInfo: nil,
                                                           repeats:  false)
        }
    }
    
    func allowSendTyping() -> Bool {
        let currentTime = IGGlobal.getCurrentMillis()
        let difference = currentTime - self.latestTypeTime
        if difference < 1000 {
            self.latestTypeTime = currentTime
            return false
        }
        self.latestTypeTime = currentTime
        return true
    }
    
    func textViewDidChangeHeight(_ height: CGFloat) {
        inputTextViewHeight = height
        setInputBarHeight()
    }
    
    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        inputTextViewHeight = height
        setInputBarHeight()
    }
    
    func setInputBarHeight() {
        let height = max(self.inputTextViewHeight - 16, 20)
        var inputBarHeight = height + 16.0
        
        inputTextViewHeightConstraint.constant = inputBarHeight - 5
        
        if currentAttachment != nil {
            inputBarAttachmentViewBottomConstraint.constant = inputBarHeight + 8
            inputBarHeight += 36
            inputBarAttachmentView.isHidden = false
        } else {
            inputBarAttachmentViewBottomConstraint.constant = 0.0
            inputBarAttachmentView.isHidden = true
        }
        
        if selectedMessageToEdit != nil {
            inputBarOriginalMessageViewBottomConstraint.constant = inputBarHeight + 8
            inputBarHeight += 36.0
            inputBarOriginalMessageView.isHidden = false
        } else if selectedMessageToReply != nil {
            inputBarOriginalMessageViewBottomConstraint.constant = inputBarHeight + 8
            inputBarHeight += 36.0
            inputBarOriginalMessageView.isHidden = false
        } else if IGMessageViewController.selectedMessageToForwardToThisRoom != nil {
            inputBarOriginalMessageViewBottomConstraint.constant = inputBarHeight + 8
            inputBarHeight += 36.0
            inputBarOriginalMessageView.isHidden = false
        } else {
            inputBarOriginalMessageViewBottomConstraint.constant = 0.0
            inputBarOriginalMessageView.isHidden = true
        }
        
        
        inputBarHeightConstraint.constant = inputBarHeight
        inputBarHeightContainerConstraint.constant = inputBarHeight + 16
//        UIView.animate(withDuration: 0.2) {
//            self.view.layoutIfNeeded()
//        }
        
        UIView.animate(withDuration: 0.2, animations: { 
            self.view.layoutIfNeeded()
        }, completion: { (completed) in
            self.setCollectionViewInset()
        })
    }
    
    func managePinnedMessage(){
        if room?.pinMessage != nil && room?.pinMessage?.id != room?.deletedPinMessageId {
            txtPinnedMessage.text = IGRoomMessage.detectPinMessage(message: (room?.pinMessage)!)
            pinnedMessageView.isHidden = false
        } else {
            pinnedMessageView.isHidden = true
        }
    }
}

//MARK: - AVAudioRecorderDelegate
extension IGMessageViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        sendCancelRecoringVoice()
        if self.isRecordingVoice {
            self.didFinishRecording(success: flag)
            let filePath = recorder.url
            //discard file if time is too small
            
            //AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:avAudioRecorder.url options:nil];
            //CMTime time = asset.duration;
            //double durationInSeconds = CMTimeGetSeconds(time);
            let asset = AVURLAsset(url: filePath)
            let time = CMTimeGetSeconds(asset.duration)
            if time < 1.0 {
                return
            }
            do {
                let attachment = IGFile(name: filePath.lastPathComponent)
                
                let data = try Data(contentsOf: filePath)
                self.saveAttachmentToLocalStorage(data: data, fileNameOnDisk: filePath.lastPathComponent)
                attachment.fileNameOnDisk = filePath.lastPathComponent
                attachment.size = data.count
                attachment.type = .voice
                self.currentAttachment = attachment
                self.didTapOnSendButton(self.inputBarSendButton)
            } catch {
                //there was an error recording voice
            }
        }
        self.isRecordingVoice = false
    }
}

//MARK: - IGMessageGeneralCollectionViewCellDelegate
extension IGMessageViewController: IGMessageGeneralCollectionViewCellDelegate {
    func didTapAndHoldOnMessage(cellMessage: IGRoomMessage, cell: IGMessageGeneralCollectionViewCell) {
        
        if cellMessage.status == IGRoomMessageStatus.sending {
            return
        }
        
        self.view.endEditing(true)
        
        if cellMessage.status == IGRoomMessageStatus.failed {
            manageFailedMessage(cellMessage: cellMessage, cell: cell)
        } else {
            manageSendedMessage(cellMessage: cellMessage, cell: cell)
        }
    }
    
    private func manageSendedMessage(cellMessage: IGRoomMessage, cell: IGMessageGeneralCollectionViewCell){
        let alertC = UIAlertController(title: nil, message: nil, preferredStyle: IGGlobal.detectAlertStyle())
        let copy = UIAlertAction(title: "Copy", style: .default, handler: { (action) in
            self.copyMessage(cellMessage)
        })
        
        var pinTitle = "Pin Message"
        if self.room?.pinMessage != nil && self.room?.pinMessage?.id == cellMessage.id {
            pinTitle = "Unpin Message"
        }
        
        let pin = UIAlertAction(title: pinTitle, style: .default, handler: { (action) in
            if self.groupPinGranted(){
                if self.room?.pinMessage != nil && self.room?.pinMessage?.id == cellMessage.id {
                    self.groupPin()
                } else {
                    self.groupPin(messageId: cellMessage.id)
                }
            } else if self.channelPinGranted() {
                if self.room?.pinMessage != nil && self.room?.pinMessage?.id == cellMessage.id {
                    self.channelPin()
                } else {
                    self.channelPin(messageId: cellMessage.id)
                }
            }
        })
        let reply = UIAlertAction(title: "Reply", style: .default, handler: { (action) in
            self.forwardOrReplyMessage(cellMessage)
        })
        let forward = UIAlertAction(title: "Forward", style: .default, handler: { (action) in
            IGMessageViewController.selectedMessageToForwardFromThisRoom = cellMessage
            IGMessageViewController.selectedMessageToForwardToThisRoom = IGMessageViewController.selectedMessageToForwardFromThisRoom
            self.navigationController?.popViewController(animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                IGRecentsTableViewController.forwardStartObserver.openForwardPage()
            }
        })
        let edit = UIAlertAction(title: "Edit", style: .default, handler: { (action) in
            if self.connectionStatus == .waitingForNetwork || self.connectionStatus == .connecting {
                let alert = UIAlertController(title: "Error", message: "No Network Connection", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }else {
                self.editMessage(cellMessage)
            }
        })
        
        let share = UIAlertAction(title: "Share", style: .default, handler: { (action) in
            var finalMessage = cellMessage
            if let forward = cellMessage.forwardedFrom {
                finalMessage = forward
            }
            IGHelperPopular.shareAttachment(url: finalMessage.attachment?.path(), viewController: self)
        })
        
        let report = UIAlertAction(title: "Report", style: .default, handler: { (action) in
            self.report(room: self.room!, message: cellMessage)
        })
        
        _ = UIAlertAction(title: "More", style: .default, handler: { (action) in
            for visibleCell in self.collectionView.visibleCells {
                let aCell = visibleCell as! IGMessageGeneralCollectionViewCell
                aCell.setMultipleSelectionMode(true)
            }
        })
        _ = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
            self.deleteMessage(cellMessage)
        })
        let deleteForMe = UIAlertAction(title: "Delete for me", style: .destructive, handler: { (action) in
            self.deleteMessage(cellMessage)
        })
        let roomTitle = self.room?.title != nil ? self.room!.title! : ""
        let deleteForBoth = UIAlertAction(title: "Delete for me and " + roomTitle, style: .destructive, handler: { (action) in
            self.deleteMessage(cellMessage, both: true)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
        })
        
        //Copy
        if allowCopy(cellMessage){
            alertC.addAction(copy)
        }
        
        if allowPin() {
            alertC.addAction(pin)
        }
        
        //Reply
        if allowReply(){
            alertC.addAction(reply)
        }
        
        //Forward
        alertC.addAction(forward)
        
        //Edit
        if self.allowEdit(cellMessage){
            alertC.addAction(edit)
        }
        
        //Share
        if self.allowShare(cellMessage){
            alertC.addAction(share)
        }
        
        alertC.addAction(report)
        
        //Delete
        let delete = allowDelete(cellMessage)
        if delete.singleDelete {
            alertC.addAction(deleteForMe)
        }
        if delete.bothDelete {
            alertC.addAction(deleteForBoth)
        }
        
        alertC.addAction(cancel)
        
        self.present(alertC, animated: true, completion: nil)
    }
    
    private func manageFailedMessage(cellMessage: IGRoomMessage, cell: IGMessageGeneralCollectionViewCell){
        let alertC = UIAlertController(title: nil, message: nil, preferredStyle: IGGlobal.detectAlertStyle())
        
        let resend = UIAlertAction(title: "Send Again", style: .default, handler: { (action) in
            DispatchQueue.main.async {
                IGMessageSender.defaultSender.resend(message: cellMessage, to: self.room!)
            }
        })
        
        let delete = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
            if let attachment = cellMessage.attachment {
                IGMessageSender.defaultSender.deleteFailedMessage(primaryKeyId: attachment.primaryKeyId, hasAttachment: true)
            } else {
                IGMessageSender.defaultSender.deleteFailedMessage(primaryKeyId: cellMessage.primaryKeyId)
            }
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertC.addAction(resend)
        alertC.addAction(delete)
        alertC.addAction(cancel)
        
        self.present(alertC, animated: true, completion: nil)
    }
  
    func goToPosition(cellMessage: IGRoomMessage){
        var count = 0
        for message in self.messages {
            if cellMessage.id == message.id {
                let indexPath = IndexPath(row: 0, section: count)
                self.collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.bottom, animated: false)
                break
            }
            count+=1
        }
    }
    
    
    
    /******* overrided method for show file attachment (use from UIDocumentInteractionControllerDelegate) *******/
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func didTapOnAttachment(cellMessage: IGRoomMessage, cell: IGMessageGeneralCollectionViewCell, imageView: IGImageView?) {
        
        var finalMessage = cellMessage
        var roomMessageLists = self.messagesWithMedia
        if cellMessage.forwardedFrom != nil {
            //roomMessageLists = self.messagesWithForwardedMedia
            roomMessageLists = self.messagesWithMedia
            finalMessage = cellMessage.forwardedFrom!
        }
        
        if finalMessage.type == .sticker {
            if let sticker = IGHelperJson.parseStickerMessage(data: (finalMessage.additional?.data)!) {
                stickerPageType = StickerPageType.PREVIEW
                stickerGroupId = sticker.groupId
                performSegue(withIdentifier: "showSticker", sender: self)
            }
            return
        }
        
        if finalMessage.type == .location {
            isSendLocation = false
            receivedLocation = CLLocation(latitude: (finalMessage.location?.latitude)!, longitude: (finalMessage.location?.longitude)!)
            self.performSegue(withIdentifier: "showLocationViewController", sender: self)
            return
        }
        
        var attachmetVariableInCache = IGAttachmentManager.sharedManager.getRxVariable(attachmentPrimaryKeyId: finalMessage.attachment!.primaryKeyId!)
        if attachmetVariableInCache == nil {
            let attachmentRef = ThreadSafeReference(to: finalMessage.attachment!)
            IGAttachmentManager.sharedManager.add(attachmentRef: attachmentRef)
            attachmetVariableInCache = IGAttachmentManager.sharedManager.getRxVariable(attachmentPrimaryKeyId: finalMessage.attachment!.primaryKeyId!)
        }
        
        let attachment = attachmetVariableInCache!.value
        if attachment.status != .ready && !IGGlobal.isFileExist(path: finalMessage.attachment?.path(), fileSize: (finalMessage.attachment?.size)!) {
            return
        }
        
        switch finalMessage.type {
        case .image, .imageAndText:
            break
        case .video, .videoAndText:
            if let path = attachment.path() {
                let player = AVPlayer(url: path)
                let avController = AVPlayerViewController()
                avController.player = player
                player.play()
                present(avController, animated: true, completion: nil)
            }
            return
        case .voice , .audio, .audioAndText :
            let musicPlayer = IGMusicViewController()
            musicPlayer.attachment = finalMessage.attachment
            self.present(musicPlayer, animated: true, completion: nil)
            return
            
        case .file , .fileAndText:
            if let path = attachment.path() {
                let controller = UIDocumentInteractionController()
                controller.delegate = self
                controller.url = path
                controller.presentPreview(animated: true)
            }
            return
        default:
            return
        }
        
        let thisMessageInSharedMediaResult = roomMessageLists.filter("id == \(cellMessage.id)")
        var indexOfThis = 0
        if let this = thisMessageInSharedMediaResult.first {
            indexOfThis = roomMessageLists.index(of: this)!
        }
        
        var photos: [INSPhotoViewable] = Array(roomMessageLists.map { (message) -> IGMedia in
            return IGMedia(message: message, forwardedMedia: false)
        })
        
        let currentPhoto = photos[indexOfThis]
        let galleryPreview = INSPhotosViewController(photos: photos, initialPhoto: currentPhoto, referenceView: imageView)
        galleryPreview.referenceViewForPhotoWhenDismissingHandler = { photo in
            return imageView
        }
        present(galleryPreview, animated: true, completion: nil)
    }
    
    func didTapOnForwardedAttachment(cellMessage: IGRoomMessage, cell: IGMessageGeneralCollectionViewCell) {
        if let forwardedMsgType = cellMessage.forwardedFrom?.type {
        switch forwardedMsgType {
        case .audio , .voice :
            let musicPlayer = IGMusicViewController()
            musicPlayer.attachment = cellMessage.forwardedFrom?.attachment
            self.present(musicPlayer, animated: true, completion: {
            })
            break
        case .video, .videoAndText:
            if let path = cellMessage.forwardedFrom?.attachment?.path() {
                let player = AVPlayer(url: path)
                let avController = AVPlayerViewController()
                avController.player = player
                player.play()
                present(avController, animated: true, completion: nil)
            }
        default:
            break
        }
        }
    }
    
    func didTapOnSenderAvatar(cellMessage: IGRoomMessage, cell: IGMessageGeneralCollectionViewCell) {
        if let sender = cellMessage.authorUser {
            self.selectedUserToSeeTheirInfo = sender
            openUserProfile()
        }
    }
    
    func didTapOnHashtag(hashtagText: String) {
        
    }
    
    func didTapOnReply(cellMessage: IGRoomMessage, cell: IGMessageGeneralCollectionViewCell){
        if let replyMessage = cellMessage.repliedTo {
            goToPosition(cellMessage: replyMessage)
        }
    }
    
    func didTapOnForward(cellMessage: IGRoomMessage, cell: IGMessageGeneralCollectionViewCell){
        if let forwardMessage = cellMessage.forwardedFrom {
            
            var usernameType : IGPClientSearchUsernameResponse.IGPResult.IGPType = .room
            if forwardMessage.authorUser != nil {
                usernameType = .user
            }
            
            IGHelperChatOpener.manageOpenChatOrProfile(viewController: self, usernameType: usernameType, user: forwardMessage.authorUser, room: forwardMessage.authorRoom)
        }
    }
    
    func didTapOnMention(mentionText: String) {
        IGHelperChatOpener.checkUsernameAndOpenRoom(viewController: self, username: mentionText)
    }
    
    func didTapOnEmail(email: String) {
        if let url = URL(string: "mailto:\(email)") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    func didTapOnURl(url: URL) {
        var urlString = url.absoluteString
        let urlStringLower = url.absoluteString.lowercased()
        
        if urlStringLower.contains("https://igap.net/join") || urlStringLower.contains("http://igap.net/join") ||  urlStringLower.contains("igap.net/join") {
            didTapOnRoomLink(link: urlString)
            return
        }
        
        if !(urlStringLower.contains("https://")) && !(urlStringLower.contains("http://")) {
            urlString = "http://" + urlString
        }
        
        IGHelperOpenLink.openLink(urlString: urlString, navigationController: self.navigationController!)
    }
    func didTapOnRoomLink(link: String) {
        let strings = link.split(separator: "/")
        let token = strings[strings.count-1]
        self.requestToCheckInvitedLink(invitedLink: String(token))
    }
    
    func didTapOnBotAction(action: String){
        if !isBotRoom() {return}
        
        var myaction : String = action
        if !(myaction.contains("/")) {
            myaction = "/"+myaction
        }
        inputTextView.text = myaction
        self.didTapOnSendButton(self.inputBarSendButton)
    }
    
    func createChat(selectedUser: IGRegisteredUser) {
        let hud = MBProgressHUD.showAdded(to: self.view.superview!, animated: true)
        hud.mode = .indeterminate
        IGChatGetRoomRequest.Generator.generate(peerId: selectedUser.id).success({ (protoResponse) in
            DispatchQueue.main.async {
                switch protoResponse {
                case let chatGetRoomResponse as IGPChatGetRoomResponse:
                    let roomId = IGChatGetRoomRequest.Handler.interpret(response: chatGetRoomResponse)
                    
                    IGClientGetRoomRequest.Generator.generate(roomId: roomId).success({ (protoResponse) in
                        DispatchQueue.main.async {
                            switch protoResponse {
                            case let clientGetRoomResponse as IGPClientGetRoomResponse:
                                IGClientGetRoomRequest.Handler.interpret(response: clientGetRoomResponse)
                                let room = IGRoom(igpRoom: clientGetRoomResponse.igpRoom)
                                let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                                let roomVC = storyboard.instantiateViewController(withIdentifier: "messageViewController") as! IGMessageViewController
                                roomVC.room = room
                                self.navigationController!.pushViewController(roomVC, animated: true)
                            default:
                                break
                            }
                            self.hud.hide(animated: true)
                        }
                    }).error ({ (errorCode, waitTime) in
                        DispatchQueue.main.async {
                            switch errorCode {
                            case .timeout:
                                let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                            default:
                                break
                            }
                            self.hud.hide(animated: true)
                        }
                    }).send()
                    
                    hud.hide(animated: true)
                    break
                default:
                    break
                }
            }
            
        }).error({ (errorCode, waitTime) in
            hud.hide(animated: true)
            let alertC = UIAlertController(title: "Error", message: "An error occured trying to create a conversation", preferredStyle: .alert)
            
            let cancel = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertC.addAction(cancel)
            self.present(alertC, animated: true, completion: nil)
        }).send()
    }
    
    func joinRoombyInvitedLink(room:IGPRoom, invitedToken: String) {
        self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.hud.mode = .indeterminate
        IGClientJoinByInviteLinkRequest.Generator.generate(invitedToken: invitedToken).success({ (protoResponse) in
            DispatchQueue.main.async {
                if let _ = protoResponse as? IGPClientJoinByInviteLinkResponse {
                    IGFactory.shared.updateRoomParticipant(roomId: room.igpID, isParticipant: true)
                    let predicate = NSPredicate(format: "id = %lld", room.igpID)
                    if let roomInfo = try! Realm().objects(IGRoom.self).filter(predicate).first {
                        self.openChatAfterJoin(room: roomInfo)
                    }
                }
                self.hud.hide(animated: true)
            }
        }).error ({ (errorCode, waitTime) in
            DispatchQueue.main.async {
                switch errorCode {
                case .timeout:
                    let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                    
                case .clientJoinByInviteLinkForbidden:
                    let alert = UIAlertController(title: "Error", message: "Sorry,this group does not seem to exist.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.hud.hide(animated: true)
                    self.present(alert, animated: true, completion: nil)
                    
                case .clientJoinByInviteLinkAlreadyJoined:
                    self.openChatAfterJoin(room: IGRoom(igpRoom: room), before: true)
                default:
                    break
                }
                self.hud.hide(animated: true)
            }
        }).send()

    }
    func requestToCheckInvitedLink(invitedLink: String) {
        self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.hud.mode = .indeterminate
        IGClinetCheckInviteLinkRequest.Generator.generate(invitedToken: invitedLink).success({ (protoResponse) in
            DispatchQueue.main.async {
                self.hud.hide(animated: true)
                if let clinetCheckInvitedlink = protoResponse as? IGPClientCheckInviteLinkResponse {
                    let alert = UIAlertController(title: "iGap", message: "Are you sure want to join \(clinetCheckInvitedlink.igpRoom.igpTitle)?", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        self.joinRoombyInvitedLink(room:clinetCheckInvitedlink.igpRoom, invitedToken: invitedLink)
                    })
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    
                    alert.addAction(okAction)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }).error ({ (errorCode, waitTime) in
            DispatchQueue.main.async {
                switch errorCode {
                case .timeout:
                    
                    let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    
                    self.present(alert, animated: true, completion: nil)
                default:
                    break
                }
                self.hud.hide(animated: true)
            }
            
        }).send()
    }
    
    private func openChatAfterJoin(room: IGRoom, before:Bool = false){
        
        var beforeString = ""
        if before {
            beforeString = "before "
        }
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Success", message: "You joined \(beforeString)to \(room.title!)!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            let openNow = UIAlertAction(title: "Open Now", style: .default, handler: { (action) in
                let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let chatPage = storyboard.instantiateViewController(withIdentifier: "messageViewController") as! IGMessageViewController
                chatPage.room = room
                self.navigationController!.pushViewController(chatPage, animated: true)
            })
            alert.addAction(okAction)
            alert.addAction(openNow)
            self.present(alert, animated: true, completion: nil)
        }
    }
}

//MARK: - IGForwardMessageDelegate
extension IGMessageViewController : IGForwardMessageDelegate {
    func didSelectRoomToForwardMessage(room: IGRoom) {
        if room.id == self.room?.id {
            IGMessageViewController.selectedMessageToForwardToThisRoom = IGMessageViewController.selectedMessageToForwardFromThisRoom
            self.forwardOrReplyMessage(IGMessageViewController.selectedMessageToForwardFromThisRoom!, isReply: false)
            return
        }
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let messagesVc = storyBoard.instantiateViewController(withIdentifier: "messageViewController") as! IGMessageViewController
        self.inputTextView.resignFirstResponder()
        messagesVc.room = room
        IGMessageViewController.selectedMessageToForwardToThisRoom = IGMessageViewController.selectedMessageToForwardFromThisRoom
        IGMessageViewController.selectedMessageToForwardFromThisRoom = nil
        self.navigationController!.pushViewController(messagesVc, animated:false)
    }
}



//MARK: - StatusBar Tap
extension IGMessageViewController {
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func addNotificationObserverForTapOnStatusBar() {
        NotificationCenter.default.addObserver(forName: IGNotificationStatusBarTapped.name, object: .none, queue: .none) { _ in
            if self.collectionView.contentSize.height < self.collectionView.frame.height {
                return
            }
            //1200 is just an arbitrary number. can be anything
            let newOffsetY = min(self.collectionView.contentOffset.y + 1200, self.collectionView.contentSize.height - self.collectionView.frame.height + self.collectionView.contentInset.bottom)
            let newOffsett = CGPoint(x: 0, y: newOffsetY)
            self.collectionView.setContentOffset(newOffsett , animated: true)
        }
    }    
}

//MARK: - Set and cancel current action (typing, ...)
extension IGMessageViewController {
    fileprivate func sendTyping() {
        IGClientActionManager.shared.sendTyping(for: self.room!)
    }
    @objc fileprivate func sendCancelTyping() {
        
        if !self.allowSendTyping() {
            typingStatusExpiryTimer.invalidate()
            typingStatusExpiryTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                           target:   self,
                                                           selector: #selector(sendCancelTyping),
                                                           userInfo: nil,
                                                           repeats:  false)
        } else {
            typingStatusExpiryTimer.invalidate()
            IGClientActionManager.shared.cancelTying(for: self.room!)
        }
    }
    
    fileprivate func sendRecordingVoice() {
        IGClientActionManager.shared.sendRecordingVoice(for: self.room!)
    }
    fileprivate func sendCancelRecoringVoice() {
        IGClientActionManager.shared.sendCancelRecoringVoice(for: self.room!)
    }
    
//    Capturing Image
//    Capturign Video
//    Sending Gif
//    Sending Location
//    Choosing Contact
//    Painting
    
}
extension String {
    func chopPrefix(_ count: Int = 1) -> String {
        return substring(from: index(startIndex, offsetBy: count))
    }
    
    func chopSuffix(_ count: Int = 1) -> String {
        return substring(to: index(endIndex, offsetBy: -count))
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
