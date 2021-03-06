//
//  SWalletPersistence.swift
//  platonWallet
//
//  Created by matrixelement on 14/11/2018.
//  Copyright © 2018 ju. All rights reserved.
//

import Foundation

class SWalletPersistence {
     
    public class func add(swallet : SWallet){
        try? RealmInstance!.write {
            RealmInstance!.add(swallet)
        }
    }
    
    public class func update(swallet : SWallet){
        try? RealmInstance!.write { 
            RealmInstance!.add(swallet, update: true)
        }
    }
    
    public class func getAll() -> [SWallet]{
        let r = RealmInstance!.objects(SWallet.self).sorted(byKeyPath: "createTime", ascending: true)
        let array = Array(r)
        return array
    }
    
    public class func delete(addrInfo: SWallet) {
        try? RealmInstance!.write {
            RealmInstance!.delete(addrInfo)
        }
        
    }
}
