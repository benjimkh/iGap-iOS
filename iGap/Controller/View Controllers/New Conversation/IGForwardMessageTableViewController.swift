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
import Contacts
import SwiftProtobuf
import RealmSwift
import IGProtoBuff
import MGSwipeTableCell
import MBProgressHUD

protocol IGForwardMessageDelegate {
    func didSelectRoomToForwardMessage(room : IGRoom)
}

class IGForwardMessageTableViewController: UITableViewController {

    @IBOutlet weak var forwardSegment: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    class User:NSObject {
        let registredUser: IGRegisteredUser
        @objc let name:String!
        var section :Int?
        init(registredUser: IGRegisteredUser){
            self.registredUser = registredUser
            self.name = registredUser.displayName
        }
    }
    class Section  {
        var users:[User] = []
        func addUser(_ user:User){
            self.users.append(user)
        }
    }
    
    static var forwardMessageDelegate: IGForwardMessageDelegate?
    //Contact
    var contacts = try! Realm().objects(IGRegisteredUser.self).filter("isInContacts == 1" )
    var contactSections : [Section]?
    let collation = UILocalizedIndexedCollation.current()
    var filteredTableData = [CNContact]()
    var resultSearchController = UISearchController()
    var contactsSections : [Section]{
        if self.contactSections != nil {
            return self.contactSections!
        }
        let users :[User] = contacts.map{ (registeredUser) -> User in
            let user = User(registredUser: registeredUser )
            
            user.section = self.collation.section(for: user, collationStringSelector: #selector(getter: User.name))
            return user
        }
        var sections = [Section]()
        for _ in 0..<self.collation.sectionIndexTitles.count{
            sections.append(Section())
        }
        for user in users {
            sections[user.section!].addUser(user)
        }
        for section in sections {
            section.users = self.collation.sortedArray(from: section.users, collationStringSelector: #selector(getter: User.name)) as! [User]
        }
        self.contactSections = sections
        return self.contactSections!
    }    
    
    
    //Chats
    var roomsCellIdentifer = IGChatRoomListTableViewCell.cellReuseIdentifier()
    var contactsCellIdentifier = "forwardContactCell"
    var rooms: Results<IGRoom>? = nil
    var hud = MBProgressHUD()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        let sortProperties = [SortDescriptor(keyPath: "pinId", ascending: false), SortDescriptor(keyPath: "sortimgTimestamp", ascending: false)]
        self.rooms = try! Realm().objects(IGRoom.self).filter("isParticipant = 1 AND isReadOnly = false").sorted(by: sortProperties)
        self.tableView.tableFooterView = UIView()
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addModalViewItems(leftItemText: nil, rightItemText: "Cancel", title: nil)
        navigationItem.rightViewContainer?.addAction {
            self.dismiss(animated: true, completion: {
                IGMessageViewController.selectedMessageToForwardToThisRoom = nil
            })
        }

        
        self.tableView.register(IGChatRoomListTableViewCell.nib(), forCellReuseIdentifier: IGChatRoomListTableViewCell.cellReuseIdentifier())
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        self.view.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        self.tableView.tableHeaderView?.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        
        IGHelperView.makeSearchView(searchBar: searchBar)
    }
    
    //MARK: - IBActions
    @IBAction func didChangedSegmentValue(_ sender: UISegmentedControl) {
        if (sender.selectedSegmentIndex == 1) {
            self.tableView.tag = 1
        } else if sender.selectedSegmentIndex == 0 {
            self.tableView.tag = 0
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch self.tableView.tag {
        case 1:
             return self.contactsSections.count
        case 0:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.tableView.tag {
        case 1:
            return self.contactsSections[ section ].users.count
        case 0:
            return rooms!.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.tableView.tag == 0 {
            let chatsCell: IGChatRoomListTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: roomsCellIdentifer) as! IGChatRoomListTableViewCell
            chatsCell.setRoom(room: rooms![indexPath.row])
            chatsCell.separatorInset = UIEdgeInsets(top: 0, left: 82.0, bottom: 0, right: 0)
            chatsCell.layoutMargins = UIEdgeInsets.zero
            return chatsCell
        } else {
            let contactsCell = tableView.dequeueReusableCell(withIdentifier: contactsCellIdentifier, for: indexPath) as! IGForwardContactsTableViewCell
            let user = self.contactsSections[indexPath.section ].users[indexPath.row]
            contactsCell.setUser(user.registredUser)
            return contactsCell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var user: IGRegisteredUser?
        var room: IGRoom?
        var type: IGPClientSearchUsernameResponse.IGPResult.IGPType!
        if self.tableView.tag == 0 {
            type = IGPClientSearchUsernameResponse.IGPResult.IGPType.room
            room = self.rooms![indexPath.row]
        } else {
            type = IGPClientSearchUsernameResponse.IGPResult.IGPType.user
            user = self.contactsSections[indexPath.section].users[indexPath.row].registredUser
        }

        dismiss(animated: true, completion: {
            DispatchQueue.main.async {
                IGRecentsTableViewController.forwardStartObserver.onForwardStart(user: user, room: room, type: type)
            }
        })
    }
    
    override func tableView(_ tableView: UITableView,titleForHeaderInSection section: Int) -> String {
        if self.tableView.tag == 0 {
            return ""
        }else {
            tableView.headerView(forSection: section)?.backgroundColor = UIColor.red
            if !self.contactsSections[section].users.isEmpty {
                return self.collation.sectionTitles[section]
            }else{
                return ""
            }
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if self.tableView.tag == 1 {
        return self.collation.sectionIndexTitles
        }else {
           return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int{
        return self.collation.section(forSectionIndexTitle: index)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.tableView.tag == 0 {
        return 78.0
        }
        if self.tableView.tag == 1 {
           return 55.0
        }
        return 44.0
    }
}


extension IGForwardMessageTableViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        IGLookAndFind.enableForward = true
        IGGlobal.heroTabIndex = -1
        let lookAndFind = UIStoryboard(name: "IGSettingStoryboard", bundle: nil).instantiateViewController(withIdentifier: "IGLookAndFind")
        lookAndFind.hero.isEnabled = true
        self.searchBar.hero.id = "searchBar"
        self.navigationController?.hero.isEnabled = true
        self.navigationController?.hero.navigationAnimationType = .fade
        self.hero.replaceViewController(with: lookAndFind)
        return true
    }
}

