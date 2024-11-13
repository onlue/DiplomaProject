//
//  MyFireBaseManager.swift
//  diploma
//
//  Created by Максим Купрейчук on 19.04.2023.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

class FireBaseManager : NSObject{
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    var currentUser: ChatUser?
    
    static let shared = FireBaseManager()
    
    override init(){
        FirebaseApp.configure()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        
        super.init()
    }
}
