/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the Kianiranian STDG - www.kianiranian.com
 * All rights reserved.
 */

import RealmSwift
import Foundation
import IGProtoBuff

class IGRoomMessageWallet: Object {
    @objc dynamic var id:                String?
    @objc dynamic var type:              Int      = IGPRoomMessageWallet.IGPType.moneyTransfer.rawValue
    @objc dynamic var fromUserId:        Int64    = 0
    @objc dynamic var toUserId:          Int64    = 0
    @objc dynamic var amount:            Int64    = 0
    @objc dynamic var traceNumber:       Int64    = 0
    @objc dynamic var invoiceNumber:     Int64    = 0
    @objc dynamic var payTime:           Int32    = 0
    @objc dynamic var walletDescription: String?
    
    
    override static func primaryKey() -> String {
        return "id"
    }
    
    convenience init(igpRoomMessageWallet: IGPRoomMessageWallet, for message: IGRoomMessage) {
        self.init()
        self.id = message.primaryKeyId
        self.type = igpRoomMessageWallet.igpType.rawValue
        self.fromUserId = igpRoomMessageWallet.igpMoneyTransfer.igpFromUserID
        self.toUserId = igpRoomMessageWallet.igpMoneyTransfer.igpToUserID
        self.amount = igpRoomMessageWallet.igpMoneyTransfer.igpAmount
        self.traceNumber = igpRoomMessageWallet.igpMoneyTransfer.igpTraceNumber
        self.invoiceNumber = igpRoomMessageWallet.igpMoneyTransfer.igpInvoiceNumber
        self.payTime = igpRoomMessageWallet.igpMoneyTransfer.igpPayTime
        self.walletDescription = igpRoomMessageWallet.igpMoneyTransfer.igpDescription
    }
    
    static func putOrUpdate(realm: Realm, igpRoomMessageWallet: IGPRoomMessageWallet, for message: IGRoomMessage) -> IGRoomMessageWallet {
        
        let predicate = NSPredicate(format: "id = %@", message.primaryKeyId!)
        var wallet: IGRoomMessageWallet! = realm.objects(IGRoomMessageWallet.self).filter(predicate).first

        if wallet == nil {
            wallet = IGRoomMessageWallet()
            wallet.id = message.primaryKeyId
        }
        
        wallet.type = igpRoomMessageWallet.igpType.rawValue
        wallet.fromUserId = igpRoomMessageWallet.igpMoneyTransfer.igpFromUserID
        wallet.toUserId = igpRoomMessageWallet.igpMoneyTransfer.igpToUserID
        wallet.amount = igpRoomMessageWallet.igpMoneyTransfer.igpAmount
        wallet.traceNumber = igpRoomMessageWallet.igpMoneyTransfer.igpTraceNumber
        wallet.invoiceNumber = igpRoomMessageWallet.igpMoneyTransfer.igpInvoiceNumber
        wallet.payTime = igpRoomMessageWallet.igpMoneyTransfer.igpPayTime
        wallet.walletDescription = igpRoomMessageWallet.igpMoneyTransfer.igpDescription
        
        return wallet
    }
    
    
    //detach from current realm
    func detach() -> IGRoomMessageWallet {
        let detachedRoomMessageLocation = IGRoomMessageWallet(value: self)
        return detachedRoomMessageLocation
    }
}
