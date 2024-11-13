//
//  ChatUserStruct.swift
//  diploma
//
//  Created by Максим Купрейчук on 20.04.2023.
//

import Foundation

struct ChatUser: Identifiable{
    
    var id: String{ uid }
    
    let uid, email, profileImageUrl, familyid: String
    let canAccessChat, updateLocation: Bool
    
    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        self.familyid = data[FireBaseConstants.familyid] as? String ?? ""
        self.canAccessChat = data["canAccessChat"] as? Bool ?? false
        self.updateLocation = data["canUpdateLocation"] as? Bool ?? false
    }
}
