////
////  fetchRecentMessages.swift
////  diploma
////
////  Created by Максим Купрейчук on 28.04.2023.
////
//
//struct recentMessage: Identifiable{
//    var id = UUID()
//    
//    let profileImage, name, lastMessage: String
//    
//    init(profileImage: String, name: String, lastMessage: String) {
//        self.profileImage = profileImage
//        self.name = name
//        self.lastMessage = lastMessage
//    }
//
//}
//
//import Foundation
//
//class FetchRecentMessages: ObservableObject{
//    
//    @Published var userArray = [recentMessage]()
//    
//    init(){
//        getMessages()
//    }
//    
//    var usersArray = [String]()
//    
//    func getMessages(){
//        guard let userid = FireBaseManager.shared.auth.currentUser?.uid else {return}
//        
//        FireBaseManager.shared.firestore.collection(FireBaseConstants.messageCollection)
//            .document(userid)
//            .collection()
//            .getDocuments{
//                document, error in
//                if let error = error{
//                    print("\(error)")
//                    return
//                }
//            }
//            
//    }
//}
